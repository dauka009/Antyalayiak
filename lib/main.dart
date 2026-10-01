import 'package:flutter/material.dart';
import 'core.dart';
import 'screens.dart';

void main() => runApp(const QalqanApp());

class QalqanApp extends StatelessWidget {
  const QalqanApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Qalqan',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const SplashScreen(),
      );
}
