// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:habit_tracker/services/firestore_service.dart';
import 'package:habit_tracker/services/jarvis_service.dart';
import 'package:habit_tracker/theme/app_colors.dart';

const Color _kLime = Color(0xFFC5FF47);
const Color _kJarvisBlue = Color(0xFF4DA6FF);
const Color _kRed = Color(0xFFFF6B6B);

class CoachScreen extends StatefulWidget {
  const CoachScreen({super.key});

  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen>
    with SingleTickerProviderStateMixin {
  final List<Map<String, String>> _messages = [];
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  bool _sending = false;
  bool _serverOnline = false;
  bool _serverChecked = false;

  // ── Voice ──────────────────────────────────────────────────────────────────
  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _sttAvailable = false;

  // Voice mode states
  bool _voiceMode = false;   // true = always-listening conversational mode
  bool _listening = false;   // currently capturing mic input
  bool _speaking = false;    // Jarvis is currently speaking
  bool _ttsEnabled = true;
  String _partialText = ''; // live transcript while speaking

  String _habitContext = '';

  // Pulse animation for the orb
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _initVoice();
    _checkServer();
  }

  // ── Init ───────────────────────────────────────────────────────────────────
  Future<void> _initVoice() async {
    _sttAvailable = await _stt.initialize(
      onError: (e) {
        debugPrint('STT error: $e');
        if (mounted) setState(() => _listening = false);
        // retry listening after error if still in voice mode
        if (_voiceMode && !_sending && !_speaking) {
          Future.delayed(const Duration(milliseconds: 500), _startListening);
        }
      },
      onStatus: (s) {
        debugPrint('STT status: $s');
        if ((s == 'done' || s == 'notListening') && mounted) {
          setState(() => _listening = false);
          // auto-restart if in voice mode and Jarvis isn't speaking/sending
          if (_voiceMode && !_sending && !_speaking) {
            Future.delayed(const Duration(milliseconds: 300), _startListening);
          }
        }
      },
    );

    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.48);
    await _tts.setPitch(1.0);
    await _tts.awaitSpeakCompletion(true);

