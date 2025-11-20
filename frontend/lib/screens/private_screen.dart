// lib/screens/private_screen.dart
import 'package:flutter/material.dart';
import 'personal_section.dart';

class PrivateScreen extends StatelessWidget {
  const PrivateScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: const [
          PersonalSection(),
        ],
      ),
    );
  }
}
