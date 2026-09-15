// SPDX-License-Identifier: BSD-3-Clause
//
// Генератор скриншотов для README.
//
// Запуск:
//   flutter test tool/screenshots/screenshots_test.dart --update-goldens
//
// Скриншоты снимаются с демонстрационными данными в двух форматах экрана:
// смартфон (360×780 dp) и планшет (1280×800 dp).
import 'dart:io';

import 'package:expense_tracker/app.dart';
import 'package:expense_tracker/data/models/expense.dart';
import 'package:expense_tracker/data/models/expense_category.dart';
import 'package:expense_tracker/data/models/payment_method.dart';
import 'package:expense_tracker/data/models/trip.dart';
import 'package:expense_tracker/data/repositories/repositories.dart';
import 'package:expense_tracker/data/services/receipt_storage.dart';
import 'package:expense_tracker/data/store/json_store.dart';
import 'package:expense_tracker/state/app_state.dart';
import 'package:expense_tracker/state/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

const Size phone = Size(1080, 2340);
const double phoneRatio = 3;
const Size tablet = Size(2560, 1600);
const double tabletRatio = 2;

Future<void> loadFonts() async {
  final String? root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) {
    return;
  }
  final Directory fonts = Directory(
    '$root/bin/cache/artifacts/material_fonts',
  );
  if (!fonts.existsSync()) {
    return;
  }

  final File icons = File('${fonts.path}/materialicons-regular.otf');
  if (icons.existsSync()) {
    final FontLoader iconLoader = FontLoader('MaterialIcons');
    final Uint8List bytes = await icons.readAsBytes();
    iconLoader.addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
    await iconLoader.load();
  }

  final FontLoader loader = FontLoader('Roboto');
  for (final String name in <String>[
    'roboto-regular.ttf',
    'roboto-medium.ttf',
    'roboto-bold.ttf',
  ]) {
    final File file = File('${fonts.path}/$name');
    if (file.existsSync()) {
      final Uint8List bytes = await file.readAsBytes();
      loader.addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
    }
  }
  await loader.load();
}

