import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
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

  final _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  // Track whether each tab is at its root screen
  final _isAtRoot = [true, true, true, true, true];

  // Navigator widgets — created once, never recreated
  late final List<Widget> _navigators;

  static const _navItems = [
    _NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
    ),
    _NavItem(
      icon: Icons.layers_outlined,
      activeIcon: Icons.layers_rounded,
      label: 'Sets',
    ),
    _NavItem(
      icon: Icons.style_outlined,
      activeIcon: Icons.style_rounded,
      label: 'Collection',
    ),
    _NavItem(
      icon: Icons.bookmark_border_rounded,
      activeIcon: Icons.bookmark_rounded,
      label: 'Watchlist',
    ),
    _NavItem(
      icon: Icons.more_horiz_rounded,
      activeIcon: Icons.more_horiz_rounded,
      label: 'More',
    ),
  ];

  @override
  void initState() {
    super.initState();
    const roots = [
      HomeScreen(),
      SetsScreen(),
      CollectionScreen(),
      WatchlistScreen(),
      MoreScreen(),
    ];
    _navigators = List.generate(5, (i) {
      return _TabNavigator(
        tabIndex: i,
        navigatorKey: _navigatorKeys[i],
        root: roots[i],
        onDepthChanged: (atRoot) {
          if (mounted && _isAtRoot[i] != atRoot) {
            setState(() => _isAtRoot[i] = atRoot);
          }
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final nav = _navigatorKeys[_currentIndex].currentState;
        if (nav != null && nav.canPop()) {
          nav.pop();
          return;
        }
        if (_currentIndex != 0) setState(() => _currentIndex = 0);
      },
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: _navigators),
        bottomNavigationBar: _DuelBottomNav(
          currentIndex: _currentIndex,
          isAtRoot: _isAtRoot,
          items: _navItems,
          onTap: (i) {
            if (i == _currentIndex) {
              _navigatorKeys[i].currentState?.popUntil((r) => r.isFirst);
              if (!_isAtRoot[i]) setState(() => _isAtRoot[i] = true);
            } else {
              setState(() => _currentIndex = i);
            }
          },
        ),
      ),
    );
  }
}

// ── Tab Navigator ──────────────────────────────────────────────────────────────
// Uses a HeroController (standard Flutter practice) + custom RouteObserver
// that does NOT use NavigatorObserver (avoids the _elements assertion).
// Instead, each pushed route wraps its page in _DepthTracker which fires
// a callback via didChangeDependencies — safe and observer-free.

class _TabNavigator extends StatefulWidget {
  final int tabIndex;
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget root;
  final ValueChanged<bool> onDepthChanged; // true = at root

  const _TabNavigator({
    required this.tabIndex,
    required this.navigatorKey,
    required this.root,
    required this.onDepthChanged,
  });

  @override
  State<_TabNavigator> createState() => _TabNavigatorState();
}

class _TabNavigatorState extends State<_TabNavigator> {
  int _depth = 0; // 0 = root

  void _onPush() {
    _depth++;
    widget.onDepthChanged(_depth == 0);
  }

  void _onPop() {
    if (_depth > 0) _depth--;
    widget.onDepthChanged(_depth == 0);
  }

  @override
  Widget build(BuildContext context) {
    return _DepthScope(
      onPush: _onPush,
      onPop: _onPop,
      child: Navigator(
        key: widget.navigatorKey,
        onGenerateRoute: (settings) =>
            MaterialPageRoute(builder: (_) => widget.root, settings: settings),
      ),
    );
  }
}

// ── Depth scope — provides push/pop callbacks to descendants ──────────────────

class _DepthScope extends InheritedWidget {
  final VoidCallback onPush;
  final VoidCallback onPop;

  const _DepthScope({
    required this.onPush,
    required this.onPop,
    required super.child,
  });

  static _DepthScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_DepthScope>();

  @override
  bool updateShouldNotify(_DepthScope old) => false;
}

// ── Tracked push helper — screens call this instead of Navigator.push ─────────
// We override Navigator.push globally by wrapping Navigator with a custom
// delegate. Simpler: expose a static helper that wraps push/pop.

/// Call this instead of [Navigator.push] inside any tab screen so the shell
/// knows the depth changed.
Future<T?> tabPush<T>(BuildContext context, Route<T> route) {
  final scope = _DepthScope.of(context);
  scope?.onPush();
  return Navigator.of(context).push(route).then((result) {
    // Called when the pushed route is popped — notify shell to restore active state
    scope?.onPop();
    return result;
  });
}

/// Call this instead of [Navigator.pop] if you need to notify depth.
/// Usually not needed — back button is handled by PopScope in shell.
void tabPop<T>(BuildContext context, [T? result]) {
  _DepthScope.of(context)?.onPop();
  Navigator.of(context).pop(result);
}

// ── Custom bottom nav with pill indicator ──────────────────────────────────────

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _DuelBottomNav extends StatelessWidget {
  final int currentIndex;
  final List<bool> isAtRoot;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;

  const _DuelBottomNav({
    required this.currentIndex,
    required this.isAtRoot,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.bgCard,
        border: Border(top: BorderSide(color: AppTheme.bgBorder, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final isActive = i == currentIndex && isAtRoot[i];
              final isCurrentTab = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppTheme.accent.withValues(alpha: 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          isActive ? item.activeIcon : item.icon,
                          size: 22,
                          color: isActive
                              ? AppTheme.accent
                              : isCurrentTab
                              ? AppTheme.textSecondary
                              : AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: isActive
                              ? AppTheme.accent
                              : isCurrentTab
                              ? AppTheme.textSecondary
                              : AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
