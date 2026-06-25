import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../theme/colors.dart';
import '../../providers/theme_provider.dart';
import '../../services/gemini_service.dart';

class NotesGeneratorScreen extends ConsumerStatefulWidget {
  final String subject;
  const NotesGeneratorScreen({super.key, required this.subject});

  @override
  ConsumerState<NotesGeneratorScreen> createState() => _NotesGeneratorScreenState();
}

class _NotesGeneratorScreenState extends ConsumerState<NotesGeneratorScreen> {
  String? _generatedNotes;
  bool _isGenerating = false;

  Future<void> _generateFromAI() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null && result.files.isNotEmpty && result.files.single.path != null) {
      setState(() {
        _isGenerating = true;
        _generatedNotes = null;
      });

      try {
        final fileBytes = await File(result.files.single.path!).readAsBytes();
        final ext = result.files.single.extension?.toLowerCase() ?? '';
        String mimeType = 'application/pdf';
        if (['jpg', 'jpeg'].contains(ext)) mimeType = 'image/jpeg';
        else if (ext == 'png') mimeType = 'image/png';

        final prompt = '''
You are Vayu, an elite academic tutor.
Extract comprehensive, highly structured study notes from this document.
Format your response entirely in standard Markdown.
Include headings, bullet points, and bold text for key terms.
Do NOT include any generic conversational text like "Here are the notes".
Start directly with the title heading: "# Notes: [Topic Name]".
''';

        final aiResponse = await GeminiService.instance.generateContentWithFiles(
          prompt,
          [{'mimeType': mimeType, 'bytes': fileBytes}],
        );

        setState(() {
          _isGenerating = false;
          _generatedNotes = aiResponse.trim();
        });
      } catch (e) {
        setState(() {
          _isGenerating = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('AI Generation failed. Check API key or file format.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'AI Notes - ${widget.subject}',
          style: TextStyle(color: AppColors.textPrimary, fontFamily: 'Playfair Display', fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      body: _isGenerating
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(accent)),
                  const SizedBox(height: 16),
                  Text('Vayu is analyzing your document...', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            )
          : _generatedNotes == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_awesome, size: 64, color: AppColors.textSecondary),
                        const SizedBox(height: 16),
                        Text(
                          'Generate AI Notes',
                          style: TextStyle(
                            fontFamily: 'Playfair Display',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Upload a PDF or Image of your study material to automatically extract structured Markdown notes.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _generateFromAI,
                          icon: Icon(Icons.upload_file, color: Colors.white),
                          label: const Text('Select File', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Markdown(
                  data: _generatedNotes!,
                  styleSheet: MarkdownStyleSheet(
                    h1: TextStyle(fontFamily: 'Playfair Display', color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                    h2: TextStyle(fontFamily: 'Playfair Display', color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                    p: TextStyle(fontFamily: 'Plus Jakarta Sans', color: AppColors.textSecondary, fontSize: 14, height: 1.5),
                    listBullet: TextStyle(color: accent),
                  ),
                ),
      floatingActionButton: _generatedNotes != null
          ? FloatingActionButton.extended(
              heroTag: 'new_notes',
              backgroundColor: accent,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.refresh),
              label: const Text('Generate Another'),
              onPressed: _generateFromAI,
            )
          : null,
    );
  }
}
