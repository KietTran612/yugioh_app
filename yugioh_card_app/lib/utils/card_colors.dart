import 'package:flutter/material.dart';

/// Returns the background color associated with a card's frame type.
Color frameTypeColor(String frameType) {
  switch (frameType.toLowerCase()) {
    case 'normal':
      return const Color(0xFFFDE68A); // yellow-tan
    case 'effect':
      return const Color(0xFFFB923C); // orange
    case 'ritual':
      return const Color(0xFF93C5FD); // blue
    case 'fusion':
      return const Color(0xFFA78BFA); // purple
    case 'synchro':
      return const Color(0xFFE5E7EB); // light gray
    case 'xyz':
      return const Color(0xFF374151); // dark gray
    case 'link':
      return const Color(0xFF60A5FA); // blue
    case 'pendulum_normal':
    case 'pendulum_effect':
    case 'pendulum_ritual':
    case 'pendulum_fusion':
    case 'pendulum_synchro':
    case 'pendulum_xyz':
      return const Color(0xFF6EE7B7); // teal-green
    case 'spell':
      return const Color(0xFF34D399); // green
    case 'trap':
      return const Color(0xFFF472B6); // pink
    case 'token':
      return const Color(0xFF9CA3AF); // gray
    default:
      return const Color(0xFFD1D5DB);
  }
}

/// Returns the text color for a given frame type (for contrast).
Color frameTypeTextColor(String frameType) {
  switch (frameType.toLowerCase()) {
    case 'xyz':
      return Colors.white;
    default:
      return Colors.black87;
  }
}

/// Returns the color for an attribute badge.
Color attributeColor(String attribute) {
  switch (attribute.toUpperCase()) {
    case 'DARK':
      return const Color(0xFF7C3AED);
    case 'LIGHT':
      return const Color(0xFFFBBF24);
    case 'FIRE':
      return const Color(0xFFEF4444);
    case 'WATER':
      return const Color(0xFF3B82F6);
    case 'EARTH':
      return const Color(0xFF92400E);
    case 'WIND':
      return const Color(0xFF10B981);
    case 'DIVINE':
      return const Color(0xFFF59E0B);
    default:
      return const Color(0xFF6B7280);
  }
}
