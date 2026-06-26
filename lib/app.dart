import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/theme_provider.dart';
import 'providers/theme_mode_provider.dart';
import 'providers/theme_style_provider.dart';
import 'providers/sync_provider.dart';
import 'theme/app_theme.dart';
import 'theme/colors.dart';
import 'widgets/vayu_orb.dart';
import 'widgets/mesh_background.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/onboarding/onboarding_step1_screen.dart';
import 'screens/onboarding/onboarding_step2_screen.dart';
import 'screens/onboarding/onboarding_step3_screen.dart';
import 'screens/onboarding/onboarding_step4_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/syllabus/syllabus_screen.dart';
import 'screens/ai_tutor/ai_tutor_screen.dart';
import 'screens/vault/vault_screen.dart';
import 'screens/flashcards/flashcards_screen.dart';
import 'screens/pomodoro/pomodoro_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/profile/user_search_screen.dart';
import 'screens/social/dm_list_screen.dart';
import 'screens/social/chat_screen.dart';
import 'screens/social/guilds_screen.dart';
import 'screens/social/guild_create_screen.dart';
import 'screens/social/guild_home_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/profile/settings_screen.dart';
import 'screens/leaderboard/leaderboard_screen.dart';
import 'providers/connectivity_provider.dart';

CustomTransitionPage slideRightPage(Widget child, GoRouterState state) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: animation.drive(
          Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOutCubic)),
        ),
        child: child,
      );
    },
  );
}

final goRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingStep1Screen(),
    ),
    GoRoute(
      path: '/onboarding/step2',
      builder: (context, state) => const OnboardingStep2Screen(),
    ),
    GoRoute(
      path: '/onboarding/step3',
      builder: (context, state) => const OnboardingStep3Screen(),
    ),
    GoRoute(
      path: '/onboarding/step4',
      builder: (context, state) => const OnboardingStep4Screen(),
    ),
    // Nest the 5 primary screens inside a StatefulShellRoute
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ScaffoldWithNestedNavigation(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (context, state) => const DashboardScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/syllabus',
              builder: (context, state) => const SyllabusScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/tutor',
              builder: (context, state) => const AiTutorScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/vault',
              builder: (context, state) => const VaultScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) {
                final uid = state.uri.queryParameters['uid'];
                return ProfileScreen(uid: uid);
              },
            ),
          ],
        ),
      ],
    ),
    // Extra top level routes (bottom navigation bar hidden)
    GoRoute(
      path: '/messages',
      pageBuilder: (context, state) => slideRightPage(const DmListScreen(), state),
    ),
    GoRoute(
      path: '/flashcards',
      pageBuilder: (context, state) => slideRightPage(const FlashcardsScreen(), state),
    ),
    GoRoute(
      path: '/pomodoro',
      pageBuilder: (context, state) => slideRightPage(const PomodoroScreen(), state),
    ),
    GoRoute(
      path: '/leaderboard',
      pageBuilder: (context, state) => slideRightPage(const LeaderboardScreen(), state),
    ),
    GoRoute(
      path: '/guilds',
      pageBuilder: (context, state) => slideRightPage(const GuildsScreen(), state),
    ),
    GoRoute(
      path: '/guilds/create',
      pageBuilder: (context, state) => slideRightPage(const GuildCreateScreen(), state),
    ),
    GoRoute(
      path: '/guilds/home/:guildId',
      pageBuilder: (context, state) {
        final guildId = state.pathParameters['guildId']!;
        return slideRightPage(GuildHomeScreen(guildId: guildId), state);
      },
    ),
    GoRoute(
      path: '/chat/:dmId/:otherUserId/:otherUsername',
      pageBuilder: (context, state) {
        final dmId = state.pathParameters['dmId']!;
        final otherUserId = state.pathParameters['otherUserId']!;
        final otherUsername = state.pathParameters['otherUsername']!;
        return slideRightPage(
          ChatScreen(
            dmId: dmId,
            otherUserId: otherUserId,
            otherUsername: otherUsername,
          ),
          state,
        );
      },
    ),
    GoRoute(
      path: '/search',
      pageBuilder: (context, state) => slideRightPage(const UserSearchScreen(), state),
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (context, state) => slideRightPage(const SettingsScreen(), state),
    ),
  ],
);

