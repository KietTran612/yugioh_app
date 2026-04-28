class YugiohCard {
  final int id;
  final String name;
  final String type;
  final String frameType;
  final String desc;
  final String race;
  final String archetype;
  final String imageUrl;
  final String imageUrlSmall;
  final List<CardImage> cardImages;
  final CardPrices? prices;
  final List<CardSet> sets;
  final CardMisc? misc;

  // Monster-specific
  final int? atk;
  final int? def;
  final int? level;
  final String? attribute;
  final int? scale;
  final int? linkVal;
  final List<String> linkMarkers;

  const YugiohCard({
    required this.id,
    required this.name,
    required this.type,
    required this.frameType,
    required this.desc,
    required this.race,
    required this.archetype,
    required this.imageUrl,
    required this.imageUrlSmall,
    required this.cardImages,
    this.prices,
    required this.sets,
    this.misc,
    this.atk,
    this.def,
    this.level,
    this.attribute,
    this.scale,
    this.linkVal,
    this.linkMarkers = const [],
  });

  bool get isMonster => !isSpell && !isTrap;
  bool get isSpell => frameType == 'spell';
  bool get isTrap => frameType == 'trap';
  bool get isLink => frameType == 'link';
  bool get isPendulum => frameType.contains('pendulum');
  bool get isFusion => frameType == 'fusion';
  bool get isSynchro => frameType == 'synchro';
  bool get isXyz => frameType == 'xyz';
  bool get isRitual => frameType == 'ritual';

  factory YugiohCard.fromJson(Map<String, dynamic> json) {
    return YugiohCard(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      frameType: json['frame_type'] as String? ?? '',
      desc: json['desc'] as String? ?? '',
      race: json['race'] as String? ?? '',
      archetype: json['archetype'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      imageUrlSmall: json['image_url_small'] as String? ?? '',
      cardImages: (json['card_images'] as List<dynamic>? ?? [])
          .map((e) => CardImage.fromJson(e as Map<String, dynamic>))
          .toList(),
      prices: json['prices'] != null
          ? CardPrices.fromJson(json['prices'] as Map<String, dynamic>)
          : null,
      sets: (json['sets'] as List<dynamic>? ?? [])
          .map((e) => CardSet.fromJson(e as Map<String, dynamic>))
          .toList(),
      misc: json['misc'] != null
          ? CardMisc.fromJson(json['misc'] as Map<String, dynamic>)
          : null,
      atk: json['atk'] as int?,
      def: json['def'] as int?,
      level: json['level'] as int?,
      attribute: json['attribute'] as String?,
      scale: json['scale'] as int?,
      linkVal: json['link_val'] as int?,
      linkMarkers: (json['link_markers'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
    );
  }
}

class CardImage {
  final int id;
  final String imageUrl;
  final String imageUrlSmall;

  const CardImage({
    required this.id,
    required this.imageUrl,
    required this.imageUrlSmall,
  });

  factory CardImage.fromJson(Map<String, dynamic> json) => CardImage(
    id: json['id'] as int,
    imageUrl: json['image_url'] as String? ?? '',
    imageUrlSmall: json['image_url_small'] as String? ?? '',
  );
}

class CardPrices {
  final String tcgplayer;
  final String cardmarket;
  final String ebay;
  final String amazon;

  const CardPrices({
    required this.tcgplayer,
    required this.cardmarket,
    required this.ebay,
    required this.amazon,
  });

  factory CardPrices.fromJson(Map<String, dynamic> json) => CardPrices(
    tcgplayer: json['tcgplayer'] as String? ?? '0.00',
    cardmarket: json['cardmarket'] as String? ?? '0.00',
    ebay: json['ebay'] as String? ?? '0.00',
    amazon: json['amazon'] as String? ?? '0.00',
  );
}

class CardSet {
  final String setName;
  final String setCode;
  final String setRarity;
  final String setRarityCode;

  const CardSet({
    required this.setName,
    required this.setCode,
    required this.setRarity,
    required this.setRarityCode,
  });

  factory CardSet.fromJson(Map<String, dynamic> json) => CardSet(
    setName: json['set_name'] as String? ?? '',
    setCode: json['set_code'] as String? ?? '',
    setRarity: json['set_rarity'] as String? ?? '',
    setRarityCode: json['set_rarity_code'] as String? ?? '',
  );
}

/// Banlist status for a specific format.
enum BanlistStatus {
  forbidden,
  limited,
  semiLimited;

  static BanlistStatus? fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'forbidden':
        return BanlistStatus.forbidden;
      case 'limited':
        return BanlistStatus.limited;
      case 'semi-limited':
        return BanlistStatus.semiLimited;
      default:
        return null;
    }
  }

  String get label {
    switch (this) {
      case BanlistStatus.forbidden:
        return 'Forbidden';
      case BanlistStatus.limited:
        return 'Limited';
      case BanlistStatus.semiLimited:
        return 'Semi-Limited';
    }
  }
}

class BanlistInfo {
  final BanlistStatus? tcg;
  final BanlistStatus? ocg;
  final BanlistStatus? goat;

  const BanlistInfo({this.tcg, this.ocg, this.goat});

  bool get hasAny => tcg != null || ocg != null || goat != null;

  factory BanlistInfo.fromJson(Map<String, dynamic> json) => BanlistInfo(
    tcg: BanlistStatus.fromString(json['ban_tcg'] as String?),
    ocg: BanlistStatus.fromString(json['ban_ocg'] as String?),
    goat: BanlistStatus.fromString(json['ban_goat'] as String?),
  );
}

class CardMisc {
  final List<String> formats;
  final String tcgDate;
  final String ocgDate;
  final int views;
  final BanlistInfo? banlist;

  const CardMisc({
    required this.formats,
    required this.tcgDate,
    required this.ocgDate,
    required this.views,
    this.banlist,
  });

  factory CardMisc.fromJson(Map<String, dynamic> json) {
    final banlistJson = json['banlist_info'] as Map<String, dynamic>?;
    return CardMisc(
      formats: (json['formats'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      tcgDate: json['tcg_date'] as String? ?? '',
      ocgDate: json['ocg_date'] as String? ?? '',
      views: json['views'] as int? ?? 0,
      banlist: banlistJson != null ? BanlistInfo.fromJson(banlistJson) : null,
    );
  }
}

class FilterIndex {
  final List<String> types;
  final List<String> frameTypes;
  final List<String> races;
  final List<String> attributes;
  final List<String> archetypes;
  final List<int> levels;
  final List<String> tcgRarities; // sorted by rarity tier

  const FilterIndex({
    required this.types,
    required this.frameTypes,
    required this.races,
    required this.attributes,
    required this.archetypes,
    required this.levels,
    this.tcgRarities = const [],
  });

  factory FilterIndex.fromJson(Map<String, dynamic> json) => FilterIndex(
    types: (json['types'] as List<dynamic>? ?? [])
        .map((e) => e as String)
        .toList(),
    frameTypes: (json['frame_types'] as List<dynamic>? ?? [])
        .map((e) => e as String)
        .toList(),
    races: (json['races'] as List<dynamic>? ?? [])
        .map((e) => e as String)
        .toList(),
    attributes: (json['attributes'] as List<dynamic>? ?? [])
        .map((e) => e as String)
        .toList(),
    archetypes: (json['archetypes'] as List<dynamic>? ?? [])
        .map((e) => e as String)
        .toList(),
    levels: (json['levels'] as List<dynamic>? ?? [])
        .map((e) => e as int)
        .toList(),
    tcgRarities: (json['tcg_rarities'] as List<dynamic>? ?? [])
        .map((e) => e as String)
        .toList(),
  );
}
