import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../ui/avatars.dart';
import '../ui/shapes.dart';
import '../ui/tokens.dart';

/// Profile picture choice, stored on this device per account.
class AvatarChoice {
  const AvatarChoice({this.preset = 0, this.frame = ExpressiveShape.cookie9, this.photo});
  final int preset;
  final ExpressiveShape frame;
  final Uint8List? photo;

  AvatarPreset get presetSpec => avatarPresets[preset.clamp(0, avatarPresets.length - 1)];

  AvatarChoice copyWith({int? preset, ExpressiveShape? frame, Uint8List? photo, bool clearPhoto = false}) =>
      AvatarChoice(
        preset: preset ?? this.preset,
        frame: frame ?? this.frame,
        photo: clearPhoto ? null : (photo ?? this.photo),
      );

  Map<String, Object?> toJson() => {
    'preset': preset,
    'frame': frame.name,
    if (photo != null) 'photo': base64Encode(photo!),
  };

  factory AvatarChoice.fromJson(Map<String, dynamic> j) => AvatarChoice(
    preset: j['preset'] as int? ?? 0,
    frame: ExpressiveShape.values.firstWhere((s) => s.name == j['frame'], orElse: () => ExpressiveShape.cookie9),
    photo: j['photo'] is String ? base64Decode(j['photo'] as String) : null,
  );
}

/// Theme, accessibility and device-only preferences ("Tema & tampilan",
/// "Pengaturan"), persisted with shared_preferences.
class AppearanceController extends ChangeNotifier {
  AppearanceController._(this._prefs);
  final SharedPreferences? _prefs;

  /// In-memory controller for tests and previews.
  AppearanceController.memory() : _prefs = null;

  static Future<AppearanceController> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppearanceController._(prefs).._read();
  }

  static const _k = 'sims_appearance_v1';

  SchemeKey scheme = SchemeKey.navy;
  ThemeMode mode = ThemeMode.system;
  bool dynamicColor = false;
  ContrastLevel contrast = ContrastLevel.standard;

  /// Multiplies the system text scale.
  double textScale = 1;
  bool reduceMotion = false;

  /// Default for "Kirim notifikasi WhatsApp ke admin" in the request form.
  bool whatsappByDefault = true;

  final Map<String, AvatarChoice> _avatars = {};

  /// Saved choice, or a preset picked from the account id so each person
  /// starts with a stable, distinct picture.
  AvatarChoice avatarFor(String userId) =>
      _avatars[userId] ?? AvatarChoice(preset: userId.codeUnits.fold<int>(0, (a, b) => a + b) % avatarPresets.length);

  void _read() {
    final raw = _prefs?.getString(_k);
    if (raw == null) return;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      // Saved legacy 'leaf' defaults start fresh on Navy Scitech.
      scheme = SchemeKey.values.firstWhere((s) => s.name == j['palette'], orElse: () => SchemeKey.navy);
      mode = ThemeMode.values.firstWhere((m) => m.name == j['mode'], orElse: () => ThemeMode.system);
      dynamicColor = j['dynamic'] as bool? ?? false;
      contrast = ContrastLevel.values.firstWhere((c) => c.name == j['contrast'], orElse: () => ContrastLevel.standard);
      textScale = (j['textScale'] as num?)?.toDouble() ?? 1;
      reduceMotion = j['reduceMotion'] as bool? ?? false;
      whatsappByDefault = j['whatsapp'] as bool? ?? true;
      final avatars = j['avatars'] as Map<String, dynamic>? ?? {};
      for (final e in avatars.entries) {
        _avatars[e.key] = AvatarChoice.fromJson(e.value as Map<String, dynamic>);
      }
    } on FormatException {
      // A corrupt entry falls back to defaults; the next change rewrites it.
    }
  }

  void _save() {
    notifyListeners();
    _prefs?.setString(
      _k,
      jsonEncode({
        'palette': scheme.name,
        'mode': mode.name,
        'dynamic': dynamicColor,
        'contrast': contrast.name,
        'textScale': textScale,
        'reduceMotion': reduceMotion,
        'whatsapp': whatsappByDefault,
        'avatars': {for (final e in _avatars.entries) e.key: e.value.toJson()},
      }),
    );
  }

  void setScheme(SchemeKey value) {
    scheme = value;
    dynamicColor = false;
    _save();
  }

  void setMode(ThemeMode value) {
    mode = value;
    _save();
  }

  void setDynamicColor(bool value) {
    dynamicColor = value;
    _save();
  }

  void setContrast(ContrastLevel value) {
    contrast = value;
    _save();
  }

  void setTextScale(double value) {
    textScale = value;
    _save();
  }

  void setReduceMotion(bool value) {
    reduceMotion = value;
    _save();
  }

  void setWhatsappByDefault(bool value) {
    whatsappByDefault = value;
    _save();
  }

  void setAvatar(String userId, AvatarChoice choice) {
    _avatars[userId] = choice;
    _save();
  }

  /// Palette for the given platform brightness and wallpaper colour.
  AppPalette resolve({required Brightness platform, Color? wallpaper}) {
    final dark = switch (mode) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system => platform == Brightness.dark,
    };
    return AppPalette.resolve(
      scheme: scheme,
      dark: dark,
      contrast: contrast,
      seedOverride: dynamicColor ? wallpaper : null,
    );
  }
}

/// Makes the [AppearanceController] reachable from any page.
class AppearanceScope extends InheritedNotifier<AppearanceController> {
  const AppearanceScope({required AppearanceController controller, required super.child, super.key})
    : super(notifier: controller);

  static AppearanceController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppearanceScope>()!.notifier!;
}
