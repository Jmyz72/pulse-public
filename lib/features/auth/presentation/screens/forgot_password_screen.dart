import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_animations.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/glass_text_field.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_flow_scaffold.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleResetPassword() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        AuthResetPasswordRequested(email: _emailController.text.trim()),
      );
    }
  }

  void _handleTryAnotherEmail() {
    context.read<AuthBloc>().add(AuthErrorReset());
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthBloc>().state;
    final emailSent = state.status == AuthStatus.passwordResetSent;
    final isLoading = state.status == AuthStatus.loading;

    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == AuthStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to send reset email: ${state.errorMessage ?? 'Unknown error'}',
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, _) {
        return AuthFlowScaffold(
          eyebrow: emailSent ? 'RESET SENT' : 'PASSWORD RESET',
          title: emailSent ? 'Check your inbox.' : 'Recover your Pulse access.',
          subtitle: emailSent
              ? 'If the account exists, the next step is already on its way to your email.'
              : 'Enter the email attached to your account and we will send a secure reset link.',
          maxWidth: 460,
          showBackButton: true,
          child: AnimatedSwitcher(
            duration: AppAnimations.medium,
            switchInCurve: AppAnimations.defaultCurve,
            switchOutCurve: AppAnimations.defaultCurve,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.03),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: emailSent ? _buildSuccessView() : _buildFormView(isLoading),
          ),
        );
      },
    );
  }

  Widget _buildFormView(bool isLoading) {
    return Container(
      key: const ValueKey('form'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 34,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: GlassCard(
        padding: const EdgeInsets.all(AppDimensions.spacingLg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Send reset link',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingSm),
              const Text(
                'Use the email you signed up with. If we find a match, we will send reset instructions immediately.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingLg),
              GlassTextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                enabled: !isLoading,
                validator: Validators.validateEmail,
                labelText: 'Email',
                hintText: 'name@email.com',
                prefixIcon: const Icon(
                  Icons.email_outlined,
                  color: AppColors.textTeal,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingLg),
              const _ActionNote(
                title: 'Before you retry',
                description:
                    'Double-check the address for typos. Some providers also route reset emails into spam or promotions.',
              ),
              const SizedBox(height: AppDimensions.spacingLg),
              GlassButton(
                text: 'Send Reset Link',
                onPressed: _handleResetPassword,
                isLoading: isLoading,
                isPrimary: true,
                icon: Icons.send_rounded,
                width: double.infinity,
              ),
              const SizedBox(height: AppDimensions.spacingMd),
              GlassButton(
                text: 'Back to Sign In',
                onPressed: isLoading ? () {} : () => Navigator.pop(context),
                icon: Icons.arrow_back_rounded,
                width: double.infinity,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Container(
      key: const ValueKey('success'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.10),
            blurRadius: 34,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: GlassCard(
        padding: const EdgeInsets.all(AppDimensions.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.spacingMd),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.24),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: AppDimensions.spacingSm),
                  Expanded(
                    child: Text(
                      'Reset request sent for ${_emailController.text}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.spacingLg),
            const _ActionNote(
              title: 'What happens next',
              description:
                  'Open the latest email from Pulse, follow the secure link, and create a new password there.',
            ),
            const SizedBox(height: AppDimensions.spacingMd),
            const _ActionNote(
              title: 'If you do not see it',
              description:
                  'Wait a minute, check spam, then try again with another email if you are unsure which address was used.',
            ),
            const SizedBox(height: AppDimensions.spacingLg),
            GlassButton(
              text: 'Try Another Email',
              onPressed: _handleTryAnotherEmail,
              icon: Icons.refresh_rounded,
              width: double.infinity,
            ),
            const SizedBox(height: AppDimensions.spacingMd),
            GlassButton(
              text: 'Back to Sign In',
              onPressed: () {
                context.read<AuthBloc>().add(AuthErrorReset());
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.login,
                  (route) => false,
                );
              },
              isPrimary: true,
              icon: Icons.arrow_back_rounded,
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionNote extends StatelessWidget {
  final String title;
  final String description;

  const _ActionNote({required this.title, required this.description});

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
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
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
