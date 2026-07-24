import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────────────────

/// Seed color for the entire Material 3 color scheme.
const Color kSeedColor = Color(0xFF0F7A6A);

/// Shape radii — use these named constants, never inline values.
class AppRadius {
  AppRadius._();
  static const double card = 24;
  static const double dialog = 28;
  static const double chip = 10;
  static const double button = 12;
  static const double banner = 12;
  static const double inputField = 24;
  static const double categoryCard = 18;
}

/// Urdu typography constants.
class UrduType {
  UrduType._();
  /// Line-height multiplier for Urdu headwords (displaySmall and up).
  static const double headHeight = 1.8;
  /// Line-height multiplier for Urdu body / subtitle text.
  static const double bodyHeight = 1.6;
}

// ─────────────────────────────────────────────────────────────────────────────
// THEME
// ─────────────────────────────────────────────────────────────────────────────

class AppTheme {
  AppTheme._();

  static ThemeData light() => _base(
        ColorScheme.fromSeed(
          seedColor: kSeedColor,
          brightness: Brightness.light,
        ),
      );

  static ThemeData dark() => _base(
        ColorScheme.fromSeed(
          seedColor: kSeedColor,
          brightness: Brightness.dark,
        ),
      );

  static ThemeData _base(ColorScheme scheme) {
    final tt = _typeScale(scheme);
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      textTheme: tt,

      // Scaffold
      scaffoldBackgroundColor: scheme.surface,

      // AppBar — zero elevation, tonal surface
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: scheme.surfaceTint,
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: false,
        titleTextStyle: tt.titleLarge?.copyWith(color: scheme.onSurface),
      ),

      // Cards — tonal surface, no shadow
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.45),
            width: 1,
          ),
        ),
        margin: EdgeInsets.zero,
      ),

      // Input fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.inputField),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.inputField),
          borderSide: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.inputField),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        hintStyle: tt.bodyLarge?.copyWith(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
      ),

      // Chips — smaller radius, not stadium
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.chip),
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        labelStyle: tt.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),

      // Buttons
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          minimumSize: const Size(64, 48),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          minimumSize: const Size(64, 48),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          minimumSize: const Size(48, 48),
        ),
      ),

      // ListTile — 48px min touch target
      listTileTheme: ListTileThemeData(
        minTileHeight: 56,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),

      // Dividers
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.4),
        thickness: 1,
        space: 1,
      ),

      // NavigationBar
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return tt.labelSmall?.copyWith(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          );
        }),
      ),

      // BottomSheet
      bottomSheetTheme: BottomSheetThemeData(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.dialog),
          ),
        ),
        backgroundColor: scheme.surfaceContainerLow,
      ),

      // Dialogs
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.dialog),
        ),
        backgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.banner),
        ),
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: tt.bodyMedium?.copyWith(color: scheme.onInverseSurface),
      ),
    );
  }

  // ── Type scale ──────────────────────────────────────────────────────────────
  static TextTheme _typeScale(ColorScheme scheme) {
    return const TextTheme(
      displayLarge: TextStyle(
          fontSize: 57, fontWeight: FontWeight.w400, letterSpacing: -0.25),
      displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.w400),
      displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.w400),
      headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w600),
      headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
      headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(
          fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: 0),
      titleMedium: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 0.15),
      titleSmall: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1),
      bodyLarge: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.5),
      bodyMedium: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.25),
      bodySmall: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.4),
      labelLarge: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1),
      labelMedium: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5),
      labelSmall: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5),
    );
  }

  // ── Urdu text style helpers ──────────────────────────────────────────────────

  /// Large Urdu headword style (Word of the Day, word detail page).
  static TextStyle urduHeadStyle(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return (tt.displaySmall ?? const TextStyle()).copyWith(
      height: UrduType.headHeight,
      fontWeight: FontWeight.bold,
    );
  }

  /// Smaller Urdu text for body/subtitles.
  static TextStyle urduBodyStyle(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return (tt.bodyLarge ?? const TextStyle()).copyWith(
      height: UrduType.bodyHeight,
    );
  }

  /// Urdu style for list tiles (search results, categories, etc.).
  static TextStyle urduListStyle(BuildContext context) {
    return const TextStyle(fontSize: 22, height: UrduType.bodyHeight);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// URDU TEXT WIDGET
// ─────────────────────────────────────────────────────────────────────────────

/// Renders Urdu text right-to-left with correct line-height.
/// Always set [semanticsLabel] for accessibility (TalkBack/VoiceOver).
class UrduText extends StatelessWidget {
  const UrduText(
    this.text, {
    super.key,
    this.style,
    this.textAlign = TextAlign.right,
    this.semanticsLabel,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final TextStyle? style;
  final TextAlign textAlign;

  /// Explicit label for screen readers. If null, falls back to [text].
  final String? semanticsLabel;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final base = style ?? const TextStyle();
    // Ensure height is set if not already specified by the incoming style.
    final effective = base.height != null
        ? base
        : base.copyWith(height: UrduType.bodyHeight);

    return Semantics(
      label: semanticsLabel ?? text,
      excludeSemantics: true,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Text(
          text,
          textAlign: textAlign,
          style: effective,
          maxLines: maxLines,
          overflow: overflow,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────

/// True if [s] contains Arabic/Urdu script characters.
bool isUrdu(String s) {
  for (final r in s.runes) {
    if (r >= 0x0600 && r <= 0x06FF) return true;
    if (r >= 0x0750 && r <= 0x077F) return true;
    if (r >= 0xFB50 && r <= 0xFDFF) return true;
  }
  return false;
}
