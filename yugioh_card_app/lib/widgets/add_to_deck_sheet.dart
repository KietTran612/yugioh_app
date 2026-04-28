import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/card_model.dart';
import '../models/deck_model.dart';
import '../providers/deck_provider.dart';
import '../utils/app_theme.dart';

// ── Add to Deck button (AppBar action) ────────────────────────────────────────

class AddToDeckButton extends ConsumerWidget {
  final YugiohCard card;
  const AddToDeckButton({super.key, required this.card});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.library_add_rounded, size: 22),
      color: AppTheme.textSecondary,
      tooltip: 'Add to Deck',
      onPressed: () => _showAddToDeckSheet(context, ref),
    );
  }

  void _showAddToDeckSheet(BuildContext context, WidgetRef ref) {
    final decks = ref.read(deckProvider);
    if (decks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No decks yet — create one in the Collection tab'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddToDeckSheet(card: card),
    );
  }
}

// ── Add to Deck sheet ─────────────────────────────────────────────────────────

class AddToDeckSheet extends ConsumerWidget {
  final YugiohCard card;
  const AddToDeckSheet({super.key, required this.card});

  bool get _isExtraCard =>
      card.isFusion || card.isSynchro || card.isXyz || card.isLink;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decks = ref.watch(deckProvider);
    final mdDecks = decks
        .where((d) => d.format == DeckFormat.masterDuel)
        .toList();
    final dlDecks = decks
        .where((d) => d.format == DeckFormat.duelLinks)
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      expand: false,
      builder: (_, controller) => Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add to Deck',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  _isExtraCard ? 'Extra Deck card' : 'Main Deck card',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              children: [
                if (mdDecks.isNotEmpty) ...[
                  const _FormatHeader(label: 'Master Duel'),
                  ...mdDecks.map((d) => _DeckTile(deck: d, card: card)),
                ],
                if (dlDecks.isNotEmpty) ...[
                  const _FormatHeader(label: 'Duel Links'),
                  ...dlDecks.map((d) => _DeckTile(deck: d, card: card)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Format header ─────────────────────────────────────────────────────────────

class _FormatHeader extends StatelessWidget {
  final String label;
  const _FormatHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ── Deck tile with stepper ────────────────────────────────────────────────────

class _DeckTile extends ConsumerStatefulWidget {
  final Deck deck;
  final YugiohCard card;

  const _DeckTile({required this.deck, required this.card});

  @override
  ConsumerState<_DeckTile> createState() => _DeckTileState();
}

class _DeckTileState extends ConsumerState<_DeckTile> {
  int? _value; // null = not yet initialised

  bool get _isExtraCard =>
      widget.card.isFusion ||
      widget.card.isSynchro ||
      widget.card.isXyz ||
      widget.card.isLink;

  @override
  Widget build(BuildContext context) {
    final decks = ref.watch(deckProvider);
    final deck = decks.firstWhere(
      (d) => d.id == widget.deck.id,
      orElse: () => widget.deck,
    );
    final cfg = deck.config;

    final deckSize = _isExtraCard
        ? deck.extraDeck.length
        : deck.mainDeck.length;
    final maxDeck = _isExtraCard ? cfg.extraMax : cfg.mainMax;

    final copyCount = _isExtraCard
        ? deck.extraDeck.where((id) => id == widget.card.id).length
        : deck.mainDeck.where((id) => id == widget.card.id).length;

    _value ??= copyCount;

    final canIncrease = _value! < 3 && deckSize < maxDeck;
    final canDecrease = _value! > 0;
    final isDirty = _value != copyCount;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDirty
              ? AppTheme.accent.withValues(alpha: 0.5)
              : AppTheme.bgBorder,
          width: isDirty ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.style_rounded, size: 18, color: AppTheme.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deck.name,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _isExtraCard
                      ? 'Extra: $deckSize/$maxDeck'
                      : 'Main: $deckSize/$maxDeck',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // Stepper
          Container(
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.bgBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StepBtn(
                  icon: Icons.remove_rounded,
                  enabled: canDecrease,
                  onTap: () => setState(() => _value = _value! - 1),
                ),
                SizedBox(
                  width: 28,
                  child: Center(
                    child: Text(
                      '${_value!}',
                      style: TextStyle(
                        color: isDirty ? AppTheme.accent : AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                _StepBtn(
                  icon: Icons.add_rounded,
                  enabled: canIncrease,
                  onTap: () => setState(() => _value = _value! + 1),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: isDirty ? () => _save(context, copyCount) : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.black,
              disabledBackgroundColor: AppTheme.bgBorder,
              disabledForegroundColor: AppTheme.textMuted,
              minimumSize: const Size(56, 36),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Save',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _save(BuildContext context, int currentCopyCount) {
    final target = _value!;
    final diff = target - currentCopyCount;
    final notifier = ref.read(deckProvider.notifier);
    final zone = _isExtraCard ? DeckZone.extra : DeckZone.main;

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
        setState(() => _value = currentCopyCount);
        return;
      }
    } else if (diff < 0) {
      for (var i = 0; i < diff.abs(); i++) {
        notifier.removeCard(widget.deck.id, widget.card.id, zone);
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          diff > 0
              ? 'Added $diff to "${widget.deck.name}"'
              : 'Removed ${diff.abs()} from "${widget.deck.name}"',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.accent.withValues(alpha: 0.9),
      ),
    );
  }
}

// ── Step button ───────────────────────────────────────────────────────────────

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _StepBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? AppTheme.accent : AppTheme.textMuted,
        ),
      ),
    );
  }
}
