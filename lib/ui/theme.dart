import 'package:flutter/material.dart';

/// "Ink & signal": near-black ink, one mint signal colour for "secure",
/// amber for "not verified", red only for key changes.
abstract final class Palette {
  static const bg = Color(0xFF0B0F14);
  static const surface = Color(0xFF131A22);
  static const raised = Color(0xFF1B2430);
  static const line = Color(0xFF263241);
  static const mint = Color(0xFF4DE3B5);
  static const amber = Color(0xFFF5B84A);
  static const danger = Color(0xFFFF5C6C);
  static const text = Color(0xFFE8EEF3);
  static const muted = Color(0xFF8A97A6);
  static const mono = TextStyle(fontFamily: 'monospace', letterSpacing: 1.5);
}

ThemeData buildTheme() {
  const scheme = ColorScheme.dark(
    primary: Palette.mint,
    onPrimary: Color(0xFF04221A),
    secondary: Palette.amber,
    error: Palette.danger,
    surface: Palette.surface,
    onSurface: Palette.text,
    onSurfaceVariant: Palette.muted,
    outline: Palette.line,
    surfaceContainerHighest: Palette.raised,
  );
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(18));
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Vazirmatn',
    colorScheme: scheme,
    scaffoldBackgroundColor: Palette.bg,
    appBarTheme: const AppBarTheme(
      backgroundColor: Palette.bg,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: Palette.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: shape.copyWith(side: const BorderSide(color: Palette.line)),
    ),
    dialogTheme: DialogThemeData(backgroundColor: Palette.raised, shape: shape),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Palette.surface,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Palette.raised,
      contentTextStyle: const TextStyle(color: Palette.text),
      shape: shape,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Palette.raised,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Palette.mint),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: shape,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: shape,
        side: const BorderSide(color: Palette.line),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 20),
    ),
  );
}
