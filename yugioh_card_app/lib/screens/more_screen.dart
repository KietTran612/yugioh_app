import 'package:flutter/material.dart';
import '../services/card_data_service.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          _MoreTile(
            icon: Icons.refresh_rounded,
            title: 'Refresh Card Data',
            subtitle: 'Re-fetch all cards from YGOPRODeck API',
            onTap: () => _confirmRefresh(context),
          ),
          const Divider(indent: 56),
          _MoreTile(
            icon: Icons.info_outline_rounded,
            title: 'About',
            subtitle: 'Yu-Gi-Oh! Card App v0.3',
            onTap: () => _showAbout(context),
          ),
        ],
      ),
    );
  }

  void _confirmRefresh(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Refresh Card Data'),
        content: const Text(
          'Re-fetch all cards from the YGOPRODeck API.\nThis may take a moment.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              await CardDataService.clearCache();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cache cleared. Restart app to re-fetch.'),
                  ),
                );
              }
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Yu-Gi-Oh! Card App',
      applicationVersion: 'v0.3',
      applicationLegalese: 'Card data from YGOPRODeck API',
    );
  }
}

class _MoreTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MoreTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
