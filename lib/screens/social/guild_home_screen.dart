import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/guild_model.dart';
import '../../models/user_model.dart';
import '../../models/vault_file_model.dart';
import '../../services/guild_service.dart';
import '../../services/vault_service.dart';
import '../../services/firestore_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/colors.dart';
import '../../widgets/empty_state.dart';

class GuildHomeScreen extends ConsumerStatefulWidget {
  final String guildId;

  const GuildHomeScreen({
    super.key,
    required this.guildId,
  });

  @override
  ConsumerState<GuildHomeScreen> createState() => _GuildHomeScreenState();
}

class _GuildHomeScreenState extends ConsumerState<GuildHomeScreen> {
  GuildModel? _guild;
  bool _isLoading = true;
  String _errorMessage = '';

  // Chat Tab controllers
  final TextEditingController _chatController = TextEditingController();

  // Notes Tab uploading state
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _loadGuildDetails();
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  Future<void> _loadGuildDetails() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('guilds').doc(widget.guildId).get();
      if (doc.exists) {
        setState(() {
          _guild = GuildModel.fromFirestore(doc);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Guild not found.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading guild: $e';
        _isLoading = false;
      });
    }
  }

  void _showInviteCodeDialog(String code) {
    showDialog(
      context: context,
      builder: (ctx) {
        final accent = ref.watch(themeProvider);
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppColors.border),
          ),
          title: const Text(
            'Invite Code',
            style: TextStyle(fontFamily: 'Playfair Display', fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Share this code with others to join:',
                style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Plus Jakarta Sans', fontSize: 13),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  code,
                  style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3.0,
                    color: accent,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied invite code to clipboard!')),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 14),
                label: const Text('Copy Code'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surface2,
                  foregroundColor: AppColors.textPrimary,
                  elevation: 0,
                  side: BorderSide(color: AppColors.border),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickAndUploadGuildFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.single.path == null) return;

    final file = File(result.files.single.path!);
    final filename = result.files.single.name;
    final ext = filename.split('.').last.toLowerCase();
    
    String fileType = 'other';
    if (ext == 'pdf') {
      fileType = 'pdf';
    } else if (ext == 'png' || ext == 'jpg' || ext == 'jpeg') {
      fileType = 'image';
    } else if (ext == 'doc' || ext == 'docx' || ext == 'txt') {
      fileType = 'doc';
    }

    final currentUid = ref.read(authProvider)?.uid;
    if (currentUid == null) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      await VaultService().uploadGuildFile(
        file,
        widget.guildId,
        fileType,
        currentUid,
        onProgress: (prog) {
          setState(() {
            _uploadProgress = prog;
          });
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File shared to guild successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = ref.watch(themeProvider);
    final currentUser = ref.watch(authProvider);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(accent))),
      );
    }

    if (_errorMessage.isNotEmpty || _guild == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text(_errorMessage.isNotEmpty ? _errorMessage : 'Guild not found.')),
      );
    }

    final isAdmin = _guild!.createdBy == currentUser?.uid;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _guild!.name,
                style: const TextStyle(
                  fontFamily: 'Playfair Display',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                '${_guild!.memberIds.length} Members • ${_guild!.subjectFocus}',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
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
            onPressed: () => context.pop(),
          ),
          actions: [
            if (isAdmin)
              IconButton(
                icon: Icon(Icons.share_rounded, color: AppColors.textPrimary),
                onPressed: () => _showInviteCodeDialog(_guild!.inviteCode),
              ),
            const SizedBox(width: 8),
          ],
          bottom: TabBar(
            indicatorColor: accent,
            labelColor: accent,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(text: 'Chat'),
              Tab(text: 'Members'),
              Tab(text: 'Notes'),
              Tab(text: 'Ranks'),
            ],
          ),
        ),
        body: Column(
          children: [
            if (_isUploading)
              LinearProgressIndicator(
                value: _uploadProgress,
                valueColor: AlwaysStoppedAnimation<Color>(accent),
                backgroundColor: AppColors.surface2,
              ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildChatTab(currentUser, accent),
                  _buildMembersTab(accent),
                  _buildNotesTab(currentUser, accent),
                  _buildLeaderboardTab(accent),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 1: CHAT ---
  Widget _buildChatTab(UserModel? user, Color accent) {
    if (user == null) return const SizedBox();

    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: GuildService().getGuildMessages(widget.guildId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(accent)));
              }
              if (snapshot.hasError) {
                return const Center(child: Text('Error loading chat messages.'));
              }

              final docs = snapshot.data?.docs ?? [];

              if (docs.isEmpty) {
                return Center(
                  child: Text(
                    'No messages yet. Send a message to start!',
                    style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Plus Jakarta Sans'),
                  ),
                );
              }

              return ListView.builder(
                reverse: true,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final senderId = data['senderId'] ?? '';
                  final text = data['text'] ?? '';
                  final senderUsername = data['senderUsername'] ?? 'learner';
                  final isMe = senderId == user.uid;

                  // Parse timestamp
                  final tsVal = data['timestamp'];
                  DateTime ts = DateTime.now();
                  if (tsVal is Timestamp) {
                    ts = tsVal.toDate();
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Column(
                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        if (!isMe)
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 3),
                            child: Text(
                              '@$senderUsername',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isMe ? accent : AppColors.surface2,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                              bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                            ),
                            border: !isMe
                                ? Border(left: BorderSide(color: accent, width: 3))
                                : null,
                          ),
                          child: Text(
                            text,
                            style: TextStyle(
                              color: isMe ? Colors.white : AppColors.textPrimary,
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          DateFormat('hh:mm a').format(ts),
                          style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
        // Chat input bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _chatController,
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Message guild...',
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendChatMessage(user),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => _sendChatMessage(user),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: accent,
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _sendChatMessage(UserModel user) async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    _chatController.clear();
    await GuildService().sendGuildMessage(widget.guildId, user.uid, text, user.username);
  }

  // --- TAB 2: MEMBERS ---
  Widget _buildMembersTab(Color accent) {
    // Stream changes to guild to dynamically update members list
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('guilds').doc(widget.guildId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(accent)));
        }

        final gData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final memberIds = List<String>.from(gData['memberIds'] ?? []);
        final creatorId = gData['createdBy'] ?? '';

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: memberIds.length,
          separatorBuilder: (context, index) => Divider(color: AppColors.border, height: 1),
          itemBuilder: (context, index) {
            final memberId = memberIds[index];
            return FutureBuilder<DocumentSnapshot>(
              future: FirestoreService().getUserData(memberId),
              builder: (context, uSnap) {
                if (uSnap.connectionState == ConnectionState.waiting) {
                  return const ListTile(
                    title: Text('Loading...', style: TextStyle(fontSize: 14)),
                  );
                }

                final uData = uSnap.data?.data() as Map<String, dynamic>?;
                if (uData == null) {
                  return const ListTile(
                    title: Text('Learner'),
                  );
                }

                final profile = uData['profile'] as Map<String, dynamic>? ?? {};
                final metrics = uData['metrics'] as Map<String, dynamic>? ?? {};

                final displayName = profile['name'] ?? 'Learner';
                final username = profile['username'] ?? 'learner';
                final grade = profile['grade'] ?? '';
                final xp = metrics['xp'] ?? 0;
                final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'L';

                final isCreator = memberId == creatorId;

                // Pick avatar bg color dynamically
                final avatarColors = [
                  const Color(0xFF34D399),
                  const Color(0xFF60A5FA),
                  const Color(0xFFF59E0B),
                  const Color(0xFFEF4444),
                  const Color(0xFFEC4899),
                  const Color(0xFF8B5CF6),
                ];
                final avatarBgColor = avatarColors[displayName.hashCode % avatarColors.length];

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  leading: CircleAvatar(
                    backgroundColor: avatarBgColor,
                    child: Text(
                      initial,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Playfair Display'),
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(
                        displayName,
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (isCreator)
                        Icon(Icons.workspace_premium_rounded, color: Colors.amber[700], size: 16),
                    ],
                  ),
                  subtitle: Row(
                    children: [
                      Text(
                        '@$username',
                        style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 12, color: AppColors.textSecondary),
                      ),
                      if (grade.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          '• $grade',
                          style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                  trailing: Text(
                    '$xp XP',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.bold,
                      color: accent,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // --- TAB 3: NOTES ---
  Widget _buildNotesTab(UserModel? user, Color accent) {
    if (user == null) return const SizedBox();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<List<VaultFileModel>>(
        stream: VaultService().getGuildFiles(widget.guildId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(accent)));
          }

          final files = snapshot.data ?? [];

          if (files.isEmpty) {
            return EmptyState(
              icon: Icons.note_add_outlined,
              title: 'No shared notes yet',
              subtitle: 'Share study guides, PDFs, or summaries with your guild members.',
              ctaLabel: 'Upload File',
              onCta: _pickAndUploadGuildFile,
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];
              return _buildFileCard(file, accent);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'guild_notes_fab',
        onPressed: _pickAndUploadGuildFile,
        backgroundColor: accent,
        foregroundColor: AppColors.background,
        child: const Icon(Icons.upload_file_rounded),
      ),
    );
  }

  Widget _buildFileCard(VaultFileModel file, Color accent) {
    IconData icon;
    Color iconColor;

    if (file.fileType == 'pdf') {
      icon = Icons.picture_as_pdf_rounded;
      iconColor = Colors.redAccent;
    } else if (file.fileType == 'image') {
      icon = Icons.image_rounded;
      iconColor = Colors.blueAccent;
    } else if (file.fileType == 'doc') {
      icon = Icons.description_rounded;
      iconColor = Colors.teal;
    } else {
      icon = Icons.insert_drive_file_rounded;
      iconColor = AppColors.textSecondary;
    }

    final double sizeMb = file.sizeBytes / (1024 * 1024);

    return InkWell(
      onTap: () async {
        final uri = Uri.parse(file.downloadUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not open file URL.')),
            );
          }
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 28),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _confirmDeleteFile(file),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${sizeMb.toStringAsFixed(2)} MB',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 11,
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

  void _confirmDeleteFile(VaultFileModel file) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Delete File'),
          content: Text('Are you sure you want to delete ${file.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await VaultService().deleteGuildFile(file, widget.guildId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('File deleted.')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // --- TAB 4: LEADERBOARD ---
  Widget _buildLeaderboardTab(Color accent) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('guilds').doc(widget.guildId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(accent)));
        }

        final gData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final memberIds = List<String>.from(gData['memberIds'] ?? []);

        // Load all profiles, sort them, and render
        return FutureBuilder<List<UserModel>>(
          future: _fetchGuildUsers(memberIds),
          builder: (context, uListSnap) {
            if (uListSnap.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(accent)));
            }

            final members = uListSnap.data ?? [];
            // Sort by XP descending
            members.sort((a, b) => b.xp.compareTo(a.xp));

            if (members.isEmpty) {
              return const Center(child: Text('No members found.'));
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: members.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final user = members[index];
                final rank = index + 1;

                Color? tileBgColor;
                Widget? rankIcon;

                if (rank == 1) {
                  tileBgColor = AppColors.surface2;
                  rankIcon = const Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 24);
                } else if (rank == 2) {
                  rankIcon = const Icon(Icons.workspace_premium_rounded, color: Colors.grey, size: 24);
                } else if (rank == 3) {
                  rankIcon = const Icon(Icons.workspace_premium_rounded, color: Colors.brown, size: 24);
                } else {
                  rankIcon = CircleAvatar(
                    radius: 12,
                    backgroundColor: AppColors.surface2,
                    child: Text(
                      '$rank',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                }

                final initial = user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'L';
                final avatarColors = [
                  const Color(0xFF34D399),
                  const Color(0xFF60A5FA),
                  const Color(0xFFF59E0B),
                  const Color(0xFFEF4444),
                  const Color(0xFFEC4899),
                  const Color(0xFF8B5CF6),
                ];
                final avatarBgColor = avatarColors[user.displayName.hashCode % avatarColors.length];

                return Container(
                  decoration: BoxDecoration(
                    color: tileBgColor ?? AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: rank == 1 ? accent.withAlpha(80) : AppColors.border,
                      width: rank == 1 ? 1.5 : 1.0,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(width: 32, child: Center(child: rankIcon)),
                        const SizedBox(width: 12),
                        CircleAvatar(
                          backgroundColor: avatarBgColor,
                          child: Text(
                            initial,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Playfair Display'),
                          ),
                        ),
                      ],
                    ),
                    title: Text(
                      user.displayName,
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      '@${user.username}',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    trailing: Text(
                      '${user.xp} XP',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.bold,
                        color: accent,
                        fontSize: 15,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<List<UserModel>> _fetchGuildUsers(List<String> userIds) async {
    final List<UserModel> list = [];
    for (final uid in userIds) {
      try {
        final doc = await FirestoreService().getUserData(uid);
        if (doc.exists) {
          final data = doc.data();
          final profile = data?['profile'] as Map<String, dynamic>? ?? {};
          final metrics = data?['metrics'] as Map<String, dynamic>? ?? {};
          
          list.add(UserModel(
            uid: uid,
            email: '',
            displayName: profile['name'] ?? 'Learner',
            photoUrl: profile['photoUrl'] ?? 'https://api.dicebear.com/7.x/bottts/svg?seed=$uid',
            level: metrics['level'] ?? 1,
            xp: metrics['xp'] ?? 0,
            enrolledSubjects: List<String>.from(profile['enrolledSubjects'] ?? []),
            username: profile['username'] ?? '',
            grade: profile['grade'] ?? '',
            board: profile['board'] ?? '',
          ));
        }
      } catch (e) {
        debugPrint('Error fetching user data in leaderboard: $e');
      }
    }
    return list;
  }
}
