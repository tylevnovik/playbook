import 'package:flutter/material.dart';

class CharacterEditPage extends StatelessWidget {
  final String? characterId;

  const CharacterEditPage({super.key, this.characterId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Character Edit Page: $characterId')),
    );
  }
}
