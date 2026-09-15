// SPDX-License-Identifier: BSD-3-Clause
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/format/formatters.dart';
import '../../../core/layout/adaptive.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_tokens.dart';
import '../../../data/models/expense.dart';
import '../../../data/models/expense_category.dart';
import '../../../data/models/payment_method.dart';
import '../../../data/models/trip.dart';
import '../../../state/app_state.dart';
import '../../widgets/aurora_app_bar.dart';
import '../../widgets/aurora_widgets.dart';

/// Создание и редактирование траты.
///
/// Поля соответствуют техническому заданию: сумма, категория, дата,
/// текстовый комментарий, получатель платежа, способ оплаты, командировка
/// и прикреплённые чеки.
class ExpenseFormPage extends StatefulWidget {
  const ExpenseFormPage({this.expense, this.initialTripId, super.key});

  /// Редактируемая трата. `null` — создание новой.
  final Expense? expense;

  /// Командировка, выбранная заранее (при добавлении траты из командировки).
  final String? initialTripId;

  @override
  State<ExpenseFormPage> createState() => _ExpenseFormPageState();
}

class _ExpenseFormPageState extends State<ExpenseFormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late final TextEditingController _amountController;
  late final TextEditingController _payeeController;
  late final TextEditingController _commentController;

  late String _categoryId;
  late DateTime _date;
  late PaymentMethod _paymentMethod;
  String? _tripId;
  late List<String> _receipts;

  /// Файлы, скопированные в данные приложения в этом сеансе редактирования.
  final List<String> _addedReceipts = <String>[];

  /// Файлы, откреплённые от траты и подлежащие удалению при сохранении.
  final List<String> _removedReceipts = <String>[];

  bool _saving = false;

  bool get _isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    final Expense? expense = widget.expense;
    final AppState state = context.read<AppState>();

    _amountController = TextEditingController(
      text: expense == null ? '' : Formatters.amount(expense.amount),
    );
    _payeeController = TextEditingController(text: expense?.payee ?? '');
    _commentController = TextEditingController(text: expense?.comment ?? '');
    _categoryId =
        expense?.categoryId ??
        (state.categories.isNotEmpty ? state.categories.first.id : '');
    _date = expense?.date ?? DateTime.now();
    _paymentMethod = expense?.paymentMethod ?? PaymentMethod.card;
    _tripId = expense?.tripId ?? widget.initialTripId;
    _receipts = List<String>.from(expense?.receiptPaths ?? const <String>[]);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _payeeController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(DateTime.now().year + 5),
      helpText: 'Дата траты',
    );
    if (selected != null) {
      setState(
        () => _date = DateTime(
          selected.year,
          selected.month,
          selected.day,
          _date.hour,
          _date.minute,
        ),
      );
    }
  }

  Future<void> _addReceipt(ImageSource source) async {
    final AppState state = context.read<AppState>();
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 2000,
      );
      if (file == null) {
        return;
      }
      final String stored = await state.storeReceipt(file.path);
      if (!mounted) {
        return;
      }
      setState(() {
        _receipts = <String>[..._receipts, stored];
        _addedReceipts.add(stored);
      });
    } on PlatformException catch (error) {
      if (!mounted) {
        return;
      }
      auroraNotify(
        context,
        source == ImageSource.camera
            ? 'Камера недоступна: ${error.message ?? error.code}'
            : 'Не удалось открыть галерею: ${error.message ?? error.code}',
      );
    } on Exception catch (error) {
      if (!mounted) {
        return;
      }
      auroraNotify(context, 'Не удалось прикрепить чек: $error');
    }
  }

  void _detachReceipt(String path) {
    setState(() {
      _receipts = _receipts.where((String item) => item != path).toList();
      if (_addedReceipts.remove(path)) {
        // Файл был добавлен в этом сеансе — удаляем сразу.
        unawaited(context.read<AppState>().removeReceiptFile(path));
      } else {
        _removedReceipts.add(path);
      }
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _saving = true);

    final AppState state = context.read<AppState>();
    final double amount = Formatters.parseAmount(_amountController.text) ?? 0;
    final Expense expense =
        widget.expense?.copyWith(
          amount: amount,
          categoryId: _categoryId,
          date: _date,
          payee: _payeeController.text.trim(),
          comment: _commentController.text.trim(),
          paymentMethod: _paymentMethod,
          tripId: _tripId,
          clearTrip: _tripId == null,
          receiptPaths: _receipts,
        ) ??
        Expense(
          id: state.newId(),
          amount: amount,
          categoryId: _categoryId,
          date: _date,
          payee: _payeeController.text.trim(),
          comment: _commentController.text.trim(),
          paymentMethod: _paymentMethod,
          tripId: _tripId,
          receiptPaths: _receipts,
          createdAt: DateTime.now(),
        );

    if (_isEditing) {
      await state.updateExpense(expense);
    } else {
      await state.addExpense(expense);
    }
    for (final String path in _removedReceipts) {
      await state.removeReceiptFile(path);
    }

    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(expense);
  }

  Future<void> _discard() async {
    final AppState state = context.read<AppState>();
    for (final String path in _addedReceipts) {
      await state.removeReceiptFile(path);
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppState state = context.watch<AppState>();
    final AuroraPalette palette = context.palette;
    final TextTheme text = Theme.of(context).textTheme;
    final double margin = AuroraLayout.pageMargin(context);

    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) {
          unawaited(_discard());
        }
      },
      child: Scaffold(
        appBar: AuroraAppBar(
          title: _isEditing ? 'Редактирование траты' : 'Новая трата',
          subtitle: Formatters.date(_date),
          leading: AuroraIconButton(
            icon: Icons.arrow_back,
            tooltip: 'Назад',
            onPressed: _discard,
          ),
          actions: <Widget>[
            AuroraIconButton(
              icon: Icons.check,
              tooltip: 'Сохранить',
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              margin,
              AuroraSizes.paddingMedium,
              margin,
              AuroraSizes.paddingLarge * 2,
            ),
            children: <Widget>[
              TextFormField(
                controller: _amountController,
                autofocus: !_isEditing,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                style: text.headlineSmall,
                decoration: const InputDecoration(
                  labelText: 'Сумма',
                  suffixText: '₽',
                ),
                validator: (String? value) {
                  final double? amount = Formatters.parseAmount(value ?? '');
                  if (amount == null) {
                    return 'Введите сумму';
                  }
                  if (amount <= 0) {
                    return 'Сумма должна быть больше нуля';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AuroraSizes.paddingLarge),
              Text('Категория', style: text.titleSmall),
              const SizedBox(height: AuroraSizes.paddingMedium),
              _CategorySelector(
                categories: state.categories,
                selectedId: _categoryId,
                onSelected: (String id) => setState(() => _categoryId = id),
              ),
              const SizedBox(height: AuroraSizes.paddingLarge),
              _FieldRow(
                icon: Icons.event_outlined,
                label: 'Дата',
                value: Formatters.date(_date),
                onTap: _pickDate,
              ),
              const SizedBox(height: AuroraSizes.paddingMedium),
              TextFormField(
                controller: _payeeController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Получатель платежа',
                  hintText: 'Организация, получившая платёж',
                  prefixIcon: Icon(Icons.storefront_outlined),
                ),
              ),
              const SizedBox(height: AuroraSizes.paddingMedium),
              TextFormField(
                controller: _commentController,
                textCapitalization: TextCapitalization.sentences,
                minLines: 1,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Комментарий',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
              ),
              const SizedBox(height: AuroraSizes.paddingLarge),
              Text('Способ оплаты', style: text.titleSmall),
              const SizedBox(height: AuroraSizes.paddingMedium),
              _PaymentMethodSelector(
                selected: _paymentMethod,
                onSelected: (PaymentMethod method) =>
                    setState(() => _paymentMethod = method),
              ),
              const SizedBox(height: AuroraSizes.paddingLarge),
              Text('Командировка', style: text.titleSmall),
              const SizedBox(height: AuroraSizes.paddingMedium),
              _TripSelector(
                trips: state.trips,
                selectedId: _tripId,
                onSelected: (String? id) => setState(() => _tripId = id),
              ),
              const SizedBox(height: AuroraSizes.paddingLarge),
              Row(
                children: <Widget>[
                  Expanded(child: Text('Чеки', style: text.titleSmall)),
                  AuroraIconButton(
                    icon: Icons.photo_camera_outlined,
                    tooltip: 'Снять чек камерой',
                    onPressed: () => _addReceipt(ImageSource.camera),
                  ),
                  AuroraIconButton(
                    icon: Icons.photo_library_outlined,
                    tooltip: 'Выбрать из галереи',
                    onPressed: () => _addReceipt(ImageSource.gallery),
                  ),
                ],
              ),
              const SizedBox(height: AuroraSizes.paddingMedium),
              _ReceiptStrip(
                paths: _receipts,
                onRemove: _detachReceipt,
                resolve: state.receiptStorage.resolve,
              ),
              if (_isEditing) ...<Widget>[
                const SizedBox(height: AuroraSizes.paddingLarge),
                OutlinedButton.icon(
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
                    await state.deleteExpense(widget.expense!.id);
                    if (context.mounted) {
                      Navigator.of(context).pop(_deletedMarker);
                    }
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Удалить трату'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: palette.danger,
                    side: BorderSide(color: palette.danger),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Результат формы, означающий удаление траты.
const Object _deletedMarker = Object();

/// Признак удаления траты в результате, возвращённом формой.
bool isExpenseDeleted(Object? result) => identical(result, _deletedMarker);

class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AuroraPalette palette = context.palette;
    final TextTheme text = Theme.of(context).textTheme;

    return Material(
      color: palette.surfaceVariant,
      borderRadius: AuroraRadius.small,
      child: InkWell(
        onTap: onTap,
        borderRadius: AuroraRadius.small,
        child: Container(
          height: AuroraSizes.itemSizeSmall,
          padding: const EdgeInsets.symmetric(
            horizontal: AuroraSizes.paddingMedium + AuroraSizes.paddingSmall,
          ),
          child: Row(
            children: <Widget>[
              Icon(icon, color: palette.textSecondary),
              const SizedBox(width: AuroraSizes.paddingMedium),
              Expanded(child: Text(label, style: text.bodyMedium)),
              Text(
                value,
                style: text.bodyMedium?.copyWith(color: palette.accent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategorySelector extends StatelessWidget {
  const _CategorySelector({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  final List<ExpenseCategory> categories;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final AuroraPalette palette = context.palette;

    return Wrap(
      spacing: AuroraSizes.paddingSmall,
      runSpacing: AuroraSizes.paddingSmall,
      children: <Widget>[
        for (final ExpenseCategory category in categories)
          ChoiceChip(
            selected: category.id == selectedId,
            onSelected: (_) => onSelected(category.id),
            showCheckmark: false,
            avatar: Icon(
              category.id == selectedId
                  ? Icons.check
                  : Icons.circle,
              size: 14,
              color: category.id == selectedId
                  ? palette.onAccentFill
                  : AuroraPalette.chartColorAt(category.colorIndex),
            ),
            label: Text(category.name),
            labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: category.id == selectedId
                  ? palette.onAccentFill
                  : palette.textPrimary,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AuroraSizes.paddingMedium,
              vertical: AuroraSizes.paddingMedium,
            ),
          ),
      ],
    );
  }
}

class _PaymentMethodSelector extends StatelessWidget {
  const _PaymentMethodSelector({
    required this.selected,
    required this.onSelected,
  });

  final PaymentMethod selected;
  final ValueChanged<PaymentMethod> onSelected;

  @override
  Widget build(BuildContext context) {
    final AuroraPalette palette = context.palette;

    return Row(
      children: <Widget>[
        for (final PaymentMethod method in PaymentMethod.values)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: AuroraSizes.paddingSmall),
              child: Material(
                color: method == selected
                    ? palette.accentFill
                    : palette.surfaceVariant,
                borderRadius: AuroraRadius.small,
                child: InkWell(
                  onTap: () => onSelected(method),
                  borderRadius: AuroraRadius.small,
                  child: Container(
                    height: AuroraSizes.itemSizeSmall,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(AuroraSizes.paddingSmall),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          method.icon,
                          size: AuroraSizes.iconSizeSmall,
                          color: method == selected
                              ? palette.onAccentFill
                              : palette.textSecondary,
                        ),
                        const SizedBox(height: AuroraSizes.paddingSmall),
                        Text(
                          method.label,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: method == selected
                                ? palette.onAccentFill
                                : palette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _TripSelector extends StatelessWidget {
  const _TripSelector({
    required this.trips,
    required this.selectedId,
    required this.onSelected,
  });

  final List<Trip> trips;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    if (trips.isEmpty) {
      return Text(
        'Командировок пока нет. Создайте их в разделе «Командировки», '
        'чтобы прикреплять к ним служебные траты.',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }

    return Wrap(
      spacing: AuroraSizes.paddingSmall,
      runSpacing: AuroraSizes.paddingSmall,
      children: <Widget>[
        ChoiceChip(
          selected: selectedId == null,
          onSelected: (_) => onSelected(null),
          showCheckmark: false,
          label: const Text('Без командировки'),
          labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: selectedId == null
                ? context.palette.onAccentFill
                : context.palette.textPrimary,
          ),
        ),
        for (final Trip trip in trips)
          ChoiceChip(
            selected: trip.id == selectedId,
            onSelected: (_) => onSelected(trip.id),
            showCheckmark: false,
            label: Text(trip.title),
            labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: trip.id == selectedId
                  ? context.palette.onAccentFill
                  : context.palette.textPrimary,
            ),
          ),
      ],
    );
  }
}

/// Лента прикреплённых чеков с возможностью открыть и открепить файл.
class _ReceiptStrip extends StatelessWidget {
  const _ReceiptStrip({
    required this.paths,
    required this.onRemove,
    required this.resolve,
  });

  final List<String> paths;
  final ValueChanged<String> onRemove;
  final Future<File> Function(String) resolve;

  @override
  Widget build(BuildContext context) {
    final AuroraPalette palette = context.palette;

    if (paths.isEmpty) {
      return Container(
        height: AuroraSizes.itemSizeLarge,
        decoration: BoxDecoration(
          borderRadius: AuroraRadius.small,
          border: Border.all(color: palette.divider),
        ),
        alignment: Alignment.center,
        child: Text(
          'Чеки не прикреплены',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    return SizedBox(
      height: AuroraSizes.iconSizeLarge + AuroraSizes.paddingLarge,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: paths.length,
        separatorBuilder: (_, _) =>
            const SizedBox(width: AuroraSizes.paddingMedium),
        itemBuilder: (BuildContext context, int index) => ReceiptThumbnail(
          path: paths[index],
          resolve: resolve,
          onRemove: () => onRemove(paths[index]),
        ),
      ),
    );
  }
}

/// Миниатюра чека.
class ReceiptThumbnail extends StatelessWidget {
  const ReceiptThumbnail({
    required this.path,
    required this.resolve,
    this.onRemove,
    this.size = AuroraSizes.iconSizeLarge,
    super.key,
  });

  final String path;
  final Future<File> Function(String) resolve;
  final VoidCallback? onRemove;
  final double size;

  @override
  Widget build(BuildContext context) {
    final AuroraPalette palette = context.palette;

    return FutureBuilder<File>(
      future: resolve(path),
      builder: (BuildContext context, AsyncSnapshot<File> snapshot) {
        final File? file = snapshot.data;
        final bool exists = file != null && file.existsSync();

        return Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            GestureDetector(
              onTap: exists
                  ? () => showDialog<void>(
                      context: context,
                      builder: (BuildContext context) => Dialog(
                        insetPadding: const EdgeInsets.all(
                          AuroraSizes.paddingLarge,
                        ),
                        child: InteractiveViewer(
                          child: Image.file(file, fit: BoxFit.contain),
                        ),
                      ),
                    )
                  : null,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: palette.surfaceVariant,
                  borderRadius: AuroraRadius.small,
                ),
                clipBehavior: Clip.antiAlias,
                child: exists
                    ? Image.file(file, fit: BoxFit.cover)
                    : Icon(
                        Icons.receipt_long_outlined,
                        color: palette.textSecondary,
                      ),
              ),
            ),
            if (onRemove != null)
              Positioned(
                right: -AuroraSizes.paddingMedium,
                top: -AuroraSizes.paddingMedium,
                child: AuroraIconButton(
                  icon: Icons.cancel,
                  tooltip: 'Открепить чек',
                  onPressed: onRemove,
                ),
              ),
          ],
        );
      },
    );
  }
}
