// SPDX-License-Identifier: BSD-3-Clause
import 'package:expense_tracker/data/models/expense.dart';
import 'package:expense_tracker/data/models/expense_filter.dart';
import 'package:expense_tracker/data/models/payment_method.dart';
import 'package:expense_tracker/data/services/analytics.dart';
import 'package:flutter_test/flutter_test.dart';

Expense expense({
  required double amount,
  required DateTime date,
  String categoryId = 'cat_cafe',
  String? tripId,
  PaymentMethod method = PaymentMethod.card,
}) => Expense(
  id: '$categoryId-${date.toIso8601String()}-$amount',
  amount: amount,
  categoryId: categoryId,
  date: date,
  tripId: tripId,
  paymentMethod: method,
);

void main() {
  final List<Expense> sample = <Expense>[
    expense(amount: 100, date: DateTime(2026, 1, 10)),
    expense(amount: 300, date: DateTime(2026, 1, 20), categoryId: 'cat_food'),
    expense(amount: 600, date: DateTime(2026, 3, 5), tripId: 'trip_1'),
  ];

  group('Суммы по месяцам', () {
    test('заполняет месяцы без трат нулями', () {
      final List<MonthTotal> totals = ExpenseAnalytics.byMonth(sample);

      expect(totals, hasLength(3));
      expect(totals[0].month, equals(DateTime(2026)));
      expect(totals[0].total, equals(400));
      expect(totals[1].month, equals(DateTime(2026, 2)));
      expect(totals[1].total, equals(0));
      expect(totals[1].count, equals(0));
      expect(totals[2].total, equals(600));
    });

    test('учитывает границы заданного периода', () {
      final List<MonthTotal> totals = ExpenseAnalytics.byMonth(
        sample,
        range: DateRange(DateTime(2025, 12), DateTime(2026, 4, 30)),
      );

      expect(totals, hasLength(5));
      expect(totals.first.month, equals(DateTime(2025, 12)));
      expect(totals.last.month, equals(DateTime(2026, 4)));
    });

    test('пустой список без периода даёт пустой результат', () {
      expect(ExpenseAnalytics.byMonth(const <Expense>[]), isEmpty);
    });
  });

  group('Суммы по категориям', () {
    test('сортируются по убыванию и содержат долю', () {
      final List<CategoryTotal> totals = ExpenseAnalytics.byCategory(sample);

      expect(totals, hasLength(2));
      expect(totals.first.categoryId, equals('cat_cafe'));
      expect(totals.first.total, equals(700));
      expect(totals.first.count, equals(2));
      expect(totals.first.share, closeTo(0.7, 0.0001));
      expect(totals.last.share, closeTo(0.3, 0.0001));
    });
  });

  group('Суммы по командировкам', () {
    test('траты вне командировок идут последними', () {
      final List<TripTotal> totals = ExpenseAnalytics.byTrip(sample);

      expect(totals, hasLength(2));
      expect(totals.first.tripId, equals('trip_1'));
      expect(totals.first.total, equals(600));
      expect(totals.last.tripId, isNull);
      expect(totals.last.total, equals(400));
    });
  });

  test('способы оплаты суммируются', () {
    final List<Expense> expenses = <Expense>[
      expense(amount: 100, date: DateTime(2026, 1, 10)),
      expense(
        amount: 50,
        date: DateTime(2026, 1, 11),
        method: PaymentMethod.cash,
      ),
      expense(
        amount: 25,
        date: DateTime(2026, 1, 12),
        method: PaymentMethod.cash,
      ),
    ];

    final Map<PaymentMethod, double> totals = ExpenseAnalytics.byPaymentMethod(
      expenses,
    );

    expect(totals[PaymentMethod.card], equals(100));
    expect(totals[PaymentMethod.cash], equals(75));
    expect(totals[PaymentMethod.qr], isNull);
  });

  test('средняя и наибольшая траты', () {
    expect(ExpenseAnalytics.total(sample), equals(1000));
    expect(ExpenseAnalytics.average(sample), closeTo(333.33, 0.01));
    expect(ExpenseAnalytics.largest(sample)?.amount, equals(600));
    expect(ExpenseAnalytics.average(const <Expense>[]), equals(0));
    expect(ExpenseAnalytics.largest(const <Expense>[]), isNull);
  });
}
