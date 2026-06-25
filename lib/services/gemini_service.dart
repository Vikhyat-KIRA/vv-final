import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  static GeminiService get instance => _instance;
  GeminiService._internal();

  final List<Map<String, dynamic>> _history = [];
  String? _apiKey;
  // Cached system prompt — rebuilt only when invalidated
  String? _cachedSystemPrompt;

  List<Map<String, dynamic>> get history => _history;

  /// Invalidates the system prompt cache (call after onboarding or settings change)
  void invalidatePromptCache() => _cachedSystemPrompt = null;

  Future<String?> _getApiKey() async {
    if (_apiKey != null) return _apiKey;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('config')
          .doc('gemini')
          .get();
      if (doc.exists && doc.data() != null) {
        _apiKey = doc.data()?['apiKey'] as String?;
      }
    } catch (e) {
      debugPrint('Error fetching Gemini API Key: $e');
    }
    return _apiKey;
  }

  /// Returns the cached system prompt, building it once if needed
  Future<String> _getSystemPrompt() async {
    if (_cachedSystemPrompt != null) return _cachedSystemPrompt!;

    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name') ?? 'Learner';
    final grade = prefs.getString('user_grade') ?? 'Class 8';
    final board = prefs.getString('user_board') ?? 'CBSE';
    final currentPercent = prefs.getDouble('user_percentage') ?? 60.0;
    final targetPercent = prefs.getDouble('user_target_percentage') ?? 90.0;
    final delta = (targetPercent - currentPercent).clamp(0.0, 100.0);
    final urgency = prefs.getString('user_urgency') ?? 'calm';
    final tutorMode = prefs.getString('user_tutor_mode') ?? 'general';
    final currentChapter = prefs.getString('last_chapter') ?? 'Waves';

    String prompt =
        'You are Vayu, an elite academic tutor for $name, a $grade student on $board board. '
        'Current: ${currentPercent.toInt()}%. Target: ${targetPercent.toInt()}%. '
        'Delta: ${delta.toInt()}%. Urgency: $urgency. '
        'Keep replies under 4 sentences unless explaining a concept in detail. '
        'Be sharp and push toward their goal.';

    if (tutorMode == 'general') {
      prompt += ' You can discuss any academic topic.';
    } else if (tutorMode == 'strict' || tutorMode == 'syllabus') {
      prompt += ' STRICT MODE: Only respond about the $board $grade curriculum. '
          'Current chapter: $currentChapter. Redirect off-syllabus questions.';
    }

    if (urgency == 'critical') {
      prompt += ' Tone: urgent, direct, no filler.';
    } else if (urgency == 'calm') {
      prompt += ' Tone: supportive, encouraging.';
    }

    _cachedSystemPrompt = prompt;
    return prompt;
  }

  /// Streams response tokens one by one via SSE.
  /// Yields partial text deltas as they arrive.
  Stream<String> sendMessageStream(String userText, {Uint8List? audioBytes}) async* {
    final List<Map<String, dynamic>> userParts = [];
    if (audioBytes != null) {
      userParts.add({
        'inline_data': {
          'mime_type': 'audio/wav',
          'data': base64Encode(audioBytes),
        }
      });
    }
    if (userText.isNotEmpty) {
      userParts.add({'text': userText});
    } else if (audioBytes == null) {
      return; // nothing to send
    }

    _history.add({
      'role': 'user',
      'parts': userParts,
    });

    final apiKey = await _getApiKey();
    final systemPrompt = await _getSystemPrompt();

    // No API key — stream the mock reply character by character
    if (apiKey == null || apiKey.isEmpty || apiKey == 'YOUR_GEMINI_API_KEY') {
      final mockReply = _buildMockReply(userText);
      // Simulate streaming: emit ~8 chars at a time with a small delay
      const chunkSize = 8;
      for (int i = 0; i < mockReply.length; i += chunkSize) {
        final end = (i + chunkSize).clamp(0, mockReply.length);
        yield mockReply.substring(i, end);
        await Future.delayed(const Duration(milliseconds: 30));
      }
      _history.add({
        'role': 'model',
        'parts': [{'text': mockReply}],
      });
      _trimHistory();
      return;
    }

    final streamUrl =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:streamGenerateContent?key=$apiKey&alt=sse';

    final requestBody = jsonEncode({
      'system_instruction': {
        'parts': [{'text': systemPrompt}]
      },
      'contents': _history,
    });

    try {
      final request = http.Request('POST', Uri.parse(streamUrl))
        ..headers['Content-Type'] = 'application/json'
        ..body = requestBody;

      final response = await http.Client().send(request);

      if (response.statusCode != 200) {
        yield 'Vayu is unavailable right now (${response.statusCode}). Try again.';
        return;
      }

      final fullBuffer = StringBuffer();
      await for (final chunk in response.stream.transform(utf8.decoder)) {
        // SSE lines: each chunk may contain multiple 'data: {...}' lines
        for (final line in chunk.split('\n')) {
          if (!line.startsWith('data: ')) continue;
          final jsonStr = line.substring(6).trim();
          if (jsonStr == '[DONE]' || jsonStr.isEmpty) continue;
          try {
            final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
            final candidates = decoded['candidates'] as List<dynamic>?;
            if (candidates == null || candidates.isEmpty) continue;
            final parts = (candidates[0]['content']?['parts']) as List<dynamic>?;
            if (parts == null || parts.isEmpty) continue;
            final text = parts[0]['text'] as String? ?? '';
            if (text.isNotEmpty) {
              fullBuffer.write(text);
              yield text;
            }
          } catch (_) {
            // Malformed JSON chunk — skip
          }
        }
      }

      final fullReply = fullBuffer.toString();
      if (fullReply.isNotEmpty) {
        _history.add({
          'role': 'model',
          'parts': [{'text': fullReply}],
        });
        _trimHistory();
      }
    } catch (e) {
      debugPrint('Error in GeminiService.sendMessageStream: $e');
      yield 'Vayu is unavailable right now. Try again in a moment.';
    }
  }

  /// Non-streaming fallback (kept for compatibility)
  Future<String> sendMessage(String userText) async {
    final buffer = StringBuffer();
    await for (final chunk in sendMessageStream(userText)) {
      buffer.write(chunk);
    }
    return buffer.toString();
  }

  Future<String> generateContentWithFiles(String prompt, List<Map<String, dynamic>> files) async {
    final apiKey = await _getApiKey();
    if (apiKey == null || apiKey.isEmpty || apiKey == 'YOUR_GEMINI_API_KEY') {
      if (prompt.toLowerCase().contains('note')) {
        return 'Mock AI Notes generated from file.';
      } else if (prompt.toLowerCase().contains('flashcard')) {
        return 'Mock Flashcards generated from file.';
      }
      return 'Mock response generated from file.';
    }

    final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey';

    final parts = <Map<String, dynamic>>[];
    for (final file in files) {
      parts.add({
        'inlineData': {
          'mimeType': file['mimeType'],
          'data': base64Encode(file['bytes'] as List<int>),
        }
      });
    }
    parts.add({'text': prompt});

    final requestBody = jsonEncode({
      'contents': [
        {
          'parts': parts,
        }
      ]
    });

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final text = decoded['candidates'][0]['content']['parts'][0]['text'] as String?;
        return text ?? 'No response text.';
      } else {
        return 'Error: ${response.statusCode} - ${response.body}';
      }
    } catch (e) {
      debugPrint('Error generating content with files: $e');
      return 'Error: $e';
    }
  }

  void clearHistory() => _history.clear();

  Future<String> analyzeExamTimetable(Uint8List imageBytes) async {
    final apiKey = await _getApiKey();
    if (apiKey == null || apiKey.isEmpty || apiKey == 'YOUR_GEMINI_API_KEY') {
      return 'normal';
    }

    final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey';

    final prompt = "Analyze this exam timetable. Extract the exam dates and strictly recommend a study urgency level ('critical', 'high', 'normal', 'calm'). Provide the urgency level as the last word of your response.";

    final requestBody = jsonEncode({
      'contents': [
        {
          'parts': [
            {
              'inlineData': {
                'mimeType': 'image/jpeg',
                'data': base64Encode(imageBytes),
              }
            },
            {
              'text': prompt
            }
          ]
        }
      ]
    });

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final candidates = decoded['candidates'] as List<dynamic>?;
        if (candidates != null && candidates.isNotEmpty) {
          final parts = candidates[0]['content']['parts'] as List<dynamic>?;
          if (parts != null && parts.isNotEmpty) {
             return parts[0]['text'] as String? ?? 'normal';
          }
        }
        return 'normal';
      } else {
        debugPrint('Error analyzing timetable: ${response.body}');
        return 'normal';
      }
    } catch (e) {
      debugPrint('Error analyzing timetable: $e');
      return 'normal';
    }
  }

  String _buildMockReply(String userText) {
    if (userText.toLowerCase().contains('explain')) {
      return 'In Physics, waves are oscillations that transfer energy without transferring matter. '
          'Key features: wavelength, amplitude, frequency, and wave speed. '
          'Waves can be mechanical (like sound) or electromagnetic (like light). '
          'Which type would you like to explore?';
    } else if (userText.toLowerCase().contains('test')) {
      return 'Quick test: What is the main difference between transverse and longitudinal waves? '
          '(Think about particle vibration direction vs. wave travel direction.)';
    } else if (userText.toLowerCase().contains('motivate')) {
      return 'You have a delta gap to close — but with consistent daily sessions you will hit your target. '
          "Let's conquer this chapter together!";
    } else {
      return 'Configure your API key in Firestore (collection: config, doc: gemini, field: apiKey) '
          'to enable live Gemini responses. What concept shall we cover?';
    }
  }

  void _trimHistory() {
    if (_history.length > 20) {
      _history.removeRange(0, 2);
    }
  }
}
