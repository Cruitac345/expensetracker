// SPDX-License-Identifier: BSD-3-Clause
import 'package:flutter/foundation.dart';

import 'category_icons.dart';

/// Категория траты.
///
/// Стандартные категории (`isBuiltIn`) заданы техническим заданием, их нельзя
/// удалить. Пользовательские категории можно создавать, изменять и удалять.
@immutable
class ExpenseCategory {
  const ExpenseCategory({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.colorIndex,
    this.isBuiltIn = false,
  });

  factory ExpenseCategory.fromJson(Map<String, dynamic> json) =>
      ExpenseCategory(
        id: json['id'] as String,
        name: json['name'] as String,
        iconKey: json['iconKey'] as String? ?? CategoryIcons.fallbackKey,
        colorIndex: (json['colorIndex'] as num?)?.toInt() ?? 0,
        isBuiltIn: json['isBuiltIn'] as bool? ?? false,
      );

  final String id;
  final String name;
  final String iconKey;

  /// Индекс цвета в палитре диаграмм.
  final int colorIndex;

  /// Стандартная категория из технического задания.
  final bool isBuiltIn;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'iconKey': iconKey,
    'colorIndex': colorIndex,
    'isBuiltIn': isBuiltIn,
  };

  ExpenseCategory copyWith({
    String? name,
    String? iconKey,
    int? colorIndex,
  }) => ExpenseCategory(
    id: id,
    name: name ?? this.name,
    iconKey: iconKey ?? this.iconKey,
    colorIndex: colorIndex ?? this.colorIndex,
    isBuiltIn: isBuiltIn,
  );

  /// Стандартные категории трат (техническое задание, раздел «Категории трат»).
  static const List<ExpenseCategory> defaults = <ExpenseCategory>[
    ExpenseCategory(
      id: 'cat_groceries',
      name: 'Продукты',
      iconKey: 'basket',
      colorIndex: 0,
      isBuiltIn: true,
    ),
    ExpenseCategory(
      id: 'cat_cafe',
      name: 'Кафе',
      iconKey: 'cafe',
      colorIndex: 1,
      isBuiltIn: true,
    ),
    ExpenseCategory(
      id: 'cat_utilities',
      name: 'Коммунальные платежи',
      iconKey: 'home',
      colorIndex: 2,
      isBuiltIn: true,
    ),
    ExpenseCategory(
      id: 'cat_transport',
      name: 'Транспорт',
      iconKey: 'transport',
      colorIndex: 3,
      isBuiltIn: true,
    ),
    ExpenseCategory(
      id: 'cat_clothes',
      name: 'Одежда',
      iconKey: 'clothes',
      colorIndex: 4,
      isBuiltIn: true,
    ),
    ExpenseCategory(
      id: 'cat_health',
      name: 'Здоровье',
      iconKey: 'health',
      colorIndex: 5,
      isBuiltIn: true,
    ),
    ExpenseCategory(
      id: 'cat_entertainment',
      name: 'Развлечение',
      iconKey: 'fun',
      colorIndex: 6,
      isBuiltIn: true,
    ),
    ExpenseCategory(
      id: 'cat_education',
      name: 'Обучение',
      iconKey: 'education',
      colorIndex: 7,
      isBuiltIn: true,
    ),
  ];

  @override
  bool operator ==(Object other) =>
      other is ExpenseCategory &&
      other.id == id &&
      other.name == name &&
      other.iconKey == iconKey &&
      other.colorIndex == colorIndex &&
      other.isBuiltIn == isBuiltIn;

  @override
  int get hashCode => Object.hash(id, name, iconKey, colorIndex, isBuiltIn);
}
