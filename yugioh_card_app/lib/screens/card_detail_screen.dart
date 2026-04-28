import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/card_model.dart';
import '../providers/card_sets_provider.dart';
import '../providers/translation_provider.dart';
import '../services/translation_service.dart';
import '../utils/app_theme.dart';
import '../widgets/add_to_deck_sheet.dart';
import '../widgets/card_detail_widgets.dart';
import '../widgets/card_image.dart';
import '../widgets/favorite_button.dart';
import 'set_detail_screen.dart';
import 'main_shell.dart' show tabPush;

class CardDetailScreen extends StatelessWidget {
  final YugiohCard card;

  const CardDetailScreen({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    final frameColor = AppTheme.getFrameColor(card.frameType);
    final attrColor = AppTheme.getAttributeColor(card.attribute);
    final accentColor = card.attribute != null ? attrColor : frameColor;

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: CustomScrollView(
        slivers: [
          // ── Sliver AppBar ────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 0,
            pinned: true,
            backgroundColor: AppTheme.bgDeep,
            foregroundColor: AppTheme.textPrimary,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.bgElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.bgBorder),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              card.name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            actions: [
              AddToDeckButton(card: card),
              FavoriteIconButton(cardId: card.id),
              const SizedBox(width: 4),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: AppTheme.bgBorder),
            ),
          ),

          // ── Body ─────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Hero section ─────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => _showFullImage(context, card.imageUrl),
                        child: Hero(
                          tag: 'card_image_${card.id}',
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: accentColor.withValues(alpha: 0.5),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CardNetworkImage(
                                imageUrl: card.imageUrl,
                                width: 150,
                                height: 218,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CardTypeBadge(label: card.type, color: frameColor),
                            const SizedBox(height: 10),
                            if (card.attribute != null) ...[
                              CardAttributeBadge(attribute: card.attribute!),
                              const SizedBox(height: 10),
                            ],
                            if (card.isMonster) ...[
                              Row(
                                children: [
                                  CardStatBadge(
                                    label: 'ATK',
                                    value: card.atk != null
                                        ? '${card.atk}'
                                        : '?',
                                    color: const Color(0xFFE74C3C),
                                  ),
                                  const SizedBox(width: 8),
                                  if (!card.isLink)
                                    CardStatBadge(
                                      label: 'DEF',
                                      value: card.def != null
                                          ? '${card.def}'
                                          : '?',
                                      color: const Color(0xFF3498DB),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),
                            ],
                            CardInfoChip(label: 'Race', value: card.race),
                            if (card.level != null) ...[
                              const SizedBox(height: 6),
                              CardInfoChip(
                                label: card.isXyz
                                    ? 'Rank'
                                    : card.isLink
                                    ? 'Link'
                                    : 'Level',
                                value: card.isLink
                                    ? '${card.linkVal}'
                                    : '${card.level}',
                                icon: card.isXyz
                                    ? Icons.circle
                                    : Icons.star_rounded,
                                iconColor: AppTheme.accentGold,
                              ),
                            ],
                            if (card.archetype.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              CardInfoChip(
                                label: 'Archetype',
                                value: card.archetype,
                              ),
                            ],
                            if (card.isPendulum && card.scale != null) ...[
                              const SizedBox(height: 6),
                              CardInfoChip(
                                label: 'Scale',
                                value: '${card.scale}',
                              ),
                            ],
                            if (card.isLink && card.linkMarkers.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              CardInfoChip(
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

                  // ── Formats ──────────────────────────────────────────
                  if (card.misc?.formats.isNotEmpty == true) ...[
                    const CardDetailSectionHeader(title: 'Formats'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: card.misc!.formats
                          .map((f) => CardFormatChip(label: f))
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Banlist ───────────────────────────────────────────
                  if (card.misc?.banlist?.hasAny == true) ...[
                    const CardDetailSectionHeader(title: 'Banlist Status'),
                    const SizedBox(height: 10),
                    CardBanlistPanel(banlist: card.misc!.banlist!),
                    const SizedBox(height: 20),
                  ],

                  // ── TCG Rarity ────────────────────────────────────────
                  if (card.sets.isNotEmpty) ...[
                    CardTcgRaritySection(sets: card.sets),
                    const SizedBox(height: 20),
                  ],

                  // ── Card Text ─────────────────────────────────────────
                  _CardTextSection(card: card),

                  // ── Card Sets ─────────────────────────────────────────
                  if (card.sets.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    CardDetailSectionHeader(
                      title: 'Card Sets',
                      trailing: '${card.sets.length}',
                    ),
                    const SizedBox(height: 10),
                    _CardSetsPanel(sets: card.sets),
                  ],

                  // ── Prices ────────────────────────────────────────────
                  if (card.prices != null) ...[
                    const SizedBox(height: 20),
                    const CardDetailSectionHeader(title: 'Prices'),
                    const SizedBox(height: 10),
                    _PricesPanel(prices: card.prices!),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    tabPush(
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

// ── Card Text section with translation ────────────────────────────────────────

class _CardTextSection extends ConsumerWidget {
  final YugiohCard card;

  const _CardTextSection({required this.card});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translationState = ref.watch(translationProvider(card.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const CardDetailSectionHeader(title: 'Card Text'),
            const Spacer(),
            IconButton(
              icon: Icon(
                Icons.translate_rounded,
                size: 20,
                color: translationState.translatedText != null
                    ? AppTheme.accent
                    : AppTheme.textSecondary,
              ),
              onPressed: translationState.isLoading
                  ? null
                  : () => _showTranslateSheet(context, ref),
              tooltip: 'Translate',
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (translationState.translatedText != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.translate_rounded,
                      size: 12,
                      color: AppTheme.accent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _getLangName(translationState.targetLang ?? ''),
                      style: const TextStyle(
                        color: AppTheme.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => ref
                          .read(translationProvider(card.id).notifier)
                          .reset(),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 14,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SelectableText(
                  translationState.translatedText!,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    height: 1.65,
                    fontSize: 13.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Translated by Google',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],

        if (translationState.isLoading) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.bgBorder),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.accent,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Translating...',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],

        if (translationState.error != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE74C3C).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE74C3C).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 16,
                  color: Color(0xFFE74C3C),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    translationState.error!,
                    style: const TextStyle(
                      color: Color(0xFFE74C3C),
                      fontSize: 12,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => ref
                      .read(translationProvider(card.id).notifier)
                      .clearError(),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: Color(0xFFE74C3C),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.bgBorder),
          ),
          child: SelectableText(
            card.desc.isNotEmpty ? card.desc : '—',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              height: 1.65,
              fontSize: 13.5,
            ),
          ),
        ),
      ],
    );
  }

  void _showTranslateSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Translate to',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ...TranslationLanguage.languages.map((lang) {
              return _LanguageTile(
                language: lang,
                onTap: () {
                  Navigator.pop(context);
                  ref
                      .read(translationProvider(card.id).notifier)
                      .translate(
                        cardId: card.id,
                        text: card.desc,
                        targetLang: lang.code,
                      );
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  String _getLangName(String code) {
    final match = TranslationLanguage.languages.where((l) => l.code == code);
    return match.isNotEmpty ? match.first.name : code;
  }
}

class _LanguageTile extends StatelessWidget {
  final TranslationLanguage language;
  final VoidCallback onTap;

  const _LanguageTile({required this.language, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        margin: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Text(language.flag, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Text(
              language.name,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Full image viewer ─────────────────────────────────────────────────────────

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
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 5.0,
          child: Hero(
            tag: heroTag,
            child: CardNetworkImage(imageUrl: imageUrl, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}

// ── Card Sets panel ───────────────────────────────────────────────────────────

class _CardSetsPanel extends StatefulWidget {
  final List<CardSet> sets;

  const _CardSetsPanel({required this.sets});

  @override
  State<_CardSetsPanel> createState() => _CardSetsPanelState();
}

class _CardSetsPanelState extends State<_CardSetsPanel> {
  bool _showAll = false;

  void _navigateToSet(BuildContext context, String setName) {
    final container = ProviderScope.containerOf(context, listen: false);
    final setsAsync = container.read(cardSetsProvider);
    setsAsync.whenData((sets) {
      final match = sets.where((s) => s.setName == setName);
      if (match.isNotEmpty) {
        tabPush(
          context,
          MaterialPageRoute(
            builder: (_) => SetDetailScreen(setInfo: match.first),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final displaySets = _showAll ? widget.sets : widget.sets.take(5).toList();

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.bgBorder),
      ),
      child: Column(
        children: [
          ...displaySets.asMap().entries.map((entry) {
            final i = entry.key;
            final s = entry.value;
            final isLast =
                i == displaySets.length - 1 &&
                (_showAll || widget.sets.length <= 5);
            return _SetRow(
              cardSet: s,
              isLast: isLast,
              onTap: () => _navigateToSet(context, s.setName),
            );
          }),
          if (widget.sets.length > 5)
            InkWell(
              onTap: () => setState(() => _showAll = !_showAll),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _showAll
                          ? 'Show less'
                          : '+ ${widget.sets.length - 5} more sets',
                      style: const TextStyle(
                        color: AppTheme.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _showAll
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: AppTheme.accent,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  final CardSet cardSet;
  final bool isLast;
  final VoidCallback onTap;

  const _SetRow({
    required this.cardSet,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: isLast
          ? const BorderRadius.vertical(bottom: Radius.circular(12))
          : BorderRadius.zero,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
                  bottom: BorderSide(color: AppTheme.bgBorder, width: 1),
                ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                cardSet.setName,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              cardSet.setCode,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _rarityColor(cardSet.setRarity).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _rarityColor(cardSet.setRarity).withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                cardSet.setRarity,
                style: TextStyle(
                  color: _rarityColor(cardSet.setRarity),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: AppTheme.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Color _rarityColor(String rarity) {
    final r = rarity.toLowerCase();
    if (r.contains('secret')) return const Color(0xFFFF6B6B);
    if (r.contains('ultimate')) return const Color(0xFFFFD700);
    if (r.contains('ultra')) return const Color(0xFFFFB800);
    if (r.contains('super')) return const Color(0xFF00C896);
    if (r.contains('rare')) return const Color(0xFF74B9FF);
    return AppTheme.textSecondary;
  }
}

// ── Prices panel ──────────────────────────────────────────────────────────────

class _PricesPanel extends StatelessWidget {
  final CardPrices prices;

  const _PricesPanel({required this.prices});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.bgBorder),
      ),
      child: Column(
        children: [
          _priceRow('TCGPlayer', prices.tcgplayer, Icons.store_rounded, false),
          _priceRow(
            'Cardmarket',
            prices.cardmarket,
            Icons.shopping_cart_rounded,
            false,
          ),
          _priceRow('eBay', prices.ebay, Icons.gavel_rounded, false),
          _priceRow(
            'Amazon',
            prices.amazon,
            Icons.local_shipping_rounded,
            true,
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String market, String price, IconData icon, bool isLast) {
    final priceVal = double.tryParse(price) ?? 0.0;
    final hasPrice = priceVal > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: AppTheme.bgBorder, width: 1),
              ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              market,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            hasPrice ? '\$$price' : '—',
            style: TextStyle(
              color: hasPrice ? AppTheme.accent : AppTheme.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.chevron_right_rounded,
            size: 16,
            color: AppTheme.textMuted,
          ),
        ],
      ),
    );
  }
}
