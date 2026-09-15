// SPDX-License-Identifier: BSD-3-Clause
import 'package:flutter/foundation.dart';

import 'payment_method.dart';

/// Трата — основная сущность приложения.
@immutable
class Expense {
  const Expense({
    required this.id,
    required this.amount,
    required this.categoryId,
    required this.date,
    this.payee = '',
    this.comment = '',
    this.paymentMethod = PaymentMethod.card,
    this.tripId,
    this.receiptPaths = const <String>[],
    this.createdAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
    id: json['id'] as String,
    amount: (json['amount'] as num).toDouble(),
    categoryId: json['categoryId'] as String,
    date: DateTime.parse(json['date'] as String),
    payee: json['payee'] as String? ?? '',
    comment: json['comment'] as String? ?? '',
    paymentMethod: PaymentMethod.fromId(json['paymentMethod'] as String?),
    tripId: json['tripId'] as String?,
    receiptPaths:
        (json['receiptPaths'] as List<dynamic>?)
            ?.map((dynamic path) => path as String)
            .toList(growable: false) ??
        const <String>[],
    createdAt: json['createdAt'] == null
        ? null
        : DateTime.parse(json['createdAt'] as String),
  );

  final String id;

  /// Сумма траты.
  final double amount;

  final String categoryId;

  /// Дата совершения траты.
  final DateTime date;

  /// Получатель платежа — организация, получившая платёж.
  final String payee;

  /// Текстовый комментарий.
  final String comment;

  final PaymentMethod paymentMethod;

  /// Командировка, к которой прикреплена трата (для служебных расходов).
  final String? tripId;

  /// Пути к файлам чеков внутри каталога данных приложения.
  final List<String> receiptPaths;

  final DateTime? createdAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'amount': amount,
    'categoryId': categoryId,
    'date': date.toIso8601String(),
    'payee': payee,
    'comment': comment,
    'paymentMethod': paymentMethod.id,
    'tripId': tripId,
    'receiptPaths': receiptPaths,
    'createdAt': (createdAt ?? date).toIso8601String(),
  };

  Expense copyWith({
    double? amount,
    String? categoryId,
    DateTime? date,
    String? payee,
    String? comment,
    PaymentMethod? paymentMethod,
    String? tripId,
    bool clearTrip = false,
    List<String>? receiptPaths,
  }) => Expense(
    id: id,
    amount: amount ?? this.amount,
    categoryId: categoryId ?? this.categoryId,
    date: date ?? this.date,
    payee: payee ?? this.payee,
    comment: comment ?? this.comment,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    tripId: clearTrip ? null : (tripId ?? this.tripId),
    receiptPaths: receiptPaths ?? this.receiptPaths,
    createdAt: createdAt,
  );

  bool get hasReceipts => receiptPaths.isNotEmpty;

  /// Первый день месяца траты — ключ группировки для дашборда.
  DateTime get month => DateTime(date.year, date.month);

  @override
  bool operator ==(Object other) =>
      other is Expense &&
      other.id == id &&
      other.amount == amount &&
      other.categoryId == categoryId &&
      other.date == date &&
      other.payee == payee &&
      other.comment == comment &&
      other.paymentMethod == paymentMethod &&
      other.tripId == tripId &&
      listEquals(other.receiptPaths, receiptPaths);

  @override
  int get hashCode => Object.hash(
    id,
    amount,
    categoryId,
    date,
    payee,
    comment,
    paymentMethod,
    tripId,
    Object.hashAll(receiptPaths),
  );
}
