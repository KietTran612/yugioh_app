import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/card_model.dart';
import '../models/deck_model.dart';
import '../models/filter_state.dart';
import '../providers/card_provider.dart';
import '../providers/deck_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/card_image.dart';
import 'card_picker_sheet.dart';

// ── Hard-filter helpers ────────────────────────────────────────────────────────

/// Trả về true nếu card hợp lệ cho zone trong deck.
bool cardValidForZone(YugiohCard card, DeckZone zone) {
  final isExtra = card.isFusion || card.isSynchro || card.isXyz || card.isLink;
  switch (zone) {
    case DeckZone.main:
      return !isExtra; // Main: không nhận Extra-type
    case DeckZone.extra:
      return isExtra; // Extra: chỉ nhận Extra-type
    case DeckZone.side:
      return true; // Side: tất cả
  }
}

/// Trả về true nếu card bị Forbidden trong format của deck.
bool cardForbidden(YugiohCard card, DeckFormat format) {
  final banlist = card.misc?.banlist;
  if (banlist == null) return false;
  switch (format) {
    case DeckFormat.masterDuel:
      // Master Duel: dùng status nghiêm nhất giữa TCG và OCG (API không có ban_md)
      final tcg = banlist.tcg;
      final ocg = banlist.ocg;
      if (tcg == BanlistStatus.forbidden || ocg == BanlistStatus.forbidden) {
        return true;
      }
      return false;
    case DeckFormat.duelLinks:
      return banlist.ocg == BanlistStatus.forbidden;
  }
}

// ── Local filter state (độc lập với global filterStateProvider) ───────────────

class _PickerFilter {
  final Set<String> frameTypes;
  final Set<String> attributes;
  final Set<String> races;
  final Set<int> levels;
  final String? archetype;
  final int? atkMin;
  final int? atkMax;
  final int? defMin;
  final int? defMax;
  final Set<String> tcgRarities;
  final Set<String> banlistStatuses;
  final Set<String> formats;
  final SortOption sortBy;
  final bool sortAscending;

  const _PickerFilter({
    this.frameTypes = const {},
    this.attributes = const {},
    this.races = const {},
    this.levels = const {},
    this.archetype,
    this.atkMin,
    this.atkMax,
    this.defMin,
    this.defMax,
    this.tcgRarities = const {},
    this.banlistStatuses = const {},
    this.formats = const {},
    this.sortBy = SortOption.name,
    this.sortAscending = true,
  });

  bool get hasActive =>
      frameTypes.isNotEmpty ||
      attributes.isNotEmpty ||
      races.isNotEmpty ||
      levels.isNotEmpty ||
      archetype != null ||
      atkMin != null ||
      atkMax != null ||
      defMin != null ||
      defMax != null ||
      tcgRarities.isNotEmpty ||
      banlistStatuses.isNotEmpty ||
      formats.isNotEmpty;

  // Đếm số filter section đang active (dùng cho badge)
  int get activeCount {
    int n = 0;
    if (frameTypes.isNotEmpty) n++;
    if (attributes.isNotEmpty) n++;
    if (races.isNotEmpty) n++;
    if (levels.isNotEmpty) n++;
    if (archetype != null) n++;
    if (atkMin != null || atkMax != null) n++;
    if (defMin != null || defMax != null) n++;
    if (tcgRarities.isNotEmpty) n++;
    if (banlistStatuses.isNotEmpty) n++;
    if (formats.isNotEmpty) n++;
    return n;
  }

