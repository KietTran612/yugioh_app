/// Holds the current filter/search state for the card list.
class FilterState {
  final String searchQuery;

  // Multi-select filters
  final Set<String> frameTypes; // e.g. {'effect', 'fusion'}
  final Set<String> attributes; // e.g. {'DARK', 'LIGHT'}
  final Set<String> races; // e.g. {'Dragon', 'Warrior'}
  final Set<int> levels; // e.g. {4, 8}

  // Single-select filters
  final String? archetype;
  final int? atkMin;
  final int? atkMax;
  final int? defMin;
  final int? defMax;
  final SortOption sortBy;
  final bool sortAscending;

  const FilterState({
    this.searchQuery = '',
    this.frameTypes = const {},
    this.attributes = const {},
    this.races = const {},
    this.levels = const {},
    this.archetype,
    this.atkMin,
    this.atkMax,
    this.defMin,
    this.defMax,
    this.sortBy = SortOption.name,
    this.sortAscending = true,
  });

  bool get hasActiveFilters =>
      searchQuery.isNotEmpty ||
      frameTypes.isNotEmpty ||
      attributes.isNotEmpty ||
      races.isNotEmpty ||
      levels.isNotEmpty ||
      archetype != null ||
      atkMin != null ||
      atkMax != null ||
      defMin != null ||
      defMax != null;

  FilterState copyWith({
    String? searchQuery,
    Set<String>? frameTypes,
    Set<String>? attributes,
    Set<String>? races,
    Set<int>? levels,
    Object? archetype = _sentinel,
    Object? atkMin = _sentinel,
    Object? atkMax = _sentinel,
    Object? defMin = _sentinel,
    Object? defMax = _sentinel,
    SortOption? sortBy,
    bool? sortAscending,
  }) {
    return FilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      frameTypes: frameTypes ?? this.frameTypes,
      attributes: attributes ?? this.attributes,
      races: races ?? this.races,
      levels: levels ?? this.levels,
      archetype: archetype == _sentinel ? this.archetype : archetype as String?,
      atkMin: atkMin == _sentinel ? this.atkMin : atkMin as int?,
      atkMax: atkMax == _sentinel ? this.atkMax : atkMax as int?,
      defMin: defMin == _sentinel ? this.defMin : defMin as int?,
      defMax: defMax == _sentinel ? this.defMax : defMax as int?,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }

  FilterState reset() => const FilterState();
}

const _sentinel = Object();

enum SortOption { name, atk, def, level, type }

extension SortOptionLabel on SortOption {
  String get label {
    switch (this) {
      case SortOption.name:
        return 'Name';
      case SortOption.atk:
        return 'ATK';
      case SortOption.def:
        return 'DEF';
      case SortOption.level:
        return 'Level / Rank';
      case SortOption.type:
        return 'Type';
    }
  }
}
