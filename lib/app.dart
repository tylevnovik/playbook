import 'package:flutter/material.dart';

class PlaybookApp extends StatelessWidget {
  const PlaybookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Playbook',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(child: Text('Playbook')),
      ),
    );
  }
}
