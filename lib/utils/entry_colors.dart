import 'package:flutter/material.dart';

/// Picks a consistent, distinct color for a password entry based on its
/// title, so the same service always gets the same colored icon badge —
/// similar to the colorful vault icons in modern password manager UIs.
const List<Color> _palette = [
  Color(0xFF6366F1), // indigo
  Color(0xFF14B8A6), // teal
  Color(0xFFF97316), // orange
  Color(0xFFEC4899), // pink
  Color(0xFF8B5CF6), // purple
  Color(0xFF3B82F6), // blue
  Color(0xFF10B981), // green
  Color(0xFFEF4444), // red
];

Color colorForEntry(String title) {
  if (title.isEmpty) return _palette.first;
  final hash = title.codeUnits.fold<int>(0, (sum, unit) => sum + unit);
  return _palette[hash % _palette.length];
}
