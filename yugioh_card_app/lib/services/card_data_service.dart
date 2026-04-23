import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/card_model.dart';

const _apiBase = 'https://db.ygoprodeck.com/api/v7';
const _imageBase = 'https://images.ygoprodeck.com/images/cards';
const _imageSmallBase = 'https://images.ygoprodeck.com/images/cards_small';

// Key dùng cho SharedPreferences (web) và tên file (mobile/desktop)
const _cacheKey = 'yugioh_cards_cache';
const _cacheFileName = 'cards_cache.json';

/// Loads card data:
/// 1. Bundled assets (cards.json)
/// 2. Local cache (SharedPreferences on web, file on mobile/desktop)
/// 3. Fetch from YGOPRODeck API → save to cache
class CardDataService {
  static final _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 120),
    ),
  );

  static Future<CardDataResult> loadCards({
    void Function(String message)? onStatus,
  }) async {
    // 1. Try bundled assets
    try {
      onStatus?.call('Loading local data...');
      final result = await _loadFromAssets();
      if (result != null) {
        debugPrint(
          '[CardDataService] Loaded ${result.cards.length} cards from assets.',
        );
        return result;
      }
    } catch (e) {
      debugPrint('[CardDataService] Assets not available: $e');
    }

    // 2. Try local cache
    try {
      onStatus?.call('Loading cached data...');
      final result = await _loadFromCache();
      if (result != null) {
        debugPrint(
          '[CardDataService] Loaded ${result.cards.length} cards from cache.',
        );
        return result;
      }
    } catch (e) {
      debugPrint('[CardDataService] Cache not available: $e');
    }

    // 3. Fetch from API and save to cache
    debugPrint('[CardDataService] Fetching from API...');
    final result = await _fetchFromApi(onStatus: onStatus);

    // Save to cache in background
    _saveToCache(result).catchError((e) {
      debugPrint('[CardDataService] Failed to save cache: $e');
    });

    return result;
  }

  // ── 1. Bundled assets ──────────────────────────────────────────────────────

  static Future<CardDataResult?> _loadFromAssets() async {
    try {
      final jsonStr = await rootBundle.loadString(
        'assets/data/cards.json',
        cache: false,
      );
      if (jsonStr.isEmpty) return null;
      return await compute(_parseCardDataJson, jsonStr);
    } on FlutterError {
      return null;
    }
  }

  // ── 2. Local cache ─────────────────────────────────────────────────────────

  static Future<CardDataResult?> _loadFromCache() async {
    final jsonStr = kIsWeb ? await _readFromPrefs() : await _readFromFile();

    if (jsonStr == null || jsonStr.isEmpty) return null;
    return await compute(_parseCardDataJson, jsonStr);
  }

  static Future<String?> _readFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cacheKey);
  }

  static Future<String?> _readFromFile() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_cacheFileName');
      if (!await file.exists()) return null;
      return await file.readAsString();
    } catch (e) {
      return null;
    }
  }

  // ── 3. Fetch from API ──────────────────────────────────────────────────────

  static Future<CardDataResult> _fetchFromApi({
    void Function(String message)? onStatus,
  }) async {
    onStatus?.call('Connecting to YGOPRODeck API...');

    final response = await _dio.get(
      '$_apiBase/cardinfo.php',
      queryParameters: {'misc': 'yes'},
      options: Options(responseType: ResponseType.json),
    );

    onStatus?.call(
      'Processing ${(response.data['data'] as List).length} cards...',
    );

    final rawCards = response.data['data'] as List<dynamic>;
    debugPrint('[CardDataService] Fetched ${rawCards.length} cards from API.');

    final result = await compute(_parseApiCards, rawCards);
    onStatus?.call('Done!');
    return result;
  }

  // ── Save to cache ──────────────────────────────────────────────────────────

  static Future<void> _saveToCache(CardDataResult result) async {
    // Serialize back to the same JSON format _parseCardDataJson expects
    final json = {
      'cards': result.cards.map(_cardToJson).toList(),
      'filter_index': {
        'types': result.filterIndex.types,
        'frame_types': result.filterIndex.frameTypes,
        'races': result.filterIndex.races,
        'attributes': result.filterIndex.attributes,
        'archetypes': result.filterIndex.archetypes,
        'levels': result.filterIndex.levels,
      },
    };

    final jsonStr = jsonEncode(json);

    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonStr);
      debugPrint('[CardDataService] Saved cache to SharedPreferences.');
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_cacheFileName');
      await file.writeAsString(jsonStr);
      debugPrint('[CardDataService] Saved cache to ${file.path}');
    }
  }

  /// Clear cached data (useful for force-refresh)
  static Future<void> clearCache() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
    } else {
      try {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$_cacheFileName');
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
    debugPrint('[CardDataService] Cache cleared.');
  }
}

