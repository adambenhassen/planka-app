import 'package:flutter/material.dart';

/// Planka-flavored blue used as the Material 3 seed.
const _seed = Color(0xFF2563EB);

/// App-level design tokens Material 3's [ColorScheme] doesn't express — the
/// surfaces and effects that give the Kanban board its Planka look. Held in a
/// [ThemeExtension] so widgets read them via `Theme.of(context)` and a dark
/// variant is a later addition, not a rewrite.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  /// List-column background. Slightly translucent so a colored board background
  /// tints through (the Planka/Trello list-over-background effect).
  final Color listSurface;

  /// Card background. Effectively opaque for legibility over any background.
  final Color cardSurface;

  /// Overlay painted over a board background to keep list/card text legible.
  final Color boardScrim;

  /// Shadow for a card while it is being dragged over the board background.
  final List<BoxShadow> dragShadow;

  const AppTokens({
    required this.listSurface,
    required this.cardSurface,
    required this.boardScrim,
    required this.dragShadow,
  });

  factory AppTokens.light(ColorScheme scheme) => AppTokens(
        listSurface: scheme.surfaceContainerLow.withValues(alpha: 0.94),
        cardSurface: scheme.surfaceContainerLowest,
        boardScrim: Colors.black.withValues(alpha: 0.06),
        dragShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );

  @override
  AppTokens copyWith({
    Color? listSurface,
    Color? cardSurface,
    Color? boardScrim,
    List<BoxShadow>? dragShadow,
  }) =>
      AppTokens(
        listSurface: listSurface ?? this.listSurface,
        cardSurface: cardSurface ?? this.cardSurface,
        boardScrim: boardScrim ?? this.boardScrim,
        dragShadow: dragShadow ?? this.dragShadow,
      );

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    return AppTokens(
      listSurface: Color.lerp(listSurface, other.listSurface, t)!,
      cardSurface: Color.lerp(cardSurface, other.cardSurface, t)!,
      boardScrim: Color.lerp(boardScrim, other.boardScrim, t)!,
      dragShadow: t < 0.5 ? dragShadow : other.dragShadow,
    );
  }
}

/// Convenience accessor: `context.tokens`.
extension AppTokensX on BuildContext {
  AppTokens get tokens => Theme.of(this).extension<AppTokens>()!;
}

class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(seedColor: _seed);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surfaceContainerLowest,
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        clipBehavior: Clip.antiAlias,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: scheme.surfaceTint,
        elevation: 0,
        scrolledUnderElevation: 2,
      ),
      extensions: [AppTokens.light(scheme)],
    );
  }
}

/// Deterministic Planka-style board colors derived from a name, so a board looks
/// the same every launch without needing a server-set background. Drawn from a
/// small curated palette of saturated colors that stay legible under a scrim.
const _boardPalette = <Color>[
  Color(0xFF1565C0), // ocean blue
  Color(0xFF00838F), // teal
  Color(0xFF3949AB), // indigo
  Color(0xFF2E7D32), // green
  Color(0xFF6A1B9A), // purple
  Color(0xFFD84315), // deep orange
  Color(0xFFAD1457), // pink
  Color(0xFF37474F), // blue-grey
];

/// Stable (cross-run) hash — Dart's [String.hashCode] isn't guaranteed stable
/// across VM versions, and board colors must not shift between launches.
int _stableHash(String s) {
  var h = 0;
  for (final c in s.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return h;
}

/// The base color for a board/project named [seed].
Color boardColor(String seed) =>
    _boardPalette[_stableHash(seed) % _boardPalette.length];

/// A subtle top-left→bottom-right gradient for a board background or tile.
LinearGradient boardGradient(String seed) {
  final base = boardColor(seed);
  final darker = Color.lerp(base, Colors.black, 0.22)!;
  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [base, darker],
  );
}
