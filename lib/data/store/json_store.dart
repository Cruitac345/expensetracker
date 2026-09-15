// SPDX-License-Identifier: BSD-3-Clause
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Локальное хранилище коллекций в формате JSON.
///
/// Техническое задание требует локального хранения данных. Абстракция
/// позволяет подменить реализацию в тестах на хранилище в памяти.
abstract interface class JsonStore {
  /// Чтение коллекции. Для отсутствующей коллекции возвращается пустой список.
  Future<List<Map<String, dynamic>>> read(String collection);

  /// Полная перезапись коллекции.
  Future<void> write(String collection, List<Map<String, dynamic>> rows);

  /// Каталог данных приложения — в нём хранятся вложения (чеки).
  Future<Directory> dataDirectory();
}

/// Реализация поверх файловой системы каталога данных приложения.
///
/// Запись атомарная: данные пишутся во временный файл и затем переименовываются,
/// поэтому прерывание работы не повреждает коллекцию.
class FileJsonStore implements JsonStore {
  FileJsonStore({Directory? root}) : _root = root;

  Directory? _root;

  @override
  Future<Directory> dataDirectory() async {
    final Directory root = _root ??= await getApplicationDocumentsDirectory();
    if (!root.existsSync()) {
      await root.create(recursive: true);
    }
    return root;
  }

  Future<File> _file(String collection) async {
    final Directory root = await dataDirectory();
    return File(p.join(root.path, '$collection.json'));
  }

  @override
  Future<List<Map<String, dynamic>>> read(String collection) async {
    final File file = await _file(collection);
    if (!file.existsSync()) {
      return <Map<String, dynamic>>[];
    }
    final String raw = await file.readAsString();
    if (raw.trim().isEmpty) {
      return <Map<String, dynamic>>[];
    }
    final dynamic decoded = jsonDecode(raw);
    if (decoded is! List) {
      return <Map<String, dynamic>>[];
    }
    return decoded.whereType<Map<String, dynamic>>().toList(growable: false);
  }

  @override
  Future<void> write(String collection, List<Map<String, dynamic>> rows) async {
    final File file = await _file(collection);
    final File temp = File('${file.path}.tmp');
    await temp.writeAsString(jsonEncode(rows), flush: true);
    await temp.rename(file.path);
  }
}

/// Хранилище в памяти — используется в тестах.
class MemoryJsonStore implements JsonStore {
  MemoryJsonStore({Directory? directory}) : _directory = directory;

  final Map<String, List<Map<String, dynamic>>> _data =
      <String, List<Map<String, dynamic>>>{};
  final Directory? _directory;

  @override
  Future<Directory> dataDirectory() async =>
      _directory ?? Directory.systemTemp.createTempSync('expense_tracker');

  @override
  Future<List<Map<String, dynamic>>> read(String collection) async =>
      List<Map<String, dynamic>>.from(
        _data[collection] ?? <Map<String, dynamic>>[],
      );

  @override
  Future<void> write(String collection, List<Map<String, dynamic>> rows) async {
    _data[collection] = List<Map<String, dynamic>>.from(rows);
  }
}
