import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/card_model.dart';
import '../models/deck_model.dart';
import '../providers/deck_provider.dart';
import '../utils/app_theme.dart';
import 'card_image.dart';

// ── Stat pill ─────────────────────────────────────────────────────────────────

class DeckStatPill extends StatelessWidget {
  final String label;
  final Color color;
  const DeckStatPill({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Error text ────────────────────────────────────────────────────────────────
// Format: "\x00CardName\x00warning message" → card name white, warning red.

class DeckErrorText extends StatelessWidget {
  final String message;
  const DeckErrorText({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    if (message.startsWith('\x00')) {
      final parts = message.substring(1).split('\x00');
      final cardName = parts.isNotEmpty ? parts[0] : '';
      final warning = parts.length > 1 ? parts[1] : '';
      return RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: cardName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const TextSpan(text: '  '),
            TextSpan(
              text: warning,
              style: TextStyle(
                color: const Color(0xFFE74C3C).withValues(alpha: 0.85),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }
    return Text(
      message,
      style: const TextStyle(color: Color(0xFFE74C3C), fontSize: 12),
    );
  }
}

// ── Banlist badge ─────────────────────────────────────────────────────────────

class DeckBanlistBadge extends StatelessWidget {
  final BanlistStatus status;
  const DeckBanlistBadge({super.key, required this.status});

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

// ── Card zone section ─────────────────────────────────────────────────────────

class DeckCardZoneSection extends StatelessWidget {
  final String title;
  final int count;
  final int maxCount;
  final List<YugiohCard> cards;
  final String deckId;
  final DeckZone zone;
  final DeckFormat deckFormat;
  final WidgetRef ref;
  final VoidCallback onOpenPicker;
  final void Function(BuildContext, YugiohCard) onCardTap;

  const DeckCardZoneSection({
    super.key,
    required this.title,
    required this.count,
    required this.maxCount,
    required this.cards,
    required this.deckId,
    required this.zone,
    required this.deckFormat,
    required this.ref,
    required this.onOpenPicker,
    required this.onCardTap,
  });

  Color get _zoneColor {
    switch (zone) {
      case DeckZone.main:
        return AppTheme.accent;
      case DeckZone.extra:
        return AppTheme.accentGold;
      case DeckZone.side:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Row(
              children: [
                Container(
                  width: 3,
                  height: 16,
                  decoration: BoxDecoration(
                    color: _zoneColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.bgElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.bgBorder),
                  ),
                  child: Text(
                    '$count/$maxCount',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onOpenPicker,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _zoneColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _zoneColor.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Icon(Icons.add_rounded, size: 16, color: _zoneColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (cards.isEmpty)
              _EmptyZone(zoneColor: _zoneColor, onTap: onOpenPicker)
            else
              DeckCardGrid(
                cards: cards,
                deckId: deckId,
                zone: zone,
                deckFormat: deckFormat,
                ref: ref,
                onCardTap: onCardTap,
              ),
          ],
        ),
      ),
    );
  }
}

// ── Empty zone placeholder ────────────────────────────────────────────────────

class _EmptyZone extends StatelessWidget {
  final Color zoneColor;
  final VoidCallback onTap;
  const _EmptyZone({required this.zoneColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.bgBorder),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: zoneColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: zoneColor.withValues(alpha: 0.3)),
              ),
              child: Icon(Icons.add_rounded, size: 28, color: zoneColor),
            ),
            const SizedBox(height: 10),
            Text(
              'Tap to add cards',
              style: TextStyle(
                color: zoneColor.withValues(alpha: 0.8),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Browse and search all cards',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Card grid in deck ─────────────────────────────────────────────────────────

class DeckCardGrid extends StatelessWidget {
  final List<YugiohCard> cards;
  final String deckId;
  final DeckZone zone;
  final DeckFormat deckFormat;
  final WidgetRef ref;
  final void Function(BuildContext, YugiohCard) onCardTap;

  const DeckCardGrid({
    super.key,
    required this.cards,
    required this.deckId,
    required this.zone,
    required this.deckFormat,
    required this.ref,
    required this.onCardTap,
  });

  /// Master Duel: max(TCG, OCG). Duel Links: OCG.
  BanlistStatus? _getBanlistStatus(YugiohCard card) {
    final banlist = card.misc?.banlist;
    if (banlist == null) return null;
    switch (deckFormat) {
      case DeckFormat.masterDuel:
        final tcg = banlist.tcg;
        final ocg = banlist.ocg;
        if (tcg == null) return ocg;
        if (ocg == null) return tcg;
        return tcg.index <= ocg.index ? tcg : ocg;
      case DeckFormat.duelLinks:
        return banlist.ocg;
    }
  }

  void _showRemoveDialog(BuildContext context, YugiohCard card, int count) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              card.name,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '$count cop${count > 1 ? 'ies' : 'y'} in deck',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(
                Icons.remove_circle_outline_rounded,
                color: Color(0xFFE74C3C),
              ),
              title: const Text(
                'Remove 1 copy',
                style: TextStyle(color: AppTheme.textPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                ref
                    .read(deckProvider.notifier)
                    .removeCard(deckId, card.id, zone);
              },
            ),
            if (count > 1)
              ListTile(
                leading: const Icon(
                  Icons.delete_sweep_rounded,
                  color: Color(0xFFE74C3C),
                ),
                title: Text(
                  'Remove all $count copies',
                  style: const TextStyle(color: AppTheme.textPrimary),
                ),
                onTap: () {
                  Navigator.pop(context);
                  for (var i = 0; i < count; i++) {
                    ref
                        .read(deckProvider.notifier)
                        .removeCard(deckId, card.id, zone);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 10;
    if (width > 800) return 8;
    if (width > 600) return 6;
    return 5;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = <int, List<YugiohCard>>{};
    for (final c in cards) {
      grouped.putIfAbsent(c.id, () => []).add(c);
    }
    final unique = grouped.entries.toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _getCrossAxisCount(context),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.69,
      ),
      itemCount: unique.length,
      itemBuilder: (context, i) {
        final entry = unique[i];
        final card = entry.value.first;
        final count = entry.value.length;
        final banlistStatus = _getBanlistStatus(card);

        return GestureDetector(
          onTap: () => onCardTap(context, card),
          onLongPress: () => _showRemoveDialog(context, card, count),
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
              if (count > 1)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppTheme.accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.bgDeep, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        'x$count',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              if (banlistStatus != null)
                Positioned(
                  top: 4,
                  left: 4,
                  child: DeckBanlistBadge(status: banlistStatus),
                ),
            ],
          ),
        );
      },
    );
  }
}
