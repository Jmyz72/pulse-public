import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_flow_scaffold.dart';

class AuthIntroScreen extends StatelessWidget {
  const AuthIntroScreen({super.key});

  Future<void> _promptGoogleLinkPassword(
    BuildContext context,
    String email,
  ) async {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF052B32),
          title: const Text(
            'Link Google sign-in',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter the password for $email to link Google to your existing Pulse account.',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingMd),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  style: const TextStyle(color: AppColors.textPrimary),
                  validator: (value) {
                    if ((value ?? '').isEmpty) {
                      return 'Password is required';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<AuthBloc>().add(AuthGoogleOnboardingCancelled());
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(dialogContext).pop();
                  context.read<AuthBloc>().add(
                    AuthGoogleLinkRequested(password: passwordController.text),
                  );
                }
              },
              child: const Text('Link account'),
            ),
          ],
        );
      },
    );

    passwordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthBloc>().state;
    final isLoading = state.status == AuthStatus.loading;

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.home,
            (route) => false,
          );
        } else if (state.status == AuthStatus.profileCompletionRequired) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.profileCompletion,
            (route) => false,
          );
        } else if (state.status == AuthStatus.usernameSetupRequired) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.googleUsernameSetup,
            (route) => false,
          );
        } else if (state.status == AuthStatus.googleLinkRequired) {
          final email = state.pendingGoogleProfileData?.email ?? 'your account';
          _promptGoogleLinkPassword(context, email);
        } else if (state.status == AuthStatus.error &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: AuthFlowScaffold(
        eyebrow: 'WELCOME TO PULSE',
        title: 'Start with the flow that fits.',
        subtitle:
            'Choose how you want to enter. The actual auth steps stay focused, shorter, and easier to finish.',
        maxWidth: 520,
        footer: const _IntroDetails(),
        child: GlassCard(
          padding: const EdgeInsets.all(AppDimensions.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Pick an entry point',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingSm),
              const Text(
                'Sign in if you already have an account, create one if you are new, or use Google to move faster.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingLg),
              GlassButton(
                key: const ValueKey('auth-intro-sign-in'),
                text: 'Sign In',
                onPressed: isLoading
                    ? () {}
                    : () => Navigator.pushNamed(context, AppRoutes.login),
                isPrimary: true,
                icon: Icons.login_rounded,
                width: double.infinity,
              ),
              const SizedBox(height: AppDimensions.spacingMd),
              GlassButton(
                key: const ValueKey('auth-intro-register'),
                text: 'Create Account',
                onPressed: isLoading
                    ? () {}
                    : () => Navigator.pushNamed(context, AppRoutes.register),
                icon: Icons.person_add_alt_1_rounded,
                width: double.infinity,
              ),
              const SizedBox(height: AppDimensions.spacingMd),
              const _EntryDivider(),
              const SizedBox(height: AppDimensions.spacingMd),
              GlassButton(
                key: const ValueKey('auth-intro-google'),
                text: 'Continue with Google',
                onPressed: isLoading
                    ? () {}
                    : () => context.read<AuthBloc>().add(
                        AuthGoogleSignInRequested(),
                      ),
                isLoading: isLoading,
                icon: Icons.account_circle_outlined,
                width: double.infinity,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntroDetails extends StatelessWidget {
  const _IntroDetails();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _IntroBenefitGrid(),
        SizedBox(height: AppDimensions.spacingMd),
        _PulsePreviewCard(),
      ],
    );
  }
}

class _IntroBenefitGrid extends StatelessWidget {
  const _IntroBenefitGrid();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = AppDimensions.spacingMd;
        final tileWidth = (constraints.maxWidth - spacing) / 2;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: const [
            _BenefitTile(
              icon: Icons.receipt_long_rounded,
              title: 'Expenses',
              description: 'Track who paid and who still owes.',
            ),
            _BenefitTile(
              icon: Icons.groups_rounded,
              title: 'Groups',
              description: 'Keep plans and conversations in one place.',
            ),
            _BenefitTile(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Chat',
              description: 'Pick up every conversation where you left it.',
            ),
            _BenefitTile(
              icon: Icons.event_note_rounded,
              title: 'Plans',
              description: 'Keep schedules and shared plans aligned.',
            ),
          ].map((tile) => SizedBox(width: tileWidth, child: tile)).toList(),
        );
      },
    );
  }
}

class _PulsePreviewCard extends StatelessWidget {
  const _PulsePreviewCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingLg),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.18)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Inside Pulse',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: AppDimensions.spacingXs),
          Text(
            'Everything stays organized around the same group instead of splitting your plans across multiple apps.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          SizedBox(height: AppDimensions.spacingMd),
          _PreviewRow(
            icon: Icons.check_circle_outline_rounded,
            title: 'Split bills cleanly',
            description: 'Follow balances without guessing who still owes.',
          ),
          SizedBox(height: AppDimensions.spacingSm),
          _PreviewRow(
            icon: Icons.check_circle_outline_rounded,
            title: 'Coordinate faster',
            description: 'Keep tasks, timing, and group updates together.',
          ),
          SizedBox(height: AppDimensions.spacingSm),
          _PreviewRow(
            icon: Icons.check_circle_outline_rounded,
            title: 'Start light',
            description:
                'Create the account now and finish optional profile details later.',
          ),
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _PreviewRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
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
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
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
    );
  }
}

class _BenefitTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _BenefitTile({
    required this.icon,
    required this.title,
    required this.description,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: AppDimensions.spacingSm),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
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
    );
  }
}

class _EntryDivider extends StatelessWidget {
  const _EntryDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: AppColors.secondary.withValues(alpha: 0.18),
            thickness: 1,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppDimensions.spacingMd),
          child: Text(
            'or',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: AppColors.secondary.withValues(alpha: 0.18),
            thickness: 1,
          ),
        ),
      ],
    );
  }
}
