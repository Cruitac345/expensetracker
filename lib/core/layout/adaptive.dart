// SPDX-License-Identifier: BSD-3-Clause
import 'package:flutter/material.dart';

import '../theme/aurora_tokens.dart';

/// Правила адаптации интерфейса под смартфоны и планшеты.
///
/// Гайдлайн ОС Аврора («Многопанельный режим») рекомендует показывать
/// несколько панелей, когда площадь экрана позволяет это без потери
/// читаемости: альбомная ориентация смартфона, а также планшет.
class AuroraLayout {
  const AuroraLayout._();

  /// Порог перехода к многопанельному режиму (список + детали).
  static const double splitBreakpoint = 720;

  /// Порог, при котором дополнительно закрепляется панель навигации.
  static const double wideBreakpoint = 1000;

  static double widthOf(BuildContext context) => MediaQuery.sizeOf(context).width;

  /// Многопанельный режим: список слева, содержимое справа.
  static bool isSplit(BuildContext context) =>
      widthOf(context) >= splitBreakpoint;

  /// Широкий экран планшета: панель навигации закреплена у левого края.
  static bool isWide(BuildContext context) =>
      widthOf(context) >= wideBreakpoint;

  /// Поля страницы: на планшете шире, чем на смартфоне.
  static double pageMargin(BuildContext context) => isSplit(context)
      ? AuroraSizes.pageMarginTablet
      : AuroraSizes.pageMarginPhone;

  static EdgeInsets pagePadding(BuildContext context) =>
      EdgeInsets.symmetric(horizontal: pageMargin(context));

  /// Число колонок сетки для плиток дашборда.
  static int dashboardColumns(BuildContext context) {
    final double width = widthOf(context);
    if (width >= wideBreakpoint) {
      return 3;
    }
    if (width >= splitBreakpoint) {
      return 2;
    }
    return 1;
  }
}

/// Многопанельный режим по гайдлайну ОС Аврора.
///
/// Панели располагаются слева направо и разделяются сепаратором шириной
/// не более 6dp. Ширина панели задаётся в колонках 12-колоночной сетки.
class AuroraSplitView extends StatelessWidget {
  const AuroraSplitView({required this.panels, super.key});

  final List<AuroraPanel> panels;

  @override
  Widget build(BuildContext context) {
    final Color separator = Theme.of(context).dividerColor;
    final List<Widget> children = <Widget>[];

    for (int i = 0; i < panels.length; i++) {
      final AuroraPanel panel = panels[i];
      children.add(
        panel.width != null
            ? SizedBox(width: panel.width, child: panel.child)
            : Expanded(flex: panel.columnSpan, child: panel.child),
      );
      if (i != panels.length - 1) {
        children.add(
          Container(width: AuroraSizes.splitViewSeparator, color: separator),
        );
      }
    }

    return Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
  }
}

/// Панель многопанельного режима.
@immutable
class AuroraPanel {
  const AuroraPanel({
    required this.child,
    this.columnSpan = 4,
    this.width,
  }) : assert(
         columnSpan >= 1 && columnSpan <= 12,
         'Панель занимает от 1 до 12 колонок',
       );

  /// Содержимое панели.
  final Widget child;

  /// Ширина панели в колонках 12-колоночной сетки (1…12).
  final int columnSpan;

  /// Фиксированная ширина — для закреплённой панели навигации.
  final double? width;
}
