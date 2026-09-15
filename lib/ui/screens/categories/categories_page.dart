// SPDX-License-Identifier: BSD-3-Clause
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/format/formatters.dart';
import '../../../core/layout/adaptive.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_tokens.dart';
import '../../../data/models/category_icons.dart';
import '../../../data/models/expense_category.dart';
import '../../../data/services/analytics.dart';
import '../../../state/app_state.dart';
import '../../widgets/aurora_app_bar.dart';
import '../../widgets/aurora_widgets.dart';

/// Категории трат.
///
/// Стандартные категории из технического задания защищены от изменения и
/// удаления, пользовательские можно создавать, редактировать и удалять.
class CategoriesPage extends StatelessWidget {
  const CategoriesPage({this.leading, super.key});

  final Widget? leading;

  Future<void> _edit(BuildContext context, {ExpenseCategory? category}) async {
    final AppState state = context.read<AppState>();
    final _CategoryDraft? draft = await showModalBottomSheet<_CategoryDraft>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => _CategoryForm(
        category: category,
        defaultColorIndex: state.categories.length,
      ),
    );
    if (draft == null) {
      return;
    }
    if (category == null) {
      await state.addCategory(
        name: draft.name,
        iconKey: draft.iconKey,
        colorIndex: draft.colorIndex,
      );
    } else {
      await state.updateCategory(
        category.copyWith(
          name: draft.name,
          iconKey: draft.iconKey,
          colorIndex: draft.colorIndex,
        ),
      );
    }
  }

  Future<void> _delete(BuildContext context, ExpenseCategory category) async {
    final AppState state = context.read<AppState>();
    final int count = state.expenseCountOfCategory(category.id);

    if (count == 0) {
      final bool confirmed = await auroraConfirm(
        context,
        title: 'Удалить категорию?',
        message: 'Категория «${category.name}» будет удалена.',
      );
      if (confirmed) {
        await state.deleteCategory(category.id);
      }
      return;
    }

    if (!context.mounted) {
      return;
    }

    final List<ExpenseCategory> replacements = state.categories
        .where((ExpenseCategory item) => item.id != category.id)
        .toList();

    final String? choice = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Удалить категорию?'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'В категории «${category.name}» '
                '${Formatters.plural(count, 'трата', 'траты', 'трат')}. '
                'Выберите категорию, в которую их перенести, '
                'или удалите вместе с тратами.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AuroraSizes.paddingMedium),
              for (final ExpenseCategory item in replacements)
                ListTile(
                  leading: CategoryAvatar(
                    category: item,
                    size: AuroraSizes.iconSizeSmall,
                  ),
                  title: Text(item.name),
                  onTap: () => Navigator.of(context).pop(item.id),
                ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('__delete__'),
            style: TextButton.styleFrom(
              foregroundColor: context.palette.danger,
            ),
            child: const Text('Удалить с тратами'),
          ),
        ],
      ),
    );

    if (choice == null) {
      return;
    }
    await state.deleteCategory(
      category.id,
      replacementId: choice == '__delete__' ? null : choice,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppState state = context.watch<AppState>();
    final double margin = AuroraLayout.pageMargin(context);
    final List<ExpenseCategory> builtIn = state.categories
        .where((ExpenseCategory category) => category.isBuiltIn)
        .toList();
    final List<ExpenseCategory> custom = state.customCategories;

    return Scaffold(
      appBar: AuroraAppBar(
        title: 'Категории',
        subtitle:
            '${builtIn.length} стандартных · '
            '${Formatters.plural(custom.length, 'своя', 'свои', 'своих')}',
        leading: leading,
        actions: <Widget>[
          AuroraIconButton(
            icon: Icons.add,
            tooltip: 'Новая категория',
            onPressed: () => _edit(context),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          margin,
          AuroraSizes.paddingMedium,
          margin,
          AuroraSizes.paddingLarge,
        ),
        children: <Widget>[
          Text('Стандартные', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AuroraSizes.paddingSmall),
          for (final ExpenseCategory category in builtIn)
            _CategoryTile(
              category: category,
              count: state.expenseCountOfCategory(category.id),
              total: ExpenseAnalytics.total(
                state.expensesOfCategory(category.id),
              ),
            ),
          const SizedBox(height: AuroraSizes.paddingLarge),
          Text('Собственные', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AuroraSizes.paddingSmall),
          if (custom.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AuroraSizes.paddingMedium,
              ),
              child: Text(
                'Своих категорий пока нет. Добавьте их кнопкой «+» '
                'в панели приложения.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            )
          else
            for (final ExpenseCategory category in custom)
              _CategoryTile(
                category: category,
                count: state.expenseCountOfCategory(category.id),
                total: ExpenseAnalytics.total(
                  state.expensesOfCategory(category.id),
                ),
                onEdit: () => _edit(context, category: category),
                onDelete: () => _delete(context, category),
              ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.count,
    required this.total,
    this.onEdit,
    this.onDelete,
  });

  final ExpenseCategory category;
  final int count;
  final double total;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AuroraSizes.paddingSmall),
      child: Material(
        color: context.palette.surface,
        borderRadius: AuroraRadius.medium,
        child: InkWell(
          onTap: onEdit,
          borderRadius: AuroraRadius.medium,
          child: Container(
            constraints: const BoxConstraints(
              minHeight: AuroraSizes.itemSizeSmall,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AuroraSizes.paddingMedium,
              vertical: AuroraSizes.paddingSmall,
            ),
            child: Row(
              children: <Widget>[
                CategoryAvatar(category: category),
                const SizedBox(width: AuroraSizes.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(category.name, style: text.bodyLarge),
                      Text(
                        count == 0
                            ? 'Нет трат'
                            : '${Formatters.plural(count, 'трата', 'траты', 'трат')} '
                                  'на ${Formatters.money(total)}',
                        style: text.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (onEdit != null)
                  AuroraIconButton(
                    icon: Icons.edit_outlined,
                    tooltip: 'Изменить',
                    onPressed: onEdit,
                  ),
                if (onDelete != null)
                  AuroraIconButton(
                    icon: Icons.delete_outline,
                    tooltip: 'Удалить',
                    onPressed: onDelete,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryDraft {
  const _CategoryDraft({
    required this.name,
    required this.iconKey,
    required this.colorIndex,
  });

  final String name;
  final String iconKey;
  final int colorIndex;
}

class _CategoryForm extends StatefulWidget {
  const _CategoryForm({required this.defaultColorIndex, this.category});

  final ExpenseCategory? category;
  final int defaultColorIndex;

  @override
  State<_CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends State<_CategoryForm> {
  late final TextEditingController _nameController;
  late String _iconKey;
  late int _colorIndex;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _iconKey = widget.category?.iconKey ?? CategoryIcons.fallbackKey;
    _colorIndex = widget.category?.colorIndex ?? widget.defaultColorIndex;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final String name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Введите название категории');
      return;
    }
    Navigator.of(context).pop(
      _CategoryDraft(name: name, iconKey: _iconKey, colorIndex: _colorIndex),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AuroraSizes.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                widget.category == null
                    ? 'Новая категория'
                    : 'Изменение категории',
                style: text.titleLarge,
              ),
              const SizedBox(height: AuroraSizes.paddingLarge),
              TextField(
                controller: _nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Название',
                  errorText: _error,
                ),
                onChanged: (_) {
                  if (_error != null) {
                    setState(() => _error = null);
                  }
                },
              ),
              const SizedBox(height: AuroraSizes.paddingLarge),
              Text('Иконка', style: text.titleSmall),
              const SizedBox(height: AuroraSizes.paddingMedium),
              Wrap(
                spacing: AuroraSizes.paddingSmall,
                runSpacing: AuroraSizes.paddingSmall,
                children: <Widget>[
                  for (final String key in CategoryIcons.keys)
                    _PickerCell(
                      selected: key == _iconKey,
                      color: AuroraPalette.chartColorAt(_colorIndex),
                      onTap: () => setState(() => _iconKey = key),
                      child: Icon(
                        CategoryIcons.byKey(key),
                        size: AuroraSizes.iconSizeSmall,
                        color: key == _iconKey
                            ? context.palette.onAccentFill
                            : context.palette.textSecondary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AuroraSizes.paddingLarge),
              Text('Цвет', style: text.titleSmall),
              const SizedBox(height: AuroraSizes.paddingMedium),
              Wrap(
                spacing: AuroraSizes.paddingSmall,
                runSpacing: AuroraSizes.paddingSmall,
                children: <Widget>[
                  for (
                    int index = 0;
                    index < AuroraPalette.chart.length;
                    index++
                  )
                    _PickerCell(
                      selected:
                          index == _colorIndex % AuroraPalette.chart.length,
                      color: AuroraPalette.chartColorAt(index),
                      onTap: () => setState(() => _colorIndex = index),
                      child: Container(
                        width: AuroraSizes.iconSizeSmall,
                        height: AuroraSizes.iconSizeSmall,
                        decoration: BoxDecoration(
                          color: AuroraPalette.chartColorAt(index),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AuroraSizes.paddingLarge),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Отмена'),
                    ),
                  ),
                  const SizedBox(width: AuroraSizes.paddingMedium),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Сохранить'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickerCell extends StatelessWidget {
  const _PickerCell({
    required this.selected,
    required this.color,
    required this.onTap,
    required this.child,
  });

  final bool selected;
  final Color color;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? color : context.palette.surfaceVariant,
    borderRadius: AuroraRadius.small,
    child: InkWell(
      onTap: onTap,
      borderRadius: AuroraRadius.small,
      child: SizedBox(
        width: AuroraSizes.itemSizeExtraSmall,
        height: AuroraSizes.itemSizeExtraSmall,
        child: Center(child: child),
      ),
    ),
  );
}
