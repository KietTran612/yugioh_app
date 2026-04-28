import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/card_model.dart';
import '../models/deck_model.dart';
import '../providers/deck_provider.dart';
import '../utils/app_theme.dart';
import 'card_image.dart';

/// Bottom sheet để add/remove card vào một deck cụ thể.
/// Dùng chung từ CardPickerScreen và bất kỳ nơi nào cần.
class QuickAddSheet extends ConsumerStatefulWidget {
  final YugiohCard card;
  final Deck deck;

  /// Zone ưu tiên (pre-select tab). Nếu null thì tự detect theo card type.
  final DeckZone? preferredZone;

  const QuickAddSheet({
    super.key,
    required this.card,
    required this.deck,
    this.preferredZone,
  });

  @override
  ConsumerState<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends ConsumerState<QuickAddSheet> {
  late DeckZone _zone;

  // Số copy user muốn có trong từng zone
  int? _mainValue;
  int? _extraValue;
  int? _sideValue;

  bool get _isExtraCard =>
      widget.card.isFusion ||
      widget.card.isSynchro ||
      widget.card.isXyz ||
      widget.card.isLink;

  @override
  void initState() {
    super.initState();
    // Chọn zone mặc định
    if (widget.preferredZone != null) {
      _zone = widget.preferredZone!;
    } else {
      _zone = _isExtraCard ? DeckZone.extra : DeckZone.main;
    }
  }

  @override
  Widget build(BuildContext context) {
    final decks = ref.watch(deckProvider);
    final deck = decks.firstWhere(
      (d) => d.id == widget.deck.id,
      orElse: () => widget.deck,
    );
    final cfg = deck.config;

    // Counts hiện tại
    final mainCount = deck.mainDeck.where((id) => id == widget.card.id).length;
    final extraCount = deck.extraDeck
        .where((id) => id == widget.card.id)
        .length;
    final sideCount = deck.sideDeck.where((id) => id == widget.card.id).length;

    _mainValue ??= mainCount;
    _extraValue ??= extraCount;
    _sideValue ??= sideCount;

    // Zones available cho card này
    final availableZones = _availableZones(cfg);

    // Nếu zone hiện tại không available, reset về zone đầu tiên
    if (!availableZones.contains(_zone)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _zone = availableZones.first);
      });
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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

