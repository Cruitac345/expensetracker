// SPDX-License-Identifier: BSD-3-Clause
import '../models/expense.dart';
import '../models/expense_category.dart';
import '../models/trip.dart';
import '../store/json_store.dart';

/// Репозиторий трат.
class ExpenseRepository {
  ExpenseRepository(this._store);

  static const String collection = 'expenses';

  final JsonStore _store;

  Future<List<Expense>> loadAll() async {
    final List<Map<String, dynamic>> rows = await _store.read(collection);
    return rows.map(Expense.fromJson).toList();
  }

  Future<void> saveAll(List<Expense> expenses) => _store.write(
    collection,
    expenses.map((Expense expense) => expense.toJson()).toList(growable: false),
  );
}

/// Репозиторий категорий. При первом запуске заполняется стандартными.
class CategoryRepository {
  CategoryRepository(this._store);

  static const String collection = 'categories';

  final JsonStore _store;

  Future<List<ExpenseCategory>> loadAll() async {
    final List<Map<String, dynamic>> rows = await _store.read(collection);
    if (rows.isEmpty) {
      final List<ExpenseCategory> defaults = List<ExpenseCategory>.from(
        ExpenseCategory.defaults,
      );
      await saveAll(defaults);
      return defaults;
    }
    return rows.map(ExpenseCategory.fromJson).toList();
  }

  Future<void> saveAll(List<ExpenseCategory> categories) => _store.write(
    collection,
    categories
        .map((ExpenseCategory category) => category.toJson())
        .toList(growable: false),
  );
}

/// Репозиторий командировок.
class TripRepository {
  TripRepository(this._store);

  static const String collection = 'trips';

  final JsonStore _store;

  Future<List<Trip>> loadAll() async {
    final List<Map<String, dynamic>> rows = await _store.read(collection);
    return rows.map(Trip.fromJson).toList();
  }

  Future<void> saveAll(List<Trip> trips) => _store.write(
    collection,
    trips.map((Trip trip) => trip.toJson()).toList(growable: false),
  );
}
