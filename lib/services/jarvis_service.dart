// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// Jarvis AI coach — powered by Groq via the FastAPI server.
/// Deploy the server (jarvis_server/) to Railway/Render and update [baseUrl].
abstract final class JarvisService {
  // ── Config ──────────────────────────────────────────────────────────────────
  /// Update this after deploying: https://your-app.up.railway.app
  static const String baseUrl = String.fromEnvironment(
    'JARVIS_URL',
    defaultValue: 'https://habit-tracker-ecuo.onrender.com',
  );

  // ── Chat (streaming SSE via server → Groq) ──────────────────────────────────
  static Stream<String> chatStream({
    required List<Map<String, String>> messages,
    String habitContext = '',
  }) async* {
    final uri = Uri.parse('$baseUrl/chat');
    final request = http.Request('POST', uri)
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode({'messages': messages, 'habit_context': habitContext});

    http.StreamedResponse response;
    try {
      response = await http.Client().send(request);
    } catch (e) {
      print('⚠️ JarvisService: cannot reach server — $e');
      yield* Stream.error('Cannot reach Jarvis server.');
      return;
    }

    if (response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      print('⚠️ JarvisService: HTTP ${response.statusCode} — $body');
      yield* Stream.error('Server error ${response.statusCode}');
      return;
    }

    final lineStream = response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    await for (final line in lineStream) {
      if (!line.startsWith('data: ')) continue;
      final payload = line.substring(6).trim();
      if (payload.isEmpty || payload == '[DONE]') continue;
      try {
        final json = jsonDecode(payload) as Map<String, dynamic>;
        if (json.containsKey('error')) {
          print('⚠️ JarvisService: ${json['error']}');
          break;
        }
        final text = json['text'] as String?;
        if (text != null && text.isNotEmpty) yield text;
      } catch (_) {}
    }
  }

  // ── TTS — get audio bytes for a piece of text ───────────────────────────────

  /// Asks the server to convert [text] to speech and returns raw MP3 bytes.
  /// Returns null if the server is unavailable or TTS is not installed.
  static Future<Uint8List?> tts(String text) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/tts'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'text': text}),
          )
          .timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) return response.bodyBytes;
      print('⚠️ JarvisService TTS: HTTP ${response.statusCode}');
      return null;
    } catch (e) {
      print('⚠️ JarvisService TTS error: $e');
      return null;
    }
  }

  // ── STT — send audio bytes, get transcript ──────────────────────────────────

  /// Sends raw audio bytes to the server for transcription via Whisper.
  /// [filename] helps the server pick the right decoder (e.g. "audio.m4a").
  /// Returns the transcript string, or null on error.
  static Future<String?> stt(Uint8List audioBytes, String filename) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/stt'),
      )..files.add(http.MultipartFile.fromBytes(
          'audio',
          audioBytes,
          filename: filename,
        ));

      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final body = await streamed.stream.bytesToString();

      if (streamed.statusCode == 200) {
        final json = jsonDecode(body) as Map<String, dynamic>;
        return json['transcript'] as String?;
      }
      print('⚠️ JarvisService STT: HTTP ${streamed.statusCode} — $body');
      return null;
    } catch (e) {
      print('⚠️ JarvisService STT error: $e');
      return null;
    }
  }

  // ── Health check ─────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>?> health() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
