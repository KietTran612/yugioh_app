import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/filter_state.dart';
import '../providers/card_provider.dart';
import '../utils/app_theme.dart';

class FilterPanel extends ConsumerWidget {
  final ScrollController? scrollController;
  const FilterPanel({super.key, this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterAsync = ref.watch(filterIndexProvider);

    return filterAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.accent),
      ),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (index) => Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.textMuted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filters',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                _ResetButton(),
              ],
            ),
          ),
          const Divider(color: AppTheme.bgBorder, height: 16),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                _SectionTitle('Card Type'),
                _FrameTypeDropdown(items: index.frameTypes),
                const SizedBox(height: 12),

                _SectionTitle('Attribute'),
                _AttributeDropdown(items: index.attributes),
                const SizedBox(height: 12),

                _SectionTitle('Race / Type'),
                _RaceDropdown(items: index.races),
                const SizedBox(height: 12),

                _SectionTitle('Level / Rank'),
                _LevelDropdown(items: index.levels),
                const SizedBox(height: 12),

                _SectionTitle('Archetype'),
                _ArchetypeDropdown(items: index.archetypes),
                const SizedBox(height: 12),

                _SectionTitle('ATK Range'),
                _AtkRangeRow(),
                const SizedBox(height: 12),

                _SectionTitle('DEF Range'),
                _DefRangeRow(),
                const SizedBox(height: 12),

                _SectionTitle('Sort By'),
                _SortRow(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Each filter is its own Consumer — only rebuilds when its value changes ─────

class _ResetButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasFilters = ref.watch(
      filterStateProvider.select((s) => s.hasActiveFilters),
    );
    return TextButton.icon(
      onPressed: hasFilters
          ? () => ref.read(filterStateProvider.notifier).reset()
          : null,
      icon: const Icon(Icons.filter_alt_off, size: 16),
      label: const Text('Reset'),
    );
  }
}

class _FrameTypeDropdown extends ConsumerWidget {
  final List<String> items;
  const _FrameTypeDropdown({required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(filterStateProvider.select((s) => s.frameTypes));
    final notifier = ref.read(filterStateProvider.notifier);
    return _MultiSelectDropdown<String>(
      label: 'Frame Type',
      items: items,
      selected: selected,
      onToggle: notifier.toggleFrameType,
    );
  }
}

class _AttributeDropdown extends ConsumerWidget {
  final List<String> items;
  const _AttributeDropdown({required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(filterStateProvider.select((s) => s.attributes));
    final notifier = ref.read(filterStateProvider.notifier);
    return _MultiSelectDropdown<String>(
      label: 'Attribute',
      items: items,
      selected: selected,
      onToggle: notifier.toggleAttribute,
    );
  }
}

class _RaceDropdown extends ConsumerWidget {
  final List<String> items;
  const _RaceDropdown({required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(filterStateProvider.select((s) => s.races));
    final notifier = ref.read(filterStateProvider.notifier);
    return _MultiSelectDropdown<String>(
      label: 'Race',
      items: items,
      selected: selected,
      onToggle: notifier.toggleRace,
    );
  }
}

class _LevelDropdown extends ConsumerWidget {
  final List<int> items;
  const _LevelDropdown({required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(filterStateProvider.select((s) => s.levels));
    final notifier = ref.read(filterStateProvider.notifier);
    return _MultiSelectDropdown<int>(
      label: 'Level / Rank',
      items: items,
      selected: selected,
      itemLabel: (v) => v.toString(),
      onToggle: notifier.toggleLevel,
    );
  }
}

class _ArchetypeDropdown extends ConsumerWidget {
  final List<String> items;
  const _ArchetypeDropdown({required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(filterStateProvider.select((s) => s.archetype));
    return _DropdownFilter<String>(
      label: 'Archetype',
      value: value,
      items: items,
      onChanged: ref.read(filterStateProvider.notifier).setArchetype,
    );
  }
}

class _AtkRangeRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final min = ref.watch(filterStateProvider.select((s) => s.atkMin));
    final max = ref.watch(filterStateProvider.select((s) => s.atkMax));
    return _RangeRow(
      minValue: min,
      maxValue: max,
      onChanged: ref.read(filterStateProvider.notifier).setAtkRange,
    );
  }
}

class _DefRangeRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final min = ref.watch(filterStateProvider.select((s) => s.defMin));
    final max = ref.watch(filterStateProvider.select((s) => s.defMax));
    return _RangeRow(
      minValue: min,
      maxValue: max,
      onChanged: ref.read(filterStateProvider.notifier).setDefRange,
    );
  }
}

class _SortRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sortBy = ref.watch(filterStateProvider.select((s) => s.sortBy));
    final ascending = ref.watch(
      filterStateProvider.select((s) => s.sortAscending),
    );
    final notifier = ref.read(filterStateProvider.notifier);

    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<SortOption>(
            initialValue: sortBy,
            decoration: _inputDecoration('Sort'),
            items: SortOption.values
                .map((o) => DropdownMenuItem(value: o, child: Text(o.label)))
                .toList(),
            onChanged: (v) {
              if (v != null) notifier.setSortBy(v);
            },
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(ascending ? Icons.arrow_upward : Icons.arrow_downward),
          onPressed: notifier.toggleSortDirection,
          tooltip: ascending ? 'Ascending' : 'Descending',
        ),
      ],
    );
  }
}