/// Демонстрационные данные: полгода трат, две командировки, свои категории.
Future<AppState> demoState() async {
  final JsonStore store = MemoryJsonStore();
  final CategoryRepository categories = CategoryRepository(store);
  final TripRepository trips = TripRepository(store);
  final ExpenseRepository expenses = ExpenseRepository(store);

  final List<ExpenseCategory> allCategories = <ExpenseCategory>[
    ...ExpenseCategory.defaults,
    const ExpenseCategory(
      id: 'cat_subscriptions',
      name: 'Подписки',
      iconKey: 'phone',
      colorIndex: 8,
    ),
  ];
  await categories.saveAll(allCategories);

  final List<Trip> allTrips = <Trip>[
    Trip(
      id: 'trip_kazan',
      title: 'Казань, конференция',
      startDate: DateTime(2026, 8, 12),
      endDate: DateTime(2026, 8, 16),
      destination: 'Казань',
      note: 'Отраслевая конференция, авансовый отчёт до 25 августа',
    ),
    Trip(
      id: 'trip_spb',
      title: 'Санкт-Петербург, аудит',
      startDate: DateTime(2026, 6, 3),
      endDate: DateTime(2026, 6, 7),
      destination: 'Санкт-Петербург',
    ),
  ];
  await trips.saveAll(allTrips);

  int counter = 0;
  Expense make(
    int year,
    int month,
    int day,
    double amount,
    String categoryId,
    String payee,
    String comment, {
    PaymentMethod method = PaymentMethod.card,
    String? tripId,
    int receipts = 0,
  }) => Expense(
    id: 'demo_${counter++}',
    amount: amount,
    categoryId: categoryId,
    date: DateTime(year, month, day),
    payee: payee,
    comment: comment,
    paymentMethod: method,
    tripId: tripId,
    receiptPaths: List<String>.generate(
      receipts,
      (int index) => 'receipts/demo_$index.jpg',
    ),
  );

  await expenses.saveAll(<Expense>[
    make(2026, 9, 12, 2480.30, 'cat_groceries', 'Пятёрочка', 'Продукты на неделю', receipts: 1),
    make(2026, 9, 11, 390, 'cat_cafe', 'Кофейня «Сити»', 'Кофе с коллегами', method: PaymentMethod.qr),
    make(2026, 9, 9, 1150, 'cat_transport', 'Яндекс Такси', 'Поездка в офис'),
    make(2026, 9, 5, 5400, 'cat_utilities', 'ЖКХ Центр', 'Коммунальные за август'),
    make(2026, 9, 3, 899, 'cat_subscriptions', 'Кинопоиск', 'Годовая подписка'),
    make(2026, 8, 30, 3200, 'cat_health', 'Аптека «Здоровье»', 'Лекарства', method: PaymentMethod.cash),
    make(2026, 8, 27, 7800, 'cat_clothes', 'Спортмастер', 'Кроссовки', receipts: 2),
    make(2026, 8, 16, 4300, 'cat_transport', 'РЖД', 'Билет Казань — Москва', tripId: 'trip_kazan', receipts: 1),
    make(2026, 8, 15, 1780, 'cat_cafe', 'Ресторан «Тюбетей»', 'Ужин', tripId: 'trip_kazan'),
    make(2026, 8, 14, 9600, 'cat_utilities', 'Гостиница «Волга»', 'Проживание, 3 ночи', tripId: 'trip_kazan', receipts: 1),
    make(2026, 8, 12, 4150, 'cat_transport', 'Аэрофлот', 'Перелёт Москва — Казань', tripId: 'trip_kazan'),
    make(2026, 8, 6, 620, 'cat_cafe', 'Столовая №1', 'Обед', method: PaymentMethod.cash),
    make(2026, 8, 2, 2990, 'cat_entertainment', 'Каро Фильм', 'Кино с семьёй'),
    make(2026, 7, 28, 12500, 'cat_education', 'Учебный центр', 'Курс по Flutter'),
    make(2026, 7, 21, 2340, 'cat_groceries', 'Магнит', 'Продукты'),
    make(2026, 7, 14, 760, 'cat_transport', 'Мосгортранс', 'Проездной', method: PaymentMethod.qr),
    make(2026, 7, 7, 4100, 'cat_health', 'Клиника «Мед+»', 'Приём врача', receipts: 1),
    make(2026, 6, 25, 3150, 'cat_groceries', 'Вкусвилл', 'Продукты'),
    make(2026, 6, 18, 1890, 'cat_entertainment', 'Парк Горького', 'Выходные'),
    make(2026, 6, 7, 5200, 'cat_utilities', 'Отель «Нева»', 'Проживание', tripId: 'trip_spb', receipts: 1),
    make(2026, 6, 5, 980, 'cat_cafe', 'Кафе «Север»', 'Обед', tripId: 'trip_spb', method: PaymentMethod.cash),
    make(2026, 6, 3, 3600, 'cat_transport', 'РЖД', 'Сапсан Москва — СПб', tripId: 'trip_spb'),
    make(2026, 5, 29, 2100, 'cat_clothes', 'Zarina', 'Летняя одежда'),
    make(2026, 5, 20, 1450, 'cat_groceries', 'Лента', 'Продукты', method: PaymentMethod.other),
    make(2026, 5, 12, 890, 'cat_cafe', 'Шоколадница', 'Завтрак'),
    make(2026, 4, 26, 6700, 'cat_education', 'Книжный дом', 'Учебные материалы'),
    make(2026, 4, 15, 2300, 'cat_groceries', 'Перекрёсток', 'Продукты'),
  ]);

  final AppState state = AppState(
    expenseRepository: expenses,
    categoryRepository: categories,
    tripRepository: trips,
    receiptStorage: ReceiptStorage(store),
    store: store,
  );
  await state.load();
  return state;
}

