import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/vault_file_model.dart';
import '../../services/vault_service.dart';
import '../../widgets/file_card.dart';
import '../../theme/colors.dart';
import 'pdf_viewer_screen.dart';
import 'flashcards_screen.dart';
import 'notes_generator_screen.dart';

class FolderScreen extends StatefulWidget {
  final String subject;

  const FolderScreen({super.key, required this.subject});

  @override
  State<FolderScreen> createState() => _FolderScreenState();
}

class _FolderScreenState extends State<FolderScreen> {
  final VaultService _vaultService = VaultService();

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? 'dev_user';

  void _viewFile(BuildContext context, VaultFileModel file) {
    final ext = file.name.split('.').last.toLowerCase();
    if (ext == 'pdf') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PdfViewerScreen(file: file),
        ),
      );
    } else if (['png', 'jpg', 'jpeg', 'gif'].contains(ext)) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  color: AppColors.background,
                  child: file.downloadUrl.startsWith('file://')
                      ? Image.file(
                          File(file.storageRef),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Text(
                                'Failed to load local image.',
                                style: TextStyle(color: AppColors.error),
                              ),
                            );
                          },
                        )
                      : Image.network(
                          file.downloadUrl,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Padding(
                              padding: EdgeInsets.all(32.0),
                              child: CircularProgressIndicator(color: AppColors.accentDefault),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Text(
                                'Failed to load image preview.',
                                style: TextStyle(color: AppColors.error),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Visual previews are only supported for PDFs and Images.'),
          backgroundColor: AppColors.accentDefault,
        ),
      );
    }
  }

  void _deleteFile(VaultFileModel file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Delete File?', style: TextStyle(color: AppColors.textPrimary, fontFamily: 'Playfair Display')),
        content: Text('Are you sure you want to delete ${file.name}?', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: Text('Delete', style: TextStyle(color: AppColors.error)),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleting ${file.name}...'),
            backgroundColor: AppColors.accentDefault,
            duration: const Duration(seconds: 1),
          ),
        );
      }
      await _vaultService.deleteFile(file, _uid);
    }
  }

  void _showUploadBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return _UploadBottomSheet(
              subject: widget.subject,
              uid: _uid,
              onComplete: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Uploaded ✓'),
                    backgroundColor: AppColors.accentDefault,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.subject,
          style: TextStyle(
            fontFamily: 'Playfair Display',
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.auto_awesome, color: AppColors.textPrimary),
            tooltip: 'AI Notes Generator',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => NotesGeneratorScreen(subject: widget.subject),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.style, color: AppColors.textPrimary),
            tooltip: 'Flashcards',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => FlashcardsScreen(subject: widget.subject),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<VaultFileModel>>(
        stream: _vaultService.getFiles(_uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: AppColors.accentDefault));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading files: ${snapshot.error}', style: TextStyle(color: AppColors.error)));
          }

          final allFiles = snapshot.data ?? [];
          final filteredFiles = allFiles.where((f) => f.subject == widget.subject).toList();

          if (filteredFiles.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open_outlined, size: 64, color: AppColors.textSecondary),
                  SizedBox(height: 16),
                  Text(
                    'Folder is empty',
                    style: TextStyle(
                      fontFamily: 'Playfair Display',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Upload study items to this subject vault',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _showUploadBottomSheet,
                    icon: Icon(Icons.cloud_upload_outlined, color: AppColors.background),
                    label: Text('Upload File', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Playfair Display')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentDefault,
                      foregroundColor: AppColors.background,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredFiles.length,
            itemBuilder: (context, index) {
              final file = filteredFiles[index];
              return FileCard(
                file: file,
                onView: () => _viewFile(context, file),
                onDelete: () => _deleteFile(file),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showUploadBottomSheet,
        backgroundColor: AppColors.accentDefault,
        foregroundColor: AppColors.background,
        child: Icon(Icons.add),
      ),
    );
  }
}

class _UploadBottomSheet extends StatefulWidget {
  final String subject;
  final String uid;
  final VoidCallback onComplete;

  const _UploadBottomSheet({
    required this.subject,
    required this.uid,
    required this.onComplete,
  });

  @override
  State<_UploadBottomSheet> createState() => _UploadBottomSheetState();
}

class _UploadBottomSheetState extends State<_UploadBottomSheet> {
  File? _pickedFile;
  String _selectedSubject = 'Physics';
  String _selectedFileType = 'Notes';
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  final List<String> _subjects = ['Physics', 'Chemistry', 'Maths', 'Biology', 'General'];
  final List<String> _fileTypes = ['Notes', 'PDFs', 'Sample Papers'];

  @override
  void initState() {
    super.initState();
    // Default subject to current folder's subject
    if (_subjects.contains(widget.subject)) {
      _selectedSubject = widget.subject;
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'png', 'jpg', 'jpeg'],
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _pickedFile = File(result.files.single.path!);
      });
    }
  }

  void _upload() async {
    if (_pickedFile == null) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      await VaultService().uploadFile(
        _pickedFile!,
        _selectedSubject,
        _selectedFileType,
        widget.uid,
        onProgress: (progress) {
          setState(() {
            _uploadProgress = progress;
          });
        },
      );
      if (!mounted) return;
      widget.onComplete();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Text(
              'Upload to Vault',
              style: TextStyle(
                fontFamily: 'Playfair Display',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          SizedBox(height: 24),

          // File Picker Row / Selector
          if (_pickedFile == null)
            GestureDetector(
              onTap: _isUploading ? null : _pickFile,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surface2, style: BorderStyle.solid),
                ),
                child: Column(
                  children: [
                    Icon(Icons.cloud_upload_outlined, size: 40, color: AppColors.accentDefault),
                    SizedBox(height: 12),
                    Text(
                      'Tap to choose document',
                      style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Supports PDF, DOC, DOCX, PNG, JPG',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surface2),
              ),
              child: Row(
                children: [
                  Icon(Icons.insert_drive_file, color: AppColors.accentDefault),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _pickedFile!.path.split(Platform.pathSeparator).last,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!_isUploading)
                    IconButton(
                      icon: Icon(Icons.clear, color: AppColors.textSecondary),
                      onPressed: () => setState(() => _pickedFile = null),
                    ),
                ],
              ),
            ),
          SizedBox(height: 20),

          // Subject selection Dropdown
          Text(
            'Subject Group',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 13),
          ),
          SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.background,
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
                onChanged: _isUploading
                    ? null
                    : (val) {
                        if (val != null) setState(() => _selectedSubject = val);
                      },
              ),
            ),
          ),
          SizedBox(height: 20),

          // File Type Chips
          Text(
            'Document Category',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 13),
          ),
          SizedBox(height: 8),
          Row(
            children: _fileTypes.map((type) {
              final isSelected = _selectedFileType == type;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(
                    type,
                    style: TextStyle(
                      color: isSelected ? AppColors.background : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppColors.accentDefault,
                  backgroundColor: AppColors.background,
                  onSelected: _isUploading
                      ? null
                      : (selected) {
                          if (selected) setState(() => _selectedFileType = type);
                        },
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 24),

          // Upload button / progress indicators
          if (_isUploading) ...[
            LinearProgressIndicator(
              value: _uploadProgress,
              backgroundColor: AppColors.background,
              color: AppColors.accentDefault,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            SizedBox(height: 12),
            Center(
              child: Text(
                'Uploading... ${(_uploadProgress * 100).toInt()}%',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ] else
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _pickedFile == null ? null : _upload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentDefault,
                  disabledBackgroundColor: AppColors.surface2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Upload',
                  style: TextStyle(
                    color: AppColors.background,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontFamily: 'Playfair Display',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}