import 'package:flutter/material.dart';

class WatchlistScreen extends StatelessWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border_rounded,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text('Watchlist', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('Coming soon', style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }
}
