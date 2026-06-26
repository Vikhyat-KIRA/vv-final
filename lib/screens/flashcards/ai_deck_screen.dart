import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/flashcard_model.dart';
import '../../services/flashcard_service.dart';
import '../../services/gemini_service.dart';
import '../../theme/colors.dart';
import '../../providers/theme_provider.dart';

class AiDeckScreen extends ConsumerStatefulWidget {
  final String? prefilledText;

  const AiDeckScreen({super.key, this.prefilledText});

  @override
  ConsumerState<AiDeckScreen> createState() => _AiDeckScreenState();
}

class _AiDeckScreenState extends ConsumerState<AiDeckScreen> {
  final _flashcardService = FlashcardService();
  final _deckNameController = TextEditingController(text: 'AI Study Deck');
  final _chapterController = TextEditingController();
  late TextEditingController _pasteController;

  String _selectedSubject = 'Physics';
  bool _isGenerating = false;
  bool _isSaving = false;

  final List<String> _subjects = ['Physics', 'Chemistry', 'Maths', 'Biology', 'General'];
  
  // Holds the list of cards after generation
  final List<Map<String, String>> _generatedCards = [];

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? 'dev_user';

  @override
  void initState() {
    super.initState();
    _pasteController = TextEditingController(text: widget.prefilledText ?? '');
  }

  @override
  void dispose() {
    _deckNameController.dispose();
    _chapterController.dispose();
    _pasteController.dispose();
    super.dispose();
  }

  Future<void> _generateCards() async {
    final pasteText = _pasteController.text.trim();
    final chapterText = _chapterController.text.trim();

    if (pasteText.isEmpty && chapterText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a chapter name OR paste study text!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _generatedCards.clear();
    });

    final String contentText = pasteText.isNotEmpty
        ? pasteText
        : "Subject: $_selectedSubject, Chapter/Topic: $chapterText";

    final prompt = 'Generate 10 exam-ready flashcards. Return ONLY a valid JSON array, no markdown:\n'
        '[{"front":"question","back":"answer"}]\n'
        'Focus on definitions, key facts, important formulas. Content: $contentText';

