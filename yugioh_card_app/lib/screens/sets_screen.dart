import 'package:flutter/material.dart';

class SetsScreen extends StatelessWidget {
  const SetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.list_alt_rounded, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Sets', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('Coming soon', style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }
}
