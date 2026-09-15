// SPDX-License-Identifier: BSD-3-Clause
import 'package:flutter/material.dart';

/// Палитра приложения в стилистике ОС Аврора.
///
/// ОС Аврора использует «эмбиенс» — тёмную по умолчанию схему с акцентным
/// цветом. Приложение поддерживает обе схемы и следует системной.
@immutable
class AuroraPalette {
  const AuroraPalette({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.textPrimary,
    required this.textSecondary,
    required this.divider,
    required this.danger,
    required this.success,
    required this.warning,
  });

  final Brightness brightness;
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color primary;
  final Color onPrimary;
  final Color secondary;
  final Color textPrimary;
  final Color textSecondary;
  final Color divider;
  final Color danger;
  final Color success;
  final Color warning;

  /// Тёмный эмбиенс — основная схема ОС Аврора.
  static const AuroraPalette dark = AuroraPalette(
    brightness: Brightness.dark,
    background: Color(0xFF0E1218),
    surface: Color(0xFF171C25),
    surfaceVariant: Color(0xFF212936),
    primary: Color(0xFF4B9FFF),
    onPrimary: Color(0xFF06101F),
    secondary: Color(0xFF8AA0BF),
    textPrimary: Color(0xFFF2F5FA),
    textSecondary: Color(0xFF97A3B6),
    divider: Color(0xFF283242),
    danger: Color(0xFFFF6B5E),
    success: Color(0xFF4CD07D),
    warning: Color(0xFFFFB020),
  );

  /// Светлый эмбиенс.
  static const AuroraPalette light = AuroraPalette(
    brightness: Brightness.light,
    background: Color(0xFFF3F5F9),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFE8ECF3),
    primary: Color(0xFF1C6FD6),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFF52627A),
    textPrimary: Color(0xFF111821),
    textSecondary: Color(0xFF5B6779),
    divider: Color(0xFFD5DCE6),
    danger: Color(0xFFD53B2E),
    success: Color(0xFF1E9E55),
    warning: Color(0xFFB87400),
  );

  /// Палитра категорий и диаграмм: различимая в обеих схемах.
  static const List<Color> chart = <Color>[
    Color(0xFF4B9FFF),
    Color(0xFF4CD07D),
    Color(0xFFFFB020),
    Color(0xFFFF6B5E),
    Color(0xFFB088FF),
    Color(0xFF2FC7C9),
    Color(0xFFFF8FB1),
    Color(0xFF9BB3D4),
    Color(0xFFE0C64A),
    Color(0xFF6FD3A8),
  ];

  static Color chartColorAt(int index) => chart[index % chart.length];
}

/// Доступ к палитре из дерева виджетов: `context.palette`.
extension AuroraPaletteContext on BuildContext {
  AuroraPalette get palette =>
      Theme.of(this).brightness == Brightness.dark
          ? AuroraPalette.dark
          : AuroraPalette.light;
}
