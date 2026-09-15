// SPDX-License-Identifier: BSD-3-Clause
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../data/models/expense.dart';
import '../data/models/expense_category.dart';
import '../data/models/expense_filter.dart';
import '../data/models/trip.dart';
import '../data/repositories/repositories.dart';
import '../data/services/csv_import_service.dart';
import '../data/services/receipt_storage.dart';
import '../data/store/json_store.dart';

/// Состояние приложения: траты, категории, командировки и активный фильтр.
///
/// Данные целиком держатся в памяти и синхронно отражаются в локальном
/// хранилище после каждой операции — объём личной бухгалтерии это позволяет,
/// а интерфейс получает мгновенный отклик.
class AppState extends ChangeNotifier {
  AppState({
    required ExpenseRepository expenseRepository,
    required CategoryRepository categoryRepository,
    required TripRepository tripRepository,
    required ReceiptStorage receiptStorage,
    required JsonStore store,
    Uuid? uuid,
  }) : _expenseRepository = expenseRepository,
       _categoryRepository = categoryRepository,
       _tripRepository = tripRepository,
       _receiptStorage = receiptStorage,
       _store = store,
       _uuid = uuid ?? const Uuid();

  final ExpenseRepository _expenseRepository;
  final CategoryRepository _categoryRepository;
  final TripRepository _tripRepository;
  final ReceiptStorage _receiptStorage;
  final JsonStore _store;
  final Uuid _uuid;

  List<Expense> _expenses = <Expense>[];
  List<ExpenseCategory> _categories = <ExpenseCategory>[];
  List<Trip> _trips = <Trip>[];

  ExpenseFilter _filter = ExpenseFilter.empty;
  ExpenseSort _sort = ExpenseSort.dateDesc;
  bool _isLoading = true;

  ReceiptStorage get receiptStorage => _receiptStorage;

  bool get isLoading => _isLoading;

  ExpenseFilter get filter => _filter;

  ExpenseSort get sort => _sort;

  /// Все траты, отсортированные по текущему порядку.
  List<Expense> get allExpenses => _sorted(_expenses);

  /// Траты, прошедшие текущий фильтр и поиск.
  List<Expense> get visibleExpenses =>
      _sorted(_expenses.where(_filter.matches).toList());

  List<ExpenseCategory> get categories =>
      List<ExpenseCategory>.unmodifiable(_categories);

  List<ExpenseCategory> get customCategories => _categories
      .where((ExpenseCategory category) => !category.isBuiltIn)
      .toList(growable: false);

  List<Trip> get trips {
    final List<Trip> sorted = List<Trip>.from(_trips)
      ..sort((Trip a, Trip b) => b.startDate.compareTo(a.startDate));
    return List<Trip>.unmodifiable(sorted);
  }

  Map<String, ExpenseCategory> get categoryIndex => <String, ExpenseCategory>{
    for (final ExpenseCategory category in _categories) category.id: category,
  };

  Map<String, Trip> get tripIndex => <String, Trip>{
    for (final Trip trip in _trips) trip.id: trip,
  };

  ExpenseCategory? categoryById(String? id) =>
      _categories.cast<ExpenseCategory?>().firstWhere(
        (ExpenseCategory? category) => category?.id == id,
        orElse: () => null,
      );

  Trip? tripById(String? id) => _trips.cast<Trip?>().firstWhere(
    (Trip? trip) => trip?.id == id,
    orElse: () => null,
  );

  List<Expense> expensesOfCategory(String categoryId) => _sorted(
    _expenses
        .where((Expense expense) => expense.categoryId == categoryId)
        .toList(),
  );

  List<Expense> expensesOfTrip(String tripId) => _sorted(
    _expenses.where((Expense expense) => expense.tripId == tripId).toList(),
  );

  /// Загрузка данных из локального хранилища.
  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    _categories = await _categoryRepository.loadAll();
    _trips = await _tripRepository.loadAll();
    _expenses = await _expenseRepository.loadAll();

