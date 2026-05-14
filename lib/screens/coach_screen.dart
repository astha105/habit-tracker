import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'package:habit_tracker/services/firestore_service.dart';
import 'package:habit_tracker/services/jarvis_service.dart';

const _kBg      = Color(0xFF0D0D0F);
const _kCard    = Color(0xFF181820);
const _kBorder  = Color(0xFF2A2A3A);
const _kText    = Color(0xFFF2F2F2);
const _kSubtext = Color(0xFF888899);
const _kMuted   = Color(0xFF3A3A4A);
const _kLime    = Color(0xFFCCFF00);
const _kPurple  = Color(0xFF9B6DFF);
const _kPurple2 = Color(0xFF5B4AE8);


class CoachScreen extends StatefulWidget {
  const CoachScreen({super.key});

  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen>
    with SingleTickerProviderStateMixin {
  // ── Chat state ─────────────────────────────────────────────────────────────
  final List<Map<String, String>> _messages = [];
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  bool _sending = false;
  String _habitContext = '';

  // ── STT ────────────────────────────────────────────────────────────────────
  final SpeechToText _stt = SpeechToText();
  bool _sttReady = false;
  bool _listening = false;
  String _partial = '';

  // ── TTS ────────────────────────────────────────────────────────────────────
  final FlutterTts _tts = FlutterTts();
  bool _speaking = false;

  // ── Animation ──────────────────────────────────────────────────────────────
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _initSTT();
    _initTTS();
    _loadHabits();
  }

  Future<void> _initSTT() async {
    _sttReady = await _stt.initialize(
      onError: (e) {
        debugPrint('STT error: $e');
        if (!mounted) return;
        setState(() { _listening = false; _partial = ''; });
        if (e.errorMsg == 'error_no_match' || e.errorMsg == 'error_speech_timeout') {
          _showSnack("Didn't catch that — try again");
        }
      },
      onStatus: (s) {
        if (!mounted) return;
        if (s == 'done' || s == 'notListening') {
          if (_listening) {
            final text = _partial.trim();
            setState(() { _listening = false; _partial = ''; });
            if (text.isNotEmpty) _send(text);
          }
        }
      },
    );
    if (mounted) setState(() {});
  }

