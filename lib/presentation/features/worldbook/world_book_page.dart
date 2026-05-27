import 'package:flutter/material.dart';

class WorldBookPage extends StatelessWidget {
  final String? worldBookId;

  const WorldBookPage({super.key, this.worldBookId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('World Book Page: $worldBookId')),
    );
  }
}
