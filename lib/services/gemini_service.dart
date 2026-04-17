// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:habit_tracker/config/app_config.dart';

/// Calls the Gemini 2.0 Flash REST API directly from the Flutter client.
/// No backend required — works on the free Gemini tier.
abstract final class GeminiService {
  static const _model = 'gemini-1.5-flash-8b'; // free tier, generous quota
  static const _fallbackModel = 'gemini-1.5-flash'; // fallback if 8b is throttled
  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';
  static const _streamUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:streamGenerateContent';
  static const _fallbackStreamUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$_fallbackModel:streamGenerateContent';

  /// Single-turn call (for motivation / review).
  static Future<String?> generate({
    required String systemPrompt,
    required String userMessage,
    int maxTokens = 400,
  }) async {
    return _call(
      systemPrompt: systemPrompt,
      contents: [
        {
          'role': 'user',
          'parts': [
            {'text': userMessage}
          ],
        },
      ],
      maxTokens: maxTokens,
    );
  }

  /// Multi-turn call for the habit coach chat.
  /// [messages] is the existing conversation:
  ///   [{'role': 'user'|'assistant', 'content': '...'}, ...]
  static Future<String?> chat({
    required String systemPrompt,
    required List<Map<String, String>> messages,
    int maxTokens = 800,
  }) async {
    final contents = _toContents(messages);
    return _call(
      systemPrompt: systemPrompt,
      contents: contents,
      maxTokens: maxTokens,
    );
  }

  /// Streaming multi-turn chat — yields text chunks as they arrive.
  /// Tries gemini-1.5-flash-8b first; falls back to gemini-1.5-flash on 429.
  static Stream<String> chatStream({
    required String systemPrompt,
    required List<Map<String, String>> messages,
    int maxTokens = 800,
  }) async* {
    yield* _streamFrom(
      url: _streamUrl,
      fallbackUrl: _fallbackStreamUrl,
      systemPrompt: systemPrompt,
      messages: messages,
      maxTokens: maxTokens,
    );
  }

  static Stream<String> _streamFrom({
    required String url,
    required String fallbackUrl,
    required String systemPrompt,
    required List<Map<String, String>> messages,
    required int maxTokens,
    bool isFallback = false,
  }) async* {
    final apiKey = AppConfig.geminiApiKey;
    final body = jsonEncode({
      'system_instruction': {
        'parts': [{'text': systemPrompt}],
      },
      'contents': _toContents(messages),
      'generationConfig': {'maxOutputTokens': maxTokens},
    });

    try {
      final request = http.Request('POST', Uri.parse('$url?key=$apiKey&alt=sse'))
        ..headers['Content-Type'] = 'application/json'
        ..body = body;

      final response = await http.Client().send(request);

      if (response.statusCode == 429 && !isFallback) {
        print('⚠️ GeminiService: 429 on primary model, falling back');
        // drain the error response body before retrying
        await response.stream.drain<void>();
        yield* _streamFrom(
          url: fallbackUrl,
          fallbackUrl: fallbackUrl,
          systemPrompt: systemPrompt,
          messages: messages,
          maxTokens: maxTokens,
          isFallback: true,
        );
        return;
      }

      if (response.statusCode != 200) {
        print('⚠️ GeminiService stream: HTTP ${response.statusCode}');
        await response.stream.drain<void>();
        return;
      }

      final lineStream = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in lineStream) {
        if (!line.startsWith('data: ')) continue;
        final jsonStr = line.substring(6).trim();
        if (jsonStr.isEmpty || jsonStr == '[DONE]') continue;
        try {
          final data = jsonDecode(jsonStr) as Map<String, dynamic>;
          final chunk = (data['candidates'] as List?)
              ?.firstOrNull?['content']?['parts']
                  ?.firstOrNull?['text'] as String?;
          if (chunk != null && chunk.isNotEmpty) yield chunk;
        } catch (_) {
          // skip malformed SSE chunks
        }
      }
    } catch (e) {
      print('⚠️ GeminiService stream error: $e');
    }
  }

  static List<Map<String, dynamic>> _toContents(
      List<Map<String, String>> messages) {
    return messages
        .map((m) => {
              'role': m['role'] == 'assistant' ? 'model' : 'user',
              'parts': [
                {'text': m['content'] ?? ''}
              ],
            })
        .toList();
  }

  static Future<String?> _call({
    required String systemPrompt,
    required List<Map<String, dynamic>> contents,
    required int maxTokens,
  }) async {
    final apiKey = AppConfig.geminiApiKey;
    if (apiKey == 'YOUR_GEMINI_API_KEY') {
      print('⚠️ GeminiService: API key not set in AppConfig.geminiApiKey');
      return null;
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'system_instruction': {
            'parts': [
              {'text': systemPrompt}
            ],
          },
          'contents': contents,
          'generationConfig': {'maxOutputTokens': maxTokens},
        }),
      );

      if (response.statusCode != 200) {
        print('⚠️ GeminiService: HTTP ${response.statusCode} — ${response.body}');
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final text = (data['candidates'] as List?)
          ?.firstOrNull?['content']?['parts']
              ?.firstOrNull?['text'] as String?;
      return text;
    } catch (e) {
      print('⚠️ GeminiService error: $e');
      return null;
    }
  }
}
