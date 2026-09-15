// SPDX-License-Identifier: BSD-3-Clause
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/format/formatters.dart';
import '../../../core/layout/adaptive.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_tokens.dart';
import '../../../data/models/expense_category.dart';
import '../../../data/models/trip.dart';
import '../../../data/services/csv_import_service.dart';
import '../../../data/services/text_decoder.dart';
import '../../../state/app_state.dart';
import '../../widgets/aurora_app_bar.dart';
import '../../widgets/aurora_widgets.dart';

/// Импорт трат из локальных CSV-файлов.
class ImportPage extends StatefulWidget {
  const ImportPage({this.leading, super.key});

  final Widget? leading;

  @override
  State<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends State<ImportPage> {
  CsvImportResult? _result;
  String? _fileName;
  bool _busy = false;

  Future<void> _pickFile() async {
    final AppState state = context.read<AppState>();
    setState(() => _busy = true);
    try {
      const XTypeGroup group = XTypeGroup(
        label: 'CSV',
        extensions: <String>['csv', 'txt'],
        mimeTypes: <String>['text/csv', 'text/plain'],
      );
      final XFile? file = await openFile(
        acceptedTypeGroups: const <XTypeGroup>[group],
      );
      if (file == null) {
        return;
      }
      final String content = TextDecoder.decode(await file.readAsBytes());
      final CsvImportResult result = CsvImportService(
        idGenerator: state.newId,
      ).parse(
        content,
        categories: state.categories,
        trips: state.trips,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _result = result;
        _fileName = file.name;
      });
    } on Exception catch (error) {
      if (mounted) {
        auroraNotify(context, 'Не удалось прочитать файл: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _apply() async {
    final CsvImportResult? result = _result;
    if (result == null || result.isEmpty) {
      return;
    }
    final AppState state = context.read<AppState>();
    setState(() => _busy = true);
    await state.applyImport(result);
    if (!mounted) {
      return;
    }
    setState(() {
      _busy = false;
      _result = null;
      _fileName = null;
    });
    auroraNotify(
      context,
      'Импортировано '
      '${Formatters.plural(result.expenses.length, 'трата', 'траты', 'трат')}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final AuroraPalette palette = context.palette;
    final TextTheme text = Theme.of(context).textTheme;
    final double margin = AuroraLayout.pageMargin(context);
    final CsvImportResult? result = _result;

    return Scaffold(
      appBar: AuroraAppBar(
        title: 'Импорт CSV',
        subtitle: _fileName ?? 'Загрузка трат из файла',
        leading: widget.leading,
        actions: <Widget>[
          AuroraIconButton(
            icon: Icons.folder_open,
            tooltip: 'Выбрать файл',
            onPressed: _busy ? null : _pickFile,
          ),
        ],
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
            title: 'Формат файла',
            subtitle: 'Колонки в порядке технического задания',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AuroraSizes.paddingMedium),
                  decoration: BoxDecoration(
                    color: palette.surfaceVariant,
                    borderRadius: AuroraRadius.small,
                  ),
                  child: Text(
                    CsvImportService.columns.join(' | '),
                    style: text.bodySmall?.copyWith(fontFamily: 'monospace'),
                  ),
                ),
                const SizedBox(height: AuroraSizes.paddingMedium),
                Text(
                  'Дата — в формате ISO 8601 (2026-05-14) или 14.05.2026. '
                  'Сумма — число с точкой или запятой. '
                  'Разделитель колонок ( ; , | или табуляция) и кодировка '
                  '(UTF-8 или Windows-1251) определяются автоматически, '
                  'строка заголовка пропускается. Неизвестные категории и '
                  'командировки создаются при импорте.',
                  style: text.bodySmall,
                ),
                const SizedBox(height: AuroraSizes.paddingMedium),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AuroraSizes.paddingMedium),
                  decoration: BoxDecoration(
                    color: palette.surfaceVariant,
                    borderRadius: AuroraRadius.small,
                  ),
                  child: Text(
                    '2026-05-14T10:20:00;1250.50;Продукты;Магнит;'
                    'Карта;Продукты на неделю;',
                    style: text.bodySmall?.copyWith(fontFamily: 'monospace'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AuroraSizes.paddingMedium),
          if (result == null)
            AuroraSection(
              title: 'Файл',
              child: Column(
                children: <Widget>[
                  Text(
                    'Выберите CSV-файл в памяти устройства.',
                    style: text.bodyMedium,
                  ),
                  const SizedBox(height: AuroraSizes.paddingMedium),
                  ElevatedButton.icon(
                    onPressed: _busy ? null : _pickFile,
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Выбрать CSV-файл'),
                  ),
                ],
              ),
            )
          else ...<Widget>[
            AuroraSection(
              title: 'Разбор файла',
              subtitle: 'Разделитель: «${result.delimiter}»',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _ResultRow(
                    icon: Icons.check_circle_outline,
                    color: palette.success,
                    label: 'Готово к импорту',
                    value: Formatters.plural(
                      result.expenses.length,
                      'трата',
                      'траты',
                      'трат',
                    ),
                  ),
                  _ResultRow(
                    icon: Icons.sell_outlined,
                    color: palette.primary,
                    label: 'Новые категории',
                    value: result.newCategories.isEmpty
                        ? 'нет'
                        : result.newCategories
                              .map((ExpenseCategory item) => item.name)
                              .join(', '),
                  ),
                  _ResultRow(
                    icon: Icons.work_outline,
                    color: palette.primary,
                    label: 'Новые командировки',
                    value: result.newTrips.isEmpty
                        ? 'нет'
                        : result.newTrips
                              .map((Trip item) => item.title)
                              .join(', '),
                  ),
                  _ResultRow(
                    icon: Icons.error_outline,
                    color: result.issues.isEmpty
                        ? palette.textSecondary
                        : palette.danger,
                    label: 'Пропущено строк',
                    value: '${result.issues.length} из ${result.totalRows}',
                  ),
                  if (result.issues.isNotEmpty) ...<Widget>[
                    const SizedBox(height: AuroraSizes.paddingMedium),
                    for (final CsvImportIssue issue in result.issues.take(10))
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: AuroraSizes.paddingSmall,
                        ),
                        child: Text(
                          'Строка ${issue.line}: ${issue.message}',
                          style: text.bodySmall?.copyWith(
                            color: palette.danger,
                          ),
                        ),
                      ),
                    if (result.issues.length > 10)
                      Text(
                        'и ещё ${result.issues.length - 10}…',
                        style: text.bodySmall,
                      ),
                  ],
                  const SizedBox(height: AuroraSizes.paddingLarge),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _busy
                              ? null
                              : () => setState(() {
                                  _result = null;
                                  _fileName = null;
                                }),
                          child: const Text('Отмена'),
                        ),
                      ),
                      const SizedBox(width: AuroraSizes.paddingMedium),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _busy || result.isEmpty ? null : _apply,
                          child: Text(
                            'Импортировать ${result.expenses.length}',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AuroraSizes.paddingMedium),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: AuroraSizes.iconSizeExtraSmall, color: color),
          const SizedBox(width: AuroraSizes.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(label, style: text.bodySmall),
                Text(value, style: text.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
