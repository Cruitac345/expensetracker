// SPDX-License-Identifier: BSD-3-Clause
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../store/json_store.dart';

/// Хранилище чеков: файл копируется в каталог `receipts` данных приложения,
/// в трате сохраняется относительный путь.
class ReceiptStorage {
  ReceiptStorage(this._store, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  static const String folder = 'receipts';

  final JsonStore _store;
  final Uuid _uuid;

  Future<Directory> _folder() async {
    final Directory root = await _store.dataDirectory();
    final Directory directory = Directory(p.join(root.path, folder));
    if (!directory.existsSync()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  /// Копирует файл в данные приложения и возвращает относительный путь.
  Future<String> add(String sourcePath) async {
    final Directory directory = await _folder();
    final String extension = p.extension(sourcePath).isEmpty
        ? '.jpg'
        : p.extension(sourcePath);
    final String name = '${_uuid.v4()}$extension';
    await File(sourcePath).copy(p.join(directory.path, name));
    return p.join(folder, name);
  }

  /// Абсолютный путь к файлу чека.
  Future<File> resolve(String relativePath) async {
    final Directory root = await _store.dataDirectory();
    return File(p.join(root.path, relativePath));
  }

  /// Удаляет файл чека из данных приложения.
  Future<void> remove(String relativePath) async {
    final File file = await resolve(relativePath);
    if (file.existsSync()) {
      await file.delete();
    }
  }

  /// Удаляет все чеки траты.
  Future<void> removeAll(Iterable<String> relativePaths) async {
    for (final String path in relativePaths) {
      await remove(path);
    }
  }
}