class ScaffoldWithNestedNavigation extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNestedNavigation({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeStyle = ref.watch(themeStyleProvider);
    final accentChoice = ref.watch(accentChoiceProvider);
    final accent = ref.watch(themeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final vayuColor = AppColors.vayuOrbColor(themeStyle.name, accentChoice);

    return Scaffold(
      body: Builder(
        builder: (context) {
          final mq = MediaQuery.of(context);
          // Calculate reserved height: 80 (nav bar) + 18 (orb offset) + 16 (clearance)
          final requiredBottomPadding = 114.0 + mq.viewPadding.bottom;
          
          return MediaQuery(
            data: mq.copyWith(
              padding: mq.padding.copyWith(
                bottom: requiredBottomPadding,
              ),
            ),
            child: ShaderMask(
              shaderCallback: (Rect bounds) {
                // Fade out the last 40 pixels right before the reserved padding area.
                // This ensures content dissolves elegantly instead of clipping abruptly.
                final fadeStart = bounds.height - requiredBottomPadding - 40.0;
                final fadeEnd = bounds.height - requiredBottomPadding;
                
                return LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: const [
                    Colors.black,
                    Colors.black,
                    Colors.transparent,
                    Colors.transparent,
                  ],
                  stops: [
                    0.0,
                    fadeStart / bounds.height,
                    fadeEnd / bounds.height,
                    1.0,
                  ],
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                switchInCurve: Curves.easeIn,
                switchOutCurve: Curves.easeOut,
                child: KeyedSubtree(
                  key: ValueKey<int>(navigationShell.currentIndex),
                  child: navigationShell,
                ),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
              ),
            ),
          );
        },
      ),
      extendBody: true,
      bottomNavigationBar: SizedBox(
        height: 80,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            // Glass-effect bottom bar background
            Positioned.fill(
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.black.withOpacity(0.4)
                          : Colors.white.withOpacity(0.75),
                      border: Border(
                        top: BorderSide(
                          color: isDark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.white.withOpacity(0.5),
                          width: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Navigation items row
            Positioned.fill(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _NavItem(
                    icon: Icons.dashboard_outlined,
                    activeIcon: Icons.dashboard,
                    label: 'Home',
                    isActive: navigationShell.currentIndex == 0,
                    accentColor: accent,
                    isDark: isDark,
                    onTap: () => navigationShell.goBranch(0, initialLocation: navigationShell.currentIndex == 0),
                  ),
                  _NavItem(
                    icon: Icons.menu_book_outlined,
                    activeIcon: Icons.menu_book,
                    label: 'Syllabus',
                    isActive: navigationShell.currentIndex == 1,
                    accentColor: accent,
                    isDark: isDark,
                    onTap: () => navigationShell.goBranch(1, initialLocation: navigationShell.currentIndex == 1),
                  ),
                  // Vayu orb spacer
                  const SizedBox(width: 64),
                  _NavItem(
                    icon: Icons.folder_zip_outlined,
                    activeIcon: Icons.folder_zip,
                    label: 'Vault',
                    isActive: navigationShell.currentIndex == 3,
                    accentColor: accent,
                    isDark: isDark,
                    onTap: () => navigationShell.goBranch(3, initialLocation: navigationShell.currentIndex == 3),
                  ),
                  _NavItem(
                    icon: Icons.person_outline,
                    activeIcon: Icons.person,
                    label: 'Profile',
                    isActive: navigationShell.currentIndex == 4,
                    accentColor: accent,
                    isDark: isDark,
                    onTap: () => navigationShell.goBranch(4, initialLocation: navigationShell.currentIndex == 4),
                  ),
                ],
              ),
            ),
            // Vayu orb (centered, raised)
            Positioned(
              top: -18,
              child: VayuOrb(
                color: vayuColor,
                isActive: navigationShell.currentIndex == 2,
                onTap: () => navigationShell.goBranch(2, initialLocation: navigationShell.currentIndex == 2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final Color accentColor;
  final bool isDark;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.accentColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? activeIcon : icon,
                key: ValueKey(isActive),
                color: isActive
                    ? accentColor
                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8)),
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive
                    ? accentColor
                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ConnectivityBanner extends ConsumerWidget {
  const ConnectivityBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOffline = ref.watch(isOfflineProvider);

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      top: isOffline ? 0 : -100,
      left: 0,
      right: 0,
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          bottom: false,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              children: [
                Icon(Icons.wifi_off_rounded, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No internet connection. Changes will sync when back online.',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
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

class CustomWindowButtons extends ConsumerWidget {
  const CustomWindowButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = WindowButtonColors(
      iconNormal: AppColors.textPrimary,
      mouseOver: AppColors.surface2,
      mouseDown: AppColors.surface,
      iconMouseOver: AppColors.textPrimary,
      iconMouseDown: AppColors.textPrimary,
    );

    final closeButtonColors = WindowButtonColors(
      mouseOver: const Color(0xFFD32F2F),
      mouseDown: const Color(0xFFB71C1C),
      iconNormal: AppColors.textPrimary,
      iconMouseOver: Colors.white,
    );

    // Watch sync status for the background sync icon
    final syncState = ref.watch(syncStatusProvider);
    IconData syncIcon;
    Color syncColor;
    
    if (syncState == SyncStatus.syncing) {
      syncIcon = Icons.sync;
      syncColor = AppColors.accentDefault;
    } else if (syncState == SyncStatus.error) {
      syncIcon = Icons.sync_problem;
      syncColor = AppColors.error;
    } else {
      syncIcon = Icons.cloud_done;
      syncColor = AppColors.textSecondary.withAlpha(150);
    }

    return Row(
      children: [
        if (syncState == SyncStatus.syncing)
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: syncColor),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Icon(syncIcon, size: 16, color: syncColor),
          ),
        MinimizeWindowButton(colors: colors),
        MaximizeWindowButton(colors: colors),
        CloseWindowButton(colors: closeButtonColors),
      ],
    );
  }
}

class VidyaverseApp extends ConsumerWidget {
  const VidyaverseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final accentChoice = ref.watch(accentChoiceProvider);
    final themeStyle = ref.watch(themeStyleProvider);

    final systemBrightness = MediaQuery.platformBrightnessOf(context);

    AppColors.updateColors(themeMode, systemBrightness, accentChoice,
        themeStyle: themeStyle.name);

    // Pick the correct ThemeData based on the theme style
    ThemeData lightThemeData;
    ThemeData darkThemeData;
    ThemeMode effectiveMode = themeMode;

    switch (themeStyle) {
      case ThemeStyle.brutalist:
        lightThemeData = AppTheme.brutalistTheme(themeState);
        darkThemeData = AppTheme.glassDark(themeState); // fallback
        break;
      case ThemeStyle.gradient:
        lightThemeData = AppTheme.gradientTheme(themeState);
        darkThemeData = AppTheme.glassDark(themeState); // fallback
        break;
      case ThemeStyle.darkGold:
        lightThemeData = AppTheme.darkGoldTheme(themeState);
        darkThemeData = AppTheme.darkGoldTheme(themeState);
        effectiveMode = ThemeMode.dark; // force dark
        break;
      case ThemeStyle.glass:
      default:
        lightThemeData = AppTheme.glassLight(themeState);
        darkThemeData = AppTheme.glassDark(themeState);
        break;
    }

    return MaterialApp.router(
      title: 'Vidyaverse',
      theme: lightThemeData,
      darkTheme: darkThemeData,
      themeMode: effectiveMode,
      routerConfig: goRouter,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return Stack(
          children: [
            const Positioned.fill(
              child: AnimatedMeshBackground(),
            ),
            if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS))
              Column(
                children: [
                  WindowTitleBarBox(
                    child: Container(
                      color: AppColors.background,
                      child: Row(
                        children: [
                          Expanded(child: MoveWindow()),
                          const CustomWindowButtons(),
                        ],
                      ),
                    ),
                  ),
                  Expanded(child: child ?? const SizedBox()),
                ],
              )
            else
              if (child != null) child,
            const ConnectivityBanner(),
          ],
        );
      },
    );
  }
}
