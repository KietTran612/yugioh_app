import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/card_model.dart';
import '../providers/card_sets_provider.dart';
import '../providers/translation_provider.dart';
import '../services/translation_service.dart';
import '../utils/app_theme.dart';
import '../widgets/card_image.dart';
import '../widgets/favorite_button.dart';
import 'set_detail_screen.dart';
import 'main_shell.dart' show tabPush;
import '../providers/deck_provider.dart';
import '../models/deck_model.dart';

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
          // ── Sliver AppBar with gradient ──────────────────────────────
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
              _AddToDeckButton(card: card),
              FavoriteIconButton(cardId: card.id),
              const SizedBox(width: 4),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: AppTheme.bgBorder),
            ),
          ),

          // ── Body content ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Hero section: image + stats ──────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Card image with glow
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

                      // Stats panel
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Type badge
                            _TypeBadge(label: card.type, color: frameColor),
                            const SizedBox(height: 10),

                            // Attribute badge
                            if (card.attribute != null) ...[
                              _AttributeBadge(attribute: card.attribute!),
                              const SizedBox(height: 10),
                            ],

                            // ATK / DEF
                            if (card.isMonster) ...[
                              Row(
                                children: [
                                  _StatBadge(
                                    label: 'ATK',
                                    value: card.atk != null
                                        ? '${card.atk}'
                                        : '?',
                                    color: const Color(0xFFE74C3C),
                                  ),
                                  const SizedBox(width: 8),
                                  if (!card.isLink)
                                    _StatBadge(
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

                            // Info rows
                            _InfoChip(label: 'Race', value: card.race),

                            if (card.level != null) ...[
                              const SizedBox(height: 6),
                              _InfoChip(
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
                              _InfoChip(
                                label: 'Archetype',
                                value: card.archetype,
                              ),
                            ],

                            if (card.isPendulum && card.scale != null) ...[
                              const SizedBox(height: 6),
                              _InfoChip(label: 'Scale', value: '${card.scale}'),
                            ],

                            if (card.isLink && card.linkMarkers.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              _InfoChip(
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
                    _SectionHeader(title: 'Formats'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: card.misc!.formats
                          .map((f) => _FormatChip(label: f))
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Banlist ───────────────────────────────────────────
                  if (card.misc?.banlist?.hasAny == true) ...[
                    _SectionHeader(title: 'Banlist Status'),
                    const SizedBox(height: 10),
                    _BanlistPanel(banlist: card.misc!.banlist!),
                    const SizedBox(height: 20),
                  ],

                  // ── Card Text ─────────────────────────────────────────
                  _CardTextSection(card: card),

                  // ── Card Sets ─────────────────────────────────────────
                  if (card.sets.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _SectionHeader(
                      title: 'Card Sets',
                      trailing: '${card.sets.length}',
                    ),
                    const SizedBox(height: 10),
                    _CardSetsPanel(sets: card.sets),
                  ],

                  // ── Prices ────────────────────────────────────────────
                  if (card.prices != null) ...[
                    const SizedBox(height: 20),
                    _SectionHeader(title: 'Prices'),
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

// ── Card Text section with translation ─────────────────────────────────────────

class _CardTextSection extends ConsumerWidget {
  final YugiohCard card;

  const _CardTextSection({required this.card});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translationState = ref.watch(translationProvider(card.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with translate button
        Row(
          children: [
            _SectionHeader(title: 'Card Text'),
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

        // Translation result (if exists)
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

        // Loading indicator
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

        // Error message
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

        // Original text
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
            // Handle
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

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? trailing;

  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: AppTheme.accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.bgElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.bgBorder),
            ),
            child: Text(
              trailing!,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _TypeBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _AttributeBadge extends StatelessWidget {
  final String attribute;

  const _AttributeBadge({required this.attribute});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.getAttributeColor(attribute);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            attribute,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? iconColor;

  const _InfoChip({
    required this.label,
    required this.value,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 12, color: iconColor ?? AppTheme.textMuted),
          const SizedBox(width: 4),
        ],
        Text(
          '$label: ',
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _FormatChip extends StatelessWidget {
  final String label;

  const _FormatChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.accent,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Card Sets panel ────────────────────────────────────────────────────────────

class _CardSetsPanel extends StatefulWidget {
  final List<CardSet> sets;

  const _CardSetsPanel({required this.sets});

  @override
  State<_CardSetsPanel> createState() => _CardSetsPanelState();
}

class _CardSetsPanelState extends State<_CardSetsPanel> {
  bool _showAll = false;

  void _navigateToSet(BuildContext context, String setName) {
    // Look up CardSetInfo from the sets provider via context
    // We use a simple approach: push SetDetailScreen after finding the set
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

// ── Prices panel ───────────────────────────────────────────────────────────────

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
          Icon(
            Icons.chevron_right_rounded,
            size: 16,
            color: AppTheme.textMuted,
          ),
        ],
      ),
    );
  }
}

// ── Banlist panel ──────────────────────────────────────────────────────────────

class _BanlistPanel extends StatelessWidget {
  final BanlistInfo banlist;

  const _BanlistPanel({required this.banlist});

  @override
  Widget build(BuildContext context) {
    final entries = <_BanlistEntry>[];
    if (banlist.tcg != null) {
      entries.add(_BanlistEntry(format: 'TCG', status: banlist.tcg!));
    }
    if (banlist.ocg != null) {
      entries.add(_BanlistEntry(format: 'OCG', status: banlist.ocg!));
    }
    if (banlist.goat != null) {
      entries.add(_BanlistEntry(format: 'GOAT', status: banlist.goat!));
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: entries.map((e) => _BanlistBadge(entry: e)).toList(),
    );
  }
}

class _BanlistEntry {
  final String format;
  final BanlistStatus status;
  const _BanlistEntry({required this.format, required this.status});
}

class _BanlistBadge extends StatelessWidget {
  final _BanlistEntry entry;

  const _BanlistBadge({required this.entry});

  Color get _statusColor {
    switch (entry.status) {
      case BanlistStatus.forbidden:
        return const Color(0xFFE74C3C); // red
      case BanlistStatus.limited:
        return const Color(0xFFFFB800); // gold
      case BanlistStatus.semiLimited:
        return const Color(0xFF3498DB); // blue
    }
  }

  IconData get _statusIcon {
    switch (entry.status) {
      case BanlistStatus.forbidden:
        return Icons.block_rounded;
      case BanlistStatus.limited:
        return Icons.looks_one_rounded;
      case BanlistStatus.semiLimited:
        return Icons.looks_two_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_statusIcon, size: 14, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                entry.format,
                style: TextStyle(
                  color: color.withValues(alpha: 0.8),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                entry.status.label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Add to Deck button ─────────────────────────────────────────────────────────

class _AddToDeckButton extends ConsumerWidget {
  final YugiohCard card;
  const _AddToDeckButton({required this.card});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.library_add_rounded, size: 22),
      color: AppTheme.textSecondary,
      tooltip: 'Add to Deck',
      onPressed: () => _showAddToDeckSheet(context, ref),
    );
  }

  void _showAddToDeckSheet(BuildContext context, WidgetRef ref) {
    final decks = ref.read(deckProvider);
    if (decks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No decks yet — create one in the Collection tab'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddToDeckSheet(card: card),
    );
  }
}

class _AddToDeckSheet extends ConsumerWidget {
  final YugiohCard card;
  const _AddToDeckSheet({required this.card});

  bool get _isExtraCard =>
      card.isFusion || card.isSynchro || card.isXyz || card.isLink;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decks = ref.watch(deckProvider);
    final mdDecks = decks
        .where((d) => d.format == DeckFormat.masterDuel)
        .toList();
    final dlDecks = decks
        .where((d) => d.format == DeckFormat.duelLinks)
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      expand: false,
      builder: (_, controller) => Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add to Deck',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  _isExtraCard ? 'Extra Deck card' : 'Main Deck card',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              children: [
                if (mdDecks.isNotEmpty) ...[
                  _FormatHeader(label: 'Master Duel'),
                  ...mdDecks.map((d) => _DeckTile(deck: d, card: card)),
                ],
                if (dlDecks.isNotEmpty) ...[
                  _FormatHeader(label: 'Duel Links'),
                  ...dlDecks.map((d) => _DeckTile(deck: d, card: card)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FormatHeader extends StatelessWidget {
  final String label;
  const _FormatHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _DeckTile extends ConsumerStatefulWidget {
  final Deck deck;
  final YugiohCard card;

  const _DeckTile({required this.deck, required this.card});

  @override
  ConsumerState<_DeckTile> createState() => _DeckTileState();
}

class _DeckTileState extends ConsumerState<_DeckTile> {
  // _value = số lượng user muốn có trong deck (khởi tạo = copyCount hiện tại)
  int? _value; // null = chưa init

  bool get _isExtraCard =>
      widget.card.isFusion ||
      widget.card.isSynchro ||
      widget.card.isXyz ||
      widget.card.isLink;

  @override
  Widget build(BuildContext context) {
    final decks = ref.watch(deckProvider);
    final deck = decks.firstWhere(
      (d) => d.id == widget.deck.id,
      orElse: () => widget.deck,
    );
    final cfg = deck.config;

    final deckSize = _isExtraCard
        ? deck.extraDeck.length
        : deck.mainDeck.length;
    final maxDeck = _isExtraCard ? cfg.extraMax : cfg.mainMax;

    // Số copy card này đang có trong deck
    final copyCount = _isExtraCard
        ? deck.extraDeck.where((id) => id == widget.card.id).length
        : deck.mainDeck.where((id) => id == widget.card.id).length;

    // Init _value lần đầu
    _value ??= copyCount;

    // Giới hạn tăng: không vượt 3 copies, không vượt deck size
    final canIncrease = _value! < 3 && deckSize < maxDeck;
    final canDecrease = _value! > 0;
    final isDirty = _value != copyCount;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDirty
              ? AppTheme.accent.withValues(alpha: 0.5)
              : AppTheme.bgBorder,
          width: isDirty ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Deck icon
          const Icon(Icons.style_rounded, size: 18, color: AppTheme.accent),
          const SizedBox(width: 12),

          // Deck name + slot info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deck.name,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _isExtraCard
                      ? 'Extra: $deckSize/$maxDeck'
                      : 'Main: $deckSize/$maxDeck',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Stepper −/value/+
          Container(
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.bgBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StepBtn(
                  icon: Icons.remove_rounded,
                  enabled: canDecrease,
                  onTap: () => setState(() => _value = _value! - 1),
                ),
                SizedBox(
                  width: 28,
                  child: Center(
                    child: Text(
                      '${_value!}',
                      style: TextStyle(
                        color: isDirty ? AppTheme.accent : AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                _StepBtn(
                  icon: Icons.add_rounded,
                  enabled: canIncrease,
                  onTap: () => setState(() => _value = _value! + 1),
                ),
              ],
            ),
          ),

          // Save button — luôn hiển thị, disable khi chưa thay đổi
          const SizedBox(width: 10),
          FilledButton(
            onPressed: isDirty ? () => _save(context, copyCount) : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.black,
              disabledBackgroundColor: AppTheme.bgBorder,
              disabledForegroundColor: AppTheme.textMuted,
              minimumSize: const Size(56, 36),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Save',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _save(BuildContext context, int currentCopyCount) {
    final target = _value!;
    final diff = target - currentCopyCount;
    final notifier = ref.read(deckProvider.notifier);
    final zone = _isExtraCard ? DeckZone.extra : DeckZone.main;

    if (diff > 0) {
      // Add thêm
      String? error;
      for (var i = 0; i < diff; i++) {
        error = notifier.addCard(widget.deck.id, widget.card);
        if (error != null) break;
      }
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFE74C3C),
          ),
        );
        setState(() => _value = currentCopyCount); // revert
        return;
      }
    } else if (diff < 0) {
      // Remove bớt
      for (var i = 0; i < diff.abs(); i++) {
        notifier.removeCard(widget.deck.id, widget.card.id, zone);
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          diff > 0
              ? 'Added $diff to "${widget.deck.name}"'
              : 'Removed ${diff.abs()} from "${widget.deck.name}"',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.accent.withValues(alpha: 0.9),
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _StepBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? AppTheme.accent : AppTheme.textMuted,
        ),
      ),
    );
  }
}
