import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/card_provider.dart';
import '../providers/favorites_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/card_item.dart';
import '../widgets/quick_filter_bar.dart';
import 'card_detail_screen.dart';
import 'main_shell.dart' show tabPush;

class WatchlistScreen extends ConsumerStatefulWidget {
  const WatchlistScreen({super.key});

  @override
  ConsumerState<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends ConsumerState<WatchlistScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final favIds = ref.watch(favoritesProvider);
    final filteredAsync = ref.watch(filteredFavoriteCardsProvider);
    final filterNotifier = ref.read(watchlistFilterProvider.notifier);
    final filter = ref.watch(watchlistFilterProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Watchlist'),
            if (favIds.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.accent.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  '${favIds.length}',
                  style: const TextStyle(
                    color: AppTheme.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (favIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              color: AppTheme.textSecondary,
              tooltip: 'Clear all favorites',
              onPressed: () => _confirmClear(context),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.bgBorder),
        ),
      ),
      body: favIds.isEmpty
          ? const _EmptyState()
          : Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search favorites...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                filterNotifier.setSearch('');
                              },
                            )
                          : null,
                    ),
                    onChanged: filterNotifier.setSearch,
                  ),
                ),

                // Quick filter bar — dùng watchlistFilterProvider riêng
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: QuickFilterBar(
                    filterProvider: watchlistFilterProvider,
                    indexProvider: filterIndexProvider,
                  ),
                ),

                // Result count
                filteredAsync
                        .whenData(
                          (cards) => Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.bgElevated,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppTheme.bgBorder,
                                    ),
                                  ),
                                  child: Text(
                                    filter.hasActiveFilters
                                        ? '${cards.length} of ${favIds.length} cards'
                                        : '${cards.length} cards',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .valueOrNull ??
                    const SizedBox(height: 4),

                // Card grid
                Expanded(
                  child: filteredAsync.when(
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
                      if (cards.isEmpty) {
                        return _NoResultsState(
                          hasFilter: filter.hasActiveFilters,
                          onReset: () {
                            filterNotifier.reset();
                            _searchController.clear();
                          },
                        );
                      }

                      return GridView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _getCrossAxisCount(context),
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.69,
                        ),
                        itemCount: cards.length,
                        itemBuilder: (context, index) {
                          final card = cards[index];
                          return CardItem(
                            card: card,
                            onTap: () => tabPush(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CardDetailScreen(card: card),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 6;
    if (width > 800) return 4;
    if (width > 600) return 3;
    return 2;
  }

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Watchlist'),
        content: const Text('Remove all cards from your watchlist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(favoritesProvider.notifier).clear();
              // Reset filter khi clear hết
              ref.read(watchlistFilterProvider.notifier).reset();
              _searchController.clear();
            },
            icon: const Icon(Icons.delete_sweep_rounded, size: 16),
            label: const Text('Clear All'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE74C3C),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state (no favorites at all) ─────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
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
              Icons.favorite_border_rounded,
              size: 48,
              color: Color(0xFFFF6B6B),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No favorites yet',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap ❤️ on any card to add it here',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ── No results state (has favorites but filter returns empty) ──────────────────

class _NoResultsState extends StatelessWidget {
  final bool hasFilter;
  final VoidCallback onReset;

  const _NoResultsState({required this.hasFilter, required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 56,
            color: AppTheme.textMuted,
          ),
          const SizedBox(height: 16),
          const Text(
            'No cards match',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try adjusting your filters',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
          if (hasFilter) ...[
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
              label: const Text('Reset Filters'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.accent,
                side: const BorderSide(color: AppTheme.accent),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
