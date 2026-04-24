import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Central theme definition for the Yu-Gi-Oh! Card App.
/// Dark "Duel Terminal" aesthetic — deep navy background, teal accent.
class AppTheme {
  AppTheme._();

  // ── Brand colours ──────────────────────────────────────────────────────────
  static const Color bgDeep = Color(0xFF0A0E1A); // deepest background
  static const Color bgCard = Color(0xFF111827); // card/surface bg
  static const Color bgElevated = Color(0xFF1A2235); // elevated surfaces
  static const Color bgBorder = Color(0xFF1E2D45); // subtle borders

  static const Color accent = Color(0xFF00C896); // teal-green accent
  static const Color accentDim = Color(0x3000C896); // accent with opacity
  static const Color accentGold = Color(0xFFFFB800); // gold for stars/rank

  static const Color textPrimary = Color(0xFFEEF2FF);
  static const Color textSecondary = Color(0xFF8B9DC3);
  static const Color textMuted = Color(0xFF4A5568);

  // ── Attribute glow colours ─────────────────────────────────────────────────
  static const Map<String, Color> attributeColors = {
    'DARK': Color(0xFF9B59B6),
    'LIGHT': Color(0xFFFFD700),
    'FIRE': Color(0xFFE74C3C),
    'WATER': Color(0xFF3498DB),
    'EARTH': Color(0xFF8B6914),
    'WIND': Color(0xFF27AE60),
    'DIVINE': Color(0xFFFF8C00),
  };

  // ── Frame type colours ─────────────────────────────────────────────────────
  static const Map<String, Color> frameColors = {
    'normal': Color(0xFFB8860B),
    'effect': Color(0xFFD2691E),
    'ritual': Color(0xFF4169E1),
    'fusion': Color(0xFF8B008B),
    'synchro': Color(0xFF708090),
    'xyz': Color(0xFF2F4F4F),
    'link': Color(0xFF1E90FF),
    'spell': Color(0xFF2E8B57),
    'trap': Color(0xFFC71585),
    'token': Color(0xFF808080),
  };

  static Color getAttributeColor(String? attribute) {
    if (attribute == null) return textMuted;
    return attributeColors[attribute.toUpperCase()] ?? textMuted;
  }

  static Color getFrameColor(String frameType) {
    final key = frameType.toLowerCase();
    if (key.contains('pendulum')) return const Color(0xFF20B2AA);
    return frameColors[key] ?? textMuted;
  }

  // ── Card border colour: attribute > frame type ─────────────────────────────
  static Color getCardBorderColor(String frameType, String? attribute) {
    if (attribute != null && attribute.isNotEmpty) {
      return getAttributeColor(attribute);
    }
    return getFrameColor(frameType);
  }

  // ── ThemeData ──────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDeep,
      colorScheme: const ColorScheme.dark(
        brightness: Brightness.dark,
        primary: accent,
        onPrimary: Colors.black,
        secondary: accentGold,
        onSecondary: Colors.black,
        surface: bgCard,
        onSurface: textPrimary,
        surfaceContainerHighest: bgElevated,
        outline: bgBorder,
        error: Color(0xFFE74C3C),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgDeep,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
        iconTheme: IconThemeData(color: textSecondary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: bgCard,
        selectedItemColor: accent,
        unselectedItemColor: textMuted,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(fontSize: 11),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgElevated,
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
        prefixIconColor: textMuted,
        suffixIconColor: textMuted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: bgBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: bgBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
      ),
      cardTheme: CardThemeData(
        color: bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: bgBorder),
        ),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: bgElevated,
        selectedColor: accent,
        labelStyle: const TextStyle(fontSize: 12, color: textPrimary),
        side: const BorderSide(color: bgBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      dividerTheme: const DividerThemeData(
        color: bgBorder,
        thickness: 1,
        space: 1,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
        titleMedium: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        titleSmall: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        bodyLarge: TextStyle(color: textPrimary, fontSize: 15),
        bodyMedium: TextStyle(color: textPrimary, fontSize: 14),
        bodySmall: TextStyle(color: textSecondary, fontSize: 12),
        labelLarge: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        labelSmall: TextStyle(color: textMuted, fontSize: 11),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          side: const BorderSide(color: accent),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: accent),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: bgBorder),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        dragHandleColor: textMuted,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: bgElevated,
        contentTextStyle: const TextStyle(color: textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