    _isLoading = false;
    notifyListeners();
  }

  String newId() => _uuid.v4();

  // --- Фильтрация и сортировка ---------------------------------------------

  void applyFilter(ExpenseFilter filter) {
    _filter = filter;
    notifyListeners();
  }

  void updateQuery(String query) {
    _filter = _filter.copyWith(query: query);
    notifyListeners();
  }

  void resetFilter() {
    _filter = ExpenseFilter.empty;
    notifyListeners();
  }

  void changeSort(ExpenseSort sort) {
    _sort = sort;
    notifyListeners();
  }

  List<Expense> _sorted(List<Expense> source) {
    final List<Expense> result = List<Expense>.from(source);
    switch (_sort) {
      case ExpenseSort.dateDesc:
        result.sort((Expense a, Expense b) => b.date.compareTo(a.date));
      case ExpenseSort.dateAsc:
        result.sort((Expense a, Expense b) => a.date.compareTo(b.date));
      case ExpenseSort.amountDesc:
        result.sort((Expense a, Expense b) => b.amount.compareTo(a.amount));
      case ExpenseSort.amountAsc:
        result.sort((Expense a, Expense b) => a.amount.compareTo(b.amount));
    }
    return result;
  }

  // --- Траты ----------------------------------------------------------------

  Future<void> addExpense(Expense expense) async {
    _expenses = <Expense>[..._expenses, expense];
    await _expenseRepository.saveAll(_expenses);
    notifyListeners();
  }

  Future<void> updateExpense(Expense expense) async {
    _expenses = _expenses
        .map((Expense item) => item.id == expense.id ? expense : item)
        .toList();
    await _expenseRepository.saveAll(_expenses);
    notifyListeners();
  }

  /// Удаляет трату вместе с прикреплёнными чеками.
  Future<void> deleteExpense(String id) async {
    final Expense? expense = _expenses.cast<Expense?>().firstWhere(
      (Expense? item) => item?.id == id,
      orElse: () => null,
    );
    if (expense == null) {
      return;
    }
    await _receiptStorage.removeAll(expense.receiptPaths);
    _expenses = _expenses.where((Expense item) => item.id != id).toList();
    await _expenseRepository.saveAll(_expenses);
    notifyListeners();
  }

  /// Копирует файл чека в данные приложения и возвращает относительный путь.
  Future<String> storeReceipt(String sourcePath) =>
      _receiptStorage.add(sourcePath);

  Future<void> removeReceiptFile(String relativePath) =>
      _receiptStorage.remove(relativePath);

  // --- Категории ------------------------------------------------------------

  Future<ExpenseCategory> addCategory({
    required String name,
    required String iconKey,
    required int colorIndex,
  }) async {
    final ExpenseCategory category = ExpenseCategory(
      id: newId(),
      name: name,
      iconKey: iconKey,
      colorIndex: colorIndex,
    );
    _categories = <ExpenseCategory>[..._categories, category];
    await _categoryRepository.saveAll(_categories);
    notifyListeners();
    return category;
  }

  Future<void> updateCategory(ExpenseCategory category) async {
    _categories = _categories
        .map((ExpenseCategory item) => item.id == category.id ? category : item)
        .toList();
    await _categoryRepository.saveAll(_categories);
    notifyListeners();
  }

  /// Число трат в категории — используется при удалении категории.
  int expenseCountOfCategory(String categoryId) => _expenses
      .where((Expense expense) => expense.categoryId == categoryId)
      .length;

  /// Удаляет пользовательскую категорию.
  ///
  /// Траты удалённой категории переносятся в [replacementId], если он задан,
  /// иначе удаляются вместе с категорией.
  Future<void> deleteCategory(String id, {String? replacementId}) async {
    final ExpenseCategory? category = categoryById(id);
    if (category == null || category.isBuiltIn) {
      return;
    }

    if (replacementId != null) {
      _expenses = _expenses
          .map(
            (Expense expense) => expense.categoryId == id
                ? expense.copyWith(categoryId: replacementId)
                : expense,
          )
          .toList();
    } else {
      final List<Expense> removed = _expenses
          .where((Expense expense) => expense.categoryId == id)
          .toList();
      for (final Expense expense in removed) {
        await _receiptStorage.removeAll(expense.receiptPaths);
      }
      _expenses = _expenses
          .where((Expense expense) => expense.categoryId != id)
          .toList();
    }

    _categories = _categories
        .where((ExpenseCategory item) => item.id != id)
        .toList();

    if (_filter.categoryIds.contains(id)) {
      _filter = _filter.copyWith(
        categoryIds: _filter.categoryIds
            .where((String value) => value != id)
            .toSet(),
      );
    }

    await _expenseRepository.saveAll(_expenses);
    await _categoryRepository.saveAll(_categories);
    notifyListeners();
  }

  // --- Командировки ---------------------------------------------------------

  Future<Trip> addTrip({
    required String title,
    required DateTime startDate,
    required DateTime endDate,
    String destination = '',
    String note = '',
  }) async {
    final Trip trip = Trip(
      id: newId(),
      title: title,
      startDate: startDate,
      endDate: endDate,
      destination: destination,
      note: note,
    );
    _trips = <Trip>[..._trips, trip];
    await _tripRepository.saveAll(_trips);
    notifyListeners();
    return trip;
  }

  Future<void> updateTrip(Trip trip) async {
    _trips = _trips
        .map((Trip item) => item.id == trip.id ? trip : item)
        .toList();
    await _tripRepository.saveAll(_trips);
    notifyListeners();
  }

  /// Удаляет командировку. Траты сохраняются, но открепляются от неё.
  Future<void> deleteTrip(String id) async {
    _trips = _trips.where((Trip trip) => trip.id != id).toList();
    _expenses = _expenses
        .map(
          (Expense expense) => expense.tripId == id
              ? expense.copyWith(clearTrip: true)
              : expense,
        )
        .toList();
    if (_filter.tripId == id) {
      _filter = _filter.copyWith(clearTrip: true);
    }
    await _tripRepository.saveAll(_trips);
    await _expenseRepository.saveAll(_expenses);
    notifyListeners();
  }

  /// Прикрепляет трату к командировке или открепляет её.
  Future<void> assignTrip(String expenseId, String? tripId) async {
    _expenses = _expenses.map((Expense expense) {
      if (expense.id != expenseId) {
        return expense;
      }
      return tripId == null
          ? expense.copyWith(clearTrip: true)
          : expense.copyWith(tripId: tripId);
    }).toList();
    await _expenseRepository.saveAll(_expenses);
    notifyListeners();
  }

  /// Выгружает все траты в CSV-файл формата технического задания и
  /// возвращает путь к созданному файлу.
  Future<String> exportCsv() async {
    final Directory directory = await _store.dataDirectory();
    final String content = CsvImportService.export(
      expenses: allExpenses,
      categories: categoryIndex,
      trips: tripIndex,
    );
    final File file = File(
      p.join(
        directory.path,
        'expenses_${DateTime.now().toIso8601String().substring(0, 10)}.csv',
      ),
    );
    await file.writeAsString(content, encoding: utf8, flush: true);
    return file.path;
  }

  // --- Импорт ---------------------------------------------------------------

  /// Применяет результат разбора CSV: создаёт новые категории, командировки
  /// и добавляет траты.
  Future<void> applyImport(CsvImportResult result) async {
    if (result.newCategories.isNotEmpty) {
      _categories = <ExpenseCategory>[..._categories, ...result.newCategories];
      await _categoryRepository.saveAll(_categories);
    }
    if (result.newTrips.isNotEmpty) {
      _trips = <Trip>[..._trips, ...result.newTrips];
      await _tripRepository.saveAll(_trips);
    }
    if (result.expenses.isNotEmpty) {
      _expenses = <Expense>[..._expenses, ...result.expenses];
      await _expenseRepository.saveAll(_expenses);
    }
    notifyListeners();
  }
}
