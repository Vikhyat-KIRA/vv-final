import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_model.dart';
import '../../services/leaderboard_service.dart';
import '../../theme/colors.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/glass_card.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  final LeaderboardService _leaderboardService = LeaderboardService();
  late Future<List<UserModel>> _topUsersFuture;

  @override
  void initState() {
    super.initState();
    _topUsersFuture = _leaderboardService.getTopUsers();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = ref.watch(themeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Global Leaderboard', style: TextStyle(fontFamily: 'Space Grotesk', fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: FutureBuilder<List<UserModel>>(
        future: _topUsersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: themeColor));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading leaderboard: ${snapshot.error}', style: TextStyle(color: AppColors.textPrimary)));
          }

          final users = snapshot.data ?? [];
          if (users.isEmpty) {
            return Center(child: Text('No users found', style: TextStyle(color: AppColors.textPrimary)));
          }

          final top3 = users.take(3).toList();
          final others = users.length > 3 ? users.sublist(3) : <UserModel>[];

          return CustomScrollView(
            slivers: [
              if (top3.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
                    child: _buildPodium(top3, isDark),
                  ),
                ),
              if (others.isNotEmpty)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final user = others[index];
                      final rank = index + 4;
                      return _buildRankListItem(user, rank, themeColor);
                    },
                    childCount: others.length,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPodium(List<UserModel> top3, bool isDark) {
    final hasSecond = top3.length > 1;
    final hasThird = top3.length > 2;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (hasSecond) _buildPodiumItem(top3[1], 2, 140, isDark ? Colors.blueGrey.shade300 : Colors.blueGrey.shade500),
        const SizedBox(width: 8),
        _buildPodiumItem(top3[0], 1, 180, Colors.amber.shade500),
        const SizedBox(width: 8),
        if (hasThird) _buildPodiumItem(top3[2], 3, 120, Colors.orange.shade400),
      ],
    );
  }

  Widget _buildPodiumItem(UserModel user, int rank, double height, Color badgeColor) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: rank == 1 ? 40 : 30,
            backgroundImage: NetworkImage(user.photoUrl),
            backgroundColor: AppColors.surface,
          ),
          const SizedBox(height: 8),
          Text(
            user.displayName.isNotEmpty ? user.displayName : user.username,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: rank == 1 ? 16 : 14,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${user.xp} XP',
            style: TextStyle(
              fontSize: 12,
              color: badgeColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            padding: const EdgeInsets.all(8),
            margin: EdgeInsets.zero,
            backgroundColor: badgeColor.withOpacity(0.15),
            borderColor: badgeColor.withOpacity(0.6),
            child: Container(
              height: height,
              width: double.infinity,
              alignment: Alignment.topCenter,
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                rank.toString(),
                style: TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: badgeColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankListItem(UserModel user, int rank, Color themeColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            SizedBox(
              width: 30,
              child: Text(
                rank.toString(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage(user.photoUrl),
              backgroundColor: AppColors.surface,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName.isNotEmpty ? user.displayName : user.username,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Level ${user.level}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${user.xp} XP',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: themeColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
