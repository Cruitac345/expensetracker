// SPDX-License-Identifier: BSD-3-Clause
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'aurora_colors.dart';
import 'aurora_tokens.dart';

/// Тема приложения по дизайн-системе ОС Аврора.
///
/// Типографическая шкала и размеры повторяют официальный UI Kit
/// «Aurora Controls»: размеры шрифта 12/14/16/19/21/26/28, межстрочный
/// интервал 1.25, начертания 400/500/700, радиус кнопок и полей 4.
class AuroraTheme {
  const AuroraTheme._();

  static ThemeData light() => _build(AuroraPalette.light);

  static ThemeData dark() => _build(AuroraPalette.dark);

  static ThemeData _build(AuroraPalette palette) {
    // Гарнитура применяется сразу: стили кнопок и полей берутся из этой
    // шкалы напрямую, поэтому семейство шрифта должно быть в ней уже задано.
    final TextTheme textTheme = _textTheme(palette).apply(fontFamily: 'Roboto');

    return ThemeData(
      useMaterial3: true,
      brightness: palette.brightness,
      scaffoldBackgroundColor: palette.background,
      canvasColor: palette.background,
      dividerColor: palette.divider,
      textTheme: textTheme,
      fontFamily: 'Roboto',
      colorScheme: ColorScheme(
        brightness: palette.brightness,
        primary: palette.accentFill,
        onPrimary: palette.onAccentFill,
        secondary: palette.accent,
        onSecondary: palette.onAccentFill,
        error: palette.danger,
        onError: const Color(0xFFFFFFFF),
        surface: palette.surface,
        onSurface: palette.textPrimary,
        surfaceContainerHighest: palette.surfaceVariant,
        outline: palette.divider,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        foregroundColor: palette.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: AuroraSizes.itemSizeHeader,
        systemOverlayStyle: palette.brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: palette.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: AuroraRadius.medium),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AuroraRadius.large),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AuroraSizes.paddingLarge,
          vertical: AuroraSizes.paddingMedium + AuroraSizes.paddingSmall,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: palette.textSecondary),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: palette.textSecondary,
        ),
        border: OutlineInputBorder(
          borderRadius: AuroraRadius.small,
          borderSide: BorderSide(color: palette.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AuroraRadius.small,
          borderSide: BorderSide(color: palette.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AuroraRadius.small,
          borderSide: BorderSide(
            color: palette.accent,
            width: AuroraSizes.lineWidth,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AuroraRadius.small,
          borderSide: BorderSide(color: palette.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AuroraRadius.small,
          borderSide: BorderSide(
            color: palette.danger,
            width: AuroraSizes.lineWidth,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.accentFill,
          foregroundColor: palette.onAccentFill,
          elevation: 0,
          minimumSize: const Size.fromHeight(AuroraSizes.itemSizeExtraSmall),
          padding: const EdgeInsets.symmetric(
            horizontal: AuroraSizes.paddingLarge,
          ),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: AuroraRadius.small),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.accent,
          minimumSize: const Size.fromHeight(AuroraSizes.itemSizeExtraSmall),
          padding: const EdgeInsets.symmetric(
            horizontal: AuroraSizes.paddingLarge,
          ),
          side: BorderSide(color: palette.accent, width: AuroraSizes.lineWidth),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: AuroraRadius.small),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.accent,
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: AuroraRadius.small),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: palette.accent,
          minimumSize: const Size.square(AuroraSizes.itemSizeExtraSmall),
          shape: RoundedRectangleBorder(borderRadius: AuroraRadius.small),
        ),
      ),
      iconTheme: IconThemeData(
        color: palette.accent,
        size: AuroraSizes.iconSizeSmall,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: palette.accent,
        textColor: palette.textPrimary,
        minVerticalPadding: AuroraSizes.paddingMedium,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AuroraSizes.paddingLarge,
        ),
        shape: RoundedRectangleBorder(borderRadius: AuroraRadius.small),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: palette.surfaceVariant,
        selectedColor: palette.accentFill,
        side: BorderSide(color: palette.divider),
        labelStyle: textTheme.bodyMedium,
        shape: RoundedRectangleBorder(borderRadius: AuroraRadius.small),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (Set<WidgetState> states) => states.contains(WidgetState.selected)
              ? palette.onAccentFill
              : palette.textSecondary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (Set<WidgetState> states) => states.contains(WidgetState.selected)
              ? palette.accentFill
              : palette.surfaceVariant,
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (Set<WidgetState> states) => states.contains(WidgetState.selected)
              ? palette.accent
              : palette.textSecondary,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.surfaceVariant,
        contentTextStyle: textTheme.bodyMedium,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AuroraRadius.small),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: palette.accentFill,
        foregroundColor: palette.onAccentFill,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AuroraRadius.small),
      ),
      dividerTheme: DividerThemeData(
        color: palette.divider,
        space: 1,
        thickness: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: palette.accent,
        linearTrackColor: palette.surfaceVariant,
      ),
    );
  }

  /// Текстовая шкала «Aurora Controls», разложенная по ролям Material.
  static TextTheme _textTheme(AuroraPalette palette) {
    const double height = AuroraFontSizes.lineHeight;

    return TextTheme(
      headlineLarge: TextStyle(
        fontSize: AuroraFontSizes.huge,
        height: height,
        letterSpacing: 0,
        fontWeight: AuroraFontWeights.bold,
        color: palette.textPrimary,
      ),
      headlineMedium: TextStyle(
        fontSize: AuroraFontSizes.extraLarge,
        height: height,
        letterSpacing: 0,
        fontWeight: AuroraFontWeights.bold,
        color: palette.textPrimary,
      ),
      headlineSmall: TextStyle(
        fontSize: AuroraFontSizes.large,
        height: height,
        letterSpacing: 0,
        fontWeight: AuroraFontWeights.bold,
        color: palette.textPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: AuroraFontSizes.large,
        height: height,
        letterSpacing: 0,
        fontWeight: AuroraFontWeights.medium,
        color: palette.textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: AuroraFontSizes.medium,
        height: height,
        letterSpacing: 0,
        fontWeight: AuroraFontWeights.regular,
        color: palette.textPrimary,
      ),
      titleSmall: TextStyle(
        fontSize: AuroraFontSizes.extraSmall,
        height: height,
        letterSpacing: 0,
        fontWeight: AuroraFontWeights.regular,
        color: palette.textSecondary,
      ),
      bodyLarge: TextStyle(
        fontSize: AuroraFontSizes.medium,
        height: height,
        letterSpacing: 0,
        fontWeight: AuroraFontWeights.regular,
        color: palette.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: AuroraFontSizes.small,
        height: height,
        letterSpacing: 0,
        fontWeight: AuroraFontWeights.regular,
        color: palette.textPrimary,
      ),
      bodySmall: TextStyle(
        fontSize: AuroraFontSizes.tiny,
        height: height,
        letterSpacing: 0,
        fontWeight: AuroraFontWeights.regular,
        color: palette.textSecondary,
      ),
      labelLarge: TextStyle(
        fontSize: AuroraFontSizes.small,
        height: height,
        letterSpacing: 0,
        fontWeight: AuroraFontWeights.medium,
        color: palette.textPrimary,
      ),
      labelMedium: TextStyle(
        fontSize: AuroraFontSizes.extraSmall,
        height: height,
        letterSpacing: 0,
        fontWeight: AuroraFontWeights.medium,
        color: palette.textPrimary,
      ),
    );
  }
}
