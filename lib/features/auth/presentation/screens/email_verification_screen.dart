import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_flow_scaffold.dart';

class EmailVerificationScreen extends StatelessWidget {
  const EmailVerificationScreen({super.key});

  void _goToLogin(BuildContext context, String email) {
    context.read<AuthBloc>().add(AuthVerificationAcknowledged());
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
      arguments: <String, String>{'email': email},
    );
  }

  void _goToRegister(BuildContext context, String email, String? displayName) {
    context.read<AuthBloc>().add(AuthVerificationAcknowledged());
    final arguments = <String, String>{'email': email};
    if (displayName != null) {
      arguments['displayName'] = displayName;
    }
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.register,
      (route) => false,
      arguments: arguments,
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final state = context.watch<AuthBloc>().state;
    final email =
        args?['email'] as String? ?? state.pendingVerificationEmail ?? '';
    final displayName =
        args?['displayName'] as String? ?? state.user?.displayName;

    return AuthFlowScaffold(
      eyebrow: 'VERIFY EMAIL',
      title: 'Check your inbox.',
      subtitle: 'We sent a verification link before you can sign in.',
      maxWidth: 480,
      footer: const _InlineTip(
        title: 'If you do not see it',
        description:
            'Check spam, promotions, and any filters that may have moved the message.',
        icon: Icons.mark_email_unread_outlined,
      ),
      child: GlassCard(
        padding: const EdgeInsets.all(AppDimensions.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _VerificationIcon(),
            const SizedBox(height: AppDimensions.spacingLg),
            const Text(
              'We sent a verification email to',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingSm),
            Text(
              email,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingMd),
            Text(
              displayName?.isEmpty ?? true
                  ? 'Open your email app and tap the link to continue.'
                  : 'Welcome, $displayName. Open your email app and tap the link to continue.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingLg),
            GlassButton(
              key: const ValueKey('verification-login'),
              text: 'I\'ve verified my email',
              onPressed: () => _goToLogin(context, email),
              isPrimary: true,
              icon: Icons.login_rounded,
              width: double.infinity,
            ),
            const SizedBox(height: AppDimensions.spacingMd),
            GlassButton(
              key: const ValueKey('verification-register'),
              text: 'Use different email',
              onPressed: () => _goToRegister(context, email, displayName),
              icon: Icons.edit_outlined,
              width: double.infinity,
            ),
            const SizedBox(height: AppDimensions.spacingSm),
            TextButton(
              key: const ValueKey('verification-back'),
              onPressed: () => _goToLogin(context, email),
              child: const Text(
                'Back to sign in',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerificationIcon extends StatelessWidget {
  const _VerificationIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(AppDimensions.spacingLg),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withValues(alpha: 0.12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.28)),
      ),
      child: const Icon(
        Icons.mark_email_read_rounded,
        color: AppColors.primary,
        size: 34,
      ),
    );
  }
}

class _InlineTip extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const _InlineTip({
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: AppDimensions.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
