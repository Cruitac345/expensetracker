import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';

import '../../state/app_state.dart';
import '../models/expense.dart';
import '../models/expense_category.dart';
import '../models/trip.dart';

class BackupService {
  BackupService(this.state);

  final AppState state;

  Future<String> create() async {
    final Archive archive = Archive();

    final List<int> e1 = utf8.encode(jsonEncode(
      state.expenses.map((Expense e) => e.toJson()).toList(),
    ));
    archive.addFile(ArchiveFile('expenses.json', e1.length, e1));

    final List<int> e2 = utf8.encode(jsonEncode(
      state.categories.map((ExpenseCategory c) => c.toJson()).toList(),
    ));
    archive.addFile(ArchiveFile('categories.json', e2.length, e2));

    final List<int> e3 = utf8.encode(jsonEncode(
      state.trips.map((Trip t) => t.toJson()).toList(),
    ));
    archive.addFile(ArchiveFile('trips.json', e3.length, e3));

    final Directory receiptsDir = await state.receiptStorage.directory();
    for (final FileSystemEntity item in receiptsDir.listSync()) {
      if (item is File) {
        final List<int> bytes = item.readAsBytesSync();
        archive.addFile(ArchiveFile(
          'receipts/${item.uri.pathSegments.last}',
          bytes.length,
          bytes,
        ));
      }
    }

    final List<int> zip = ZipEncoder().encode(archive);
    final Directory dir = await getApplicationDocumentsDirectory();
    final String stamp = DateTime.now()
        .toIso8601String()
        .substring(0, 16)
        .replaceAll(':', '-');
    final File out = File('${dir.path}/backup_$stamp.zip');
    await out.writeAsBytes(zip);
    return out.path;
  }

  Future<void> restore(File zip) async {
    final Archive archive = ZipDecoder().decodeBytes(await zip.readAsBytes());

    final ArchiveFile expFile =
        archive.files.firstWhere((ArchiveFile f) => f.name == 'expenses.json');
    final List expRaw =
        jsonDecode(utf8.decode(expFile.content as List<int>)) as List;
    final List<Expense> expenses = expRaw
        .map((e) => Expense.fromJson(e as Map<String, dynamic>))
        .toList();

    final ArchiveFile catFile = archive.files
        .firstWhere((ArchiveFile f) => f.name == 'categories.json');
    final List catRaw =
        jsonDecode(utf8.decode(catFile.content as List<int>)) as List;
    final List<ExpenseCategory> categories = catRaw
        .map((c) => ExpenseCategory.fromJson(c as Map<String, dynamic>))
        .toList();

    final ArchiveFile tripFile =
        archive.files.firstWhere((ArchiveFile f) => f.name == 'trips.json');
    final List tripRaw =
        jsonDecode(utf8.decode(tripFile.content as List<int>)) as List;
    final List<Trip> trips =
        tripRaw.map((t) => Trip.fromJson(t as Map<String, dynamic>)).toList();

    final Directory receiptsDir = await state.receiptStorage.directory();
    await receiptsDir.create(recursive: true);
    for (final ArchiveFile f in archive.files) {
      if (!f.name.startsWith('receipts/')) continue;
      final String name = f.name.substring('receipts/'.length);
      await File('${receiptsDir.path}/$name')
          .writeAsBytes(f.content as List<int>);
    }

    await state.restoreAll(
      expenses: expenses,
      categories: categories,
      trips: trips,
    );
  }
}