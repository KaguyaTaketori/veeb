// lib/app/vee_app.dart
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
      theme: _buildTheme(),
      home: const AuthGate(),
    );
  }

  static ThemeData _buildTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    );
    final textTheme = VeeTextStyles.buildTextTheme();

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      textTheme: textTheme,

      // ── Scaffold ──────────────────────────────────────────────────────────
      // 全局背景色，各页面无需重复设置 backgroundColor: Colors.grey.shade50
      scaffoldBackgroundColor: VeeTokens.surfaceDefault,

      // ── AppBar ────────────────────────────────────────────────────────────
      // 透明背景 + 无分割线 + 居中标题，与 Vee 设计规范一致
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
      // 扁平卡片 + 细边框，作用于所有未显式设置 shape 的 Card widget
      // 注意：显式设置了 shape 的 Card（如 VeeCard）不受此影响
      cardTheme: CardTheme(
        elevation: VeeTokens.elevationNone,
        margin: EdgeInsets.zero,
        color: VeeTokens.surfaceCard,
        shape: VeeTokens.cardShape,
        clipBehavior: Clip.antiAlias,
      ),

      // ── Input Decoration ──────────────────────────────────────────────────
      // 全局统一所有 TextField / TextFormField 的默认外观。
      // 各页面显式设置的 InputDecoration 属性会覆盖此处的默认值。
      // 效果：原先散落在各页面的 border / fillColor / contentPadding 定义
      //       现在只需在此处维护一份。
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: VeeTokens.surfaceCard,
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
          return textTheme.labelMedium!.copyWith(color: VeeTokens.textSecondaryVal);
        }),
        // ── Borders ─────────────────────────────────────────────────────
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
          borderSide: BorderSide(
            color: VeeTokens.borderColor.withOpacity(0.5),
          ),
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
        backgroundColor: VeeTokens.surfaceCard,
        surfaceTintColor: Colors.transparent,
        indicatorColor: VeeTokens.selectedTint(colorScheme.primary),
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
            return IconThemeData(color: colorScheme.primary, size: VeeTokens.iconLg);
          }
          return const IconThemeData(color: VeeTokens.textSecondaryVal, size: VeeTokens.iconLg);
        }),
        elevation: VeeTokens.elevationNone,
        height: 64,
      ),

      // ── NavigationRail ────────────────────────────────────────────────────
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: VeeTokens.surfaceCard,
        selectedIconTheme: IconThemeData(color: colorScheme.primary),
        unselectedIconTheme: const IconThemeData(color: VeeTokens.textSecondaryVal),
        indicatorColor: VeeTokens.selectedTint(colorScheme.primary),
        elevation: VeeTokens.elevationNone,
      ),

      // ── BottomSheet ───────────────────────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: VeeTokens.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: VeeTokens.sheetBorderRadius,
        ),
        elevation: VeeTokens.elevationModal,
        showDragHandle: false,
        clipBehavior: Clip.antiAlias,
      ),

      // ── Dialog ────────────────────────────────────────────────────────────
      dialogTheme: DialogTheme(
        elevation: VeeTokens.elevationModal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VeeTokens.rXl),
        ),
        backgroundColor: VeeTokens.surfaceCard,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: VeeTokens.textPrimaryVal,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: VeeTokens.textSecondaryVal,
        ),
      ),

      // ── Divider ───────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        thickness: 1.0,
        color: VeeTokens.borderColor,
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
        backgroundColor: const Color(0xFF2D2D2D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VeeTokens.rMd),
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        actionTextColor: colorScheme.primary.withOpacity(0.9),
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
          if (states.contains(WidgetState.selected)) return colorScheme.primary;
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