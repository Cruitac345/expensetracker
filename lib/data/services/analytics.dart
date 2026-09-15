// SPDX-License-Identifier: BSD-3-Clause
import 'package:flutter/foundation.dart';

import '../models/expense.dart';
import '../models/expense_filter.dart';
import '../models/payment_method.dart';

/// Сумма трат за месяц.
@immutable
class MonthTotal {
  const MonthTotal({
    required this.month,
    required this.total,
    required this.count,
  });

  final DateTime month;
  final double total;
  final int count;
}

/// Сумма трат по категории.
@immutable
class CategoryTotal {
  const CategoryTotal({
    required this.categoryId,
    required this.total,
    required this.count,
    required this.share,
  });

  final String categoryId;
  final double total;
  final int count;

  /// Доля в общей сумме выборки, 0…1.
  final double share;
}

/// Сумма трат по командировке. `tripId == null` — траты вне командировок.
@immutable
class TripTotal {
  const TripTotal({
    required this.tripId,
    required this.total,
    required this.count,
  });

  final String? tripId;
  final double total;
  final int count;
}

/// Агрегация трат для дашборда.
///
/// Все расчёты — чистые функции над списком трат, поэтому покрываются
/// модульными тестами без участия интерфейса и хранилища.
class ExpenseAnalytics {
  const ExpenseAnalytics._();

  static double total(Iterable<Expense> expenses) => expenses.fold<double>(
    0,
    (double sum, Expense expense) => sum + expense.amount,
  );

  /// Распределение трат по месяцам. Месяцы без трат заполняются нулями,
  /// чтобы столбчатая диаграмма не имела разрывов по временной оси.
  static List<MonthTotal> byMonth(List<Expense> expenses, {DateRange? range}) {
    if (expenses.isEmpty && range == null) {
      return const <MonthTotal>[];
    }

    final Map<DateTime, List<Expense>> grouped = <DateTime, List<Expense>>{};
    for (final Expense expense in expenses) {
      grouped.putIfAbsent(expense.month, () => <Expense>[]).add(expense);
    }

    DateTime first;
    DateTime last;
    if (range != null) {
      first = DateTime(range.start.year, range.start.month);
      last = DateTime(range.end.year, range.end.month);
    } else {
      final List<DateTime> months = grouped.keys.toList()..sort();
      first = months.first;
      last = months.last;
    }

    final List<MonthTotal> result = <MonthTotal>[];
    DateTime cursor = first;
    while (!cursor.isAfter(last)) {
      final List<Expense> monthly = grouped[cursor] ?? const <Expense>[];
      result.add(
        MonthTotal(month: cursor, total: total(monthly), count: monthly.length),
      );
      cursor = DateTime(cursor.year, cursor.month + 1);
    }
    return result;
  }

  /// Распределение трат по категориям, отсортированное по убыванию суммы.
  static List<CategoryTotal> byCategory(List<Expense> expenses) {
    final double sum = total(expenses);
    final Map<String, List<Expense>> grouped = <String, List<Expense>>{};
    for (final Expense expense in expenses) {
      grouped.putIfAbsent(expense.categoryId, () => <Expense>[]).add(expense);
    }

    final List<CategoryTotal> result = grouped.entries.map((
      MapEntry<String, List<Expense>> entry,
    ) {
      final double categorySum = total(entry.value);
      return CategoryTotal(
        categoryId: entry.key,
        total: categorySum,
        count: entry.value.length,
        share: sum == 0 ? 0 : categorySum / sum,
      );
    }).toList();

    result.sort(
      (CategoryTotal a, CategoryTotal b) => b.total.compareTo(a.total),
    );
    return result;
  }

  /// Распределение трат по командировкам, отсортированное по убыванию суммы.
  static List<TripTotal> byTrip(List<Expense> expenses) {
    final Map<String?, List<Expense>> grouped = <String?, List<Expense>>{};
    for (final Expense expense in expenses) {
      grouped.putIfAbsent(expense.tripId, () => <Expense>[]).add(expense);
    }

    final List<TripTotal> result = grouped.entries
        .map(
          (MapEntry<String?, List<Expense>> entry) => TripTotal(
            tripId: entry.key,
            total: total(entry.value),
            count: entry.value.length,
          ),
        )
        .toList();

    result.sort((TripTotal a, TripTotal b) {
      if (a.tripId == null) {
        return 1;
      }
      if (b.tripId == null) {
        return -1;
      }
      return b.total.compareTo(a.total);
    });
    return result;
  }

  /// Распределение трат по способам оплаты.
  static Map<PaymentMethod, double> byPaymentMethod(List<Expense> expenses) {
    final Map<PaymentMethod, double> result = <PaymentMethod, double>{};
    for (final Expense expense in expenses) {
      result.update(
        expense.paymentMethod,
        (double value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }
    return result;
  }

  /// Средняя трата в выборке.
  static double average(List<Expense> expenses) =>
      expenses.isEmpty ? 0 : total(expenses) / expenses.length;

  /// Наибольшая трата в выборке.
  static Expense? largest(List<Expense> expenses) {
    if (expenses.isEmpty) {
      return null;
    }
    return expenses.reduce(
      (Expense a, Expense b) => a.amount >= b.amount ? a : b,
    );
  }
}
