// ignore_for_file: deprecated_member_use, prefer_interpolation_to_compose_strings, curly_braces_in_flow_control_structures

import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:habit_tracker/theme/theme_controller.dart';

// ─── Models ───────────────────────────────────────────────────────────────────

class _Cycle {
  final DateTime start;
  final DateTime end;
  final int durationDays;
  final List<String> symptoms;

  const _Cycle({
    required this.start,
    required this.end,
    required this.durationDays,
    this.symptoms = const [],
  });

  Map<String, dynamic> toJson() => {
    'start': start.millisecondsSinceEpoch,
    'end': end.millisecondsSinceEpoch,
    'duration': durationDays,
    'symptoms': symptoms,
  };

  factory _Cycle.fromJson(Map<String, dynamic> j) => _Cycle(
    start: DateTime.fromMillisecondsSinceEpoch(j['start'] as int),
    end: DateTime.fromMillisecondsSinceEpoch(j['end'] as int),
    durationDays: j['duration'] as int,
    symptoms: (j['symptoms'] as List?)?.cast<String>() ?? [],
  );
}

class _DayLog {
  final DateTime date;
  final String flow;
  final List<String> symptoms;

  const _DayLog({required this.date, this.flow = '', this.symptoms = const []});

  Map<String, dynamic> toJson() => {
    'date': date.millisecondsSinceEpoch,
    'flow': flow,
    'symptoms': symptoms,
  };

  factory _DayLog.fromJson(Map<String, dynamic> j) => _DayLog(
    date: DateTime.fromMillisecondsSinceEpoch(j['date'] as int),
    flow: j['flow'] as String? ?? '',
    symptoms: (j['symptoms'] as List?)?.cast<String>() ?? [],
  );
}

// ─── Constants ────────────────────────────────────────────────────────────────

const _kSymptoms = [
  ('cramps', Icons.electric_bolt_rounded),
  ('headache', Icons.psychology_rounded),
  ('bloating', Icons.circle_outlined),
  ('fatigue', Icons.bedtime_rounded),
  ('mood swings', Icons.mood_bad_rounded),
  ('back pain', Icons.accessibility_new_rounded),
  ('nausea', Icons.sick_rounded),
  ('tender breasts', Icons.favorite_border_rounded),
  ('spotting', Icons.water_drop_rounded),
  ('insomnia', Icons.nightlight_rounded),
];

const _kFlowLevels = ['spotting', 'light', 'medium', 'heavy'];

const Color _rose = Color(0xFFE57373);
const Color _roseDim = Color(0xFFF48FB1);
const Color _lavender = Color(0xFFCE93D8);
const Color _teal = Color(0xFF80CBC4);

// ─── Screen ───────────────────────────────────────────────────────────────────

class PeriodTrackerScreen extends StatefulWidget {
  const PeriodTrackerScreen({super.key});

  @override
  State<PeriodTrackerScreen> createState() => _PeriodTrackerScreenState();
}

class _PeriodTrackerScreenState extends State<PeriodTrackerScreen> {
  static const _prefKeyCycles = 'period_cycles_v1';
  static const _prefKeyDayLogs = 'period_day_logs_v1';

