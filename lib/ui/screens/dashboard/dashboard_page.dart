// SPDX-License-Identifier: BSD-3-Clause
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/format/formatters.dart';
import '../../../core/layout/adaptive.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_tokens.dart';
import '../../../data/models/expense.dart';
import '../../../data/models/expense_filter.dart';
import '../../../data/models/payment_method.dart';
import '../../../data/models/trip.dart';
import '../../../data/services/analytics.dart';
import '../../../state/app_state.dart';
import '../../widgets/aurora_app_bar.dart';
import '../../widgets/aurora_widgets.dart';
import '../trips/trips_page.dart';
import 'category_expenses_page.dart';
import 'charts.dart';

/// Предустановленные периоды дашборда.
enum DashboardPeriod {
  currentMonth('Текущий месяц'),
  threeMonths('3 месяца'),
  sixMonths('6 месяцев'),
  year('Текущий год'),
  all('Всё время'),
  custom('Период');

  const DashboardPeriod(this.label);

  final String label;
}

/// Дашборд с тратами: распределение по месяцам, категориям и командировкам.
class DashboardPage extends StatefulWidget {
  const DashboardPage({this.leading, super.key});

  final Widget? leading;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  DashboardPeriod _period = DashboardPeriod.sixMonths;
  ChartKind _chartKind = ChartKind.pie;
  DateRange? _customRange;

  DateRange? get _range {
    final DateTime now = DateTime.now();
    return switch (_period) {
      DashboardPeriod.currentMonth => DateRange.month(now),
      DashboardPeriod.threeMonths => DateRange.lastMonths(now, 3),
      DashboardPeriod.sixMonths => DateRange.lastMonths(now, 6),
      DashboardPeriod.year => DateRange.year(now),
      DashboardPeriod.all => null,
      DashboardPeriod.custom => _customRange,
    };
  }

  /// Период в коротком виде.
  String get _periodLabelShort {
    final DateRange? range = _range;
    if (range == null) {
      return 'Всё время';
    }
    return Formatters.rangeShort(range.start, range.end);
  }

  Future<void> _pickPeriod(DashboardPeriod period) async {
    if (period != DashboardPeriod.custom) {
      setState(() => _period = period);
      return;
    }
    final DateTime now = DateTime.now();
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5),
      initialDateRange: _customRange == null
          ? null
          : DateTimeRange(start: _customRange!.start, end: _customRange!.end),
      helpText: 'Период дашборда',
      saveText: 'Готово',
    );
    if (picked != null) {
      setState(() {
        _customRange = DateRange(picked.start, picked.end);
        _period = DashboardPeriod.custom;
      });
    }
  }

  void _openCategory(String categoryId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CategoryExpensesPage(
          categoryId: categoryId,
          range: _range,
          periodLabel: _periodLabelShort,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppState state = context.watch<AppState>();
    final DateRange? range = _range;
    final double margin = AuroraLayout.pageMargin(context);

    final List<Expense> expenses = state.allExpenses
        .where((Expense expense) => range?.contains(expense.date) ?? true)
        .toList();

    final double total = ExpenseAnalytics.total(expenses);
    final List<MonthTotal> byMonth = ExpenseAnalytics.byMonth(
      expenses,
      range: range,
    );
    final List<CategoryTotal> byCategory = ExpenseAnalytics.byCategory(
      expenses,
    );
    final List<TripTotal> byTrip = ExpenseAnalytics.byTrip(expenses);
    final Map<PaymentMethod, double> byMethod =
        ExpenseAnalytics.byPaymentMethod(expenses);

    String nameOf(String categoryId) =>
        state.categoryById(categoryId)?.name ?? 'Без категории';
    Color colorOf(String categoryId) => AuroraPalette.chartColorAt(
      state.categoryById(categoryId)?.colorIndex ?? 0,
    );

    final List<Widget> sections = <Widget>[
      _StatsRow(expenses: expenses, total: total),
      AuroraSection(
        title: 'Расходы по месяцам',
        subtitle: 'Нажатие на столбец открывает месяц целиком',
        child: MonthlyBarChart(
          totals: byMonth,
          onMonthSelected: (MonthTotal item) => setState(() {
            _customRange = DateRange.month(item.month);
            _period = DashboardPeriod.custom;
          }),
        ),
      ),
      AuroraSection(
        title: 'Распределение по категориям',
        subtitle: 'Нажмите категорию, чтобы увидеть её траты',
        trailing: _ChartKindToggle(
          current: _chartKind,
          onChanged: (ChartKind kind) => setState(() => _chartKind = kind),
        ),
        child: Column(
          children: <Widget>[
            if (_chartKind == ChartKind.pie) ...<Widget>[
              CategoryPieChart(
                totals: byCategory,
                nameOf: nameOf,
                colorOf: colorOf,
                onSelected: (CategoryTotal item) =>
                    _openCategory(item.categoryId),
              ),
              const SizedBox(height: AuroraSizes.paddingMedium),
              ChartLegend(
                totals: byCategory,
                nameOf: nameOf,
                colorOf: colorOf,
                onSelected: (CategoryTotal item) =>
                    _openCategory(item.categoryId),
              ),
            ] else
              CategoryBars(
                totals: byCategory,
                nameOf: nameOf,
                colorOf: colorOf,
                onSelected: (CategoryTotal item) =>
                    _openCategory(item.categoryId),
              ),
          ],
        ),
      ),
      AuroraSection(
        title: 'Распределение по командировкам',
        subtitle: 'Служебные расходы за период',
        child: _TripBreakdown(totals: byTrip, total: total),
      ),
      AuroraSection(
        title: 'Способы оплаты',
        child: _PaymentBreakdown(totals: byMethod, total: total),
      ),
    ];

    return Scaffold(
      appBar: AuroraAppBar(
        title: 'Дашборд',
        subtitle: '$_periodLabelShort · ${Formatters.money(total)}',
        leading: widget.leading,
        actions: <Widget>[
          _PeriodButton(current: _period, onSelected: _pickPeriod),
        ],
      ),
      body: expenses.isEmpty
          ? const AuroraEmptyState(
              icon: Icons.insights_outlined,
              title: 'Нет данных',
              message:
                  'За выбранный период трат нет. '
                  'Измените период или добавьте траты.',
            )
          : ListView(
              padding: EdgeInsets.fromLTRB(
                margin,
                AuroraSizes.paddingMedium,
                margin,
                AuroraSizes.paddingLarge,
              ),
              children: AuroraLayout.dashboardColumns(context) >= 2
                  ? <Widget>[_TwoColumnLayout(sections: sections)]
                  : <Widget>[
                      for (final Widget section in sections)
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: AuroraSizes.paddingMedium,
                          ),
                          child: section,
                        ),
                    ],
            ),
    );
  }
}

