import 'package:flutter/material.dart';

class ChatPage extends StatelessWidget {
  final String characterId;
  final String? chatId;

  const ChatPage({super.key, required this.characterId, this.chatId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Chat Page: char=$characterId, chat=$chatId')),
    );
  }
}
