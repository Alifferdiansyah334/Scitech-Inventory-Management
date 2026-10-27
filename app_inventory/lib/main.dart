import 'package:flutter/material.dart';
import 'core/app_config.dart';
import 'production/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ConnectedScitechApp(state: AppConfig.instance.appState));
}
