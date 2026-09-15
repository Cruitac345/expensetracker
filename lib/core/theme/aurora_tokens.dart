// SPDX-License-Identifier: BSD-3-Clause
import 'package:flutter/widgets.dart';

/// Размерные константы дизайн-системы ОС Аврора.
///
/// Значения взяты из официального UI Kit «Aurora Controls» (Open Mobile
/// Platform, ветка `flutter-aurora-3.35.7`): модуль сетки 4 px, отступы
/// `padding*`, размеры иконок `iconSize*`, высоты элементов `itemSize*`.
/// Компоненты приложения не используют «магические» числа — только эти токены.
class AuroraSizes {
  const AuroraSizes._();

  /// Модуль сетки — 4 px. Все размеры кратны ему.
  static const double module = 4;

  /// Произвольный размер, кратный модулю.
  static double moduleX(int multiplier) => module * multiplier;

  // Отступы (SpacingData)
  static const double paddingSmall = 4;
  static const double paddingMedium = 8;
  static const double paddingLarge = 16;

  /// Боковые поля страницы (horizontalPageMargin).
  static const double pageMarginPhone = 16;

  /// На планшете поля шире — площадь экрана позволяет.
  static const double pageMarginTablet = 24;

  // Размеры иконок (IconSizeData)
  static const double iconSizeExtraSmall = 16;
  static const double iconSizeSmall = 20;

  /// Размер иконки в панели приложения и в кнопках.
  static const double iconSizeSmallPlus = 32;
  static const double iconSizeMedium = 44;
  static const double iconSizeLarge = 64;
  static const double iconSizeExtraLarge = 84;

  /// Размер иконки приложения на домашнем экране.
  static const double iconSizeLauncher = 56;

  // Высоты элементов (ItemSizeData)

  /// Минимальная цель нажатия — 48×48.
  static const double itemSizeExtraSmall = 48;
  static const double itemSizeSmall = 56;
  static const double itemSizeMedium = 68;
  static const double itemSizeLarge = 76;
  static const double itemSizeExtraLarge = 92;
  static const double itemSizeHuge = 120;

  /// Высота панели приложения (itemSizeHeader).
  static const double itemSizeHeader = 68;

  /// Толщина линий и индикаторов.
  static const double lineWidth = 2;

  /// Минимальная ширина поля поиска в панели приложения (гайдлайн — 300 dp).
  static const double searchFieldMinWidth = 300;

  /// Максимальная ширина разделителя панелей SplitView (гайдлайн — 6 dp).
  static const double splitViewSeparator = 6;

  /// Ширина закреплённой навигационной панели в многопанельном режиме.
  static const double navigationPanelWidth = 260;
}

/// Размеры шрифта (FontSizeData из «Aurora Controls»).
class AuroraFontSizes {
  const AuroraFontSizes._();

  static const double tiny = 12;
  static const double extraSmall = 14;
  static const double small = 16;
  static const double medium = 19;
  static const double large = 21;
  static const double extraLarge = 26;
  static const double huge = 28;

  /// Межстрочный интервал текстовых стилей кита.
  static const double lineHeight = 1.25;
}

/// Начертания шрифта (FontWeightData).
class AuroraFontWeights {
  const AuroraFontWeights._();

  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight bold = FontWeight.w700;
}

/// Уровни прозрачности (OpacityData).
class AuroraOpacity {
  const AuroraOpacity._();

  static const double faint = 0.2;
  static const double low = 0.4;
  static const double high = 0.6;
  static const double overlay = 0.8;
  static const double highlightBackground = 0.3;
}

/// Радиусы скругления.
///
/// Кит задаёт радиус 4 для кнопок и полей ввода; для карточек и модальных
/// панелей приложение использует кратные модулю 8 и 16.
class AuroraRadius {
  const AuroraRadius._();

  static final BorderRadius small = BorderRadius.circular(4);
  static final BorderRadius medium = BorderRadius.circular(8);
  static final BorderRadius large = BorderRadius.circular(16);
}

/// Длительности анимаций интерфейса.
class AuroraDurations {
  const AuroraDurations._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
}
