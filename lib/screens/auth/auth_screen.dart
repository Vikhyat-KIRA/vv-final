import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../theme/colors.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {

      final GoogleSignIn googleSignIn = GoogleSignIn(
        params: GoogleSignInParams(
          clientId: '773443742576-rab15ntpgmeeffg9isalt55pamcqstc3.apps.googleusercontent.com',
          clientSecret: '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',
          redirectPort: 3000,
          scopes: ['email', 'profile'],
        ),
      );
      
      final GoogleSignInCredentials? credentials = await googleSignIn.signIn();
      if (credentials != null) {
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: credentials.accessToken,
          idToken: credentials.idToken,
        );

        final UserCredential result = await FirebaseAuth.instance.signInWithCredential(credential);
        final user = result.user;

        if (user != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_id', user.uid);
          await prefs.setString('user_email', user.email ?? '');
          await prefs.setString('user_name', user.displayName ?? 'Quantum Learner');

          ref.read(authProvider.notifier).loginWithFirebaseUser(user);

          // Check if user has a profile in Firestore
          final doc = await FirestoreService().getUserData(user.uid);
          if (doc.exists) {
            await prefs.setBool('onboarding_complete', true);
            if (mounted) {
              context.go('/dashboard');
            }
          } else {
            await prefs.setBool('onboarding_complete', false);
            if (mounted) {
              context.go('/onboarding');
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google Sign-In failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.background, AppColors.surface],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset(
                'assets/app_icon.png',
                width: 72,
                height: 72,
              ),
              SizedBox(height: 16),
              Text(
                'VIDYAVERSE',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayMedium,
              ),
              SizedBox(height: 8),
              Text(
                'Gamified AI-Powered Study Companion',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              SizedBox(height: 64),
              if (_isLoading)
                Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentDefault),
                  ),
                )
              else
                // Google Sign-In button (white surface, Google logo SVG asset, 'Continue with Google')
                ElevatedButton(
                  onPressed: _handleGoogleSignIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    elevation: 1,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: AppColors.surface2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/google_logo.svg',
                        width: 20,
                        height: 20,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Continue with Google',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}