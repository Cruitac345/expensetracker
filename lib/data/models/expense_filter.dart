// SPDX-License-Identifier: BSD-3-Clause
import 'package:flutter/foundation.dart';

import 'expense.dart';
import 'payment_method.dart';

/// Диапазон дат выборки.
@immutable
class DateRange {
  const DateRange(this.start, this.end);

  /// Диапазон, охватывающий месяц указанной даты.
  factory DateRange.month(DateTime date) => DateRange(
    DateTime(date.year, date.month),
    DateTime(date.year, date.month + 1).subtract(const Duration(days: 1)),
  );

  /// Диапазон, охватывающий год указанной даты.
  factory DateRange.year(DateTime date) =>
      DateRange(DateTime(date.year), DateTime(date.year, 12, 31));

  /// Последние [months] месяцев, включая текущий.
  factory DateRange.lastMonths(DateTime now, int months) => DateRange(
    DateTime(now.year, now.month - (months - 1)),
    DateTime(now.year, now.month + 1).subtract(const Duration(days: 1)),
  );

  final DateTime start;
  final DateTime end;

  bool contains(DateTime date) {
    final DateTime day = DateTime(date.year, date.month, date.day);
    return !day.isBefore(DateTime(start.year, start.month, start.day)) &&
        !day.isAfter(DateTime(end.year, end.month, end.day));
  }

  @override
  bool operator ==(Object other) =>
      other is DateRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);
}

/// Фильтр списка трат.
///
/// Техническое задание требует фильтрации по категории, дате или выборке дат,
/// сумме (больше или меньше предела), способу оплаты, командировке и любой
/// комбинации перечисленного, а также поиска по комментарию и получателю.
@immutable
class ExpenseFilter {
  const ExpenseFilter({
    this.categoryIds = const <String>{},
    this.dateRange,
    this.minAmount,
    this.maxAmount,
    this.paymentMethods = const <PaymentMethod>{},
    this.tripId,
    this.withoutTrip = false,
    this.query = '',
  });

  /// Категории (пустое множество — без ограничения).
  final Set<String> categoryIds;

  /// Дата или выборка дат.
  final DateRange? dateRange;

  /// Нижний предел суммы: трата не меньше значения.
  final double? minAmount;

  /// Верхний предел суммы: трата не больше значения.
  final double? maxAmount;

  /// Способы оплаты (пустое множество — без ограничения).
  final Set<PaymentMethod> paymentMethods;

  /// Конкретная командировка.
  final String? tripId;

  /// Только траты вне командировок.
  final bool withoutTrip;

  /// Поиск по комментарию и получателю платежа.
  final String query;

  static const ExpenseFilter empty = ExpenseFilter();

  bool get isEmpty =>
      categoryIds.isEmpty &&
      dateRange == null &&
      minAmount == null &&
      maxAmount == null &&
      paymentMethods.isEmpty &&
      tripId == null &&
      !withoutTrip &&
      query.trim().isEmpty;

  /// Количество активных условий — выводится значком у кнопки фильтров.
  int get activeCount {
    int count = 0;
    if (categoryIds.isNotEmpty) {
      count++;
    }
    if (dateRange != null) {
      count++;
    }
    if (minAmount != null || maxAmount != null) {
      count++;
    }
    if (paymentMethods.isNotEmpty) {
      count++;
    }
    if (tripId != null || withoutTrip) {
      count++;
    }
    if (query.trim().isNotEmpty) {
      count++;
    }
    return count;
  }

  /// Проверка траты на соответствие всем условиям фильтра.
  bool matches(Expense expense) {
    if (categoryIds.isNotEmpty && !categoryIds.contains(expense.categoryId)) {
      return false;
    }
    if (dateRange != null && !dateRange!.contains(expense.date)) {
      return false;
    }
    if (minAmount != null && expense.amount < minAmount!) {
      return false;
    }
    if (maxAmount != null && expense.amount > maxAmount!) {
      return false;
    }
    if (paymentMethods.isNotEmpty &&
        !paymentMethods.contains(expense.paymentMethod)) {
      return false;
    }
    if (withoutTrip && expense.tripId != null) {
      return false;
    }
    if (tripId != null && expense.tripId != tripId) {
      return false;
    }
    final String needle = query.trim().toLowerCase();
    if (needle.isNotEmpty) {
      final bool inComment = expense.comment.toLowerCase().contains(needle);
      final bool inPayee = expense.payee.toLowerCase().contains(needle);
      if (!inComment && !inPayee) {
        return false;
      }
    }
    return true;
  }

  ExpenseFilter copyWith({
    Set<String>? categoryIds,
    DateRange? dateRange,
    bool clearDateRange = false,
    double? minAmount,
    bool clearMinAmount = false,
    double? maxAmount,
    bool clearMaxAmount = false,
    Set<PaymentMethod>? paymentMethods,
    String? tripId,
    bool clearTrip = false,
    bool? withoutTrip,
    String? query,
  }) => ExpenseFilter(
    categoryIds: categoryIds ?? this.categoryIds,
    dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
    minAmount: clearMinAmount ? null : (minAmount ?? this.minAmount),
    maxAmount: clearMaxAmount ? null : (maxAmount ?? this.maxAmount),
    paymentMethods: paymentMethods ?? this.paymentMethods,
    tripId: clearTrip ? null : (tripId ?? this.tripId),
    withoutTrip: withoutTrip ?? this.withoutTrip,
    query: query ?? this.query,
  );

  @override
  bool operator ==(Object other) =>
      other is ExpenseFilter &&
      setEquals(other.categoryIds, categoryIds) &&
      other.dateRange == dateRange &&
      other.minAmount == minAmount &&
      other.maxAmount == maxAmount &&
      setEquals(other.paymentMethods, paymentMethods) &&
      other.tripId == tripId &&
      other.withoutTrip == withoutTrip &&
      other.query == query;

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(categoryIds),
    dateRange,
    minAmount,
    maxAmount,
    Object.hashAllUnordered(paymentMethods),
    tripId,
    withoutTrip,
    query,
  );
}

/// Порядок сортировки списка трат.
enum ExpenseSort {
  dateDesc('Сначала новые'),
  dateAsc('Сначала старые'),
  amountDesc('Сумма по убыванию'),
  amountAsc('Сумма по возрастанию');

  const ExpenseSort(this.label);

  final String label;
}
