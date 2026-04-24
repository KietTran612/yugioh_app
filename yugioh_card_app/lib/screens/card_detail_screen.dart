import 'package:flutter/material.dart';
import '../models/card_model.dart';
import '../utils/card_colors.dart';
import '../widgets/card_image.dart';

class CardDetailScreen extends StatelessWidget {
  final YugiohCard card;

  const CardDetailScreen({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    final frameColor = frameTypeColor(card.frameType);

    return Scaffold(
      // Use theme background — no tinted overlay
      appBar: AppBar(
        title: Text(card.name, overflow: TextOverflow.ellipsis),
        backgroundColor: frameColor,
        foregroundColor: frameTypeTextColor(card.frameType),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top section: image + stats ──────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card image — tap to view full size
                GestureDetector(
                  onTap: () => _showFullImage(context, card.imageUrl),
                  child: Hero(
                    tag: 'card_image_${card.id}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CardNetworkImage(
                        imageUrl: card.imageUrl,
                        width: 160,
                        height: 230,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Stats
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Frame type badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: frameColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          card.type,
                          style: TextStyle(
                            color: frameTypeTextColor(card.frameType),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      if (card.attribute != null) ...[
                        _AttributeBadge(attribute: card.attribute!),
                        const SizedBox(height: 8),
                      ],

                      _InfoRow(label: 'Race', value: card.race),

                      if (card.level != null) ...[
                        const SizedBox(height: 4),
                        _InfoRow(
                          label: card.isXyz
                              ? 'Rank'
                              : card.isLink
                              ? 'Link'
                              : 'Level',
                          value: card.isLink
                              ? '${card.linkVal}'
                              : '${card.level}',
                        ),
                      ],

                      if (card.isMonster) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _StatBadge(
                              label: 'ATK',
                              value: card.atk != null ? '${card.atk}' : '?',
                            ),
                            const SizedBox(width: 8),
                            if (!card.isLink)
                              _StatBadge(
                                label: 'DEF',
                                value: card.def != null ? '${card.def}' : '?',
                              ),
                          ],
                        ),
                      ],

                      if (card.archetype.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        _InfoRow(label: 'Archetype', value: card.archetype),
                      ],

                      if (card.isPendulum && card.scale != null) ...[
                        const SizedBox(height: 4),
                        _InfoRow(label: 'Scale', value: '${card.scale}'),
                      ],

                      if (card.isLink && card.linkMarkers.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        _InfoRow(
                          label: 'Markers',
                          value: card.linkMarkers.join(', '),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Card Text ───────────────────────────────────────────────
            _SectionHeader('Card Text'),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SelectableText(
                card.desc.isNotEmpty ? card.desc : '—',
                style: const TextStyle(height: 1.6),
              ),
            ),

            // ── Formats ─────────────────────────────────────────────────
            if (card.misc?.formats.isNotEmpty == true) ...[
              const SizedBox(height: 20),
              _SectionHeader('Formats'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: card.misc!.formats
                    .map(
                      (f) => Chip(
                        label: Text(f),
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer,
                      ),
                    )
                    .toList(),
              ),
            ],

            // ── Card Sets ────────────────────────────────────────────────
            if (card.sets.isNotEmpty) ...[
              const SizedBox(height: 20),
              _SectionHeader('Card Sets (${card.sets.length})'),
              const SizedBox(height: 8),
              Card(
                margin: EdgeInsets.zero,
                child: Column(
                  children: [
                    ...card.sets.take(10).map((s) => _SetRow(cardSet: s)),
                    if (card.sets.length > 10)
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          '+ ${card.sets.length - 10} more sets',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],

            // ── Prices ───────────────────────────────────────────────────
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

  void _showFullImage(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullImageScreen(
          imageUrl: imageUrl,
          cardName: card.name,
          heroTag: 'card_image_${card.id}',
        ),
      ),
    );
  }
}

// ── Full image viewer ──────────────────────────────────────────────────────────

class _FullImageScreen extends StatelessWidget {
  final String imageUrl;
  final String cardName;
  final String heroTag;

  const _FullImageScreen({
    required this.imageUrl,
    required this.cardName,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(cardName),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Hero(
            tag: heroTag,
            child: CardNetworkImage(imageUrl: imageUrl, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
  );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: value),
        ],
      ),
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
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
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
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
    ),
  );
}

class _SetRow extends StatelessWidget {
  final CardSet cardSet;
  const _SetRow({required this.cardSet});

  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    title: Text(cardSet.setName, style: const TextStyle(fontSize: 13)),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          cardSet.setCode,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(width: 8),
        Chip(
          label: Text(cardSet.setRarity, style: const TextStyle(fontSize: 11)),
          padding: EdgeInsets.zero,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
      ],
    ),
  );
}

class _PriceTable extends StatelessWidget {
  final CardPrices prices;
  const _PriceTable({required this.prices});

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Column(
      children: [
        _priceRow(context, 'TCGPlayer', prices.tcgplayer),
        _priceRow(context, 'Cardmarket', prices.cardmarket),
        _priceRow(context, 'eBay', prices.ebay),
        _priceRow(context, 'Amazon', prices.amazon, isLast: true),
      ],
    ),
  );

  Widget _priceRow(
    BuildContext context,
    String market,
    String price, {
    bool isLast = false,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      border: isLast
          ? null
          : Border(bottom: BorderSide(color: Colors.grey.shade200)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(market, style: const TextStyle(fontWeight: FontWeight.w500)),
        Text('\$$price', style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    ),
  );
}
