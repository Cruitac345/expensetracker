import 'package:aurora_intent/aurora_intent.dart';
import 'package:flutter/material.dart';
import 'state/app_state.dart';
import 'ui/screens/report_preview.dart';
import 'data/models/expense.dart';


Future<void> registerReportIntent(
  AppState state,
  GlobalKey<NavigatorState> nav,
) async {
  AuroraIntent.initialize();

  await AuroraIntent.registerIntent('X-GenerateReport', (Map p) async {
    try {
      final Map? period = p['period'] as Map?;
      final DateTime? from =
          period?['from'] == null ? null : DateTime.parse(period!['from']);
      final DateTime? to =
          period?['to'] == null ? null : DateTime.parse(period!['to']);

      final List cats = p['categories'] as List? ?? [];
      final List trips = p['trips'] as List? ?? [];
      final List methods = p['paymentMethods'] as List? ?? [];
      final String search = (p['search'] as String? ?? '').toLowerCase();
      final bool? hasReceipt = p['hasReceipt'] as bool?;
      final String sort = p['sort'] as String? ?? 'date_desc';

      final List<Expense> list = state.expenses.where((Expense e) {
        if (from != null && e.date.isBefore(from)) return false;
        if (to != null && e.date.isAfter(to)) return false;
        if (cats.isNotEmpty &&
            !cats.contains(state.categoryById(e.categoryId)?.name)) {
          return false;
        }
        if (trips.isNotEmpty) {
          final String title =
              e.tripId == null ? '' : (state.tripById(e.tripId)?.title ?? '');
          if (!trips.contains(title)) return false;
        }
        if (methods.isNotEmpty && !methods.contains(e.paymentMethod.id)) {
          return false;
        }
        if (hasReceipt != null && e.hasReceipts!= hasReceipt) return false;
        if (search.isNotEmpty &&
            !e.comment.toLowerCase().contains(search) &&
            !e.payee.toLowerCase().contains(search)) {
          return false;
        }
        return true;
      }).toList();

      switch (sort) {
        case 'date_asc':
          list.sort((a, b) => a.date.compareTo(b.date));
        case 'amount_desc':
          list.sort((a, b) => b.amount.compareTo(a.amount));
        case 'amount_asc':
          list.sort((a, b) => a.amount.compareTo(b.amount));
        default:
          list.sort((a, b) => b.date.compareTo(a.date));
      }

      if (list.isEmpty) {
        return {'status': 'error', 'errorMessage': 'Нет трат'};
      }

      final String? path = await nav.currentState!.push<String>(
        MaterialPageRoute<String>(builder: (_) => ReportPreview(expenses: list)),
      );

      return path == null
          ? {'status': 'error', 'errorMessage': 'cancelled'}
          : {'status': 'ok', 'path': path};
    } catch (e) {
      return {'status': 'error', 'errorMessage': e.toString()};
    }
  });

  await AuroraIntent.startService();
}