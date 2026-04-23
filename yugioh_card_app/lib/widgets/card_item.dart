import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../models/card_model.dart';
import '../utils/card_colors.dart';

class CardItem extends StatelessWidget {
  final YugiohCard card;
  final VoidCallback onTap;

  const CardItem({super.key, required this.card, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bgColor = frameTypeColor(card.frameType);
    final textColor = frameTypeTextColor(card.frameType);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card image
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(10)),
                child: CachedNetworkImage(
                  imageUrl: card.imageUrlSmall,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(color: Colors.white),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
            ),

            // Card name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Text(
                card.name,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),

            // ATK / DEF or type badge
            Padding(
              padding: const EdgeInsets.only(bottom: 6, left: 6, right: 6),
              child: card.isMonster
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _statChip(
                            'ATK',
                            card.atk != null ? '${card.atk}' : '?',
                            textColor),
                        const SizedBox(width: 4),
                        _statChip(
                            'DEF',
                            card.def != null ? '${card.def}' : '?',
                            textColor),
                      ],
                    )
                  : Center(
                      child: _typeBadge(card.frameType),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(String label, String value, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label $value',
        style: TextStyle(fontSize: 9, color: textColor, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _typeBadge(String frameType) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        frameType.toUpperCase(),
        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }
}
