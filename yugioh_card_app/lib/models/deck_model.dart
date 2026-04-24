import 'dart:convert';

// ── Format config ──────────────────────────────────────────────────────────────

enum DeckFormat { masterDuel, duelLinks }

class DeckFormatConfig {
  final int mainMin;
  final int mainMax;
  final int extraMax;
  final int sideMax; // 0 = no side deck
  final String label;
  final String shortLabel;

  const DeckFormatConfig({
    required this.mainMin,
    required this.mainMax,
    required this.extraMax,
    required this.sideMax,
    required this.label,
    required this.shortLabel,
  });

  bool get hasSide => sideMax > 0;
}

const deckFormatConfigs = {
  DeckFormat.masterDuel: DeckFormatConfig(
    mainMin: 40,
    mainMax: 60,
    extraMax: 15,
    sideMax: 15,
    label: 'Master Duel',
    shortLabel: 'MD',
  ),
  DeckFormat.duelLinks: DeckFormatConfig(
    mainMin: 20,
    mainMax: 30,
    extraMax: 9,
    sideMax: 0,
    label: 'Duel Links',
    shortLabel: 'DL',
  ),
};

// ── Deck model ─────────────────────────────────────────────────────────────────

class Deck {
  final String id;
  final String name;
  final DeckFormat format;
  final List<int> mainDeck; // card IDs (duplicates allowed, max 3 per card)
  final List<int> extraDeck;
  final List<int> sideDeck;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Deck({
    required this.id,
    required this.name,
    required this.format,
    required this.mainDeck,
    required this.extraDeck,
    required this.sideDeck,
    required this.createdAt,
    required this.updatedAt,
  });

  DeckFormatConfig get config => deckFormatConfigs[format]!;

  int get totalCards => mainDeck.length + extraDeck.length + sideDeck.length;

  /// Validate deck — returns list of error messages (empty = valid)
  List<String> validate() {
    final errors = <String>[];
    final cfg = config;

    if (mainDeck.length < cfg.mainMin) {
      errors.add(
        'Main Deck needs at least ${cfg.mainMin} cards (${mainDeck.length}/${cfg.mainMin})',
      );
    }
    if (mainDeck.length > cfg.mainMax) {
      errors.add(
        'Main Deck exceeds ${cfg.mainMax} cards (${mainDeck.length}/${cfg.mainMax})',
      );
    }
    if (extraDeck.length > cfg.extraMax) {
      errors.add(
        'Extra Deck exceeds ${cfg.extraMax} cards (${extraDeck.length}/${cfg.extraMax})',
      );
    }
    if (sideDeck.length > cfg.sideMax) {
      errors.add(
        'Side Deck exceeds ${cfg.sideMax} cards (${sideDeck.length}/${cfg.sideMax})',
      );
    }

    // Max 3 copies per card across main + side
    final allCards = [...mainDeck, ...sideDeck];
    final counts = <int, int>{};
    for (final id in allCards) {
      counts[id] = (counts[id] ?? 0) + 1;
    }
    for (final entry in counts.entries) {
      if (entry.value > 3) {
        errors.add('Card ID ${entry.key} appears ${entry.value} times (max 3)');
      }
    }

    return errors;
  }

  bool get isValid => validate().isEmpty;

  Deck copyWith({
    String? name,
    List<int>? mainDeck,
    List<int>? extraDeck,
    List<int>? sideDeck,
  }) {
    return Deck(
      id: id,
      name: name ?? this.name,
      format: format,
      mainDeck: mainDeck ?? this.mainDeck,
      extraDeck: extraDeck ?? this.extraDeck,
      sideDeck: sideDeck ?? this.sideDeck,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'format': format.name,
    'mainDeck': mainDeck,
    'extraDeck': extraDeck,
    'sideDeck': sideDeck,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Deck.fromJson(Map<String, dynamic> json) => Deck(
    id: json['id'] as String,
    name: json['name'] as String,
    format: DeckFormat.values.firstWhere(
      (f) => f.name == json['format'],
      orElse: () => DeckFormat.masterDuel,
    ),
    mainDeck: List<int>.from(json['mainDeck'] as List),
    extraDeck: List<int>.from(json['extraDeck'] as List),
    sideDeck: List<int>.from(json['sideDeck'] as List? ?? []),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  static String encodeList(List<Deck> decks) =>
      jsonEncode(decks.map((d) => d.toJson()).toList());

  static List<Deck> decodeList(String raw) {
    final list = jsonDecode(raw) as List;
    return list.map((e) => Deck.fromJson(e as Map<String, dynamic>)).toList();
  }
}
