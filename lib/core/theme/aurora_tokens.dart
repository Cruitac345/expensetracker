// SPDX-License-Identifier: BSD-3-Clause
import 'package:flutter/widgets.dart';

/// Размерные константы дизайн-системы ОС Аврора.
///
/// Именование и значения соответствуют гайдлайну Аврора (UI Kit):
/// отступы `padding*`, размеры иконок `iconSize*`, высоты элементов
/// списка `itemSize*`. Компоненты приложения не используют «магические»
/// числа — только эти токены.
class AuroraSizes {
  const AuroraSizes._();

  // Отступы
  static const double paddingSmall = 4;
  static const double paddingMedium = 12;
  static const double paddingLarge = 24;

  /// Поля страницы. На планшете поля шире (гайдлайн «Панель приложения»).
  static const double pageMarginPhone = 24;
  static const double pageMarginTablet = 32;

  // Размеры иконок
  static const double iconSizeExtraSmall = 24;
  static const double iconSizeSmall = 32;

  /// Размер кнопки-иконки в панели приложения — 48×48 (гайдлайн AppBar).
  static const double iconSizeSmallPlus = 48;
  static const double iconSizeMedium = 64;
  static const double iconSizeLarge = 96;

  // Высоты элементов списка
  static const double itemSizeExtraSmall = 48;
  static const double itemSizeSmall = 64;
  static const double itemSizeMedium = 80;
  static const double itemSizeLarge = 96;

  /// Высота панели приложения: заголовок + подзаголовок.
  static const double appBarHeight = 72;

  /// Минимальная ширина поля поиска в панели приложения (гайдлайн — 300dp).
  static const double searchFieldMinWidth = 300;

  /// Максимальная ширина разделителя панелей SplitView (гайдлайн — 6dp).
  static const double splitViewSeparator = 6;

  /// Ширина закреплённой навигационной панели в многопанельном режиме.
  static const double navigationPanelWidth = 260;

  /// Размер иконки приложения на экране устройства (гайдлайн «Иконки»).
  static const double iconSizeLauncher = 86;
}

/// Радиусы скругления (UI Kit ОС Аврора).
class AuroraRadius {
  const AuroraRadius._();

  static final BorderRadius small = BorderRadius.circular(8);
  static final BorderRadius medium = BorderRadius.circular(16);
  static final BorderRadius large = BorderRadius.circular(24);
}

/// Длительности анимаций интерфейса.
class AuroraDurations {
  const AuroraDurations._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
}
