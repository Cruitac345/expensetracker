// SPDX-License-Identifier: BSD-3-Clause
import 'package:flutter/material.dart';

import '../../core/layout/adaptive.dart';
import '../../core/theme/aurora_colors.dart';
import '../../core/theme/aurora_tokens.dart';

/// Панель приложения по гайдлайну ОС Аврора.
///
/// Заголовок выравнивается по левому краю и центрируется по вертикали,
/// под ним располагается подзаголовок. Кнопки-иконки имеют размер 48×48
/// и отделяются друг от друга отступом не меньше `paddingMedium`.
class AuroraAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AuroraAppBar({
    required this.title,
    this.subtitle,
    this.leading,
    this.actions = const <Widget>[],
    this.bottom,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> actions;

  /// Дополнительная строка под панелью — например, поле поиска.
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize => Size.fromHeight(
    AuroraSizes.itemSizeHeader + (bottom?.preferredSize.height ?? 0),
  );

  @override
  Widget build(BuildContext context) {
    final AuroraPalette palette = context.palette;
    final TextTheme text = Theme.of(context).textTheme;
    final double margin = AuroraLayout.pageMargin(context);

    return Material(
      color: palette.background,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              height: AuroraSizes.itemSizeHeader,
              child: Padding(
                padding: EdgeInsets.only(
                  left: leading == null ? margin : AuroraSizes.paddingSmall,
                  right: actions.isEmpty ? margin : AuroraSizes.paddingSmall,
                ),
                child: Row(
                  children: <Widget>[
                    if (leading != null) ...<Widget>[
                      leading!,
                      const SizedBox(width: AuroraSizes.paddingSmall),
                    ],
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            title,
                            style: text.titleLarge,
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                            softWrap: false,
                          ),
                          if (subtitle != null)
                            Text(
                              subtitle!,
                              style: text.titleSmall,
                              maxLines: 1,
                              overflow: TextOverflow.fade,
                              softWrap: false,
                            ),
                        ],
                      ),
                    ),
                    if (actions.isNotEmpty) ...<Widget>[
                      const SizedBox(width: AuroraSizes.paddingMedium),
                      ...actions,
                    ],
                  ],
                ),
              ),
            ),
            ?bottom,
          ],
        ),
      ),
    );
  }
}

/// Кнопка-иконка панели приложения: размер 48×48 (гайдлайн — `iconSizeSmallPlus`).
class AuroraIconButton extends StatelessWidget {
  const AuroraIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.badge,
    this.selected = false,
    super.key,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  /// Счётчик поверх иконки — например, число активных фильтров.
  final int? badge;

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final AuroraPalette palette = context.palette;
    final Widget button = SizedBox(
      width: AuroraSizes.itemSizeExtraSmall,
      height: AuroraSizes.itemSizeExtraSmall,
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        icon: Icon(icon),
        iconSize: AuroraSizes.iconSizeSmallPlus,
        style: IconButton.styleFrom(
          foregroundColor: selected ? palette.onAccentFill : palette.accent,
          backgroundColor: selected ? palette.accentFill : Colors.transparent,
        ),
      ),
    );

    if (badge == null || badge == 0) {
      return button;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        button,
        Positioned(
          right: AuroraSizes.paddingSmall,
          top: AuroraSizes.paddingSmall,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: palette.accentFill,
              borderRadius: AuroraRadius.large,
            ),
            child: Text(
              '$badge',
              style: TextStyle(
                fontSize: 11,
                height: 1.2,
                fontWeight: FontWeight.bold,
                color: palette.onAccentFill,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Строка поиска панели приложения.
///
/// Показывается в развёрнутом виде, минимальная ширина — 300dp (гайдлайн).
class AuroraSearchField extends StatelessWidget implements PreferredSizeWidget {
  const AuroraSearchField({
    required this.controller,
    required this.onChanged,
    this.hintText = 'Поиск',
    this.autofocus = true,
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;
  final bool autofocus;

  @override
  Size get preferredSize => const Size.fromHeight(
    AuroraSizes.itemSizeSmall + AuroraSizes.paddingSmall,
  );

  @override
  Widget build(BuildContext context) {
    final AuroraPalette palette = context.palette;
    final double margin = AuroraLayout.pageMargin(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        margin,
        0,
        margin,
        AuroraSizes.paddingMedium,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: AuroraSizes.searchFieldMinWidth,
        ),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          autofocus: autofocus,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(Icons.search, color: palette.textSecondary),
            suffixIcon: controller.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Очистить',
                    constraints: const BoxConstraints.tightFor(
                      width: AuroraSizes.itemSizeExtraSmall,
                      height: AuroraSizes.itemSizeExtraSmall,
                    ),
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                  ),
            suffixIconConstraints: const BoxConstraints.tightFor(
              width: AuroraSizes.itemSizeExtraSmall,
              height: AuroraSizes.itemSizeExtraSmall,
            ),
            isDense: true,
          ),
        ),
      ),
    );
  }
}
