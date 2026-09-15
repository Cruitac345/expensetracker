// SPDX-License-Identifier: BSD-3-Clause
import 'package:flutter/material.dart';

import '../../core/theme/aurora_colors.dart';
import '../../core/theme/aurora_tokens.dart';
import '../../data/models/category_icons.dart';
import '../../data/models/expense_category.dart';

/// Заглушка пустого экрана: иконка, заголовок, пояснение и действие.
class AuroraEmptyState extends StatelessWidget {
  const AuroraEmptyState({
    required this.icon,
    required this.title,
    this.message,
    this.action,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final AuroraPalette palette = context.palette;
    final TextTheme text = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AuroraSizes.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              icon,
              size: AuroraSizes.iconSizeLarge,
              color: palette.textSecondary,
            ),
            const SizedBox(height: AuroraSizes.paddingLarge),
            Text(title, style: text.titleLarge, textAlign: TextAlign.center),
            if (message != null) ...<Widget>[
              const SizedBox(height: AuroraSizes.paddingMedium),
              Text(
                message!,
                style: text.bodyMedium?.copyWith(color: palette.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...<Widget>[
              const SizedBox(height: AuroraSizes.paddingLarge),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Блок содержимого с заголовком и действием — основной строительный элемент
/// дашборда и страниц деталей.
class AuroraSection extends StatelessWidget {
  const AuroraSection({
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.all(AuroraSizes.paddingMedium),
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(title, style: text.titleMedium),
                      if (subtitle != null)
                        Text(subtitle!, style: text.bodySmall),
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: AuroraSizes.paddingMedium),
            child,
          ],
        ),
      ),
    );
  }
}

/// Плитка с числовым показателем.
class AuroraStatTile extends StatelessWidget {
  const AuroraStatTile({
    required this.label,
    required this.value,
    this.icon,
    this.accent,
    super.key,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final AuroraPalette palette = context.palette;
    final TextTheme text = Theme.of(context).textTheme;
    final Color color = accent ?? palette.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AuroraSizes.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  Icon(icon, size: AuroraSizes.iconSizeExtraSmall, color: color),
                  const SizedBox(width: AuroraSizes.paddingSmall),
                ],
                Expanded(
                  child: Text(
                    label,
                    style: text.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AuroraSizes.paddingSmall),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: text.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Круглый значок категории с её иконкой и цветом.
class CategoryAvatar extends StatelessWidget {
  const CategoryAvatar({
    required this.category,
    this.size = AuroraSizes.itemSizeExtraSmall,
    super.key,
  });

  final ExpenseCategory? category;
  final double size;

  @override
  Widget build(BuildContext context) {
    final Color color = category == null
        ? context.palette.textSecondary
        : AuroraPalette.chartColorAt(category!.colorIndex);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(
        CategoryIcons.byKey(category?.iconKey),
        size: size * 0.5,
        color: color,
      ),
    );
  }
}

/// Подпись-метка (чип) для набора значений: способ оплаты, командировка и т. п.
class AuroraTag extends StatelessWidget {
  const AuroraTag({required this.label, this.icon, this.color, super.key});

  final String label;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final AuroraPalette palette = context.palette;
    final Color tint = color ?? palette.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AuroraSizes.paddingMedium,
        vertical: AuroraSizes.paddingSmall,
      ),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: AuroraRadius.large,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 14, color: tint),
            const SizedBox(width: AuroraSizes.paddingSmall),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: tint),
            ),
          ),
        ],
      ),
    );
  }
}

/// Диалог подтверждения необратимого действия.
Future<bool> auroraConfirm(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Удалить',
  String cancelLabel = 'Отмена',
  bool destructive = true,
}) async {
  final AuroraPalette palette = context.palette;
  final bool? result = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(
            foregroundColor: destructive ? palette.danger : palette.primary,
          ),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Показывает короткое сообщение внизу экрана.
void auroraNotify(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
