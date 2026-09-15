// SPDX-License-Identifier: BSD-3-Clause
import 'package:intl/intl.dart';

/// Форматирование сумм, дат и периодов для интерфейса на русском языке.
class Formatters {
  const Formatters._();

  static const String locale = 'ru_RU';

  static final NumberFormat _money = NumberFormat.currency(
    locale: locale,
    symbol: '₽',
    decimalDigits: 2,
  );

  static final NumberFormat _moneyCompact = NumberFormat.compactCurrency(
    locale: locale,
    symbol: '₽',
    decimalDigits: 1,
  );

  static final DateFormat _date = DateFormat('dd.MM.yyyy', locale);
  static final DateFormat _dateTime = DateFormat('dd.MM.yyyy HH:mm', locale);
  static final DateFormat _dayMonth = DateFormat('d MMMM', locale);
  static final DateFormat _monthYear = DateFormat('LLLL yyyy', locale);
  static final DateFormat _monthShort = DateFormat('LLL', locale);

  /// Сумма с символом рубля: `1 234,50 ₽`.
  static String money(double value) => _money.format(value);

  static final NumberFormat _compact = NumberFormat.compact(locale: locale);

  /// Компактное число для подписей оси диаграммы: `12,3 тыс.`.
  static String compactNumber(double value) => _compact.format(value);

  /// Компактная сумма для подписей диаграмм: `12,3 тыс. ₽`.
  static String moneyCompact(double value) => _moneyCompact.format(value);

  /// Сумма без символа валюты — для полей ввода.
  static String amount(double value) =>
      NumberFormat('#0.##', locale).format(value);

  static String date(DateTime value) => _date.format(value);

  static String dateTime(DateTime value) => _dateTime.format(value);

  static String dayMonth(DateTime value) => _dayMonth.format(value);

  /// Месяц и год с заглавной буквы: `Май 2026`.
  static String monthYear(DateTime value) => capitalize(_monthYear.format(value));

  /// Короткое название месяца для оси диаграммы: `май`.
  static String monthShort(DateTime value) =>
      _monthShort.format(value).replaceAll('.', '');

  /// Период «с … по …» с опущенным повтором года.
  static String range(DateTime start, DateTime end) {
    if (start.year == end.year) {
      return '${_dayMonth.format(start)} — ${_dayMonth.format(end)} ${end.year}';
    }
    return '${date(start)} — ${date(end)}';
  }

  static String capitalize(String value) => value.isEmpty
      ? value
      : value[0].toUpperCase() + value.substring(1);

  /// Разбор суммы из пользовательского ввода: принимает `1234,50` и `1234.50`.
  static double? parseAmount(String raw) {
    final String normalized = raw
        .replaceAll(' ', '')
        .replaceAll(' ', '')
        .replaceAll(',', '.')
        .trim();
    if (normalized.isEmpty) {
      return null;
    }
    return double.tryParse(normalized);
  }

  /// Склонение существительного: `5 трат`, `1 трата`, `2 траты`.
  static String plural(int count, String one, String few, String many) {
    final int mod100 = count % 100;
    final int mod10 = count % 10;
    if (mod100 >= 11 && mod100 <= 14) {
      return '$count $many';
    }
    if (mod10 == 1) {
      return '$count $one';
    }
    if (mod10 >= 2 && mod10 <= 4) {
      return '$count $few';
    }
    return '$count $many';
  }
}
