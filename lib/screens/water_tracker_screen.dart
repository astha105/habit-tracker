// ignore_for_file: deprecated_member_use

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:habit_tracker/theme/theme_controller.dart';
import 'package:habit_tracker/services/notification_service.dart';

class WaterTrackerScreen extends StatefulWidget {
  const WaterTrackerScreen({super.key});

  @override
  State<WaterTrackerScreen> createState() => _WaterTrackerScreenState();
}

class _WaterTrackerScreenState extends State<WaterTrackerScreen>
    with SingleTickerProviderStateMixin {
  static const int _goalMl = 2000;
  static const int _stepMl = 250;
  static const Color _water = Color(0xFF4FC3F7);

  int _todayMl = 0;
  List<_Entry> _log = [];
  late AnimationController _waveCtrl;

  // Reminder settings
  bool _remindersEnabled = false;
  int _reminderStartHour = 8;
  int _reminderEndHour = 21;
  int _reminderIntervalHours = 2;

  String get _todayKey {
    final now = DateTime.now();
    return 'water_${now.year}_${now.month}_${now.day}';
  }

  String get _logKey {
    final now = DateTime.now();
    return 'water_log_${now.year}_${now.month}_${now.day}';
  }

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _load();
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final ml = prefs.getInt(_todayKey) ?? 0;
    final raw = prefs.getStringList(_logKey) ?? [];
    final entries = raw.map((s) {
      final parts = s.split('|');
      return _Entry(
        time: DateTime.fromMillisecondsSinceEpoch(int.parse(parts[0])),
        ml: int.parse(parts[1]),
      );
    }).toList();
    final enabled = prefs.getBool('water_reminders_enabled') ?? false;
    final start = prefs.getInt('water_reminder_start') ?? 8;
    final end = prefs.getInt('water_reminder_end') ?? 21;
    final interval = prefs.getInt('water_reminder_interval') ?? 2;
    if (mounted) {
      setState(() {
        _todayMl = ml;
        _log = entries;
        _remindersEnabled = enabled;
        _reminderStartHour = start;
        _reminderEndHour = end;
        _reminderIntervalHours = interval;
      });
    }
  }

  Future<void> _saveReminderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('water_reminders_enabled', _remindersEnabled);
    await prefs.setInt('water_reminder_start', _reminderStartHour);
    await prefs.setInt('water_reminder_end', _reminderEndHour);
    await prefs.setInt('water_reminder_interval', _reminderIntervalHours);
    if (_remindersEnabled) {
      await NotificationService.scheduleWaterReminders(
        startHour: _reminderStartHour,
        endHour: _reminderEndHour,
        intervalHours: _reminderIntervalHours,
      );
    } else {
      await NotificationService.cancelWaterReminders();
    }
  }

  String _hourLabel(int h) {
    if (h == 0) return '12 AM';
    if (h == 12) return '12 PM';
    return h < 12 ? '$h AM' : '${h - 12} PM';
  }

  Future<void> _add(int ml) async {
    final prefs = await SharedPreferences.getInstance();
    final newTotal = (_todayMl + ml).clamp(0, _goalMl * 3);
    final entry = _Entry(time: DateTime.now(), ml: ml);
    final newLog = [..._log, entry];
    await prefs.setInt(_todayKey, newTotal);
    await prefs.setStringList(_logKey,
        newLog.map((e) => '${e.time.millisecondsSinceEpoch}|${e.ml}').toList());
    setState(() { _todayMl = newTotal; _log = newLog; });
  }

  Future<void> _remove(int index) async {
    final entry = _log[index];
    final prefs = await SharedPreferences.getInstance();
    final newTotal = math.max(0, _todayMl - entry.ml);
    final newLog = [..._log]..removeAt(index);
    await prefs.setInt(_todayKey, newTotal);
    await prefs.setStringList(_logKey,
        newLog.map((e) => '${e.time.millisecondsSinceEpoch}|${e.ml}').toList());
    setState(() { _todayMl = newTotal; _log = newLog; });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance,
      builder: (context, themeMode, _) {
        final isDark = themeMode == ThemeMode.dark ||
            (themeMode == ThemeMode.system &&
                MediaQuery.of(context).platformBrightness == Brightness.dark);
        final bg = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF5F5F2);
        final card = isDark ? const Color(0xFF1A1A1A) : Colors.white;
        final textPrimary = isDark ? Colors.white : const Color(0xFF0D0D0D);
        final textSecondary = isDark ? const Color(0xFF8A8AA0) : const Color(0xFF6B6B80);

        final progress = (_todayMl / _goalMl).clamp(0.0, 1.0);
        final glasses = (_todayMl / _stepMl).floor();
        final goalGlasses = _goalMl ~/ _stepMl;

        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            backgroundColor: bg,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text('Water Tracker',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: textPrimary)),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress circle
                Center(
                  child: SizedBox(
                    width: 200,
                    height: 200,
                    child: AnimatedBuilder(
                      animation: _waveCtrl,
                      builder: (context2, snap) => CustomPaint(
                        painter: _WavePainter(
                          progress: progress,
                          animValue: _waveCtrl.value,
                          isDark: isDark,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${_todayMl}ml',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                  letterSpacing: -1,
                                ),
                              ),
                              Text(
                                'of ${_goalMl}ml',
                                style: TextStyle(fontSize: 13, color: textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),
                Center(
                  child: Text(
                    '$glasses / $goalGlasses glasses',
                    style: TextStyle(fontSize: 14, color: textSecondary, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    progress >= 1.0 ? '🎉 Daily goal reached!' : '${(progress * 100).toInt()}% of daily goal',
                    style: TextStyle(
                      fontSize: 13,
                      color: progress >= 1.0 ? const Color(0xFF4CAF50) : textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Quick add buttons
                Text('Add water',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    for (final item in const [
                      (150, 'Small\nsip', '☕'),
                      (250, 'Glass', '🥛'),
                      (350, 'Large\nglass', '🫗'),
                      (500, 'Bottle', '🍶'),
                    ])
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => _add(item.$1),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: card,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _water.withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(item.$3, style: const TextStyle(fontSize: 20)),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.$2,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: textPrimary,
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 28),

                if (_log.isNotEmpty) ...[
                  Text("Today's log",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary)),
                  const SizedBox(height: 12),
                  for (int i = _log.length - 1; i >= 0; i--)
                    _LogRow(
                      entry: _log[i],
                      isDark: isDark,
                      card: card,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      onDelete: () => _remove(i),
                    ),
                ],

                const SizedBox(height: 28),

                // ── Reminders ─────────────────────────────────────────────────
                Text('Reminders',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary)),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      // Toggle row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: _water.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: const Icon(Icons.notifications_outlined, size: 16, color: Color(0xFF4FC3F7)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text('Drink water reminders',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
                            ),
                            Switch(
                              value: _remindersEnabled,
                              activeColor: _water,
                              onChanged: (v) async {
                                setState(() => _remindersEnabled = v);
                                await _saveReminderSettings();
                              },
                            ),
                          ],
                        ),
                      ),

                      if (_remindersEnabled) ...[
                        Divider(height: 1, color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE)),

                        // Start hour
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text('Start time',
                                    style: TextStyle(fontSize: 13, color: textSecondary)),
                              ),
                              DropdownButton<int>(
                                value: _reminderStartHour,
                                dropdownColor: card,
                                underline: const SizedBox(),
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
                                items: [for (int h = 6; h <= 12; h++)
                                  DropdownMenuItem(value: h, child: Text(_hourLabel(h)))],
                                onChanged: (v) async {
                                  if (v == null) return;
                                  setState(() => _reminderStartHour = v);
                                  await _saveReminderSettings();
                                },
                              ),
                            ],
                          ),
                        ),

                        Divider(height: 1, color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE)),

                        // End hour
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text('End time',
                                    style: TextStyle(fontSize: 13, color: textSecondary)),
                              ),
                              DropdownButton<int>(
                                value: _reminderEndHour,
                                dropdownColor: card,
                                underline: const SizedBox(),
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
                                items: [for (int h = 18; h <= 23; h++)
                                  DropdownMenuItem(value: h, child: Text(_hourLabel(h)))],
                                onChanged: (v) async {
                                  if (v == null) return;
                                  setState(() => _reminderEndHour = v);
                                  await _saveReminderSettings();
                                },
                              ),
                            ],
                          ),
                        ),

                        Divider(height: 1, color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE)),

                        // Interval
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text('Remind every',
                                    style: TextStyle(fontSize: 13, color: textSecondary)),
                              ),
                              DropdownButton<int>(
                                value: _reminderIntervalHours,
                                dropdownColor: card,
                                underline: const SizedBox(),
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
                                items: const [
                                  DropdownMenuItem(value: 1, child: Text('1 hour')),
                                  DropdownMenuItem(value: 2, child: Text('2 hours')),
                                  DropdownMenuItem(value: 3, child: Text('3 hours')),
                                ],
                                onChanged: (v) async {
                                  if (v == null) return;
                                  setState(() => _reminderIntervalHours = v);
                                  await _saveReminderSettings();
                                },
                              ),
                            ],
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                          child: Text(
                            'You\'ll be notified every $_reminderIntervalHours hour${_reminderIntervalHours > 1 ? 's' : ''} from ${_hourLabel(_reminderStartHour)} to ${_hourLabel(_reminderEndHour)}',
                            style: TextStyle(fontSize: 11, color: textSecondary, height: 1.4),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Entry {
  final DateTime time;
  final int ml;
  const _Entry({required this.time, required this.ml});
}

class _LogRow extends StatelessWidget {
  final _Entry entry;
  final bool isDark;
  final Color card, textPrimary, textSecondary;
  final VoidCallback onDelete;

  const _LogRow({
    required this.entry,
    required this.isDark,
    required this.card,
    required this.textPrimary,
    required this.textSecondary,
    required this.onDelete,
  });

  static String _labelFor(int ml) {
    if (ml <= 150) return '☕ Small sip';
    if (ml <= 250) return '🥛 Glass';
    if (ml <= 350) return '🫗 Large glass';
    return '🍶 Bottle';
  }

  @override
  Widget build(BuildContext context) {
    final h = entry.time.hour.toString().padLeft(2, '0');
    final m = entry.time.minute.toString().padLeft(2, '0');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          const SizedBox(width: 4),
          Expanded(
            child: Text(_labelFor(entry.ml),
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
          ),
          Text('$h:$m',
              style: TextStyle(fontSize: 12, color: textSecondary)),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onDelete,
            child: Icon(Icons.close_rounded, size: 16, color: textSecondary),
          ),
        ],
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double progress;
  final double animValue;
  final bool isDark;

  const _WavePainter({
    required this.progress,
    required this.animValue,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Background circle
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFE8F4FD),
    );

    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: radius)));

    // Fill level
    final fillHeight = size.height * (1 - progress);

    // Wave
    final wavePath = Path();
    wavePath.moveTo(0, fillHeight);
    for (double x = 0; x <= size.width; x++) {
      final y = fillHeight +
          math.sin((x / size.width * 2 * math.pi) + (animValue * 2 * math.pi)) * 6 +
          math.sin((x / size.width * 4 * math.pi) + (animValue * 2 * math.pi * 1.3)) * 3;
      wavePath.lineTo(x, y);
    }
    wavePath.lineTo(size.width, size.height);
    wavePath.lineTo(0, size.height);
    wavePath.close();

    canvas.drawPath(
      wavePath,
      Paint()..color = const Color(0xFF4FC3F7).withOpacity(0.7),
    );

    // Second wave slightly offset
    final wavePath2 = Path();
    wavePath2.moveTo(0, fillHeight);
    for (double x = 0; x <= size.width; x++) {
      final y = fillHeight +
          math.sin((x / size.width * 2 * math.pi) + (animValue * 2 * math.pi) + 1) * 5 +
          math.sin((x / size.width * 3 * math.pi) + (animValue * 2 * math.pi * 0.8)) * 4;
      wavePath2.lineTo(x, y);
    }
    wavePath2.lineTo(size.width, size.height);
    wavePath2.lineTo(0, size.height);
    wavePath2.close();

    canvas.drawPath(
      wavePath2,
      Paint()..color = const Color(0xFF0288D1).withOpacity(0.4),
    );

    canvas.restore();

    // Border
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFF4FC3F7).withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_WavePainter old) =>
      old.progress != progress || old.animValue != animValue;
}
