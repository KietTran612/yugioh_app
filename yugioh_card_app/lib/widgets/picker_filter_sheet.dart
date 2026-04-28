import 'package:flutter/material.dart';
import '../models/card_model.dart';
import '../models/filter_state.dart';
import '../utils/app_theme.dart';

// ── Picker filter state ───────────────────────────────────────────────────────
// Local immutable filter state, independent of global filterStateProvider.

class PickerFilter {
  final Set<String> frameTypes;
  final Set<String> attributes;
  final Set<String> races;
  final Set<int> levels;
  final String? archetype;
  final int? atkMin;
  final int? atkMax;
  final int? defMin;
  final int? defMax;
  final Set<String> tcgRarities;
  final Set<String> banlistStatuses;
  final Set<String> formats;
  final SortOption sortBy;
  final bool sortAscending;

  const PickerFilter({
    this.frameTypes = const {},
    this.attributes = const {},
    this.races = const {},
    this.levels = const {},
    this.archetype,
    this.atkMin,
    this.atkMax,
    this.defMin,
    this.defMax,
    this.tcgRarities = const {},
    this.banlistStatuses = const {},
    this.formats = const {},
    this.sortBy = SortOption.name,
    this.sortAscending = true,
  });

  bool get hasActive =>
      frameTypes.isNotEmpty ||
      attributes.isNotEmpty ||
      races.isNotEmpty ||
      levels.isNotEmpty ||
      archetype != null ||
      atkMin != null ||
      atkMax != null ||
      defMin != null ||
      defMax != null ||
      tcgRarities.isNotEmpty ||
      banlistStatuses.isNotEmpty ||
      formats.isNotEmpty;

  int get activeCount {
    int n = 0;
    if (frameTypes.isNotEmpty) n++;
    if (attributes.isNotEmpty) n++;
    if (races.isNotEmpty) n++;
    if (levels.isNotEmpty) n++;
    if (archetype != null) n++;
    if (atkMin != null || atkMax != null) n++;
    if (defMin != null || defMax != null) n++;
    if (tcgRarities.isNotEmpty) n++;
    if (banlistStatuses.isNotEmpty) n++;
    if (formats.isNotEmpty) n++;
    return n;
  }

  PickerFilter copyWith({
    Set<String>? frameTypes,
    Set<String>? attributes,
    Set<String>? races,
    Set<int>? levels,
    Object? archetype = _sentinel,
    Object? atkMin = _sentinel,
    Object? atkMax = _sentinel,
    Object? defMin = _sentinel,
    Object? defMax = _sentinel,
    Set<String>? tcgRarities,
    Set<String>? banlistStatuses,
    Set<String>? formats,
    SortOption? sortBy,
    bool? sortAscending,
  }) => PickerFilter(
    frameTypes: frameTypes ?? this.frameTypes,
    attributes: attributes ?? this.attributes,
    races: races ?? this.races,
    levels: levels ?? this.levels,
    archetype: archetype == _sentinel ? this.archetype : archetype as String?,
    atkMin: atkMin == _sentinel ? this.atkMin : atkMin as int?,
    atkMax: atkMax == _sentinel ? this.atkMax : atkMax as int?,
    defMin: defMin == _sentinel ? this.defMin : defMin as int?,
    defMax: defMax == _sentinel ? this.defMax : defMax as int?,
    tcgRarities: tcgRarities ?? this.tcgRarities,
    banlistStatuses: banlistStatuses ?? this.banlistStatuses,
    formats: formats ?? this.formats,
    sortBy: sortBy ?? this.sortBy,
    sortAscending: sortAscending ?? this.sortAscending,
  );

  PickerFilter reset() => const PickerFilter();
}

const _sentinel = Object();

// ── Filter bottom sheet ───────────────────────────────────────────────────────

class PickerFilterSheet extends StatefulWidget {
  final FilterIndex filterIndex;
  final PickerFilter current;
  final ValueChanged<PickerFilter> onApply;

  const PickerFilterSheet({
    super.key,
    required this.filterIndex,
    required this.current,
    required this.onApply,
  });

  @override
  State<PickerFilterSheet> createState() => _PickerFilterSheetState();
}