    _tts.setStartHandler(() {
      if (mounted) setState(() => _speaking = true);
    });
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _speaking = false);
      // resume listening after Jarvis finishes talking
      if (mounted && _voiceMode && !_sending) {
        Future.delayed(const Duration(milliseconds: 400), _startListening);
      }
    });
    _tts.setCancelHandler(() {
      if (mounted) setState(() => _speaking = false);
    });

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _tts.setSharedInstance(true);
      await _tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
          IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
        ],
        IosTextToSpeechAudioMode.defaultMode,
      );
    }

    if (mounted) setState(() {});
  }

  Future<void> _checkServer() async {
    final health = await JarvisService.health();
    if (!mounted) return;
    setState(() {
      _serverOnline = health != null;
      _serverChecked = true;
    });
    if (_serverOnline) await _loadHabits();
  }

  Future<void> _loadHabits() async {
    try {
      final habits = await FirestoreService().loadHabits();
      if (!mounted) return;
      final today = DateTime.now();
      _habitContext = habits.map((h) {
        final doneToday = h.completionHistory.any(
          (d) =>
              d.year == today.year &&
              d.month == today.month &&
              d.day == today.day,
        );
        return '• ${h.title} — streak: ${h.currentStreak}d, today: ${doneToday ? "done" : "pending"}';
      }).join('\n');
    } catch (_) {}
  }

  // ── Voice mode ─────────────────────────────────────────────────────────────
  Future<void> _enterVoiceMode() async {
    if (!_sttAvailable) return;
    setState(() => _voiceMode = true);
    await _tts.stop();
    await _startListening();
  }

  Future<void> _exitVoiceMode() async {
    setState(() {
      _voiceMode = false;
      _listening = false;
      _partialText = '';
    });
    await _stt.stop();
    await _tts.stop();
  }

  Future<void> _startListening() async {
    if (!_sttAvailable || !_voiceMode || _sending || _speaking || _listening) {
      return;
    }
    setState(() {
      _listening = true;
      _partialText = '';
    });
    await _stt.listen(
      onResult: (SpeechRecognitionResult result) {
        if (!mounted) return;
        setState(() => _partialText = result.recognizedWords);
        if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
          setState(() {
            _listening = false;
            _partialText = '';
          });
          _send(result.recognizedWords.trim());
        }
      },
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(seconds: 2),
      partialResults: true,
    );
  }

  // ── Send ───────────────────────────────────────────────────────────────────
  Future<void> _send([String? override]) async {
    final text = (override ?? _inputCtrl.text).trim();
    if (text.isEmpty || _sending) return;

    // stop listening while we send
    if (_listening) {
      await _stt.stop();
      setState(() => _listening = false);
    }

    _inputCtrl.clear();
    final history = List<Map<String, String>>.from(_messages);

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _sending = true;
      _messages.add({'role': 'assistant', 'content': ''});
    });
    _scrollToBottom();

    final messagesForApi = [...history, {'role': 'user', 'content': text}];
    final replyIndex = _messages.length - 1;
    final buffer = StringBuffer();
    bool gotAny = false;

    try {
      await for (final chunk in JarvisService.chatStream(
        messages: messagesForApi,
        habitContext: _habitContext,
      )) {
        if (!mounted) return;
        buffer.write(chunk);
        gotAny = true;
        setState(() {
          _messages[replyIndex] = {
            'role': 'assistant',
            'content': buffer.toString(),
          };
        });
        _scrollToBottom();
      }
    } catch (_) {}

    if (!mounted) return;

    final reply = buffer.toString();
    setState(() {
      _sending = false;
      if (!gotAny) {
        _messages[replyIndex] = {
          'role': 'assistant',
          'content': "I couldn't connect right now. Make sure the Jarvis server is running.",
        };
      }
    });
    _scrollToBottom();

    // Speak the reply — completion handler will restart listening
    if (_ttsEnabled && gotAny && reply.isNotEmpty) {
      await _tts.speak(reply);
    } else if (_voiceMode && !_sending) {
      // If TTS is off, restart listening immediately
      Future.delayed(const Duration(milliseconds: 300), _startListening);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.bg : AppColors.canvas;
    final bg2 = isDark ? AppColors.bg2 : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textPrimary : AppColors.ink;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg2,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textColor, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _JarvisAvatar(size: 28, isDark: isDark),
            const SizedBox(width: 8),
            Text(
              'Jarvis',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: textColor,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(width: 6),
            _ServerDot(online: _serverOnline, checked: _serverChecked),
          ],
        ),
        actions: [
          // TTS toggle
          IconButton(
            icon: Icon(
              _ttsEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              color: _ttsEnabled ? _kJarvisBlue : (isDark ? Colors.white24 : Colors.black26),
              size: 20,
            ),
            tooltip: _ttsEnabled ? 'Mute Jarvis' : 'Unmute Jarvis',
            onPressed: () async {
              setState(() => _ttsEnabled = !_ttsEnabled);
              if (!_ttsEnabled) await _tts.stop();
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: borderColor),
        ),
      ),
      body: !_serverChecked
          ? const Center(child: CircularProgressIndicator(strokeWidth: 1.5))
          : !_serverOnline
              ? _ServerOffline(isDark: isDark, onRetry: _checkServer)
              : Column(
                  children: [
                    Expanded(
                      child: _messages.isEmpty && !_voiceMode
                          ? _WelcomeState(
                              isDark: isDark,
                              onSuggest: _send,
                              sttAvailable: _sttAvailable,
                              onStartVoice: _enterVoiceMode,
                            )
                          : Stack(
                              children: [
                                ListView.builder(
                                  controller: _scrollCtrl,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 16),
                                  itemCount: _messages.length,
                                  itemBuilder: (_, i) {
                                    final msg = _messages[i];
                                    final isUser = msg['role'] == 'user';
                                    final content = msg['content'] ?? '';
                                    if (!isUser && content.isEmpty) {
                                      return _TypingIndicator(isDark: isDark);
                                    }
                                    return _Bubble(
                                      text: content,
                                      isUser: isUser,
                                      isDark: isDark,
                                    );
                                  },
                                ),
                                // Voice mode overlay orb
                                if (_voiceMode)
                                  Positioned(
                                    bottom: 16,
                                    left: 0,
                                    right: 0,
                                    child: _VoiceOrb(
                                      listening: _listening,
                                      speaking: _speaking,
                                      sending: _sending,
                                      partialText: _partialText,
                                      pulseAnim: _pulseAnim,
                                      onExit: _exitVoiceMode,
                                      isDark: isDark,
                                    ),
                                  ),
                              ],
                            ),
                    ),
                    // Show voice orb at bottom on welcome screen too
                    if (_voiceMode && _messages.isEmpty)
                      _VoiceOrb(
                        listening: _listening,
                        speaking: _speaking,
                        sending: _sending,
                        partialText: _partialText,
                        pulseAnim: _pulseAnim,
                        onExit: _exitVoiceMode,
                        isDark: isDark,
                      ),
                    if (!_voiceMode)
                      _InputBar(
                        controller: _inputCtrl,
                        sending: _sending,
                        isDark: isDark,
                        sttAvailable: _sttAvailable,
                        onSend: _send,
                        onStartVoice: _enterVoiceMode,
                      ),
                  ],
                ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Voice Orb — shown in conversational mode
