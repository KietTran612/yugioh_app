import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/card_model.dart';
import '../models/deck_model.dart';
import '../providers/card_provider.dart';
import '../providers/deck_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/deck_zone_widgets.dart';
import 'card_detail_screen.dart';
import 'card_picker_screen.dart';
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
    final cardDataAsync = ref.watch(cardDataProvider);
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
        data: (cards) {
          final cardMap =
              cardDataAsync
                  .whenData(
                    (data) => <int, YugiohCard>{
                      for (final c in data.cards) c.id: c,
                    },
                  )
                  .valueOrNull ??
              {};
          final errors = deck.validateWithCards(cardMap);
          return _DeckBody(deck: deck, cards: cards, errors: errors, ref: ref);
        },
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

// ── Deck body ─────────────────────────────────────────────────────────────────

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

  void _openPicker(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CardPickerScreen(deckId: deck.id)),
    );
  }

  void _onCardTap(BuildContext context, YugiohCard card) {
    tabPush(
      context,
      MaterialPageRoute(builder: (_) => CardDetailScreen(card: card)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cfg = deck.config;

    return CustomScrollView(
      slivers: [
        // Stats bar
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppTheme.bgCard,
            child: Row(
              children: [
                DeckStatPill(
                  label: 'Main ${deck.mainDeck.length}/${cfg.mainMax}',
                  color:
                      deck.mainDeck.length >= cfg.mainMin &&
                          deck.mainDeck.length <= cfg.mainMax
                      ? AppTheme.accent
                      : const Color(0xFFE74C3C),
                ),
                const SizedBox(width: 8),
                DeckStatPill(
                  label: 'Extra ${deck.extraDeck.length}/${cfg.extraMax}',
                  color: AppTheme.accentGold,
                ),
                if (cfg.hasSide) ...[
                  const SizedBox(width: 8),
                  DeckStatPill(
                    label: 'Side ${deck.sideDeck.length}/${cfg.sideMax}',
                    color: AppTheme.textSecondary,
                  ),
                ],
              ],
            ),
          ),
        ),

        // Validation errors
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
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 1),
                              child: Icon(
                                Icons.warning_amber_rounded,
                                size: 14,
                                color: Color(0xFFE74C3C),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(child: DeckErrorText(message: e)),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),

        // Main Deck
        DeckCardZoneSection(
          title: 'Main Deck',
          count: deck.mainDeck.length,
          maxCount: cfg.mainMax,
          cards: cards.main,
          deckId: deck.id,
          zone: DeckZone.main,
          deckFormat: deck.format,
          ref: ref,
          onOpenPicker: () => _openPicker(context),
          onCardTap: _onCardTap,
        ),

        // Extra Deck
        DeckCardZoneSection(
          title: 'Extra Deck',
          count: deck.extraDeck.length,
          maxCount: cfg.extraMax,
          cards: cards.extra,
          deckId: deck.id,
          zone: DeckZone.extra,
          deckFormat: deck.format,
          ref: ref,
          onOpenPicker: () => _openPicker(context),
          onCardTap: _onCardTap,
        ),

        // Side Deck
        if (cfg.hasSide)
          DeckCardZoneSection(
            title: 'Side Deck',
            count: deck.sideDeck.length,
            maxCount: cfg.sideMax,
            cards: cards.side,
            deckId: deck.id,
            zone: DeckZone.side,
            deckFormat: deck.format,
            ref: ref,
            onOpenPicker: () => _openPicker(context),
            onCardTap: _onCardTap,
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }
}
