import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/filter_state.dart';
import '../providers/card_provider.dart';

class FilterPanel extends ConsumerWidget {
  final ScrollController? scrollController;
  const FilterPanel({super.key, this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterAsync = ref.watch(filterIndexProvider);

    return filterAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (index) => Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filters',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Reset button — only watches hasActiveFilters
                _ResetButton(),
              ],
            ),
          ),
          const Divider(),
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
    final value = ref.watch(filterStateProvider.select((s) => s.frameType));
    return _DropdownFilter<String>(
      label: 'Frame Type',
      value: value,
      items: items,
      onChanged: ref.read(filterStateProvider.notifier).setFrameType,
    );
  }
}

class _AttributeDropdown extends ConsumerWidget {
  final List<String> items;
  const _AttributeDropdown({required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(filterStateProvider.select((s) => s.attribute));
    return _DropdownFilter<String>(
      label: 'Attribute',
      value: value,
      items: items,
      onChanged: ref.read(filterStateProvider.notifier).setAttribute,
    );
  }
}

class _RaceDropdown extends ConsumerWidget {
  final List<String> items;
  const _RaceDropdown({required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(filterStateProvider.select((s) => s.race));
    return _DropdownFilter<String>(
      label: 'Race',
      value: value,
      items: items,
      onChanged: ref.read(filterStateProvider.notifier).setRace,
    );
  }
}

class _LevelDropdown extends ConsumerWidget {
  final List<int> items;
  const _LevelDropdown({required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(filterStateProvider.select((s) => s.level));
    return _DropdownFilter<int>(
      label: 'Level / Rank',
      value: value,
      items: items,
      itemLabel: (v) => v.toString(),
      onChanged: ref.read(filterStateProvider.notifier).setLevel,
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
            value: sortBy,
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
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
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
      value: value,
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
  border: const OutlineInputBorder(),
  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  isDense: true,
);
