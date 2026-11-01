import 'package:flutter/widgets.dart';

/// Palette derived from the Scitech logo (navy #0F2C59). Accent orange is
/// reserved for deadlines and actions that are waiting on someone.
abstract final class AppColors {
  static const paper = Color(0xFFF3F2EE);
  static const surface = Color(0xFFFFFFFF);
  static const line = Color(0xFFD9D7D0);
  static const control = Color(0xFF8A8F98);
  static const ink = Color(0xFF0E1B2E);
  static const muted = Color(0xFF4F5B6B);
  static const faint = Color(0xFF5E6876);
  static const navy = Color(0xFF0F2C59);
  static const navy2 = Color(0xFF1D3F73);
  static const navySoft = Color(0xFFE6EBF3);
  static const navyMuted = Color(0xFFC9D3E3);
  static const accent = Color(0xFFF26B1D);
  static const accentText = Color(0xFFB4470C);
  static const accentSoft = Color(0xFFFDEBDD);
  static const ok = Color(0xFF1F7A4D);
  static const okSoft = Color(0xFFE3F2EA);
  static const bad = Color(0xFFB42318);
  static const badSoft = Color(0xFFFBE9E7);
}

abstract final class AppRadii {
  static const tag = 6.0;
  static const chip = 16.0;
  static const control = 16.0;
  static const card = 24.0;
  static const sheet = 32.0;
}

abstract final class AppFonts {
  static const sans = 'Fira Sans';
  static const mono = 'IBM Plex Mono';
}

/// Short, label-style identifier taken from the real record id (first four
/// hexadecimal characters), matching the asset tag motif.
String shortId(String id) {
  final clean = id.replaceAll(RegExp('[^A-Za-z0-9]'), '');
  if (clean.isEmpty) return '----';
  return clean.substring(0, clean.length < 4 ? clean.length : 4).toUpperCase();
}
