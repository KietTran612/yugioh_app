import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/card_model.dart';
import '../models/deck_model.dart';
import '../providers/deck_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/card_image.dart';
import 'card_detail_screen.dart';
import 'main_shell.dart' show tabPush;

class DeckDetailScreen extends ConsumerWidget {
  final String deckId;
  const DeckDetailScreen({super.key, required this.deckId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decks = ref.watch(deckProvider);
    final deck = decks.where((d) => d.id == deckId).firstOrNull;

    if (deck == null) {
      return Scaffold(
        backgroundColor: AppTheme.bgDeep,
        appBar: AppBar(title: const Text('Deck')),
        body: const Center(
          child: Text(
            'Deck not found',
            style: TextStyle(color: AppTheme.textMuted),
          ),
        ),
      );
    }

    final deckCardsAsync = ref.watch(deckCardsProvider(deckId));
    final errors = deck.validate();
    final cfg = deck.config;

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDeep,
        foregroundColor: AppTheme.textPrimary,
        title: Text(
          deck.name,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          // Format badge
          Container(
            margin: const EdgeInsets.only(right: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.accent.withValues(alpha: 0.4)),
            ),
            child: Text(
              cfg.shortLabel,
              style: const TextStyle(
                color: AppTheme.accent,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          // Rename
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            color: AppTheme.textSecondary,
            onPressed: () => _showRenameDialog(context, ref, deck),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.bgBorder),
        ),
      ),
      body: deckCardsAsync.when(
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
        data: (cards) =>
            _DeckBody(deck: deck, cards: cards, errors: errors, ref: ref),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref, Deck deck) {
    final controller = TextEditingController(text: deck.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        title: const Text(
          'Rename Deck',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(hintText: 'Deck name'),
          onSubmitted: (_) {
            final name = controller.text.trim();
            if (name.isNotEmpty) {
              ref.read(deckProvider.notifier).renameDeck(deck.id, name);
            }
            Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                ref.read(deckProvider.notifier).renameDeck(deck.id, name);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// ── Deck body ──────────────────────────────────────────────────────────────────

class _DeckBody extends StatelessWidget {
  final Deck deck;
  final DeckCards cards;
  final List<String> errors;
  final WidgetRef ref;

  const _DeckBody({
    required this.deck,
    required this.cards,
    required this.errors,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final cfg = deck.config;

    return CustomScrollView(
      slivers: [
        // ── Stats bar ──────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppTheme.bgCard,
            child: Row(
              children: [
                _StatPill(
                  label: 'Main ${deck.mainDeck.length}/${cfg.mainMax}',
                  color:
                      deck.mainDeck.length >= cfg.mainMin &&
                          deck.mainDeck.length <= cfg.mainMax
                      ? AppTheme.accent
                      : const Color(0xFFE74C3C),
                ),
                const SizedBox(width: 8),
                _StatPill(
                  label: 'Extra ${deck.extraDeck.length}/${cfg.extraMax}',
                  color: AppTheme.accentGold,
                ),
                if (cfg.hasSide) ...[
                  const SizedBox(width: 8),
                  _StatPill(
                    label: 'Side ${deck.sideDeck.length}/${cfg.sideMax}',
                    color: AppTheme.textSecondary,
                  ),
                ],
              ],
            ),
          ),
        ),

        // ── Validation errors ──────────────────────────────────────────
        if (errors.isNotEmpty)
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE74C3C).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFE74C3C).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: errors
                    .map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              size: 14,
                              color: Color(0xFFE74C3C),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                e,
                                style: const TextStyle(
                                  color: Color(0xFFE74C3C),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),

        // ── Main Deck ──────────────────────────────────────────────────
        _CardZoneSection(
          title: 'Main Deck',
          count: deck.mainDeck.length,
          maxCount: cfg.mainMax,
          cards: cards.main,
          deckId: deck.id,
          zone: DeckZone.main,
          ref: ref,
        ),

        // ── Extra Deck ─────────────────────────────────────────────────
        if (deck.extraDeck.isNotEmpty || true)
          _CardZoneSection(
            title: 'Extra Deck',
            count: deck.extraDeck.length,
            maxCount: cfg.extraMax,
            cards: cards.extra,
            deckId: deck.id,
            zone: DeckZone.extra,
            ref: ref,
          ),

        // ── Side Deck ──────────────────────────────────────────────────
        if (cfg.hasSide)
          _CardZoneSection(
            title: 'Side Deck',
            count: deck.sideDeck.length,
            maxCount: cfg.sideMax,
            cards: cards.side,
            deckId: deck.id,
            zone: DeckZone.side,
            ref: ref,
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }
}

// ── Card zone section ──────────────────────────────────────────────────────────

class _CardZoneSection extends StatelessWidget {
  final String title;
  final int count;
  final int maxCount;
  final List<YugiohCard> cards;
  final String deckId;
  final DeckZone zone;
  final WidgetRef ref;

  const _CardZoneSection({
    required this.title,
    required this.count,
    required this.maxCount,
    required this.cards,
    required this.deckId,
    required this.zone,
    required this.ref,
  });

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
              ],
            ),
            const SizedBox(height: 12),

            // Card grid or empty
            if (cards.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.bgBorder,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.add_circle_outline_rounded,
                      size: 32,
                      color: AppTheme.textMuted,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No cards yet',
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Add cards from card detail screen',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              )
            else
              _CardGrid(cards: cards, deckId: deckId, zone: zone, ref: ref),
          ],
        ),
      ),
    );
  }

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
}

// ── Card grid in deck ──────────────────────────────────────────────────────────

class _CardGrid extends StatelessWidget {
  final List<YugiohCard> cards;
  final String deckId;
  final DeckZone zone;
  final WidgetRef ref;

  const _CardGrid({
    required this.cards,
    required this.deckId,
    required this.zone,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    // Group cards by id to show count badge
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

        return GestureDetector(
          onTap: () => tabPush(
            context,
            MaterialPageRoute(builder: (_) => CardDetailScreen(card: card)),
          ),
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
              // Count badge
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
            ],
          ),
        );
      },
    );
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
}

// ── Stat pill ──────────────────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatPill({required this.label, required this.color});

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
