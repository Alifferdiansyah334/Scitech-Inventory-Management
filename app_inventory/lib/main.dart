import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:marionette_flutter/marionette_flutter.dart';

import 'pages/login_page.dart';

void main() {
  if (kDebugMode) {
    MarionetteBinding.ensureInitialized();
  } else {
    WidgetsFlutterBinding.ensureInitialized();
  }

  runApp(const ScitechApp());
}

class ScitechApp extends StatelessWidget {
  const ScitechApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scitech Inventory',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F7FB),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5546E8)),
      ),
      home: const LoginPage(),
    );
  }
}
