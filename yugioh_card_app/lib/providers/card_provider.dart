import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/card_model.dart';
import '../models/filter_state.dart';
import '../services/card_data_service.dart';

// ── Raw data provider ─────────────────────────────────────────────────────────

final cardDataProvider = FutureProvider<CardDataResult>((ref) async {
  return await CardDataService.loadCards();
});

// ── Filter state provider ─────────────────────────────────────────────────────

final filterStateProvider =
    StateNotifierProvider<FilterStateNotifier, FilterState>(
      (ref) => FilterStateNotifier(),
    );

class FilterStateNotifier extends StateNotifier<FilterState> {
  FilterStateNotifier() : super(const FilterState());

  void setSearch(String query) => state = state.copyWith(searchQuery: query);

  // Multi-select toggles
  void toggleFrameType(String value) {
    final updated = Set<String>.from(state.frameTypes);
    if (updated.contains(value))
      updated.remove(value);
    else
      updated.add(value);
    state = state.copyWith(frameTypes: updated);
  }

  void toggleAttribute(String value) {
    final updated = Set<String>.from(state.attributes);
    if (updated.contains(value))
      updated.remove(value);
    else
      updated.add(value);
    state = state.copyWith(attributes: updated);
  }

  void toggleRace(String value) {
    final updated = Set<String>.from(state.races);
    if (updated.contains(value))
      updated.remove(value);
    else
      updated.add(value);
    state = state.copyWith(races: updated);
  }

  void toggleLevel(int value) {
    final updated = Set<int>.from(state.levels);
    if (updated.contains(value))
      updated.remove(value);
    else
      updated.add(value);
    state = state.copyWith(levels: updated);
  }

  // Single-select
  void setArchetype(String? value) => state = state.copyWith(archetype: value);
  void setAtkRange(int? min, int? max) =>
      state = state.copyWith(atkMin: min, atkMax: max);
  void setDefRange(int? min, int? max) =>
      state = state.copyWith(defMin: min, defMax: max);
  void setSortBy(SortOption option) => state = state.copyWith(sortBy: option);
  void toggleSortDirection() =>
      state = state.copyWith(sortAscending: !state.sortAscending);
  void reset() => state = state.reset();
}

// ── Filtered cards provider ───────────────────────────────────────────────────

final filteredCardsProvider = Provider<AsyncValue<List<YugiohCard>>>((ref) {
  final dataAsync = ref.watch(cardDataProvider);
  final filter = ref.watch(filterStateProvider);
  return dataAsync.whenData((data) => _applyFilter(data.cards, filter));
});

List<YugiohCard> _applyFilter(List<YugiohCard> allCards, FilterState filter) {
  var cards = allCards;

  if (filter.searchQuery.isNotEmpty) {
    final q = filter.searchQuery.toLowerCase();
    cards = cards
        .where(
          (c) =>
              c.name.toLowerCase().contains(q) ||
              c.desc.toLowerCase().contains(q),
        )
        .toList();
  }

  // Multi-select: card must match ANY selected value (OR logic)
  if (filter.frameTypes.isNotEmpty) {
    cards = cards
        .where((c) => filter.frameTypes.contains(c.frameType))
        .toList();
  }
  if (filter.attributes.isNotEmpty) {
    cards = cards
        .where((c) => filter.attributes.contains(c.attribute))
        .toList();
  }
  if (filter.races.isNotEmpty) {
    cards = cards.where((c) => filter.races.contains(c.race)).toList();
  }
  if (filter.levels.isNotEmpty) {
    cards = cards
        .where((c) => c.level != null && filter.levels.contains(c.level))
        .toList();
  }

  // Single-select
  if (filter.archetype != null) {
    cards = cards.where((c) => c.archetype == filter.archetype).toList();
  }
  if (filter.atkMin != null) {
    cards = cards
        .where((c) => c.atk != null && c.atk! >= filter.atkMin!)
        .toList();
  }
  if (filter.atkMax != null) {
    cards = cards
        .where((c) => c.atk != null && c.atk! <= filter.atkMax!)
        .toList();
  }
  if (filter.defMin != null) {
    cards = cards
        .where((c) => c.def != null && c.def! >= filter.defMin!)
        .toList();
  }
  if (filter.defMax != null) {
    cards = cards
        .where((c) => c.def != null && c.def! <= filter.defMax!)
        .toList();
  }

  // Sort
  final sorted = List<YugiohCard>.from(cards);
  sorted.sort((a, b) {
    int cmp;
    switch (filter.sortBy) {
      case SortOption.name:
        cmp = a.name.compareTo(b.name);
        break;
      case SortOption.atk:
        cmp = (a.atk ?? -1).compareTo(b.atk ?? -1);
        break;
      case SortOption.def:
        cmp = (a.def ?? -1).compareTo(b.def ?? -1);
        break;
      case SortOption.level:
        cmp = (a.level ?? 0).compareTo(b.level ?? 0);
        break;
      case SortOption.type:
        cmp = a.type.compareTo(b.type);
        break;
    }
    return filter.sortAscending ? cmp : -cmp;
  });

  return sorted;
}

// ── Filter index provider ─────────────────────────────────────────────────────

final filterIndexProvider = Provider<AsyncValue<FilterIndex>>((ref) {
  return ref.watch(cardDataProvider).whenData((d) => d.filterIndex);
});
