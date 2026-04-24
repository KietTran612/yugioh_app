import 'package:flutter/material.dart';
import '../models/card_model.dart';
import '../providers/card_sets_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/card_item.dart';
import 'card_detail_screen.dart';
import 'main_shell.dart' show tabPush;

class SetDetailScreen extends StatefulWidget {
  final CardSetInfo setInfo;

  const SetDetailScreen({super.key, required this.setInfo});

  @override
  State<SetDetailScreen> createState() => _SetDetailScreenState();
}

class _SetDetailScreenState extends State<SetDetailScreen> {
  String _selectedRarity = 'All';
  String _selectedType = 'All'; // Monster / Spell / Trap
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<YugiohCard> get _filteredCards {
    var cards = widget.setInfo.cards;

    // Filter by card type category
    if (_selectedType != 'All') {
      cards = cards.where((c) {
        switch (_selectedType) {
          case 'Monster':
            return c.isMonster;
          case 'Spell':
            return c.isSpell;
          case 'Trap':
            return c.isTrap;
          default:
            return true;
        }
      }).toList();
    }

    // Filter by rarity
    if (_selectedRarity != 'All') {
      cards = cards.where((c) {
        return c.sets.any(
          (s) =>
              s.setName == widget.setInfo.setName &&
              s.setRarity == _selectedRarity,
        );
      }).toList();
    }

    // Filter by search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      cards = cards
          .where(
            (c) =>
                c.name.toLowerCase().contains(q) ||
                c.race.toLowerCase().contains(q) ||
                c.type.toLowerCase().contains(q),
          )
          .toList();
    }

    // Sort by set code (card number within set)
    cards = List.from(cards)
      ..sort((a, b) {
        final aCode = _getSetCode(a);
        final bCode = _getSetCode(b);
        return aCode.compareTo(bCode);
      });

    return cards;
  }

  String _getSetCode(YugiohCard card) {
    final match = card.sets.where((s) => s.setName == widget.setInfo.setName);
    return match.isNotEmpty ? match.first.setCode : '';
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredCards;
    final rarities = ['All', ...widget.setInfo.rarities];

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: CustomScrollView(
        slivers: [
          // ── AppBar ────────────────────────────────────────────────────
          SliverAppBar(
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
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.setInfo.setName,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.setInfo.setCode.isNotEmpty)
                  Text(
                    widget.setInfo.setCode,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: AppTheme.bgBorder),
            ),
          ),

          // ── Search + stats bar ────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats row
                  Row(
                    children: [
                      _StatPill(
                        icon: Icons.style_rounded,
                        label: '${widget.setInfo.cardCount} cards',
                        color: AppTheme.accent,
                      ),
                      const SizedBox(width: 8),
                      _StatPill(
                        icon: Icons.auto_awesome_rounded,
                        label: '${widget.setInfo.rarities.length} rarities',
                        color: AppTheme.accentGold,
                      ),
                      if (_selectedRarity != 'All' ||
                          _selectedType != 'All' ||
                          _searchQuery.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        _StatPill(
                          icon: Icons.filter_list_rounded,
                          label: '${filtered.length} shown',
                          color: AppTheme.textSecondary,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Search
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search in this set...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),

          // ── Type filter chips ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final type in ['All', 'Monster', 'Spell', 'Trap']) ...[
                    _FilterChip(
                      label: type,
                      isSelected: _selectedType == type,
                      color: _typeColor(type),
                      onTap: () => setState(() => _selectedType = type),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // ── Rarity filter chips ───────────────────────────────────────
          SliverToBoxAdapter(
            child: SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: rarities.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final rarity = rarities[index];
                  final isSelected = _selectedRarity == rarity;
                  final color = rarity == 'All'
                      ? AppTheme.textSecondary
                      : _rarityColor(rarity);

                  return _FilterChip(
                    label: rarity,
                    isSelected: isSelected,
                    color: color,
                    onTap: () => setState(() => _selectedRarity = rarity),
                  );
                },
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // ── Card grid ─────────────────────────────────────────────────
          filtered.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: AppTheme.textMuted,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No cards found',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final card = filtered[index];
                      return CardItem(
                        card: card,
                        onTap: () => tabPush(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CardDetailScreen(card: card),
                          ),
                        ),
                      );
                    }, childCount: filtered.length),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _getCrossAxisCount(context),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.69,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 6;
    if (width > 800) return 4;
    if (width > 600) return 3;
    return 2;
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

  Color _typeColor(String type) {
    switch (type) {
      case 'Monster':
        return const Color(0xFFFFB800);
      case 'Spell':
        return const Color(0xFF27AE60);
      case 'Trap':
        return const Color(0xFFC71585);
      default:
        return AppTheme.accent;
    }
  }
}

// ── Filter chip ────────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.2)
              : AppTheme.bgElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.7)
                : AppTheme.bgBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ── Stat pill ──────────────────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
