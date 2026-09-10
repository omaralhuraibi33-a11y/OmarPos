import 'package:flutter/material.dart';
import 'login_screen.dart';

void main() {
  runApp(const OmarPosMasterApp());
}

class OmarPosMasterApp extends StatelessWidget {
  const OmarPosMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OmarPos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: LoginScreen(),
      ),
    );
  }
}