// ─────────────────────────────────────────────────────────────────────────────
class _VoiceOrb extends StatelessWidget {
  final bool listening, speaking, sending;
  final String partialText;
  final Animation<double> pulseAnim;
  final VoidCallback onExit;
  final bool isDark;

  const _VoiceOrb({
    required this.listening,
    required this.speaking,
    required this.sending,
    required this.partialText,
    required this.pulseAnim,
    required this.onExit,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final Color orbColor;
    final String label;

    if (sending) {
      orbColor = _kJarvisBlue.withOpacity(0.5);
      label = 'Thinking…';
    } else if (speaking) {
      orbColor = _kJarvisBlue;
      label = 'Jarvis is speaking…';
    } else if (listening) {
      orbColor = const Color(0xFF34D399);
      label = partialText.isNotEmpty ? partialText : 'Listening…';
    } else {
      orbColor = _kJarvisBlue.withOpacity(0.3);
      label = 'Starting…';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Partial transcript
        if (partialText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
            child: Text(
              partialText,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.textSecondary : AppColors.ink2,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        // State label
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.textMuted : AppColors.ink3,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 12),
        // Pulsing orb
        AnimatedBuilder(
          animation: pulseAnim,
          builder: (_, child) {
            final scale = (listening && !sending && !speaking)
                ? pulseAnim.value
                : 1.0;
            return Transform.scale(
              scale: scale,
              child: child,
            );
          },
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: orbColor,
              boxShadow: [
                BoxShadow(
                  color: orbColor.withOpacity(0.45),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Icon(
              sending
                  ? Icons.hourglass_top_rounded
                  : speaking
                      ? Icons.graphic_eq_rounded
                      : Icons.mic_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Exit voice mode button
        GestureDetector(
          onTap: onExit,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.bg3 : const Color(0xFFF0F0EE),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Exit voice mode',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textSecondary : AppColors.ink2,
              ),
            ),
          ),
        ),
        SizedBox(height: 16 + MediaQuery.of(context).padding.bottom),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Jarvis Avatar
// ─────────────────────────────────────────────────────────────────────────────
class _JarvisAvatar extends StatelessWidget {
  final double size;
  final bool isDark;
  const _JarvisAvatar({required this.size, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4DA6FF), Color(0xFF2255CC)],
        ),
      ),
      child: Icon(Icons.smart_toy_rounded,
          size: size * 0.52, color: Colors.white),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Server status dot
// ─────────────────────────────────────────────────────────────────────────────
class _ServerDot extends StatelessWidget {
  final bool online, checked;
  const _ServerDot({required this.online, required this.checked});

  @override
  Widget build(BuildContext context) {
    if (!checked) return const SizedBox.shrink();
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: online ? const Color(0xFF34D399) : _kRed,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Server offline screen
// ─────────────────────────────────────────────────────────────────────────────
class _ServerOffline extends StatelessWidget {
  final bool isDark;
  final VoidCallback onRetry;
  const _ServerOffline({required this.isDark, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final txt2 = isDark ? AppColors.textSecondary : AppColors.ink2;
    final textColor = isDark ? AppColors.textPrimary : AppColors.ink;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _kRed.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off_rounded, size: 36, color: _kRed),
            ),
            const SizedBox(height: 20),
            Text('Jarvis is offline',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    letterSpacing: -0.5)),
            const SizedBox(height: 10),
            Text(
              'Start the Python server to chat with Jarvis:\n\n'
              'cd jarvis_server\n'
              'uvicorn main:app --reload',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: txt2, height: 1.7, fontFamily: 'monospace'),
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: _kJarvisBlue,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text('Retry',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Welcome / empty state
// ─────────────────────────────────────────────────────────────────────────────
class _WelcomeState extends StatelessWidget {
  final bool isDark, sttAvailable;
  final void Function(String) onSuggest;
  final VoidCallback onStartVoice;

  const _WelcomeState({
    required this.isDark,
    required this.onSuggest,
    required this.sttAvailable,
    required this.onStartVoice,
  });

  @override
  Widget build(BuildContext context) {
    final txt2 = isDark ? AppColors.textSecondary : AppColors.ink2;
    final textColor = isDark ? AppColors.textPrimary : AppColors.ink;
    final chipBg = isDark ? AppColors.bg3 : const Color(0xFFF0F4FF);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _JarvisAvatar(size: 80, isDark: isDark),
            const SizedBox(height: 20),
            Text('Hi, I\'m Jarvis',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    letterSpacing: -0.8)),
            const SizedBox(height: 8),
            Text(
              'Your personal habit coach.\nType below or tap the mic to talk.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: txt2, height: 1.6),
            ),
            if (sttAvailable) ...[
              const SizedBox(height: 24),
              GestureDetector(
                onTap: onStartVoice,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4DA6FF), Color(0xFF2255CC)],
                    ),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: _kJarvisBlue.withOpacity(0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.mic_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('Talk to Jarvis',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              letterSpacing: -0.3)),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 28),
            for (final suggestion in _suggestions)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _SuggestionChip(
                  label: suggestion,
                  bg: chipBg,
                  onTap: () => onSuggest(suggestion),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static const _suggestions = [
    'How do I build a morning routine?',
    "Why do I keep breaking my streak?",
    'Help me stay motivated this week',
    "What habit should I focus on next?",
  ];
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final Color bg;
  final VoidCallback onTap;
  const _SuggestionChip(
      {required this.label, required this.bg, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kJarvisBlue.withOpacity(0.2)),
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 13, color: _kJarvisBlue, letterSpacing: -0.2)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Message bubble
// ─────────────────────────────────────────────────────────────────────────────
class _Bubble extends StatelessWidget {
  final String text;
  final bool isUser, isDark;
  const _Bubble(
      {required this.text, required this.isUser, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final aiBg = isDark ? AppColors.bg3 : Colors.white;
    final aiText = isDark ? AppColors.textPrimary : AppColors.ink;
    final aiBorder = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            _JarvisAvatar(size: 28, isDark: isDark),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? _kLime : aiBg,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: isUser ? null : Border.all(color: aiBorder),
              ),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  color: isUser ? Colors.black : aiText,
                  height: 1.5,
                  letterSpacing: -0.1,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Typing indicator
// ─────────────────────────────────────────────────────────────────────────────
class _TypingIndicator extends StatefulWidget {
  final bool isDark;
  const _TypingIndicator({required this.isDark});

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? AppColors.bg3 : Colors.white;
    final border =
        widget.isDark ? AppColors.borderDark : AppColors.borderLight;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          _JarvisAvatar(size: 28, isDark: widget.isDark),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: _ctrl,
                  builder: (_, _) {
                    final phase =
                        (_ctrl.value - i * 0.15).clamp(0.0, 1.0);
                    final opacity = (0.3 +
                        0.7 *
                            (0.5 - (phase - 0.5).abs() * 2)
                                .clamp(0.0, 1.0));
                    return Padding(
                      padding: EdgeInsets.only(right: i < 2 ? 4 : 0),
                      child: Opacity(
                        opacity: opacity,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                              color: _kJarvisBlue,
                              shape: BoxShape.circle),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Input bar (text mode)
// ─────────────────────────────────────────────────────────────────────────────
class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool sending, isDark, sttAvailable;
  final VoidCallback onSend, onStartVoice;

  const _InputBar({
    required this.controller,
    required this.sending,
    required this.isDark,
    required this.sttAvailable,
    required this.onSend,
    required this.onStartVoice,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.bg2 : Colors.white;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final hintColor = isDark ? AppColors.textMuted : AppColors.ink3;
    final textColor = isDark ? AppColors.textPrimary : AppColors.ink;
    final fieldBg = isDark ? AppColors.bg3 : const Color(0xFFF5F5F3);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: border, width: 0.5)),
      ),
      padding: EdgeInsets.fromLTRB(
          16, 10, 16, 10 + MediaQuery.of(context).padding.bottom),
      child: Row(
        children: [
          if (sttAvailable) ...[
            GestureDetector(
              onTap: onStartVoice,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _kJarvisBlue.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: _kJarvisBlue, width: 1.5),
                ),
                child: const Icon(Icons.mic_rounded,
                    size: 20, color: _kJarvisBlue),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !sending,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(
                  fontSize: 14, color: textColor, letterSpacing: -0.2),
              decoration: InputDecoration(
                hintText: 'Ask Jarvis…',
                hintStyle: TextStyle(fontSize: 14, color: hintColor),
                filled: true,
                fillColor: fieldBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: sending ? null : onSend,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: sending
                    ? _kJarvisBlue.withOpacity(0.35)
                    : _kJarvisBlue,
                shape: BoxShape.circle,
              ),
              child: sending
                  ? const Padding(
                      padding: EdgeInsets.all(11),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.arrow_upward_rounded,
                      size: 20, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
