// SPDX-License-Identifier: BSD-3-Clause
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Найденный на устройстве файл с данными для импорта.
class CsvCandidate {
  const CsvCandidate({
    required this.file,
    required this.name,
    required this.folder,
    required this.size,
    required this.modified,
  });

  final File file;

  /// Имя файла без пути.
  final String name;

  /// Человекочитаемое имя каталога, в котором лежит файл.
  final String folder;

  /// Размер в байтах.
  final int size;
  final DateTime modified;
}

/// Поиск CSV-файлов в пользовательских каталогах устройства —
/// запасной выбор, когда системный селектор недоступен.
class CsvFileFinder {
  const CsvFileFinder();

  static const List<String> _extensions = <String>['.csv', '.txt'];

  /// Каталоги, где обычно лежат выгрузки.
  static const List<String> _userFolders = <String>[
    'Documents',
    'Downloads',
    'Загрузки',
    'Документы',
    'Download',
  ];

  /// Ищет подходящие файлы и возвращает их от свежих к старым.
  Future<List<CsvCandidate>> find() async {
    final List<Directory> roots = await _roots();
    final Map<String, CsvCandidate> found = <String, CsvCandidate>{};

    for (final Directory root in roots) {
      for (final File file in _filesOf(root)) {
        found.putIfAbsent(file.path, () => _describe(file, root));
      }
    }

    final List<CsvCandidate> result = found.values.toList()
      ..sort(
        (CsvCandidate a, CsvCandidate b) => b.modified.compareTo(a.modified),
      );
    return result;
  }

  Future<List<Directory>> _roots() async {
    final List<Directory> roots = <Directory>[];

    void add(String? path) {
      if (path == null || path.isEmpty) {
        return;
      }
      final Directory directory = Directory(path);
      if (directory.existsSync() &&
          !roots.any((Directory item) => item.path == directory.path)) {
        roots.add(directory);
      }
    }

    final String? home = Platform.environment['HOME'];
    for (final String folder in _userFolders) {
      add(home == null ? null : p.join(home, folder));
    }
    add(home);

    try {
      add((await getApplicationDocumentsDirectory()).path);
    } on Exception {
      // Каталог может быть недоступен.
    }
    // Съёмный носитель.
    add('/run/media/${Platform.environment['USER'] ?? 'defaultuser'}');
    return roots;
  }

  /// Файлы каталога и его подкаталогов первого уровня.
  Iterable<File> _filesOf(Directory root) sync* {
    for (final FileSystemEntity entity in _listSafely(root)) {
      if (entity is File && _isSupported(entity.path)) {
        yield entity;
      } else if (entity is Directory && !p.basename(entity.path).startsWith('.')) {
        for (final FileSystemEntity nested in _listSafely(entity)) {
          if (nested is File && _isSupported(nested.path)) {
            yield nested;
          }
        }
      }
    }
  }

  List<FileSystemEntity> _listSafely(Directory directory) {
    try {
      return directory.listSync(followLinks: false);
    } on FileSystemException {
      // Каталог закрыт песочницей.
      return const <FileSystemEntity>[];
    }
  }

  bool _isSupported(String path) =>
      _extensions.contains(p.extension(path).toLowerCase());

  CsvCandidate _describe(File file, Directory root) {
    final FileStat stat = file.statSync();
    return CsvCandidate(
      file: file,
      name: p.basename(file.path),
      folder: p.basename(p.dirname(file.path)),
      size: stat.size,
      modified: stat.modified,
    );
  }
}
