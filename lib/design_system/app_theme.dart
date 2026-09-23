import 'package:flutter/material.dart';

abstract final class AppBreakpoints {
  static const compact = 700.0;
  static const expandedRail = 1180.0;
}

abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

@immutable
class KnowledgeColors extends ThemeExtension<KnowledgeColors> {
  const KnowledgeColors({
    required this.course,
    required this.concept,
    required this.note,
    required this.success,
    required this.warning,
  });

  final Color course;
  final Color concept;
  final Color note;
  final Color success;
  final Color warning;

  @override
  KnowledgeColors copyWith({
    Color? course,
    Color? concept,
    Color? note,
    Color? success,
    Color? warning,
  }) => KnowledgeColors(
    course: course ?? this.course,
    concept: concept ?? this.concept,
    note: note ?? this.note,
    success: success ?? this.success,
    warning: warning ?? this.warning,
  );

  @override
  KnowledgeColors lerp(covariant KnowledgeColors? other, double t) {
    if (other == null) return this;
    return KnowledgeColors(
      course: Color.lerp(course, other.course, t)!,
      concept: Color.lerp(concept, other.concept, t)!,
      note: Color.lerp(note, other.note, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }
}

abstract final class AppTheme {
  static const _seed = Color(0xff5b3e8c);

  static ThemeData light() => _theme(Brightness.light);
  static ThemeData dark() => _theme(Brightness.dark);

  static ThemeData _theme(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    final dark = brightness == Brightness.dark;
    final theme = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: dark
          ? const Color(0xff111014)
          : const Color(0xfff8f7fb),
      dividerColor: scheme.outlineVariant.withValues(alpha: .7),
      cardTheme: CardThemeData(
        color: dark ? const Color(0xff1b191f) : Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .7)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xff211f25) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size.square(48),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: dark ? const Color(0xff18161c) : Colors.white,
        indicatorColor: scheme.secondaryContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        selectedIconTheme: IconThemeData(color: scheme.onSecondaryContainer),
        selectedLabelTextStyle: TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
        unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
        unselectedLabelTextStyle: TextStyle(color: scheme.onSurfaceVariant),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: scheme.secondaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 13,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        waitDuration: const Duration(milliseconds: 350),
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: TextStyle(color: scheme.onInverseSurface, fontSize: 14),
      ),
      extensions: const [
        KnowledgeColors(
          course: Color(0xff2563eb),
          concept: Color(0xffc2410c),
          note: Color(0xff7c3aed),
          success: Color(0xff15803d),
          warning: Color(0xffb45309),
        ),
      ],
    );
    return theme.copyWith(
      textTheme: Typography.material2021().englishLike.apply(
        fontSizeFactor: 1.15,
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
    );
  }
}
