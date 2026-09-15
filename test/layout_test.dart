// SPDX-License-Identifier: BSD-3-Clause
//
// Проверка вёрстки: ни один экран не должен переполняться или ломаться
// на поддерживаемых размерах экрана и при увеличенном системном шрифте.
import 'package:expense_tracker/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures.dart';

/// Размер экрана в физических пикселях и его плотность.
class Screen {
  const Screen(this.name, this.size, this.ratio);

  final String name;
  final Size size;
  final double ratio;

  /// Логический размер в dp — по нему приложение выбирает раскладку.
  Size get logical => size / ratio;
}

const List<Screen> screens = <Screen>[
  // Смартфон с самым узким поддерживаемым экраном.
  Screen('смартфон 320×640', Size(640, 1280), 2),
  Screen('смартфон 360×780', Size(1080, 2340), 3),
  Screen('смартфон 412×915', Size(1236, 2745), 3),
  // Альбомная ориентация смартфона — включается многопанельный режим.
  Screen('смартфон альбомный 780×360', Size(2340, 1080), 3),
  Screen('планшет портрет 800×1280', Size(1600, 2560), 2),
  Screen('планшет альбомный 1280×800', Size(2560, 1600), 2),
];

void main() {
  setUpAll(initLocale);

  /// Пролистывает первый прокручиваемый список до конца — так проверяется
  /// вёрстка элементов, которые не попали на первый экран.
  Future<void> scrollThrough(WidgetTester tester) async {
    final Finder scrollable = find.byType(Scrollable).first;
    if (scrollable.evaluate().isEmpty) {
      return;
    }
    for (int i = 0; i < 6; i++) {
      await tester.drag(scrollable, const Offset(0, -400));
      await tester.pump();
      expect(
        tester.takeException(),
        isNull,
        reason: 'исключение при прокрутке',
      );
    }
    await tester.pumpAndSettle();
  }

  Future<void> openSection(WidgetTester tester, String title) async {
    final Finder menu = find.byIcon(Icons.menu);
    if (menu.evaluate().isNotEmpty) {
      await tester.tap(menu);
      await tester.pumpAndSettle();
    }
    final Finder item = find.text(title).last;
    // На невысоких экранах список разделов прокручивается.
    await tester.ensureVisible(item);
    await tester.pumpAndSettle();
    await tester.tap(item);
    await tester.pumpAndSettle();
  }

  for (final Screen screen in screens) {
    group(screen.name, () {
      Future<void> prepare(
        WidgetTester tester, {
        double textScale = 1.0,
      }) async {
        tester.view.physicalSize = screen.size;
        tester.view.devicePixelRatio = screen.ratio;
        tester.platformDispatcher.textScaleFactorTestValue = textScale;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        final AppState state = await demoState();
        await tester.pumpWidget(buildApp(state));
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: 'исключение при запуске',
        );
      }

      testWidgets('список трат', (WidgetTester tester) async {
        await prepare(tester);
        await scrollThrough(tester);
        expect(tester.takeException(), isNull);
      });

      testWidgets('дашборд', (WidgetTester tester) async {
        await prepare(tester);
        await openSection(tester, 'Дашборд');
        expect(tester.takeException(), isNull);
        await scrollThrough(tester);
      });

      testWidgets('командировки', (WidgetTester tester) async {
        await prepare(tester);
        await openSection(tester, 'Командировки');
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Казань, конференция').first);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await scrollThrough(tester);
      });

      testWidgets('категории', (WidgetTester tester) async {
        await prepare(tester);
        await openSection(tester, 'Категории');
        expect(tester.takeException(), isNull);
        await scrollThrough(tester);
      });

      testWidgets('импорт и настройки', (WidgetTester tester) async {
        await prepare(tester);
        await openSection(tester, 'Импорт CSV');
        expect(tester.takeException(), isNull);
        await scrollThrough(tester);
        await openSection(tester, 'Настройки');
        expect(tester.takeException(), isNull);
        await scrollThrough(tester);
      });

      testWidgets('форма траты', (WidgetTester tester) async {
        await prepare(tester);
        await tester.tap(find.widgetWithText(FloatingActionButton, 'Трата'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await scrollThrough(tester);
      });

      testWidgets('панель фильтров', (WidgetTester tester) async {
        await prepare(tester);
        await tester.tap(find.byIcon(Icons.filter_alt_outlined));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await scrollThrough(tester);
      });

      testWidgets('поиск', (WidgetTester tester) async {
        await prepare(tester);
        await tester.tap(find.byIcon(Icons.search));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.enterText(find.byType(TextField).first, 'кофе');
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });

      testWidgets('крупный системный шрифт', (WidgetTester tester) async {
        await prepare(tester, textScale: 1.3);
        await scrollThrough(tester);
        await openSection(tester, 'Дашборд');
        expect(tester.takeException(), isNull);
        await scrollThrough(tester);
      });
    });
  }

  testWidgets('пустое состояние без данных', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(640, 1280);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildApp(await emptyState()));
    await tester.pumpAndSettle();

    expect(find.text('Трат пока нет'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
