import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _favoritesKey = 'yugioh_favorites_v1';

/// Handles persistence of favorite card IDs using SharedPreferences.
/// Stores a JSON list of int IDs — very lightweight, no size issues.
class FavoritesService {
  /// Load saved favorite card IDs. Returns empty set if none saved.
  static Future<Set<int>> loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_favoritesKey);
      if (jsonStr == null || jsonStr.isEmpty) return {};
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list.map((e) => e as int).toSet();
    } catch (e) {
      debugPrint('[Favorites] Load failed: $e');
      return {};
    }
  }

  /// Persist the full set of favorite card IDs.
  static Future<void> saveFavorites(Set<int> ids) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_favoritesKey, jsonEncode(ids.toList()));
    } catch (e) {
      debugPrint('[Favorites] Save failed: $e');
    }
  }

  /// Clear all favorites.
  static Future<void> clearFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_favoritesKey);
  }
}
