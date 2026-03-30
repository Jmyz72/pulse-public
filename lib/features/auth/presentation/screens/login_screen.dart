import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_animations.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/glass_text_field.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_flow_scaffold.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _didPrefillRouteEmail = false;

  bool _showForm = false;
  bool _showBottom = false;

  late final AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: AppAnimations.shake,
    );
    _startStaggerAnimation();
  }

  void _startStaggerAnimation() {
    Future.delayed(Duration.zero, () {
      if (mounted) setState(() => _showForm = true);
    });
    Future.delayed(AppAnimations.staggerDelay, () {
      if (mounted) setState(() => _showBottom = true);
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        AuthLoginRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );
    } else {
      _shakeController.forward(from: 0.0);
    }
  }

  void _handleEmailLinkRequest() {
    final validationError = Validators.validateEmail(_emailController.text);
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _shakeController.forward(from: 0.0);
      return;
    }

    context.read<AuthBloc>().add(
      AuthEmailLinkSignInRequested(email: _emailController.text.trim()),
    );
  }

  void _handleEmailLinkCompletion() {
    final validationError = Validators.validateEmail(_emailController.text);
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    context.read<AuthBloc>().add(
      AuthEmailLinkCompletionRequested(email: _emailController.text.trim()),
    );
  }

  Future<void> _promptGoogleLinkPassword(String email) async {
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
                  validator: Validators.validateLoginPassword,
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

  Widget _staggerIn({required bool show, required Widget child}) {
    return AnimatedOpacity(
      duration: AppAnimations.staggerElement,
      curve: AppAnimations.defaultCurve,
      opacity: show ? 1.0 : 0.0,
      child: AnimatedContainer(
        duration: AppAnimations.staggerElement,
        curve: AppAnimations.defaultCurve,
        transform: Matrix4.translationValues(
          0,
          show ? 0 : AppAnimations.slideOffset,
          0,
        ),
        child: child,
      ),
    );
  }

  void _handleBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.authIntro,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_didPrefillRouteEmail) {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      final prefilledEmail = args?['email'] as String?;
      if (prefilledEmail != null && prefilledEmail.isNotEmpty) {
        _emailController.text = prefilledEmail;
      }
      _didPrefillRouteEmail = true;
    }

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
          final email =
              state.pendingGoogleProfileData?.email ??
              _emailController.text.trim();
          _promptGoogleLinkPassword(email);
        } else if (state.status == AuthStatus.error) {
          final errorMessage = state.errorMessage ?? 'Login failed';
          final isEmailVerificationIssue =
              errorMessage == AppStrings.errorEmailNotVerified ||
              errorMessage.toLowerCase().contains('verify your email');

          if (isEmailVerificationIssue) {
            Navigator.pushNamed(
              context,
              AppRoutes.emailVerification,
              arguments: {'email': _emailController.text.trim()},
            );
            return;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: AuthFlowScaffold(
        eyebrow: 'SIGN IN',
        title: 'Jump back into your group.',
        subtitle:
            'Use your Pulse account to continue where your chats, plans, and balances left off.',
        maxWidth: 460,
        showBackButton: true,
        onBack: _handleBack,
        footer: _staggerIn(
          show: _showBottom,
          child: _buildRegisterPrompt(isLoading),
        ),
        child: _staggerIn(show: _showForm, child: _buildFormCard(isLoading)),
      ),
    );
  }

  Widget _buildFormCard(bool isLoading) {
    final state = context.watch<AuthBloc>().state;
    final showEmailLinkCompletion = state.pendingEmailLink != null;

    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final dx = _shakeController.isAnimating
            ? sin(_shakeController.value * pi * 4) *
                  AppAnimations.shakeOffset *
                  (1 - _shakeController.value)
            : 0.0;
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: Container(
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
                  'Sign in',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingSm),
                const Text(
                  'Enter your details and get back into Pulse.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingLg),
                if (showEmailLinkCompletion) ...[
                  const _InlineNotice(
                    icon: Icons.mark_email_read_outlined,
                    title: 'Finish email-link sign-in',
                    description:
                        'Confirm the email address that received this sign-in link, then continue.',
                  ),
                  const SizedBox(height: AppDimensions.spacingMd),
                ] else if (state.emailLinkSentEmail != null) ...[
                  _InlineNotice(
                    icon: Icons.mail_outline_rounded,
                    title: 'Check your inbox',
                    description:
                        'We sent a sign-in link to ${state.emailLinkSentEmail}. Open it on this device, or return here and confirm your email if prompted.',
                  ),
                  const SizedBox(height: AppDimensions.spacingMd),
                ],
                GlassTextField(
                  key: const ValueKey('login-email'),
                  controller: _emailController,
                  labelText: 'Email',
                  hintText: 'name@email.com',
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    color: AppColors.textTeal,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  enabled: !isLoading,
                  validator: Validators.validateEmail,
                ),
                  if (!showEmailLinkCompletion) ...[
                    const SizedBox(height: AppDimensions.spacingMd),
                    GlassTextField(
                      key: const ValueKey('login-password'),
                      controller: _passwordController,
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: AppColors.textTeal,
                    ),
                    obscureText: _obscurePassword,
                    enabled: !isLoading,
                    validator: Validators.validateLoginPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.textTeal,
                      ),
                      tooltip: _obscurePassword
                          ? 'Show password'
                          : 'Hide password',
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingSm),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                      onPressed: isLoading
                          ? null
                          : () {
                              context.read<AuthBloc>().add(AuthErrorReset());
                              Navigator.pushNamed(
                                context,
                                AppRoutes.forgotPassword,
                              );
                            },
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppDimensions.spacingLg),
                GlassButton(
                  text: showEmailLinkCompletion ? 'Finish sign-in' : 'Continue',
                  onPressed: showEmailLinkCompletion
                      ? _handleEmailLinkCompletion
                      : _handleLogin,
                  isLoading: isLoading,
                  isPrimary: true,
                  icon: showEmailLinkCompletion
                      ? Icons.mark_email_read_outlined
                      : Icons.arrow_forward_rounded,
                  width: double.infinity,
                ),
                if (!showEmailLinkCompletion) ...[
                  const SizedBox(height: AppDimensions.spacingMd),
                  GlassButton(
                    key: const ValueKey('login-email-link'),
                    text: 'Email me a sign-in link',
                    onPressed: state.isSendingEmailLink
                        ? () {}
                        : _handleEmailLinkRequest,
                    isLoading: state.isSendingEmailLink,
                    icon: Icons.alternate_email_rounded,
                    width: double.infinity,
                  ),
                ],
                if (!showEmailLinkCompletion) ...[
                  const SizedBox(height: AppDimensions.spacingMd),
                  const _AuthDivider(label: 'or'),
                  const SizedBox(height: AppDimensions.spacingMd),
                  GlassButton(
                    key: const ValueKey('login-google'),
                    text: 'Continue with Google',
                    onPressed: () => context.read<AuthBloc>().add(
                      AuthGoogleSignInRequested(),
                    ),
                    isLoading: isLoading,
                    icon: Icons.account_circle_outlined,
                    width: double.infinity,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterPrompt(bool isLoading) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingLg,
        vertical: AppDimensions.spacingMd,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Flexible(
            child: Text(
              'New here?',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: isLoading
                ? null
                : () {
                    context.read<AuthBloc>().add(AuthErrorReset());
                    Navigator.pushNamed(context, AppRoutes.register);
                  },
            child: const Text(
              'Create your account',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineNotice extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _InlineNotice({
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
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
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

class _AuthDivider extends StatelessWidget {
  final String label;

  const _AuthDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: AppColors.secondary.withValues(alpha: 0.22),
            height: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: AppColors.secondary.withValues(alpha: 0.22),
            height: 1,
          ),
        ),
      ],
    );
  }
}
