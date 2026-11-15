import 'package:flutter/material.dart';
import 'core/app_config.dart';
import 'core/appearance.dart';
import 'production/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appearance = await AppearanceController.load();
  runApp(ConnectedScitechApp(state: AppConfig.instance.appState, appearance: appearance));
}
