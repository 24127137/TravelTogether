// lib/screens/private_screen.dart
import 'package:flutter/material.dart';
import '../widgets/KhungCNhN.dart';

class PrivateScreen extends StatelessWidget {
  const PrivateScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // KHÔNG dùng MaterialApp ở đây
    return Scaffold(
      body: ListView(
        children: const [
          KhungCNhN(),
        ],
      ),
    );
  }
}
