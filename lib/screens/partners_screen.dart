// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:habit_tracker/services/partnership_service.dart';
import 'package:habit_tracker/services/firestore_service.dart';
import 'package:habit_tracker/theme/app_colors.dart';

class PartnersScreen extends StatefulWidget {
  const PartnersScreen({super.key});

  @override
  State<PartnersScreen> createState() => _PartnersScreenState();
}

class _PartnersScreenState extends State<PartnersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _accent => _isDark ? AppColors.lime : AppColors.purpleLight;
  Color get _bg => _isDark ? AppColors.bg : AppColors.canvas;
  Color get _bg2 => _isDark ? AppColors.bg2 : Colors.white;
  Color get _txt => _isDark ? AppColors.textPrimary : AppColors.ink;
  Color get _txt2 => _isDark ? AppColors.textSecondary : AppColors.ink2;
  Color get _txt3 => _isDark ? AppColors.textMuted : AppColors.ink3;
  Color get _border =>
      _isDark ? AppColors.borderDark : AppColors.borderLight;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg2,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: _txt, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        centerTitle: true,
        title: Text('Accountability',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _txt,
                letterSpacing: -0.4)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Column(
            children: [
              Divider(height: 1, thickness: 1, color: _border),
              TabBar(
                controller: _tabs,
                labelColor: _accent,
                unselectedLabelColor: _txt3,
                indicatorColor: _accent,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
                unselectedLabelStyle:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                tabs: const [
                  Tab(text: 'My Partners'),
                  Tab(text: 'Add Partner'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _MyPartnersTab(
            isDark: _isDark,
            accent: _accent,
            bg2: _bg2,
            txt: _txt,
            txt2: _txt2,
            txt3: _txt3,
            border: _border,
          ),
          _AddPartnerTab(
            isDark: _isDark,
            accent: _accent,
            bg2: _bg2,
            txt: _txt,
            txt2: _txt2,
            txt3: _txt3,
            border: _border,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// My Partners tab — shows active partnerships + nudge buttons
// ─────────────────────────────────────────────────────────────────────────────
class _MyPartnersTab extends StatefulWidget {
  final bool isDark;
  final Color accent, bg2, txt, txt2, txt3, border;

  const _MyPartnersTab({
    required this.isDark,
    required this.accent,
    required this.bg2,
    required this.txt,
    required this.txt2,
    required this.txt3,
    required this.border,
  });

  @override
  State<_MyPartnersTab> createState() => _MyPartnersTabState();
}

class _MyPartnersTabState extends State<_MyPartnersTab> {
  List<Map<String, dynamic>> _partnerships = [];
  bool _loading = true;
  final Set<String> _nudging = {};
  final _service = PartnershipService();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await _service.getPartnerships();
    if (mounted) setState(() { _partnerships = result; _loading = false; });
  }

  Future<void> _nudge(
      String partnershipId, String habitTitle) async {
    final key = '$partnershipId-$habitTitle';
    if (_nudging.contains(key)) return;
    setState(() => _nudging.add(key));

    final sent = await _service.nudgePartner(partnershipId, habitTitle);
    if (!mounted) return;
    setState(() => _nudging.remove(key));

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(sent
          ? 'Nudge sent for "$habitTitle" 💪'
          : 'Could not send nudge. Try again.'),
      behavior: SnackBarBehavior.floating,
      backgroundColor: sent ? AppColors.teal : AppColors.coral,
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(
          child: CircularProgressIndicator(color: widget.accent, strokeWidth: 2));
    }

    if (_partnerships.isEmpty) {
      return _EmptyPartners(
          accent: widget.accent, txt2: widget.txt2, bg2: widget.bg2);
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: widget.accent,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _partnerships.length,
        itemBuilder: (ctx, i) {
          final p = _partnerships[i];
          final name = p['partnerName'] as String? ?? 'Partner';
          final partnershipId = p['partnershipId'] as String;
          final habitTitles = List<String>.from(p['habitTitles'] ?? []);

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              decoration: BoxDecoration(
                color: widget.bg2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: widget.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Partner header ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: widget.accent.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: widget.accent),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name,
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: widget.txt,
                                      letterSpacing: -0.3)),
                              const SizedBox(height: 2),
                              Text(
                                '${habitTitles.length} shared habit${habitTitles.length == 1 ? '' : 's'}',
                                style: TextStyle(
                                    fontSize: 11, color: widget.txt3),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: widget.border),
                  // ── Habit rows ──
                  ...habitTitles.map((title) {
                    final nudgeKey = '$partnershipId-$title';
                    final isNudging = _nudging.contains(nudgeKey);
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Icon(Icons.track_changes_rounded,
                              size: 18, color: widget.txt3),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(title,
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: widget.txt,
                                    letterSpacing: -0.2)),
                          ),
                          GestureDetector(
                            onTap: isNudging
                                ? null
                                : () => _nudge(partnershipId, title),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: isNudging
                                    ? widget.accent.withOpacity(0.2)
                                    : widget.accent,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: isNudging
                                  ? SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1.5,
                                        color: widget.isDark
                                            ? AppColors.bg
                                            : Colors.white,
                                      ),
                                    )
                                  : Text('Nudge 👉',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: widget.isDark
                                            ? AppColors.bg
                                            : Colors.white,
                                      )),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add Partner tab — create invite or enter code
// ─────────────────────────────────────────────────────────────────────────────
class _AddPartnerTab extends StatefulWidget {
  final bool isDark;
  final Color accent, bg2, txt, txt2, txt3, border;

  const _AddPartnerTab({
    required this.isDark,
    required this.accent,
    required this.bg2,
    required this.txt,
    required this.txt2,
    required this.txt3,
    required this.border,
  });

  @override
  State<_AddPartnerTab> createState() => _AddPartnerTabState();
}

class _AddPartnerTabState extends State<_AddPartnerTab> {
  // ── Create invite state ──
  List<_HabitOption> _habitOptions = [];
  final Set<String> _selectedIds = {};
  String? _inviteCode;
  bool _creating = false;
  bool _loadingHabits = true;

  // ── Accept invite state ──
  final TextEditingController _codeCtrl = TextEditingController();
  bool _accepting = false;

  final _service = PartnershipService();

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    try {
      final goals = await FirestoreService().loadHabits();
      if (mounted) {
        setState(() {
          _habitOptions = goals.map((g) {
            final docId =
                g.title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
            return _HabitOption(id: docId, title: g.title);
          }).toList();
          _loadingHabits = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingHabits = false);
    }
  }

  Future<void> _createInvite() async {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Select at least one habit to share'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() => _creating = true);
    final selected =
        _habitOptions.where((h) => _selectedIds.contains(h.id)).toList();
    final result = await _service.createPartnership(
      habitIds: selected.map((h) => h.id).toList(),
      habitTitles: selected.map((h) => h.title).toList(),
    );
    if (!mounted) return;
    setState(() {
      _creating = false;
      _inviteCode = result?['inviteCode'];
    });
  }

  Future<void> _acceptInvite() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Enter the 6-character code from your friend'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() => _accepting = true);
    try {
      final ownerName = await _service.acceptPartnership(code);
      if (!mounted) return;
      setState(() => _accepting = false);
      _codeCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            "You're now holding ${ownerName ?? 'your friend'} accountable! 🎯"),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.teal,
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _accepting = false);
      final msg = e.toString().contains('Invalid or already-used') ||
              e.toString().contains("can't join your own")
          ? e.toString().replaceFirst('Exception: ', '')
          : 'Could not accept invite. Try again.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.coral,
      ));
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section: Create invite ──
          _SectionHeader(
              title: 'Invite a friend',
              subtitle: "They'll be able to nudge you if you miss a habit",
              txt: widget.txt,
              txt3: widget.txt3),
          const SizedBox(height: 12),

          if (_loadingHabits)
            Center(
                child: CircularProgressIndicator(
                    color: widget.accent, strokeWidth: 2))
          else if (_habitOptions.isEmpty)
            _InfoBox(
                message: 'Add some habits first before inviting a partner.',
                bg2: widget.bg2,
                txt2: widget.txt2,
                border: widget.border)
          else if (_inviteCode != null)
            _InviteCodeCard(
              code: _inviteCode!,
              accent: widget.accent,
              bg2: widget.bg2,
              txt: widget.txt,
              txt2: widget.txt2,
              border: widget.border,
              onReset: () => setState(() {
                _inviteCode = null;
                _selectedIds.clear();
              }),
            )
          else ...[
            // Habit picker
            Container(
              decoration: BoxDecoration(
                color: widget.bg2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: widget.border),
              ),
              child: Column(
                children: _habitOptions.asMap().entries.map((entry) {
                  final i = entry.key;
                  final h = entry.value;
                  final selected = _selectedIds.contains(h.id);
                  return Column(
                    children: [
                      if (i > 0) Divider(height: 1, color: widget.border),
                      CheckboxListTile(
                        value: selected,
                        activeColor: widget.accent,
                        checkColor:
                            widget.isDark ? AppColors.bg : Colors.white,
                        title: Text(h.title,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: widget.txt)),
                        onChanged: (v) => setState(() {
                          if (v == true) {
                            _selectedIds.add(h.id);
                          } else {
                            _selectedIds.remove(h.id);
                          }
                        }),
                        controlAffinity: ListTileControlAffinity.trailing,
                        dense: true,
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _creating ? null : _createInvite,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.accent,
                  disabledBackgroundColor: widget.accent.withOpacity(0.4),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: _creating
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: widget.isDark ? AppColors.bg : Colors.white,
                        ),
                      )
                    : Text('Generate invite code',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: widget.isDark
                                ? AppColors.bg
                                : Colors.white)),
              ),
            ),
          ],

          const SizedBox(height: 32),
          Divider(color: widget.border),
          const SizedBox(height: 24),

          // ── Section: Accept invite ──
          _SectionHeader(
              title: 'Have a code?',
              subtitle: 'Enter the 6-character code from your friend',
              txt: widget.txt,
              txt3: widget.txt3),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _codeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 6,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 4,
                      color: widget.txt),
                  decoration: InputDecoration(
                    hintText: 'ABC123',
                    hintStyle: TextStyle(
                        fontSize: 18,
                        letterSpacing: 4,
                        color: widget.txt3,
                        fontWeight: FontWeight.w400),
                    counterText: '',
                    filled: true,
                    fillColor: widget.bg2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: widget.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: widget.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: widget.accent, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _accepting ? null : _acceptInvite,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.accent,
                    disabledBackgroundColor: widget.accent.withOpacity(0.4),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _accepting
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: widget.isDark ? AppColors.bg : Colors.white,
                          ),
                        )
                      : Text('Join',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: widget.isDark
                                  ? AppColors.bg
                                  : Colors.white)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Supporting widgets
// ─────────────────────────────────────────────────────────────────────────────

class _HabitOption {
  final String id, title;
  const _HabitOption({required this.id, required this.title});
}

class _SectionHeader extends StatelessWidget {
  final String title, subtitle;
  final Color txt, txt3;
  const _SectionHeader(
      {required this.title,
      required this.subtitle,
      required this.txt,
      required this.txt3});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: txt,
                letterSpacing: -0.4)),
        const SizedBox(height: 3),
        Text(subtitle, style: TextStyle(fontSize: 12, color: txt3)),
      ],
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String message;
  final Color bg2, txt2, border;
  const _InfoBox(
      {required this.message,
      required this.bg2,
      required this.txt2,
      required this.border});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: bg2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border)),
      child: Text(message, style: TextStyle(fontSize: 13, color: txt2)),
    );
  }
}

