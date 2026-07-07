import 'package:flutter/material.dart';

/// Planka's named background gradients, ported from the server client's
/// `styles.module.scss` (the `.background<Name>` rules) and keyed by the
/// `backgroundGradient` value the API returns.
///
/// ponytail: colors and stops are exact; angled `linear-gradient(<deg>)`
/// directions are normalized to top-left→bottom-right, and `radial-gradient`s
/// use a corner-anchored [RadialGradient]. The color identity is what reads at
/// board-background scale — the precise CSS angle is not load-bearing.
const Map<String, Gradient> _gradients = {
  'old-lime': LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF7B920A), Color(0xFFADD100)]),
  'ocean-dive': LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [Color(0xFF062E53), Color(0xFF1AD0E0)]),
  'tzepesch-style': LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF190A05), Color(0xFF870000)]),
  'jungle-mesh': LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF727A17), Color(0xFF414D0B)]),
  'strawberry-dust': LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFAC4F73), Color(0xFFFE9E96)]),
  'purple-rose': LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF742B3E), Color(0xFFC04767)]),
  'sun-scream': LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFBDD13), Color(0xFFFF9901)]),
  'warm-rust': LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFF5A08), Color(0xFF580000)]),
  'sky-change': LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF003459), Color(0xFF00A8E8)]),
  'green-eyes': LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF13AA52), Color(0xFF00662B)]),
  'blue-xchange': RadialGradient(
      center: Alignment.center,
      radius: 1.0,
      colors: [Color(0xFF294F83), Color(0xFF162C4A)]),
  'blood-orange': LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFD64759), Color(0xFFDA7352)]),
  'sour-peel': LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFD6F46), Color(0xFFFB9832)]),
  'green-ninja': LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF224E4D), Color(0xFF083023)]),
  'algae-green': RadialGradient(
      center: Alignment(-0.8, -0.6),
      radius: 1.2,
      colors: [Color(0xFF005F68), Color(0xFF0F9CA8)]),
  'coral-reef': LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFEEB37B), Color(0xFFD8674D), Color(0xFF722B36)]),
  'steel-grey': RadialGradient(
      center: Alignment(-1.0, -1.0),
      radius: 1.4,
      colors: [Color(0xFF4A626E), Color(0xFF1E2130)]),
  'heat-waves': LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Color(0xFF12C2E9), Color(0xFFC471ED), Color(0xFFF64F59)]),
  'velvet-lounge': RadialGradient(
      center: Alignment(-0.8, -0.6),
      radius: 1.3,
      colors: [Color(0xFF970A82), Color(0xFF212121)]),
  'purple-rain': LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF32194F), Color(0xFF7A6595)]),
  'blue-steel': LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [Color(0xFF09203F), Color(0xFF537895)]),
  'blueish-curve': LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF056F92), Color(0xFF063954)]),
  'prism-light': LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [
    Color(0xFFFBC606),
    Color(0xFFE0525F),
    Color(0xFFC24E9A),
    Color(0xFF20ADBE),
    Color(0xFF169E5F),
  ]),
  'green-mist': LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF008080), Color(0xFFAECE64)]),
  'red-curtain': RadialGradient(
      center: Alignment(-0.95, -0.7),
      radius: 1.3,
      colors: [Color(0xFFFF0066), Color(0xFF500523)]),
};

/// The Planka gradient for a `backgroundGradient` name, or null if unknown.
Gradient? plankaGradient(String? name) => name == null ? null : _gradients[name];

/// The gradient for a project's background, or null when there's none we render
/// (no background set, or an `image` background we don't load yet). Callers fall
/// back to a deterministic color.
Gradient? projectGradient(String? backgroundType, String? backgroundGradient) =>
    backgroundType == 'gradient' ? plankaGradient(backgroundGradient) : null;
