import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('خوش آمدی، سلطان!')),
      body: const Center(child: Text('اینجا صفحه اصلیه!')),
    );
  }
}
