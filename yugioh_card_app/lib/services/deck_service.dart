import 'package:shared_preferences/shared_preferences.dart';
import '../models/deck_model.dart';

class DeckService {
  static const _key = 'decks_v1';

  static Future<List<Deck>> loadDecks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      return Deck.decodeList(raw);
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveDecks(List<Deck> decks) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, Deck.encodeList(decks));
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
