// SPDX-License-Identifier: BSD-3-Clause
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';

import '../models/category_icons.dart';
import '../models/expense.dart';
import '../models/expense_category.dart';
import '../models/payment_method.dart';
import '../models/trip.dart';

/// Ошибка разбора строки CSV.
@immutable
class CsvImportIssue {
  const CsvImportIssue({required this.line, required this.message});

  /// Номер строки в файле, начиная с 1.
  final int line;
  final String message;
}

/// Результат разбора файла импорта.
@immutable
class CsvImportResult {
  const CsvImportResult({
    required this.expenses,
    required this.newCategories,
    required this.newTrips,
    required this.issues,
    required this.totalRows,
    required this.delimiter,
  });

  /// Распознанные траты.
  final List<Expense> expenses;

  /// Категории, которых не было в приложении и которые будут созданы.
  final List<ExpenseCategory> newCategories;

  /// Командировки, которых не было в приложении и которые будут созданы.
  final List<Trip> newTrips;

  /// Строки, которые не удалось разобрать.
  final List<CsvImportIssue> issues;

  /// Всего строк с данными в файле.
  final int totalRows;

  /// Распознанный разделитель полей.
  final String delimiter;

  bool get isEmpty => expenses.isEmpty;
}

/// Импорт трат из локальных CSV-файлов.
///
/// Формат: `Дата (ISO8601) | Сумма (double) | Категория | Получатель |
/// Способ оплаты | Комментарий | Командировка`.
///
/// Разделитель определяется автоматически (`;`, `,`, табуляция или `|`),
/// строка заголовка распознаётся и пропускается. Неизвестные категории и
/// командировки создаются автоматически.
class CsvImportService {
  const CsvImportService({required this.idGenerator});

  /// Генератор идентификаторов для новых сущностей.
  final String Function() idGenerator;

  static const List<String> _delimiters = <String>[';', ',', '\t', '|'];

  /// Ожидаемые колонки файла.
  static const List<String> columns = <String>[
    'Дата',
    'Сумма',
    'Категория',
    'Получатель',
    'Способ оплаты',
    'Комментарий',
    'Командировка',
  ];

  /// Определяет разделитель по первой непустой строке файла.
  static String detectDelimiter(String content) {
    final String line = content
        .split(RegExp(r'\r\n|\r|\n'))
        .firstWhere(
          (String value) => value.trim().isNotEmpty,
          orElse: () => '',
        );
    String best = ';';
    int bestCount = 0;
    for (final String delimiter in _delimiters) {
      final int count = delimiter.allMatches(line).length;
      if (count > bestCount) {
        bestCount = count;
        best = delimiter;
      }
    }
    return best;
  }