class _InviteCodeCard extends StatelessWidget {
  final String code;
  final Color accent, bg2, txt, txt2, border;
  final VoidCallback onReset;

  const _InviteCodeCard({
    required this.code,
    required this.accent,
    required this.bg2,
    required this.txt,
    required this.txt2,
    required this.border,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text('Share this code with your friend',
              style: TextStyle(fontSize: 13, color: txt2)),
          const SizedBox(height: 16),
          Text(code,
              style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 8,
                  color: accent)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Code copied!'),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 1),
                    ));
                  },
                  icon: Icon(Icons.copy_rounded, size: 14, color: accent),
                  label: Text('Copy',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: accent)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: accent.withOpacity(0.4)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onReset,
                  icon: Icon(Icons.add_rounded, size: 14, color: txt2),
                  label: Text('New code',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: txt2)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: border),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('Code is valid until your friend joins',
              style: TextStyle(fontSize: 11, color: txt2)),
        ],
      ),
    );
  }
}

class _EmptyPartners extends StatelessWidget {
  final Color accent, txt2, bg2;
  const _EmptyPartners(
      {required this.accent, required this.txt2, required this.bg2});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.people_outline_rounded,
                  size: 32, color: accent),
            ),
            const SizedBox(height: 20),
            Text('No partners yet',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: accent)),
            const SizedBox(height: 8),
            Text(
              "Invite a friend to keep each other accountable. They'll see your habits and can nudge you.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: txt2, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
