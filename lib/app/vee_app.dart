import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_localizations.dart';
import '../widgets/auth_gate.dart';
import '../widgets/ui_core/vee_tokens.dart';
import '../widgets/ui_core/vee_text_styles.dart';

class VeeApp extends ConsumerWidget {
  const VeeApp({super.key});

  static const Color _seedColor = Color(0xFFE85D30);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      title: 'Vee',
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      home: const AuthGate(),
    );
  }

  static ThemeData _buildTheme(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: brightness,
    );
    final isDark = brightness == Brightness.dark;
    final textTheme = VeeTextStyles.buildTextTheme();

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      textTheme: textTheme,

      // ── Scaffold ──────────────────────────────────────────────────────────
      scaffoldBackgroundColor: isDark
          ? VeeTokens.surfaceDefaultDark
          : VeeTokens.surfaceDefault,

      // ── AppBar ────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: VeeTokens.textPrimaryVal,
        scrolledUnderElevation: 0,
        elevation: VeeTokens.elevationNone,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: VeeTokens.textPrimaryVal,
        ),
        iconTheme: const IconThemeData(
          color: VeeTokens.textPrimaryVal,
          size: VeeTokens.iconLg,
        ),
        actionsIconTheme: const IconThemeData(
          color: VeeTokens.textPrimaryVal,
          size: VeeTokens.iconLg,
        ),
      ),

      // ── Card ──────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: VeeTokens.elevationNone,
        margin: EdgeInsets.zero,
        color: isDark ? VeeTokens.surfaceCardDark : VeeTokens.surfaceCard,
        shape: VeeTokens.cardShape,
        clipBehavior: Clip.antiAlias,
      ),

      // ── [Fix 9] InkWell / Splash 전역 색상 ──────────────────────────────
      //
      // Material 기본 회색 물결(#1F000000)을 브랜드 오렌지 기반으로 교체.
      // 이 설정이 적용되는 위젯:
      //   InkWell, InkResponse, ListTile, Card, FilledButton.tonal,
      //   OutlinedButton, TextButton, NavigationBar 항목 탭 피드백 등
      //
      // splashFactory: InkSparkle는 Android 12+ ripple 효과.
      // iOS / Web에서는 자동으로 InkRipple로 폴백됨.
      splashFactory: InkSparkle.splashFactory,
      splashColor: VeeTokens.selectedTint(colorScheme.primary), // 12%
      highlightColor: VeeTokens.hoverTint(colorScheme.primary), // 8%
      // ── Input Decoration ──────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? VeeTokens.surfaceCardDark : VeeTokens.surfaceCard,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: VeeTokens.s16,
          vertical: VeeTokens.s16,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: VeeTokens.textPlaceholderVal,
          fontSize: 13,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: VeeTokens.textSecondaryVal,
        ),
        floatingLabelStyle: WidgetStateTextStyle.resolveWith((states) {
          if (states.contains(WidgetState.focused)) {
            return textTheme.labelMedium!.copyWith(color: colorScheme.primary);
          }
          return textTheme.labelMedium!.copyWith(
            color: VeeTokens.textSecondaryVal,
          );
        }),
        border: OutlineInputBorder(
          borderRadius: VeeTokens.inputBorderRadius,
          borderSide: VeeTokens.defaultBorder,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: VeeTokens.inputBorderRadius,
          borderSide: VeeTokens.defaultBorder,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: VeeTokens.inputBorderRadius,
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: VeeTokens.inputBorderRadius,
          borderSide: VeeTokens.errorBorder,
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: VeeTokens.inputBorderRadius,
          borderSide: VeeTokens.errorBorder,
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: VeeTokens.inputBorderRadius,
          borderSide: BorderSide(color: VeeTokens.borderColor.withOpacity(0.5)),
        ),
      ),

      // ── FilledButton ──────────────────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, VeeTokens.touchStandard),
          shape: const RoundedRectangleBorder(
            borderRadius: VeeTokens.buttonBorderRadius,
          ),
          textStyle: textTheme.labelLarge,
          padding: const EdgeInsets.symmetric(
            horizontal: VeeTokens.s20,
            vertical: VeeTokens.s12,
          ),
        ),
      ),

      // ── OutlinedButton ────────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, VeeTokens.touchStandard),
          shape: const RoundedRectangleBorder(
            borderRadius: VeeTokens.buttonBorderRadius,
          ),
          textStyle: textTheme.labelLarge,
          side: VeeTokens.defaultBorder,
          padding: const EdgeInsets.symmetric(
            horizontal: VeeTokens.s20,
            vertical: VeeTokens.s12,
          ),
        ),
      ),

      // ── TextButton ────────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, VeeTokens.touchMin),
          textStyle: textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: VeeTokens.s12,
            vertical: VeeTokens.s8,
          ),
        ),
      ),

      // ── Chip ──────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        labelStyle: textTheme.labelMedium,
        padding: VeeTokens.chipPadding,
        shape: const StadiumBorder(),
        side: VeeTokens.defaultBorder,
        backgroundColor: VeeTokens.surfaceSunken,
        selectedColor: VeeTokens.selectedTint(colorScheme.primary),
        checkmarkColor: colorScheme.primary,
        elevation: VeeTokens.elevationNone,
      ),

      // ── NavigationBar ─────────────────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark
            ? VeeTokens.surfaceCardDark
            : VeeTokens.surfaceCard,
        surfaceTintColor: Colors.transparent,

        // [Fix 8] 선택 인디케이터: 타원 → 둥근 사각형 (rMd=12px)
        // 이전: 기본 StadiumBorder (pill 형태)
        // 이후: RoundedRectangleBorder → 카드/버튼 원각과 통일
        indicatorColor: VeeTokens.selectedTint(colorScheme.primary),
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(VeeTokens.rMd)),
        ),

        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return textTheme.labelSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            );
          }
          return textTheme.labelSmall?.copyWith(
            color: VeeTokens.textSecondaryVal,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              color: colorScheme.primary,
              size: VeeTokens.iconLg,
            );
          }
          return const IconThemeData(
            color: VeeTokens.textSecondaryVal,
            size: VeeTokens.iconLg,
          );
        }),
        elevation: VeeTokens.elevationNone,
        height: 64,
      ),

      // ── NavigationRail ────────────────────────────────────────────────────
      // [Fix 8 연동] Rail도 동일한 둥근 사각형 인디케이터 적용
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: isDark
            ? VeeTokens.surfaceCardDark
            : VeeTokens.surfaceCard,
        selectedIconTheme: IconThemeData(color: colorScheme.primary),
        unselectedIconTheme: const IconThemeData(
          color: VeeTokens.textSecondaryVal,
        ),
        indicatorColor: VeeTokens.selectedTint(colorScheme.primary),
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(VeeTokens.rMd)),
        ),
        elevation: VeeTokens.elevationNone,
      ),

      // ── BottomSheet ───────────────────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark
            ? VeeTokens.surfaceCardDark
            : VeeTokens.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: VeeTokens.sheetBorderRadius,
        ),
        elevation: VeeTokens.elevationModal,
        showDragHandle: false,
        clipBehavior: Clip.antiAlias,
      ),

      // ── Dialog ────────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        elevation: VeeTokens.elevationModal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VeeTokens.rXl),
        ),
        backgroundColor: isDark
            ? VeeTokens.surfaceCardDark
            : VeeTokens.surfaceCard,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: VeeTokens.textPrimaryVal,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: VeeTokens.textSecondaryVal,
        ),
      ),

      // ── Divider ───────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        thickness: 1.0,
        color: isDark ? VeeTokens.borderColorDark : VeeTokens.borderColor,
        space: 1.0,
      ),

      // ── ListTile ──────────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: VeeTokens.s16,
          vertical: VeeTokens.s4,
        ),
        titleTextStyle: textTheme.titleSmall,
        subtitleTextStyle: textTheme.bodySmall?.copyWith(
          color: VeeTokens.textSecondaryVal,
        ),
        leadingAndTrailingTextStyle: textTheme.bodySmall,
        minLeadingWidth: VeeTokens.s16,
        minVerticalPadding: VeeTokens.s8,
      ),

      // ── SnackBar ──────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VeeTokens.rMd),
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        actionTextColor: colorScheme.inversePrimary,
      ),

      // ── FloatingActionButton ──────────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VeeTokens.rLg),
        ),
        elevation: VeeTokens.elevationToast,
        focusElevation: VeeTokens.elevationToast,
        hoverElevation: VeeTokens.elevationModal,
      ),

      // ── Switch ────────────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return VeeTokens.selectedTint(colorScheme.primary);
          }
          return VeeTokens.borderColor;
        }),
      ),

      // ── ProgressIndicator ─────────────────────────────────────────────────
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: VeeTokens.borderColor,
        linearMinHeight: 6,
        circularTrackColor: VeeTokens.borderColor,
      ),
    );
  }
}
