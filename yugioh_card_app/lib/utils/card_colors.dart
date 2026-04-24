import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Delegates to AppTheme — kept for backward compatibility.
Color frameTypeColor(String frameType) => AppTheme.getFrameColor(frameType);

Color frameTypeTextColor(String frameType) {
  // Most frame types are dark enough to need white text
  switch (frameType.toLowerCase()) {
    case 'synchro':
    case 'normal':
      return Colors.black87;
    default:
      return Colors.white;
  }
}

Color attributeColor(String attribute) => AppTheme.getAttributeColor(attribute);
