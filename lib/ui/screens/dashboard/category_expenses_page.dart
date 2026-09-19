// SPDX-License-Identifier: BSD-3-Clause
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/format/formatters.dart';
import '../../../core/layout/adaptive.dart';
import '../../../core/theme/aurora_tokens.dart';
import '../../../data/models/expense.dart';
import '../../../data/models/expense_category.dart';
import '../../../data/models/expense_filter.dart';
import '../../../data/services/analytics.dart';
import '../../../state/app_state.dart';
import '../../widgets/aurora_app_bar.dart';
import '../../widgets/aurora_widgets.dart';
import '../../widgets/expense_list_item.dart';
import '../expenses/expense_details_view.dart';

/// Траты выбранной категории за период. Открывается из дашборда нажатием
/// на сегмент диаграммы или строку легенды.
class CategoryExpensesPage extends StatelessWidget {
  const CategoryExpensesPage({
    required this.categoryId,
    this.range,
    this.periodLabel,
    super.key,
  });

  final String categoryId;
  final DateRange? range;
  final String? periodLabel;

  @override
  Widget build(BuildContext context) {
    final AppState state = context.watch<AppState>();
    final ExpenseCategory? category = state.categoryById(categoryId);
    final double margin = AuroraLayout.pageMargin(context);

    final List<Expense> expenses = state
        .expensesOfCategory(categoryId)
        .where((Expense expense) => range?.contains(expense.date) ?? true)
        .toList();
    final double total = ExpenseAnalytics.total(expenses);

    return Scaffold(
      appBar: AuroraAppBar(
        title: category?.name ?? 'Категория',
        subtitle:
            '${Formatters.plural(expenses.length, 'трата', 'траты', 'трат')} '
            'на ${Formatters.money(total)}'
            '${periodLabel == null ? '' : ' · $periodLabel'}',
        leading: AuroraIconButton(
          icon: Icons.arrow_back,
          tooltip: 'Назад',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: expenses.isEmpty
          ? const AuroraEmptyState(
              icon: Icons.inbox_outlined,
              title: 'Трат нет',
              message: 'В этой категории за выбранный период трат не было.',
            )
          : ListView.separated(
              padding: EdgeInsets.fromLTRB(
                margin,
                AuroraSizes.paddingMedium,
                margin,
                AuroraSizes.paddingLarge,
              ),
              itemCount: expenses.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AuroraSizes.paddingSmall),
              itemBuilder: (BuildContext context, int index) {
                final Expense expense = expenses[index];
                return ExpenseListItem(
                  expense: expense,
                  category: category,
                  trip: state.tripById(expense.tripId),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ExpenseDetailsPage(expenseId: expense.id),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
