// SPDX-License-Identifier: BSD-3-Clause
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/format/formatters.dart';
import '../../../core/layout/adaptive.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_tokens.dart';
import '../../../data/services/analytics.dart';
import '../../../state/app_state.dart';
import '../../../state/settings_controller.dart';
import '../../widgets/aurora_app_bar.dart';
import '../../widgets/aurora_widgets.dart';

/// Настройки приложения и сведения о данных.
class SettingsPage extends StatelessWidget {
  const SettingsPage({this.leading, super.key});

  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final AppState state = context.watch<AppState>();
    final SettingsController settings = context.watch<SettingsController>();
    final TextTheme text = Theme.of(context).textTheme;
    final double margin = AuroraLayout.pageMargin(context);

    return Scaffold(
      appBar: AuroraAppBar(
        title: 'Настройки',
        subtitle: 'Оформление и данные приложения',
        leading: leading,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          margin,
          AuroraSizes.paddingMedium,
          margin,
          AuroraSizes.paddingLarge,
        ),
        children: <Widget>[
          AuroraSection(
            title: 'Оформление',
            subtitle: 'Схема интерфейса',
            child: RadioGroup<ThemeMode>(
              groupValue: settings.themeMode,
              onChanged: (ThemeMode? value) {
                if (value != null) {
                  settings.setThemeMode(value);
                }
              },
              child: Column(
                children: <Widget>[
                  for (final ThemeMode mode in ThemeMode.values)
                    RadioListTile<ThemeMode>(
                      value: mode,
                      title: Text(switch (mode) {
                        ThemeMode.system => 'Как в системе',
                        ThemeMode.light => 'Светлая',
                        ThemeMode.dark => 'Тёмная',
                      }, style: text.bodyMedium),
                      contentPadding: EdgeInsets.zero,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AuroraSizes.paddingMedium),
          AuroraSection(
            title: 'Данные',
            subtitle: 'Хранятся локально в каталоге приложения',
            child: Column(
              children: <Widget>[
                _InfoRow(label: 'Траты', value: '${state.allExpenses.length}'),
                _InfoRow(
                  label: 'Общая сумма',
                  value: Formatters.money(
                    ExpenseAnalytics.total(state.allExpenses),
                  ),
                ),
                _InfoRow(
                  label: 'Категории',
                  value:
                      '${state.categories.length} '
                      '(своих — ${state.customCategories.length})',
                ),
                _InfoRow(label: 'Командировки', value: '${state.trips.length}'),
                const SizedBox(height: AuroraSizes.paddingMedium),
                OutlinedButton.icon(
                  onPressed: () async {
                    final String path = await state.exportCsv();
                    if (context.mounted) {
                      auroraNotify(context, 'Файл сохранён: $path');
                    }
                  },
                  icon: const Icon(Icons.file_upload_outlined),
                  label: const Text('Выгрузить траты в CSV'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AuroraSizes.paddingMedium),
          AuroraSection(
            title: 'О приложении',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const _InfoRow(label: 'Название', value: 'Трекер Расходов'),
                const _InfoRow(label: 'Версия', value: '1.0.0'),
                const _InfoRow(label: 'Платформа', value: 'ОС Аврора 5.1.6+'),
                const _InfoRow(label: 'Лицензия', value: 'BSD-3-Clause'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AuroraSizes.paddingSmall),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label, style: text.bodyMedium)),
          Text(
            value,
            style: text.bodyMedium?.copyWith(
              color: context.palette.textSecondary,
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }
}
