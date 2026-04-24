import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/filter_state.dart';
import '../providers/card_provider.dart';

class QuickFilterBar extends ConsumerStatefulWidget {
  const QuickFilterBar({super.key});

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
    'Sort': 120.0,
  };
  static const _sectionHeaderHeight = 44.0;
  static const _resetButtonHeight = 52.0;

  final _containerKey = GlobalKey();
  double _availableHeight = double.infinity;
  final Set<String> _openSections = {'Type', 'Attribute'};

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
    final available = screenHeight - offset.dy - 32;
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

  double _estimatedContentHeight(Set<String> openSections, bool hasActive) {
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
      for (final s in _sectionOrder) {
        if (_estimatedContentHeight(_openSections, hasActive) <=
            _availableHeight)
          break;
        if (s != key && _openSections.contains(s)) _openSections.remove(s);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(filterStateProvider);
    final filterAsync = ref.watch(filterIndexProvider);
    final notifier = ref.read(filterStateProvider.notifier);
    final hasActive = filter.hasActiveFilters;

    return Column(
      key: _containerKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Toggle bar ──────────────────────────────────────────────────
        InkWell(
          onTap: _toggleMain,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: hasActive
                  ? Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withValues(alpha: 0.5)
                  : Theme.of(context).colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.tune,
                  size: 16,
                  color: hasActive
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: hasActive
                      ? _ActiveFilterSummary(filter: filter)
                      : Text(
                          'Quick Filters',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                ),
                if (hasActive)
                  GestureDetector(
                    onTap: notifier.reset,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(Icons.close, size: 16, color: Colors.grey),
                    ),
                  ),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: const Icon(Icons.keyboard_arrow_down, size: 20),
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
            error: (_, __) => const SizedBox.shrink(),
            data: (index) => Container(
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  // Type — multi-select
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
                  // Attribute — multi-select
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
                  // Race — multi-select
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
                  // Level — multi-select
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
                  // Archetype — single-select
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
                        icon: const Icon(Icons.filter_alt_off, size: 16),
                        label: const Text('Reset All Filters'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(36),
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
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$activeCount',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                AnimatedRotation(
                  turns: isOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.keyboard_arrow_down, size: 18),
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

// ── Multi-select chip group — 2 rows, horizontal scroll ───────────────────────

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
              ? (chipColor ?? Theme.of(context).colorScheme.primary)
              : (chipColor?.withValues(alpha: 0.1) ??
                    Theme.of(context).colorScheme.surfaceContainerHighest),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? (chipColor ?? Theme.of(context).colorScheme.primary)
                : Colors.grey.withValues(alpha: 0.3),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : (chipColor ?? Colors.grey[700]),
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
          child: Text('–', style: TextStyle(fontSize: 16)),
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
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  option.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected ? Colors.white : Colors.grey[700],
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
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  filter.sortAscending
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  filter.sortAscending ? 'Ascending' : 'Descending',
                  style: const TextStyle(fontSize: 11),
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
    if (filter.levels.isNotEmpty)
      parts.add(filter.levels.map((v) => '★$v').join(', '));
    if (filter.races.isNotEmpty) parts.add(filter.races.join(', '));
    if (filter.archetype != null) parts.add(filter.archetype!);
    if (filter.atkMin != null || filter.atkMax != null) {
      parts.add('ATK ${filter.atkMin ?? 0}–${filter.atkMax ?? '∞'}');
    }
    if (filter.defMin != null || filter.defMax != null) {
      parts.add('DEF ${filter.defMin ?? 0}–${filter.defMax ?? '∞'}');
    }
    if (filter.searchQuery.isNotEmpty) parts.add('"${filter.searchQuery}"');

    return Text(
      parts.join(' · '),
      style: TextStyle(
        fontSize: 12,
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w500,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }
}

// ── Divider ────────────────────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Divider(
    height: 1,
    thickness: 1,
    color: Colors.grey.withValues(alpha: 0.15),
  );
}

// ── Color helpers ──────────────────────────────────────────────────────────────

Color _frameTypeColor(String frameType) {
  switch (frameType.toLowerCase()) {
    case 'normal':
      return const Color(0xFFB8860B);
    case 'effect':
      return const Color(0xFFD2691E);
    case 'ritual':
      return const Color(0xFF4169E1);
    case 'fusion':
      return const Color(0xFF8B008B);
    case 'synchro':
      return const Color(0xFF708090);
    case 'xyz':
      return const Color(0xFF2F4F4F);
    case 'link':
      return const Color(0xFF1E90FF);
    case 'spell':
      return const Color(0xFF2E8B57);
    case 'trap':
      return const Color(0xFFC71585);
    case 'token':
      return const Color(0xFF808080);
    default:
      if (frameType.contains('pendulum')) return const Color(0xFF20B2AA);
      return const Color(0xFF696969);
  }
}

Color _attributeColor(String attribute) {
  switch (attribute.toUpperCase()) {
    case 'DARK':
      return const Color(0xFF6A0DAD);
    case 'LIGHT':
      return const Color(0xFFDAA520);
    case 'FIRE':
      return const Color(0xFFCC2200);
    case 'WATER':
      return const Color(0xFF1565C0);
    case 'EARTH':
      return const Color(0xFF5D4037);
    case 'WIND':
      return const Color(0xFF2E7D32);
    case 'DIVINE':
      return const Color(0xFFE65100);
    default:
      return const Color(0xFF546E7A);
  }
}
