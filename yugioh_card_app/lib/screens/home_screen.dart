import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/card_provider.dart';
import '../services/card_data_service.dart';
import '../widgets/card_item.dart';
import '../widgets/filter_panel.dart';
import '../widgets/quick_filter_bar.dart';
import 'card_detail_screen.dart';

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
    // Load more when near bottom
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

    // Reset display count when filter changes
    ref.listen(filterStateProvider, (prev, next) {
      if (prev != next) {
        setState(() => _displayCount = _pageSize);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yu-Gi-Oh! Cards'),
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _confirmRefresh(context),
            tooltip: 'Refresh card data',
          ),
          // Active filter indicator
          if (filter.hasActiveFilters)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: IconButton(
                icon: Badge(child: const Icon(Icons.filter_list)),
                onPressed: () => _showFilterSheet(context),
                tooltip: 'Filters (active)',
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () => _showFilterSheet(context),
              tooltip: 'Filters',
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search cards...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          filterNotifier.setSearch('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: filterNotifier.setSearch,
            ),
          ),

          // Quick filter bar
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: QuickFilterBar(),
          ),

          // Card count
          cardsAsync
                  .whenData(
                    (cards) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${cards.length} cards',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                        ),
                      ),
                    ),
                  )
                  .valueOrNull ??
              const SizedBox(height: 6),

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
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No cards found',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                final displayCards = cards.take(_displayCount).toList();
                final hasMore = _displayCount < cards.length;

                return GridView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _getCrossAxisCount(context),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.69, // Yu-Gi-Oh card ratio 59x86mm
                  ),
                  // +1 for loading indicator at bottom
                  itemCount: displayCards.length + (hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == displayCards.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    final card = displayCards[index];
                    return CardItem(
                      card: card,
                      onTap: () => Navigator.push(
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

  void _confirmRefresh(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Refresh Card Data'),
        content: const Text(
          'This will re-fetch all cards from the YGOPRODeck API.\n\nIt may take a moment. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              // Clear cache first so loadCards() goes to API
              await CardDataService.clearCache();
              ref.invalidate(cardDataProvider);
            },
            icon: const Icon(Icons.refresh),
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
      // useSafeArea prevents sheet from going under system UI
      useSafeArea: true,
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

// ── Loading widget ─────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 24),
          Text('Loading cards...'),
          SizedBox(height: 8),
          Text(
            'Fetching from API on first launch',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ── Error widget ───────────────────────────────────────────────────────────────

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
            const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Failed to load card data',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
