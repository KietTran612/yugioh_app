import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/card_sets_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/card_image.dart';
import 'set_detail_screen.dart';

class SetsScreen extends ConsumerStatefulWidget {
  const SetsScreen({super.key});

  @override
  ConsumerState<SetsScreen> createState() => _SetsScreenState();
}

class _SetsScreenState extends ConsumerState<SetsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSortSheet(BuildContext context) {
    final notifier = ref.read(setsFilterProvider.notifier);
    final current = ref.read(setsFilterProvider).sort;

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
            // Handle
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
            const Text(
              'Sort Sets',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ...SetSortOption.values.map((opt) {
              final isSelected = opt == current;
              return _SortOptionTile(
                label: _sortLabel(opt),
                icon: _sortIcon(opt),
                isSelected: isSelected,
                onTap: () {
                  notifier.setSort(opt);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  String _sortLabel(SetSortOption opt) {
    switch (opt) {
      case SetSortOption.nameAZ:
        return 'Name A → Z';
      case SetSortOption.nameZA:
        return 'Name Z → A';
      case SetSortOption.mostCards:
        return 'Most Cards';
      case SetSortOption.fewestCards:
        return 'Fewest Cards';
    }
  }

  IconData _sortIcon(SetSortOption opt) {
    switch (opt) {
      case SetSortOption.nameAZ:
        return Icons.sort_by_alpha_rounded;
      case SetSortOption.nameZA:
        return Icons.sort_by_alpha_rounded;
      case SetSortOption.mostCards:
        return Icons.keyboard_arrow_down_rounded;
      case SetSortOption.fewestCards:
        return Icons.keyboard_arrow_up_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final setsAsync = ref.watch(filteredSetsProvider);
    final filter = ref.watch(setsFilterProvider);
    final filterNotifier = ref.read(setsFilterProvider.notifier);

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        title: const Text('Card Sets'),
        actions: [
          // Sort button
          IconButton(
            icon: Icon(
              Icons.sort_rounded,
              size: 22,
              color: filter.hasActiveFilters
                  ? AppTheme.accent
                  : AppTheme.textSecondary,
            ),
            onPressed: () => _showSortSheet(context),
            tooltip: 'Sort',
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.bgBorder),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search sets...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: filter.search.isNotEmpty
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

          // Content
          Expanded(
            child: setsAsync.when(
              loading: () => const _LoadingView(),
              error: (e, _) => _ErrorView(error: e),
              data: (sets) {
                if (sets.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 56,
                          color: AppTheme.textMuted,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No sets found',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    // Count + sort label row
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
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
                              '${sets.length} sets',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Active sort label
                          Consumer(
                            builder: (context, ref, _) {
                              final sort = ref.watch(setsFilterProvider).sort;
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.accent.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppTheme.accent.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.sort_rounded,
                                      size: 11,
                                      color: AppTheme.accent,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _sortLabel(sort),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.accent,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    // List
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: sets.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          return _SetCard(
                            setInfo: sets[index],
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    SetDetailScreen(setInfo: sets[index]),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Set card list item ─────────────────────────────────────────────────────────

class _SetCard extends StatelessWidget {
  final CardSetInfo setInfo;
  final VoidCallback onTap;

  const _SetCard({required this.setInfo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final topRarityColor = _rarityColor(setInfo.topRarity);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.bgBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Cover image — first card in set
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(12),
              ),
              child: SizedBox(
                width: 64,
                height: 88,
                child: setInfo.coverImageUrl.isNotEmpty
                    ? CardNetworkImage(
                        imageUrl: setInfo.coverImageUrl,
                        fit: BoxFit.cover,
                        width: 64,
                        height: 88,
                      )
                    : Container(
                        color: AppTheme.bgElevated,
                        child: const Icon(
                          Icons.layers_rounded,
                          color: AppTheme.textMuted,
                          size: 28,
                        ),
                      ),
              ),
            ),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Set name
                    Text(
                      setInfo.setName,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Set code + card count
                    Row(
                      children: [
                        if (setInfo.setCode.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.bgElevated,
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: AppTheme.bgBorder),
                            ),
                            child: Text(
                              setInfo.setCode,
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 10,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          '${setInfo.cardCount} cards',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),

                    // Top rarity badge
                    if (setInfo.topRarity.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: topRarityColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: topRarityColor.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          setInfo.topRarity,
                          style: TextStyle(
                            color: topRarityColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Chevron
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textMuted,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _rarityColor(String rarity) {
    final r = rarity.toLowerCase();
    if (r.contains('secret')) return const Color(0xFFFF6B6B);
    if (r.contains('ultimate')) return const Color(0xFFFFD700);
    if (r.contains('ultra')) return const Color(0xFFFFB800);
    if (r.contains('super')) return const Color(0xFF00C896);
    if (r.contains('rare')) return const Color(0xFF74B9FF);
    return AppTheme.textSecondary;
  }
}

// ── Sort option tile ───────────────────────────────────────────────────────────

class _SortOptionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SortOptionTile({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accent.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppTheme.accent.withValues(alpha: 0.4)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppTheme.accent : AppTheme.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppTheme.accent : AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_rounded, size: 18, color: AppTheme.accent),
          ],
        ),
      ),
    );
  }
}

// ── Loading ────────────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 2),
          SizedBox(height: 20),
          Text(
            'Building set index...',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ── Error ──────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final Object error;
  const _ErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppTheme.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              error.toString(),
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
