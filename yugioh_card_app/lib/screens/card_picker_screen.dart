import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/card_model.dart';
import '../models/deck_model.dart';
import '../models/filter_state.dart';
import '../providers/card_provider.dart';
import '../providers/deck_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/card_image.dart';
import '../widgets/card_picker_sheet.dart';
import '../widgets/picker_filter_sheet.dart';

// ── Hard-filter helpers ───────────────────────────────────────────────────────

/// Returns true if the card is valid for the given zone.
bool cardValidForZone(YugiohCard card, DeckZone zone) {
  final isExtra = card.isFusion || card.isSynchro || card.isXyz || card.isLink;
  switch (zone) {
    case DeckZone.main:
      return !isExtra;
    case DeckZone.extra:
      return isExtra;
    case DeckZone.side:
      return true;
  }
}

/// Returns true if the card is Forbidden in the deck's format.
/// Master Duel: checks both TCG and OCG (API has no ban_md).
bool cardForbidden(YugiohCard card, DeckFormat format) {
  final banlist = card.misc?.banlist;
  if (banlist == null) return false;
  switch (format) {
    case DeckFormat.masterDuel:
      return banlist.tcg == BanlistStatus.forbidden ||
          banlist.ocg == BanlistStatus.forbidden;
    case DeckFormat.duelLinks:
      return banlist.ocg == BanlistStatus.forbidden;
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

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
  PickerFilter _filter = const PickerFilter();
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

    // Zone validity
    if (_activeZone != null) {
      cards = cards.where((c) => cardValidForZone(c, _activeZone!)).toList();
    }

    // Search
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

    // Frame type
    if (_filter.frameTypes.isNotEmpty) {
      cards = cards
          .where((c) => _filter.frameTypes.contains(c.frameType))
          .toList();
    }
    // Attribute
    if (_filter.attributes.isNotEmpty) {
      cards = cards
          .where((c) => _filter.attributes.contains(c.attribute))
          .toList();
    }
    // Race
    if (_filter.races.isNotEmpty) {
      cards = cards.where((c) => _filter.races.contains(c.race)).toList();
    }
    // Level
    if (_filter.levels.isNotEmpty) {
      cards = cards
          .where((c) => c.level != null && _filter.levels.contains(c.level))
          .toList();
    }
    // Archetype
    if (_filter.archetype != null) {
      cards = cards.where((c) => c.archetype == _filter.archetype).toList();
    }
    // ATK
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
    // DEF
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
    // TCG Rarity
    if (_filter.tcgRarities.isNotEmpty) {
      cards = cards
          .where(
            (c) => c.sets.any(
              (s) => _filter.tcgRarities.contains(s.setRarityCode),
            ),
          )
          .toList();
    }
    // Banlist — resolve effectiveStatus per deck format
    if (_filter.banlistStatuses.isNotEmpty) {
      cards = cards.where((c) {
        final b = c.misc?.banlist;
        if (b == null) return false;
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
          effectiveStatus = b.ocg;
        }
        if (effectiveStatus == null) return false;
        return _filter.banlistStatuses.contains(effectiveStatus.label);
      }).toList();
    }
    // Format
    if (_filter.formats.isNotEmpty) {
      cards = cards.where((c) {
        final cardFormats = c.misc?.formats ?? [];
        return _filter.formats.every((f) => cardFormats.contains(f));
      }).toList();
    }

    // Sort
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
          // Zone selector
          _ZoneSelector(
            deck: deck,
            activeZone: _activeZone,
            onZoneChanged: (z) => setState(() {
              _activeZone = z;
              _displayCount = 50;
            }),
          ),

          // Search bar
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

          // Card grid
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
        builder: (_, controller) => PickerFilterSheet(
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

// ── Zone selector bar ─────────────────────────────────────────────────────────

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

// ── Card item ─────────────────────────────────────────────────────────────────

class _PickerCardItem extends ConsumerWidget {
  final YugiohCard card;
  final Deck deck;
  final DeckZone? activeZone;

  const _PickerCardItem({
    required this.card,
    required this.deck,
    required this.activeZone,
  });

  /// Master Duel: max(TCG, OCG). Duel Links: OCG.
  BanlistStatus? _banlistStatus() {
    final b = card.misc?.banlist;
    if (b == null) return null;
    if (deck.format == DeckFormat.masterDuel) {
      final tcg = b.tcg;
      final ocg = b.ocg;
      if (tcg == null) return ocg;
      if (ocg == null) return tcg;
      return tcg.index <= ocg.index ? tcg : ocg;
    }
    return b.ocg;
  }

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
    final isAtLimit = totalInDeck >= 3;
    final status = _banlistStatus();

    return GestureDetector(
      onTap: () => _showAddSheet(context),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: CardNetworkImage(
              imageUrl: card.imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),

          // Gradient + name
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

          // Side deck badge (top-left, only when no banlist badge)
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

          // Banlist badge (top-left)
          if (status != null)
            Positioned(
              top: 4,
              left: 4,
              child: _PickerBanlistBadge(status: status),
            ),

          // Dim overlay at copy limit
          if (isAtLimit)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: Colors.black.withValues(alpha: 0.5),
                ),
                child: const Center(
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white54,
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

// ── Banlist badge ─────────────────────────────────────────────────────────────

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

// ── Small helpers ─────────────────────────────────────────────────────────────

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