    try {
      final responseText = await GeminiService.instance.sendMessage(prompt);
      
      // Clean potential code block wrapping
      String cleanJson = responseText.trim();
      if (cleanJson.startsWith('```')) {
        cleanJson = cleanJson.replaceAll(RegExp(r'^```(json)?\n?'), '');
      }
      if (cleanJson.endsWith('```')) {
        cleanJson = cleanJson.substring(0, cleanJson.length - 3).trim();
      }

      final List<dynamic> jsonList = jsonDecode(cleanJson);
      
      setState(() {
        for (final item in jsonList) {
          _generatedCards.add({
            'front': (item['front'] ?? '').toString(),
            'back': (item['back'] ?? '').toString(),
          });
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate cards: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  Future<void> _saveDeck() async {
    final deckName = _deckNameController.text.trim();
    if (deckName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a deck name!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_generatedCards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generate flashcards first!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final deckId = 'deck_${DateTime.now().millisecondsSinceEpoch}';
      
      final List<FlashcardModel> cards = [];
      for (int i = 0; i < _generatedCards.length; i++) {
        final cardData = _generatedCards[i];
        final front = cardData['front']?.trim() ?? '';
        final back = cardData['back']?.trim() ?? '';
        
        if (front.isNotEmpty && back.isNotEmpty) {
          cards.add(
            FlashcardModel(
              id: 'card_${deckId}_$i',
              front: front,
              back: back,
              reviewStatus: 0, // new card
            ),
          );
        }
      }

      if (cards.isEmpty) {
        throw Exception('Flashcards cannot be empty.');
      }

      final deck = DeckModel(
        id: deckId,
        name: deckName,
        subject: _selectedSubject,
        cards: cards,
        masteryPercent: 0.0,
        createdAt: DateTime.now(),
      );

      await _flashcardService.saveDeck(_uid, deck);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deck saved successfully ✓'),
            backgroundColor: AppColors.accentDefault,
          ),
        );
        Navigator.pop(context); // return to decks screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving deck: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'AI Deck Generator',
          style: TextStyle(
            fontFamily: 'Space Grotesk',
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Deck Name Field
            Text(
              'Deck Name',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 13),
            ),
            SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.surface2),
              ),
              child: TextField(
                controller: _deckNameController,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Enter deck name...',
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            SizedBox(height: 20),

            // Subject selection dropdown
            Text(
              'Subject',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 13),
            ),
            SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.surface2),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedSubject,
                  isExpanded: true,
                  dropdownColor: AppColors.surface,
                  items: _subjects.map((String sub) {
                    return DropdownMenuItem<String>(
                      value: sub,
                      child: Text(sub, style: TextStyle(color: AppColors.textPrimary)),
                    );
                  }).toList(),
                  onChanged: _isGenerating
                      ? null
                      : (val) {
                          if (val != null) setState(() => _selectedSubject = val);
                        },
                ),
              ),
            ),
            SizedBox(height: 20),

            // If we have generated cards, show editable list. Otherwise, show input form
            if (_generatedCards.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Review AI Flashcards',
                    style: TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _generateCards,
                    icon: Icon(Icons.refresh, size: 16),
                    label: Text('Re-generate'),
                    style: TextButton.styleFrom(foregroundColor: accent),
                  ),
                ],
              ),
              SizedBox(height: 12),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _generatedCards.length,
                itemBuilder: (context, index) {
                  final card = _generatedCards[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    color: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: AppColors.surface2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Card ${index + 1}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                                onPressed: () {
                                  setState(() {
                                    _generatedCards.removeAt(index);
                                  });
                                },
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          // Question TextFormField
                          TextFormField(
                            initialValue: card['front'],
                            style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                            decoration: InputDecoration(
                              labelText: 'Question',
                              labelStyle: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.surface2)),
                            ),
                            onChanged: (val) {
                              _generatedCards[index]['front'] = val;
                            },
                          ),
                          SizedBox(height: 12),
                          // Answer TextFormField
                          TextFormField(
                            initialValue: card['back'],
                            style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                            decoration: InputDecoration(
                              labelText: 'Answer',
                              labelStyle: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.surface2)),
                            ),
                            onChanged: (val) {
                              _generatedCards[index]['back'] = val;
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 24),
              _isSaving
                  ? Center(child: CircularProgressIndicator(color: AppColors.accentDefault))
                  : SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _saveDeck,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Save Deck',
                          style: TextStyle(
                            color: AppColors.background,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Space Grotesk',
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
            ] else ...[
              // Chapter name input
              Text(
                'Chapter Name (Simple Topic Generation)',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 13),
              ),
              SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.surface2),
                ),
                child: TextField(
                  controller: _chapterController,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'e.g. Photoelectric Effect...',
                    hintStyle: TextStyle(color: AppColors.textSecondary),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Paste area
              Text(
                'OR Paste Study Text',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 13),
              ),
              SizedBox(height: 8),
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surface2),
                ),
                child: TextField(
                  controller: _pasteController,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.5),
                  decoration: InputDecoration(
                    hintText: 'Paste study paragraphs, textbook notes, or outlines here...',
                    hintStyle: TextStyle(color: AppColors.textSecondary),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                ),
              ),
              SizedBox(height: 32),

              // Generate Button
              _isGenerating
                  ? Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(color: AppColors.accentDefault),
                          SizedBox(height: 12),
                          Text(
                            'AI is writing flashcards...',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _generateCards,
                        icon: Icon(Icons.psychology, color: AppColors.background),
                        label: Text(
                          'Generate Cards',
                          style: TextStyle(
                            color: AppColors.background,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Space Grotesk',
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
            ],
          ],
        ),
      ),
    );
  }
}