          // Card info
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: CardNetworkImage(
                    imageUrl: widget.card.imageUrl,
                    width: 44,
                    height: 64,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.card.name,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.card.type,
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        deck.name,
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Zone tabs (chỉ hiện nếu có nhiều hơn 1 zone)
          if (availableZones.length > 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: availableZones.map((z) {
                  final isActive = _zone == z;
                  final color = _zoneColor(z);
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _zone = z),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isActive
                              ? color.withValues(alpha: 0.15)
                              : AppTheme.bgElevated,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isActive ? color : AppTheme.bgBorder,
                            width: isActive ? 1.5 : 1,
                          ),
                        ),
                        child: Text(
                          _zoneLabel(z),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isActive ? color : AppTheme.textSecondary,
                            fontSize: 12,
                            fontWeight: isActive
                                ? FontWeight.w700
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

          // Stepper for active zone
          _buildZoneStepper(deck, cfg, mainCount, extraCount, sideCount),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// Số copy tối đa — luôn là 3, banlist chỉ hiển thị warning, không block.
  int _maxAllowedCopies(Deck deck) => 3;

  /// Trả về warning nếu [value] vi phạm giới hạn banlist.
  /// Luôn show warning cho Forbidden (dù value = 0 cũng không nên có trong deck).
  String? _banlistWarning(Deck deck, int value) {
    final (status, source) = _effectiveStatusWithSource(deck);
    final src = source != null ? ' ($source)' : '';
    switch (status) {
      case BanlistStatus.forbidden:
        return 'Forbidden in ${deck.config.label}$src';
      case BanlistStatus.limited:
        if (value > 1) return 'Limited — max 1 copy (you have $value)$src';
        return null;
      case BanlistStatus.semiLimited:
        if (value > 2)
          return 'Semi-Limited — max 2 copies (you have $value)$src';
        return null;
      default:
        return null;
    }
  }

  Color _banlistWarningColor(Deck deck) {
    final (status, _) = _effectiveStatusWithSource(deck);
    switch (status) {
      case BanlistStatus.forbidden:
        return AppTheme.getBanlistColor('Forbidden');
      case BanlistStatus.limited:
        return AppTheme.getBanlistColor('Limited');
      case BanlistStatus.semiLimited:
        return AppTheme.getBanlistColor('Semi-Limited');
      default:
        return AppTheme.textMuted;
    }
  }

  /// Lấy status nghiêm nhất + nguồn luật để hiển thị trong warning.
  /// Master Duel = max(TCG, OCG) — API không có ban_md riêng.
  /// Duel Links = OCG.
  (BanlistStatus?, String?) _effectiveStatusWithSource(Deck deck) {
    final b = widget.card.misc?.banlist;
    if (b == null) return (null, null);

    if (deck.format == DeckFormat.masterDuel) {
      final tcg = b.tcg;
      final ocg = b.ocg;
      if (tcg == null && ocg == null) return (null, null);
      if (tcg == null) return (ocg, 'OCG');
      if (ocg == null) return (tcg, 'TCG');
      // Cả hai đều có — lấy nghiêm hơn, ghi rõ nguồn
      if (tcg.index < ocg.index) return (tcg, 'TCG');
      if (ocg.index < tcg.index) return (ocg, 'OCG');
      return (tcg, 'TCG+OCG'); // cùng mức
    }

    // Duel Links
    return (b.ocg, b.ocg != null ? 'OCG' : null);
  }

  Widget _buildZoneStepper(
    Deck deck,
    DeckFormatConfig cfg,
    int mainCount,
    int extraCount,
    int sideCount,
  ) {
    int currentCount;
    int deckSize;
    int maxDeck;
    int value;

    switch (_zone) {
      case DeckZone.main:
        currentCount = mainCount;
        deckSize = deck.mainDeck.length;
        maxDeck = cfg.mainMax;
        value = _mainValue!;
        break;
      case DeckZone.extra:
        currentCount = extraCount;
        deckSize = deck.extraDeck.length;
        maxDeck = cfg.extraMax;
        value = _extraValue!;
        break;
      case DeckZone.side:
        currentCount = sideCount;
        deckSize = deck.sideDeck.length;
        maxDeck = cfg.sideMax;
        value = _sideValue!;
        break;
    }

    final canIncrease = value < _maxAllowedCopies(deck) && deckSize < maxDeck;
    final canDecrease = value > 0;
    final isDirty = value != currentCount;
    final color = _zoneColor(_zone);

    void setVal(int v) => setState(() {
      switch (_zone) {
        case DeckZone.main:
          _mainValue = v;
          break;
        case DeckZone.extra:
          _extraValue = v;
          break;
        case DeckZone.side:
          _sideValue = v;
          break;
      }
    });

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Row(
        children: [
          // Zone info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_zoneLabel(_zone)}: $deckSize/$maxDeck',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                // Banlist warning — chỉ hiện khi value vi phạm ngưỡng
                if (_banlistWarning(deck, value) != null)
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 11,
                        color: _banlistWarningColor(deck),
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          _banlistWarning(deck, value)!,
                          style: TextStyle(
                            color: _banlistWarningColor(deck),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                if (isDirty)
                  Text(
                    value > currentCount
                        ? '+${value - currentCount} to add'
                        : '−${currentCount - value} to remove',
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),

          // Stepper
          Container(
            decoration: BoxDecoration(
              color: AppTheme.bgElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.bgBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StepBtn(
                  icon: Icons.remove_rounded,
                  enabled: canDecrease,
                  color: color,
                  onTap: () => setVal(value - 1),
                ),
                SizedBox(
                  width: 40,
                  child: Center(
                    child: Text(
                      '$value',
                      style: TextStyle(
                        color: isDirty ? color : AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                _StepBtn(
                  icon: Icons.add_rounded,
                  enabled: canIncrease,
                  color: color,
                  onTap: () => setVal(value + 1),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Save button
          FilledButton(
            onPressed: isDirty
                ? () => _save(context, currentCount, value)
                : null,
            style: FilledButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.black,
              disabledBackgroundColor: AppTheme.bgBorder,
              disabledForegroundColor: AppTheme.textMuted,
              minimumSize: const Size(80, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              isDirty ? 'Save' : 'Done',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  void _save(BuildContext context, int currentCount, int targetValue) {
    final diff = targetValue - currentCount;
    final notifier = ref.read(deckProvider.notifier);

    if (diff > 0) {
      String? error;
      for (var i = 0; i < diff; i++) {
        error = notifier.addCard(widget.deck.id, widget.card);
        if (error != null) break;
      }
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFE74C3C),
          ),
        );
        setState(() {
          switch (_zone) {
            case DeckZone.main:
              _mainValue = currentCount;
              break;
            case DeckZone.extra:
              _extraValue = currentCount;
              break;
            case DeckZone.side:
              _sideValue = currentCount;
              break;
          }
        });
        return;
      }
    } else if (diff < 0) {
      for (var i = 0; i < diff.abs(); i++) {
        notifier.removeCard(widget.deck.id, widget.card.id, _zone);
      }
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          diff > 0
              ? 'Added $diff cop${diff > 1 ? "ies" : "y"} of "${widget.card.name}"'
              : 'Removed ${diff.abs()} from "${widget.deck.name}"',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.accent.withValues(alpha: 0.9),
      ),
    );
  }

  List<DeckZone> _availableZones(DeckFormatConfig cfg) {
    final zones = <DeckZone>[];
    // Main: chỉ non-extra cards
    if (!_isExtraCard) zones.add(DeckZone.main);
    // Extra: chỉ extra cards
    if (_isExtraCard) zones.add(DeckZone.extra);
    // Side: tất cả, nhưng chỉ nếu deck có side
    if (cfg.hasSide) zones.add(DeckZone.side);
    return zones.isEmpty ? [DeckZone.main] : zones;
  }

  String _zoneLabel(DeckZone z) {
    switch (z) {
      case DeckZone.main:
        return 'Main Deck';
      case DeckZone.extra:
        return 'Extra Deck';
      case DeckZone.side:
        return 'Side Deck';
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

// ── Step button ────────────────────────────────────────────────────────────────

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final Color color;
  final VoidCallback onTap;

  const _StepBtn({
    required this.icon,
    required this.enabled,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? color : AppTheme.textMuted,
        ),
      ),
    );
  }
}
