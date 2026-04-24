import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'sets_screen.dart';
import 'collection_screen.dart';
import 'watchlist_screen.dart';
import 'more_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const _screens = [
    HomeScreen(),
    SetsScreen(),
    CollectionScreen(),
    WatchlistScreen(),
    MoreScreen(),
  ];

  static const _items = [
    BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home_rounded),
      label: 'Home',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.list_alt_outlined),
      activeIcon: Icon(Icons.list_alt_rounded),
      label: 'Sets',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.style_outlined),
      activeIcon: Icon(Icons.style_rounded),
      label: 'Collection',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.bookmark_border_rounded),
      activeIcon: Icon(Icons.bookmark_rounded),
      label: 'Watchlist',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.more_horiz_rounded),
      activeIcon: Icon(Icons.more_horiz_rounded),
      label: 'More',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurface.withValues(alpha: 0.5),
        backgroundColor: colorScheme.surface,
        elevation: 8,
        selectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: _items,
      ),
    );
  }
}
