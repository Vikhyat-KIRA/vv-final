import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/vault_file_model.dart';
import '../../services/notes_service.dart';
import '../../theme/colors.dart';
import '../../providers/theme_provider.dart';
import '../flashcards/ai_deck_screen.dart';

class PdfViewerScreen extends ConsumerStatefulWidget {
  final VaultFileModel file;

  const PdfViewerScreen({super.key, required this.file});

  @override
  ConsumerState<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends ConsumerState<PdfViewerScreen> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  int _currentPage = 1;
  int _pageCount = 0;
  bool _isLoading = true;

  Future<void> _generateNotes() async {
    // 1. Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.accentDefault),
                SizedBox(height: 20),
                Text(
                  'Vayu is reading...',
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Extracting content and synthesizing notes.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      // Load user preferences for grade and board
      final prefs = await SharedPreferences.getInstance();
      final grade = prefs.getString('user_grade') ?? 'Class 10';
      final board = prefs.getString('user_board') ?? 'CBSE';

      // 2. Extract PDF text
      final rawText = await NotesService().extractTextFromPdf(widget.file.downloadUrl);

      // 3. Generate notes
      final notes = await NotesService().generateNotes(rawText, grade, board);

      // 4. Dismiss loading dialog
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // 5. Present GeneratedNotesSheet
      if (mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) {
            return _GeneratedNotesSheet(
              notes: notes,
              file: widget.file,
              grade: grade,
              board: board,
            );
          },
        );
      }
    } catch (e) {
      // Dismiss loading dialog on failure
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating notes: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.file.name,
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              _pageCount > 0 ? 'Page $_currentPage of $_pageCount' : 'Loading document...',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          widget.file.downloadUrl.startsWith('file://')
              ? SfPdfViewer.file(
                  File(widget.file.storageRef),
                  controller: _pdfViewerController,
                  onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                    setState(() {
                      _pageCount = details.document.pages.count;
                      _isLoading = false;
                    });
                  },
                  onPageChanged: (PdfPageChangedDetails details) {
                    setState(() {
                      _currentPage = details.newPageNumber;
                    });
                  },
                )
              : SfPdfViewer.network(
                  widget.file.downloadUrl,
                  controller: _pdfViewerController,
                  onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                    setState(() {
                      _pageCount = details.document.pages.count;
                      _isLoading = false;
                    });
                  },
                  onPageChanged: (PdfPageChangedDetails details) {
                    setState(() {
                      _currentPage = details.newPageNumber;
                    });
                  },
                ),
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(
                color: AppColors.accentDefault,
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _generateNotes,
        backgroundColor: AppColors.accentDefault,
        foregroundColor: AppColors.background,
        icon: Icon(Icons.psychology),
        label: Text(
          'Generate AI Notes',
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk'),
        ),
      ),
    );
  }
}

class _GeneratedNotesSheet extends ConsumerStatefulWidget {
  final String notes;
  final VaultFileModel file;
  final String grade;
  final String board;

  const _GeneratedNotesSheet({
    required this.notes,
    required this.file,
    required this.grade,
    required this.board,
  });

  @override
  ConsumerState<_GeneratedNotesSheet> createState() => _GeneratedNotesSheetState();
}

class _GeneratedNotesSheetState extends ConsumerState<_GeneratedNotesSheet> {
  bool _isSaving = false;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? 'dev_user';

  Future<void> _saveNotes() async {
    setState(() {
      _isSaving = true;
    });

    try {
      await NotesService().saveNotes(_uid, widget.file.id, widget.notes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notes saved to Firestore ✓'),
            backgroundColor: AppColors.accentDefault,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save notes: $e'),
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

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 1.0,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pull Bar / Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'AI Study Notes',
                    style: TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: accent, width: 1),
                    ),
                    child: Text(
                      widget.file.subject,
                      style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: accent,
                      ),
                    ),
                  ),
                ],
              ),
              Divider(color: AppColors.surface2, height: 24),

              // Scrollable rich text notes
              Expanded(
                child: Markdown(
                  controller: scrollController,
                  data: widget.notes,
                  selectable: true,
                  styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                    h2: TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: accent,
                    ),
                    p: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      height: 1.6,
                    ),
                    listBullet: TextStyle(color: accent),
                    tableBody: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  ),
                ),
              ),
              Divider(color: AppColors.surface2, height: 24),

              // Action Buttons Row
              Row(
                children: [
                  // Save Button
                  Expanded(
                    child: _isSaving
                        ? Center(child: CircularProgressIndicator(color: AppColors.accentDefault))
                        : OutlinedButton.icon(
                            onPressed: _saveNotes,
                            icon: Icon(Icons.bookmark_border, size: 18),
                            label: Text('Save'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textPrimary,
                              side: BorderSide(color: AppColors.surface2),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                  ),
                  SizedBox(width: 8),

                  // Copy All Button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: widget.notes));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Notes copied to clipboard ✓'),
                            backgroundColor: AppColors.accentDefault,
                          ),
                        );
                      },
                      icon: Icon(Icons.copy, size: 18),
                      label: Text('Copy All'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: BorderSide(color: AppColors.surface2),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),

                  // Create Flashcards Button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Close bottom sheet first
                        Navigator.pop(context);
                        // Push AiDeckScreen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AiDeckScreen(prefilledText: widget.notes),
                          ),
                        );
                      },
                      icon: Icon(Icons.flash_on, size: 18, color: AppColors.background),
                      label: Text('Cards'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: AppColors.background,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
