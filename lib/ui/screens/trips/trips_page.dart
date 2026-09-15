// SPDX-License-Identifier: BSD-3-Clause
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/format/formatters.dart';
import '../../../core/layout/adaptive.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_tokens.dart';
import '../../../data/models/expense.dart';
import '../../../data/models/trip.dart';
import '../../../data/services/analytics.dart';
import '../../../state/app_state.dart';
import '../../widgets/aurora_app_bar.dart';
import '../../widgets/aurora_widgets.dart';
import '../../widgets/expense_list_item.dart';
import '../expenses/expense_details_view.dart';
import '../expenses/expense_form_page.dart';

/// Командировки для служебных расходов.
///
/// Командировка создаётся на определённый период, к ней прикрепляются траты.
class TripsPage extends StatefulWidget {
  const TripsPage({this.leading, super.key});

  final Widget? leading;

  @override
  State<TripsPage> createState() => _TripsPageState();
}

class _TripsPageState extends State<TripsPage> {
  String? _selectedId;

  Future<void> _edit(BuildContext context, {Trip? trip}) async {
    final AppState state = context.read<AppState>();
    final _TripDraft? draft = await showModalBottomSheet<_TripDraft>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => _TripForm(trip: trip),
    );
    if (draft == null) {
      return;
    }
    if (trip == null) {
      final Trip created = await state.addTrip(
        title: draft.title,
        startDate: draft.startDate,
        endDate: draft.endDate,
        destination: draft.destination,
        note: draft.note,
      );
      if (mounted) {
        setState(() => _selectedId = created.id);
      }
    } else {
      await state.updateTrip(
        trip.copyWith(
          title: draft.title,
          startDate: draft.startDate,
          endDate: draft.endDate,
          destination: draft.destination,
          note: draft.note,
        ),
      );
    }
  }

  Future<void> _delete(BuildContext context, Trip trip) async {
    final AppState state = context.read<AppState>();
    final bool confirmed = await auroraConfirm(
      context,
      title: 'Удалить командировку?',
      message:
          'Командировка «${trip.title}» будет удалена. '
          'Её траты сохранятся, но будут откреплены.',
    );
    if (!confirmed) {
      return;
    }
    await state.deleteTrip(trip.id);
    if (mounted && _selectedId == trip.id) {
      setState(() => _selectedId = null);
    }
  }

  void _open(BuildContext context, Trip trip, {required bool split}) {
    if (split) {
      setState(() => _selectedId = trip.id);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => TripDetailsPage(tripId: trip.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppState state = context.watch<AppState>();
    final bool split = AuroraLayout.isSplit(context);
    final List<Trip> trips = state.trips;
    final double margin = AuroraLayout.pageMargin(context);

    if (_selectedId != null &&
        !trips.any((Trip trip) => trip.id == _selectedId)) {
      _selectedId = null;
    }

    final Widget list = trips.isEmpty
        ? AuroraEmptyState(
            icon: Icons.work_outline,
            title: 'Командировок нет',
            message:
                'Создайте командировку на нужный период, '
                'чтобы прикреплять к ней служебные траты.',
            action: ElevatedButton.icon(
              onPressed: () => _edit(context),
              icon: const Icon(Icons.add),
              label: const Text('Новая командировка'),
            ),
          )
        : ListView.separated(
            padding: EdgeInsets.fromLTRB(
              margin,
              AuroraSizes.paddingMedium,
              margin,
              AuroraSizes.itemSizeExtraLarge,
            ),
            itemCount: trips.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: AuroraSizes.paddingSmall),
            itemBuilder: (BuildContext context, int index) {
              final Trip trip = trips[index];
              final List<Expense> expenses = state.expensesOfTrip(trip.id);
              return _TripTile(
                trip: trip,
                count: expenses.length,
                total: ExpenseAnalytics.total(expenses),
                selected: split && trip.id == _selectedId,
                onTap: () => _open(context, trip, split: split),
                onEdit: () => _edit(context, trip: trip),
                onDelete: () => _delete(context, trip),
              );
            },
          );

    return Scaffold(
      appBar: AuroraAppBar(
        title: 'Командировки',
        subtitle: Formatters.plural(
          trips.length,
          'командировка',
          'командировки',
          'командировок',
        ),
        leading: widget.leading,
        actions: <Widget>[
          AuroraIconButton(
            icon: Icons.add,
            tooltip: 'Новая командировка',
            onPressed: () => _edit(context),
          ),
        ],
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
                          title: 'Выберите командировку',
                          message: 'Её траты откроются в этой панели.',
                        )
                      : TripDetailsView(tripId: _selectedId!),
                ),
              ],
            )
          : list,
    );
  }
}