// ── Serialization helpers ──────────────────────────────────────────────────────

Map<String, dynamic> _cardToJson(YugiohCard c) {
  final map = <String, dynamic>{
    'id': c.id,
    'name': c.name,
    'type': c.type,
    'frame_type': c.frameType,
    'desc': c.desc,
    'race': c.race,
    'archetype': c.archetype,
    'image_url': c.imageUrl,
    'image_url_small': c.imageUrlSmall,
    'card_images': c.cardImages
        .map(
          (img) => {
            'id': img.id,
            'image_url': img.imageUrl,
            'image_url_small': img.imageUrlSmall,
          },
        )
        .toList(),
    'prices': c.prices != null
        ? {
            'tcgplayer': c.prices!.tcgplayer,
            'cardmarket': c.prices!.cardmarket,
            'ebay': c.prices!.ebay,
            'amazon': c.prices!.amazon,
          }
        : null,
    'sets': c.sets
        .map(
          (s) => {
            'set_name': s.setName,
            'set_code': s.setCode,
            'set_rarity': s.setRarity,
            'set_rarity_code': s.setRarityCode,
          },
        )
        .toList(),
    'misc': c.misc != null
        ? {
            'formats': c.misc!.formats,
            'tcg_date': c.misc!.tcgDate,
            'ocg_date': c.misc!.ocgDate,
            'views': c.misc!.views,
          }
        : null,
  };

  if (c.atk != null) map['atk'] = c.atk;
  if (c.def != null) map['def'] = c.def;
  if (c.level != null) map['level'] = c.level;
  if (c.attribute != null) map['attribute'] = c.attribute;
  if (c.scale != null) map['scale'] = c.scale;
  if (c.linkVal != null) map['link_val'] = c.linkVal;
  if (c.linkMarkers.isNotEmpty) map['link_markers'] = c.linkMarkers;

  return map;
}

// ── Isolate-safe parse functions ───────────────────────────────────────────────

CardDataResult _parseCardDataJson(String jsonStr) {
  final json = jsonDecode(jsonStr) as Map<String, dynamic>;
  final cards = (json['cards'] as List<dynamic>)
      .map((e) => YugiohCard.fromJson(e as Map<String, dynamic>))
      .toList();
  final filterIndex = FilterIndex.fromJson(
    json['filter_index'] as Map<String, dynamic>,
  );
  return CardDataResult(cards: cards, filterIndex: filterIndex);
}

