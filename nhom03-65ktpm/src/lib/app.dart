import 'package:flutter/material.dart';

class SmartNoteApp extends StatelessWidget {
  const SmartNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartNote',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2F6BFF)),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('SmartNote'),
        ),
      ),
    );
  }
}
