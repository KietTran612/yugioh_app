import 'package:flutter/material.dart';
import '../models/card_model.dart';
import '../utils/app_theme.dart';
import 'card_image.dart';
import 'favorite_button.dart';

class CardItem extends StatelessWidget {
  final YugiohCard card;
  final VoidCallback onTap;

  const CardItem({super.key, required this.card, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final borderColor = AppTheme.getCardBorderColor(
      card.frameType,
      card.attribute,
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: borderColor.withValues(alpha: 0.45),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Card image — full resolution
              CardNetworkImage(imageUrl: card.imageUrl, fit: BoxFit.cover),

              // Coloured border overlay
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: borderColor.withValues(alpha: 0.7),
                    width: 1.5,
                  ),
                ),
              ),

              // Favorite button — top right corner
              Positioned(
                top: 5,
                right: 5,
                child: FavoriteButton(cardId: card.id),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