CardDataResult _parseApiCards(List<dynamic> rawCards) {
  final cards = rawCards.map((raw) {
    final card = raw as Map<String, dynamic>;
    final images = card['card_images'] as List<dynamic>? ?? [];
    final cardId = images.isNotEmpty ? images[0]['id'] : card['id'];

    final prices = <String, String>{};
    final cardPrices = card['card_prices'] as List<dynamic>? ?? [];
    if (cardPrices.isNotEmpty) {
      final p = cardPrices[0] as Map<String, dynamic>;
      prices['tcgplayer'] = p['tcgplayer_price'] as String? ?? '0.00';
      prices['cardmarket'] = p['cardmarket_price'] as String? ?? '0.00';
      prices['ebay'] = p['ebay_price'] as String? ?? '0.00';
      prices['amazon'] = p['amazon_price'] as String? ?? '0.00';
    }

    final sets = (card['card_sets'] as List<dynamic>? ?? []).map((s) {
      final set = s as Map<String, dynamic>;
      return {
        'set_name': set['set_name'] ?? '',
        'set_code': set['set_code'] ?? '',
        'set_rarity': set['set_rarity'] ?? '',
        'set_rarity_code': set['set_rarity_code'] ?? '',
      };
    }).toList();

    final miscList = card['misc_info'] as List<dynamic>? ?? [];
    final misc = miscList.isNotEmpty
        ? {
            'formats': (miscList[0] as Map<String, dynamic>)['formats'] ?? [],
            'tcg_date': (miscList[0] as Map<String, dynamic>)['tcg_date'] ?? '',
            'ocg_date': (miscList[0] as Map<String, dynamic>)['ocg_date'] ?? '',
            'views': (miscList[0] as Map<String, dynamic>)['views'] ?? 0,
          }
        : <String, dynamic>{};

    final normalized = <String, dynamic>{
      'id': card['id'],
      'name': card['name'] ?? '',
      'type': card['type'] ?? '',
      'frame_type': card['frameType'] ?? '',
      'desc': card['desc'] ?? '',
      'race': card['race'] ?? '',
      'archetype': card['archetype'] ?? '',
      'image_url': '$_imageBase/$cardId.jpg',
      'image_url_small': '$_imageSmallBase/$cardId.jpg',
      'card_images': images
          .map(
            (img) => {
              'id': img['id'],
              'image_url': '$_imageBase/${img['id']}.jpg',
              'image_url_small': '$_imageSmallBase/${img['id']}.jpg',
            },
          )
          .toList(),
      'prices': prices,
      'sets': sets,
      'misc': misc,
    };

    final frameType = card['frameType'] as String? ?? '';
    if (frameType != 'spell' && frameType != 'trap') {
      normalized['atk'] = card['atk'];
      normalized['def'] = card['def'];
      normalized['level'] = card['level'];
      normalized['attribute'] = card['attribute'] ?? '';
      normalized['scale'] = card['scale'];
      normalized['link_val'] = card['linkval'];
      normalized['link_markers'] = card['linkmarkers'] ?? [];
    }

    return YugiohCard.fromJson(normalized);
  }).toList();

  // Build filter index
  final types = <String>{};
  final frameTypes = <String>{};
  final races = <String>{};
  final attributes = <String>{};
  final archetypes = <String>{};
  final levels = <int>{};

  for (final c in cards) {
    if (c.type.isNotEmpty) types.add(c.type);
    if (c.frameType.isNotEmpty) frameTypes.add(c.frameType);
    if (c.race.isNotEmpty) races.add(c.race);
    if (c.attribute?.isNotEmpty == true) attributes.add(c.attribute!);
    if (c.archetype.isNotEmpty) archetypes.add(c.archetype);
    if (c.level != null) levels.add(c.level!);
  }

  final filterIndex = FilterIndex(
    types: types.toList()..sort(),
    frameTypes: frameTypes.toList()..sort(),
    races: races.toList()..sort(),
    attributes: attributes.toList()..sort(),
    archetypes: archetypes.toList()..sort(),
    levels: levels.toList()..sort(),
  );

  return CardDataResult(cards: cards, filterIndex: filterIndex);
}

// ── Result model ───────────────────────────────────────────────────────────────

class CardDataResult {
  final List<YugiohCard> cards;
  final FilterIndex filterIndex;
  const CardDataResult({required this.cards, required this.filterIndex});
}