  _PickerFilter copyWith({
    Set<String>? frameTypes,
    Set<String>? attributes,
    Set<String>? races,
    Set<int>? levels,
    Object? archetype = _pSentinel,
    Object? atkMin = _pSentinel,
    Object? atkMax = _pSentinel,
    Object? defMin = _pSentinel,
    Object? defMax = _pSentinel,
    Set<String>? tcgRarities,
    Set<String>? banlistStatuses,
    Set<String>? formats,
    SortOption? sortBy,
    bool? sortAscending,
  }) => _PickerFilter(
    frameTypes: frameTypes ?? this.frameTypes,
    attributes: attributes ?? this.attributes,
    races: races ?? this.races,
    levels: levels ?? this.levels,
    archetype: archetype == _pSentinel ? this.archetype : archetype as String?,
    atkMin: atkMin == _pSentinel ? this.atkMin : atkMin as int?,
    atkMax: atkMax == _pSentinel ? this.atkMax : atkMax as int?,
    defMin: defMin == _pSentinel ? this.defMin : defMin as int?,
    defMax: defMax == _pSentinel ? this.defMax : defMax as int?,
    tcgRarities: tcgRarities ?? this.tcgRarities,
    banlistStatuses: banlistStatuses ?? this.banlistStatuses,
    formats: formats ?? this.formats,
    sortBy: sortBy ?? this.sortBy,
    sortAscending: sortAscending ?? this.sortAscending,
  );

  _PickerFilter reset() => const _PickerFilter();
}

const _pSentinel = Object();

// ── Screen ─────────────────────────────────────────────────────────────────────

class CardPickerScreen extends ConsumerStatefulWidget {
  final String deckId;

  const CardPickerScreen({super.key, required this.deckId});

  @override
  ConsumerState<CardPickerScreen> createState() => _CardPickerScreenState();
}

