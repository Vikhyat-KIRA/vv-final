import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../theme/colors.dart';
import '../../providers/theme_provider.dart';
import '../../services/gemini_service.dart';

class FlashcardsScreen extends ConsumerStatefulWidget {
  final String subject;
  const FlashcardsScreen({super.key, required this.subject});

  @override
  ConsumerState<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends ConsumerState<FlashcardsScreen> {
  final List<Map<String, String>> _flashcards = [];
  bool _isGenerating = false;

  void _addManualFlashcard() {
    // Show dialog to add Question and Answer manually
    String question = '';
    String answer = '';

    showDialog(
      context: context,
      builder: (ctx) {
        final accent = ref.watch(themeProvider);
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text('New Flashcard', style: TextStyle(color: AppColors.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: 'Question',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                ),
                style: TextStyle(color: AppColors.textPrimary),
                onChanged: (val) => question = val,
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Answer',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                ),
                style: TextStyle(color: AppColors.textPrimary),
                maxLines: 3,
                onChanged: (val) => answer = val,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.white),
              onPressed: () {
                if (question.isNotEmpty && answer.isNotEmpty) {
                  setState(() {
                    _flashcards.add({'q': question, 'a': answer});
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _generateFromAI() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null && result.files.isNotEmpty && result.files.single.path != null) {
      setState(() {
        _isGenerating = true;
      });

      try {
        final fileBytes = await File(result.files.single.path!).readAsBytes();
        final ext = result.files.single.extension?.toLowerCase() ?? '';
        String mimeType = 'application/pdf';
        if (['jpg', 'jpeg'].contains(ext)) mimeType = 'image/jpeg';
        else if (ext == 'png') mimeType = 'image/png';

        final prompt = '''
Extract 3 to 5 high-yield flashcards from this document.
Format your response as a valid JSON array of objects.
Each object must have "q" for Question and "a" for Answer.
Example: [{"q": "Question", "a": "Answer"}]
Only output the JSON array, no markdown fences.
''';

        final aiResponse = await GeminiService.instance.generateContentWithFiles(
          prompt,
          [{'mimeType': mimeType, 'bytes': fileBytes}],
        );

        String cleanJson = aiResponse.trim();
        if (cleanJson.startsWith('```json')) cleanJson = cleanJson.substring(7);
        if (cleanJson.startsWith('```')) cleanJson = cleanJson.substring(3);
        if (cleanJson.endsWith('```')) cleanJson = cleanJson.substring(0, cleanJson.length - 3);

        final List<dynamic> parsed = jsonDecode(cleanJson.trim());
        final newCards = parsed.map((e) => {'q': e['q'].toString(), 'a': e['a'].toString()}).toList();

        setState(() {
          _isGenerating = false;
          _flashcards.addAll(newCards);
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
          'Flashcards - ${widget.subject}',
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
                  Text('AI is reading your file...', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            )
          : _flashcards.isEmpty
              ? Center(
                  child: Text('No flashcards yet. Create one or let AI generate from your notes!',
                      textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _flashcards.length,
                  itemBuilder: (context, index) {
                    final card = _flashcards[index];
                    return Card(
                      color: AppColors.surface,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: AppColors.border),
                      ),
                      child: ListTile(
                        title: Text(card['q'] ?? '', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                        subtitle: Text(card['a'] ?? '', style: TextStyle(color: AppColors.textSecondary)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () {
                            setState(() {
                              _flashcards.removeAt(index);
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'ai_flash',
            backgroundColor: AppColors.surface,
            foregroundColor: accent,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Generate with AI'),
            onPressed: _generateFromAI,
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'manual_flash',
            backgroundColor: accent,
            foregroundColor: Colors.white,
            child: const Icon(Icons.add),
            onPressed: _addManualFlashcard,
          ),
        ],
      ),
    );
  }
}
