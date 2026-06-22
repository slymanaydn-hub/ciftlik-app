import 'package:flutter/material.dart';

import 'core/constants.dart';
import 'features/shell.dart';
import 'ui/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SuruGardasApp());
}

class SuruGardasApp extends StatelessWidget {
  const SuruGardasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appName,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const MainShell(),
    );
  }
}
