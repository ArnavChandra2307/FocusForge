import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Core Palette ───────────────────────────────────────────────────────────

  /// Primary backgrounds
  static const Color backgroundPrimary   = Color(0xFF090909);
  static const Color backgroundSecondary = Color(0xFF141414);
  static const Color surface             = Color(0xFF1A1A1A);
  static const Color surfaceElevated     = Color(0xFF202020);

  /// Borders
  static const Color borderSubtle   = Color(0xFF1E1E1E);
  static const Color borderDefault  = Color(0xFF2A2A2A);
  static const Color borderStrong   = Color(0xFF3A3A3A);

  /// Text hierarchy
  static const Color textPrimary    = Color(0xFFF0F0F0);
  static const Color textSecondary  = Color(0xFF888888);
  static const Color textMuted      = Color(0xFF555555);
  static const Color textDisabled   = Color(0xFF333333);

  /// Semantic colors
  static const Color accent  = Color(0xFF4F8CFF); // primary interactive
  static const Color success = Color(0xFF00D26A);
  static const Color warning = Color(0xFFFFB800);
  static const Color danger  = Color(0xFFFF4D4D);

  /// Accent tints (for backgrounds behind accent elements)
  static const Color accentTint   = Color(0x1A4F8CFF); // 10% accent
  static const Color successTint  = Color(0x1A00D26A);
  static const Color warningTint  = Color(0x1AFFB800);
  static const Color dangerTint   = Color(0x1AFF4D4D);

  // ─── Subject Colors ──────────────────────────────────────────────────────────
  // Each subject gets a distinct but harmonious accent.
  // All are muted/desaturated to stay premium — no neon.

  static const Color physicsColor          = Color(0xFF4F8CFF); // Blue
  static const Color chemistryColor        = Color(0xFF8B6FFF); // Violet
  static const Color biologyColor          = Color(0xFF3DD68C); // Green
  static const Color mathsColor            = Color(0xFFFFB84D); // Amber
  static const Color englishLanguageColor  = Color(0xFF4ECDC4); // Teal
  static const Color englishLitColor       = Color(0xFF4ECDC4); // Teal (same family)
  static const Color hindiColor            = Color(0xFFFF8A65); // Coral
  static const Color geographyColor        = Color(0xFF57A6A1); // Sea green
  static const Color historyColor          = Color(0xFFCD9B4E); // Gold
  static const Color computerColor         = Color(0xFF7CB9E8); // Sky blue

  /// Returns the color for a given subject name.
  static Color subjectColor(String subject) {
    switch (subject.toLowerCase().trim()) {
      case 'physics':
        return physicsColor;
      case 'chemistry':
        return chemistryColor;
      case 'biology':
        return biologyColor;
      case 'mathematics':
      case 'maths':
        return mathsColor;
      case 'english language':
        return englishLanguageColor;
      case 'english literature':
        return englishLitColor;
      case 'hindi':
        return hindiColor;
      case 'geography':
        return geographyColor;
      case 'history & civics':
      case 'history':
      case 'civics':
        return historyColor;
      case 'computer applications':
      case 'computer application':
        return computerColor;
      default:
        return accent;
    }
  }

  /// Returns a 10% tint of the subject color for card backgrounds.
  static Color subjectTint(String subject) {
    return subjectColor(subject).withAlpha(26); // ~10%
  }

  // ─── Typography ──────────────────────────────────────────────────────────────

  /// DM Sans — body, UI, labels, captions
  static TextStyle dmSans({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color color = textPrimary,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.dmSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  /// Instrument Serif — display numbers, streak counts, hero moments
  static TextStyle instrumentSerif({
    double fontSize = 48,
    FontWeight fontWeight = FontWeight.w400,
    Color color = textPrimary,
    FontStyle fontStyle = FontStyle.normal,
    double? letterSpacing,
  }) {
    return GoogleFonts.instrumentSerif(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
    );
  }

  // ─── Theme ───────────────────────────────────────────────────────────────────

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    colorScheme: const ColorScheme.dark(
      primary:            accent,
      secondary:          Color(0xFF8B6FFF),
      tertiary:           success,
      surface:            backgroundSecondary,
      error:              danger,
      onPrimary:          backgroundPrimary,
      onSecondary:        backgroundPrimary,
      onSurface:          textPrimary,
      outline:            borderDefault,
      outlineVariant:     borderSubtle,
      surfaceContainerHighest: surface,
    ),

    scaffoldBackgroundColor: backgroundPrimary,

    textTheme: GoogleFonts.dmSansTextTheme(
      TextTheme(
        // Display — used for large hero numbers (supplement with instrumentSerif directly)
        displayLarge: GoogleFonts.dmSans(
          fontSize: 36, fontWeight: FontWeight.w300, color: textPrimary,
          letterSpacing: -0.02 * 36,
        ),
        displayMedium: GoogleFonts.dmSans(
          fontSize: 28, fontWeight: FontWeight.w300, color: textPrimary,
          letterSpacing: -0.02 * 28,
        ),

        // Headlines — screen titles, card headers
        headlineLarge: GoogleFonts.dmSans(
          fontSize: 24, fontWeight: FontWeight.w500, color: textPrimary,
          letterSpacing: -0.01 * 24,
        ),
        headlineMedium: GoogleFonts.dmSans(
          fontSize: 20, fontWeight: FontWeight.w500, color: textPrimary,
          letterSpacing: -0.01 * 20,
        ),
        headlineSmall: GoogleFonts.dmSans(
          fontSize: 18, fontWeight: FontWeight.w500, color: textPrimary,
        ),

        // Titles — card section headers
        titleLarge: GoogleFonts.dmSans(
          fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary,
        ),
        titleMedium: GoogleFonts.dmSans(
          fontSize: 15, fontWeight: FontWeight.w500, color: textPrimary,
        ),
        titleSmall: GoogleFonts.dmSans(
          fontSize: 13, fontWeight: FontWeight.w500, color: textSecondary,
        ),

        // Body — content text
        bodyLarge: GoogleFonts.dmSans(
          fontSize: 15, fontWeight: FontWeight.w400, color: textPrimary,
          height: 1.6,
        ),
        bodyMedium: GoogleFonts.dmSans(
          fontSize: 14, fontWeight: FontWeight.w400, color: textPrimary,
          height: 1.5,
        ),
        bodySmall: GoogleFonts.dmSans(
          fontSize: 13, fontWeight: FontWeight.w400, color: textSecondary,
          height: 1.5,
        ),

        // Labels — all caps metadata, badges, captions
        labelLarge: GoogleFonts.dmSans(
          fontSize: 12, fontWeight: FontWeight.w500, color: textPrimary,
          letterSpacing: 0.06 * 12,
        ),
        labelMedium: GoogleFonts.dmSans(
          fontSize: 11, fontWeight: FontWeight.w500, color: textSecondary,
          letterSpacing: 0.08 * 11,
        ),
        labelSmall: GoogleFonts.dmSans(
          fontSize: 10, fontWeight: FontWeight.w500, color: textMuted,
          letterSpacing: 0.1 * 10,
        ),
      ),
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleTextStyle: GoogleFonts.dmSans(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: textPrimary,
        letterSpacing: -0.01 * 18,
      ),
      iconTheme: const IconThemeData(color: textSecondary, size: 20),
    ),

    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: borderSubtle, width: 0.5),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: backgroundSecondary,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: borderDefault, width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: borderDefault, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: accent, width: 1.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: danger, width: 0.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: danger, width: 1.0),
      ),
      labelStyle: GoogleFonts.dmSans(color: textMuted, fontSize: 13),
      hintStyle: GoogleFonts.dmSans(color: textDisabled, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        disabledBackgroundColor: borderDefault,
        disabledForegroundColor: textMuted,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 20),
        textStyle: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: accent,
        side: const BorderSide(color: borderDefault, width: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 20),
        textStyle: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w400),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: accent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500),
      ),
    ),

    dividerTheme: const DividerThemeData(
      color: borderSubtle,
      thickness: 0.5,
      space: 0,
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: backgroundPrimary,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      height: 64,
      indicatorColor: accentTint,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return GoogleFonts.dmSans(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: accent,
            letterSpacing: 0.04 * 10,
          );
        }
        return GoogleFonts.dmSans(
          fontSize: 10,
          fontWeight: FontWeight.w400,
          color: textDisabled,
          letterSpacing: 0.04 * 10,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: accent, size: 20);
        }
        return const IconThemeData(color: textDisabled, size: 20);
      }),
    ),

    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: backgroundPrimary,
      selectedItemColor: accent,
      unselectedItemColor: textDisabled,
      selectedLabelStyle: GoogleFonts.dmSans(
        fontSize: 10, fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: GoogleFonts.dmSans(
        fontSize: 10, fontWeight: FontWeight.w400,
      ),
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.white;
        return textMuted;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return accent;
        return surface;
      }),
      trackOutlineColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.transparent;
        return borderDefault;
      }),
    ),

    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return accent;
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(Colors.white),
      side: const BorderSide(color: borderDefault, width: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: surfaceElevated,
      contentTextStyle: GoogleFonts.dmSans(
        fontSize: 13, color: textPrimary, fontWeight: FontWeight.w400,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: borderDefault, width: 0.5),
      ),
      behavior: SnackBarBehavior.floating,
      elevation: 0,
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: backgroundSecondary,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: borderDefault, width: 0.5),
      ),
      titleTextStyle: GoogleFonts.dmSans(
        fontSize: 17, fontWeight: FontWeight.w500, color: textPrimary,
      ),
      contentTextStyle: GoogleFonts.dmSans(
        fontSize: 14, color: textSecondary,
      ),
    ),

    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: backgroundSecondary,
      modalBackgroundColor: backgroundSecondary,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),

    listTileTheme: ListTileThemeData(
      tileColor: Colors.transparent,
      iconColor: textSecondary,
      titleTextStyle: GoogleFonts.dmSans(
        fontSize: 14, fontWeight: FontWeight.w400, color: textPrimary,
      ),
      subtitleTextStyle: GoogleFonts.dmSans(
        fontSize: 12, color: textMuted,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    ),

    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: accent,
      linearTrackColor: borderSubtle,
      circularTrackColor: borderSubtle,
    ),

    sliderTheme: SliderThemeData(
      activeTrackColor: accent,
      inactiveTrackColor: borderDefault,
      thumbColor: accent,
      overlayColor: accentTint,
      trackHeight: 3,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
    ),
  );

  static ThemeData get lightTheme => darkTheme;
}