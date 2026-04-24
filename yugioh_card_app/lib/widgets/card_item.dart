import 'package:flutter/material.dart';
import '../models/card_model.dart';
import 'card_image.dart';

class CardItem extends StatelessWidget {
  final YugiohCard card;
  final VoidCallback onTap;

  const CardItem({super.key, required this.card, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CardNetworkImage(
          imageUrl: card.imageUrlSmall,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