  /// Разбирает содержимое CSV-файла.
  CsvImportResult parse(
    String content, {
    required List<ExpenseCategory> categories,
    required List<Trip> trips,
  }) {
    final String delimiter = detectDelimiter(content);
    final List<List<dynamic>> rows = Csv(
      fieldDelimiter: delimiter,
      autoDetect: false,
    ).decode(content);

    final List<Expense> expenses = <Expense>[];
    final List<CsvImportIssue> issues = <CsvImportIssue>[];
    final List<ExpenseCategory> newCategories = <ExpenseCategory>[];
    final List<Trip> newTrips = <Trip>[];

    final Map<String, ExpenseCategory> categoryByName =
        <String, ExpenseCategory>{
          for (final ExpenseCategory category in categories)
            category.name.toLowerCase().trim(): category,
        };
    final Map<String, Trip> tripByName = <String, Trip>{
      for (final Trip trip in trips) trip.title.toLowerCase().trim(): trip,
    };

    int dataRows = 0;
    for (int index = 0; index < rows.length; index++) {
      final int line = index + 1;
      final List<String> cells = rows[index]
          .map((dynamic cell) => (cell ?? '').toString().trim())
          .toList();

      if (cells.every((String cell) => cell.isEmpty)) {
        continue;
      }
      if (index == 0 && _looksLikeHeader(cells)) {
        continue;
      }

      dataRows++;

      if (cells.length < 3) {
        issues.add(
          CsvImportIssue(
            line: line,
            message: 'Ожидается не менее трёх колонок: дата, сумма, категория',
          ),
        );
        continue;
      }

      final DateTime? date = parseDate(cells[0]);
      if (date == null) {
        issues.add(
          CsvImportIssue(
            line: line,
            message: 'Не удалось разобрать дату «${cells[0]}»',
          ),
        );
        continue;
      }

      final double? amount = parseAmount(cells[1]);
      if (amount == null) {
        issues.add(
          CsvImportIssue(
            line: line,
            message: 'Не удалось разобрать сумму «${cells[1]}»',
          ),
        );
        continue;
      }
      if (amount <= 0) {
        issues.add(
          CsvImportIssue(line: line, message: 'Сумма должна быть больше нуля'),
        );
        continue;
      }

      final String categoryName = cells[2].isEmpty ? 'Без категории' : cells[2];
      final String categoryKey = categoryName.toLowerCase().trim();
      ExpenseCategory? category = categoryByName[categoryKey];
      if (category == null) {
        category = ExpenseCategory(
          id: idGenerator(),
          name: categoryName,
          iconKey: CategoryIcons.fallbackKey,
          colorIndex: categories.length + newCategories.length,
        );
        categoryByName[categoryKey] = category;
        newCategories.add(category);
      }

      final String payee = cells.length > 3 ? cells[3] : '';
      final PaymentMethod method = PaymentMethod.parse(
        cells.length > 4 ? cells[4] : '',
      );
      final String comment = cells.length > 5 ? cells[5] : '';
      final String tripName = cells.length > 6 ? cells[6] : '';

      String? tripId;
      if (tripName.isNotEmpty) {
        final String tripKey = tripName.toLowerCase().trim();
        Trip? trip = tripByName[tripKey];
        if (trip == null) {
          trip = Trip(
            id: idGenerator(),
            title: tripName,
            startDate: date,
            endDate: date,
          );
          tripByName[tripKey] = trip;
          newTrips.add(trip);
        } else if (newTrips.contains(trip)) {
          // Расширяем период создаваемой командировки по датам её трат.
          final Trip updated = trip.copyWith(
            startDate: date.isBefore(trip.startDate) ? date : trip.startDate,
            endDate: date.isAfter(trip.endDate) ? date : trip.endDate,
          );
          newTrips[newTrips.indexOf(trip)] = updated;
          tripByName[tripKey] = updated;
          trip = updated;
        }
        tripId = trip.id;
      }

      expenses.add(
        Expense(
          id: idGenerator(),
          amount: amount,
          categoryId: category.id,
          date: date,
          payee: payee,
          comment: comment,
          paymentMethod: method,
          tripId: tripId,
          createdAt: DateTime.now(),
        ),
      );
    }

    return CsvImportResult(
      expenses: expenses,
      newCategories: newCategories,
      newTrips: newTrips,
      issues: issues,
      totalRows: dataRows,
      delimiter: delimiter,
    );
  }

  /// Формирует CSV для экспорта.
  static String export({
    required List<Expense> expenses,
    required Map<String, ExpenseCategory> categories,
    required Map<String, Trip> trips,
    String delimiter = ';',
  }) {
    final List<List<String>> rows = <List<String>>[
      columns,
      for (final Expense expense in expenses)
        <String>[
          expense.date.toIso8601String(),
          expense.amount.toStringAsFixed(2),
          categories[expense.categoryId]?.name ?? '',
          expense.payee,
          expense.paymentMethod.label,
          expense.comment,
          expense.tripId == null ? '' : trips[expense.tripId]?.title ?? '',
        ],
    ];
    return Csv(fieldDelimiter: delimiter, lineDelimiter: '\n').encode(rows);
  }

  static bool _looksLikeHeader(List<String> cells) =>
      parseDate(cells.first) == null;

  /// Разбор даты: ISO8601, `dd.MM.yyyy` и `dd/MM/yyyy`.
  static DateTime? parseDate(String raw) {
    final String value = raw.trim();
    if (value.isEmpty) {
      return null;
    }
    final DateTime? iso = DateTime.tryParse(value);
    if (iso != null) {
      return iso;
    }
    final RegExpMatch? match = RegExp(
      r'^(\d{1,2})[./-](\d{1,2})[./-](\d{4})$',
    ).firstMatch(value);
    if (match == null) {
      return null;
    }
    final int day = int.parse(match.group(1)!);
    final int month = int.parse(match.group(2)!);
    final int year = int.parse(match.group(3)!);
    if (month < 1 || month > 12 || day < 1 || day > 31) {
      return null;
    }
    return DateTime(year, month, day);
  }

  /// Разбор суммы: `1234.50`, `1234,50`, `1 234,50`, `1 234,50 ₽`.
  static double? parseAmount(String raw) {
    final String value = raw
        .replaceAll(RegExp(r'[^\d,.\-]'), '')
        .replaceAll(' ', '');
    if (value.isEmpty) {
      return null;
    }
    final int lastComma = value.lastIndexOf(',');
    final int lastDot = value.lastIndexOf('.');
    String normalized = value;
    if (lastComma >= 0 && lastDot >= 0) {
      // Разделитель дробной части — последний из символов.
      if (lastComma > lastDot) {
        normalized = value.replaceAll('.', '').replaceAll(',', '.');
      } else {
        normalized = value.replaceAll(',', '');
      }
    } else if (lastComma >= 0) {
      normalized = value.replaceAll(',', '.');
    }
    return double.tryParse(normalized);
  }
}
