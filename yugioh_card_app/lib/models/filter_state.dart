/// Holds the current filter/search state for the card list.
class FilterState {
  final String searchQuery;
  final String? frameType;     // spell | trap | effect | fusion | synchro | xyz | link | ritual | pendulum | normal
  final String? attribute;     // DARK | LIGHT | FIRE | WATER | EARTH | WIND | DIVINE
  final String? race;          // Dragon | Warrior | Spellcaster | ...
  final String? archetype;
  final int? level;
  final int? atkMin;
  final int? atkMax;
  final int? defMin;
  final int? defMax;
  final SortOption sortBy;
  final bool sortAscending;

  const FilterState({
    this.searchQuery = '',
    this.frameType,
    this.attribute,
    this.race,
    this.archetype,
    this.level,
    this.atkMin,
    this.atkMax,
    this.defMin,
    this.defMax,
    this.sortBy = SortOption.name,
    this.sortAscending = true,
  });

  bool get hasActiveFilters =>
      searchQuery.isNotEmpty ||
      frameType != null ||
      attribute != null ||
      race != null ||
      archetype != null ||
      level != null ||
      atkMin != null ||
      atkMax != null ||
      defMin != null ||
      defMax != null;

  FilterState copyWith({
    String? searchQuery,
    Object? frameType = _sentinel,
    Object? attribute = _sentinel,
    Object? race = _sentinel,
    Object? archetype = _sentinel,
    Object? level = _sentinel,
    Object? atkMin = _sentinel,
    Object? atkMax = _sentinel,
    Object? defMin = _sentinel,
    Object? defMax = _sentinel,
    SortOption? sortBy,
    bool? sortAscending,
  }) {
    return FilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      frameType: frameType == _sentinel ? this.frameType : frameType as String?,
      attribute: attribute == _sentinel ? this.attribute : attribute as String?,
      race: race == _sentinel ? this.race : race as String?,
      archetype: archetype == _sentinel ? this.archetype : archetype as String?,
      level: level == _sentinel ? this.level : level as int?,
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

// Sentinel object to distinguish null from "not provided"
const _sentinel = Object();

enum SortOption {
  name,
  atk,
  def,
  level,
  type,
}

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
