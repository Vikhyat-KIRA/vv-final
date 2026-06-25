import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'gemini_service.dart';

class NotesService {
  static final NotesService _instance = NotesService._internal();
  factory NotesService() => _instance;
  NotesService._internal();

  /// Downloads and extracts text from a PDF document page-by-page
  Future<String> extractTextFromPdf(String downloadUrl) async {
    try {
      final response = await http.get(Uri.parse(downloadUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download PDF: HTTP ${response.statusCode}');
      }
      final pdfBytes = response.bodyBytes;
      final PdfDocument doc = PdfDocument(inputBytes: pdfBytes);
      final StringBuffer buffer = StringBuffer();
      
      for (int i = 0; i < doc.pages.count; i++) {
        final text = PdfTextExtractor(doc).extractText(startPageIndex: i, endPageIndex: i);
        buffer.write(text);
      }
      
      String textResult = buffer.toString().trim();
      if (textResult.length > 12000) {
        textResult = '${textResult.substring(0, 12000)}...[truncated]';
      }
      
      doc.dispose();
      return textResult;
    } catch (e) {
      debugPrint('Error extracting text from PDF: $e');
      throw Exception('Failed to read PDF text: $e');
    }
  }

  /// Generates study notes in a specific format via GeminiService
  Future<String> generateNotes(String text, String grade, String board) async {
    final prompt = 'You are a brilliant study notes maker for a $grade $board student.\n'
        'Analyze this content and return study notes in EXACTLY this format:\n'
        '## Key Concepts\n'
        '## Important Definitions\n'
        '## Formulae / Key Data\n'
        '## Likely Exam Questions\n'
        'Be concise and exam-focused. Content: $text';

    try {
      final response = await GeminiService.instance.sendMessage(prompt);
      return response;
    } catch (e) {
      debugPrint('Error in generateNotes: $e');
      return 'Could not generate AI Notes. Please try again. Error: $e';
    }
  }

  /// Saves generated notes to Firestore under ai_notes/$uid/files/$fileId
  Future<void> saveNotes(String uid, String fileId, String notes) async {
    try {
      await FirebaseFirestore.instance
          .collection('ai_notes')
          .doc(uid)
          .collection('files')
          .doc(fileId)
          .set({
        'notes': notes,
        'generatedAt': Timestamp.now(),
        'fileId': fileId,
      }, SetOptions(merge: true));
    } on FirebaseException catch (e, stack) {
      debugPrint('FirebaseException in saveNotes: ${e.message}\n$stack');
      rethrow;
    } catch (e, stack) {
      debugPrint('Unknown error in saveNotes: $e\n$stack');
      rethrow;
    }
  }
}