class _CardPickerScreenState extends ConsumerState<CardPickerScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String _searchQuery = '';
  int _displayCount = 50;
  _PickerFilter _filter = const _PickerFilter();

  // Zone đang được chọn để filter (null = tất cả hợp lệ)
  DeckZone? _activeZone;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 400) {
      setState(() => _displayCount += 50);
    }
  }

  List<YugiohCard> _applyFilters(List<YugiohCard> all, Deck deck) {
    var cards = all;

    // ── Hard filter: zone validity ────────────────────────────────────
    if (_activeZone != null) {
      cards = cards.where((c) => cardValidForZone(c, _activeZone!)).toList();
    }

    // ── Search ────────────────────────────────────────────────────────
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      cards = cards
          .where(
            (c) =>
                c.name.toLowerCase().contains(q) ||
                c.desc.toLowerCase().contains(q),
          )
          .toList();
    }

    // ── User filters ──────────────────────────────────────────────────
    if (_filter.frameTypes.isNotEmpty) {
      cards = cards
          .where((c) => _filter.frameTypes.contains(c.frameType))
          .toList();
    }
    if (_filter.attributes.isNotEmpty) {
      cards = cards
          .where((c) => _filter.attributes.contains(c.attribute))
          .toList();
    }
    if (_filter.races.isNotEmpty) {
      cards = cards.where((c) => _filter.races.contains(c.race)).toList();
    }
    if (_filter.levels.isNotEmpty) {
      cards = cards
          .where((c) => c.level != null && _filter.levels.contains(c.level))
          .toList();
    }
    if (_filter.archetype != null) {
      cards = cards.where((c) => c.archetype == _filter.archetype).toList();
    }
    if (_filter.atkMin != null) {
      cards = cards
          .where((c) => c.atk != null && c.atk! >= _filter.atkMin!)
          .toList();
    }
    if (_filter.atkMax != null) {
      cards = cards
          .where((c) => c.atk != null && c.atk! <= _filter.atkMax!)
          .toList();
    }
    if (_filter.defMin != null) {
      cards = cards
          .where((c) => c.def != null && c.def! >= _filter.defMin!)
          .toList();
    }
    if (_filter.defMax != null) {
      cards = cards
          .where((c) => c.def != null && c.def! <= _filter.defMax!)
          .toList();
    }
    if (_filter.tcgRarities.isNotEmpty) {
      cards = cards
          .where(
            (c) => c.sets.any(
              (s) => _filter.tcgRarities.contains(s.setRarityCode),
            ),
          )
          .toList();
    }
    if (_filter.banlistStatuses.isNotEmpty) {
      cards = cards.where((c) {
        final b = c.misc?.banlist;
        if (b == null) return false;
        // Lấy effective status theo format của deck (Master Duel = max(TCG,OCG))
        final BanlistStatus? effectiveStatus;
        if (deck.format == DeckFormat.masterDuel) {
          final tcg = b.tcg;
          final ocg = b.ocg;
          if (tcg == null && ocg == null) return false;
          if (tcg == null) {
            effectiveStatus = ocg;
          } else if (ocg == null) {
            effectiveStatus = tcg;
          } else {
            effectiveStatus = tcg.index <= ocg.index ? tcg : ocg;
          }
        } else {
          // Duel Links dùng OCG
          effectiveStatus = b.ocg;
        }
        if (effectiveStatus == null) return false;
        return _filter.banlistStatuses.contains(effectiveStatus.label);
      }).toList();
    }
    if (_filter.formats.isNotEmpty) {
      cards = cards.where((c) {
        final cardFormats = c.misc?.formats ?? [];
        return _filter.formats.every((f) => cardFormats.contains(f));
      }).toList();
    }

    // ── Sort ──────────────────────────────────────────────────────────
    cards = List.from(cards)
      ..sort((a, b) {
        int cmp;
        switch (_filter.sortBy) {
          case SortOption.name:
            cmp = a.name.compareTo(b.name);
            break;
          case SortOption.atk:
            cmp = (a.atk ?? -1).compareTo(b.atk ?? -1);
            break;
          case SortOption.def:
            cmp = (a.def ?? -1).compareTo(b.def ?? -1);
            break;
          case SortOption.level:
            cmp = (a.level ?? 0).compareTo(b.level ?? 0);
            break;
          case SortOption.type:
            cmp = a.type.compareTo(b.type);
            break;
        }
        return _filter.sortAscending ? cmp : -cmp;
      });

    return cards;
  }

  @override
  Widget build(BuildContext context) {
    final cardsAsync = ref.watch(cardDataProvider);
    final decks = ref.watch(deckProvider);
    final deck = decks.where((d) => d.id == widget.deckId).firstOrNull;

    if (deck == null) {
      return const Scaffold(
        backgroundColor: AppTheme.bgDeep,
        body: Center(
          child: Text(
            'Deck not found',
            style: TextStyle(color: AppTheme.textMuted),
          ),
        ),
      );
    }

    final filterAsync = ref.watch(filterIndexProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: _buildAppBar(deck, filterAsync),
      body: Column(
        children: [
          // ── Zone selector ──────────────────────────────────────────
          _ZoneSelector(
            deck: deck,
            activeZone: _activeZone,
            onZoneChanged: (z) => setState(() {
              _activeZone = z;
              _displayCount = 50;
            }),
          ),

          // ── Search bar ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              autofocus: false,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search cards...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                            _displayCount = 50;
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (v) => setState(() {
                _searchQuery = v;
                _displayCount = 50;
              }),
            ),
          ),

          // ── Card grid ──────────────────────────────────────────────
          Expanded(
            child: cardsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.accent,
                  strokeWidth: 2,
                ),
              ),
              error: (e, _) => Center(
                child: Text(
                  'Error: $e',
                  style: const TextStyle(color: AppTheme.textMuted),
                ),
              ),
              data: (data) {
                final filtered = _applyFilters(data.cards, deck);
                if (filtered.isEmpty) {
                  return _EmptyResult(
                    hasFilter: _filter.hasActive || _searchQuery.isNotEmpty,
                  );
                }
                final display = filtered.take(_displayCount).toList();
                final hasMore = _displayCount < filtered.length;

                return Column(
                  children: [
                    // Count row
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                      child: Row(
                        children: [
                          _CountBadge(count: filtered.length),
                          if (_activeZone != null) ...[
                            const SizedBox(width: 8),
                            _ZoneBadge(zone: _activeZone!),
                          ],
                        ],
                      ),
                    ),
                    Expanded(
                      child: GridView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _crossAxisCount(context),
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 0.69,
                        ),
                        itemCount: display.length + (hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == display.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(
                                  color: AppTheme.accent,
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          }
                          return _PickerCardItem(
                            card: display[index],
                            deck: deck,
                            activeZone: _activeZone,
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    Deck deck,
    AsyncValue<FilterIndex> filterAsync,
  ) {
    return AppBar(
      backgroundColor: AppTheme.bgDeep,
      foregroundColor: AppTheme.textPrimary,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add Cards',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          Text(
            deck.name,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textMuted,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      actions: [
        // Filter button
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: Icon(
                Icons.tune_rounded,
                color: _filter.hasActive
                    ? AppTheme.accent
                    : AppTheme.textSecondary,
              ),
              tooltip: 'Filter',
              onPressed: () =>
                  filterAsync.whenData((index) => _showFilterSheet(index)),
            ),
            if (_filter.hasActive)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppTheme.bgBorder),
      ),
    );
  }

  void _showFilterSheet(FilterIndex index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => _PickerFilterSheet(
          filterIndex: index,
          current: _filter,
          onApply: (f) {
            setState(() {
              _filter = f;
              _displayCount = 50;
            });
          },
        ),
      ),
    );
  }

  int _crossAxisCount(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w > 1200) return 8;
    if (w > 800) return 6;
    if (w > 600) return 4;
    return 3;
  }
}

