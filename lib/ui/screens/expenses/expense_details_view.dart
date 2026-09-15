// SPDX-License-Identifier: BSD-3-Clause
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/format/formatters.dart';
import '../../../core/layout/adaptive.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_tokens.dart';
import '../../../data/models/expense.dart';
import '../../../data/models/expense_category.dart';
import '../../../data/models/trip.dart';
import '../../../state/app_state.dart';
import '../../widgets/aurora_app_bar.dart';
import '../../widgets/aurora_widgets.dart';
import 'expense_form_page.dart';

/// Карточка траты: все поля, чеки и действия редактирования и удаления.
class ExpenseDetailsView extends StatelessWidget {
  const ExpenseDetailsView({
    required this.expenseId,
    this.onDeleted,
    super.key,
  });

  final String expenseId;

  /// Вызывается после удаления траты — панель деталей должна закрыться.
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context) {
    final AppState state = context.watch<AppState>();
    final AuroraPalette palette = context.palette;
    final TextTheme text = Theme.of(context).textTheme;

    final Expense? expense = state.allExpenses
        .cast<Expense?>()
        .firstWhere(
          (Expense? item) => item?.id == expenseId,
          orElse: () => null,
        );

    if (expense == null) {
      return const AuroraEmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'Трата не найдена',
        message: 'Возможно, она была удалена.',
      );
    }

    final ExpenseCategory? category = state.categoryById(expense.categoryId);
    final Trip? trip = state.tripById(expense.tripId);
    final double margin = AuroraLayout.pageMargin(context);

    return ListView(
      padding: EdgeInsets.fromLTRB(
        margin,
        AuroraSizes.paddingMedium,
        margin,
        AuroraSizes.paddingLarge,
      ),
      children: <Widget>[
        Row(
          children: <Widget>[
            CategoryAvatar(category: category, size: AuroraSizes.itemSizeSmall),
            const SizedBox(width: AuroraSizes.paddingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    Formatters.money(expense.amount),
                    style: text.headlineSmall,
                  ),
                  Text(
                    category?.name ?? 'Без категории',
                    style: text.titleSmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AuroraSizes.paddingLarge),
        _DetailRow(
          icon: Icons.event_outlined,
          label: 'Дата',
          value: Formatters.date(expense.date),
        ),
        _DetailRow(
          icon: Icons.storefront_outlined,
          label: 'Получатель платежа',
          value: expense.payee.isEmpty ? '—' : expense.payee,
        ),
        _DetailRow(
          icon: expense.paymentMethod.icon,
          label: 'Способ оплаты',
          value: expense.paymentMethod.label,
        ),
        _DetailRow(
          icon: Icons.work_outline,
          label: 'Командировка',
          value: trip?.title ?? 'Без командировки',
        ),
        _DetailRow(
          icon: Icons.notes_outlined,
          label: 'Комментарий',
          value: expense.comment.isEmpty ? '—' : expense.comment,
        ),
        const SizedBox(height: AuroraSizes.paddingLarge),
        Text('Чеки', style: text.titleSmall),
        const SizedBox(height: AuroraSizes.paddingMedium),
        if (expense.receiptPaths.isEmpty)
          Text('Чеки не прикреплены', style: text.bodySmall)
        else
          Wrap(
            spacing: AuroraSizes.paddingMedium,
            runSpacing: AuroraSizes.paddingMedium,
            children: <Widget>[
              for (final String path in expense.receiptPaths)
                ReceiptThumbnail(
                  path: path,
                  resolve: state.receiptStorage.resolve,
                  size: AuroraSizes.iconSizeLarge,
                ),
            ],
          ),
        const SizedBox(height: AuroraSizes.paddingLarge),
        Row(
          children: <Widget>[
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<Object?>(
                    builder: (_) => ExpenseFormPage(expense: expense),
                  ),
                ),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Изменить'),
              ),
            ),
            const SizedBox(width: AuroraSizes.paddingMedium),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final bool confirmed = await auroraConfirm(
                    context,
                    title: 'Удалить трату?',
                    message:
                        'Трата и прикреплённые к ней чеки будут удалены '
                        'без возможности восстановления.',
                  );
                  if (!confirmed || !context.mounted) {
                    return;
                  }
                  await state.deleteExpense(expense.id);
                  onDeleted?.call();
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('Удалить'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: palette.danger,
                  side: BorderSide(color: palette.danger),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Страница деталей траты для смартфона.
class ExpenseDetailsPage extends StatelessWidget {
  const ExpenseDetailsPage({required this.expenseId, super.key});

  final String expenseId;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AuroraAppBar(
      title: 'Трата',
      leading: AuroraIconButton(
        icon: Icons.arrow_back,
        tooltip: 'Назад',
        onPressed: () => Navigator.of(context).pop(),
      ),
    ),
    body: ExpenseDetailsView(
      expenseId: expenseId,
      onDeleted: () => Navigator.of(context).pop(),
    ),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final AuroraPalette palette = context.palette;
    final TextTheme text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AuroraSizes.paddingMedium),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            icon,
            size: AuroraSizes.iconSizeSmall,
            color: palette.textSecondary,
          ),
          const SizedBox(width: AuroraSizes.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(label, style: text.bodySmall),
                Text(value, style: text.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
