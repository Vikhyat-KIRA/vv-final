import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/vault_service.dart';
import '../services/gemini_service.dart';
import '../theme/colors.dart';
import 'glass_card.dart';
class ExamCountdownCard extends StatefulWidget {
  final Color accentColor;

  const ExamCountdownCard({
    super.key,
    required this.accentColor,
  });

  @override
  State<ExamCountdownCard> createState() => _ExamCountdownCardState();
}

class _ExamCountdownCardState extends State<ExamCountdownCard> {
  String? _examName;
  DateTime? _examDate;
  DateTime? _examStartDate;
  String? _examTimetablePath;
  bool _isUploadingTimetable = false;

  @override
  void initState() {
    super.initState();
    _loadExamDetails();
  }

  Future<void> _loadExamDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final examName = prefs.getString('exam_name');
    final examDateStr = prefs.getString('exam_date');
    final examStartDateStr = prefs.getString('exam_start_date');
    final examTimetablePath = prefs.getString('exam_timetable_path');

    if (examName != null && examDateStr != null) {
      setState(() {
        _examName = examName;
        _examDate = DateTime.tryParse(examDateStr);
        _examStartDate = examStartDateStr != null ? DateTime.tryParse(examStartDateStr) : DateTime.now();
        _examTimetablePath = examTimetablePath;
      });
    }
  }

  Future<void> _setExamDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (pickedDate != null) {
      if (!mounted) return;
      final textController = TextEditingController(text: 'Term Finals');
      final name = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text('Enter Exam Name'),
          content: TextField(
            controller: textController,
            decoration: const InputDecoration(labelText: 'Exam Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(''),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(textController.text.trim()),
              child: Text('Save'),
            ),
          ],
        ),
      );

      if (name != null && name.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final now = DateTime.now();
        await prefs.setString('exam_name', name);
        await prefs.setString('exam_date', pickedDate.toIso8601String());
        await prefs.setString('exam_start_date', now.toIso8601String());

        setState(() {
          _examName = name;
          _examDate = pickedDate;
          _examStartDate = now;
        });
      }
    }
  }

  Future<void> _editExamName() async {
    final textController = TextEditingController(text: _examName);
    if (!mounted) return;
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Edit Exam Name'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(labelText: 'Exam Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(''),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(textController.text.trim()),
            child: Text('Save'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('exam_name', name);
      setState(() {
        _examName = name;
      });
    }
  }

  Future<void> _uploadTimetable() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() {
      _isUploadingTimetable = true;
    });

    try {
      final file = File(pickedFile.path);
      final bytes = await file.readAsBytes();
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString('user_id') ?? 'local_user';

      // 1. Upload to Vault
      await VaultService().uploadFile(file, 'Timetable', 'image', uid);

      // 2. Analyze with Gemini
      final responseText = await GeminiService.instance.analyzeExamTimetable(bytes);
      
      // 3. Parse Urgency
      String urgency = 'normal';
      final lowerResp = responseText.toLowerCase();
      if (lowerResp.contains('critical')) {
        urgency = 'critical';
      } else if (lowerResp.contains('high')) {
        urgency = 'high';
      } else if (lowerResp.contains('calm')) {
        urgency = 'calm';
      }

      await prefs.setString('user_urgency', urgency);
      await prefs.setString('exam_timetable_path', pickedFile.path);
      
      // Invalidate system prompt cache so urgency update takes effect
      GeminiService.instance.invalidatePromptCache();

      if (mounted) {
        setState(() {
          _examTimetablePath = pickedFile.path;
          _isUploadingTimetable = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Timetable analyzed! Urgency level set to: $urgency')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingTimetable = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to process timetable: $e')),
        );
      }
    }
  }

  Widget _buildCountdownBlock(String value, String label, BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.surface.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
          ),
          child: Text(
            value,
            style: textTheme.displayLarge?.copyWith(
              fontSize: 28,
              height: 1.0,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontSize: 10,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildCountdownTimer(Duration remaining, BuildContext context) {
    if (remaining.isNegative) remaining = Duration.zero;
    final days = remaining.inDays.toString().padLeft(2, '0');
    final hours = (remaining.inHours % 24).toString().padLeft(2, '0');
    final minutes = (remaining.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    final sepColor = Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5);

    Widget sep = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Text(':', style: Theme.of(context).textTheme.displayLarge?.copyWith(
        fontSize: 24, 
        color: sepColor,
        height: 1.0,
      )),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCountdownBlock(days, 'Days', context),
        sep,
        _buildCountdownBlock(hours, 'Hrs', context),
        sep,
        _buildCountdownBlock(minutes, 'Min', context),
        sep,
        _buildCountdownBlock(seconds, 'Sec', context),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_examName == null || _examDate == null) {
      return GlassCard(
        elevation: CardElevation.elevated,
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text('No exam scheduled', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _setExamDate,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.accentColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Set Exam Date', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    final totalDuration = _examDate!.difference(_examStartDate!);
    final elapsedDuration = DateTime.now().difference(_examStartDate!);
    final double progress = totalDuration.inSeconds > 0 
        ? (elapsedDuration.inSeconds / totalDuration.inSeconds).clamp(0.0, 1.0) 
        : 1.0;

    return GlassCard(
      elevation: CardElevation.elevated,
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _examName!,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit_outlined, size: 18, color: colorScheme.onSurfaceVariant),
                onPressed: _editExamName,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Live Countdown Stream Builder
          StreamBuilder<int>(
            stream: Stream<int>.periodic(const Duration(seconds: 1), (x) => x),
            builder: (context, snapshot) {
              final remaining = _examDate!.difference(DateTime.now());
              return _buildCountdownTimer(remaining, context);
            },
          ),
          const SizedBox(height: 24),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: colorScheme.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(widget.accentColor),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Preparation Timeline', style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
              Text('${(progress * 100).toInt()}% Elapsed', style: textTheme.bodySmall?.copyWith(color: widget.accentColor, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (_isUploadingTimetable)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else if (_examTimetablePath != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(_examTimetablePath!),
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Icon(Icons.calendar_today, size: 24, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Text('Exam Timetable', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface)),
                ],
              ),
              TextButton.icon(
                onPressed: _isUploadingTimetable ? null : _uploadTimetable,
                icon: const Icon(Icons.upload_file, size: 18),
                label: const Text('Upload'),
                style: TextButton.styleFrom(
                  foregroundColor: widget.accentColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