// ── Zone selector bar ──────────────────────────────────────────────────────────

class _ZoneSelector extends StatelessWidget {
  final Deck deck;
  final DeckZone? activeZone;
  final ValueChanged<DeckZone?> onZoneChanged;

  const _ZoneSelector({
    required this.deck,
    required this.activeZone,
    required this.onZoneChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cfg = deck.config;
    final zones = <DeckZone>[DeckZone.main, DeckZone.extra];
    if (cfg.hasSide) zones.add(DeckZone.side);

    return Container(
      color: AppTheme.bgCard,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          // "All" chip
          _ZoneChip(
            label: 'All',
            color: AppTheme.textSecondary,
            isActive: activeZone == null,
            onTap: () => onZoneChanged(null),
          ),
          const SizedBox(width: 8),
          ...zones.map((z) {
            final count = _zoneCount(z);
            final max = _zoneMax(z, cfg);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _ZoneChip(
                label: '${_zoneLabel(z)} $count/$max',
                color: _zoneColor(z),
                isActive: activeZone == z,
                onTap: () => onZoneChanged(activeZone == z ? null : z),
              ),
            );
          }),
        ],
      ),
    );
  }

  int _zoneCount(DeckZone z) {
    switch (z) {
      case DeckZone.main:
        return deck.mainDeck.length;
      case DeckZone.extra:
        return deck.extraDeck.length;
      case DeckZone.side:
        return deck.sideDeck.length;
    }
  }

  int _zoneMax(DeckZone z, DeckFormatConfig cfg) {
    switch (z) {
      case DeckZone.main:
        return cfg.mainMax;
      case DeckZone.extra:
        return cfg.extraMax;
      case DeckZone.side:
        return cfg.sideMax;
    }
  }

  String _zoneLabel(DeckZone z) {
    switch (z) {
      case DeckZone.main:
        return 'Main';
      case DeckZone.extra:
        return 'Extra';
      case DeckZone.side:
        return 'Side';
    }
  }

  Color _zoneColor(DeckZone z) {
    switch (z) {
      case DeckZone.main:
        return AppTheme.accent;
      case DeckZone.extra:
        return AppTheme.accentGold;
      case DeckZone.side:
        return AppTheme.textSecondary;
    }
  }
}

