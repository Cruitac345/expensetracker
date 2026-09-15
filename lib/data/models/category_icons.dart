// SPDX-License-Identifier: BSD-3-Clause
import 'package:flutter/material.dart';

/// Набор иконок для категорий трат.
///
/// В хранилище лежит строковый ключ, а не кодовая точка шрифта: так иконки
/// остаются константными и не мешают tree-shaking при сборке пакета.
class CategoryIcons {
  const CategoryIcons._();

  static const String fallbackKey = 'tag';

  static const Map<String, IconData> all = <String, IconData>{
    'basket': Icons.shopping_basket_outlined,
    'cafe': Icons.local_cafe_outlined,
    'home': Icons.home_outlined,
    'transport': Icons.directions_bus_outlined,
    'clothes': Icons.checkroom_outlined,
    'health': Icons.favorite_outline,
    'fun': Icons.sports_esports_outlined,
    'education': Icons.school_outlined,
    'tag': Icons.sell_outlined,
    'gift': Icons.card_giftcard,
    'pet': Icons.pets_outlined,
    'travel': Icons.flight_takeoff_outlined,
    'phone': Icons.smartphone_outlined,
    'fuel': Icons.local_gas_station_outlined,
    'sport': Icons.fitness_center_outlined,
    'beauty': Icons.spa_outlined,
    'tools': Icons.handyman_outlined,
    'book': Icons.menu_book_outlined,
    'child': Icons.child_care_outlined,
    'bank': Icons.account_balance_outlined,
  };

  static List<String> get keys => all.keys.toList(growable: false);

  static IconData byKey(String? key) =>
      all[key] ?? all[fallbackKey] ?? Icons.sell_outlined;
}
