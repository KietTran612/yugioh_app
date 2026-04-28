import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
          IconButton(
            icon: const Icon(Icons.upload_rounded, size: 20),
            color: AppTheme.textSecondary,
            tooltip: 'Export YDK',
            onPressed: () => _showExportSheet(context, deck),
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

  void _showExportSheet(BuildContext context, Deck deck) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ExportSheet(deck: deck),
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

// ── Export sheet ──────────────────────────────────────────────────────────────

class _ExportSheet extends StatefulWidget {
  final Deck deck;
  const _ExportSheet({required this.deck});

  @override
  State<_ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends State<_ExportSheet> {
  bool _copied = false;

  String get _ydkText => widget.deck.toYdk();

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: _ydkText));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final deck = widget.deck;
    final totalCards =
        deck.mainDeck.length + deck.extraDeck.length + deck.sideDeck.length;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) => Column(
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
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              children: [
                const Icon(
                  Icons.upload_rounded,
                  color: AppTheme.accent,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Export YDK',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${deck.name} · $totalCards cards',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: AppTheme.bgBorder, height: 1),

          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              children: [
                // How to import guide
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.accent.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 14,
                            color: AppTheme.accent,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'How to import into Master Duel',
                            style: TextStyle(
                              color: AppTheme.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ..._steps([
                        'Copy the YDK code below',
                        'Open db.yugioh-card.com in a browser',
                        'Log in → My Deck → New Deck or edit existing',
                        'Install the "Deck Transfer for Master Duel" browser extension',
                        'Use the Import button injected by the extension to paste your YDK',
                        'Save the deck on the official database',
                        'In Master Duel: Deck → Sync with Official Database',
                      ]),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Deck stats row
                Row(
                  children: [
                    _StatChip(
                      label: 'Main',
                      count: deck.mainDeck.length,
                      color: AppTheme.accent,
                    ),
                    const SizedBox(width: 8),
                    _StatChip(
                      label: 'Extra',
                      count: deck.extraDeck.length,
                      color: AppTheme.accentGold,
                    ),
                    if (deck.config.hasSide) ...[
                      const SizedBox(width: 8),
                      _StatChip(
                        label: 'Side',
                        count: deck.sideDeck.length,
                        color: AppTheme.textSecondary,
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 16),

                // YDK preview
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.bgDeep,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.bgBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Preview header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                        child: Row(
                          children: [
                            const Text(
                              'YDK Preview',
                              style: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${_ydkText.split('\n').length} lines',
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(color: AppTheme.bgBorder, height: 1),
                      // Scrollable YDK text
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(14),
                          child: SelectableText(
                            _ydkText,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                              fontFamily: 'monospace',
                              height: 1.6,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),

          // Copy button
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              8,
              20,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            child: FilledButton.icon(
              onPressed: _copyToClipboard,
              icon: Icon(
                _copied ? Icons.check_rounded : Icons.copy_rounded,
                size: 18,
              ),
              label: Text(
                _copied ? 'Copied!' : 'Copy YDK to Clipboard',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: _copied
                    ? const Color(0xFF27AE60)
                    : AppTheme.accent,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _steps(List<String> steps) {
    return steps.asMap().entries.map((entry) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 18,
              height: 18,
              margin: const EdgeInsets.only(top: 1),
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${entry.key + 1}',
                  style: const TextStyle(
                    color: AppTheme.accent,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                entry.value,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