/// Детали командировки: период, сумма и список прикреплённых трат.
class TripDetailsView extends StatelessWidget {
  const TripDetailsView({required this.tripId, super.key});

  final String tripId;

  @override
  Widget build(BuildContext context) {
    final AppState state = context.watch<AppState>();
    final Trip? trip = state.tripById(tripId);
    final double margin = AuroraLayout.pageMargin(context);

    if (trip == null) {
      return const AuroraEmptyState(
        icon: Icons.work_outline,
        title: 'Командировка не найдена',
      );
    }

    final List<Expense> expenses = state.expensesOfTrip(tripId);
    final double total = ExpenseAnalytics.total(expenses);
    final TextTheme text = Theme.of(context).textTheme;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        margin,
        AuroraSizes.paddingMedium,
        margin,
        AuroraSizes.itemSizeExtraLarge,
      ),
      children: <Widget>[
        Text(trip.title, style: text.headlineSmall),
        const SizedBox(height: AuroraSizes.paddingSmall),
        Text(
          Formatters.range(trip.startDate, trip.endDate),
          style: text.titleSmall,
        ),
        if (trip.destination.isNotEmpty) ...<Widget>[
          const SizedBox(height: AuroraSizes.paddingSmall),
          Row(
            children: <Widget>[
              Icon(
                Icons.place_outlined,
                size: AuroraSizes.iconSizeSmall,
                color: context.palette.textSecondary,
              ),
              const SizedBox(width: AuroraSizes.paddingSmall),
              Expanded(child: Text(trip.destination, style: text.bodyMedium)),
            ],
          ),
        ],
        if (trip.note.isNotEmpty) ...<Widget>[
          const SizedBox(height: AuroraSizes.paddingMedium),
          Text(trip.note, style: text.bodyMedium),
        ],
        const SizedBox(height: AuroraSizes.paddingLarge),
        Row(
          children: <Widget>[
            Expanded(
              child: AuroraStatTile(
                label: 'Сумма расходов',
                value: Formatters.money(total),
                icon: Icons.summarize_outlined,
              ),
            ),
            const SizedBox(width: AuroraSizes.paddingMedium),
            Expanded(
              child: AuroraStatTile(
                label: 'Дней',
                value: '${trip.days}',
                icon: Icons.event_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: AuroraSizes.paddingLarge),
        Row(
          children: <Widget>[
            Expanded(child: Text('Траты командировки', style: text.titleSmall)),
            TextButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<Object?>(
                  builder: (_) => ExpenseFormPage(initialTripId: tripId),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Добавить'),
            ),
          ],
        ),
        const SizedBox(height: AuroraSizes.paddingSmall),
        if (expenses.isEmpty)
          Text(
            'К командировке не прикреплено ни одной траты.',
            style: text.bodySmall,
          )
        else
          for (final Expense expense in expenses)
            Padding(
              padding: const EdgeInsets.only(bottom: AuroraSizes.paddingSmall),
              child: ExpenseListItem(
                expense: expense,
                category: state.categoryById(expense.categoryId),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ExpenseDetailsPage(expenseId: expense.id),
                  ),
                ),
              ),
            ),
      ],
    );
  }
}

/// Страница деталей командировки для смартфона.
class TripDetailsPage extends StatelessWidget {
  const TripDetailsPage({required this.tripId, super.key});

  final String tripId;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AuroraAppBar(
      title: 'Командировка',
      leading: AuroraIconButton(
        icon: Icons.arrow_back,
        tooltip: 'Назад',
        onPressed: () => Navigator.of(context).pop(),
      ),
    ),
    body: TripDetailsView(tripId: tripId),
  );
}

