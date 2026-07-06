import 'package:flutter/material.dart';

/// Planka's label palette, ordered as the create-label dialog shows it:
/// (color name → display color). The single source for both the name→color
/// lookup ([labelColor]) and the picker's swatch list ([kLabelColorNames]).
const _labelPalette = <(String, Color)>[
  ('berry-red', Color(0xFFE04556)),
  ('pumpkin-orange', Color(0xFFF0982D)),
  ('lagoon-blue', Color(0xFF109DC0)),
  ('pink-tulip', Color(0xFFF97394)),
  ('light-mud', Color(0xFFC7A57B)),
  ('orange-peel', Color(0xFFFAB623)),
  ('bright-moss', Color(0xFFA5C261)),
  ('antique-blue', Color(0xFF6A85A0)),
  ('dark-granite', Color(0xFF8B8680)),
  ('turquoise-sea', Color(0xFF29A886)),
  ('sunny-grass', Color(0xFFBDC847)),
  ('morning-sky', Color(0xFF66A8D4)),
  ('light-orange', Color(0xFFECA66E)),
  ('midnight-blue', Color(0xFF2B394F)),
  ('tank-green', Color(0xFF9AA177)),
  ('gun-metal', Color(0xFF5C6772)),
  ('wet-moss', Color(0xFF3F8955)),
  ('red-burgundy', Color(0xFFAD5F7D)),
  ('light-concrete', Color(0xFFAFB0A4)),
  ('apricot-red', Color(0xFFF56B62)),
  ('desert-sand', Color(0xFFEDCB76)),
  ('navy-blue', Color(0xFF16344D)),
  ('egg-yellow', Color(0xFFF7D036)),
  ('coral-green', Color(0xFF4FD683)),
  ('light-cocoa', Color(0xFFAD8D71)),
];

final _labelColors = <String, Color>{
  for (final (name, color) in _labelPalette) name: color,
  // Planka spelling alias of lagoon-blue seen in some server payloads.
  'lagune-blue': const Color(0xFF109DC0),
};

/// Ordered label color names for the create-label picker.
final kLabelColorNames = [for (final (name, _) in _labelPalette) name];

/// The display color for a Planka label color name; a neutral for unknowns.
Color labelColor(String name) => _labelColors[name] ?? const Color(0xFF8B8680);