class _ZoneChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;

  const _ZoneChip({
    required this.label,
    required this.color,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.15) : AppTheme.bgElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? color : AppTheme.bgBorder,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? color : AppTheme.textSecondary,
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ── Card item ──────────────────────────────────────────────────────────────────

class _PickerCardItem extends ConsumerWidget {
  final YugiohCard card;
  final Deck deck;
  final DeckZone? activeZone;

  const _PickerCardItem({
    required this.card,
    required this.deck,
    required this.activeZone,
  });

  /// Lấy banlist status theo format của deck
  /// Master Duel: lấy status nghiêm nhất giữa TCG và OCG
  BanlistStatus? _banlistStatus() {
    final b = card.misc?.banlist;
    if (b == null) return null;
    if (deck.format == DeckFormat.masterDuel) {
      return _stricterStatus(b.tcg, b.ocg);
    }
    return b.ocg; // Duel Links dùng OCG
  }

  /// Trả về status nghiêm hơn giữa hai status.
  static BanlistStatus? _stricterStatus(BanlistStatus? a, BanlistStatus? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.index <= b.index ? a : b;
  }

  /// Số copy tối đa — luôn là 3, banlist chỉ hiển thị warning, không block.
  int _maxAllowed() => 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decks = ref.watch(deckProvider);
    final current = decks.where((d) => d.id == deck.id).firstOrNull ?? deck;

    final isExtra =
        card.isFusion || card.isSynchro || card.isXyz || card.isLink;
    final mainCount = current.mainDeck.where((id) => id == card.id).length;
    final extraCount = current.extraDeck.where((id) => id == card.id).length;
    final sideCount = current.sideDeck.where((id) => id == card.id).length;
    final totalInDeck = mainCount + extraCount + sideCount;
    final displayCount = isExtra ? extraCount : mainCount;
    final maxAllowed = _maxAllowed();
    final isAtLimit = totalInDeck >= maxAllowed;
    final status = _banlistStatus();

    return GestureDetector(
      onTap: () => _showAddSheet(context),
      child: Stack(
        children: [
          // Card image
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: CardNetworkImage(
              imageUrl: card.imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),

          // Gradient overlay + name
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(4, 10, 4, 4),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(6),
                ),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Text(
                card.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Copy count badge (top-right)
          if (displayCount > 0)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.accent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.bgDeep, width: 1.5),
                ),
                child: Text(
                  'x$displayCount',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),

          // Side deck badge (top-left, chỉ khi không có banlist badge)
          if (sideCount > 0 && status == null)
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.textSecondary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.bgDeep, width: 1.5),
                ),
                child: Text(
                  'S$sideCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),

          // Banlist badge (top-left): BAN / LIM / S-L
          if (status != null)
            Positioned(
              top: 4,
              left: 4,
              child: _PickerBanlistBadge(status: status),
            ),

          // Dim overlay khi đã đạt giới hạn copies
          if (isAtLimit)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: Colors.black.withValues(alpha: 0.5),
                ),
                child: Center(
                  child: Icon(
                    maxAllowed == 0
                        ? Icons.block_rounded
                        : Icons.check_circle_rounded,
                    color: maxAllowed == 0
                        ? Colors.red.shade300
                        : Colors.white54,
                    size: 24,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) =>
          QuickAddSheet(card: card, deck: deck, preferredZone: activeZone),
    );
  }
}

// ── Banlist badge dùng trong picker ───────────────────────────────────────────

