import 'package:flutter/material.dart';

class AppTheme {
  static const seed = Color(0xFF1B5E57); // deep teal

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    );
    return _base(scheme);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    );
    return _base(scheme);
  }

  static ThemeData _base(ColorScheme scheme) {
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      chipTheme: const ChipThemeData(
        shape: StadiumBorder(),
      ),
    );
  }
}

/// Renders Urdu text right-to-left with a larger, comfortable size.
class UrduText extends StatelessWidget {
  const UrduText(
    this.text, {
    super.key,
    this.style,
    this.textAlign = TextAlign.right,
  });

  final String text;
  final TextStyle? style;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Text(
        text,
        textAlign: textAlign,
        style: (style ?? const TextStyle()).copyWith(height: 1.6),
      ),
    );
  }
}

/// True if [s] contains Arabic/Urdu script characters.
bool isUrdu(String s) {
  for (final r in s.runes) {
    if (r >= 0x0600 && r <= 0x06FF) return true;
    if (r >= 0x0750 && r <= 0x077F) return true;
    if (r >= 0xFB50 && r <= 0xFDFF) return true;
  }
  return false;
}