  List<_Cycle> _cycles = [];
  Map<String, _DayLog> _dayLogs = {};
  bool _isOnPeriod = false;
  DateTime? _currentStart;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final rawCycles = prefs.getString(_prefKeyCycles);
    if (rawCycles != null) {
      final list = jsonDecode(rawCycles) as List;
      _cycles = list.map((e) => _Cycle.fromJson(e as Map<String, dynamic>)).toList();
      _cycles.sort((a, b) => b.start.compareTo(a.start));
    }
    final rawLogs = prefs.getString(_prefKeyDayLogs);
    if (rawLogs != null) {
      final map = jsonDecode(rawLogs) as Map<String, dynamic>;
      _dayLogs = map.map((k, v) => MapEntry(k, _DayLog.fromJson(v as Map<String, dynamic>)));
    }
    final startMs = prefs.getInt('period_current_start');
    if (startMs != null) {
      _currentStart = DateTime.fromMillisecondsSinceEpoch(startMs);
      _isOnPeriod = true;
    }
    if (mounted) setState(() {});
  }

  Future<void> _saveCycles() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyCycles, jsonEncode(_cycles.map((c) => c.toJson()).toList()));
  }

  Future<void> _saveDayLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _prefKeyDayLogs, jsonEncode(_dayLogs.map((k, v) => MapEntry(k, v.toJson()))));
  }

  Future<void> _startPeriod() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
      helpText: 'When did your period start?',
    );
    if (picked == null || !mounted) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('period_current_start', picked.millisecondsSinceEpoch);
    setState(() {
      _currentStart = picked;
      _isOnPeriod = true;
    });
  }

  Future<void> _endPeriod() async {
    if (_currentStart == null) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: _currentStart!,
      lastDate: DateTime.now(),
      helpText: 'When did your period end?',
    );
    if (picked == null || !mounted) return;
    final allSymptoms = <String>{};
    DateTime d = _currentStart!;
    while (!d.isAfter(picked)) {
      final log = _dayLogs[_dayKey(d)];
      if (log != null) allSymptoms.addAll(log.symptoms);
      d = d.add(const Duration(days: 1));
    }
    final duration = picked.difference(_currentStart!).inDays + 1;
    final cycle = _Cycle(
      start: _currentStart!,
      end: picked,
      durationDays: duration,
      symptoms: allSymptoms.toList(),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('period_current_start');
    setState(() {
      _cycles.insert(0, cycle);
      _isOnPeriod = false;
      _currentStart = null;
    });
    await _saveCycles();
  }

  Future<void> _deleteCycle(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete entry?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _cycles.removeAt(index));
    await _saveCycles();
  }

  void _openDayLog(BuildContext context, bool isDark, Color card, Color textPrimary,
      Color textSecondary) {
    final today = DateTime.now();
    final key = _dayKey(today);
    final existing = _dayLogs[key] ?? _DayLog(date: today);
    String selectedFlow = existing.flow;
    final selectedSymptoms = Set<String>.from(existing.symptoms);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          decoration: BoxDecoration(
            color: card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: textSecondary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Log today',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary)),
                const SizedBox(height: 6),
                Text(_formatDate(today), style: TextStyle(fontSize: 13, color: textSecondary)),
                const SizedBox(height: 20),
                Text('Flow intensity',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
                const SizedBox(height: 10),
                Row(
                  children: _kFlowLevels.map((level) {
                    final selected = selectedFlow == level;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setSheetState(() => selectedFlow = selected ? '' : level),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selected ? _rose : _rose.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(_capitalize(level),
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: selected ? Colors.white : _rose)),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Text('Symptoms',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _kSymptoms.map((s) {
                    final (name, icon) = s;
                    final selected = selectedSymptoms.contains(name);
                    return GestureDetector(
                      onTap: () => setSheetState(() {
                        if (selected) selectedSymptoms.remove(name);
                        else selectedSymptoms.add(name);
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? _rose.withOpacity(0.15) : Colors.transparent,
                          border: Border.all(
                              color: selected ? _rose : textSecondary.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, size: 14, color: selected ? _rose : textSecondary),
                            const SizedBox(width: 5),
                            Text(_capitalize(name),
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: selected ? _rose : textSecondary)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _rose,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () async {
                      final log = _DayLog(
                          date: today, flow: selectedFlow, symptoms: selectedSymptoms.toList());
                      setState(() => _dayLogs[key] = log);
                      await _saveDayLogs();
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Save',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Computed ─────────────────────────────────────────────────────────────────

  int get _avgCycleLength {
    if (_cycles.length < 2) return 28;
    int total = 0;
    for (int i = 0; i < _cycles.length - 1; i++) {
      total += _cycles[i].start.difference(_cycles[i + 1].start).inDays.abs();
    }
    return (total / (_cycles.length - 1)).round();
  }

  int get _avgPeriodDuration {
    if (_cycles.isEmpty) return 5;
    final total = _cycles.fold(0, (sum, c) => sum + c.durationDays);
    return (total / _cycles.length).round();
  }

  DateTime? get _nextPeriodDate {
    if (_cycles.isEmpty) return null;
    return _cycles.first.start.add(Duration(days: _avgCycleLength));
  }

  int? get _daysUntilNext {
    final next = _nextPeriodDate;
    if (next == null) return null;
    return next.difference(DateTime.now()).inDays;
  }

  DateTime? get _ovulationDate {
    final next = _nextPeriodDate;
    if (next == null) return null;
    return next.subtract(const Duration(days: 14));
  }

  DateTime? get _fertileStart => _ovulationDate?.subtract(const Duration(days: 5));
  DateTime? get _fertileEnd => _ovulationDate?.add(const Duration(days: 1));

  // 1-based day in current cycle, 0 if unknown
  int get _currentCycleDay {
    if (_isOnPeriod && _currentStart != null) {
      return (DateTime.now().difference(_currentStart!).inDays + 1).clamp(1, _avgCycleLength);
    }
    if (_cycles.isNotEmpty) {
      final days = DateTime.now().difference(_cycles.first.start).inDays;
      return (days % _avgCycleLength) + 1;
    }
    return 0;
  }

  String _currentPhase() {
    final day = _currentCycleDay;
    if (day == 0) return 'Unknown';
    final ovDay = _avgCycleLength - 14;
    if (day <= _avgPeriodDuration) return 'Menstrual';
    if (day < ovDay) return 'Follicular';
    if (day <= ovDay + 1) return 'Ovulation';
    return 'Luteal';
  }

  Color _phaseColor() {
    switch (_currentPhase()) {
      case 'Menstrual': return _rose;
      case 'Follicular': return _teal;
      case 'Ovulation': return _lavender;
      case 'Luteal': return _roseDim;
      default: return _rose;
    }
  }

  String _formatDate(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[d.month - 1]} ${d.day}, ${d.year}';
  }

  String _formatShort(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[d.month - 1]} ${d.day}';
  }

  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  _DayLog? get _todayLog => _dayLogs[_dayKey(DateTime.now())];

  // ─── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance,
      builder: (context, themeMode, child) {
        final isDark = themeMode == ThemeMode.dark ||
            (themeMode == ThemeMode.system &&
                MediaQuery.of(context).platformBrightness == Brightness.dark);
        final bg = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF5F5F2);
        final card = isDark ? const Color(0xFF1A1A1A) : Colors.white;
        final textPrimary = isDark ? Colors.white : const Color(0xFF0D0D0D);
        final textSecondary = isDark ? const Color(0xFF8A8AA0) : const Color(0xFF6B6B80);

        final phase = _currentPhase();
        final phaseColor = _phaseColor();
        final cycleDay = _currentCycleDay;
        final daysUntil = _daysUntilNext;
        final todayLog = _todayLog;

        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            backgroundColor: bg,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text('Period Tracker',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: textPrimary)),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Cycle Wheel ──────────────────────────────────────────────
                Center(
                  child: _CycleWheel(
                    cycleLength: _avgCycleLength,
                    periodDays: _avgPeriodDuration,
                    currentDay: cycleDay,
                    currentPhase: phase,
                    phaseColor: phaseColor,
                    isDark: isDark,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    hasCycles: _cycles.isNotEmpty || _isOnPeriod,
                    daysUntilNext: daysUntil,
                    nextPeriodDate: _nextPeriodDate,
                    isOnPeriod: _isOnPeriod,
                    currentStart: _currentStart,
                    formatDate: _formatShort,
                  ),
                ),

                const SizedBox(height: 8),

                // ── Phase legend chips ────────────────────────────────────────
                if (_cycles.isNotEmpty || _isOnPeriod) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _PhaseLegendChip('Menstrual', _rose),
                      const SizedBox(width: 8),
                      _PhaseLegendChip('Follicular', _teal),
                      const SizedBox(width: 8),
                      _PhaseLegendChip('Ovulation', _lavender),
                      const SizedBox(width: 8),
                      _PhaseLegendChip('Luteal', _roseDim),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],

                // ── Action buttons ────────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _isOnPeriod ? null : _startPeriod,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: _isOnPeriod
                                ? (isDark ? const Color(0xFF1A1A1A) : const Color(0xFFEEEEEE))
                                : _rose,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.play_circle_outline_rounded,
                                    size: 16,
                                    color: _isOnPeriod ? textSecondary : Colors.white),
                                const SizedBox(width: 6),
                                Text('Start period',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: _isOnPeriod ? textSecondary : Colors.white)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: _isOnPeriod ? _endPeriod : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: _isOnPeriod
                                ? _rose
                                : (isDark ? const Color(0xFF1A1A1A) : const Color(0xFFEEEEEE)),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.stop_circle_outlined,
                                    size: 16,
                                    color: _isOnPeriod ? Colors.white : textSecondary),
                                const SizedBox(width: 6),
                                Text('End period',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: _isOnPeriod ? Colors.white : textSecondary)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ── Log today button ──────────────────────────────────────────
                GestureDetector(
                  onTap: () => _openDayLog(context, isDark, card, textPrimary, textSecondary),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _rose.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.edit_note_rounded, size: 16, color: _rose),
                        const SizedBox(width: 6),
                        Text(
                          todayLog != null &&
                                  (todayLog.flow.isNotEmpty || todayLog.symptoms.isNotEmpty)
                              ? 'Edit today\'s log  ·  ${_capitalize(todayLog.flow.isNotEmpty ? todayLog.flow : '')}${todayLog.symptoms.isNotEmpty ? (todayLog.flow.isNotEmpty ? '  ' : '') + '${todayLog.symptoms.length} symptom${todayLog.symptoms.length == 1 ? '' : 's'}' : ''}'
                              : 'Log symptoms & flow for today',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _rose),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Today symptom chips ───────────────────────────────────────
                if (todayLog != null && todayLog.symptoms.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: todayLog.symptoms.map((s) {
                        final icon = _kSymptoms
                            .firstWhere((e) => e.$1 == s, orElse: () => (s, Icons.circle))
                            .$2;
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding:
                              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                              color: _rose.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20)),
                          child: Row(
                            children: [
                              Icon(icon, size: 12, color: _rose),
                              const SizedBox(width: 4),
                              Text(_capitalize(s),
                                  style: TextStyle(fontSize: 11, color: _rose)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],

                if (_cycles.isNotEmpty) ...[
                  const SizedBox(height: 24),

                  // ── Stats ─────────────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Avg cycle',
                          value: '$_avgCycleLength days',
                          icon: Icons.loop_rounded,
                          isDark: isDark, card: card,
                          textPrimary: textPrimary, textSecondary: textSecondary,
                          accent: _rose,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'Avg duration',
                          value: '$_avgPeriodDuration days',
                          icon: Icons.calendar_today_rounded,
                          isDark: isDark, card: card,
                          textPrimary: textPrimary, textSecondary: textSecondary,
                          accent: _roseDim,
                        ),
                      ),
                    ],
                  ),

                  if (_ovulationDate != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Ovulation est.',
                            value: _formatShort(_ovulationDate!),
                            icon: Icons.brightness_5_rounded,
                            isDark: isDark, card: card,
                            textPrimary: textPrimary, textSecondary: textSecondary,
                            accent: _lavender,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            label: 'Fertile window',
                            value: '${_formatShort(_fertileStart!)} – ${_formatShort(_fertileEnd!)}',
                            icon: Icons.eco_rounded,
                            isDark: isDark, card: card,
                            textPrimary: textPrimary, textSecondary: textSecondary,
                            accent: _teal,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 12),

                  _SymptomSummary(
                    cycles: _cycles,
                    isDark: isDark, card: card,
                    textPrimary: textPrimary, textSecondary: textSecondary,
                  ),

                  const SizedBox(height: 28),

                  Text('History',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary)),
                  const SizedBox(height: 12),

                  for (int i = 0; i < _cycles.length; i++)
                    _CycleRow(
                      cycle: _cycles[i],
                      isDark: isDark, card: card,
                      textPrimary: textPrimary, textSecondary: textSecondary,
                      formatDate: _formatDate,
                      onDelete: () => _deleteCycle(i),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Cycle Wheel ─────────────────────────────────────────────────────────────

class _CycleWheel extends StatelessWidget {
  final int cycleLength;
  final int periodDays;
  final int currentDay;
  final String currentPhase;
  final Color phaseColor;
  final bool isDark;
  final Color textPrimary, textSecondary;
  final bool hasCycles;
  final int? daysUntilNext;
  final DateTime? nextPeriodDate;
  final bool isOnPeriod;
  final DateTime? currentStart;
  final String Function(DateTime) formatDate;

  const _CycleWheel({
    required this.cycleLength,
    required this.periodDays,
    required this.currentDay,
    required this.currentPhase,
    required this.phaseColor,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.hasCycles,
    required this.daysUntilNext,
    required this.nextPeriodDate,
    required this.isOnPeriod,
    required this.currentStart,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size.width - 48;
    final wheelSize = size.clamp(260.0, 320.0);

    return SizedBox(
      width: wheelSize,
      height: wheelSize,
      child: CustomPaint(
        painter: _WheelPainter(
          cycleLength: cycleLength,
          periodDays: periodDays,
          currentDay: currentDay,
          isDark: isDark,
          hasCycles: hasCycles,
        ),
        child: Center(
          child: _WheelCenter(
            currentDay: currentDay,
            currentPhase: currentPhase,
            phaseColor: phaseColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            hasCycles: hasCycles,
            daysUntilNext: daysUntilNext,
            nextPeriodDate: nextPeriodDate,
            isOnPeriod: isOnPeriod,
            currentStart: currentStart,
            formatDate: formatDate,
          ),
        ),
      ),
    );
  }
}

class _WheelCenter extends StatelessWidget {
  final int currentDay;
  final String currentPhase;
  final Color phaseColor, textPrimary, textSecondary;
  final bool hasCycles, isOnPeriod;
  final int? daysUntilNext;
  final DateTime? nextPeriodDate;
  final DateTime? currentStart;
  final String Function(DateTime) formatDate;

  const _WheelCenter({
    required this.currentDay,
    required this.currentPhase,
    required this.phaseColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.hasCycles,
    required this.isOnPeriod,
    required this.daysUntilNext,
    required this.nextPeriodDate,
    required this.currentStart,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasCycles) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_rounded, color: _rose, size: 28),
          const SizedBox(height: 8),
          Text('Track your', style: TextStyle(fontSize: 13, color: _rose)),
          Text('cycle', style: TextStyle(fontSize: 13, color: _rose)),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (currentDay > 0) ...[
          Text(
            'Day $currentDay',
            style: TextStyle(
                fontSize: 32, fontWeight: FontWeight.w800, color: phaseColor, height: 1),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: phaseColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(currentPhase,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: phaseColor)),
          ),
          const SizedBox(height: 8),
          if (isOnPeriod && currentStart != null)
            Text('Started ${formatDate(currentStart!)}',
                style: TextStyle(fontSize: 10, color: textSecondary))
          else if (daysUntilNext != null)
            Text(
              daysUntilNext! <= 0
                  ? 'Period starting'
                  : 'Next in ${daysUntilNext}d',
              style: TextStyle(fontSize: 11, color: textSecondary),
            ),
        ],
      ],
    );
  }
}

class _WheelPainter extends CustomPainter {
  final int cycleLength;
  final int periodDays;
  final int currentDay;
  final bool isDark;
  final bool hasCycles;

  _WheelPainter({
    required this.cycleLength,
    required this.periodDays,
    required this.currentDay,
    required this.isDark,
    required this.hasCycles,
  });

  Color _colorForDay(int day) {
    final ovDay = cycleLength - 14;
    if (day <= periodDays) return _rose;
    if (day < ovDay) return _teal;
    if (day <= ovDay + 1) return _lavender;
    return _roseDim;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerR = size.width * 0.46;
    final arcR = size.width * 0.355;
    final dotR = size.width * 0.435;

    // Background track ring
    canvas.drawCircle(
      center,
      arcR,
      Paint()
        ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.05)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.075,
    );

    if (!hasCycles) {
      // Ghost ring for first-time state
      canvas.drawCircle(
        center,
        arcR,
        Paint()
          ..color = _rose.withOpacity(0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.075,
      );
      return;
    }

    final arcWidth = size.width * 0.075;
    final gapAngle = 0.012; // radians gap between day arcs
    final fullSlice = 2 * math.pi / cycleLength;
    final drawSlice = fullSlice - gapAngle;

    // Draw phase arc segments
    for (int day = 1; day <= cycleLength; day++) {
      final color = _colorForDay(day);
      final startAngle = -math.pi / 2 + (day - 1) * fullSlice + gapAngle / 2;
      final isActive = day <= currentDay;
      final opacity = hasCycles ? (isActive ? 0.95 : 0.22) : 0.18;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: arcR),
        startAngle,
        drawSlice,
        false,
        Paint()
          ..color = color.withOpacity(opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = arcWidth
          ..strokeCap = StrokeCap.butt,
      );
    }

    // Draw day number dots
    for (int day = 1; day <= cycleLength; day++) {
      final angle = -math.pi / 2 + (day - 1) * fullSlice + fullSlice / 2;
      final dx = center.dx + dotR * math.cos(angle);
      final dy = center.dy + dotR * math.sin(angle);
      final pos = Offset(dx, dy);
      final color = _colorForDay(day);
      final isToday = day == currentDay;

      final bubbleR = isToday ? 13.0 : (day % 7 == 1 ? 10.0 : 9.0);

      // Bubble background
      canvas.drawCircle(
        pos,
        bubbleR,
        Paint()
          ..color = isToday
              ? color
              : (isDark ? const Color(0xFF2C2C2C) : Colors.white),
      );

      // Bubble border for today
      if (isToday) {
        canvas.drawCircle(
          pos,
          bubbleR + 2.5,
          Paint()
            ..color = color.withOpacity(0.4)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }

      // Day number text
      final tp = TextPainter(
        text: TextSpan(
          text: '$day',
          style: TextStyle(
            color: isToday ? Colors.white : color.withOpacity(day <= currentDay ? 0.9 : 0.45),
            fontSize: isToday ? 9.5 : 8.0,
            fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }

    // Ovulation marker (small triangle/dot at the ovulation day)
    final ovDay = cycleLength - 14;
    final ovAngle = -math.pi / 2 + (ovDay - 1) * fullSlice + fullSlice / 2;
    final markerR = outerR - 4;
    final mx = center.dx + markerR * math.cos(ovAngle);
    final my = center.dy + markerR * math.sin(ovAngle);
    canvas.drawCircle(
      Offset(mx, my),
      4,
      Paint()..color = _lavender.withOpacity(0.9),
    );
  }

  @override
  bool shouldRepaint(_WheelPainter old) =>
      old.cycleLength != cycleLength ||
      old.currentDay != currentDay ||
      old.isDark != isDark ||
      old.hasCycles != hasCycles;
}

// ─── Phase Legend Chip ────────────────────────────────────────────────────────

class _PhaseLegendChip extends StatelessWidget {
  final String label;
  final Color color;
  const _PhaseLegendChip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// ─── Symptom Summary ──────────────────────────────────────────────────────────

class _SymptomSummary extends StatelessWidget {
  final List<_Cycle> cycles;
  final bool isDark;
  final Color card, textPrimary, textSecondary;

  const _SymptomSummary({
    required this.cycles,
    required this.isDark,
    required this.card,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final freq = <String, int>{};
    for (final c in cycles) {
      for (final s in c.symptoms) freq[s] = (freq[s] ?? 0) + 1;
    }
    if (freq.isEmpty) return const SizedBox.shrink();
    final top = (freq.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).take(5);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Common symptoms',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
          const SizedBox(height: 12),
          ...top.map((e) {
            final pct = e.value / cycles.length;
            final icon = _kSymptoms
                .firstWhere((s) => s.$1 == e.key, orElse: () => (e.key, Icons.circle))
                .$2;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(icon, size: 14, color: _rose),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 90,
                    child: Text(e.key[0].toUpperCase() + e.key.substring(1),
                        style: TextStyle(fontSize: 12, color: textPrimary)),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 6,
                        backgroundColor: _rose.withOpacity(0.1),
                        valueColor: const AlwaysStoppedAnimation(_rose),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${e.value}/${cycles.length}',
                      style: TextStyle(fontSize: 11, color: textSecondary)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final bool isDark;
  final Color card, textPrimary, textSecondary, accent;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.isDark,
    required this.card,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
                color: accent.withOpacity(0.12), borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, size: 16, color: accent),
          ),
          const SizedBox(height: 12),
          Text(value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 12, color: textSecondary)),
        ],
      ),
    );
  }
}

// ─── Cycle Row ────────────────────────────────────────────────────────────────

class _CycleRow extends StatelessWidget {
  final _Cycle cycle;
  final bool isDark;
  final Color card, textPrimary, textSecondary;
  final String Function(DateTime) formatDate;
  final VoidCallback onDelete;

  const _CycleRow({
    required this.cycle,
    required this.isDark,
    required this.card,
    required this.textPrimary,
    required this.textSecondary,
    required this.formatDate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: _rose.withOpacity(0.12), shape: BoxShape.circle),
                child: const Icon(Icons.favorite_rounded, size: 16, color: _rose),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${formatDate(cycle.start)} – ${formatDate(cycle.end)}',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
                    const SizedBox(height: 2),
                    Text('${cycle.durationDays} day${cycle.durationDays == 1 ? '' : 's'}',
                        style: TextStyle(fontSize: 12, color: textSecondary)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onDelete,
                child: Icon(Icons.delete_outline_rounded, size: 18, color: textSecondary),
              ),
            ],
          ),
          if (cycle.symptoms.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: cycle.symptoms.take(5).map((s) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: _rose.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                child: Text(s[0].toUpperCase() + s.substring(1),
                    style: TextStyle(fontSize: 10, color: _rose.withOpacity(0.8))),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
