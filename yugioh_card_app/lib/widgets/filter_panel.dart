import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/filter_state.dart';
import '../providers/card_provider.dart';

class FilterPanel extends ConsumerWidget {
  const FilterPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterAsync = ref.watch(filterIndexProvider);
    final filter = ref.watch(filterStateProvider);
    final notifier = ref.read(filterStateProvider.notifier);

    return filterAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (index) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Frame Type ──────────────────────────────────────────────────
          _SectionTitle('Card Type'),
          _DropdownFilter(
            label: 'Frame Type',
            value: filter.frameType,
            items: index.frameTypes,
            onChanged: notifier.setFrameType,
          ),
          const SizedBox(height: 12),

          // ── Attribute ───────────────────────────────────────────────────
          _SectionTitle('Attribute'),
          _DropdownFilter(
            label: 'Attribute',
            value: filter.attribute,
            items: index.attributes,
            onChanged: notifier.setAttribute,
          ),
          const SizedBox(height: 12),

          // ── Race / Type ─────────────────────────────────────────────────
          _SectionTitle('Race / Type'),
          _DropdownFilter(
            label: 'Race',
            value: filter.race,
            items: index.races,
            onChanged: notifier.setRace,
          ),
          const SizedBox(height: 12),

          // ── Level / Rank ────────────────────────────────────────────────
          _SectionTitle('Level / Rank'),
          _DropdownFilter<int>(
            label: 'Level',
            value: filter.level,
            items: index.levels,
            itemLabel: (v) => v.toString(),
            onChanged: notifier.setLevel,
          ),
          const SizedBox(height: 12),

          // ── Archetype ───────────────────────────────────────────────────
          _SectionTitle('Archetype'),
          _DropdownFilter(
            label: 'Archetype',
            value: filter.archetype,
            items: index.archetypes,
            onChanged: notifier.setArchetype,
          ),
          const SizedBox(height: 12),

          // ── ATK Range ───────────────────────────────────────────────────
          _SectionTitle('ATK Range'),
          _RangeRow(
            minValue: filter.atkMin,
            maxValue: filter.atkMax,
            onChanged: notifier.setAtkRange,
          ),
          const SizedBox(height: 12),

          // ── DEF Range ───────────────────────────────────────────────────
          _SectionTitle('DEF Range'),
          _RangeRow(
            minValue: filter.defMin,
            maxValue: filter.defMax,
            onChanged: notifier.setDefRange,
          ),
          const SizedBox(height: 12),

          // ── Sort ────────────────────────────────────────────────────────
          _SectionTitle('Sort By'),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<SortOption>(
                  initialValue: filter.sortBy,
                  decoration: _inputDecoration('Sort'),
                  items: SortOption.values
                      .map(
                        (o) => DropdownMenuItem(value: o, child: Text(o.label)),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) notifier.setSortBy(v);
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  filter.sortAscending
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                ),
                onPressed: notifier.toggleSortDirection,
                tooltip: filter.sortAscending ? 'Ascending' : 'Descending',
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Reset ───────────────────────────────────────────────────────
          FilledButton.icon(
            onPressed: filter.hasActiveFilters ? notifier.reset : null,
            icon: const Icon(Icons.filter_alt_off),
            label: const Text('Reset Filters'),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

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
      initialValue: value,
      decoration: _inputDecoration(label),
      isExpanded: true,
      items: [
        DropdownMenuItem<T>(value: null, child: Text('All')),
        ...items.map(
          (item) => DropdownMenuItem<T>(
            value: item,
            child: Text(itemLabel != null ? itemLabel!(item) : item.toString()),
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
