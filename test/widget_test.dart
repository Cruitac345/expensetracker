// SPDX-License-Identifier: BSD-3-Clause
import 'package:expense_tracker/app.dart';
import 'package:expense_tracker/data/repositories/repositories.dart';
import 'package:expense_tracker/data/services/receipt_storage.dart';
import 'package:expense_tracker/data/store/json_store.dart';
import 'package:expense_tracker/state/app_state.dart';
import 'package:expense_tracker/state/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

Future<Widget> buildApp() async {
  final JsonStore store = MemoryJsonStore();
  final AppState state = AppState(
    expenseRepository: ExpenseRepository(store),
    categoryRepository: CategoryRepository(store),
    tripRepository: TripRepository(store),
    receiptStorage: ReceiptStorage(store),
    store: store,
  );
  await state.load();

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AppState>.value(value: state),
      ChangeNotifierProvider<SettingsController>.value(
        value: SettingsController(themeMode: ThemeMode.dark),
      ),
    ],
    child: const ExpenseTrackerApp(),
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ru_RU', null);
    Intl.defaultLocale = 'ru_RU';
  });

  testWidgets('на смартфоне открывается список трат с пустым состоянием', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(await buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Траты'), findsOneWidget);
    expect(find.text('Трат пока нет'), findsOneWidget);
    // На смартфоне разделы доступны из панели приложения.
    expect(find.byIcon(Icons.menu), findsOneWidget);
  });

  testWidgets('на планшете панель разделов закреплена слева', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(2560, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(await buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Дашборд'), findsOneWidget);
    expect(find.text('Командировки'), findsOneWidget);
    expect(find.text('Импорт CSV'), findsOneWidget);
    expect(find.byIcon(Icons.menu), findsNothing);
  });

  testWidgets('форма новой траты содержит все поля', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(await buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FloatingActionButton, 'Трата'));
    await tester.pumpAndSettle();

    expect(find.text('Новая трата'), findsOneWidget);
    expect(find.text('Сумма'), findsOneWidget);
    expect(find.text('Категория'), findsOneWidget);
    expect(find.text('Получатель платежа'), findsOneWidget);
    expect(find.text('Комментарий'), findsOneWidget);

    // Остальные поля формы расположены ниже — прокручиваем список.
    await tester.dragUntilVisible(
      find.text('Чеки'),
      find.byType(ListView),
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();

    expect(find.text('Способ оплаты'), findsOneWidget);
    expect(find.text('Командировка'), findsWidgets);
    expect(find.text('Чеки'), findsOneWidget);
    expect(find.text('Чеки не прикреплены'), findsOneWidget);
  });
}
