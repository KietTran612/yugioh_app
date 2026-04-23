import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/card_model.dart';
import '../models/filter_state.dart';
import '../services/card_data_service.dart';

// ── Loading status provider ───────────────────────────────────────────────────

final loadingStatusProvider = StateProvider<String?>((ref) => null);

// ── Raw data provider ─────────────────────────────────────────────────────────

final cardDataProvider = FutureProvider<CardDataResult>((ref) async {
  final setStatus = ref.read(loadingStatusProvider.notifier);

  final result = await CardDataService.loadCards(
    onStatus: (msg) => setStatus.state = msg,
  );

  setStatus.state = null; // Clear status when done
  return result;
});

// ── Filter state provider ─────────────────────────────────────────────────────

final filterStateProvider =
    StateNotifierProvider<FilterStateNotifier, FilterState>(
      (ref) => FilterStateNotifier(),
    );

class FilterStateNotifier extends StateNotifier<FilterState> {
  FilterStateNotifier() : super(const FilterState());

  void setSearch(String query) => state = state.copyWith(searchQuery: query);

  void setFrameType(String? value) => state = state.copyWith(frameType: value);

  void setAttribute(String? value) => state = state.copyWith(attribute: value);

  void setRace(String? value) => state = state.copyWith(race: value);

  void setArchetype(String? value) => state = state.copyWith(archetype: value);

  void setLevel(int? value) => state = state.copyWith(level: value);

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

  return dataAsync.whenData((data) {
    var cards = data.cards;

    // Search by name or description
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

    // Frame type filter
    if (filter.frameType != null) {
      cards = cards.where((c) => c.frameType == filter.frameType).toList();
    }

    // Attribute filter
    if (filter.attribute != null) {
      cards = cards.where((c) => c.attribute == filter.attribute).toList();
    }

    // Race filter
    if (filter.race != null) {
      cards = cards.where((c) => c.race == filter.race).toList();
    }

    // Archetype filter
    if (filter.archetype != null) {
      cards = cards.where((c) => c.archetype == filter.archetype).toList();
    }

    // Level filter
    if (filter.level != null) {
      cards = cards.where((c) => c.level == filter.level).toList();
    }

    // ATK range
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

    // DEF range
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
    cards = List.from(cards);
    cards.sort((a, b) {
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

    return cards;
  });
});

// ── Filter index provider ─────────────────────────────────────────────────────

final filterIndexProvider = Provider<AsyncValue<FilterIndex>>((ref) {
  return ref.watch(cardDataProvider).whenData((d) => d.filterIndex);
});
