// SPDX-License-Identifier: BSD-3-Clause
import 'package:expense_tracker/data/models/expense.dart';
import 'package:expense_tracker/data/models/expense_filter.dart';
import 'package:expense_tracker/data/models/payment_method.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final Expense groceries = Expense(
    id: 'e1',
    amount: 1250.5,
    categoryId: 'cat_groceries',
    date: DateTime(2026, 5, 14),
    payee: 'Магнит',
    comment: 'Продукты на неделю',
  );
  final Expense taxi = Expense(
    id: 'e2',
    amount: 380,
    categoryId: 'cat_transport',
    date: DateTime(2026, 6, 2),
    payee: 'Яндекс Такси',
    comment: 'Аэропорт',
    paymentMethod: PaymentMethod.qr,
    tripId: 'trip_1',
  );

  test('пустой фильтр пропускает всё', () {
    expect(ExpenseFilter.empty.isEmpty, isTrue);
    expect(ExpenseFilter.empty.matches(groceries), isTrue);
    expect(ExpenseFilter.empty.activeCount, equals(0));
  });

  test('фильтр по категории', () {
    const ExpenseFilter filter = ExpenseFilter(
      categoryIds: <String>{'cat_transport'},
    );
    expect(filter.matches(taxi), isTrue);
    expect(filter.matches(groceries), isFalse);
  });

  test('фильтр по выборке дат', () {
    final ExpenseFilter filter = ExpenseFilter(
      dateRange: DateRange.month(DateTime(2026, 5, 20)),
    );
    expect(filter.matches(groceries), isTrue);
    expect(filter.matches(taxi), isFalse);
  });

  test('пределы суммы', () {
    const ExpenseFilter min = ExpenseFilter(minAmount: 500);
    expect(min.matches(groceries), isTrue);
    expect(min.matches(taxi), isFalse);

    const ExpenseFilter max = ExpenseFilter(maxAmount: 500);
    expect(max.matches(groceries), isFalse);
    expect(max.matches(taxi), isTrue);
  });

  test('фильтр по способу оплаты', () {
    const ExpenseFilter filter = ExpenseFilter(
      paymentMethods: <PaymentMethod>{PaymentMethod.qr},
    );
    expect(filter.matches(taxi), isTrue);
    expect(filter.matches(groceries), isFalse);
  });

  test('фильтр по командировке и её отсутствию', () {
    const ExpenseFilter inTrip = ExpenseFilter(tripId: 'trip_1');
    expect(inTrip.matches(taxi), isTrue);
    expect(inTrip.matches(groceries), isFalse);

    const ExpenseFilter withoutTrip = ExpenseFilter(withoutTrip: true);
    expect(withoutTrip.matches(groceries), isTrue);
    expect(withoutTrip.matches(taxi), isFalse);
  });

  test('поиск по комментарию и получателю без учёта регистра', () {
    expect(const ExpenseFilter(query: 'магнит').matches(groceries), isTrue);
    expect(const ExpenseFilter(query: 'НЕДЕЛЮ').matches(groceries), isTrue);
    expect(const ExpenseFilter(query: 'такси').matches(groceries), isFalse);
  });

  test('комбинация условий применяется целиком', () {
    final ExpenseFilter filter = ExpenseFilter(
      categoryIds: const <String>{'cat_transport'},
      dateRange: DateRange(DateTime(2026, 6), DateTime(2026, 6, 30)),
      minAmount: 100,
      maxAmount: 1000,
      paymentMethods: const <PaymentMethod>{PaymentMethod.qr},
      tripId: 'trip_1',
      query: 'аэропорт',
    );

    expect(filter.matches(taxi), isTrue);
    expect(filter.matches(groceries), isFalse);
    expect(filter.activeCount, equals(6));
    expect(filter.isEmpty, isFalse);
  });

  test('копия фильтра умеет очищать отдельные условия', () {
    const ExpenseFilter filter = ExpenseFilter(minAmount: 100, tripId: 't');
    final ExpenseFilter cleared = filter.copyWith(
      clearMinAmount: true,
      clearTrip: true,
    );

    expect(cleared.minAmount, isNull);
    expect(cleared.tripId, isNull);
    expect(cleared.isEmpty, isTrue);
  });
}
