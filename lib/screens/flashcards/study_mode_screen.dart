import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/flashcard_model.dart';
import '../../services/flashcard_service.dart';
import '../../widgets/flash_card_widget.dart';
import '../../theme/colors.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';

class StudyModeScreen extends ConsumerStatefulWidget {
  final DeckModel deck;

  const StudyModeScreen({super.key, required this.deck});

  @override
  ConsumerState<StudyModeScreen> createState() => _StudyModeScreenState();
}

class _StudyModeScreenState extends ConsumerState<StudyModeScreen> {
  final _flashcardService = FlashcardService();
  
  late List<FlashcardModel> _queue;
  final List<FlashcardModel> _mastered = [];
  final List<FlashcardModel> _toReview = []; // Cards that failed once in this session

  int _sessionXpEarned = 0;
  bool _isFinished = false;
  
  // Track slide animation direction (true = right slide, false = left slide)
  bool _slideRight = true;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? 'dev_user';

  @override
  void initState() {
    super.initState();
    _queue = List.from(widget.deck.cards);
  }

  void _handleGotIt() async {
    if (_queue.isEmpty) return;

    final card = _queue[0];
    
    // Save state update in Firestore (Mastered = status 2)
    await _flashcardService.updateCardStatus(_uid, widget.deck.id, card.id, 2);
    
    // Award XP
    ref.read(authProvider.notifier).addXp(5);

    setState(() {
      _slideRight = true;
      _mastered.add(card);
      _sessionXpEarned += 5;
      _queue.removeAt(0);

      if (_queue.isEmpty) {
        _isFinished = true;
      }
    });
  }

  void _handleAgain() async {
    if (_queue.isEmpty) return;

    final card = _queue[0];
    
    // Save status in Firestore (Again/Learning = status 1)
    await _flashcardService.updateCardStatus(_uid, widget.deck.id, card.id, 1);

    setState(() {
      _slideRight = false;
      
      // If we haven't already marked it for review, add to review list
      if (!_toReview.any((c) => c.id == card.id)) {
        _toReview.add(card);
      }
      
      // Move to end of queue
      _queue.removeAt(0);
      _queue.add(
        FlashcardModel(
          id: card.id,
          front: card.front,
          back: card.back,
          reviewStatus: 1,
        ),
      );
    });
  }

  void _restartSession() {
    setState(() {
      _queue = List.from(widget.deck.cards);
      _mastered.clear();
      _toReview.clear();
      _sessionXpEarned = 0;
      _isFinished = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = ref.watch(themeProvider);

    if (_isFinished) {
      return _buildResultsScreen(accent);
    }

    if (_queue.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.accentDefault),
        ),
      );
    }

    final currentCard = _queue[0];
    final totalCards = widget.deck.cards.length;
    final progress = totalCards > 0 ? (_mastered.length / totalCards) : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.deck.name,
          style: TextStyle(
            fontFamily: 'Space Grotesk',
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              // 1. Mastery progress indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mastered cards',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  Text(
                    '${_mastered.length} of $totalCards',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: accent),
                  ),
                ],
              ),
              SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.surface2,
                color: accent,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
              const Spacer(),

              // 2. 3D Flip Flashcard with custom slide transition
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  final beginOffset = _slideRight ? const Offset(1.2, 0.0) : const Offset(-1.2, 0.0);
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: beginOffset,
                      end: Offset.zero,
                    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                    child: child,
                  );
                },
                child: FlashCardWidget(
                  key: ValueKey<String>(currentCard.id),
                  card: currentCard,
                  accentColor: accent,
                ),
              ),
              const Spacer(),

              // 3. Counter display
              Text(
                'Cards in Queue: ${_queue.length}',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 24),

              // 4. Controls Row
              Row(
                children: [
                  // Again Button (Red)
                  Expanded(
                    child: TextButton.icon(
                      onPressed: _handleAgain,
                      icon: Icon(Icons.refresh, color: AppColors.error),
                      label: Text('Again'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                        backgroundColor: AppColors.error.withValues(alpha: 0.08),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: AppColors.error, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  
                  // Got It Button (Green)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _handleGotIt,
                      icon: Icon(Icons.check, color: AppColors.background),
                      label: Text('Got It'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: AppColors.background,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsScreen(Color accent) {
    final missedCount = _toReview.length;
    final masteredCount = _mastered.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Triumphant Icon Circle
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: accent.withValues(alpha: 0.3), width: 2),
                ),
                child: Icon(Icons.emoji_events, size: 72, color: accent),
              ),
              SizedBox(height: 32),

              // Title
              Text(
                'Deck Completed!',
                style: TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 12),
              
              // Encouragement subtitle
              Text(
                'Excellent study session! You are closing your syllabus knowledge gaps.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40),

              // Score Summary Panel
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.surface2),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Row(
                              children: [
                                Icon(Icons.check_circle, color: Color(0xFF10B981), size: 18),
                                SizedBox(width: 6),
                                Text(
                                  'Mastered',
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              '$masteredCount',
                              style: TextStyle(
                                fontFamily: 'Space Grotesk',
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                        Container(width: 1, height: 40, color: AppColors.surface2),
                        Column(
                          children: [
                            Row(
                              children: [
                                Icon(Icons.refresh, color: AppColors.error, size: 18),
                                SizedBox(width: 6),
                                Text(
                                  'To Review',
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              '$missedCount',
                              style: TextStyle(
                                fontFamily: 'Space Grotesk',
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Divider(color: AppColors.surface2, height: 32),
                    // XP Earned Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bolt, color: Colors.orangeAccent, size: 28),
                        SizedBox(width: 8),
                        Text(
                          '+$_sessionXpEarned XP Earned',
                          style: TextStyle(
                            fontFamily: 'Space Grotesk',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.orangeAccent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),

              // Bottom Buttons
              Row(
                children: [
                  // Study Again Button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _restartSession,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: BorderSide(color: AppColors.surface2),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        'Study Again',
                        style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk'),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  
                  // Done Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: AppColors.background,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        'Done',
                        style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk'),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