Future<Widget> app(AppState state, {ThemeMode mode = ThemeMode.dark}) async =>
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AppState>.value(value: state),
        ChangeNotifierProvider<SettingsController>.value(
          value: SettingsController(themeMode: mode),
        ),
      ],
      child: const ExpenseTrackerApp(),
    );

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ru_RU', null);
    Intl.defaultLocale = 'ru_RU';
    await loadFonts();
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
    await tester.tap(find.text(title).last);
    await tester.pumpAndSettle();
  }

  testWidgets('смартфон: список трат', (WidgetTester tester) async {
    useScreen(tester, phone, phoneRatio);
    await tester.pumpWidget(await app(await demoState()));
    await shoot(tester, 'phone-expenses');
  });

  testWidgets('смартфон: фильтры', (WidgetTester tester) async {
    useScreen(tester, phone, phoneRatio);
    await tester.pumpWidget(await app(await demoState()));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.filter_alt_outlined));
    await tester.pumpAndSettle();
    await shoot(tester, 'phone-filters');
  });

  testWidgets('смартфон: новая трата', (WidgetTester tester) async {
    useScreen(tester, phone, phoneRatio);
    await tester.pumpWidget(await app(await demoState()));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FloatingActionButton, 'Трата'));
    await tester.pumpAndSettle();
    await shoot(tester, 'phone-expense-form');
  });

  testWidgets('смартфон: дашборд', (WidgetTester tester) async {
    useScreen(tester, phone, phoneRatio);
    await tester.pumpWidget(await app(await demoState()));
    await tester.pumpAndSettle();
    await openSection(tester, 'Дашборд');
    await shoot(tester, 'phone-dashboard');
  });

  testWidgets('смартфон: командировки', (WidgetTester tester) async {
    useScreen(tester, phone, phoneRatio);
    await tester.pumpWidget(await app(await demoState()));
    await tester.pumpAndSettle();
    await openSection(tester, 'Командировки');
    await shoot(tester, 'phone-trips');
  });

  testWidgets('смартфон: категории', (WidgetTester tester) async {
    useScreen(tester, phone, phoneRatio);
    await tester.pumpWidget(await app(await demoState()));
    await tester.pumpAndSettle();
    await openSection(tester, 'Категории');
    await shoot(tester, 'phone-categories');
  });

  testWidgets('смартфон: импорт CSV', (WidgetTester tester) async {
    useScreen(tester, phone, phoneRatio);
    await tester.pumpWidget(await app(await demoState()));
    await tester.pumpAndSettle();
    await openSection(tester, 'Импорт CSV');
    await shoot(tester, 'phone-import');
  });

  testWidgets('смартфон: светлая схема', (WidgetTester tester) async {
    useScreen(tester, phone, phoneRatio);
    await tester.pumpWidget(
      await app(await demoState(), mode: ThemeMode.light),
    );
    await shoot(tester, 'phone-expenses-light');
  });

  testWidgets('планшет: многопанельный режим', (WidgetTester tester) async {
    useScreen(tester, tablet, tabletRatio);
    final AppState state = await demoState();
    await tester.pumpWidget(await app(state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Пятёрочка').first);
    await shoot(tester, 'tablet-expenses');
  });

  testWidgets('планшет: дашборд', (WidgetTester tester) async {
    useScreen(tester, tablet, tabletRatio);
    await tester.pumpWidget(await app(await demoState()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Дашборд').last);
    await shoot(tester, 'tablet-dashboard');
  });

  testWidgets('планшет: командировки', (WidgetTester tester) async {
    useScreen(tester, tablet, tabletRatio);
    await tester.pumpWidget(await app(await demoState()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Командировки').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Казань, конференция').first);
    await shoot(tester, 'tablet-trips');
  });
}
