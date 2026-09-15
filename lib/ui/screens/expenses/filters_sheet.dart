// SPDX-License-Identifier: BSD-3-Clause
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/format/formatters.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_tokens.dart';
import '../../../data/models/expense_category.dart';
import '../../../data/models/expense_filter.dart';
import '../../../data/models/payment_method.dart';
import '../../../data/models/trip.dart';

/// Открывает панель фильтров списка трат.
///
/// Возвращает новый фильтр или `null`, если пользователь закрыл панель.
Future<ExpenseFilter?> showExpenseFilters(
  BuildContext context, {
  required ExpenseFilter initial,
  required List<ExpenseCategory> categories,
  required List<Trip> trips,
}) => showModalBottomSheet<ExpenseFilter>(
  context: context,
  isScrollControlled: true,
  builder: (BuildContext context) =>
      _FiltersSheet(initial: initial, categories: categories, trips: trips),
);

class _FiltersSheet extends StatefulWidget {
  const _FiltersSheet({
    required this.initial,
    required this.categories,
    required this.trips,
  });

  final ExpenseFilter initial;
  final List<ExpenseCategory> categories;
  final List<Trip> trips;

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  late Set<String> _categoryIds;
  late Set<PaymentMethod> _methods;
  late DateRange? _range;
  late String? _tripId;
  late bool _withoutTrip;
  late final TextEditingController _minController;
  late final TextEditingController _maxController;

