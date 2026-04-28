import 'package:flutter/material.dart';
import '../models/card_model.dart';
import '../utils/app_theme.dart';

// ── Section header ────────────────────────────────────────────────────────────

class CardDetailSectionHeader extends StatelessWidget {
  final String title;
  final String? trailing;

  const CardDetailSectionHeader({
    super.key,
    required this.title,
    this.trailing,
  });

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

// ── Type badge ────────────────────────────────────────────────────────────────

class CardTypeBadge extends StatelessWidget {
  final String label;
  final Color color;

  const CardTypeBadge({super.key, required this.label, required this.color});

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

// ── Attribute badge ───────────────────────────────────────────────────────────

class CardAttributeBadge extends StatelessWidget {
  final String attribute;

  const CardAttributeBadge({super.key, required this.attribute});

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

// ── Stat badge (ATK / DEF) ────────────────────────────────────────────────────

class CardStatBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const CardStatBadge({
    super.key,
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

// ── Info chip (Race, Level, Archetype…) ───────────────────────────────────────

class CardInfoChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? iconColor;

  const CardInfoChip({
    super.key,
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

// ── Format chip ───────────────────────────────────────────────────────────────

class CardFormatChip extends StatelessWidget {
  final String label;

  const CardFormatChip({super.key, required this.label});

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

// ── Banlist panel ─────────────────────────────────────────────────────────────

class CardBanlistPanel extends StatelessWidget {
  final BanlistInfo banlist;

  const CardBanlistPanel({super.key, required this.banlist});

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
        return const Color(0xFFE74C3C);
      case BanlistStatus.limited:
        return const Color(0xFFFFB800);
      case BanlistStatus.semiLimited:
        return const Color(0xFF3498DB);
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

// ── TCG Rarity section ────────────────────────────────────────────────────────

class CardTcgRaritySection extends StatelessWidget {
  final List<CardSet> sets;
  const CardTcgRaritySection({super.key, required this.sets});

  static const _order = [
    '(C)',
    '(R)',
    '(SR)',
    '(UR)',
    '(ScR)',
    '(StR)',
    '(GR)',
    '(CR)',
    '(QCR)',
  ];

  static Color _rarityColor(String code) {
    switch (code) {
      case '(C)':
        return const Color(0xFF9E9E9E);
      case '(R)':
        return const Color(0xFF74B9FF);
      case '(SR)':
        return const Color(0xFF00C896);
      case '(UR)':
        return const Color(0xFFFFB800);
      case '(ScR)':
        return const Color(0xFFFF6B6B);
      case '(StR)':
        return const Color(0xFFE040FB);
      case '(GR)':
        return const Color(0xFFFFD700);
      case '(CR)':
        return const Color(0xFF00E5FF);
      case '(QCR)':
        return const Color(0xFFFF9800);
      default:
        return const Color(0xFF546E7A);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rarityMap = <String, String>{};
    for (final s in sets) {
      if (s.setRarityCode.isNotEmpty) {
        rarityMap[s.setRarityCode] = s.setRarity;
      }
    }
    if (rarityMap.isEmpty) return const SizedBox.shrink();

    final sorted = rarityMap.entries.toList()
      ..sort((a, b) {
        final ai = _order.indexOf(a.key);
        final bi = _order.indexOf(b.key);
        if (ai == -1 && bi == -1) return a.key.compareTo(b.key);
        if (ai == -1) return 1;
        if (bi == -1) return -1;
        return ai.compareTo(bi);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CardDetailSectionHeader(title: 'TCG Rarity'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: sorted.map((entry) {
            final color = _rarityColor(entry.key);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    entry.value,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    entry.key,
                    style: TextStyle(
                      color: color.withValues(alpha: 0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
