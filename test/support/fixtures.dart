// SPDX-License-Identifier: BSD-3-Clause
//
// Общие данные и сборка приложения для тестов и генератора скриншотов.
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

/// Пустое состояние приложения: только стандартные категории.
Future<AppState> emptyState() async => _state(const <Expense>[], const <Trip>[]);

/// Состояние с демонстрационными данными: полгода трат, две командировки,
/// своя категория.
Future<AppState> demoState() async => _state(_demoExpenses, _demoTrips);

Future<AppState> _state(List<Expense> expenses, List<Trip> trips) async {
  final JsonStore store = MemoryJsonStore();
  final CategoryRepository categories = CategoryRepository(store);
  final TripRepository tripRepository = TripRepository(store);
  final ExpenseRepository expenseRepository = ExpenseRepository(store);

  await categories.saveAll(<ExpenseCategory>[
    ...ExpenseCategory.defaults,
    if (expenses.isNotEmpty) _subscriptions,
  ]);
  await tripRepository.saveAll(trips);
  await expenseRepository.saveAll(expenses);

  final AppState state = AppState(
    expenseRepository: expenseRepository,
    categoryRepository: categories,
    tripRepository: tripRepository,
    receiptStorage: ReceiptStorage(store),
    store: store,
  );
  await state.load();
  return state;
}

/// Готовое приложение с подставленным состоянием.
Widget buildApp(AppState state, {ThemeMode mode = ThemeMode.dark}) =>
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AppState>.value(value: state),
        ChangeNotifierProvider<SettingsController>.value(
          value: SettingsController(themeMode: mode),
        ),
      ],
      child: const ExpenseTrackerApp(),
    );

/// Инициализация локали для форматирования дат.
Future<void> initLocale() async {
  await initializeDateFormatting('ru_RU', null);
  Intl.defaultLocale = 'ru_RU';
}

/// Загружает Roboto и шрифт иконок из кэша Flutter SDK, чтобы текст
/// в снимках экрана отрисовывался, а не заменялся прямоугольниками.
Future<void> loadTestFonts() async {
  final String? root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) {
    return;
  }
  final Directory fonts = Directory('$root/bin/cache/artifacts/material_fonts');
  if (!fonts.existsSync()) {
    return;
  }

  final File icons = File('${fonts.path}/materialicons-regular.otf');
  if (icons.existsSync()) {
    final FontLoader iconLoader = FontLoader('MaterialIcons')
      ..addFont(_load(icons));
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
      loader.addFont(_load(file));
    }
  }
  await loader.load();
}

Future<ByteData> _load(File file) async =>
    ByteData.sublistView(await file.readAsBytes());

const ExpenseCategory _subscriptions = ExpenseCategory(
  id: 'cat_subscriptions',
  name: 'Подписки',
  iconKey: 'phone',
  colorIndex: 8,
);

final List<Trip> _demoTrips = <Trip>[
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

int _counter = 0;

Expense _expense(
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
  id: 'demo_${_counter++}',
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

final List<Expense> _demoExpenses = <Expense>[
  _expense(2026, 9, 12, 2480.30, 'cat_groceries', 'Пятёрочка',
      'Продукты на неделю', receipts: 1),
  _expense(2026, 9, 11, 390, 'cat_cafe', 'Кофейня «Сити»', 'Кофе с коллегами',
      method: PaymentMethod.qr),
  _expense(2026, 9, 9, 1150, 'cat_transport', 'Яндекс Такси', 'Поездка в офис'),
  _expense(2026, 9, 5, 5400, 'cat_utilities', 'ЖКХ Центр',
      'Коммунальные за август'),
  _expense(2026, 9, 3, 899, 'cat_subscriptions', 'Кинопоиск',
      'Годовая подписка'),
  _expense(2026, 8, 30, 3200, 'cat_health', 'Аптека «Здоровье»', 'Лекарства',
      method: PaymentMethod.cash),
  _expense(2026, 8, 27, 7800, 'cat_clothes', 'Спортмастер', 'Кроссовки',
      receipts: 2),
  _expense(2026, 8, 16, 4300, 'cat_transport', 'РЖД', 'Билет Казань — Москва',
      tripId: 'trip_kazan', receipts: 1),
  _expense(2026, 8, 15, 1780, 'cat_cafe', 'Ресторан «Тюбетей»', 'Ужин',
      tripId: 'trip_kazan'),
  _expense(2026, 8, 14, 9600, 'cat_utilities', 'Гостиница «Волга»',
      'Проживание, 3 ночи', tripId: 'trip_kazan', receipts: 1),
  _expense(2026, 8, 12, 4150, 'cat_transport', 'Аэрофлот',
      'Перелёт Москва — Казань', tripId: 'trip_kazan'),
  _expense(2026, 8, 6, 620, 'cat_cafe', 'Столовая №1', 'Обед',
      method: PaymentMethod.cash),
  _expense(2026, 8, 2, 2990, 'cat_entertainment', 'Каро Фильм',
      'Кино с семьёй'),
  _expense(2026, 7, 28, 12500, 'cat_education', 'Учебный центр',
      'Курс по Flutter'),
  _expense(2026, 7, 21, 2340, 'cat_groceries', 'Магнит', 'Продукты'),
  _expense(2026, 7, 14, 760, 'cat_transport', 'Мосгортранс', 'Проездной',
      method: PaymentMethod.qr),
  _expense(2026, 7, 7, 4100, 'cat_health', 'Клиника «Мед+»', 'Приём врача',
      receipts: 1),
  _expense(2026, 6, 25, 3150, 'cat_groceries', 'Вкусвилл', 'Продукты'),
  _expense(2026, 6, 18, 1890, 'cat_entertainment', 'Парк Горького', 'Выходные'),
  _expense(2026, 6, 7, 5200, 'cat_utilities', 'Отель «Нева»', 'Проживание',
      tripId: 'trip_spb', receipts: 1),
  _expense(2026, 6, 5, 980, 'cat_cafe', 'Кафе «Север»', 'Обед',
      tripId: 'trip_spb', method: PaymentMethod.cash),
  _expense(2026, 6, 3, 3600, 'cat_transport', 'РЖД', 'Сапсан Москва — СПб',
      tripId: 'trip_spb'),
  _expense(2026, 5, 29, 2100, 'cat_clothes', 'Zarina', 'Летняя одежда'),
  _expense(2026, 5, 20, 1450, 'cat_groceries', 'Лента', 'Продукты',
      method: PaymentMethod.other),
  _expense(2026, 5, 12, 890, 'cat_cafe', 'Шоколадница', 'Завтрак'),
  _expense(2026, 4, 26, 6700, 'cat_education', 'Книжный дом',
      'Учебные материалы'),
  _expense(2026, 4, 15, 2300, 'cat_groceries', 'Перекрёсток', 'Продукты'),
];
