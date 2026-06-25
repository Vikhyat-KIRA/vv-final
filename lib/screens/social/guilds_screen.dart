import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/guild_model.dart';
import '../../services/guild_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/colors.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/error_state_widget.dart';
import '../../widgets/scale_dialog.dart';

class GuildsScreen extends ConsumerWidget {
  const GuildsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authProvider);
    final accent = ref.watch(themeProvider);

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Guilds', style: TextStyle(fontFamily: 'Playfair Display', fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.background,
        ),
        body: const Center(
          child: Text('Sign in to view guilds.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Study Guilds',
          style: TextStyle(
            fontFamily: 'Playfair Display',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: StreamBuilder<List<GuildModel>>(
        stream: GuildService().getMyGuilds(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.95,
              ),
              itemCount: 4,
              itemBuilder: (context, index) => const ShimmerSubjectCard(),
            );
          }

          if (snapshot.hasError) {
            return ErrorStateWidget(
              message: snapshot.error.toString(),
              onRetry: () => context.go('/guilds'),
            );
          }

          final guilds = snapshot.data ?? [];

          if (guilds.isEmpty) {
            return EmptyState(
              icon: Icons.group_work_outlined,
              title: 'Create or join a guild',
              subtitle: 'Collaborate with peers, share notes, and climb the leaderboard together.',
              ctaLabel: 'Join a Guild',
              onCta: () => _showJoinGuildDialog(context, currentUser.uid, accent),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.95,
            ),
            itemCount: guilds.length,
            itemBuilder: (context, index) {
              final guild = guilds[index];
              return _buildGuildCard(context, guild, accent);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showGuildOptionsBottomSheet(context, currentUser.uid, accent),
        backgroundColor: accent,
        foregroundColor: AppColors.background,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildGuildCard(BuildContext context, GuildModel guild, Color accent) {
    return InkWell(
      onTap: () => context.push('/guilds/home/${guild.id}'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  guild.name,
                  style: TextStyle(
                    fontFamily: 'Playfair Display',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    guild.subjectFocus,
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Icon(Icons.people_alt_rounded, size: 16, color: accent),
                const SizedBox(width: 6),
                Text(
                  '${guild.memberIds.length} Members',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showGuildOptionsBottomSheet(BuildContext context, String uid, Color accent) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Join or Create a Guild',
                  style: TextStyle(
                    fontFamily: 'Playfair Display',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push('/guilds/create');
                  },
                  icon: const Icon(Icons.create_new_folder_rounded),
                  label: const Text('Create a Guild'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: AppColors.background,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showJoinGuildDialog(context, uid, accent);
                  },
                  icon: const Icon(Icons.vpn_key_rounded),
                  label: const Text('Join with Code'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showJoinGuildDialog(BuildContext context, String uid, Color accent) {
    final codeController = TextEditingController();
    GuildModel? foundGuild;
    bool isSearching = false;
    bool searchAttempted = false;
    String errorMessage = '';

    showScaleDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: AppColors.border),
              ),
              title: Text(
                'Join Study Guild',
                style: TextStyle(
                  fontFamily: 'Playfair Display',
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: codeController,
                    maxLength: 6,
                    autofocus: true,
                    textCapitalization: TextCapitalization.characters,
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.25,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'CODE12',
                      counterText: '',
                      labelText: 'Invite Code',
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: accent),
                      ),
                    ),
                  ),
                  if (errorMessage.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      errorMessage,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                  if (isSearching) ...[
                    const SizedBox(height: 20),
                    Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(accent))),
                  ],
                  if (!isSearching && searchAttempted && foundGuild != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface2,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            foundGuild!.name,
                            style: TextStyle(
                              fontFamily: 'Playfair Display',
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            foundGuild!.description,
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.label_outline_rounded, size: 14, color: accent),
                              const SizedBox(width: 4),
                              Text(
                                foundGuild!.subjectFocus,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                              const Spacer(),
                              Icon(Icons.people_rounded, size: 14, color: accent),
                              const SizedBox(width: 4),
                              Text(
                                '${foundGuild!.memberIds.length} members',
                                style: const TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                if (foundGuild == null)
                  ElevatedButton(
                    onPressed: isSearching
                        ? null
                        : () async {
                            final code = codeController.text.trim().toUpperCase();
                            if (code.length < 6) {
                              setDialogState(() {
                                errorMessage = 'Code must be exactly 6 characters.';
                              });
                              return;
                            }

                            setDialogState(() {
                              isSearching = true;
                              errorMessage = '';
                              searchAttempted = false;
                              foundGuild = null;
                            });

                            final result = await GuildService().findByCode(code);

                            setDialogState(() {
                              isSearching = false;
                              searchAttempted = true;
                              if (result != null) {
                                foundGuild = result;
                              } else {
                                errorMessage = 'Guild not found. Double check code.';
                              }
                            });
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: AppColors.background,
                      elevation: 0,
                    ),
                    child: const Text('Find Guild'),
                  )
                else
                  ElevatedButton(
                    onPressed: () async {
                      if (foundGuild!.memberIds.contains(uid)) {
                        Navigator.of(context).pop();
                        context.push('/guilds/home/${foundGuild!.id}');
                        return;
                      }

                      await GuildService().joinGuild(foundGuild!.id, uid);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        context.push('/guilds/home/${foundGuild!.id}');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: AppColors.background,
                      elevation: 0,
                    ),
                    child: const Text('Join'),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
