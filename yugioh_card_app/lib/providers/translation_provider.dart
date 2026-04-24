import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/translation_service.dart';

/// Translation state for a single card.
class TranslationState {
  final String? translatedText;
  final String? targetLang;
  final bool isLoading;
  final String? error;

  const TranslationState({
    this.translatedText,
    this.targetLang,
    this.isLoading = false,
    this.error,
  });

  TranslationState copyWith({
    String? translatedText,
    String? targetLang,
    bool? isLoading,
    String? error,
  }) => TranslationState(
    translatedText: translatedText ?? this.translatedText,
    targetLang: targetLang ?? this.targetLang,
    isLoading: isLoading ?? this.isLoading,
    error: error ?? this.error,
  );

  TranslationState clearError() => TranslationState(
    translatedText: translatedText,
    targetLang: targetLang,
    isLoading: isLoading,
  );

  TranslationState reset() => const TranslationState();
}

/// Translation notifier — manages translation state per card.
class TranslationNotifier extends StateNotifier<TranslationState> {
  TranslationNotifier() : super(const TranslationState());

  Future<void> translate({
    required int cardId,
    required String text,
    required String targetLang,
  }) async {
    // Already translating → ignore
    if (state.isLoading) return;

    // Set loading
    state = state.copyWith(isLoading: true, error: null);

    final result = await TranslationService.translate(
      cardId: cardId,
      text: text,
      targetLang: targetLang,
    );

    if (result != null) {
      // Success
      state = TranslationState(
        translatedText: result,
        targetLang: targetLang,
        isLoading: false,
      );
    } else {
      // Failed — could be rate limit, network error, or concurrent request
      state = TranslationState(
        isLoading: false,
        error: 'Translation unavailable. Try again later.',
      );
    }
  }

  void reset() => state = const TranslationState();

  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider factory — one provider per card ID.
final translationProvider =
    StateNotifierProvider.family<TranslationNotifier, TranslationState, int>(
      (ref, cardId) => TranslationNotifier(),
    );
