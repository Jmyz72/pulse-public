import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../shared/widgets/pulse_lottie.dart';
import '../bloc/auth_bloc.dart';

/// AuthGate handles navigation based on auth state.
/// - Unauthenticated -> Login screen
/// - Authenticated -> Home screen
///
/// Feature lifecycle (settings load/clear, friends clear) is handled
/// by the app-level AuthLifecycleListener in app.dart.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isNavigating = false;

  void _navigateTo(String route) {
    if (_isNavigating || !mounted) return;
    _isNavigating = true;
    developer.log('navigating to $route', name: 'AuthGate');
    Navigator.pushNamedAndRemoveUntil(context, route, (route) => false).then((
      _,
    ) {
      if (mounted) _isNavigating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, authState) {
        if (_isNavigating) return;

        if (authState.status == AuthStatus.authenticated) {
          _navigateTo(AppRoutes.home);
        } else if (authState.status == AuthStatus.profileCompletionRequired) {
          _navigateTo(AppRoutes.profileCompletion);
        } else if (authState.status == AuthStatus.usernameSetupRequired) {
          _navigateTo(AppRoutes.googleUsernameSetup);
        } else if (authState.status == AuthStatus.unauthenticated) {
          _navigateTo(AppRoutes.authIntro);
        }
      },
      child: const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PulseLottie(
                key: ValueKey('auth-gate-lottie'),
                assetPath: 'assets/animations/Handshake Loop.lottie',
                width: 160,
                height: 160,
                semanticLabel: 'App loading animation',
              ),
              SizedBox(height: 20),
              Text(
                'Syncing your Pulse flow...',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