// ── Shared UI helpers ──────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: AppTheme.accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ],
    ),
  );
}

class _DropdownFilter<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> items;
  final String Function(T)? itemLabel;
  final void Function(T?) onChanged;

  const _DropdownFilter({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.itemLabel,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: _inputDecoration(label),
      isExpanded: true,
      items: [
        DropdownMenuItem<T>(value: null, child: const Text('All')),
        ...items.map(
          (item) => DropdownMenuItem<T>(
            value: item,
            child: Text(
              itemLabel != null ? itemLabel!(item) : item.toString(),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
}

class _RangeRow extends StatelessWidget {
  final int? minValue;
  final int? maxValue;
  final void Function(int? min, int? max) onChanged;

  const _RangeRow({this.minValue, this.maxValue, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            initialValue: minValue?.toString() ?? '',
            decoration: _inputDecoration('Min'),
            keyboardType: TextInputType.number,
            onChanged: (v) => onChanged(int.tryParse(v), maxValue),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text('–'),
        ),
        Expanded(
          child: TextFormField(
            initialValue: maxValue?.toString() ?? '',
            decoration: _inputDecoration('Max'),
            keyboardType: TextInputType.number,
            onChanged: (v) => onChanged(minValue, int.tryParse(v)),
          ),
        ),
      ],
    );
  }
}

InputDecoration _inputDecoration(String label) => InputDecoration(
  labelText: label,
  labelStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
  filled: true,
  fillColor: AppTheme.bgElevated,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: AppTheme.bgBorder),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: AppTheme.bgBorder),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: AppTheme.accent, width: 1.5),
  ),
  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  isDense: true,
);

// ── Multi-select dropdown (shows selected count, opens wrap of chips) ──────────

class _MultiSelectDropdown<T> extends StatelessWidget {
  final String label;
  final List<T> items;
  final Set<T> selected;
  final void Function(T) onToggle;
  final String Function(T)? itemLabel;

  const _MultiSelectDropdown({
    required this.label,
    required this.items,
    required this.selected,
    required this.onToggle,
    this.itemLabel,
  });

  String _labelOf(T item) =>
      itemLabel != null ? itemLabel!(item) : item.toString();

  @override
  Widget build(BuildContext context) {
    final hint = selected.isEmpty ? 'All' : selected.map(_labelOf).join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.bgElevated,
            border: Border.all(color: AppTheme.bgBorder),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '$label: $hint',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (selected.isNotEmpty)
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
                    '${selected.length}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Chip wrap
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: items.map((item) {
            final isSelected = selected.contains(item);
            return GestureDetector(
              onTap: () => onToggle(item),
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
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  _labelOf(item),
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
      ],
    );
  }
}
