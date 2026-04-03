import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'ui/main_page.dart';

void main() {
  runApp(const CalendariDePagesosApp());
}

class CalendariDePagesosApp extends StatelessWidget {
  const CalendariDePagesosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Terra i Sol',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainPage(),
    );
  }
}
