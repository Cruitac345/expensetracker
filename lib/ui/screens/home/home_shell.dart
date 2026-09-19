// SPDX-License-Identifier: BSD-3-Clause
import 'package:flutter/material.dart';

import '../../../core/layout/adaptive.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_tokens.dart';
import '../../widgets/aurora_app_bar.dart';
import '../categories/categories_page.dart';
import '../dashboard/dashboard_page.dart';
import '../expenses/expenses_page.dart';
import '../import/import_page.dart';
import '../settings/settings_page.dart';
import '../trips/trips_page.dart';

/// Раздел приложения.
enum AppSection {
  expenses('Траты', Icons.list_alt),
  dashboard('Дашборд', Icons.donut_small_outlined),
  trips('Командировки', Icons.work_outline),
  categories('Категории', Icons.sell_outlined),
  import('Импорт CSV', Icons.file_download_outlined),
  settings('Настройки', Icons.settings_outlined);

  const AppSection(this.title, this.icon);

  final String title;
  final IconData icon;
}

/// Оболочка приложения с адаптивной навигацией: на широком экране панель
/// разделов закреплена слева, на смартфоне открывается всплывающим меню.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  AppSection _section = AppSection.expenses;

  void _select(AppSection section) {
    if (_section != section) {
      setState(() => _section = section);
    }
  }

  Future<void> _openSectionMenu(BuildContext context) async {
    final AppSection? selected = await showModalBottomSheet<AppSection>(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox(height: AuroraSizes.paddingMedium),
              for (final AppSection section in AppSection.values)
                ListTile(
                  leading: Icon(section.icon),
                  title: Text(
                    section.title,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  selected: section == _section,
                  minVerticalPadding: AuroraSizes.paddingMedium,
                  onTap: () => Navigator.of(context).pop(section),
                ),
              const SizedBox(height: AuroraSizes.paddingMedium),
            ],
          ),
        ),
      ),
    );
    if (selected != null) {
      _select(selected);
    }
  }

  Widget _pageFor(AppSection section, {Widget? leading}) => switch (section) {
    AppSection.expenses => ExpensesPage(leading: leading),
    AppSection.dashboard => DashboardPage(leading: leading),
    AppSection.trips => TripsPage(leading: leading),
    AppSection.categories => CategoriesPage(leading: leading),
    AppSection.import => ImportPage(leading: leading),
    AppSection.settings => SettingsPage(leading: leading),
  };

  @override
  Widget build(BuildContext context) {
    final bool wide = AuroraLayout.isWide(context);

    if (wide) {
      return Scaffold(
        body: AuroraSplitView(
          panels: <AuroraPanel>[
            AuroraPanel(
              width: AuroraSizes.navigationPanelWidth,
              child: _NavigationPanel(current: _section, onSelected: _select),
            ),
            AuroraPanel(columnSpan: 12, child: _pageFor(_section)),
          ],
        ),
      );
    }

    return _pageFor(
      _section,
      leading: Builder(
        builder: (BuildContext context) => AuroraIconButton(
          icon: Icons.menu,
          tooltip: 'Разделы',
          onPressed: () => _openSectionMenu(context),
        ),
      ),
    );
  }
}

/// Закреплённая панель навигации для планшетов.
class _NavigationPanel extends StatelessWidget {
  const _NavigationPanel({required this.current, required this.onSelected});

  final AppSection current;
  final ValueChanged<AppSection> onSelected;

  @override
  Widget build(BuildContext context) {
    final AuroraPalette palette = context.palette;
    final TextTheme text = Theme.of(context).textTheme;

    return Material(
      color: palette.surface,
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AuroraSizes.paddingLarge,
                AuroraSizes.paddingLarge,
                AuroraSizes.paddingLarge,
                AuroraSizes.paddingMedium,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Трекер', style: text.titleLarge),
                  Text('Расходов', style: text.titleSmall),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AuroraSizes.paddingMedium,
                ),
                children: <Widget>[
                  for (final AppSection section in AppSection.values)
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: AuroraSizes.paddingSmall,
                      ),
                      child: _NavigationItem(
                        section: section,
                        selected: section == current,
                        onTap: () => onSelected(section),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.section,
    required this.selected,
    required this.onTap,
  });

  final AppSection section;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AuroraPalette palette = context.palette;
    final TextTheme text = Theme.of(context).textTheme;

    return Material(
      color: selected
          ? palette.accent.withValues(alpha: 0.14)
          : Colors.transparent,
      borderRadius: AuroraRadius.small,
      child: InkWell(
        onTap: onTap,
        borderRadius: AuroraRadius.small,
        child: Container(
          height: AuroraSizes.itemSizeExtraSmall,
          padding: const EdgeInsets.symmetric(
            horizontal: AuroraSizes.paddingMedium,
          ),
          child: Row(
            children: <Widget>[
              Icon(
                section.icon,
                size: AuroraSizes.iconSizeSmall,
                color: selected ? palette.accent : palette.textSecondary,
              ),
              const SizedBox(width: AuroraSizes.paddingMedium),
              Expanded(
                child: Text(
                  section.title,
                  style: text.bodyMedium?.copyWith(
                    color: selected ? palette.accent : palette.textPrimary,
                    fontWeight: selected ? FontWeight.w500 : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
