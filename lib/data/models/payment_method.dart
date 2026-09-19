// SPDX-License-Identifier: BSD-3-Clause
import 'package:flutter/material.dart';

/// Способ оплаты траты.
enum PaymentMethod {
  card('card', 'Карта', Icons.credit_card, <String>['карта', 'card', 'картой']),
  cash('cash', 'Наличные', Icons.payments_outlined, <String>[
    'наличные',
    'наличными',
    'cash',
  ]),
  qr('qr', 'QR-код', Icons.qr_code_2, <String>[
    'qr',
    'qr-code',
    'qr код',
    'qr-код',
    'куар',
  ]),
  other('other', 'Иной', Icons.more_horiz, <String>[
    'иной',
    'другой',
    'прочее',
    'other',
  ]);

  const PaymentMethod(this.id, this.label, this.icon, this.aliases);

  /// Идентификатор для хранения и экспорта.
  final String id;

  /// Название для интерфейса.
  final String label;

  final IconData icon;

  /// Синонимы, распознаваемые при импорте CSV.
  final List<String> aliases;

  static PaymentMethod fromId(String? id) => values.firstWhere(
    (PaymentMethod method) => method.id == id,
    orElse: () => PaymentMethod.other,
  );

  /// Разбор произвольной строки из CSV: `Карта`, `card`, `QR-код`, ...
  static PaymentMethod parse(String? raw) {
    final String value = (raw ?? '').trim().toLowerCase();
    if (value.isEmpty) {
      return PaymentMethod.other;
    }
    for (final PaymentMethod method in values) {
      if (method.id == value || method.label.toLowerCase() == value) {
        return method;
      }
      if (method.aliases.contains(value)) {
        return method;
      }
    }
    return PaymentMethod.other;
  }
}
