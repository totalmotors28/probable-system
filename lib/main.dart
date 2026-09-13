import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() => runApp(const AydymCalamApp());

class AydymCalamApp extends StatelessWidget {
  const AydymCalamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aýdym Çalar',
      debugShowCheckedModeBanner: false,
      locale: const Locale('tk', 'TM'),
      supportedLocales: const [Locale('tk', 'TM')],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C4DFF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
