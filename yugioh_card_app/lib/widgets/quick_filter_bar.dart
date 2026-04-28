import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/card_model.dart';
import '../models/filter_state.dart';
import '../providers/card_provider.dart';
import '../utils/app_theme.dart';
import 'quick_filter_widgets.dart';

// ── QuickFilterBar ────────────────────────────────────────────────────────────
// Accepts optional custom providers so it can be reused in Watchlist tab
// with its own independent filter state.

class QuickFilterBar extends ConsumerStatefulWidget {
  /// Provider for the filter state. Defaults to the global [filterStateProvider].
  final StateNotifierProvider<FilterStateNotifier, FilterState>? filterProvider;

  /// Provider for the filter index (available options). Defaults to [filterIndexProvider].
  final ProviderBase<AsyncValue<FilterIndex>>? indexProvider;

  const QuickFilterBar({super.key, this.filterProvider, this.indexProvider});

  @override
  ConsumerState<QuickFilterBar> createState() => _QuickFilterBarState();
}

class _QuickFilterBarState extends ConsumerState<QuickFilterBar>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _animController;
  late final Animation<double> _expandAnim;

  static const _sectionOrder = [
    'Type',
    'Attribute',
    'Race',
    'Level',
    'Archetype',
    'ATK',
    'DEF',
    'TCG Rarity',
    'Banlist',
    'Format',
    'Sort',
  ];
  static const _sectionHeights = {
    'Type': 120.0,
    'Attribute': 120.0,
    'Race': 100.0,
    'Level': 100.0,
    'Archetype': 100.0,
    'ATK': 90.0,
    'DEF': 90.0,
    'TCG Rarity': 100.0,
    'Banlist': 90.0,
    'Format': 90.0,
    'Sort': 120.0,
  };
  static const _sectionHeaderHeight = 44.0;
  static const _resetButtonHeight = 52.0;

  final _containerKey = GlobalKey();
  double _availableHeight = double.infinity;
  final List<String> _openSections = ['Type', 'Attribute'];

  StateNotifierProvider<FilterStateNotifier, FilterState> get _filterProvider =>
      widget.filterProvider ?? filterStateProvider;

  ProviderBase<AsyncValue<FilterIndex>> get _indexProvider =>
      widget.indexProvider ?? filterIndexProvider;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _expandAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _measureAvailableHeight(),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _measureAvailableHeight() {
    final ctx = _containerKey.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final offset = box.localToGlobal(Offset.zero);
    final screenHeight = MediaQuery.of(ctx).size.height;
    final available = screenHeight - offset.dy - 200;
    if (available > 0 && available != _availableHeight) {
      setState(() => _availableHeight = available);
    }
  }

  void _toggleMain() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _animController.forward();
      Future.delayed(
        const Duration(milliseconds: 300),
        _measureAvailableHeight,
      );
    } else {
      _animController.reverse();
    }
  }

  double _estimatedContentHeight(List<String> openSections, bool hasActive) {
    double h = 0;
    for (final key in _sectionOrder) {
      h += openSections.contains(key)
          ? (_sectionHeights[key] ?? _sectionHeaderHeight)
          : _sectionHeaderHeight;
    }
    if (hasActive) h += _resetButtonHeight;
    return h;
  }

  void _toggleSection(String key, bool hasActive) {
    setState(() {
      if (_openSections.contains(key)) {
        _openSections.remove(key);
        return;
      }
      _openSections.add(key);
      while (_estimatedContentHeight(_openSections, hasActive) >
              _availableHeight &&
          _openSections.length > 1) {
        final oldest = _openSections.firstWhere(
          (s) => s != key,
          orElse: () => '',
        );
        if (oldest.isEmpty) break;
        _openSections.remove(oldest);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(_filterProvider);
    final filterAsync = ref.watch(_indexProvider);
    final notifier = ref.read(_filterProvider.notifier);
    final hasActive = filter.hasActiveFilters;

    return Column(
      key: _containerKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Toggle bar
        InkWell(
          onTap: _toggleMain,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: hasActive
                  ? AppTheme.accent.withValues(alpha: 0.08)
                  : AppTheme.bgElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasActive
                    ? AppTheme.accent.withValues(alpha: 0.4)
                    : AppTheme.bgBorder,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.tune_rounded,
                  size: 16,
                  color: hasActive ? AppTheme.accent : AppTheme.textMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: hasActive
                      ? FilterActiveSummary(filter: filter)
                      : const Text(
                          'Quick Filters',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textMuted,
                          ),
                        ),
                ),
                if (hasActive)
                  GestureDetector(
                    onTap: notifier.reset,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Expandable content
        SizeTransition(
          sizeFactor: _expandAnim,
          child: filterAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (index) => Container(
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.bgBorder),
              ),
              child: Column(
                children: [
                  FilterCollapsibleSection(
                    title: 'Type',
                    isOpen: _openSections.contains('Type'),
                    activeCount: filter.frameTypes.length,
                    onToggle: () => _toggleSection('Type', hasActive),
                    child: FilterMultiChipGroup<String>(
                      items: index.frameTypes,
                      selected: filter.frameTypes,
                      onTap: notifier.toggleFrameType,
                      colorBuilder: (f) => AppTheme.getFrameColor(f),
                    ),
                  ),
                  const FilterDivider(),
                  FilterCollapsibleSection(
                    title: 'Attribute',
                    isOpen: _openSections.contains('Attribute'),
                    activeCount: filter.attributes.length,
                    onToggle: () => _toggleSection('Attribute', hasActive),
                    child: FilterMultiChipGroup<String>(
                      items: index.attributes,
                      selected: filter.attributes,
                      onTap: notifier.toggleAttribute,
                      colorBuilder: (a) => AppTheme.getAttributeColor(a),
                    ),
                  ),
                  const FilterDivider(),
                  FilterCollapsibleSection(
                    title: 'Race / Type',
                    isOpen: _openSections.contains('Race'),
                    activeCount: filter.races.length,
                    onToggle: () => _toggleSection('Race', hasActive),
                    child: FilterMultiChipGroup<String>(
                      items: index.races,
                      selected: filter.races,
                      onTap: notifier.toggleRace,
                    ),
                  ),
                  const FilterDivider(),
                  FilterCollapsibleSection(
                    title: 'Level / Rank',
                    isOpen: _openSections.contains('Level'),
                    activeCount: filter.levels.length,
                    onToggle: () => _toggleSection('Level', hasActive),
                    child: FilterMultiChipGroup<int>(
                      items: index.levels,
                      selected: filter.levels,
                      labelBuilder: (v) => '★$v',
                      onTap: notifier.toggleLevel,
                    ),
                  ),
                  const FilterDivider(),
                  FilterCollapsibleSection(
                    title: 'Archetype',
                    isOpen: _openSections.contains('Archetype'),
                    activeCount: filter.archetype != null ? 1 : 0,
                    onToggle: () => _toggleSection('Archetype', hasActive),
                    child: FilterMultiChipGroup<String>(
                      items: index.archetypes,
                      selected: filter.archetype != null
                          ? {filter.archetype!}
                          : {},
                      onTap: (v) => notifier.setArchetype(
                        filter.archetype == v ? null : v,
                      ),
                    ),
                  ),
                  const FilterDivider(),
                  FilterCollapsibleSection(
                    title: 'ATK Range',
                    isOpen: _openSections.contains('ATK'),
                    activeCount:
                        (filter.atkMin != null || filter.atkMax != null)
                        ? 1
                        : 0,
                    onToggle: () => _toggleSection('ATK', hasActive),
                    child: FilterRangeInput(
                      minValue: filter.atkMin,
                      maxValue: filter.atkMax,
                      onChanged: notifier.setAtkRange,
                    ),
                  ),
                  const FilterDivider(),
                  FilterCollapsibleSection(
                    title: 'DEF Range',
                    isOpen: _openSections.contains('DEF'),
                    activeCount:
                        (filter.defMin != null || filter.defMax != null)
                        ? 1
                        : 0,
                    onToggle: () => _toggleSection('DEF', hasActive),
                    child: FilterRangeInput(
                      minValue: filter.defMin,
                      maxValue: filter.defMax,
                      onChanged: notifier.setDefRange,
                    ),
                  ),
                  const FilterDivider(),
                  FilterCollapsibleSection(
                    title: 'TCG Rarity',
                    isOpen: _openSections.contains('TCG Rarity'),
                    activeCount: filter.tcgRarities.length,
                    onToggle: () => _toggleSection('TCG Rarity', hasActive),
                    child: FilterMultiChipGroup<String>(
                      items: index.tcgRarities,
                      selected: filter.tcgRarities,
                      onTap: notifier.toggleTcgRarity,
                      colorBuilder: (c) => AppTheme.getTcgRarityColor(c),
                    ),
                  ),
                  const FilterDivider(),
                  FilterCollapsibleSection(
                    title: 'Banlist',
                    isOpen: _openSections.contains('Banlist'),
                    activeCount: filter.banlistStatuses.length,
                    onToggle: () => _toggleSection('Banlist', hasActive),
                    child: FilterMultiChipGroup<String>(
                      items: const ['Forbidden', 'Limited', 'Semi-Limited'],
                      selected: filter.banlistStatuses,
                      onTap: notifier.toggleBanlistStatus,
                      colorBuilder: (s) => AppTheme.getBanlistColor(s),
                    ),
                  ),
                  const FilterDivider(),
                  FilterCollapsibleSection(
                    title: 'Format',
                    isOpen: _openSections.contains('Format'),
                    activeCount: filter.formats.length,
                    onToggle: () => _toggleSection('Format', hasActive),
                    child: FilterMultiChipGroup<String>(
                      items: const ['TCG', 'OCG', 'Master Duel', 'GOAT'],
                      selected: filter.formats,
                      onTap: notifier.toggleFormat,
                    ),
                  ),
                  const FilterDivider(),
                  FilterCollapsibleSection(
                    title: 'Sort By',
                    isOpen: _openSections.contains('Sort'),
                    activeCount: 0,
                    onToggle: () => _toggleSection('Sort', hasActive),
                    child: FilterSortSelector(
                      filter: filter,
                      notifier: notifier,
                    ),
                  ),
                  if (hasActive)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                      child: OutlinedButton.icon(
                        onPressed: notifier.reset,
                        icon: const Icon(
                          Icons.filter_alt_off_rounded,
                          size: 16,
                        ),
                        label: const Text('Reset All Filters'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(36),
                          foregroundColor: AppTheme.accent,
                          side: const BorderSide(color: AppTheme.accent),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
