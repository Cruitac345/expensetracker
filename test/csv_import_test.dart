// SPDX-License-Identifier: BSD-3-Clause
import 'dart:convert';
import 'dart:typed_data';

import 'package:expense_tracker/data/models/expense.dart';
import 'package:expense_tracker/data/models/expense_category.dart';
import 'package:expense_tracker/data/models/payment_method.dart';
import 'package:expense_tracker/data/models/trip.dart';
import 'package:expense_tracker/data/services/csv_import_service.dart';
import 'package:expense_tracker/data/services/text_decoder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  int counter = 0;
  String nextId() => 'id_${counter++}';

  CsvImportService service() {
    counter = 0;
    return CsvImportService(idGenerator: nextId);
  }

  group('Определение разделителя', () {
    test('точка с запятой', () {
      expect(
        CsvImportService.detectDelimiter('2026-05-14;100;Кафе'),
        equals(';'),
      );
    });

    test('вертикальная черта из формата технического задания', () {
      expect(
        CsvImportService.detectDelimiter('2026-05-14|100|Кафе|Кофейня'),
        equals('|'),
      );
    });

    test('запятая', () {
      expect(
        CsvImportService.detectDelimiter('2026-05-14,100,Кафе,Кофейня'),
        equals(','),
      );
    });
  });

  group('Разбор дат и сумм', () {
    test('дата в формате ISO 8601', () {
      expect(
        CsvImportService.parseDate('2026-05-14T10:20:00'),
        equals(DateTime.parse('2026-05-14T10:20:00')),
      );
    });

    test('дата в привычном формате dd.MM.yyyy', () {
      expect(
        CsvImportService.parseDate('14.05.2026'),
        equals(DateTime(2026, 5, 14)),
      );
    });

    test('некорректная дата не разбирается', () {
      expect(CsvImportService.parseDate('не дата'), isNull);
    });

    test('сумма с запятой и разделителем разрядов', () {
      expect(CsvImportService.parseAmount('1 234,50'), equals(1234.5));
      expect(CsvImportService.parseAmount('1234.50'), equals(1234.5));
      expect(CsvImportService.parseAmount('1.234,50'), equals(1234.5));
      expect(CsvImportService.parseAmount('1250.50 ₽'), equals(1250.5));
    });
  });

  group('Импорт файла', () {
    test('разбирает файл формата технического задания', () {
      const String content =
          'Дата;Сумма;Категория;Получатель;Способ оплаты;Комментарий;Командировка\n'
          '2026-05-14T10:20:00;1250.50;Продукты;Магнит;Карта;Продукты на неделю;\n'
          '2026-05-15;430;Кафе;Кофейня;qr-code;Обед;Казань, конференция\n';

      final CsvImportResult result = service().parse(
        content,
        categories: ExpenseCategory.defaults,
        trips: const <Trip>[],
      );

      expect(result.issues, isEmpty);
      expect(result.expenses, hasLength(2));
      expect(result.totalRows, equals(2));

      final Expense first = result.expenses.first;
      expect(first.amount, equals(1250.5));
      expect(first.payee, equals('Магнит'));
      expect(first.paymentMethod, equals(PaymentMethod.card));
      expect(first.comment, equals('Продукты на неделю'));
      expect(first.tripId, isNull);
      expect(first.categoryId, equals('cat_groceries'));

      final Expense second = result.expenses.last;
      expect(second.paymentMethod, equals(PaymentMethod.qr));
      expect(second.categoryId, equals('cat_cafe'));
      expect(second.tripId, isNotNull);

      expect(result.newTrips, hasLength(1));
      expect(result.newTrips.single.title, equals('Казань, конференция'));
    });

    test('создаёт неизвестную категорию', () {
      const String content = '2026-05-14;500;Подписки;Сервис;Карта;;';

      final CsvImportResult result = service().parse(
        content,
        categories: ExpenseCategory.defaults,
        trips: const <Trip>[],
      );

      expect(result.newCategories, hasLength(1));
      expect(result.newCategories.single.name, equals('Подписки'));
      expect(result.newCategories.single.isBuiltIn, isFalse);
      expect(
        result.expenses.single.categoryId,
        equals(result.newCategories.single.id),
      );
    });

    test('расширяет период создаваемой командировки по датам трат', () {
      const String content =
          '2026-05-14;500;Транспорт;РЖД;Карта;Билет;Сочи\n'
          '2026-05-18;300;Кафе;Кафе у моря;Наличные;Ужин;Сочи\n';

      final CsvImportResult result = service().parse(
        content,
        categories: ExpenseCategory.defaults,
        trips: const <Trip>[],
      );

      expect(result.newTrips, hasLength(1));
      final Trip trip = result.newTrips.single;
      expect(trip.startDate, equals(DateTime(2026, 5, 14)));
      expect(trip.endDate, equals(DateTime(2026, 5, 18)));
      expect(
        result.expenses.every((Expense expense) => expense.tripId == trip.id),
        isTrue,
      );
    });

    test('сообщает о некорректных строках и пропускает их', () {
      const String content =
          '2026-05-14;500;Кафе;;Карта;;\n'
          'не дата;500;Кафе;;Карта;;\n'
          '2026-05-16;ноль;Кафе;;Карта;;\n'
          '2026-05-17;-100;Кафе;;Карта;;\n';

      final CsvImportResult result = service().parse(
        content,
        categories: ExpenseCategory.defaults,
        trips: const <Trip>[],
      );

      expect(result.expenses, hasLength(1));
      expect(result.issues, hasLength(3));
      expect(result.issues.first.line, equals(2));
    });

    test('привязывает траты к существующей командировке по названию', () {
      final Trip existing = Trip(
        id: 'trip_1',
        title: 'Казань',
        startDate: DateTime(2026, 5, 1),
        endDate: DateTime(2026, 5, 30),
      );

      final CsvImportResult result = service().parse(
        '2026-05-14;500;Кафе;;Карта;;казань',
        categories: ExpenseCategory.defaults,
        trips: <Trip>[existing],
      );

      expect(result.newTrips, isEmpty);
      expect(result.expenses.single.tripId, equals('trip_1'));
    });
  });

  group('Экспорт', () {
    test('файл экспорта читается обратно без потерь', () {
      final Trip trip = Trip(
        id: 'trip_1',
        title: 'Казань',
        startDate: DateTime(2026, 5, 1),
        endDate: DateTime(2026, 5, 30),
      );
      final Expense expense = Expense(
        id: 'e1',
        amount: 1250.5,
        categoryId: 'cat_cafe',
        date: DateTime(2026, 5, 14),
        payee: 'Кофейня «Сити»',
        comment: 'Обед; с коллегой',
        paymentMethod: PaymentMethod.qr,
        tripId: trip.id,
      );

      final String content = CsvImportService.export(
        expenses: <Expense>[expense],
        categories: <String, ExpenseCategory>{
          'cat_cafe': ExpenseCategory.defaults[1],
        },
        trips: <String, Trip>{trip.id: trip},
      );

      final CsvImportResult result = service().parse(
        content,
        categories: ExpenseCategory.defaults,
        trips: <Trip>[trip],
      );

      expect(result.issues, isEmpty);
      final Expense restored = result.expenses.single;
      expect(restored.amount, equals(expense.amount));
      expect(restored.payee, equals(expense.payee));
      expect(restored.comment, equals(expense.comment));
      expect(restored.paymentMethod, equals(expense.paymentMethod));
      expect(restored.tripId, equals(trip.id));
    });
  });

  group('Кодировка файла', () {
    test('UTF-8 с меткой порядка байтов', () {
      final List<int> bytes = <int>[
        0xEF,
        0xBB,
        0xBF,
        ...utf8.encode('Кафе'),
      ];
      expect(
        TextDecoder.decode(Uint8List.fromList(bytes)),
        equals('Кафе'),
      );
    });

    test('Windows-1251', () {
      // «Кафе» в кодировке Windows-1251.
      final Uint8List bytes = Uint8List.fromList(<int>[0xCA, 0xE0, 0xF4, 0xE5]);
      expect(TextDecoder.decode(bytes), equals('Кафе'));
    });
  });
}
