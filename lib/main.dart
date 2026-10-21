import 'package:flutter/material.dart';

void main() {
  runApp(const MullaStudyLockApp());
}

class MullaStudyLockApp extends StatelessWidget {
  const MullaStudyLockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mulla Study Lock',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mulla Study Lock')),
      body: const Center(
        child: Text('مرحبًا بك في قفل الدراسة المجدول'),
      ),
    );
  }
}
