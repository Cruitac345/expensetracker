// SPDX-License-Identifier: BSD-3-Clause
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/repositories/repositories.dart';
import 'data/services/receipt_storage.dart';
import 'data/store/json_store.dart';
import 'state/app_state.dart';
import 'state/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('ru_RU', null);
  Intl.defaultLocale = 'ru_RU';

  final JsonStore store = FileJsonStore();
  final AppState appState = AppState(
    expenseRepository: ExpenseRepository(store),
    categoryRepository: CategoryRepository(store),
    tripRepository: TripRepository(store),
    receiptStorage: ReceiptStorage(store),
    store: store,
  );
  final SettingsController settings = SettingsController();

  await settings.load();
  await appState.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AppState>.value(value: appState),
        ChangeNotifierProvider<SettingsController>.value(value: settings),
      ],
      child: const ExpenseTrackerApp(),
    ),
  );
}