/// Раскладка дашборда в две колонки для планшета.
class _TwoColumnLayout extends StatelessWidget {
  const _TwoColumnLayout({required this.sections});

  final List<Widget> sections;

  @override
  Widget build(BuildContext context) {
    final List<Widget> left = <Widget>[];
    final List<Widget> right = <Widget>[];
    for (int index = 0; index < sections.length; index++) {
      (index.isEven ? left : right).add(
        Padding(
          padding: const EdgeInsets.only(bottom: AuroraSizes.paddingMedium),
          child: sections[index],
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(child: Column(children: left)),
        const SizedBox(width: AuroraSizes.paddingMedium),
        Expanded(child: Column(children: right)),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.expenses, required this.total});

  final List<Expense> expenses;
  final double total;

  @override
  Widget build(BuildContext context) {
    final AuroraPalette palette = context.palette;
    final Expense? largest = ExpenseAnalytics.largest(expenses);

    return Row(
      children: <Widget>[
        Expanded(
          child: AuroraStatTile(
            label: 'Всего',
            value: Formatters.money(total),
            icon: Icons.account_balance_wallet_outlined,
          ),
        ),
        const SizedBox(width: AuroraSizes.paddingMedium),
        Expanded(
          child: AuroraStatTile(
            label: 'Средняя',
            value: Formatters.money(ExpenseAnalytics.average(expenses)),
            icon: Icons.stacked_line_chart,
            accent: palette.success,
          ),
        ),
        const SizedBox(width: AuroraSizes.paddingMedium),
        Expanded(
          child: AuroraStatTile(
            label: 'Максимум',
            value: largest == null ? '—' : Formatters.money(largest.amount),
            icon: Icons.trending_up,
            accent: palette.warning,
          ),
        ),
      ],
    );
  }
}

class _TripBreakdown extends StatelessWidget {
  const _TripBreakdown({required this.totals, required this.total});

  final List<TripTotal> totals;
  final double total;

  @override
  Widget build(BuildContext context) {
    final AppState state = context.watch<AppState>();
    final TextTheme text = Theme.of(context).textTheme;
    final AuroraPalette palette = context.palette;

    if (totals.isEmpty) {
      return Text('Нет данных за период', style: text.bodySmall);
    }

    return Column(
      children: <Widget>[
        for (final TripTotal item in totals)
          Builder(
            builder: (BuildContext context) {
              final Trip? trip = state.tripById(item.tripId);
              final double share = total == 0 ? 0 : item.total / total;
              return Material(
                color: Colors.transparent,
                borderRadius: AuroraRadius.small,
                child: InkWell(
                  onTap: trip == null
                      ? null
                      : () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => TripDetailsPage(tripId: trip.id),
                          ),
                        ),
                  borderRadius: AuroraRadius.small,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AuroraSizes.paddingSmall,
                      horizontal: AuroraSizes.paddingSmall,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Icon(
                              trip == null
                                  ? Icons.person_outline
                                  : Icons.work_outline,
                              size: AuroraSizes.iconSizeSmall,
                              color: trip == null
                                  ? palette.textSecondary
                                  : palette.accent,
                            ),
                            const SizedBox(width: AuroraSizes.paddingMedium),
                            Expanded(
                              child: Text(
                                trip?.title ?? 'Вне командировок',
                                style: text.bodyMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              Formatters.money(item.total),
                              style: text.bodyMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: AuroraSizes.paddingSmall),
                        ClipRRect(
                          borderRadius: AuroraRadius.small,
                          child: LinearProgressIndicator(
                            value: share,
                            minHeight: 8,
                            backgroundColor: palette.surfaceVariant,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              trip == null
                                  ? palette.textSecondary
                                  : palette.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _PaymentBreakdown extends StatelessWidget {
  const _PaymentBreakdown({required this.totals, required this.total});

  final Map<PaymentMethod, double> totals;
  final double total;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final AuroraPalette palette = context.palette;

    if (totals.isEmpty) {
      return Text('Нет данных за период', style: text.bodySmall);
    }

    return Column(
      children: <Widget>[
        for (final PaymentMethod method in PaymentMethod.values)
          if (totals[method] != null)
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AuroraSizes.paddingSmall,
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    method.icon,
                    size: AuroraSizes.iconSizeSmall,
                    color: palette.textSecondary,
                  ),
                  const SizedBox(width: AuroraSizes.paddingMedium),
                  Expanded(
                    flex: 3,
                    child: Text(
                      method.label,
                      style: text.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AuroraSizes.paddingSmall),
                  Expanded(
                    flex: 2,
                    child: Text(
                      Formatters.money(totals[method]!),
                      style: text.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                    ),
                  ),
                  const SizedBox(width: AuroraSizes.paddingSmall),
                  Text(
                    total == 0
                        ? '0%'
                        : '${(totals[method]! / total * 100).round()}%',
                    style: text.bodySmall,
                    maxLines: 1,
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

class _ChartKindToggle extends StatelessWidget {
  const _ChartKindToggle({required this.current, required this.onChanged});

  final ChartKind current;
  final ValueChanged<ChartKind> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      for (final ChartKind kind in ChartKind.values)
        AuroraIconButton(
          icon: kind.icon,
          tooltip: '${kind.label} диаграмма',
          selected: kind == current,
          onPressed: () => onChanged(kind),
        ),
    ],
  );
}

class _PeriodButton extends StatelessWidget {
  const _PeriodButton({required this.current, required this.onSelected});

  final DashboardPeriod current;
  final ValueChanged<DashboardPeriod> onSelected;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: AuroraSizes.itemSizeExtraSmall,
    height: AuroraSizes.itemSizeExtraSmall,
    child: PopupMenuButton<DashboardPeriod>(
      tooltip: 'Период',
      icon: const Icon(Icons.date_range),
      iconSize: AuroraSizes.iconSizeSmallPlus,
      color: context.palette.surface,
      shape: RoundedRectangleBorder(borderRadius: AuroraRadius.medium),
      onSelected: onSelected,
      itemBuilder: (BuildContext context) => <PopupMenuEntry<DashboardPeriod>>[
        for (final DashboardPeriod period in DashboardPeriod.values)
          PopupMenuItem<DashboardPeriod>(
            value: period,
            height: AuroraSizes.itemSizeExtraSmall,
            child: Row(
              children: <Widget>[
                Icon(
                  period == current ? Icons.check : Icons.remove,
                  size: AuroraSizes.iconSizeSmall,
                  color: period == current
                      ? context.palette.accent
                      : Colors.transparent,
                ),
                const SizedBox(width: AuroraSizes.paddingMedium),
                Text(
                  period.label,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
      ],
    ),
  );
}
