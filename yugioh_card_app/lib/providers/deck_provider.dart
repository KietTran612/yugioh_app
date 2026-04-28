import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/card_model.dart';
import '../models/deck_model.dart';
import '../services/deck_service.dart';
import 'card_provider.dart';

// ── Deck list notifier ─────────────────────────────────────────────────────────

class DeckNotifier extends StateNotifier<List<Deck>> {
  DeckNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    state = await DeckService.loadDecks();
  }

  Future<void> _save() async {
    await DeckService.saveDecks(state);
  }

  /// Create a new empty deck
  Future<Deck> createDeck(String name, DeckFormat format) async {
    final deck = Deck(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      format: format,
      mainDeck: [],
      extraDeck: [],
      sideDeck: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    state = [...state, deck];
    await _save();
    return deck;
  }

  Future<void> deleteDeck(String deckId) async {
    state = state.where((d) => d.id != deckId).toList();
    await _save();
  }

  Future<void> renameDeck(String deckId, String newName) async {
    state = state
        .map((d) => d.id == deckId ? d.copyWith(name: newName) : d)
        .toList();
    await _save();
  }

  Future<void> updateDeck(Deck updated) async {
    state = state.map((d) => d.id == updated.id ? updated : d).toList();
    await _save();
  }

  /// Add a card to the appropriate zone (main/extra) of a deck.
  /// Returns error message if not allowed, null if success.
  String? addCard(String deckId, YugiohCard card, {bool toSide = false}) {
    final deck = state.firstWhere((d) => d.id == deckId);
    final cfg = deck.config;

    // Determine target zone
    final isExtraCard =
        card.isFusion || card.isSynchro || card.isXyz || card.isLink;

    if (toSide) {
      if (!cfg.hasSide) return 'This format has no Side Deck';
      if (deck.sideDeck.length >= cfg.sideMax) {
        return 'Side Deck is full (${cfg.sideMax} max)';
      }
      // Check 3-copy limit across main + side
      final count =
          deck.mainDeck.where((id) => id == card.id).length +
          deck.sideDeck.where((id) => id == card.id).length;
      if (count >= 3) return 'Max 3 copies per card';
      final updated = deck.copyWith(sideDeck: [...deck.sideDeck, card.id]);
      _updateState(updated);
      return null;
    }

    if (isExtraCard) {
      if (deck.extraDeck.length >= cfg.extraMax) {
        return 'Extra Deck is full (${cfg.extraMax} max)';
      }
      final count = deck.extraDeck.where((id) => id == card.id).length;
      if (count >= 3) return 'Max 3 copies per card';
      final updated = deck.copyWith(extraDeck: [...deck.extraDeck, card.id]);
      _updateState(updated);
      return null;
    }

    // Main deck
    if (deck.mainDeck.length >= cfg.mainMax) {
      return 'Main Deck is full (${cfg.mainMax} max)';
    }
    final count =
        deck.mainDeck.where((id) => id == card.id).length +
        deck.sideDeck.where((id) => id == card.id).length;
    if (count >= 3) return 'Max 3 copies per card';
    final updated = deck.copyWith(mainDeck: [...deck.mainDeck, card.id]);
    _updateState(updated);
    return null;
  }

  /// Remove one copy of a card from a zone
  void removeCard(String deckId, int cardId, _DeckZone zone) {
    final deck = state.firstWhere((d) => d.id == deckId);
    Deck updated;
    switch (zone) {
      case _DeckZone.main:
        final list = List<int>.from(deck.mainDeck);
        list.remove(cardId);
        updated = deck.copyWith(mainDeck: list);
      case _DeckZone.extra:
        final list = List<int>.from(deck.extraDeck);
        list.remove(cardId);
        updated = deck.copyWith(extraDeck: list);
      case _DeckZone.side:
        final list = List<int>.from(deck.sideDeck);
        list.remove(cardId);
        updated = deck.copyWith(sideDeck: list);
    }
    _updateState(updated);
  }

  void _updateState(Deck updated) {
    state = state.map((d) => d.id == updated.id ? updated : d).toList();
    DeckService.saveDecks(state);
  }

  Deck? getDeck(String deckId) {
    try {
      return state.firstWhere((d) => d.id == deckId);
    } catch (_) {
      return null;
    }
  }
}

enum _DeckZone { main, extra, side }

// ── Providers ──────────────────────────────────────────────────────────────────

final deckProvider = StateNotifierProvider<DeckNotifier, List<Deck>>(
  (ref) => DeckNotifier(),
);

/// Decks filtered by format
final masterDuelDecksProvider = Provider<List<Deck>>((ref) {
  return ref
      .watch(deckProvider)
      .where((d) => d.format == DeckFormat.masterDuel)
      .toList();
});

final duelLinksDecksProvider = Provider<List<Deck>>((ref) {
  return ref
      .watch(deckProvider)
      .where((d) => d.format == DeckFormat.duelLinks)
      .toList();
});

/// Resolve card IDs in a deck to YugiohCard objects
final deckCardsProvider = FutureProvider.family<DeckCards, String>((
  ref,
  deckId,
) async {
  final decks = ref.watch(deckProvider);
  final deck = decks.firstWhere((d) => d.id == deckId);
  final cardsAsync = ref.watch(cardDataProvider);

  return cardsAsync.when(
    data: (result) {
      final cardMap = {for (final c in result.cards) c.id: c};
      return DeckCards(
        main: deck.mainDeck
            .map((id) => cardMap[id])
            .whereType<YugiohCard>()
            .toList(),
        extra: deck.extraDeck
            .map((id) => cardMap[id])
            .whereType<YugiohCard>()
            .toList(),
        side: deck.sideDeck
            .map((id) => cardMap[id])
            .whereType<YugiohCard>()
            .toList(),
      );
    },
    loading: () => const DeckCards(main: [], extra: [], side: []),
    error: (_, _) => const DeckCards(main: [], extra: [], side: []),
  );
});

class DeckCards {
  final List<YugiohCard> main;
  final List<YugiohCard> extra;
  final List<YugiohCard> side;
  const DeckCards({
    required this.main,
    required this.extra,
    required this.side,
  });
}

// Re-export zone enum for use in screens
typedef DeckZone = _DeckZone;
