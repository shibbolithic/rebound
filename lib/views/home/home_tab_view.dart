import 'package:flutter/material.dart';

class HomeTabView extends StatelessWidget {
  const HomeTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Athlinix'),
      ),
      body: const Center(
        child: Text(
          'Home Feed / Dashboard',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
