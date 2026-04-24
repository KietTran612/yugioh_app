import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/favorites_provider.dart';
import '../utils/app_theme.dart';

/// Compact heart button — dùng trên card grid (góc trên phải).
class FavoriteButton extends ConsumerWidget {
  final int cardId;
  final double size;

  const FavoriteButton({super.key, required this.cardId, this.size = 28});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFav = ref.watch(
      favoritesProvider.select((ids) => ids.contains(cardId)),
    );

    return GestureDetector(
      onTap: () => ref.read(favoritesProvider.notifier).toggle(cardId),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          size: size * 0.55,
          color: isFav ? const Color(0xFFFF6B6B) : Colors.white70,
        ),
      ),
    );
  }
}

/// Larger heart button — dùng trên AppBar của Card Detail Screen.
class FavoriteIconButton extends ConsumerWidget {
  final int cardId;

  const FavoriteIconButton({super.key, required this.cardId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFav = ref.watch(
      favoritesProvider.select((ids) => ids.contains(cardId)),
    );

    return IconButton(
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, anim) =>
            ScaleTransition(scale: anim, child: child),
        child: Icon(
          isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          key: ValueKey(isFav),
          color: isFav ? const Color(0xFFFF6B6B) : AppTheme.textSecondary,
          size: 22,
        ),
      ),
      onPressed: () async {
        final nowFav = await ref
            .read(favoritesProvider.notifier)
            .toggle(cardId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                nowFav ? 'Added to favorites' : 'Removed from favorites',
              ),
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );
  }
}
