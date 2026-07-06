import 'package:flutter/material.dart';

// ponytail: stubs so routing lands before the real screens (Tasks 9, 10, 12).

class BoardScreenStub extends StatelessWidget {
  const BoardScreenStub({super.key, required this.boardId});
  final String boardId;
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text('Board $boardId')),
      body: const Center(child: Text('Board (Task 10)')));
}

class NotificationsScreenStub extends StatelessWidget {
  const NotificationsScreenStub({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: const Center(child: Text('Notifications (Task 12)')));
}
