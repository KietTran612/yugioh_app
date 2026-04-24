import 'package:shared_preferences/shared_preferences.dart';
import 'package:translator/translator.dart';

/// Translation service with caching and request locking.
class TranslationService {
  static final _translator = GoogleTranslator();
  static bool _isTranslating = false;

  /// Translate text with cache + lock to prevent concurrent requests.
  /// Returns null if translation fails or is already in progress.
  static Future<String?> translate({
    required int cardId,
    required String text,
    required String targetLang,
  }) async {
    // Lock check — prevent concurrent translation
    if (_isTranslating) return null;

    final cacheKey = 'translation_${cardId}_$targetLang';

    try {
      // Check cache first
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(cacheKey);
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }

      // Lock
      _isTranslating = true;

      // Call API
      final result = await _translator.translate(
        text,
        from: 'en',
        to: targetLang,
      );

      final translated = result.text;

      // Cache result
      if (translated.isNotEmpty) {
        await prefs.setString(cacheKey, translated);
      }

      return translated;
    } catch (e) {
      // API error — return null
      return null;
    } finally {
      // Unlock
      _isTranslating = false;
    }
  }

  /// Clear all translation cache.
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('translation_')) {
        await prefs.remove(key);
      }
    }
  }
}

/// Supported languages for translation.
class TranslationLanguage {
  final String code;
  final String name;
  final String flag;

  const TranslationLanguage({
    required this.code,
    required this.name,
    required this.flag,
  });

  static const languages = [
    TranslationLanguage(code: 'vi', name: 'Vietnamese', flag: '🇻🇳'),
    TranslationLanguage(code: 'ja', name: 'Japanese', flag: '🇯🇵'),
    TranslationLanguage(code: 'ko', name: 'Korean', flag: '🇰🇷'),
    TranslationLanguage(
      code: 'zh-cn',
      name: 'Chinese (Simplified)',
      flag: '🇨🇳',
    ),
    TranslationLanguage(code: 'es', name: 'Spanish', flag: '🇪🇸'),
    TranslationLanguage(code: 'fr', name: 'French', flag: '🇫🇷'),
    TranslationLanguage(code: 'de', name: 'German', flag: '🇩🇪'),
    TranslationLanguage(code: 'it', name: 'Italian', flag: '🇮🇹'),
    TranslationLanguage(code: 'pt', name: 'Portuguese', flag: '🇵🇹'),
    TranslationLanguage(code: 'ru', name: 'Russian', flag: '🇷🇺'),
    TranslationLanguage(code: 'th', name: 'Thai', flag: '🇹🇭'),
  ];
}
