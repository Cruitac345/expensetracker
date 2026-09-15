// SPDX-License-Identifier: BSD-3-Clause
import 'package:expense_tracker/data/models/expense.dart';
import 'package:expense_tracker/data/models/expense_category.dart';
import 'package:expense_tracker/data/models/expense_filter.dart';
import 'package:expense_tracker/data/models/payment_method.dart';
import 'package:expense_tracker/data/models/trip.dart';
import 'package:expense_tracker/data/repositories/repositories.dart';
import 'package:expense_tracker/data/services/csv_import_service.dart';
import 'package:expense_tracker/data/services/receipt_storage.dart';
import 'package:expense_tracker/data/store/json_store.dart';
import 'package:expense_tracker/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late JsonStore store;
  late AppState state;

  Future<AppState> buildState() async {
    store = MemoryJsonStore();
    final AppState created = AppState(
      expenseRepository: ExpenseRepository(store),
      categoryRepository: CategoryRepository(store),
      tripRepository: TripRepository(store),
      receiptStorage: ReceiptStorage(store),
      store: store,
    );
    await created.load();
    return created;
  }

  setUp(() async {
    state = await buildState();
  });

  Expense sample({
    double amount = 500,
    String? categoryId,
    DateTime? date,
    String? tripId,
    String payee = 'Магнит',
    String comment = '',
  }) => Expense(
    id: state.newId(),
    amount: amount,
    categoryId: categoryId ?? state.categories.first.id,
    date: date ?? DateTime(2026, 5, 14),
    payee: payee,
    comment: comment,
    tripId: tripId,
  );

  test('при первом запуске создаются стандартные категории', () async {
    expect(state.categories, hasLength(ExpenseCategory.defaults.length));
    expect(
      state.categories.map((ExpenseCategory c) => c.name),
      containsAll(<String>[
        'Продукты',
        'Кафе',
        'Коммунальные платежи',
        'Транспорт',
        'Одежда',
        'Здоровье',
        'Развлечение',
        'Обучение',
      ]),
    );
    expect(state.customCategories, isEmpty);
  });

  test('трата добавляется, изменяется и удаляется', () async {
    final Expense expense = sample();
    await state.addExpense(expense);
    expect(state.allExpenses, hasLength(1));

    await state.updateExpense(
      expense.copyWith(amount: 750, comment: 'Уточнено'),
    );
    expect(state.allExpenses.single.amount, equals(750));
    expect(state.allExpenses.single.comment, equals('Уточнено'));

    await state.deleteExpense(expense.id);
    expect(state.allExpenses, isEmpty);
  });

  test('данные переживают перезагрузку хранилища', () async {
    await state.addExpense(sample(amount: 1200));

    final AppState reloaded = AppState(
      expenseRepository: ExpenseRepository(store),
      categoryRepository: CategoryRepository(store),
      tripRepository: TripRepository(store),
      receiptStorage: ReceiptStorage(store),
      store: store,
    );
    await reloaded.load();

    expect(reloaded.allExpenses, hasLength(1));
    expect(reloaded.allExpenses.single.amount, equals(1200));
  });

  test('фильтр и сортировка применяются к списку', () async {
    await state.addExpense(
      sample(amount: 100, date: DateTime(2026, 5, 1), comment: 'кофе'),
    );
    await state.addExpense(
      sample(amount: 900, date: DateTime(2026, 5, 20), comment: 'ноутбук'),
    );

    state.applyFilter(const ExpenseFilter(minAmount: 500));
    expect(state.visibleExpenses, hasLength(1));
    expect(state.visibleExpenses.single.amount, equals(900));

    state.resetFilter();
    state.updateQuery('кофе');
    expect(state.visibleExpenses, hasLength(1));

    state.resetFilter();
    state.changeSort(ExpenseSort.amountAsc);
    expect(state.visibleExpenses.first.amount, equals(100));
    state.changeSort(ExpenseSort.amountDesc);
    expect(state.visibleExpenses.first.amount, equals(900));
  });

  group('Категории', () {
    test('своя категория создаётся и изменяется', () async {
      final ExpenseCategory category = await state.addCategory(
        name: 'Подписки',
        iconKey: 'phone',
        colorIndex: 3,
      );
      expect(state.customCategories, hasLength(1));

      await state.updateCategory(category.copyWith(name: 'Сервисы'));
      expect(state.categoryById(category.id)?.name, equals('Сервисы'));
    });

    test('стандартная категория не удаляется', () async {
      final String builtInId = state.categories.first.id;
      await state.deleteCategory(builtInId);
      expect(state.categoryById(builtInId), isNotNull);
    });

    test('удаление своей категории переносит траты', () async {
      final ExpenseCategory category = await state.addCategory(
        name: 'Подписки',
        iconKey: 'phone',
        colorIndex: 3,
      );
      await state.addExpense(sample(categoryId: category.id));
      final String target = state.categories.first.id;

      await state.deleteCategory(category.id, replacementId: target);

      expect(state.categoryById(category.id), isNull);
      expect(state.allExpenses.single.categoryId, equals(target));
    });

    test('удаление своей категории вместе с тратами', () async {
      final ExpenseCategory category = await state.addCategory(
        name: 'Подписки',
        iconKey: 'phone',
        colorIndex: 3,
      );
      await state.addExpense(sample(categoryId: category.id));

      await state.deleteCategory(category.id);

      expect(state.categoryById(category.id), isNull);
      expect(state.allExpenses, isEmpty);
    });
  });

  group('Командировки', () {
    test('трата прикрепляется и открепляется', () async {
      final Trip trip = await state.addTrip(
        title: 'Казань',
        startDate: DateTime(2026, 5, 10),
        endDate: DateTime(2026, 5, 20),
      );
      final Expense expense = sample();
      await state.addExpense(expense);

      await state.assignTrip(expense.id, trip.id);
      expect(state.expensesOfTrip(trip.id), hasLength(1));

      await state.assignTrip(expense.id, null);
      expect(state.expensesOfTrip(trip.id), isEmpty);
    });

    test('удаление командировки сохраняет траты', () async {
      final Trip trip = await state.addTrip(
        title: 'Казань',
        startDate: DateTime(2026, 5, 10),
        endDate: DateTime(2026, 5, 20),
      );
      await state.addExpense(sample(tripId: trip.id));

      await state.deleteTrip(trip.id);

      expect(state.trips, isEmpty);
      expect(state.allExpenses, hasLength(1));
      expect(state.allExpenses.single.tripId, isNull);
    });
  });

  test('импорт CSV создаёт категории, командировки и траты', () async {
    const String content =
        '2026-05-14;1250.50;Продукты;Магнит;Карта;Продукты;\n'
        '2026-05-15;430;Подписки;Сервис;qr;Музыка;Казань\n';

    final CsvImportResult result = CsvImportService(
      idGenerator: state.newId,
    ).parse(content, categories: state.categories, trips: state.trips);

    await state.applyImport(result);

    expect(state.allExpenses, hasLength(2));
    expect(
      state.customCategories.map((ExpenseCategory c) => c.name),
      contains('Подписки'),
    );
    expect(state.trips.map((Trip t) => t.title), contains('Казань'));
    expect(
      state.allExpenses
          .firstWhere((Expense e) => e.payee == 'Сервис')
          .paymentMethod,
      equals(PaymentMethod.qr),
    );
  });
}
