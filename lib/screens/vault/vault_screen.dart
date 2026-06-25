import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/colors.dart';
import '../../providers/theme_provider.dart';
import '../../models/vault_file_model.dart';
import '../../services/vault_service.dart';
import 'folder_screen.dart';

class VaultScreen extends ConsumerStatefulWidget {
  const VaultScreen({super.key});

  @override
  ConsumerState<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends ConsumerState<VaultScreen> {
  final VaultService _vaultService = VaultService();
  int _selectedFilterIndex = 0;

  final List<String> _filterOptions = ['All', 'Notes', 'PDFs', 'Sample Papers'];
  final List<String> _defaultSubjects = ['Physics', 'Chemistry', 'Maths', 'Biology', 'General'];
  List<String> _customFolders = [];

  static const _customFoldersKey = 'vault_custom_folders';

  List<String> get _allSubjects => [..._defaultSubjects, ..._customFolders];

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? 'dev_user';

  @override
  void initState() {
    super.initState();
    _loadCustomFolders();
  }

  Future<void> _loadCustomFolders() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_customFoldersKey);
    if (jsonStr != null) {
      final List<dynamic> decoded = json.decode(jsonStr);
      setState(() {
        _customFolders = decoded.cast<String>();
      });
    }
  }

  Future<void> _saveCustomFolders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customFoldersKey, json.encode(_customFolders));
  }

  Future<void> _addCustomFolder(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    // Prevent duplicates (case-insensitive check against all subjects)
    final allLower = _allSubjects.map((s) => s.toLowerCase()).toSet();
    if (allLower.contains(trimmed.toLowerCase())) return;

    setState(() {
      _customFolders.add(trimmed);
    });
    await _saveCustomFolders();
  }

  Future<void> _deleteCustomFolder(String name) async {
    setState(() {
      _customFolders.remove(name);
    });
    await _saveCustomFolders();
  }

  void _showCreateFolderSheet(Color accent) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'New Folder',
                style: TextStyle(
                  fontFamily: 'Playfair Display',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                style: TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Enter folder name',
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: accent, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                textCapitalization: TextCapitalization.words,
                onSubmitted: (value) {
                  _addCustomFolder(value);
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _addCustomFolder(controller.text);
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Create Folder',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(String folderName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Folder',
          style: TextStyle(color: AppColors.textPrimary, fontFamily: 'Playfair Display'),
        ),
        content: Text(
          'Are you sure you want to delete "$folderName"? Files inside will not be deleted.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              _deleteCustomFolder(folderName);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  double _calculateStorageUsed(List<VaultFileModel> files) {
    final totalBytes = files.fold(0, (sum, file) => sum + file.sizeBytes);
    return totalBytes / (1024 * 1024); // Convert to MB
  }

  int _getFileCount(List<VaultFileModel> files, String subject) {
    final category = _filterOptions[_selectedFilterIndex];
    return files.where((file) {
      final matchesSubject = file.subject == subject;
      if (!matchesSubject) return false;
      if (category == 'All') return true;
      return file.fileType == category;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final accent = ref.watch(themeProvider);
    final allSubjects = _allSubjects;

    return StreamBuilder<List<VaultFileModel>>(
      stream: _vaultService.getFiles(_uid),
      builder: (context, snapshot) {
        final files = snapshot.data ?? [];
        final storageUsed = _calculateStorageUsed(files);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'The Vault',
                  style: TextStyle(
                    fontFamily: 'Playfair Display',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '${storageUsed.toStringAsFixed(1)} MB used',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showCreateFolderSheet(accent),
            backgroundColor: accent,
            child: const Icon(Icons.create_new_folder_outlined, color: Colors.white),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 8),

              // Filter selector with sliding underline animation
              _FilterSelector(
                options: _filterOptions,
                selectedIndex: _selectedFilterIndex,
                accent: accent,
                onTap: (index) {
                  setState(() {
                    _selectedFilterIndex = index;
                  });
                },
              ),
              SizedBox(height: 16),

              // Folders GridView
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 80),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.25,
                  ),
                  itemCount: allSubjects.length,
                  itemBuilder: (context, index) {
                    final subject = allSubjects[index];
                    final isCustom = _customFolders.contains(subject);
                    final fileCount = _getFileCount(files, subject);
                    return _SubjectFolderCard(
                      subject: subject,
                      fileCount: fileCount,
                      accent: accent,
                      isCustom: isCustom,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => FolderScreen(subject: subject),
                          ),
                        );
                      },
                      onLongPress: isCustom ? () => _showDeleteConfirmation(subject) : null,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterSelector extends StatelessWidget {
  final List<String> options;
  final int selectedIndex;
  final Color accent;
  final ValueChanged<int> onTap;

  const _FilterSelector({
    required this.options,
    required this.selectedIndex,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(options.length, (index) {
              final isSelected = selectedIndex == index;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(index),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Text(
                      options[index],
                      style: TextStyle(
                        color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          // Underline tracker
          AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: Alignment(
              -1.0 + (selectedIndex * (2.0 / (options.length - 1))),
              1.0,
            ),
            child: FractionallySizedBox(
              widthFactor: 1.0 / options.length,
              child: Container(
                height: 3,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectFolderCard extends StatelessWidget {
  final String subject;
  final int fileCount;
  final Color accent;
  final bool isCustom;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _SubjectFolderCard({
    required this.subject,
    required this.fileCount,
    required this.accent,
    required this.onTap,
    this.isCustom = false,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.surface2),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCustom ? Icons.folder_special : Icons.folder,
                color: accent,
                size: 24,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject,
                  style: TextStyle(
                    fontFamily: 'Playfair Display',
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '$fileCount ${fileCount == 1 ? "file" : "files"}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

