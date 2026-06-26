import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:record/record.dart';
import '../../providers/chat_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/syllabus_provider.dart';

import '../../theme/colors.dart';
import '../../widgets/chat_bubble.dart';
import '../../services/gemini_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
class AiTutorScreen extends ConsumerStatefulWidget {
  const AiTutorScreen({super.key});

  @override
  ConsumerState<AiTutorScreen> createState() => _AiTutorScreenState();
}

class _AiTutorScreenState extends ConsumerState<AiTutorScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AudioRecorder _audioRecorder = AudioRecorder();
  StreamSubscription<String>? _streamSub;

  String _tutorMode = 'general';
  String _subjectName = 'Physics';
  String _chapterName = 'Waves';
  bool _isStreaming = false;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _streamSub?.cancel();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _tutorMode = prefs.getString('user_tutor_mode') ?? 'general';
      _subjectName = prefs.getString('last_subject') ?? 'Physics';
      _chapterName = prefs.getString('last_chapter') ?? 'Waves';
    });
  }

  Future<void> _selectSubject(Color accent) async {
    final subjects = ref.read(syllabusProvider);
    final subjectNames = subjects.map((s) => s.name).toList();
    
    if (subjectNames.isEmpty) {
      subjectNames.addAll(['Physics', 'Chemistry', 'Mathematics', 'Biology']);
    }

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Select Subject',
                style: TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ...subjectNames.map((name) {
                final isSelected = name == _subjectName;
                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected ? accent.withAlpha(30) : AppColors.surface2,
                      borderRadius: BorderRadius.circular(10),
                      border: isSelected ? Border.all(color: accent) : null,
                    ),
                    child: Icon(
                      Icons.menu_book,
                      color: isSelected ? accent : AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    name,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? accent : AppColors.textPrimary,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_circle, color: accent, size: 20)
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onTap: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('last_subject', name);
                    setState(() => _subjectName = name);
                    if (context.mounted) Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Future<void> _startRecording() async {
    if (await _audioRecorder.hasPermission()) {
      setState(() => _isRecording = true);
      await _audioRecorder.start(const RecordConfig(), path: ''); // Record to stream/memory
    }
  }

  Future<void> _stopRecording() async {
    setState(() => _isRecording = false);
    final path = await _audioRecorder.stop();
    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        _sendMessage('', audioBytes: bytes);
      }
    }
  }

  Future<void> _sendMessage(String text, {Uint8List? audioBytes}) async {
    if ((text.isEmpty && audioBytes == null) || _isStreaming) return;
    _messageController.clear();

    // 1. Add user message immediately
    ref.read(chatProvider.notifier).addUserMessage(text.isNotEmpty ? text : '🎤 Audio Message');

    // 2. Show typing indicator instantly before first token
    ref.read(chatProvider.notifier).setTyping(true);

    setState(() => _isStreaming = true);

    try {
      final stream = GeminiService.instance.sendMessageStream(text, audioBytes: audioBytes);
      bool firstToken = true;
      String streamingId = '';

      _streamSub = stream.listen(
        (chunk) {
          if (firstToken) {
            // Remove typing bubble, insert streaming bubble
            ref.read(chatProvider.notifier).setTyping(false);
            streamingId = ref.read(chatProvider.notifier).beginStreamingMessage();
            firstToken = false;
          }
          ref.read(chatProvider.notifier).appendToMessage(streamingId, chunk);
        },
        onDone: () {
          if (firstToken) {
            // Stream ended with no tokens (empty response)
            ref.read(chatProvider.notifier).setTyping(false);
          }
          if (streamingId.isNotEmpty) {
            ref.read(chatProvider.notifier).onStreamingComplete(streamingId);
          }
          if (mounted) setState(() => _isStreaming = false);
        },
        onError: (e) {
          ref.read(chatProvider.notifier).setTyping(false);
          ref.read(chatProvider.notifier).addAIMessage(
              'Vayu is unavailable right now. Try again in a moment.');
          if (mounted) setState(() => _isStreaming = false);
        },
        cancelOnError: true,
      );
    } catch (e) {
      ref.read(chatProvider.notifier).setTyping(false);
      ref.read(chatProvider.notifier).addAIMessage(
          'Vayu is unavailable right now. Try again in a moment.');
      if (mounted) setState(() => _isStreaming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = ref.watch(themeProvider);
    final messages = ref.watch(chatProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: _buildModeBadge(),
        leadingWidth: 120,
        title: _buildSubjectSelector(accent),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.clear_all, color: AppColors.textPrimary),
            tooltip: 'Clear Chat',
            onPressed: () {
              _streamSub?.cancel();
              setState(() => _isStreaming = false);
              ref.read(chatProvider.notifier).clearChat();
              GeminiService.instance.clearHistory();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              // RepaintBoundary isolates the list from the input bar repaints
              child: RepaintBoundary(
                child: ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    return ChatBubble(message: messages[index]);
                  },
                ),
              ),
            ),
            _buildQuickPromptChips(accent),
            // RepaintBoundary isolates input bar from list repaints
            RepaintBoundary(child: _buildInputBar(accent)),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectSelector(Color accent) {
    return GestureDetector(
      onTap: () => _selectSubject(accent),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: accent.withAlpha(15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withAlpha(60)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book, color: accent, size: 16),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _subjectName,
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, color: accent, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildModeBadge() {
    final isStrict = _tutorMode == 'strict';
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isStrict
                ? const Color(0xFF8B5CF6).withAlpha(30)
                : const Color(0xFF22C55E).withAlpha(30),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isStrict ? const Color(0xFF8B5CF6) : const Color(0xFF22C55E),
            ),
          ),
          child: Text(
            isStrict ? '📚 Strict' : '🧭 General',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isStrict ? const Color(0xFF8B5CF6) : const Color(0xFF22C55E),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickPromptChips(Color accent) {
    final prompts = [
      'Explain my chapter',
      'Test me',
      'Study plan',
      'Motivate me',
    ];
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: prompts.map((prompt) {
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ActionChip(
                label: Text(
                  prompt,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500),
                ),
                backgroundColor: AppColors.surface,
                disabledColor: AppColors.surface,
                side: BorderSide(color: AppColors.surface2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onPressed: _isStreaming ? null : () => _sendMessage(prompt),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildInputBar(Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.surface2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.surface2),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _messageController,
                maxLines: null,
                enabled: !_isStreaming,
                style:
                    TextStyle(color: AppColors.textPrimary, fontSize: 15),
                decoration: InputDecoration(
                  hintText:
                      _isStreaming ? 'Vayu is replying...' : 'Ask Vayu...',
                  hintStyle:
                      TextStyle(color: AppColors.textSecondary),
                  border: InputBorder.none,
                ),
                onSubmitted:
                    _isStreaming ? null : _sendMessage,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isStreaming ? null : () async {
              if (_isRecording) {
                await _stopRecording();
              } else {
                await _startRecording();
              }
            },
            child: _isRecording
                ? CircleAvatar(
                    backgroundColor: Colors.redAccent,
                    radius: 22,
                    child: const Icon(
                      Icons.mic,
                      color: Colors.white,
                      size: 20,
                    ),
                  ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                   .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.2, 1.2), duration: 600.ms)
                   .fade(begin: 0.8, end: 1.0)
                : CircleAvatar(
                    backgroundColor: AppColors.surface2,
                    radius: 22,
                    child: Icon(
                      Icons.mic_none,
                      color: AppColors.textPrimary,
                      size: 20,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isStreaming
                ? null
                : () {
                    final text = _messageController.text.trim();
                    if (text.isNotEmpty) _sendMessage(text);
                  },
            child: CircleAvatar(
              backgroundColor: _isStreaming
                  ? AppColors.surface2
                  : accent,
              radius: 22,
              child: _isStreaming
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(accent),
                      ),
                    )
                  : Icon(
                      Icons.arrow_upward,
                      color: AppColors.background,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
