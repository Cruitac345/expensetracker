// SPDX-License-Identifier: BSD-3-Clause
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/format/formatters.dart';
import '../../../core/layout/adaptive.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_tokens.dart';
import '../../../data/models/expense.dart';
import '../../../data/models/expense_filter.dart';
import '../../../data/services/analytics.dart';
import '../../../state/app_state.dart';
import '../../widgets/aurora_app_bar.dart';
import '../../widgets/aurora_widgets.dart';
import '../../widgets/expense_list_item.dart';
import 'expense_details_view.dart';
import 'expense_form_page.dart';
import 'filters_sheet.dart';

/// Общий список трат: прокрутка, фильтрация, поиск и переход к деталям.
class ExpensesPage extends StatefulWidget {
  const ExpensesPage({this.leading, super.key});

  final Widget? leading;

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _searchVisible = false;
  String? _selectedId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch(AppState state) {
    setState(() {
      _searchVisible = !_searchVisible;
      if (!_searchVisible) {
        _searchController.clear();
        state.updateQuery('');
      }
    });
  }

  Future<void> _openFilters(AppState state) async {
    final ExpenseFilter? filter = await showExpenseFilters(
      context,
      initial: state.filter,
      categories: state.categories,
      trips: state.trips,
    );
    if (filter != null) {
      state.applyFilter(filter);
    }
  }

  Future<void> _openForm(BuildContext context, {Expense? expense}) async {
    await Navigator.of(context).push(
      MaterialPageRoute<Object?>(
        builder: (_) => ExpenseFormPage(expense: expense),
      ),
    );
  }

  void _openExpense(
    BuildContext context,
    Expense expense, {
    required bool split,
  }) {
    if (split) {
      setState(() => _selectedId = expense.id);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ExpenseDetailsPage(expenseId: expense.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppState state = context.watch<AppState>();
    final bool split = AuroraLayout.isSplit(context);
    final List<Expense> expenses = state.visibleExpenses;
    final double total = ExpenseAnalytics.total(expenses);

    if (split &&
        _selectedId != null &&
        !expenses.any((Expense item) => item.id == _selectedId)) {
      _selectedId = null;
    }

    final Widget list = _ExpensesList(
      expenses: expenses,
      selectedId: split ? _selectedId : null,
      onTap: (Expense expense) => _openExpense(context, expense, split: split),
      onAdd: () => _openForm(context),
      hasFilter: !state.filter.isEmpty,
      onResetFilter: state.resetFilter,
    );

    return Scaffold(
      appBar: AuroraAppBar(
        title: 'Траты',
        subtitle:
            '${Formatters.plural(expenses.length, 'трата', 'траты', 'трат')} '
            'на ${Formatters.money(total)}',
        leading: widget.leading,
        actions: <Widget>[
          AuroraIconButton(
            icon: _searchVisible ? Icons.search_off : Icons.search,
            tooltip: 'Поиск по комментарию и получателю',
            selected: _searchVisible,
            onPressed: () => _toggleSearch(state),
          ),
          AuroraIconButton(
            icon: Icons.filter_alt_outlined,
            tooltip: 'Фильтры',
            badge: state.filter.activeCount,
            onPressed: () => _openFilters(state),
          ),
          _SortButton(current: state.sort, onSelected: state.changeSort),
        ],
        bottom: _searchVisible
            ? AuroraSearchField(
                controller: _searchController,
                hintText: 'Комментарий или получатель платежа',
                onChanged: (String value) {
                  state.updateQuery(value);
                  setState(() {});
                },
              )
            : null,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Трата'),
      ),
      body: split
          ? AuroraSplitView(
              panels: <AuroraPanel>[
                AuroraPanel(columnSpan: 5, child: list),
                AuroraPanel(
                  columnSpan: 7,
                  child: _selectedId == null
                      ? const AuroraEmptyState(
                          icon: Icons.touch_app_outlined,
                          title: 'Выберите трату',
                          message:
                              'Детали выбранной траты откроются в этой панели.',
                        )
                      : ExpenseDetailsView(
                          expenseId: _selectedId!,
                          onDeleted: () => setState(() => _selectedId = null),
                        ),
                ),
              ],
            )
          : list,
    );
  }
}

class _ExpensesList extends StatelessWidget {
  const _ExpensesList({
    required this.expenses,
    required this.selectedId,
    required this.onTap,
    required this.onAdd,
    required this.hasFilter,
    required this.onResetFilter,
  });

  final List<Expense> expenses;
  final String? selectedId;
  final ValueChanged<Expense> onTap;
  final VoidCallback onAdd;
  final bool hasFilter;
  final VoidCallback onResetFilter;

  @override
  Widget build(BuildContext context) {
    final AppState state = context.watch<AppState>();
    final double margin = AuroraLayout.pageMargin(context);

    if (expenses.isEmpty) {
      return AuroraEmptyState(
        icon: hasFilter
            ? Icons.filter_alt_off_outlined
            : Icons.savings_outlined,
        title: hasFilter ? 'Ничего не найдено' : 'Трат пока нет',
        message: hasFilter
            ? 'Измените условия фильтра или сбросьте его.'
            : 'Добавьте первую трату или импортируйте данные из CSV-файла.',
        action: hasFilter
            ? OutlinedButton(
                onPressed: onResetFilter,
                child: const Text('Сбросить фильтр'),
              )
            : ElevatedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Добавить трату'),
              ),
      );
    }

    // Группировка по месяцу: заголовок с названием месяца и суммой трат.
    final List<_ListEntry> entries = <_ListEntry>[];
    DateTime? currentMonth;
    for (final Expense expense in expenses) {
      if (currentMonth == null || expense.month != currentMonth) {
        currentMonth = expense.month;
        final double monthTotal = ExpenseAnalytics.total(
          expenses.where((Expense item) => item.month == currentMonth),
        );
        entries.add(_ListEntry.header(currentMonth, monthTotal));
      }
      entries.add(_ListEntry.expense(expense));
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        margin,
        AuroraSizes.paddingMedium,
        margin,
        AuroraSizes.itemSizeExtraLarge,
      ),
      itemCount: entries.length,
      separatorBuilder: (_, _) =>
          const SizedBox(height: AuroraSizes.paddingSmall),
      itemBuilder: (BuildContext context, int index) {
        final _ListEntry entry = entries[index];
        if (entry.isHeader) {
          return _MonthHeader(month: entry.month!, total: entry.total!);
        }
        final Expense expense = entry.expense!;
        return ExpenseListItem(
          expense: expense,
          category: state.categoryById(expense.categoryId),
          trip: state.tripById(expense.tripId),
          selected: expense.id == selectedId,
          onTap: () => onTap(expense),
        );
      },
    );
  }
}