class _TripTile extends StatelessWidget {
  const _TripTile({
    required this.trip,
    required this.count,
    required this.total,
    required this.selected,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final Trip trip;
  final int count;
  final double total;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final AuroraPalette palette = context.palette;
    final TextTheme text = Theme.of(context).textTheme;

    return Material(
      color: selected
          ? palette.accent.withValues(alpha: 0.12)
          : palette.surface,
      borderRadius: AuroraRadius.medium,
      child: InkWell(
        onTap: onTap,
        borderRadius: AuroraRadius.medium,
        child: Container(
          constraints: const BoxConstraints(
            minHeight: AuroraSizes.itemSizeMedium,
          ),
          padding: const EdgeInsets.all(AuroraSizes.paddingMedium),
          child: Row(
            children: <Widget>[
              Container(
                width: AuroraSizes.itemSizeExtraSmall,
                height: AuroraSizes.itemSizeExtraSmall,
                decoration: BoxDecoration(
                  color: palette.accent.withValues(alpha: 0.16),
                  borderRadius: AuroraRadius.small,
                ),
                alignment: Alignment.center,
                child: Icon(Icons.work_outline, color: palette.accent),
              ),
              const SizedBox(width: AuroraSizes.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      trip.title,
                      style: text.bodyLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      Formatters.range(trip.startDate, trip.endDate),
                      style: text.bodySmall,
                    ),
                    Text(
                      '${Formatters.plural(count, 'трата', 'траты', 'трат')} '
                      'на ${Formatters.money(total)}',
                      style: text.bodySmall?.copyWith(color: palette.accent),
                    ),
                  ],
                ),
              ),
              AuroraIconButton(
                icon: Icons.edit_outlined,
                tooltip: 'Изменить',
                onPressed: onEdit,
              ),
              AuroraIconButton(
                icon: Icons.delete_outline,
                tooltip: 'Удалить',
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TripDraft {
  const _TripDraft({
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.destination,
    required this.note,
  });

  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final String destination;
  final String note;
}

class _TripForm extends StatefulWidget {
  const _TripForm({this.trip});

  final Trip? trip;

  @override
  State<_TripForm> createState() => _TripFormState();
}

class _TripFormState extends State<_TripForm> {
  late final TextEditingController _titleController;
  late final TextEditingController _destinationController;
  late final TextEditingController _noteController;
  late DateTime _start;
  late DateTime _end;
  String? _error;

  @override
  void initState() {
    super.initState();
    final DateTime now = DateTime.now();
    _titleController = TextEditingController(text: widget.trip?.title ?? '');
    _destinationController = TextEditingController(
      text: widget.trip?.destination ?? '',
    );
    _noteController = TextEditingController(text: widget.trip?.note ?? '');
    _start = widget.trip?.startDate ?? DateTime(now.year, now.month, now.day);
    _end =
        widget.trip?.endDate ??
        DateTime(now.year, now.month, now.day).add(const Duration(days: 3));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _destinationController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(DateTime.now().year + 5),
      initialDateRange: DateTimeRange(start: _start, end: _end),
      helpText: 'Период командировки',
      saveText: 'Готово',
    );
    if (picked != null) {
      setState(() {
        _start = picked.start;
        _end = picked.end;
      });
    }
  }

  void _submit() {
    final String title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Введите название командировки');
      return;
    }
    Navigator.of(context).pop(
      _TripDraft(
        title: title,
        startDate: _start,
        endDate: _end,
        destination: _destinationController.text.trim(),
        note: _noteController.text.trim(),
      ),
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
                widget.trip == null
                    ? 'Новая командировка'
                    : 'Изменение командировки',
                style: text.titleLarge,
              ),
              const SizedBox(height: AuroraSizes.paddingLarge),
              TextField(
                controller: _titleController,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Название',
                  hintText: 'Например: Казань, конференция',
                  errorText: _error,
                ),
                onChanged: (_) {
                  if (_error != null) {
                    setState(() => _error = null);
                  }
                },
              ),
              const SizedBox(height: AuroraSizes.paddingMedium),
              TextField(
                controller: _destinationController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Место назначения',
                  prefixIcon: Icon(Icons.place_outlined),
                ),
              ),
              const SizedBox(height: AuroraSizes.paddingMedium),
              OutlinedButton.icon(
                onPressed: _pickRange,
                icon: const Icon(Icons.date_range),
                label: Text(Formatters.range(_start, _end)),
              ),
              const SizedBox(height: AuroraSizes.paddingMedium),
              TextField(
                controller: _noteController,
                minLines: 1,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Заметка',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
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