  Future<void> _initTTS() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.48);
    await _tts.setPitch(1.0);
    _tts.setStartHandler(() { if (mounted) setState(() => _speaking = true); });
    _tts.setCompletionHandler(() { if (mounted) setState(() => _speaking = false); });
    _tts.setErrorHandler((_) { if (mounted) setState(() => _speaking = false); });
  }

  Future<void> _loadHabits() async {
    try {
      final habits = await FirestoreService().loadHabits();
      if (!mounted) return;
      final today = DateTime.now();
      _habitContext = habits.map((h) {
        final doneToday = h.completionHistory.any(
          (d) => d.year == today.year && d.month == today.month && d.day == today.day,
        );
        return '• ${h.title} — streak: ${h.currentStreak}d, today: ${doneToday ? "done" : "pending"}';
      }).join('\n');
    } catch (_) {}
  }

  // ── Mic tap: toggle listen ─────────────────────────────────────────────────
  Future<void> _toggleMic() async {
    if (_sending || _speaking) return;

    if (_listening) {
      final text = _partial.trim();
      await _stt.stop();
      setState(() { _listening = false; _partial = ''; });
      if (text.isNotEmpty) _send(text);
      return;
    }

    if (!_sttReady) {
      _showSnack('Microphone not available');
      return;
    }

    setState(() { _listening = true; _partial = ''; });
    await _tts.stop();
    await _stt.listen(
      onResult: (SpeechRecognitionResult r) {
        if (mounted) setState(() => _partial = r.recognizedWords);
      },
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(seconds: 2),
      listenOptions: SpeechListenOptions(partialResults: true, cancelOnError: false),
    );
  }

  // ── Send a message ─────────────────────────────────────────────────────────
  Future<void> _send([String? override]) async {
    final text = (override ?? _inputCtrl.text).trim();
    if (text.isEmpty || _sending) return;

    if (_listening) {
      await _stt.stop();
      setState(() { _listening = false; _partial = ''; });
    }
    _inputCtrl.clear();

    final history = List<Map<String, String>>.from(_messages);
    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _sending = true;
      _messages.add({'role': 'assistant', 'content': ''});
    });
    _scrollToBottom();

    final replyIdx = _messages.length - 1;
    final buf = StringBuffer();

    try {
      await for (final chunk in JarvisService.chatStream(
        messages: [
          ...history,
          {'role': 'user', 'content': text},
        ],
        habitContext: _habitContext,
      )) {
        if (!mounted) return;
        buf.write(chunk);
        setState(() {
          _messages[replyIdx] = {'role': 'assistant', 'content': buf.toString()};
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Chat error: $e');
    }

    if (!mounted) return;
    final reply = buf.toString();
    setState(() {
      _sending = false;
      if (reply.isEmpty) {
        _messages[replyIdx] = {
          'role': 'assistant',
          'content': "Sorry, I couldn't respond. Check your connection.",
        };
      }
    });
    _scrollToBottom();

    if (reply.isNotEmpty) {
      await _tts.speak(reply);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _stt.stop();
    _tts.stop();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(child: _buildChat()),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _kBorder, width: 0.5)),
      ),
      child: Row(
        children: [
          _CircleBtn(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: Column(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [_kPurple, Color(0xFFBFA0FF)],
                  ).createShader(bounds),
                  child: const Text(
                    'AI Coach',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _sending ? _kLime : const Color(0xFF4ADE80),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _sending ? 'Thinking…' : 'Online',
                      style: const TextStyle(color: _kSubtext, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _CircleBtn(
            icon: _speaking ? Icons.volume_up_rounded : Icons.volume_off_rounded,
            iconColor: _speaking ? _kLime : _kSubtext,
            onTap: () async {
              if (_speaking) {
                await _tts.stop();
                setState(() => _speaking = false);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChat() {
    if (_messages.isEmpty) return _buildWelcome();
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      itemCount: _messages.length,
      itemBuilder: (_, i) {
        final msg = _messages[i];
        final isUser = msg['role'] == 'user';
        final content = msg['content'] ?? '';
        if (!isUser && content.isEmpty) return const _TypingDots();
        return _Bubble(text: content, isUser: isUser);
      },
    );
  }

  Widget _buildWelcome() {
    const suggestions = [
      (icon: Icons.repeat_rounded,         label: 'How do I stay consistent?'),
      (icon: Icons.whatshot_rounded,        label: 'Why do I keep breaking my streak?'),
      (icon: Icons.bolt_rounded,            label: 'Motivate me right now!'),
      (icon: Icons.track_changes_rounded,   label: 'What habit should I focus on?'),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Hero avatar
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_kPurple, _kPurple2],
              ),
              boxShadow: [
                BoxShadow(
                  color: _kPurple.withValues(alpha: 0.35),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.auto_awesome_rounded, size: 32, color: Colors.white),
          ),
          const SizedBox(height: 20),
          const Text(
            'Your personal habit coach.\nAsk me anything.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _kSubtext,
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 36),
          ...suggestions.map((q) => _SuggestionTile(
            icon: q.icon,
            label: q.label,
            onTap: () => _send(q.label),
          )),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    final isActive = _listening || _speaking;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: _kBg,
        border: Border(
          top: BorderSide(
            color: isActive ? _kPurple.withValues(alpha: 0.4) : _kBorder,
            width: isActive ? 1.0 : 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputCtrl,
              enabled: !_sending && !_listening,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(fontSize: 14, color: _kText),
              decoration: InputDecoration(
                hintText: _listening
                    ? (_partial.isEmpty ? 'Listening…' : _partial)
                    : 'Type or tap mic…',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: _listening ? _kText : _kMuted,
                  fontStyle: _listening && _partial.isEmpty
                      ? FontStyle.italic
                      : FontStyle.normal,
                ),
                filled: true,
                fillColor: _kCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide(color: isActive ? _kLime : _kBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide(color: isActive ? _kLime : _kBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: const BorderSide(color: _kPurple, width: 1.5),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 10),
          // Mic / Send button
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, child) {
              final scale = _listening ? 1.0 + 0.08 * _pulseCtrl.value : 1.0;
              return Transform.scale(scale: scale, child: child);
            },
            child: GestureDetector(
              onTap: () {
                if (_inputCtrl.text.trim().isNotEmpty) {
                  _send();
                } else {
                  _toggleMic();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _listening
                      ? Colors.redAccent
                      : _sending
                          ? _kLime.withValues(alpha: 0.4)
                          : _kLime,
                ),
                child: Icon(
                  _listening
                      ? Icons.stop_rounded
                      : _inputCtrl.text.trim().isNotEmpty
                          ? Icons.arrow_upward_rounded
                          : Icons.mic_rounded,
                  color: _listening ? Colors.white : Colors.black,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _Bubble extends StatelessWidget {
  final String text;
  final bool isUser;
  const _Bubble({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            _Avatar(),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                gradient: isUser
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF3D2880), Color(0xFF251A5C)],
                      )
                    : null,
                color: isUser ? null : _kCard,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: isUser
                    ? Border.all(color: _kPurple.withValues(alpha: 0.3))
                    : Border.all(color: _kBorder),
              ),
              child: Text(
                text,
                style: const TextStyle(fontSize: 14, color: _kText, height: 1.55),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kPurple, _kPurple2],
        ),
      ),
      child: const Icon(Icons.auto_awesome_rounded, size: 14, color: Colors.white),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          _Avatar(),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _kCard,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(color: _kBorder),
            ),
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, _) => Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  final v = (_ctrl.value - i * 0.2).clamp(0.0, 1.0);
                  return Padding(
                    padding: EdgeInsets.only(right: i < 2 ? 4 : 0),
                    child: Opacity(
                      opacity: 0.25 + 0.75 * math.sin(v * math.pi),
                      child: Container(
                        width: 6, height: 6,
                        decoration: const BoxDecoration(
                          color: _kPurple, shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SuggestionTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kPurple.withValues(alpha: 0.15),
              ),
              child: Icon(icon, color: _kPurple, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: const TextStyle(color: _kText, fontSize: 13.5, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            const Icon(Icons.north_east_rounded, color: _kSubtext, size: 15),
          ],
        ),
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;

  const _CircleBtn({
    required this.icon,
    this.iconColor = _kSubtext,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _kCard,
          border: Border.all(color: _kBorder),
        ),
        child: Icon(icon, size: 17, color: iconColor),
      ),
    );
  }
}
