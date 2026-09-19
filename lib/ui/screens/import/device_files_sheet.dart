// SPDX-License-Identifier: BSD-3-Clause
import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/format/formatters.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_tokens.dart';
import '../../../data/services/csv_file_finder.dart';

/// Список CSV-файлов из каталогов устройства. Возвращает выбранный файл
/// или `null`, если панель закрыли.
Future<File?> showDeviceCsvFiles(BuildContext context) =>
    showModalBottomSheet<File>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => const _DeviceFilesSheet(),
    );

class _DeviceFilesSheet extends StatefulWidget {
  const _DeviceFilesSheet();

  @override
  State<_DeviceFilesSheet> createState() => _DeviceFilesSheetState();
}

class _DeviceFilesSheetState extends State<_DeviceFilesSheet> {
  late Future<List<CsvCandidate>> _files;

  @override
  void initState() {
    super.initState();
    _files = const CsvFileFinder().find();
  }

  @override
  Widget build(BuildContext context) {
    final AuroraPalette palette = context.palette;
    final TextTheme text = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AuroraSizes.paddingLarge),
        child: FutureBuilder<List<CsvCandidate>>(
          future: _files,
          builder:
              (
                BuildContext context,
                AsyncSnapshot<List<CsvCandidate>> snapshot,
              ) {
                final List<CsvCandidate> files =
                    snapshot.data ?? const <CsvCandidate>[];
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Файлы на устройстве', style: text.titleLarge),
                    const SizedBox(height: AuroraSizes.paddingSmall),
                    Text(
                      'Найдены CSV-файлы в пользовательских каталогах.',
                      style: text.bodySmall,
                    ),
                    const SizedBox(height: AuroraSizes.paddingMedium),
                    if (snapshot.connectionState != ConnectionState.done)
                      const Padding(
                        padding: EdgeInsets.all(AuroraSizes.paddingLarge),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (files.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AuroraSizes.paddingLarge,
                        ),
                        child: Text(
                          'CSV-файлов не нашлось. Положите файл в каталог '
                          '«Документы» или «Загрузки» и повторите.',
                          style: text.bodyMedium,
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: files.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AuroraSizes.paddingSmall),
                          itemBuilder: (BuildContext context, int index) {
                            final CsvCandidate item = files[index];
                            return _FileTile(
                              item: item,
                              onTap: () =>
                                  Navigator.of(context).pop(item.file),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: AuroraSizes.paddingMedium),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: palette.textPrimary,
                        ),
                        child: const Text('Отмена'),
                      ),
                    ),
                  ],
                );
              },
        ),
      ),
    );
  }
}

class _FileTile extends StatelessWidget {
  const _FileTile({required this.item, required this.onTap});

  final CsvCandidate item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AuroraPalette palette = context.palette;
    final TextTheme text = Theme.of(context).textTheme;

    return Material(
      color: palette.surfaceVariant,
      borderRadius: AuroraRadius.small,
      child: InkWell(
        onTap: onTap,
        borderRadius: AuroraRadius.small,
        child: Container(
          constraints: const BoxConstraints(
            minHeight: AuroraSizes.itemSizeMedium,
          ),
          padding: const EdgeInsets.all(AuroraSizes.paddingMedium),
          child: Row(
            children: <Widget>[
              Icon(
                Icons.description_outlined,
                size: AuroraSizes.iconSizeSmallPlus,
                color: palette.accent,
              ),
              const SizedBox(width: AuroraSizes.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.name,
                      style: text.bodyLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${item.folder} · ${_size(item.size)} · '
                      '${Formatters.date(item.modified)}',
                      style: text.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _size(int bytes) {
    if (bytes < 1024) {
      return '$bytes Б';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} КБ';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} МБ';
  }
}
