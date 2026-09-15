// SPDX-License-Identifier: BSD-3-Clause
import 'package:flutter/material.dart';

import '../../core/format/formatters.dart';
import '../../core/theme/aurora_colors.dart';
import '../../core/theme/aurora_tokens.dart';
import '../../data/models/expense.dart';
import '../../data/models/expense_category.dart';
import '../../data/models/trip.dart';
import 'aurora_widgets.dart';

/// Элемент списка трат.
///
/// Высота элемента не меньше `itemSizeMedium` (80dp) — требование к размеру
/// целей нажатия в гайдлайне ОС Аврора.
class ExpenseListItem extends StatelessWidget {
  const ExpenseListItem({
    required this.expense,
    required this.category,
    this.trip,
    this.onTap,
    this.onLongPress,
    this.selected = false,
    this.showDate = true,
    super.key,
  });

  final Expense expense;
  final ExpenseCategory? category;
  final Trip? trip;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool selected;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final AuroraPalette palette = context.palette;
    final TextTheme text = Theme.of(context).textTheme;

    final String title = expense.payee.isNotEmpty
        ? expense.payee
        : category?.name ?? 'Без категории';
    final List<String> details = <String>[
      if (expense.payee.isNotEmpty) category?.name ?? 'Без категории',
      if (expense.comment.isNotEmpty) expense.comment,
    ];

    return Material(
      color: selected
          ? palette.accent.withValues(alpha: 0.12)
          : palette.surface,
      borderRadius: AuroraRadius.medium,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: AuroraRadius.medium,
        child: Container(
          constraints: const BoxConstraints(
            minHeight: AuroraSizes.itemSizeMedium,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AuroraSizes.paddingMedium,
            vertical: AuroraSizes.paddingMedium,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              CategoryAvatar(category: category),
              const SizedBox(width: AuroraSizes.paddingMedium),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      title,
                      style: text.bodyLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (details.isNotEmpty)
                      Text(
                        details.join(' · '),
                        style: text.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (trip != null || expense.hasReceipts)
                      Padding(
                        padding: const EdgeInsets.only(
                          top: AuroraSizes.paddingSmall,
                        ),
                        child: Wrap(
                          spacing: AuroraSizes.paddingSmall,
                          runSpacing: AuroraSizes.paddingSmall,
                          children: <Widget>[
                            if (trip != null)
                              AuroraTag(
                                label: trip!.title,
                                icon: Icons.work_outline,
                                color: palette.accent,
                              ),
                            if (expense.hasReceipts)
                              AuroraTag(
                                label: '${expense.receiptPaths.length}',
                                icon: Icons.receipt_long_outlined,
                                color: palette.success,
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AuroraSizes.paddingMedium),
              // Доли 3:2 не дают сумме «съесть» строку на узких экранах.
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        Formatters.money(expense.amount),
                        maxLines: 1,
                        style: text.titleMedium?.copyWith(
                          fontWeight: AuroraFontWeights.medium,
                        ),
                      ),
                    ),
                    const SizedBox(height: AuroraSizes.paddingSmall),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        Icon(
                          expense.paymentMethod.icon,
                          size: AuroraSizes.iconSizeExtraSmall,
                          color: palette.textSecondary,
                        ),
                        if (showDate) ...<Widget>[
                          const SizedBox(width: AuroraSizes.paddingSmall),
                          Flexible(
                            child: Text(
                              Formatters.date(expense.date),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.bodySmall,
                            ),
                          ),
                        ],
                      ],
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
}
