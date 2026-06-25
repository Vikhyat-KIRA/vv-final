import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/guild_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/colors.dart';

class GuildCreateScreen extends ConsumerStatefulWidget {
  const GuildCreateScreen({super.key});

  @override
  ConsumerState<GuildCreateScreen> createState() => _GuildCreateScreenState();
}

class _GuildCreateScreenState extends ConsumerState<GuildCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _subjectFocus = 'Quantum Physics';
  bool _isOpen = true;
  bool _isCreating = false;

  final List<String> _subjects = [
    'Quantum Physics',
    'Machine Learning',
    'Linear Algebra',
    'Data Structures',
    'Organic Chemistry',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = ref.read(authProvider);
    if (currentUser == null) return;

    setState(() {
      _isCreating = true;
    });

    try {
      final guild = await GuildService().createGuild(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        subjectFocus: _subjectFocus,
        isOpen: _isOpen,
        uid: currentUser.uid,
      );

      if (mounted) {
        setState(() {
          _isCreating = false;
        });
        _showSuccessDialog(guild.inviteCode, guild.id);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create guild: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _showSuccessDialog(String inviteCode, String guildId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final accent = ref.watch(themeProvider);

        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppColors.border),
          ),
          title: Text(
            'Guild Created!',
            style: TextStyle(
              fontFamily: 'Playfair Display',
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Share this code with your classmates to invite them:',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Invite Code Monospace Container
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  inviteCode,
                  style: TextStyle(
                    fontFamily: 'Courier', // clean monospace fallback
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4.0,
                    color: accent,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: inviteCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Invite code copied to clipboard!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('Copy Invite Code'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surface2,
                  foregroundColor: AppColors.textPrimary,
                  elevation: 0,
                  side: BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // pop dialog
                  context.pushReplacement('/guilds/home/$guildId'); // replace screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text(
                  'Enter Guild Home',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Create a Guild',
          style: TextStyle(
            fontFamily: 'Playfair Display',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Guild Name Input
                Text(
                  'Guild Name',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'e.g. Quantum Pioneers',
                    hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    filled: true,
                    fillColor: AppColors.surface,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: accent),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.redAccent),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.redAccent),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Please enter a name.';
                    if (val.trim().length < 3) return 'Name must be at least 3 characters.';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // 2. Description Input
                Text(
                  'Description',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Describe the goals and focus of this guild.',
                    hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    filled: true,
                    fillColor: AppColors.surface,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: accent),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.redAccent),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.redAccent),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Please enter a description.';
                    if (val.trim().length < 10) return 'Description must be at least 10 characters.';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // 3. Subject Focus Dropdown
                Text(
                  'Subject Focus',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _subjectFocus,
                      isExpanded: true,
                      dropdownColor: AppColors.surface,
                      items: _subjects.map((sub) {
                        return DropdownMenuItem<String>(
                          value: sub,
                          child: Text(
                            sub,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 15,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _subjectFocus = val;
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 4. Access Settings SegmentedButton
                Text(
                  'Guild Privacy',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<bool>(
                  style: SegmentedButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    selectedBackgroundColor: accent,
                    selectedForegroundColor: AppColors.background,
                    foregroundColor: AppColors.textSecondary,
                  ),
                  segments: const [
                    ButtonSegment(
                      value: true,
                      label: Text('Open Guild'),
                      icon: Icon(Icons.lock_open_rounded),
                    ),
                    ButtonSegment(
                      value: false,
                      label: Text('Closed Guild'),
                      icon: Icon(Icons.lock_rounded),
                    ),
                  ],
                  selected: {_isOpen},
                  onSelectionChanged: (val) {
                    setState(() {
                      _isOpen = val.first;
                    });
                  },
                ),
                const SizedBox(height: 48),

                // 5. Submit Button
                ElevatedButton(
                  onPressed: _isCreating ? null : _handleCreate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: AppColors.background,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isCreating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Create Guild',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
