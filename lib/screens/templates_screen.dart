// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:habit_tracker/config/habit_templates.dart';
import 'package:habit_tracker/config/category_config.dart';
import 'package:habit_tracker/screens/goals_screen.dart';

// ─── Theme helper (mirrors _T in goals_screen) ────────────────────────────────
class _T {
  final Color bg, card, txt, sub, border;
  const _T({required this.bg, required this.card, required this.txt, required this.sub, required this.border});

  static const purple = Color(0xFF8B7FFF);
  static const r16 = 16.0;

  static _T of(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return dark
        ? const _T(bg: Color(0xFF0F0F14), card: Color(0xFF1A1A24), txt: Color(0xFFF2F2F7), sub: Color(0xFF8E8E93), border: Color(0xFF2C2C3A))
        : const _T(bg: Color(0xFFF8F8FC), card: Colors.white, txt: Color(0xFF1C1C1E), sub: Color(0xFF6E6E73), border: Color(0xFFE5E5EA));
  }

  TextStyle heading({double size = 17}) => TextStyle(fontSize: size, fontWeight: FontWeight.w700, color: txt, letterSpacing: -0.4);
  TextStyle body({double size = 14}) => TextStyle(fontSize: size, fontWeight: FontWeight.w400, color: sub);
  TextStyle label({double size = 13}) => TextStyle(fontSize: size, fontWeight: FontWeight.w600, color: txt);
}

class TemplatesScreen extends StatefulWidget {
  final void Function(List<Goal> goals) onImport;

  const TemplatesScreen({super.key, required this.onImport});

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  // packIndex → set of selected habit indices
  final Map<int, Set<int>> _selected = {};
  int? _expandedPack;

  bool get _hasSelection => _selected.values.any((s) => s.isNotEmpty);
  int get _totalSelected => _selected.values.fold(0, (sum, s) => sum + s.length);

  void _toggleHabit(int packIdx, int habitIdx) {
    setState(() {
      _selected.putIfAbsent(packIdx, () => {});
      if (_selected[packIdx]!.contains(habitIdx)) {
        _selected[packIdx]!.remove(habitIdx);
      } else {
        _selected[packIdx]!.add(habitIdx);
      }
    });
  }

  void _selectAll(int packIdx) {
    final count = HabitTemplates.packs[packIdx].habits.length;
    setState(() {
      _selected[packIdx] = Set.from(List.generate(count, (i) => i));
    });
  }

  void _deselectAll(int packIdx) {
    setState(() {
      _selected[packIdx] = {};
    });
  }

  void _importSelected() {
    final goals = <Goal>[];
    _selected.forEach((packIdx, habitIndices) {
      for (final hi in habitIndices) {
        final t = HabitTemplates.packs[packIdx].habits[hi];
        goals.add(Goal(
          title: t.title,
          description: t.description,
          targetDays: t.targetDays,
          currentDays: 0,
          category: t.category,
          color: t.color,
          icon: t.icon,
        ));
      }
    });
    widget.onImport(goals);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = _T.of(context);
    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: t.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: t.txt, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        centerTitle: true,
        title: Text('Habit Templates', style: t.heading(size: 16)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: t.border),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: HabitTemplates.packs.length,
              itemBuilder: (ctx, packIdx) {
                final pack = HabitTemplates.packs[packIdx];
                final isExpanded = _expandedPack == packIdx;
                final selCount = _selected[packIdx]?.length ?? 0;
                return _PackCard(
                  pack: pack,
                  packIdx: packIdx,
                  isExpanded: isExpanded,
                  selectedCount: selCount,
                  selected: _selected[packIdx] ?? {},
                  onTap: () => setState(() => _expandedPack = isExpanded ? null : packIdx),
                  onToggleHabit: _toggleHabit,
                  onSelectAll: () => _selectAll(packIdx),
                  onDeselectAll: () => _deselectAll(packIdx),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _hasSelection
          ? _ImportBar(count: _totalSelected, onImport: _importSelected)
          : null,
    );
  }
}

// ─── Pack card ────────────────────────────────────────────────────────────────

class _PackCard extends StatelessWidget {
  final TemplatePack pack;
  final int packIdx;
  final bool isExpanded;
  final int selectedCount;
  final Set<int> selected;
  final VoidCallback onTap;
  final void Function(int packIdx, int habitIdx) onToggleHabit;
  final VoidCallback onSelectAll;
  final VoidCallback onDeselectAll;

