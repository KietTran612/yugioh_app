import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../models/card_model.dart';
import '../utils/card_colors.dart';

class CardDetailScreen extends StatelessWidget {
  final YugiohCard card;

  const CardDetailScreen({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    final bgColor = frameTypeColor(card.frameType);

    return Scaffold(
      backgroundColor: bgColor.withOpacity(0.15),
      appBar: AppBar(
        title: Text(card.name, overflow: TextOverflow.ellipsis),
        backgroundColor: bgColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card image + basic info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: card.imageUrl,
                    width: 160,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(width: 160, height: 230, color: Colors.white),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 160,
                      height: 230,
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image, size: 48),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoChip(label: 'Type', value: card.type),
                      const SizedBox(height: 6),
                      if (card.attribute != null)
                        _AttributeBadge(attribute: card.attribute!),
                      const SizedBox(height: 6),
                      _InfoChip(label: 'Race', value: card.race),
                      if (card.level != null) ...[
                        const SizedBox(height: 6),
                        _InfoChip(
                          label: card.isXyz ? 'Rank' : card.isLink ? 'Link' : 'Level',
                          value: card.isLink
                              ? '${card.linkVal}'
                              : '${card.level}',
                        ),
                      ],
                      if (card.isMonster) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _StatBadge(
                                label: 'ATK',
                                value: card.atk != null ? '${card.atk}' : '?'),
                            const SizedBox(width: 8),
                            if (!card.isLink)
                              _StatBadge(
                                  label: 'DEF',
                                  value: card.def != null ? '${card.def}' : '?'),
                          ],
                        ),
                      ],
                      if (card.archetype.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        _InfoChip(label: 'Archetype', value: card.archetype),
                      ],
                      if (card.isPendulum && card.scale != null) ...[
                        const SizedBox(height: 6),
                        _InfoChip(label: 'Scale', value: '${card.scale}'),
                      ],
                      if (card.isLink && card.linkMarkers.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        _InfoChip(
                            label: 'Markers',
                            value: card.linkMarkers.join(', ')),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Description
            _SectionHeader('Card Text'),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(card.desc, style: const TextStyle(height: 1.5)),
            ),

            // Formats
            if (card.misc?.formats.isNotEmpty == true) ...[
              const SizedBox(height: 20),
              _SectionHeader('Formats'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: card.misc!.formats
                    .map((f) => Chip(label: Text(f)))
                    .toList(),
              ),
            ],

            // Sets
            if (card.sets.isNotEmpty) ...[
              const SizedBox(height: 20),
              _SectionHeader('Card Sets (${card.sets.length})'),
              const SizedBox(height: 8),
              ...card.sets.take(10).map((s) => _SetRow(cardSet: s)),
              if (card.sets.length > 10)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '+ ${card.sets.length - 10} more sets',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ),
            ],

            // Prices
            if (card.prices != null) ...[
              const SizedBox(height: 20),
              _SectionHeader('Prices'),
              const SizedBox(height: 8),
              _PriceTable(prices: card.prices!),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold),
      );
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            TextSpan(
                text: '$label: ',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value),
          ],
        ),
      );
}

class _AttributeBadge extends StatelessWidget {
  final String attribute;
  const _AttributeBadge({required this.attribute});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: attributeColor(attribute),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          attribute,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      );
}

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  const _StatBadge({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '$label $value',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      );
}

class _SetRow extends StatelessWidget {
  final CardSet cardSet;
  const _SetRow({required this.cardSet});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(
              child: Text(cardSet.setName,
                  style: const TextStyle(fontSize: 13)),
            ),
            Text(cardSet.setCode,
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(width: 8),
            Chip(
              label: Text(cardSet.setRarity,
                  style: const TextStyle(fontSize: 11)),
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      );
}

class _PriceTable extends StatelessWidget {
  final CardPrices prices;
  const _PriceTable({required this.prices});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            _priceRow('TCGPlayer', prices.tcgplayer),
            _priceRow('Cardmarket', prices.cardmarket),
            _priceRow('eBay', prices.ebay),
            _priceRow('Amazon', prices.amazon, isLast: true),
          ],
        ),
      );

  Widget _priceRow(String market, String price, {bool isLast = false}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(bottom: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(market),
            Text('\$$price',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      );
}
