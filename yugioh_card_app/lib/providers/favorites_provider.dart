import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/card_model.dart';
import '../models/filter_state.dart';
import '../services/favorites_service.dart';
import 'card_provider.dart';

// ── Favorites state notifier ──────────────────────────────────────────────────

class FavoritesNotifier extends StateNotifier<Set<int>> {
  FavoritesNotifier() : super({}) {
    _load();
  }

  Future<void> _load() async {
    state = await FavoritesService.loadFavorites();
  }

  /// Toggle a card's favorite status. Returns true if now favorited.
  Future<bool> toggle(int cardId) async {
    final updated = Set<int>.from(state);
    final nowFavorited = !updated.contains(cardId);
    if (nowFavorited) {
      updated.add(cardId);
    } else {
      updated.remove(cardId);
    }
    state = updated;
    await FavoritesService.saveFavorites(state);
    return nowFavorited;
  }

  bool isFavorite(int cardId) => state.contains(cardId);

  Future<void> clear() async {
    state = {};
    await FavoritesService.clearFavorites();
  }
}

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, Set<int>>(
  (ref) => FavoritesNotifier(),
);

// ── Derived: list of favorite YugiohCard objects ──────────────────────────────

final favoriteCardsProvider = Provider<AsyncValue<List<YugiohCard>>>((ref) {
  final dataAsync = ref.watch(cardDataProvider);
  final favoriteIds = ref.watch(favoritesProvider);

  return dataAsync.whenData((data) {
    if (favoriteIds.isEmpty) return [];
    return data.cards.where((c) => favoriteIds.contains(c.id)).toList();
  });
});

// ── Watchlist filter state (independent from Home filter) ─────────────────────

final watchlistFilterProvider =
    StateNotifierProvider<FilterStateNotifier, FilterState>(
      (ref) => FilterStateNotifier(),
    );

// ── Filtered favorite cards (apply watchlist filter to favorites) ─────────────

final filteredFavoriteCardsProvider = Provider<AsyncValue<List<YugiohCard>>>((
  ref,
) {
  final dataAsync = ref.watch(cardDataProvider);
  final favoriteIds = ref.watch(favoritesProvider);
  final filter = ref.watch(watchlistFilterProvider);

  return dataAsync.whenData((data) {
    if (favoriteIds.isEmpty) return [];

    // Get only favorite cards
    var cards = data.cards.where((c) => favoriteIds.contains(c.id)).toList();

    // Apply filter (same logic as in card_provider.dart)
    return _applyFilter(cards, filter);
  });
});

// ── Filter logic (copied from card_provider.dart) ─────────────────────────────

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

  if (filter.banlistStatuses.isNotEmpty) {
    cards = cards.where((c) {
      final banlist = c.misc?.banlist;
      if (banlist == null) return false;
      final cardStatuses = <String>{
        if (banlist.tcg != null) banlist.tcg!.label,
        if (banlist.ocg != null) banlist.ocg!.label,
        if (banlist.goat != null) banlist.goat!.label,
      };
      return cardStatuses.any((s) => filter.banlistStatuses.contains(s));
    }).toList();
  }

  if (filter.formats.isNotEmpty) {
    cards = cards.where((c) {
      final cardFormats = c.misc?.formats ?? [];
      return filter.formats.every((f) => cardFormats.contains(f));
    }).toList();
  }

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