  const _PackCard({
    required this.pack,
    required this.packIdx,
    required this.isExpanded,
    required this.selectedCount,
    required this.selected,
    required this.onTap,
    required this.onToggleHabit,
    required this.onSelectAll,
    required this.onDeselectAll,
  });

  @override
  Widget build(BuildContext context) {
    final t = _T.of(context);
    final allSelected = selectedCount == pack.habits.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(_T.r16),
        border: Border.all(
          color: selectedCount > 0 ? pack.color.withValues(alpha: 0.6) : t.border,
          width: selectedCount > 0 ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          InkWell(
            onTap: onTap,
            borderRadius: isExpanded
                ? const BorderRadius.vertical(top: Radius.circular(_T.r16))
                : BorderRadius.circular(_T.r16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Emoji badge
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: pack.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(pack.emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(pack.name, style: t.heading(size: 15)),
                            if (selectedCount > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: pack.color.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('$selectedCount selected',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: pack.color)),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(pack.description, style: t.body(size: 12)),
                        const SizedBox(height: 4),
                        Text('${pack.habits.length} habits',
                            style: TextStyle(fontSize: 11, color: pack.color, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: t.sub,
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded habit list ──────────────────────────────────────────────
          if (isExpanded) ...[
            Divider(height: 1, thickness: 1, color: t.border),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text('Select habits to add', style: t.body(size: 12)),
                  const Spacer(),
                  TextButton(
                    onPressed: allSelected ? onDeselectAll : onSelectAll,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      allSelected ? 'Deselect all' : 'Select all',
                      style: TextStyle(fontSize: 12, color: pack.color, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            ...pack.habits.asMap().entries.map((entry) {
              final habitIdx = entry.key;
              final habit = entry.value;
              final isSelected = selected.contains(habitIdx);
              final catMeta = CategoryConfig.forName(habit.category);
              return _HabitTile(
                habit: habit,
                catMeta: catMeta,
                isSelected: isSelected,
                packColor: pack.color,
                onTap: () => onToggleHabit(packIdx, habitIdx),
                isLast: habitIdx == pack.habits.length - 1,
              );
            }),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

// ─── Habit tile ───────────────────────────────────────────────────────────────

class _HabitTile extends StatelessWidget {
  final HabitTemplate habit;
  final CategoryMeta catMeta;
  final bool isSelected;
  final Color packColor;
  final VoidCallback onTap;
  final bool isLast;

  const _HabitTile({
    required this.habit,
    required this.catMeta,
    required this.isSelected,
    required this.packColor,
    required this.onTap,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final t = _T.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Icon badge
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: habit.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(habit.icon, color: habit.color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(habit.title, style: t.label(size: 14)),
                  const SizedBox(height: 2),
                  Text(habit.description, style: t.body(size: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(catMeta.icon, size: 11, color: catMeta.color),
                      const SizedBox(width: 3),
                      Text(habit.category,
                          style: TextStyle(fontSize: 11, color: catMeta.color, fontWeight: FontWeight.w500)),
                      const SizedBox(width: 8),
                      Icon(Icons.local_fire_department_rounded, size: 11, color: t.sub),
                      const SizedBox(width: 2),
                      Text('${habit.targetDays}d goal', style: t.body(size: 11)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Checkbox
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22, height: 22,
              decoration: BoxDecoration(
                color: isSelected ? packColor : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected ? packColor : t.border,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Import bar ───────────────────────────────────────────────────────────────

class _ImportBar extends StatelessWidget {
  final int count;
  final VoidCallback onImport;

  const _ImportBar({required this.count, required this.onImport});

  @override
  Widget build(BuildContext context) {
    final t = _T.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: t.card,
        border: Border(top: BorderSide(color: t.border)),
      ),
      child: FilledButton.icon(
        onPressed: onImport,
        icon: const Icon(Icons.download_rounded, size: 18),
        label: Text('Add $count habit${count == 1 ? '' : 's'} to my goals'),
        style: FilledButton.styleFrom(
          backgroundColor: _T.purple,
          minimumSize: const Size.fromHeight(48),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
