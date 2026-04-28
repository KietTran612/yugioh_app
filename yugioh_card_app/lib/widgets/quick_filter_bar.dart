import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/card_model.dart';
import '../models/filter_state.dart';
import '../providers/card_provider.dart';
import '../utils/app_theme.dart';

// ── QuickFilterBar ─────────────────────────────────────────────────────────────
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

  // Resolved providers (fallback to global defaults)
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
        // ── Toggle bar ──────────────────────────────────────────────────
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
                      ? _ActiveFilterSummary(filter: filter)
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

        // ── Expandable content ──────────────────────────────────────────
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
                  _CollapsibleSection(
                    title: 'Type',
                    isOpen: _openSections.contains('Type'),
                    activeCount: filter.frameTypes.length,
                    onToggle: () => _toggleSection('Type', hasActive),
                    child: _MultiChipGroup<String>(
                      items: index.frameTypes,
                      selected: filter.frameTypes,
                      onTap: notifier.toggleFrameType,
                      colorBuilder: _frameTypeColor,
                    ),
                  ),
                  _Divider(),
                  _CollapsibleSection(
                    title: 'Attribute',
                    isOpen: _openSections.contains('Attribute'),
                    activeCount: filter.attributes.length,
                    onToggle: () => _toggleSection('Attribute', hasActive),
                    child: _MultiChipGroup<String>(
                      items: index.attributes,
                      selected: filter.attributes,
                      onTap: notifier.toggleAttribute,
                      colorBuilder: _attributeColor,
                    ),
                  ),
                  _Divider(),
                  _CollapsibleSection(
                    title: 'Race / Type',
                    isOpen: _openSections.contains('Race'),
                    activeCount: filter.races.length,
                    onToggle: () => _toggleSection('Race', hasActive),
                    child: _MultiChipGroup<String>(
                      items: index.races,
                      selected: filter.races,
                      onTap: notifier.toggleRace,
                    ),
                  ),
                  _Divider(),
                  _CollapsibleSection(
                    title: 'Level / Rank',
                    isOpen: _openSections.contains('Level'),
                    activeCount: filter.levels.length,
                    onToggle: () => _toggleSection('Level', hasActive),
                    child: _MultiChipGroup<int>(
                      items: index.levels,
                      selected: filter.levels,
                      labelBuilder: (v) => '★$v',
                      onTap: notifier.toggleLevel,
                    ),
                  ),
                  _Divider(),
                  _CollapsibleSection(
                    title: 'Archetype',
                    isOpen: _openSections.contains('Archetype'),
                    activeCount: filter.archetype != null ? 1 : 0,
                    onToggle: () => _toggleSection('Archetype', hasActive),
                    child: _MultiChipGroup<String>(
                      items: index.archetypes,
                      selected: filter.archetype != null
                          ? {filter.archetype!}
                          : {},
                      onTap: (v) => notifier.setArchetype(
                        filter.archetype == v ? null : v,
                      ),
                    ),
                  ),
                  _Divider(),
                  _CollapsibleSection(
                    title: 'ATK Range',
                    isOpen: _openSections.contains('ATK'),
                    activeCount:
                        (filter.atkMin != null || filter.atkMax != null)
                        ? 1
                        : 0,
                    onToggle: () => _toggleSection('ATK', hasActive),
                    child: _RangeInput(
                      minValue: filter.atkMin,
                      maxValue: filter.atkMax,
                      onChanged: notifier.setAtkRange,
                    ),
                  ),
                  _Divider(),
                  _CollapsibleSection(
                    title: 'DEF Range',
                    isOpen: _openSections.contains('DEF'),
                    activeCount:
                        (filter.defMin != null || filter.defMax != null)
                        ? 1
                        : 0,
                    onToggle: () => _toggleSection('DEF', hasActive),
                    child: _RangeInput(
                      minValue: filter.defMin,
                      maxValue: filter.defMax,
                      onChanged: notifier.setDefRange,
                    ),
                  ),
                  _Divider(),
                  _CollapsibleSection(
                    title: 'TCG Rarity',
                    isOpen: _openSections.contains('TCG Rarity'),
                    activeCount: filter.tcgRarities.length,
                    onToggle: () => _toggleSection('TCG Rarity', hasActive),
                    child: _MultiChipGroup<String>(
                      items: index.tcgRarities,
                      selected: filter.tcgRarities,
                      onTap: notifier.toggleTcgRarity,
                      colorBuilder: _tcgRarityColor,
                    ),
                  ),
                  _Divider(),
                  _CollapsibleSection(
                    title: 'Banlist',
                    isOpen: _openSections.contains('Banlist'),
                    activeCount: filter.banlistStatuses.length,
                    onToggle: () => _toggleSection('Banlist', hasActive),
                    child: _MultiChipGroup<String>(
                      items: const ['Forbidden', 'Limited', 'Semi-Limited'],
                      selected: filter.banlistStatuses,
                      onTap: notifier.toggleBanlistStatus,
                      colorBuilder: _banlistColor,
                    ),
                  ),
                  _Divider(),
                  _CollapsibleSection(
                    title: 'Format',
                    isOpen: _openSections.contains('Format'),
                    activeCount: filter.formats.length,
                    onToggle: () => _toggleSection('Format', hasActive),
                    child: _MultiChipGroup<String>(
                      items: const ['TCG', 'OCG', 'Master Duel', 'GOAT'],
                      selected: filter.formats,
                      onTap: notifier.toggleFormat,
                    ),
                  ),
                  _Divider(),
                  _CollapsibleSection(
                    title: 'Sort By',
                    isOpen: _openSections.contains('Sort'),
                    activeCount: 0,
                    onToggle: () => _toggleSection('Sort', hasActive),
                    child: _SortSelector(filter: filter, notifier: notifier),
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

// ── Collapsible section ────────────────────────────────────────────────────────

class _CollapsibleSection extends StatelessWidget {
  final String title;
  final bool isOpen;
  final int activeCount;
  final VoidCallback onToggle;
  final Widget child;

  const _CollapsibleSection({
    required this.title,
    required this.isOpen,
    required this.activeCount,
    required this.onToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (activeCount > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.accent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$activeCount',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                AnimatedRotation(
                  turns: isOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: child,
          ),
          crossFadeState: isOpen
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}

// ── Multi-select chip group ────────────────────────────────────────────────────

class _MultiChipGroup<T> extends StatelessWidget {
  final List<T> items;
  final Set<T> selected;
  final void Function(T) onTap;
  final String Function(T)? labelBuilder;
  final Color Function(T)? colorBuilder;

  const _MultiChipGroup({
    required this.items,
    required this.selected,
    required this.onTap,
    this.labelBuilder,
    this.colorBuilder,
  });

  Widget _chip(BuildContext context, T item) {
    final isSelected = selected.contains(item);
    final chipColor = colorBuilder?.call(item);
    final label = labelBuilder != null ? labelBuilder!(item) : item.toString();

    return GestureDetector(
      onTap: () => onTap(item),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? (chipColor ?? AppTheme.accent).withValues(alpha: 0.2)
              : AppTheme.bgElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? (chipColor ?? AppTheme.accent)
                : AppTheme.bgBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? (chipColor ?? AppTheme.accent)
                : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final row0 = <T>[];
    final row1 = <T>[];
    for (var i = 0; i < items.length; i++) {
      if (i.isEven) {
        row0.add(items[i]);
      } else {
        row1.add(items[i]);
      }
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: row0
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _chip(context, item),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: row1
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _chip(context, item),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

// ── Range input ────────────────────────────────────────────────────────────────

class _RangeInput extends StatelessWidget {
  final int? minValue;
  final int? maxValue;
  final void Function(int? min, int? max) onChanged;

  const _RangeInput({this.minValue, this.maxValue, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            initialValue: minValue?.toString() ?? '',
            decoration: const InputDecoration(
              labelText: 'Min',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              isDense: true,
            ),
            keyboardType: TextInputType.number,
            onChanged: (v) => onChanged(int.tryParse(v), maxValue),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '–',
            style: TextStyle(fontSize: 16, color: AppTheme.textMuted),
          ),
        ),
        Expanded(
          child: TextFormField(
            initialValue: maxValue?.toString() ?? '',
            decoration: const InputDecoration(
              labelText: 'Max',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              isDense: true,
            ),
            keyboardType: TextInputType.number,
            onChanged: (v) => onChanged(minValue, int.tryParse(v)),
          ),
        ),
      ],
    );
  }
}

// ── Sort selector ──────────────────────────────────────────────────────────────

class _SortSelector extends StatelessWidget {
  final FilterState filter;
  final FilterStateNotifier notifier;
  const _SortSelector({required this.filter, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: SortOption.values.map((option) {
            final isSelected = filter.sortBy == option;
            return GestureDetector(
              onTap: () => notifier.setSortBy(option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.accent.withValues(alpha: 0.2)
                      : AppTheme.bgElevated,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppTheme.accent : AppTheme.bgBorder,
                  ),
                ),
                child: Text(
                  option.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected
                        ? AppTheme.accent
                        : AppTheme.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: notifier.toggleSortDirection,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.bgElevated,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.bgBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  filter.sortAscending
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 14,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  filter.sortAscending ? 'Ascending' : 'Descending',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Active filter summary ──────────────────────────────────────────────────────

class _ActiveFilterSummary extends StatelessWidget {
  final FilterState filter;
  const _ActiveFilterSummary({required this.filter});

  @override
  Widget build(BuildContext context) {
    final parts = <String>[];
    if (filter.frameTypes.isNotEmpty) parts.add(filter.frameTypes.join(', '));
    if (filter.attributes.isNotEmpty) parts.add(filter.attributes.join(', '));
    if (filter.levels.isNotEmpty) {
      parts.add(filter.levels.map((v) => '★$v').join(', '));
    }
    if (filter.races.isNotEmpty) parts.add(filter.races.join(', '));
    if (filter.archetype != null) parts.add(filter.archetype!);
    if (filter.atkMin != null || filter.atkMax != null) {
      parts.add('ATK ${filter.atkMin ?? 0}–${filter.atkMax ?? '∞'}');
    }
    if (filter.defMin != null || filter.defMax != null) {
      parts.add('DEF ${filter.defMin ?? 0}–${filter.defMax ?? '∞'}');
    }
    if (filter.banlistStatuses.isNotEmpty) {
      parts.add(filter.banlistStatuses.join(', '));
    }
    if (filter.tcgRarities.isNotEmpty) {
      parts.add(filter.tcgRarities.join(', '));
    }
    if (filter.formats.isNotEmpty) {
      parts.add(filter.formats.join(', '));
    }
    if (filter.searchQuery.isNotEmpty) parts.add('"${filter.searchQuery}"');

    return Text(
      parts.join(' · '),
      style: const TextStyle(
        fontSize: 12,
        color: AppTheme.accent,
        fontWeight: FontWeight.w500,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }
}

// ── Divider ────────────────────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, thickness: 1, color: AppTheme.bgBorder);
}

// ── Color helpers ──────────────────────────────────────────────────────────────

Color _frameTypeColor(String frameType) => AppTheme.getFrameColor(frameType);

Color _attributeColor(String attribute) =>
    AppTheme.getAttributeColor(attribute);

Color _tcgRarityColor(String code) => AppTheme.getTcgRarityColor(code);

Color _banlistColor(String status) => AppTheme.getBanlistColor(status);
