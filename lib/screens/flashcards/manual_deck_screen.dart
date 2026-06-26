import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/flashcard_model.dart';
import '../../services/flashcard_service.dart';
import '../../theme/colors.dart';
import '../../providers/theme_provider.dart';

class ManualDeckScreen extends ConsumerStatefulWidget {
  const ManualDeckScreen({super.key});

  @override
  ConsumerState<ManualDeckScreen> createState() => _ManualDeckScreenState();
}

class _ManualDeckScreenState extends ConsumerState<ManualDeckScreen> {
  final _flashcardService = FlashcardService();
  
  final _deckNameController = TextEditingController();
  final _questionController = TextEditingController();
  final _answerController = TextEditingController();
  
  final _questionFocusNode = FocusNode();

  String _selectedSubject = 'Physics';
  bool _isSaving = false;

  final List<String> _subjects = ['Physics', 'Chemistry', 'Maths', 'Biology', 'General'];
  final List<FlashcardModel> _cards = [];

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? 'dev_user';

  @override
  void dispose() {
    _deckNameController.dispose();
    _questionController.dispose();
    _answerController.dispose();
    _questionFocusNode.dispose();
    super.dispose();
  }

  void _addCard() {
    final q = _questionController.text.trim();
    final a = _answerController.text.trim();

    if (q.isEmpty || a.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Both Question and Answer fields must be filled!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _cards.add(
        FlashcardModel(
          id: 'card_manual_${DateTime.now().millisecondsSinceEpoch}_${_cards.length}',
          front: q,
          back: a,
          reviewStatus: 0,
        ),
      );
      
      _questionController.clear();
      _answerController.clear();
    });

    // Request focus back on Question to easily type the next card
    _questionFocusNode.requestFocus();
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

    if (_cards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one flashcard to the deck!'),
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
      final deck = DeckModel(
        id: deckId,
        name: deckName,
        subject: _selectedSubject,
        cards: _cards,
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
        Navigator.pop(context); // return to decks hub
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save deck: $e'),
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
          'Manual Deck Creator',
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
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedSubject = val);
                  },
                ),
              ),
            ),
            SizedBox(height: 24),

            // Form to Add Card
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.surface2),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add New Card',
                    style: TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 12),
                  // Question Input
                  TextFormField(
                    controller: _questionController,
                    focusNode: _questionFocusNode,
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Question text',
                      labelStyle: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.surface2)),
                    ),
                  ),
                  SizedBox(height: 12),
                  // Answer Input
                  TextFormField(
                    controller: _answerController,
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Answer text',
                      labelStyle: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.surface2)),
                    ),
                  ),
                  SizedBox(height: 16),
                  // Add Card Button
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: _addCard,
                      icon: Icon(Icons.add, color: accent, size: 18),
                      label: Text('Add Card'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: BorderSide(color: accent.withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // List of added cards
            if (_cards.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Added Cards (${_cards.length})',
                    style: TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Swipe to delete',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
              SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _cards.length,
                itemBuilder: (context, index) {
                  final card = _cards[index];
                  return Dismissible(
                    key: Key(card.id),
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (direction) {
                      setState(() {
                        _cards.removeAt(index);
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Card removed'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: AppColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: AppColors.surface2),
                      ),
                      child: ListTile(
                        title: Text(
                          card.front,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          card.back,
                          style: TextStyle(fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                          onPressed: () {
                            setState(() {
                              _cards.removeAt(index);
                            });
                          },
                        ),
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
            ],
          ],
        ),
      ),
    );
  }
}
