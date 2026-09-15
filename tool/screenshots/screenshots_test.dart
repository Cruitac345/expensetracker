// SPDX-License-Identifier: BSD-3-Clause
//
// Генератор скриншотов для README.
//
// Запуск:
//   flutter test tool/screenshots/screenshots_test.dart --update-goldens
//
// Снимки делаются с демонстрационными данными в двух форматах экрана:
// смартфон (360×780 dp) и планшет (1280×800 dp).
import 'package:expense_tracker/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test/support/fixtures.dart';

const Size phone = Size(1080, 2340);
const double phoneRatio = 3;
const Size tablet = Size(2560, 1600);
const double tabletRatio = 2;

void main() {
  setUpAll(() async {
    await initLocale();
    await loadTestFonts();
  });

  Future<void> shoot(WidgetTester tester, String name) async {
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(ExpenseTrackerApp),
      matchesGoldenFile('../../docs/screenshots/$name.png'),
    );
  }

  void useScreen(WidgetTester tester, Size size, double ratio) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = ratio;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> openSection(WidgetTester tester, String title) async {
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    final Finder item = find.text(title).last;
    await tester.ensureVisible(item);
    await tester.pumpAndSettle();
    await tester.tap(item);
    await tester.pumpAndSettle();
  }

  testWidgets('смартфон: список трат', (WidgetTester tester) async {
    useScreen(tester, phone, phoneRatio);
    await tester.pumpWidget(buildApp(await demoState()));
    await shoot(tester, 'phone-expenses');
  });

  testWidgets('смартфон: фильтры', (WidgetTester tester) async {
    useScreen(tester, phone, phoneRatio);
    await tester.pumpWidget(buildApp(await demoState()));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.filter_alt_outlined));
    await tester.pumpAndSettle();
    await shoot(tester, 'phone-filters');
  });

  testWidgets('смартфон: новая трата', (WidgetTester tester) async {
    useScreen(tester, phone, phoneRatio);
    await tester.pumpWidget(buildApp(await demoState()));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FloatingActionButton, 'Трата'));
    await tester.pumpAndSettle();
    await shoot(tester, 'phone-expense-form');
  });

  testWidgets('смартфон: дашборд', (WidgetTester tester) async {
    useScreen(tester, phone, phoneRatio);
    await tester.pumpWidget(buildApp(await demoState()));
    await tester.pumpAndSettle();
    await openSection(tester, 'Дашборд');
    await shoot(tester, 'phone-dashboard');
  });

  testWidgets('смартфон: командировки', (WidgetTester tester) async {
    useScreen(tester, phone, phoneRatio);
    await tester.pumpWidget(buildApp(await demoState()));
    await tester.pumpAndSettle();
    await openSection(tester, 'Командировки');
    await shoot(tester, 'phone-trips');
  });

  testWidgets('смартфон: категории', (WidgetTester tester) async {
    useScreen(tester, phone, phoneRatio);
    await tester.pumpWidget(buildApp(await demoState()));
    await tester.pumpAndSettle();
    await openSection(tester, 'Категории');
    await shoot(tester, 'phone-categories');
  });

  testWidgets('смартфон: импорт CSV', (WidgetTester tester) async {
    useScreen(tester, phone, phoneRatio);
    await tester.pumpWidget(buildApp(await demoState()));
    await tester.pumpAndSettle();
    await openSection(tester, 'Импорт CSV');
    await shoot(tester, 'phone-import');
  });

  testWidgets('смартфон: светлая схема', (WidgetTester tester) async {
    useScreen(tester, phone, phoneRatio);
    await tester.pumpWidget(buildApp(await demoState(), mode: ThemeMode.light));
    await shoot(tester, 'phone-expenses-light');
  });

  testWidgets('планшет: многопанельный режим', (WidgetTester tester) async {
    useScreen(tester, tablet, tabletRatio);
    await tester.pumpWidget(buildApp(await demoState()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Пятёрочка').first);
    await shoot(tester, 'tablet-expenses');
  });

  testWidgets('планшет: дашборд', (WidgetTester tester) async {
    useScreen(tester, tablet, tabletRatio);
    await tester.pumpWidget(buildApp(await demoState()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Дашборд').last);
    await shoot(tester, 'tablet-dashboard');
  });

  testWidgets('планшет: командировки', (WidgetTester tester) async {
    useScreen(tester, tablet, tabletRatio);
    await tester.pumpWidget(buildApp(await demoState()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Командировки').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Казань, конференция').first);
    await shoot(tester, 'tablet-trips');
  });
}