  @override
  void initState() {
    super.initState();
    _categoryIds = Set<String>.from(widget.initial.categoryIds);
    _methods = Set<PaymentMethod>.from(widget.initial.paymentMethods);
    _range = widget.initial.dateRange;
    _tripId = widget.initial.tripId;
    _withoutTrip = widget.initial.withoutTrip;
    _minController = TextEditingController(
      text: widget.initial.minAmount == null
          ? ''
          : Formatters.amount(widget.initial.minAmount!),
    );
    _maxController = TextEditingController(
      text: widget.initial.maxAmount == null
          ? ''
          : Formatters.amount(widget.initial.maxAmount!),
    );
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  Future<void> _pickRange() async {
    final DateTime now = DateTime.now();
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5),
      initialDateRange: _range == null
          ? null
          : DateTimeRange(start: _range!.start, end: _range!.end),
      helpText: 'Выборка дат',
      saveText: 'Готово',
    );
    if (picked != null) {
      setState(() => _range = DateRange(picked.start, picked.end));
    }
  }

  ExpenseFilter _buildFilter() => ExpenseFilter(
    categoryIds: _categoryIds,
    dateRange: _range,
    minAmount: Formatters.parseAmount(_minController.text),
    maxAmount: Formatters.parseAmount(_maxController.text),
    paymentMethods: _methods,
    tripId: _tripId,
    withoutTrip: _withoutTrip,
    query: widget.initial.query,
  );

  @override
  Widget build(BuildContext context) {
    final AuroraPalette palette = context.palette;
    final TextTheme text = Theme.of(context).textTheme;
    final DateTime now = DateTime.now();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AuroraSizes.paddingLarge,
                  AuroraSizes.paddingLarge,
                  AuroraSizes.paddingMedium,
                  AuroraSizes.paddingMedium,
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(child: Text('Фильтры', style: text.titleLarge)),
                    TextButton(
                      onPressed: () => setState(() {
                        _categoryIds = <String>{};
                        _methods = <PaymentMethod>{};
                        _range = null;
                        _tripId = null;
                        _withoutTrip = false;
                        _minController.clear();
                        _maxController.clear();
                      }),
                      child: const Text('Сбросить'),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AuroraSizes.paddingLarge,
                  ),
                  shrinkWrap: true,
                  children: <Widget>[
                    Text('Категории', style: text.titleSmall),
                    const SizedBox(height: AuroraSizes.paddingMedium),
                    Wrap(
                      spacing: AuroraSizes.paddingSmall,
                      runSpacing: AuroraSizes.paddingSmall,
                      children: <Widget>[
                        for (final ExpenseCategory category
                            in widget.categories)
                          FilterChip(
                            selected: _categoryIds.contains(category.id),
                            onSelected: (bool selected) => setState(() {
                              if (selected) {
                                _categoryIds.add(category.id);
                              } else {
                                _categoryIds.remove(category.id);
                              }
                            }),
                            label: Text(category.name),
                            labelStyle: text.bodyMedium?.copyWith(
                              color: _categoryIds.contains(category.id)
                                  ? palette.onAccentFill
                                  : palette.textPrimary,
                            ),
                            showCheckmark: false,
                          ),
                      ],
                    ),
                    const SizedBox(height: AuroraSizes.paddingLarge),
                    Text('Дата или выборка дат', style: text.titleSmall),
                    const SizedBox(height: AuroraSizes.paddingMedium),
                    Wrap(
                      spacing: AuroraSizes.paddingSmall,
                      runSpacing: AuroraSizes.paddingSmall,
                      children: <Widget>[
                        _RangeChip(
                          label: 'Текущий месяц',
                          range: DateRange.month(now),
                          selected: _range,
                          onSelected: (DateRange? value) =>
                              setState(() => _range = value),
                        ),
                        _RangeChip(
                          label: 'Последние 3 месяца',
                          range: DateRange.lastMonths(now, 3),
                          selected: _range,
                          onSelected: (DateRange? value) =>
                              setState(() => _range = value),
                        ),
                        _RangeChip(
                          label: 'Текущий год',
                          range: DateRange.year(now),
                          selected: _range,
                          onSelected: (DateRange? value) =>
                              setState(() => _range = value),
                        ),
                        ActionChip(
                          avatar: const Icon(
                            Icons.date_range,
                            size: AuroraSizes.iconSizeExtraSmall,
                          ),
                          label: Text(
                            _range == null
                                ? 'Произвольный период'
                                : Formatters.range(_range!.start, _range!.end),
                          ),
                          labelStyle: text.bodyMedium,
                          onPressed: _pickRange,
                        ),
                        if (_range != null)
                          ActionChip(
                            avatar: const Icon(
                              Icons.close,
                              size: AuroraSizes.iconSizeExtraSmall,
                            ),
                            label: const Text('Убрать период'),
                            labelStyle: text.bodyMedium,
                            onPressed: () => setState(() => _range = null),
                          ),
                      ],
                    ),
                    const SizedBox(height: AuroraSizes.paddingLarge),
                    Text('Сумма', style: text.titleSmall),
                    const SizedBox(height: AuroraSizes.paddingMedium),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: _minController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.,]'),
                              ),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Больше или равно',
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: AuroraSizes.paddingMedium),
                        Expanded(
                          child: TextField(
                            controller: _maxController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.,]'),
                              ),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Меньше или равно',
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AuroraSizes.paddingLarge),
                    Text('Способ оплаты', style: text.titleSmall),
                    const SizedBox(height: AuroraSizes.paddingMedium),
                    Wrap(
                      spacing: AuroraSizes.paddingSmall,
                      runSpacing: AuroraSizes.paddingSmall,
                      children: <Widget>[
                        for (final PaymentMethod method in PaymentMethod.values)
                          FilterChip(
                            selected: _methods.contains(method),
                            onSelected: (bool selected) => setState(() {
                              if (selected) {
                                _methods.add(method);
                              } else {
                                _methods.remove(method);
                              }
                            }),
                            avatar: Icon(
                              method.icon,
                              size: AuroraSizes.iconSizeExtraSmall,
                            ),
                            label: Text(method.label),
                            labelStyle: text.bodyMedium?.copyWith(
                              color: _methods.contains(method)
                                  ? palette.onAccentFill
                                  : palette.textPrimary,
                            ),
                            showCheckmark: false,
                          ),
                      ],
                    ),
                    const SizedBox(height: AuroraSizes.paddingLarge),
                    Text('Командировка', style: text.titleSmall),
                    const SizedBox(height: AuroraSizes.paddingMedium),
                    Wrap(
                      spacing: AuroraSizes.paddingSmall,
                      runSpacing: AuroraSizes.paddingSmall,
                      children: <Widget>[
                        FilterChip(
                          selected: _withoutTrip,
                          onSelected: (bool selected) => setState(() {
                            _withoutTrip = selected;
                            if (selected) {
                              _tripId = null;
                            }
                          }),
                          label: const Text('Без командировки'),
                          labelStyle: text.bodyMedium?.copyWith(
                            color: _withoutTrip
                                ? palette.onAccentFill
                                : palette.textPrimary,
                          ),
                          showCheckmark: false,
                        ),
                        for (final Trip trip in widget.trips)
                          FilterChip(
                            selected: _tripId == trip.id,
                            onSelected: (bool selected) => setState(() {
                              _tripId = selected ? trip.id : null;
                              if (selected) {
                                _withoutTrip = false;
                              }
                            }),
                            label: Text(trip.title),
                            labelStyle: text.bodyMedium?.copyWith(
                              color: _tripId == trip.id
                                  ? palette.onAccentFill
                                  : palette.textPrimary,
                            ),
                            showCheckmark: false,
                          ),
                      ],
                    ),
                    const SizedBox(height: AuroraSizes.paddingLarge),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AuroraSizes.paddingLarge),
                child: Row(
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
                        onPressed: () =>
                            Navigator.of(context).pop(_buildFilter()),
                        child: const Text('Применить'),
                      ),
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

class _RangeChip extends StatelessWidget {
  const _RangeChip({
    required this.label,
    required this.range,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final DateRange range;
  final DateRange? selected;
  final ValueChanged<DateRange?> onSelected;

  @override
  Widget build(BuildContext context) {
    final bool isSelected = selected == range;
    return FilterChip(
      selected: isSelected,
      onSelected: (bool value) => onSelected(value ? range : null),
      label: Text(label),
      labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: isSelected
            ? context.palette.onAccentFill
            : context.palette.textPrimary,
      ),
      showCheckmark: false,
    );
  }
}