class _PickerFilterSheetState extends State<PickerFilterSheet> {
  late PickerFilter _draft;
  final _atkMinCtrl = TextEditingController();
  final _atkMaxCtrl = TextEditingController();
  final _defMinCtrl = TextEditingController();
  final _defMaxCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _draft = widget.current;
    _atkMinCtrl.text = _draft.atkMin?.toString() ?? '';
    _atkMaxCtrl.text = _draft.atkMax?.toString() ?? '';
    _defMinCtrl.text = _draft.defMin?.toString() ?? '';
    _defMaxCtrl.text = _draft.defMax?.toString() ?? '';
  }

  @override
  void dispose() {
    _atkMinCtrl.dispose();
    _atkMaxCtrl.dispose();
    _defMinCtrl.dispose();
    _defMaxCtrl.dispose();
    super.dispose();
  }

  void _reset() {
    final reset = const PickerFilter();
    setState(() => _draft = reset);
    widget.onApply(reset);
    _atkMinCtrl.clear();
    _atkMaxCtrl.clear();
    _defMinCtrl.clear();
    _defMaxCtrl.clear();
  }

  void _toggleStr(
    String v,
    Set<String> cur,
    PickerFilter Function(Set<String>) upd,
  ) {
    final s = Set<String>.from(cur);
    s.contains(v) ? s.remove(v) : s.add(v);
    final next = upd(s);
    setState(() => _draft = next);
    widget.onApply(next);
  }

  void _toggleInt(int v, Set<int> cur, PickerFilter Function(Set<int>) upd) {
    final s = Set<int>.from(cur);
    s.contains(v) ? s.remove(v) : s.add(v);
    final next = upd(s);
    setState(() => _draft = next);
    widget.onApply(next);
  }

  @override
  Widget build(BuildContext context) {
    final idx = widget.filterIndex;
    return Column(
      children: [
        // Handle
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: AppTheme.textMuted,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 12, 0),
          child: Row(
            children: [
              const Text(
                'Filter Cards',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (_draft.hasActive)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_draft.activeCount}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              TextButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.filter_alt_off, size: 16),
                label: const Text('Reset'),
              ),
            ],
          ),
        ),
        const Divider(color: AppTheme.bgBorder, height: 8),

        // Content
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            children: [
              _FilterSection(
                title: 'Card Type',
                count: _draft.frameTypes.length,
              ),
              _ChipGroup<String>(
                items: idx.frameTypes,
                selected: _draft.frameTypes,
                onToggle: (v) => _toggleStr(
                  v,
                  _draft.frameTypes,
                  (s) => _draft.copyWith(frameTypes: s),
                ),
              ),
              const SizedBox(height: 16),

              _FilterSection(
                title: 'Attribute',
                count: _draft.attributes.length,
              ),
              _ChipGroup<String>(
                items: idx.attributes,
                selected: _draft.attributes,
                onToggle: (v) => _toggleStr(
                  v,
                  _draft.attributes,
                  (s) => _draft.copyWith(attributes: s),
                ),
                colorBuilder: (a) => AppTheme.getAttributeColor(a),
              ),
              const SizedBox(height: 16),

              _FilterSection(title: 'Race / Type', count: _draft.races.length),
              _ChipGroup<String>(
                items: idx.races,
                selected: _draft.races,
                onToggle: (v) => _toggleStr(
                  v,
                  _draft.races,
                  (s) => _draft.copyWith(races: s),
                ),
              ),
              const SizedBox(height: 16),

              _FilterSection(
                title: 'Level / Rank',
                count: _draft.levels.length,
              ),
              _ChipGroup<int>(
                items: idx.levels,
                selected: _draft.levels,
                itemLabel: (v) => '★$v',
                onToggle: (v) => _toggleInt(
                  v,
                  _draft.levels,
                  (s) => _draft.copyWith(levels: s),
                ),
              ),
              const SizedBox(height: 16),

              _FilterSection(
                title: 'Archetype',
                count: _draft.archetype != null ? 1 : 0,
              ),
              DropdownButtonFormField<String>(
                value: _draft.archetype,
                decoration: pickerInputDecoration('Archetype'),
                isExpanded: true,
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('All'),
                  ),
                  ...idx.archetypes.map(
                    (a) => DropdownMenuItem(
                      value: a,
                      child: Text(a, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: (v) {
                  final next = _draft.copyWith(archetype: v);
                  setState(() => _draft = next);
                  widget.onApply(next);
                },
              ),
              const SizedBox(height: 16),

              _FilterSection(
                title: 'ATK Range',
                count: (_draft.atkMin != null || _draft.atkMax != null) ? 1 : 0,
              ),
              _RangeRow(
                minCtrl: _atkMinCtrl,
                maxCtrl: _atkMaxCtrl,
                onChanged: (min, max) {
                  final next = _draft.copyWith(atkMin: min, atkMax: max);
                  setState(() => _draft = next);
                  widget.onApply(next);
                },
              ),
              const SizedBox(height: 16),

              _FilterSection(
                title: 'DEF Range',
                count: (_draft.defMin != null || _draft.defMax != null) ? 1 : 0,
              ),
              _RangeRow(
                minCtrl: _defMinCtrl,
                maxCtrl: _defMaxCtrl,
                onChanged: (min, max) {
                  final next = _draft.copyWith(defMin: min, defMax: max);
                  setState(() => _draft = next);
                  widget.onApply(next);
                },
              ),
              const SizedBox(height: 16),

              _FilterSection(
                title: 'TCG Rarity',
                count: _draft.tcgRarities.length,
              ),
              _ChipGroup<String>(
                items: idx.tcgRarities,
                selected: _draft.tcgRarities,
                onToggle: (v) => _toggleStr(
                  v,
                  _draft.tcgRarities,
                  (s) => _draft.copyWith(tcgRarities: s),
                ),
                colorBuilder: (c) => AppTheme.getTcgRarityColor(c),
              ),
              const SizedBox(height: 16),

              _FilterSection(
                title: 'Banlist',
                count: _draft.banlistStatuses.length,
              ),
              _ChipGroup<String>(
                items: const ['Forbidden', 'Limited', 'Semi-Limited'],
                selected: _draft.banlistStatuses,
                onToggle: (v) => _toggleStr(
                  v,
                  _draft.banlistStatuses,
                  (s) => _draft.copyWith(banlistStatuses: s),
                ),
                colorBuilder: (s) => AppTheme.getBanlistColor(s),
              ),
              const SizedBox(height: 16),

              _FilterSection(title: 'Format', count: _draft.formats.length),
              _ChipGroup<String>(
                items: const ['TCG', 'OCG', 'Master Duel', 'GOAT'],
                selected: _draft.formats,
                onToggle: (v) => _toggleStr(
                  v,
                  _draft.formats,
                  (s) => _draft.copyWith(formats: s),
                ),
              ),
              const SizedBox(height: 16),

              const _FilterSection(title: 'Sort By', count: 0),
              _SortRow(
                sortBy: _draft.sortBy,
                ascending: _draft.sortAscending,
                onSortChanged: (v) {
                  final next = _draft.copyWith(sortBy: v);
                  setState(() => _draft = next);
                  widget.onApply(next);
                },
                onDirectionToggle: () {
                  final next = _draft.copyWith(
                    sortAscending: !_draft.sortAscending,
                  );
                  setState(() => _draft = next);
                  widget.onApply(next);
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),

        // Done button
        Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            MediaQuery.of(context).padding.bottom + 16,
          ),
          child: FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(
              backgroundColor: _draft.hasActive
                  ? AppTheme.accent
                  : AppTheme.bgElevated,
              foregroundColor: _draft.hasActive
                  ? Colors.black
                  : AppTheme.textSecondary,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _draft.hasActive ? 'Done (${_draft.activeCount} active)' : 'Done',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Shared InputDecoration ────────────────────────────────────────────────────

InputDecoration pickerInputDecoration(String label) => InputDecoration(
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

// ── Filter section header ─────────────────────────────────────────────────────

class _FilterSection extends StatelessWidget {
  final String title;
  final int count;
  const _FilterSection({required this.title, this.count = 0});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
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
            ),
          ),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: AppTheme.accent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Chip group ────────────────────────────────────────────────────────────────

class _ChipGroup<T> extends StatelessWidget {
  final List<T> items;
  final Set<T> selected;
  final void Function(T) onToggle;
  final String Function(T)? itemLabel;
  final Color Function(T)? colorBuilder;

  const _ChipGroup({
    required this.items,
    required this.selected,
    required this.onToggle,
    this.itemLabel,
    this.colorBuilder,
  });

  String _label(T item) =>
      itemLabel != null ? itemLabel!(item) : item.toString();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: items.map((item) {
        final active = selected.contains(item);
        final color = colorBuilder?.call(item) ?? AppTheme.accent;
        return GestureDetector(
          onTap: () => onToggle(item),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 130),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: active
                  ? color.withValues(alpha: 0.18)
                  : AppTheme.bgElevated,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: active ? color : AppTheme.bgBorder,
                width: active ? 1.5 : 1,
              ),
            ),
            child: Text(
              _label(item),
              style: TextStyle(
                fontSize: 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.normal,
                color: active ? color : AppTheme.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Range row ─────────────────────────────────────────────────────────────────

class _RangeRow extends StatelessWidget {
  final TextEditingController minCtrl;
  final TextEditingController maxCtrl;
  final void Function(int? min, int? max) onChanged;

  const _RangeRow({
    required this.minCtrl,
    required this.maxCtrl,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: minCtrl,
            decoration: pickerInputDecoration('Min'),
            keyboardType: TextInputType.number,
            onChanged: (v) =>
                onChanged(int.tryParse(v), int.tryParse(maxCtrl.text)),
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
          child: TextField(
            controller: maxCtrl,
            decoration: pickerInputDecoration('Max'),
            keyboardType: TextInputType.number,
            onChanged: (v) =>
                onChanged(int.tryParse(minCtrl.text), int.tryParse(v)),
          ),
        ),
      ],
    );
  }
}

// ── Sort row ──────────────────────────────────────────────────────────────────

class _SortRow extends StatelessWidget {
  final SortOption sortBy;
  final bool ascending;
  final ValueChanged<SortOption> onSortChanged;
  final VoidCallback onDirectionToggle;

  const _SortRow({
    required this.sortBy,
    required this.ascending,
    required this.onSortChanged,
    required this.onDirectionToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<SortOption>(
            value: sortBy,
            decoration: pickerInputDecoration('Sort'),
            items: SortOption.values
                .map((o) => DropdownMenuItem(value: o, child: Text(o.label)))
                .toList(),
            onChanged: (v) {
              if (v != null) onSortChanged(v);
            },
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(
            ascending ? Icons.arrow_upward : Icons.arrow_downward,
            color: AppTheme.accent,
          ),
          onPressed: onDirectionToggle,
          tooltip: ascending ? 'Ascending' : 'Descending',
        ),
      ],
    );
  }
}