class _PickerBanlistBadge extends StatelessWidget {
  final BanlistStatus status;
  const _PickerBanlistBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      BanlistStatus.forbidden => ('BAN', AppTheme.getBanlistColor('Forbidden')),
      BanlistStatus.limited => ('LIM', AppTheme.getBanlistColor('Limited')),
      BanlistStatus.semiLimited => (
        'S-L',
        AppTheme.getBanlistColor('Semi-Limited'),
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.bgDeep, width: 1),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 7,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ── Small helpers ──────────────────────────────────────────────────────────────

class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.bgElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.bgBorder),
      ),
      child: Text(
        '$count cards',
        style: const TextStyle(
          fontSize: 11,
          color: AppTheme.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _ZoneBadge extends StatelessWidget {
  final DeckZone zone;
  const _ZoneBadge({required this.zone});

  @override
  Widget build(BuildContext context) {
    final color = zone == DeckZone.main
        ? AppTheme.accent
        : zone == DeckZone.extra
        ? AppTheme.accentGold
        : AppTheme.textSecondary;
    final label = zone == DeckZone.main
        ? 'Main only'
        : zone == DeckZone.extra
        ? 'Extra only'
        : 'Side only';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyResult extends StatelessWidget {
  final bool hasFilter;
  const _EmptyResult({required this.hasFilter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasFilter ? Icons.search_off_rounded : Icons.style_outlined,
            size: 48,
            color: AppTheme.textMuted,
          ),
          const SizedBox(height: 12),
          Text(
            hasFilter ? 'No cards match' : 'No valid cards',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 15),
          ),
          if (hasFilter) ...[
            const SizedBox(height: 6),
            const Text(
              'Try adjusting filters',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Filter bottom sheet ────────────────────────────────────────────────────────

class _PickerFilterSheet extends StatefulWidget {
  final FilterIndex filterIndex;
  final _PickerFilter current;
  final ValueChanged<_PickerFilter> onApply;

  const _PickerFilterSheet({
    required this.filterIndex,
    required this.current,
    required this.onApply,
  });

  @override
  State<_PickerFilterSheet> createState() => _PickerFilterSheetState();
}

class _PickerFilterSheetState extends State<_PickerFilterSheet> {
  late _PickerFilter _draft;
  final _atkMinCtrl = TextEditingController();
  final _atkMaxCtrl = TextEditingController();
  final _defMinCtrl = TextEditingController();
  final _defMaxCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _draft = widget.current;
    _atkMinCtrl.text = _draft.atkMin?.toString() ?? '';
    _atkMaxCtrl.text = _draft.atkMax?.toString() ?? '';
    _defMinCtrl.text = _draft.defMin?.toString() ?? '';
    _defMaxCtrl.text = _draft.defMax?.toString() ?? '';
  }

  @override
  void dispose() {
    _atkMinCtrl.dispose();
    _atkMaxCtrl.dispose();
    _defMinCtrl.dispose();
    _defMaxCtrl.dispose();
    super.dispose();
  }

  void _reset() {
    final reset = const _PickerFilter();
    setState(() => _draft = reset);
    widget.onApply(reset);
    _atkMinCtrl.clear();
    _atkMaxCtrl.clear();
    _defMinCtrl.clear();
    _defMaxCtrl.clear();
  }

  void _toggleStr(
    String v,
    Set<String> cur,
    _PickerFilter Function(Set<String>) upd,
  ) {
    final s = Set<String>.from(cur);
    s.contains(v) ? s.remove(v) : s.add(v);
    final next = upd(s);
    setState(() => _draft = next);
    widget.onApply(next);
  }

  void _toggleInt(int v, Set<int> cur, _PickerFilter Function(Set<int>) upd) {
    final s = Set<int>.from(cur);
    s.contains(v) ? s.remove(v) : s.add(v);
    final next = upd(s);
    setState(() => _draft = next);
    widget.onApply(next);
  }

  @override
  Widget build(BuildContext context) {
    final idx = widget.filterIndex;
    return Column(
      children: [
        // Handle
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: AppTheme.textMuted,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 12, 0),
          child: Row(
            children: [
              const Text(
                'Filter Cards',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (_draft.hasActive)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_draft.activeCount}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              TextButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.filter_alt_off, size: 16),
                label: const Text('Reset'),
              ),
            ],
          ),
        ),
        const Divider(color: AppTheme.bgBorder, height: 8),

        // Content
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            children: [
              // ── Card Type ──────────────────────────────────────────
              _FilterSection(
                title: 'Card Type',
                count: _draft.frameTypes.length,
              ),
              _ChipGroup<String>(
                items: idx.frameTypes,
                selected: _draft.frameTypes,
                onToggle: (v) => _toggleStr(
                  v,
                  _draft.frameTypes,
                  (s) => _draft.copyWith(frameTypes: s),
                ),
              ),
              const SizedBox(height: 16),

              // ── Attribute ──────────────────────────────────────────
              _FilterSection(
                title: 'Attribute',
                count: _draft.attributes.length,
              ),
              _ChipGroup<String>(
                items: idx.attributes,
                selected: _draft.attributes,
                onToggle: (v) => _toggleStr(
                  v,
                  _draft.attributes,
                  (s) => _draft.copyWith(attributes: s),
                ),
                colorBuilder: _attributeChipColor,
              ),
              const SizedBox(height: 16),

              // ── Race ───────────────────────────────────────────────
              _FilterSection(title: 'Race / Type', count: _draft.races.length),
              _ChipGroup<String>(
                items: idx.races,
                selected: _draft.races,
                onToggle: (v) => _toggleStr(
                  v,
                  _draft.races,
                  (s) => _draft.copyWith(races: s),
                ),
              ),
              const SizedBox(height: 16),

              // ── Level ──────────────────────────────────────────────
              _FilterSection(
                title: 'Level / Rank',
                count: _draft.levels.length,
              ),
              _ChipGroup<int>(
                items: idx.levels,
                selected: _draft.levels,
                itemLabel: (v) => '★$v',
                onToggle: (v) => _toggleInt(
                  v,
                  _draft.levels,
                  (s) => _draft.copyWith(levels: s),
                ),
              ),
              const SizedBox(height: 16),

              // ── Archetype ──────────────────────────────────────────
              _FilterSection(
                title: 'Archetype',
                count: _draft.archetype != null ? 1 : 0,
              ),
              DropdownButtonFormField<String>(
                value: _draft.archetype,
                decoration: _pickerInputDecoration('Archetype'),
                isExpanded: true,
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('All'),
                  ),
                  ...idx.archetypes.map(
                    (a) => DropdownMenuItem(
                      value: a,
                      child: Text(a, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: (v) {
                  final next = _draft.copyWith(archetype: v);
                  setState(() => _draft = next);
                  widget.onApply(next);
                },
              ),
              const SizedBox(height: 16),

              // ── ATK Range ──────────────────────────────────────────
              _FilterSection(
                title: 'ATK Range',
                count: (_draft.atkMin != null || _draft.atkMax != null) ? 1 : 0,
              ),
              _RangeRow(
                minCtrl: _atkMinCtrl,
                maxCtrl: _atkMaxCtrl,
                onChanged: (min, max) {
                  final next = _draft.copyWith(atkMin: min, atkMax: max);
                  setState(() => _draft = next);
                  widget.onApply(next);
                },
              ),
              const SizedBox(height: 16),

              // ── DEF Range ──────────────────────────────────────────
              _FilterSection(
                title: 'DEF Range',
                count: (_draft.defMin != null || _draft.defMax != null) ? 1 : 0,
              ),
              _RangeRow(
                minCtrl: _defMinCtrl,
                maxCtrl: _defMaxCtrl,
                onChanged: (min, max) {
                  final next = _draft.copyWith(defMin: min, defMax: max);
                  setState(() => _draft = next);
                  widget.onApply(next);
                },
              ),
              const SizedBox(height: 16),

              // ── TCG Rarity ─────────────────────────────────────────
              _FilterSection(
                title: 'TCG Rarity',
                count: _draft.tcgRarities.length,
              ),
              _ChipGroup<String>(
                items: idx.tcgRarities,
                selected: _draft.tcgRarities,
                onToggle: (v) => _toggleStr(
                  v,
                  _draft.tcgRarities,
                  (s) => _draft.copyWith(tcgRarities: s),
                ),
                colorBuilder: _rarityChipColor,
              ),
              const SizedBox(height: 16),

              // ── Banlist ────────────────────────────────────────────
              _FilterSection(
                title: 'Banlist',
                count: _draft.banlistStatuses.length,
              ),
              _ChipGroup<String>(
                items: const ['Forbidden', 'Limited', 'Semi-Limited'],
                selected: _draft.banlistStatuses,
                onToggle: (v) => _toggleStr(
                  v,
                  _draft.banlistStatuses,
                  (s) => _draft.copyWith(banlistStatuses: s),
                ),
                colorBuilder: _banlistChipColor,
              ),
              const SizedBox(height: 16),

              // ── Format ─────────────────────────────────────────────
              _FilterSection(title: 'Format', count: _draft.formats.length),
              _ChipGroup<String>(
                items: const ['TCG', 'OCG', 'Master Duel', 'GOAT'],
                selected: _draft.formats,
                onToggle: (v) => _toggleStr(
                  v,
                  _draft.formats,
                  (s) => _draft.copyWith(formats: s),
                ),
              ),
              const SizedBox(height: 16),

              // ── Sort ───────────────────────────────────────────────
              _FilterSection(title: 'Sort By', count: 0),
              _SortRow(
                sortBy: _draft.sortBy,
                ascending: _draft.sortAscending,
                onSortChanged: (v) {
                  final next = _draft.copyWith(sortBy: v);
                  setState(() => _draft = next);
                  widget.onApply(next);
                },
                onDirectionToggle: () {
                  final next = _draft.copyWith(
                    sortAscending: !_draft.sortAscending,
                  );
                  setState(() => _draft = next);
                  widget.onApply(next);
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),

        // Done button — filter đã apply real-time, chỉ cần đóng sheet
        Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            MediaQuery.of(context).padding.bottom + 16,
          ),
          child: FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(
              backgroundColor: _draft.hasActive
                  ? AppTheme.accent
                  : AppTheme.bgElevated,
              foregroundColor: _draft.hasActive
                  ? Colors.black
                  : AppTheme.textSecondary,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _draft.hasActive ? 'Done (${_draft.activeCount} active)' : 'Done',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Reusable filter sub-widgets ────────────────────────────────────────────────

class _FilterSection extends StatelessWidget {
  final String title;
  final int count;
  const _FilterSection({required this.title, this.count = 0});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: AppTheme.accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: AppTheme.accent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChipGroup<T> extends StatelessWidget {
  final List<T> items;
  final Set<T> selected;
  final void Function(T) onToggle;
  final String Function(T)? itemLabel;
  final Color Function(T)? colorBuilder;

  const _ChipGroup({
    required this.items,
    required this.selected,
    required this.onToggle,
    this.itemLabel,
    this.colorBuilder,
  });

  String _label(T item) =>
      itemLabel != null ? itemLabel!(item) : item.toString();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: items.map((item) {
        final active = selected.contains(item);
        final color = colorBuilder?.call(item) ?? AppTheme.accent;
        return GestureDetector(
          onTap: () => onToggle(item),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 130),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: active
                  ? color.withValues(alpha: 0.18)
                  : AppTheme.bgElevated,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: active ? color : AppTheme.bgBorder,
                width: active ? 1.5 : 1,
              ),
            ),
            child: Text(
              _label(item),
              style: TextStyle(
                fontSize: 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.normal,
                color: active ? color : AppTheme.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _RangeRow extends StatelessWidget {
  final TextEditingController minCtrl;
  final TextEditingController maxCtrl;
  final void Function(int? min, int? max) onChanged;

  const _RangeRow({
    required this.minCtrl,
    required this.maxCtrl,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: minCtrl,
            decoration: _pickerInputDecoration('Min'),
            keyboardType: TextInputType.number,
            onChanged: (v) =>
                onChanged(int.tryParse(v), int.tryParse(maxCtrl.text)),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '–',
            style: TextStyle(fontSize: 16, color: AppTheme.textMuted),
          ),
        ),
        Expanded(
          child: TextField(
            controller: maxCtrl,
            decoration: _pickerInputDecoration('Max'),
            keyboardType: TextInputType.number,
            onChanged: (v) =>
                onChanged(int.tryParse(minCtrl.text), int.tryParse(v)),
          ),
        ),
      ],
    );
  }
}

class _SortRow extends StatelessWidget {
  final SortOption sortBy;
  final bool ascending;
  final ValueChanged<SortOption> onSortChanged;
  final VoidCallback onDirectionToggle;

  const _SortRow({
    required this.sortBy,
    required this.ascending,
    required this.onSortChanged,
    required this.onDirectionToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<SortOption>(
            value: sortBy,
            decoration: _pickerInputDecoration('Sort'),
            items: SortOption.values
                .map((o) => DropdownMenuItem(value: o, child: Text(o.label)))
                .toList(),
            onChanged: (v) {
              if (v != null) onSortChanged(v);
            },
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(
            ascending ? Icons.arrow_upward : Icons.arrow_downward,
            color: AppTheme.accent,
          ),
          onPressed: onDirectionToggle,
          tooltip: ascending ? 'Ascending' : 'Descending',
        ),
      ],
    );
  }
}

InputDecoration _pickerInputDecoration(String label) => InputDecoration(
  labelText: label,
  labelStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
  filled: true,
  fillColor: AppTheme.bgElevated,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: AppTheme.bgBorder),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: AppTheme.bgBorder),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: AppTheme.accent, width: 1.5),
  ),
  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  isDense: true,
);

// ── Color helpers ──────────────────────────────────────────────────────────────

Color _attributeChipColor(String attr) => AppTheme.getAttributeColor(attr);

Color _rarityChipColor(String code) => AppTheme.getTcgRarityColor(code);

Color _banlistChipColor(String status) => AppTheme.getBanlistColor(status);
