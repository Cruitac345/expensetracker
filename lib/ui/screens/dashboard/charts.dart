// SPDX-License-Identifier: BSD-3-Clause
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/format/formatters.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_tokens.dart';
import '../../../data/services/analytics.dart';

/// Вид диаграммы распределения трат.
enum ChartKind {
  bar('Столбчатая', Icons.bar_chart),
  pie('Круговая', Icons.pie_chart_outline);

  const ChartKind(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// Столбчатая диаграмма распределения трат по месяцам.
class MonthlyBarChart extends StatelessWidget {
  const MonthlyBarChart({
    required this.totals,
    this.onMonthSelected,
    super.key,
  });

  final List<MonthTotal> totals;
  final ValueChanged<MonthTotal>? onMonthSelected;

  @override
  Widget build(BuildContext context) {
    final AuroraPalette palette = context.palette;
    final TextTheme text = Theme.of(context).textTheme;

    if (totals.isEmpty) {
      return _ChartPlaceholder(message: 'Нет данных за выбранный период');
    }

    final double maxValue = totals
        .map((MonthTotal item) => item.total)
        .reduce((double a, double b) => a > b ? a : b);

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxValue == 0 ? 1 : maxValue * 1.2,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxValue == 0 ? 1 : maxValue / 2,
            getDrawingHorizontalLine: (double value) =>
                FlLine(color: palette.divider, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 66,
                interval: maxValue == 0 ? 1 : maxValue / 2,
                getTitlesWidget: (double value, TitleMeta meta) => Padding(
                  padding: const EdgeInsets.only(
                    right: AuroraSizes.paddingSmall,
                  ),
                  child: Text(
                    value == 0 ? '0' : Formatters.compactNumber(value),
                    style: text.bodySmall,
                    maxLines: 1,
                    textAlign: TextAlign.right,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (double value, TitleMeta meta) {
                  final int index = value.toInt();
                  if (index < 0 || index >= totals.length) {
                    return const SizedBox.shrink();
                  }
                  final DateTime month = totals[index].month;
                  return Padding(
                    padding: const EdgeInsets.only(
                      top: AuroraSizes.paddingSmall,
                    ),
                    child: Text(
                      totals.length > 6
                          ? Formatters.monthShort(month)
                          : '${Formatters.monthShort(month)}\n${month.year}',
                      style: text.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (BarChartGroupData group) =>
                  palette.surfaceVariant,
              getTooltipItem:
                  (
                    BarChartGroupData group,
                    int groupIndex,
                    BarChartRodData rod,
                    int rodIndex,
                  ) {
                    final MonthTotal item = totals[group.x];
                    return BarTooltipItem(
                      '${Formatters.monthYear(item.month)}\n'
                      '${Formatters.money(item.total)}',
                      text.bodySmall!.copyWith(color: palette.textPrimary),
                    );
                  },
            ),
            touchCallback: (FlTouchEvent event, BarTouchResponse? response) {
              if (!event.isInterestedForInteractions ||
                  response?.spot == null ||
                  onMonthSelected == null) {
                return;
              }
              onMonthSelected!(totals[response!.spot!.touchedBarGroupIndex]);
            },
          ),
          barGroups: <BarChartGroupData>[
            for (int index = 0; index < totals.length; index++)
              BarChartGroupData(
                x: index,
                barRods: <BarChartRodData>[
                  BarChartRodData(
                    toY: totals[index].total,
                    width: totals.length > 8 ? 12 : 20,
                    color: palette.accentFill,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(AuroraSizes.paddingSmall),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Круговая диаграмма распределения трат по категориям.
class CategoryPieChart extends StatelessWidget {
  const CategoryPieChart({
    required this.totals,
    required this.nameOf,
    required this.colorOf,
    this.onSelected,
    super.key,
  });

  final List<CategoryTotal> totals;
  final String Function(String categoryId) nameOf;
  final Color Function(String categoryId) colorOf;
  final ValueChanged<CategoryTotal>? onSelected;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    if (totals.isEmpty) {
      return _ChartPlaceholder(message: 'Нет данных за выбранный период');
    }

    return SizedBox(
      height: 240,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 56,
          pieTouchData: PieTouchData(
            touchCallback: (FlTouchEvent event, PieTouchResponse? response) {
              if (!event.isInterestedForInteractions ||
                  response?.touchedSection == null ||
                  onSelected == null) {
                return;
              }
              final int index =
                  response!.touchedSection!.touchedSectionIndex;
              if (index >= 0 && index < totals.length) {
                onSelected!(totals[index]);
              }
            },
          ),
          sections: <PieChartSectionData>[
            for (final CategoryTotal item in totals)
              PieChartSectionData(
                value: item.total,
                color: colorOf(item.categoryId),
                radius: 56,
                title: item.share >= 0.07
                    ? '${(item.share * 100).round()}%'
                    : '',
                titleStyle: text.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                showTitle: true,
              ),
          ],
        ),
      ),
    );
  }
}

/// Горизонтальные столбцы распределения по категориям с подписями.
class CategoryBars extends StatelessWidget {
  const CategoryBars({
    required this.totals,
    required this.nameOf,
    required this.colorOf,
    this.onSelected,
    super.key,
  });

  final List<CategoryTotal> totals;
  final String Function(String categoryId) nameOf;
  final Color Function(String categoryId) colorOf;
  final ValueChanged<CategoryTotal>? onSelected;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    if (totals.isEmpty) {
      return _ChartPlaceholder(message: 'Нет данных за выбранный период');
    }

    final double maxValue = totals.first.total;

    return Column(
      children: <Widget>[
        for (final CategoryTotal item in totals)
          Material(
            color: Colors.transparent,
            borderRadius: AuroraRadius.small,
            child: InkWell(
              onTap: onSelected == null ? null : () => onSelected!(item),
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
                        Expanded(
                          child: Text(
                            nameOf(item.categoryId),
                            style: text.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AuroraSizes.paddingSmall),
                        Flexible(
                          child: Text(
                            Formatters.money(item.total),
                            style: text.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AuroraSizes.paddingSmall),
                        Flexible(
                          child: Text(
                            '${(item.share * 100).round()}%',
                            style: text.bodySmall,
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AuroraSizes.paddingSmall),
                    ClipRRect(
                      borderRadius: AuroraRadius.small,
                      child: LinearProgressIndicator(
                        value: maxValue == 0 ? 0 : item.total / maxValue,
                        minHeight: 8,
                        backgroundColor: context.palette.surfaceVariant,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colorOf(item.categoryId),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Легенда диаграммы: цвет, название, сумма и доля.
class ChartLegend extends StatelessWidget {
  const ChartLegend({
    required this.totals,
    required this.nameOf,
    required this.colorOf,
    this.onSelected,
    super.key,
  });

  final List<CategoryTotal> totals;
  final String Function(String categoryId) nameOf;
  final Color Function(String categoryId) colorOf;
  final ValueChanged<CategoryTotal>? onSelected;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return Column(
      children: <Widget>[
        for (final CategoryTotal item in totals)
          Material(
            color: Colors.transparent,
            borderRadius: AuroraRadius.small,
            child: InkWell(
              onTap: onSelected == null ? null : () => onSelected!(item),
              borderRadius: AuroraRadius.small,
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: AuroraSizes.itemSizeExtraSmall,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AuroraSizes.paddingSmall,
                  vertical: AuroraSizes.paddingSmall,
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: AuroraSizes.paddingMedium + AuroraSizes.module,
                      height: AuroraSizes.paddingMedium + AuroraSizes.module,
                      decoration: BoxDecoration(
                        color: colorOf(item.categoryId),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AuroraSizes.paddingMedium),
                    Expanded(
                      flex: 3,
                      child: Text(
                        nameOf(item.categoryId),
                        style: text.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AuroraSizes.paddingSmall),
                    Expanded(
                      flex: 2,
                      child: Text(
                        Formatters.money(item.total),
                        style: text.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                    ),
                    const SizedBox(width: AuroraSizes.paddingSmall),
                    Flexible(
                      child: Text(
                        '${(item.share * 100).round()}%',
                        style: text.bodySmall,
                        textAlign: TextAlign.right,
                      ),
                    ),
                    if (onSelected != null)
                      Icon(
                        Icons.chevron_right,
                        size: AuroraSizes.iconSizeSmall,
                        color: context.palette.textSecondary,
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ChartPlaceholder extends StatelessWidget {
  const _ChartPlaceholder({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    height: AuroraSizes.itemSizeLarge,
    alignment: Alignment.center,
    child: Text(message, style: Theme.of(context).textTheme.bodySmall),
  );
}
