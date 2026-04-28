import 'package:flutter/material.dart';
import '../models/filter_state.dart';
import '../providers/card_provider.dart';
import '../utils/app_theme.dart';

// ── Collapsible section ───────────────────────────────────────────────────────

class FilterCollapsibleSection extends StatelessWidget {
  final String title;
  final bool isOpen;
  final int activeCount;
  final VoidCallback onToggle;
  final Widget child;

  const FilterCollapsibleSection({
    super.key,
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

// ── Multi-select chip group ───────────────────────────────────────────────────

class FilterMultiChipGroup<T> extends StatelessWidget {
  final List<T> items;
  final Set<T> selected;
  final void Function(T) onTap;
  final String Function(T)? labelBuilder;
  final Color Function(T)? colorBuilder;

  const FilterMultiChipGroup({
    super.key,
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
    // Split into two rows for visual balance
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

// ── Range input ───────────────────────────────────────────────────────────────

class FilterRangeInput extends StatelessWidget {
  final int? minValue;
  final int? maxValue;
  final void Function(int? min, int? max) onChanged;

  const FilterRangeInput({
    super.key,
    this.minValue,
    this.maxValue,
    required this.onChanged,
  });

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

// ── Sort selector ─────────────────────────────────────────────────────────────

class FilterSortSelector extends StatelessWidget {
  final FilterState filter;
  final FilterStateNotifier notifier;
  const FilterSortSelector({
    super.key,
    required this.filter,
    required this.notifier,
  });

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

// ── Active filter summary ─────────────────────────────────────────────────────

class FilterActiveSummary extends StatelessWidget {
  final FilterState filter;
  const FilterActiveSummary({super.key, required this.filter});

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

// ── Thin divider ──────────────────────────────────────────────────────────────

class FilterDivider extends StatelessWidget {
  const FilterDivider({super.key});

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, thickness: 1, color: AppTheme.bgBorder);
}
