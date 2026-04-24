import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/deck_model.dart';
import '../providers/deck_provider.dart';
import '../utils/app_theme.dart';
import 'deck_detail_screen.dart';
import 'main_shell.dart' show tabPush;

class CollectionScreen extends ConsumerStatefulWidget {
  const CollectionScreen({super.key});

  @override
  ConsumerState<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends ConsumerState<CollectionScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        title: const Text('Deck Builder'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(49),
          child: Column(
            children: [
              Container(height: 1, color: AppTheme.bgBorder),
              TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.accent,
                indicatorWeight: 2,
                labelColor: AppTheme.accent,
                unselectedLabelColor: AppTheme.textMuted,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(text: 'Master Duel'),
                  Tab(text: 'Duel Links'),
                ],
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) {
          final format = _tabController.index == 0
              ? DeckFormat.masterDuel
              : DeckFormat.duelLinks;
          return Consumer(
            builder: (context, ref, _) => FloatingActionButton.extended(
              onPressed: () => showCreateDeckDialog(context, ref, format),
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.black,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'New Deck',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          );
        },
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _DeckList(format: DeckFormat.masterDuel),
          _DeckList(format: DeckFormat.duelLinks),
        ],
      ),
    );
  }
}

// ── Deck list per format ───────────────────────────────────────────────────────

class _DeckList extends ConsumerWidget {
  final DeckFormat format;
  const _DeckList({required this.format});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decks = ref.watch(
      format == DeckFormat.masterDuel
          ? masterDuelDecksProvider
          : duelLinksDecksProvider,
    );
    final cfg = deckFormatConfigs[format]!;

    return Column(
      children: [
        // Format info bar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: AppTheme.bgCard,
          child: Row(
            children: [
              _InfoPill(
                label: 'Main ${cfg.mainMin}–${cfg.mainMax}',
                color: AppTheme.accent,
              ),
              const SizedBox(width: 8),
              _InfoPill(
                label: 'Extra max ${cfg.extraMax}',
                color: AppTheme.accentGold,
              ),
              if (cfg.hasSide) ...[
                const SizedBox(width: 8),
                _InfoPill(
                  label: 'Side max ${cfg.sideMax}',
                  color: AppTheme.textSecondary,
                ),
              ],
            ],
          ),
        ),

        // Deck list
        Expanded(
          child: decks.isEmpty
              ? _EmptyState(
                  format: format,
                  onCreateTap: () => _showCreateDialog(context, ref, format),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: decks.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _DeckCard(
                    deck: decks[i],
                    onTap: () => tabPush(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DeckDetailScreen(deckId: decks[i].id),
                      ),
                    ),
                    onDelete: () => _confirmDelete(context, ref, decks[i]),
                  ),
                ),
        ),
      ],
    );
  }

  void _showCreateDialog(
    BuildContext context,
    WidgetRef ref,
    DeckFormat format,
  ) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        title: Text(
          'New ${deckFormatConfigs[format]!.label} Deck',
          style: const TextStyle(color: AppTheme.textPrimary),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(hintText: 'Deck name'),
          onSubmitted: (_) => _create(ctx, ref, controller.text, format),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => _create(ctx, ref, controller.text, format),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _create(
    BuildContext ctx,
    WidgetRef ref,
    String name,
    DeckFormat format,
  ) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    Navigator.pop(ctx);
    await ref.read(deckProvider.notifier).createDeck(trimmed, format);
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Deck deck) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        title: const Text(
          'Delete Deck',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: Text(
          'Delete "${deck.name}"? This cannot be undone.',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(deckProvider.notifier).deleteDeck(deck.id);
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE74C3C),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ── Deck card item ─────────────────────────────────────────────────────────────

class _DeckCard extends StatelessWidget {
  final Deck deck;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _DeckCard({
    required this.deck,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cfg = deck.config;
    final errors = deck.validate();
    final isValid = errors.isEmpty;
    final mainCount = deck.mainDeck.length;
    final extraCount = deck.extraDeck.length;
    final sideCount = deck.sideDeck.length;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isValid && mainCount >= cfg.mainMin
                ? AppTheme.accent.withValues(alpha: 0.3)
                : AppTheme.bgBorder,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppTheme.accent.withValues(alpha: 0.3),
                ),
              ),
              child: const Icon(
                Icons.style_rounded,
                color: AppTheme.accent,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deck.name,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _CountChip(
                        label: 'Main $mainCount/${cfg.mainMax}',
                        color:
                            mainCount >= cfg.mainMin && mainCount <= cfg.mainMax
                            ? AppTheme.accent
                            : const Color(0xFFE74C3C),
                      ),
                      const SizedBox(width: 6),
                      _CountChip(
                        label: 'Extra $extraCount',
                        color: AppTheme.accentGold,
                      ),
                      if (cfg.hasSide && sideCount > 0) ...[
                        const SizedBox(width: 6),
                        _CountChip(
                          label: 'Side $sideCount',
                          color: AppTheme.textSecondary,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Delete button
            IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                size: 20,
                color: AppTheme.textMuted,
              ),
              onPressed: onDelete,
            ),

            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final DeckFormat format;
  final VoidCallback onCreateTap;

  const _EmptyState({required this.format, required this.onCreateTap});

  @override
  Widget build(BuildContext context) {
    final cfg = deckFormatConfigs[format]!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.bgBorder),
            ),
            child: const Icon(
              Icons.style_outlined,
              size: 48,
              color: AppTheme.accentGold,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No ${cfg.label} Decks',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Main ${cfg.mainMin}–${cfg.mainMax} · Extra max ${cfg.extraMax}',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onCreateTap,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Create Deck'),
          ),
        ],
      ),
    );
  }
}

// ── Small widgets ──────────────────────────────────────────────────────────────

class _InfoPill extends StatelessWidget {
  final String label;
  final Color color;
  const _InfoPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

class _CountChip extends StatelessWidget {
  final String label;
  final Color color;
  const _CountChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── FAB to create deck — shown via Scaffold in parent ─────────────────────────

/// Call from CollectionScreen to show create dialog for current tab format
void showCreateDeckDialog(
  BuildContext context,
  WidgetRef ref,
  DeckFormat format,
) {
  final controller = TextEditingController();
  final cfg = deckFormatConfigs[format]!;
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppTheme.bgCard,
      title: Text(
        'New ${cfg.label} Deck',
        style: const TextStyle(color: AppTheme.textPrimary),
      ),
      content: TextField(
        controller: controller,
        autofocus: true,
        style: const TextStyle(color: AppTheme.textPrimary),
        decoration: const InputDecoration(hintText: 'Deck name'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            final name = controller.text.trim();
            if (name.isEmpty) return;
            Navigator.pop(ctx);
            await ref.read(deckProvider.notifier).createDeck(name, format);
          },
          child: const Text('Create'),
        ),
      ],
    ),
  );
}
