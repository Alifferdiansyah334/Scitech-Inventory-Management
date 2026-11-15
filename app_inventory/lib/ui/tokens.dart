import 'package:flutter/widgets.dart';

export 'palette.dart';

/// Material 3 Expressive corner scale. Containers get large corners; grouped
/// list items use [listOuter] at the ends and [listInner] between items.
abstract final class AppRadii {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const lgPlus = 20.0;
  static const xl = 24.0;
  static const xxl = 28.0;
  static const hero = 40.0;
  static const listOuter = 28.0;
  static const listInner = 8.0;
  static const full = 999.0;
}

/// Spacing scale. Rows inside a group use 12-16; groups are separated by 24;
/// page sections by 32 (mobile) or 40 (wide).
abstract final class AppSpace {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const section = 40.0;
}

abstract final class AppFonts {
  /// Poppins, bundled 400-800.
  static const sans = 'Poppins';

  /// Headlines use the same family at 700/800 with tight tracking.
  static const display = 'Poppins';

  /// IDs and structured numbers only.
  static const mono = 'Roboto Mono';
}

/// Tabular figures for counts and dates that sit in columns.
const tabular = [FontFeature.tabularFigures()];

/// Compact identifier derived from the record, never an invented asset code.
String shortId(String id) {
  final clean = id.replaceAll(RegExp('[^A-Za-z0-9]'), '');
  if (clean.isEmpty) return '----';
  return clean.substring(0, clean.length < 4 ? clean.length : 4).toUpperCase();
}
