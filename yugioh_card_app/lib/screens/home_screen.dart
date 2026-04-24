import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/card_provider.dart';
import '../services/card_data_service.dart';
import '../utils/app_theme.dart';
import '../widgets/card_item.dart';
import '../widgets/filter_panel.dart';
import '../widgets/quick_filter_bar.dart';
import 'card_detail_screen.dart';
import 'main_shell.dart' show tabPush;

const _pageSize = 50;

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  int _displayCount = _pageSize;

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
      final cardsAsync = ref.read(filteredCardsProvider);
      cardsAsync.whenData((cards) {
        if (_displayCount < cards.length) {
          setState(() => _displayCount += _pageSize);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardsAsync = ref.watch(filteredCardsProvider);
    final filterNotifier = ref.read(filterStateProvider.notifier);
    final filter = ref.watch(filterStateProvider);

    ref.listen(filterStateProvider, (prev, next) {
      if (prev != next) setState(() => _displayCount = _pageSize);
    });

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: _buildAppBar(context, filter.hasActiveFilters),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search cards...',
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

          // Quick filter bar
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: QuickFilterBar(),
          ),

          // Card count row
          cardsAsync
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
                              border: Border.all(color: AppTheme.bgBorder),
                            ),
                            child: Text(
                              '${cards.length} cards',
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
            child: cardsAsync.when(
              loading: () => const _LoadingView(),
              error: (e, _) => _ErrorView(
                error: e,
                onRetry: () => ref.invalidate(cardDataProvider),
              ),
              data: (cards) {
                if (cards.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 64,
                          color: AppTheme.textMuted,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No cards found',
                          style: TextStyle(
                            fontSize: 18,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Try adjusting your filters',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final displayCards = cards.take(_displayCount).toList();
                final hasMore = _displayCount < cards.length;

                return GridView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _getCrossAxisCount(context),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.69,
                  ),
                  itemCount: displayCards.length + (hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == displayCards.length) {
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
                    final card = displayCards[index];
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

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    bool hasActiveFilters,
  ) {
    return AppBar(
      backgroundColor: AppTheme.bgDeep,
      title: Row(
        children: [
          // Logo icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.accent.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 18,
              color: AppTheme.accent,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Yu-Gi-Oh!',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
      actions: [
        // Filter button with active indicator
        _FilterButton(
          hasActive: hasActiveFilters,
          onTap: () => _showFilterSheet(context),
        ),
        // Refresh button
        IconButton(
          icon: const Icon(Icons.refresh_rounded, size: 22),
          color: AppTheme.textSecondary,
          onPressed: () => _confirmRefresh(context),
          tooltip: 'Refresh card data',
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppTheme.bgBorder),
      ),
    );
  }

  void _confirmRefresh(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Refresh Card Data'),
        content: const Text(
          'This will re-fetch all cards from the YGOPRODeck API.\nIt may take a moment. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              await CardDataService.clearCache();
              ref.invalidate(cardDataProvider);
            },
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => FilterPanel(scrollController: controller),
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
}

// ── Filter button with badge ───────────────────────────────────────────────────

class _FilterButton extends StatelessWidget {
  final bool hasActive;
  final VoidCallback onTap;

  const _FilterButton({required this.hasActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: 'Filters',
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            Icons.tune_rounded,
            size: 22,
            color: hasActive ? AppTheme.accent : AppTheme.textSecondary,
          ),
          if (hasActive)
            Positioned(
              top: -2,
              right: -2,
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
    );
  }
}

// ── Loading view ───────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 2),
          SizedBox(height: 24),
          Text(
            'Loading cards...',
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            'Fetching from API on first launch',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ── Error view ─────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.bgElevated,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.bgBorder),
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 48,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Failed to load card data',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
