// SPDX-License-Identifier: BSD-3-Clause
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/theme/aurora_theme.dart';
import 'state/settings_controller.dart';
import 'ui/screens/home/home_shell.dart';

/// Корневой виджет приложения «Трекер Расходов».
class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final SettingsController settings = context.watch<SettingsController>();

    return MaterialApp(
      title: 'Трекер Расходов',
      debugShowCheckedModeBanner: false,
      theme: AuroraTheme.light(),
      darkTheme: AuroraTheme.dark(),
      themeMode: settings.themeMode,
      locale: const Locale('ru', 'RU'),
      supportedLocales: const <Locale>[Locale('ru', 'RU')],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const HomeShell(),
    );
  }
}