class _ListEntry {
  _ListEntry.header(this.month, this.total) : expense = null, isHeader = true;

  _ListEntry.expense(this.expense)
    : month = null,
      total = null,
      isHeader = false;

  final bool isHeader;
  final DateTime? month;
  final double? total;
  final Expense? expense;
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.month, required this.total});

  final DateTime month;
  final double total;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AuroraSizes.paddingSmall,
        AuroraSizes.paddingMedium,
        AuroraSizes.paddingSmall,
        AuroraSizes.paddingSmall,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(Formatters.monthYear(month), style: text.titleSmall),
          ),
          Text(
            Formatters.money(total),
            style: text.titleSmall?.copyWith(color: context.palette.accent),
          ),
        ],
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton({required this.current, required this.onSelected});

  final ExpenseSort current;
  final ValueChanged<ExpenseSort> onSelected;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: AuroraSizes.itemSizeExtraSmall,
    height: AuroraSizes.itemSizeExtraSmall,
    child: PopupMenuButton<ExpenseSort>(
      tooltip: 'Сортировка',
      icon: const Icon(Icons.swap_vert),
      iconSize: AuroraSizes.iconSizeSmallPlus,
      color: context.palette.surface,
      shape: RoundedRectangleBorder(borderRadius: AuroraRadius.medium),
      onSelected: onSelected,
      itemBuilder: (BuildContext context) => <PopupMenuEntry<ExpenseSort>>[
        for (final ExpenseSort sort in ExpenseSort.values)
          PopupMenuItem<ExpenseSort>(
            value: sort,
            height: AuroraSizes.itemSizeExtraSmall,
            child: Row(
              children: <Widget>[
                Icon(
                  sort == current ? Icons.check : Icons.remove,
                  size: AuroraSizes.iconSizeSmall,
                  color: sort == current
                      ? context.palette.accent
                      : Colors.transparent,
                ),
                const SizedBox(width: AuroraSizes.paddingMedium),
                Text(sort.label, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
      ],
    ),
  );
}
