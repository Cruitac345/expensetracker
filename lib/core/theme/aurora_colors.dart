// SPDX-License-Identifier: BSD-3-Clause
import 'package:flutter/material.dart';

import 'aurora_tokens.dart';

/// Палитра приложения по цветовой системе ОС Аврора.
///
/// ОС Аврора строит цвета вокруг «атмосфер» (Reef, Peak, Pebbles, Volcano,
/// Lake, Aura), у каждой — тёмный и светлый вариант. Значения ниже взяты из
/// официального UI Kit «Aurora Controls» для атмосферы Reef, которая
/// используется по умолчанию:
///
/// * `primary` — основной текст: белый в тёмной схеме, чёрный в светлой;
/// * `secondary` — второстепенный текст: тот же цвет с прозрачностью 0xAF;
/// * `highlight` — акцент для иконок, ссылок и индикаторов;
/// * `highlightBackground` — заливка акцентных элементов;
/// * `error` — цвет ошибки.
///
/// Фон тёмной схемы — не чистый чёрный, а `#0C0E13`: на нём карточки
/// (`#171A21`) и поля ввода (`#232833`) читаются как отдельные плоскости,
/// а контраст текста не режет глаз.
@immutable
class AuroraPalette {
  const AuroraPalette({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.accent,
    required this.accentFill,
    required this.onAccentFill,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
    required this.divider,
    required this.danger,
    required this.success,
    required this.warning,
  });

  final Brightness brightness;

  /// Фон страницы.
  final Color background;

  /// Фон карточек и панелей.
  final Color surface;

  /// Фон полей ввода и невыбранных элементов.
  final Color surfaceVariant;

  /// Акцент (highlight) — иконки, ссылки, суммы, индикаторы.
  final Color accent;

  /// Заливка акцентных элементов (highlightBackground) — кнопки и выбор.
  final Color accentFill;

  /// Текст и иконки поверх акцентной заливки.
  final Color onAccentFill;

  /// Основной текст (primary).
  final Color textPrimary;

  /// Второстепенный текст (secondary, прозрачность 0xAF).
  final Color textSecondary;

  /// Неактивный текст (primary40).
  final Color textDisabled;

  /// Разделители (primary20).
  final Color divider;

  /// Ошибка (error).
  final Color danger;

  /// Успешное состояние — цвет уровня приложения, в ките не задан.
  final Color success;

  /// Предупреждение — цвет уровня приложения, в ките не задан.
  final Color warning;

  /// Тёмная схема атмосферы Reef — основная для ОС Аврора.
  static const AuroraPalette dark = AuroraPalette(
    brightness: Brightness.dark,
    background: Color(0xFF0C0E13),
    surface: Color(0xFF171A21),
    surfaceVariant: Color(0xFF232833),
    accent: Color(0xFFA5D2FF),
    accentFill: Color(0xFF0072E5),
    onAccentFill: Color(0xFFFFFFFF),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xAFFFFFFF),
    textDisabled: Color(0x66FFFFFF),
    divider: Color(0x33FFFFFF),
    danger: Color(0xFFFF4D4D),
    success: Color(0xFF5BD98A),
    warning: Color(0xFFFFBE7E),
  );

  /// Светлая схема атмосферы Reef.
  static const AuroraPalette light = AuroraPalette(
    brightness: Brightness.light,
    background: Color(0xFFEEEEEE),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFE3E6EA),
    accent: Color(0xFF005EB5),
    accentFill: Color(0xFF0084FF),
    onAccentFill: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF000000),
    textSecondary: Color(0xAF000000),
    textDisabled: Color(0x66000000),
    divider: Color(0x33000000),
    danger: Color(0xFFF62929),
    success: Color(0xFF1E8E4A),
    warning: Color(0xFFC74A0C),
  );

  /// Палитра категорий и диаграмм: различимая в обеих схемах.
  ///
  /// Первый цвет совпадает с акцентом атмосферы Reef, остальные подобраны
  /// так, чтобы соседние сегменты диаграмм не сливались.
  static const List<Color> chart = <Color>[
    Color(0xFF0072E5),
    Color(0xFF5BD98A),
    Color(0xFFFFBE7E),
    Color(0xFFFF4D4D),
    Color(0xFFCEA3E9),
    Color(0xFF00B2A4),
    Color(0xFFF4C893),
    Color(0xFF7FA8D4),
    Color(0xFFBEE1FA),
    Color(0xFF5D287E),
  ];

  static Color chartColorAt(int index) => chart[index % chart.length];

  /// Полупрозрачная подложка акцентного цвета — выбранные элементы списка.
  Color get accentSurface =>
      accent.withValues(alpha: AuroraOpacity.faint * 0.7);
}

/// Доступ к палитре из дерева виджетов: `context.palette`.
extension AuroraPaletteContext on BuildContext {
  AuroraPalette get palette => Theme.of(this).brightness == Brightness.dark
      ? AuroraPalette.dark
      : AuroraPalette.light;
}
