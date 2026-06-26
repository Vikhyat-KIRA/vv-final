import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../../theme/colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate immediately on first frame — no artificial delay needed
    WidgetsBinding.instance.addPostFrameCallback((_) => _route());
  }

  Future<void> _route() async {
    if (!mounted) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      context.go('/auth');
      return;
    }
    // Check onboarding status locally — no Firestore call on startup
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final complete = prefs.getBool('onboarding_complete') ?? false;
    context.go(complete ? '/dashboard' : '/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 80,
              color: AppColors.accentDefault,
            ),
            const SizedBox(height: 20),
            Text(
              'VIDYAVERSE',
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your Academic Simulator',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
