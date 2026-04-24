import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/card_model.dart';
import 'card_provider.dart';

// ── CardSetInfo — derived from YugiohCard.sets ────────────────────────────────

class CardSetInfo {
  final String setName;
  final String setCode; // prefix, e.g. "LOB" from "LOB-001"
  final int cardCount;
  final List<String> rarities; // unique rarities in this set
  final List<YugiohCard> cards; // all cards belonging to this set

  // Pre-computed fields to avoid recomputing on every build
  final String coverImageUrl;
  final String topRarity;

  const CardSetInfo({
    required this.setName,
    required this.setCode,
    required this.cardCount,
    required this.rarities,
    required this.cards,
    required this.coverImageUrl,
    required this.topRarity,
  });
}

// ── Build sets — runs in isolate on non-web, main thread on web ───────────────

List<CardSetInfo> _buildSets(List<YugiohCard> allCards) {
  // Map: setName → accumulator
  final Map<String, _SetAccumulator> acc = {};

  for (final card in allCards) {
    for (final cs in card.sets) {
      if (cs.setName.isEmpty) continue;
      final a = acc.putIfAbsent(
        cs.setName,
        () => _SetAccumulator(cs.setName, cs.setCode),
      );
      a.add(card, cs.setRarity);
    }
  }

  final sets = acc.values.map((a) => a.build()).toList();

  // Sort alphabetically
  sets.sort((a, b) => a.setName.compareTo(b.setName));
  return sets;
}

class _SetAccumulator {
  final String setName;
  final String setCode;
  final List<YugiohCard> cards = [];
  final Set<int> _cardIds = {}; // O(1) duplicate check
  final Set<String> rarities = {};

  _SetAccumulator(this.setName, this.setCode);

  void add(YugiohCard card, String rarity) {
    if (_cardIds.add(card.id)) {
      // add() returns false if already present
      cards.add(card);
    }
    if (rarity.isNotEmpty) rarities.add(rarity);
  }

  CardSetInfo build() {
    // Pre-compute cover image
    String cover = '';
    for (final c in cards) {
      if (c.imageUrl.isNotEmpty) {
        cover = c.imageUrl;
        break;
      }
    }

    // Pre-compute top rarity
    const order = ['secret', 'ultimate', 'ultra', 'super', 'rare', 'common'];
    String top = '';
    outer:
    for (final tier in order) {
      for (final r in rarities) {
        if (r.toLowerCase().contains(tier)) {
          top = r;
          break outer;
        }
      }
    }
    if (top.isEmpty && rarities.isNotEmpty) top = rarities.first;

    return CardSetInfo(
      setName: setName,
      setCode: setCode,
      cardCount: cards.length,
      rarities: rarities.toList(),
      cards: cards,
      coverImageUrl: cover,
      topRarity: top,
    );
  }
}

// ── Provider — computed once, cached by Riverpod ─────────────────────────────

final cardSetsProvider = FutureProvider<List<CardSetInfo>>((ref) async {
  final data = await ref.watch(cardDataProvider.future);

  // Run on isolate on mobile/desktop; web doesn't support isolates
  if (kIsWeb) {
    return _buildSets(data.cards);
  } else {
    return compute(_buildSets, data.cards);
  }
});

// ── Sets filter state ─────────────────────────────────────────────────────────

enum SetSortOption { nameAZ, nameZA, mostCards, fewestCards }

class SetsFilterState {
  final String search;
  final SetSortOption sort;

  const SetsFilterState({this.search = '', this.sort = SetSortOption.nameAZ});

  SetsFilterState copyWith({String? search, SetSortOption? sort}) =>
      SetsFilterState(search: search ?? this.search, sort: sort ?? this.sort);

  bool get hasActiveFilters => sort != SetSortOption.nameAZ;
}

final setsFilterProvider =
    StateNotifierProvider<SetsFilterNotifier, SetsFilterState>(
      (ref) => SetsFilterNotifier(),
    );

class SetsFilterNotifier extends StateNotifier<SetsFilterState> {
  SetsFilterNotifier() : super(const SetsFilterState());

  void setSearch(String v) => state = state.copyWith(search: v);
  void setSort(SetSortOption v) => state = state.copyWith(sort: v);
  void reset() => state = SetsFilterState(search: state.search);
  void resetSort() => state = SetsFilterState(search: state.search);
}

// Keep old provider alias for backward compat
final setsSearchProvider = Provider<String>((ref) {
  return ref.watch(setsFilterProvider).search;
});

final filteredSetsProvider = Provider<AsyncValue<List<CardSetInfo>>>((ref) {
  final setsAsync = ref.watch(cardSetsProvider);
  final filter = ref.watch(setsFilterProvider);
  final query = filter.search.toLowerCase().trim();

  return setsAsync.whenData((sets) {
    var result = sets;

    // Search
    if (query.isNotEmpty) {
      result = result
          .where(
            (s) =>
                s.setName.toLowerCase().contains(query) ||
                s.setCode.toLowerCase().contains(query),
          )
          .toList();
    }

    // Sort
    result = List.from(result);
    switch (filter.sort) {
      case SetSortOption.nameAZ:
        result.sort((a, b) => a.setName.compareTo(b.setName));
        break;
      case SetSortOption.nameZA:
        result.sort((a, b) => b.setName.compareTo(a.setName));
        break;
      case SetSortOption.mostCards:
        result.sort((a, b) => b.cardCount.compareTo(a.cardCount));
        break;
      case SetSortOption.fewestCards:
        result.sort((a, b) => a.cardCount.compareTo(b.cardCount));
        break;
    }

    return result;
  });
});
