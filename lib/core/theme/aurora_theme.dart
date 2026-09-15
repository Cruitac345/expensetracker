// SPDX-License-Identifier: BSD-3-Clause
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'aurora_colors.dart';
import 'aurora_tokens.dart';

/// Тема приложения по гайдлайну ОС Аврора.
///
/// Типографическая шкала повторяет референс Open Mobile Platform для
/// Flutter-приложений Авроры: заголовки 44/30/24, титулы 20/18/14,
/// основной текст 18/16/12 с межстрочным интервалом 1.3.
class AuroraTheme {
  const AuroraTheme._();

  static ThemeData light() => _build(AuroraPalette.light);

  static ThemeData dark() => _build(AuroraPalette.dark);

  static ThemeData _build(AuroraPalette palette) {
    final TextTheme textTheme = _textTheme(palette);

    return ThemeData(
      useMaterial3: true,
      brightness: palette.brightness,
      scaffoldBackgroundColor: palette.background,
      canvasColor: palette.background,
      dividerColor: palette.divider,
      textTheme: textTheme,
      // ОС Аврора использует Roboto как системную гарнитуру; на платформах
      // без неё Flutter подставит системный шрифт.
      fontFamily: 'Roboto',
      colorScheme: ColorScheme(
        brightness: palette.brightness,
        primary: palette.primary,
        onPrimary: palette.onPrimary,
        secondary: palette.secondary,
        onSecondary: palette.onPrimary,
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
        toolbarHeight: AuroraSizes.appBarHeight,
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AuroraSizes.paddingMedium + AuroraSizes.paddingSmall,
          vertical: AuroraSizes.paddingMedium + AuroraSizes.paddingSmall,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: palette.textSecondary),
        labelStyle: textTheme.bodyMedium?.copyWith(color: palette.textSecondary),
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
          borderSide: BorderSide(color: palette.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AuroraRadius.small,
          borderSide: BorderSide(color: palette.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AuroraRadius.small,
          borderSide: BorderSide(color: palette.danger, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: palette.onPrimary,
          elevation: 0,
          minimumSize: const Size.fromHeight(AuroraSizes.itemSizeExtraSmall),
          padding: const EdgeInsets.symmetric(
            horizontal: AuroraSizes.paddingLarge,
          ),
          textStyle: textTheme.titleMedium,
          shape: RoundedRectangleBorder(borderRadius: AuroraRadius.small),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.primary,
          minimumSize: const Size.fromHeight(AuroraSizes.itemSizeExtraSmall),
          padding: const EdgeInsets.symmetric(
            horizontal: AuroraSizes.paddingLarge,
          ),
          side: BorderSide(color: palette.primary),
          textStyle: textTheme.titleMedium,
          shape: RoundedRectangleBorder(borderRadius: AuroraRadius.small),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.primary,
          textStyle: textTheme.titleMedium,
          shape: RoundedRectangleBorder(borderRadius: AuroraRadius.small),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: palette.primary,
          minimumSize: const Size.square(AuroraSizes.iconSizeSmallPlus),
          shape: RoundedRectangleBorder(borderRadius: AuroraRadius.small),
        ),
      ),
      iconTheme: IconThemeData(
        color: palette.primary,
        size: AuroraSizes.iconSizeExtraSmall,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: palette.primary,
        textColor: palette.textPrimary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AuroraSizes.paddingMedium,
        ),
        shape: RoundedRectangleBorder(borderRadius: AuroraRadius.small),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: palette.surfaceVariant,
        selectedColor: palette.primary,
        side: BorderSide(color: palette.divider),
        labelStyle: textTheme.bodySmall,
        shape: RoundedRectangleBorder(borderRadius: AuroraRadius.large),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (Set<WidgetState> states) => states.contains(WidgetState.selected)
              ? palette.primary
              : palette.textSecondary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (Set<WidgetState> states) => states.contains(WidgetState.selected)
              ? palette.primary.withValues(alpha: 0.35)
              : palette.surfaceVariant,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.surfaceVariant,
        contentTextStyle: textTheme.bodyMedium,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AuroraRadius.small),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: palette.primary,
        foregroundColor: palette.onPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AuroraRadius.medium),
      ),
      dividerTheme: DividerThemeData(
        color: palette.divider,
        space: 1,
        thickness: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: palette.primary,
        linearTrackColor: palette.surfaceVariant,
      ),
    );
  }

  static TextTheme _textTheme(AuroraPalette palette) {
    const double lineHeight = 1.3;
    return TextTheme(
      headlineLarge: TextStyle(
        fontSize: 44,
        fontWeight: FontWeight.bold,
        color: palette.textPrimary,
      ),
      headlineMedium: TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.bold,
        color: palette.textPrimary,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: palette.textPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        height: lineHeight,
        fontWeight: FontWeight.w500,
        color: palette.textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        height: lineHeight,
        color: palette.textPrimary,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        height: lineHeight,
        color: palette.textSecondary,
      ),
      bodyLarge: TextStyle(
        fontSize: 18,
        height: lineHeight,
        color: palette.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: 16,
        height: lineHeight,
        color: palette.textPrimary,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        height: lineHeight,
        color: palette.textSecondary,
      ),
      labelLarge: TextStyle(
        fontSize: 16,
        height: lineHeight,
        fontWeight: FontWeight.w500,
        color: palette.textPrimary,
      ),
    );
  }
}
