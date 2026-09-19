// SPDX-License-Identifier: BSD-3-Clause
//
// Кнопки целиком помещаются на экран, не обрезаются по горизонтали
// и не меньше цели нажатия 48×48.
import 'package:expense_tracker/core/theme/aurora_tokens.dart';
import 'package:expense_tracker/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures.dart';

/// Минимальная цель нажатия.
const double minTarget = AuroraSizes.itemSizeExtraSmall;

/// Погрешность в пикселях на округление раскладки.
const double tolerance = 0.5;

/// Типы, для которых проверяется размер цели нажатия.
final List<Type> tapTargets = <Type>[
  IconButton,
  ElevatedButton,
  OutlinedButton,
  TextButton,
  FloatingActionButton,
];

/// Типы, которые проверяются только на обрезание (высота задаётся
/// компонентом Material и меньше 48).
final List<Type> compactControls = <Type>[
  ChoiceChip,
  FilterChip,
  ActionChip,
  ListTile,
];

class _Control {
  const _Control(this.type, this.rect, this.label);

  final Type type;
  final Rect rect;
  final String label;
}

List<_Control> _controls(WidgetTester tester, List<Type> types) {
  final List<_Control> result = <_Control>[];
  for (final Type type in types) {
    for (final Element element in find.byType(type).evaluate()) {
      final RenderObject? render = element.renderObject;
      if (render is! RenderBox || !render.hasSize || !render.attached) {
        continue;
      }
      final Rect rect = render.localToGlobal(Offset.zero) & render.size;
      if (rect.isEmpty) {
        continue;
      }
      final Iterable<Element> texts = find
          .descendant(
            of: find.byWidget(element.widget),
            matching: find.byType(Text),
          )
          .evaluate();
      final String label = texts.isEmpty
          ? ''
          : (texts.first.widget as Text).data ?? '';
      result.add(_Control(type, rect, label));
    }
  }
  return result;
}

void main() {
  setUpAll(initLocale);

  const List<(String, Size, double)> screens = <(String, Size, double)>[
    ('смартфон 320×640', Size(640, 1280), 2),
    ('смартфон 360×780', Size(1080, 2340), 3),
    ('планшет 1280×800', Size(2560, 1600), 2),
  ];

  for (final (String name, Size size, double ratio) in screens) {
    group(name, () {
      late Size screen;

      Future<void> prepare(WidgetTester tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = ratio;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        screen = size / ratio;

        final AppState state = await demoState();
        await tester.pumpWidget(buildApp(state));
        await tester.pumpAndSettle();
      }

      /// Кнопка не должна выходить за края экрана по горизонтали,
      /// а целиком видимая кнопка — ещё и по вертикали.
      void checkVisible(WidgetTester tester, String where) {
        for (final _Control control in _controls(tester, tapTargets)) {
          final Rect rect = control.rect;
          expect(
            rect.left,
            greaterThanOrEqualTo(-tolerance),
            reason:
                '$where: ${control.type} «${control.label}» '
                'выходит за левый край',
          );
          expect(
            rect.right,
            lessThanOrEqualTo(screen.width + tolerance),
            reason:
                '$where: ${control.type} «${control.label}» '
                'выходит за правый край',
          );
          // Элементы, прокрученные за пределы экрана, не проверяем.
          final bool onScreen =
              rect.top >= -tolerance &&
              rect.bottom <= screen.height + tolerance;
          if (onScreen) {
            expect(
              rect.height,
              greaterThanOrEqualTo(minTarget - tolerance),
              reason:
                  '$where: ${control.type} «${control.label}» '
                  'ниже минимальной цели нажатия',
            );
            if (control.type == IconButton ||
                control.type == FloatingActionButton) {
              expect(
                rect.width,
                greaterThanOrEqualTo(minTarget - tolerance),
                reason: '$where: ${control.type} уже минимальной цели нажатия',
              );
            }
          }
        }

        for (final _Control control in _controls(tester, compactControls)) {
          expect(
            control.rect.left,
            greaterThanOrEqualTo(-tolerance),
            reason:
                '$where: ${control.type} «${control.label}» '
                'выходит за левый край',
          );
          expect(
            control.rect.right,
            lessThanOrEqualTo(screen.width + tolerance),
            reason:
                '$where: ${control.type} «${control.label}» '
                'выходит за правый край',
          );
        }
      }

      Future<void> openSection(WidgetTester tester, String title) async {
        final Finder menu = find.byIcon(Icons.menu);
        if (menu.evaluate().isNotEmpty) {
          await tester.tap(menu);
          await tester.pumpAndSettle();
        }
        final Finder item = find.text(title).last;
        await tester.ensureVisible(item);
        await tester.pumpAndSettle();
        await tester.tap(item);
        await tester.pumpAndSettle();
      }

      testWidgets('список трат и панель приложения', (
        WidgetTester tester,
      ) async {
        await prepare(tester);
        checkVisible(tester, 'Траты');

        await tester.tap(find.byIcon(Icons.search));
        await tester.pumpAndSettle();
        checkVisible(tester, 'Траты с поиском');
      });

      testWidgets('форма траты', (WidgetTester tester) async {
        await prepare(tester);
        await tester.tap(find.widgetWithText(FloatingActionButton, 'Трата'));
        await tester.pumpAndSettle();
        checkVisible(tester, 'Новая трата');

        await tester.dragUntilVisible(
          find.text('Чеки'),
          find.byType(ListView).first,
          const Offset(0, -200),
        );
        await tester.pumpAndSettle();
        checkVisible(tester, 'Новая трата, низ формы');
      });

      testWidgets('панель фильтров', (WidgetTester tester) async {
        await prepare(tester);
        await tester.tap(find.byIcon(Icons.filter_alt_outlined));
        await tester.pumpAndSettle();
        checkVisible(tester, 'Фильтры');
      });

      testWidgets('дашборд', (WidgetTester tester) async {
        await prepare(tester);
        await openSection(tester, 'Дашборд');
        checkVisible(tester, 'Дашборд');
      });

      testWidgets('командировки и категории', (WidgetTester tester) async {
        await prepare(tester);
        await openSection(tester, 'Командировки');
        checkVisible(tester, 'Командировки');

        await openSection(tester, 'Категории');
        checkVisible(tester, 'Категории');
      });

      testWidgets('импорт и настройки', (WidgetTester tester) async {
        await prepare(tester);
        await openSection(tester, 'Импорт CSV');
        checkVisible(tester, 'Импорт CSV');

        await openSection(tester, 'Настройки');
        checkVisible(tester, 'Настройки');
      });
    });
  }
}
