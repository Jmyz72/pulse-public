import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_animations.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/glass_text_field.dart';
import '../../domain/entities/password_policy_validation.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_flow_scaffold.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _accountFormKey = GlobalKey<FormState>();
  final _usernameFormKey = GlobalKey<FormState>();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _showForm = false;
  bool _showBottom = false;
  bool _submittedAccountStep = false;
  bool _submittedUsernameStep = false;
  bool _didPrefillRouteArgs = false;
  int _currentStep = 0;

  Timer? _usernameDebounceTimer;
  Timer? _passwordDebounceTimer;
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
    _usernameDebounceTimer?.cancel();
    _passwordDebounceTimer?.cancel();
    _usernameController.dispose();
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validateAccountStep() {
    setState(() => _submittedAccountStep = true);
    final formState = _accountFormKey.currentState;
    if (formState != null) {
      return formState.validate();
    }

    return _validateAccountFields();
  }

  bool _validateUsernameStep() {
    setState(() => _submittedUsernameStep = true);
    final formState = _usernameFormKey.currentState;
    if (formState != null) {
      return formState.validate();
    }

    return _validateUsernameFields();
  }

  void _showStatusMessage(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleNextStep(AuthState state) {
    if (!_validateAccountStep()) {
      _shakeController.forward(from: 0.0);
      return;
    }

    if (state.isCheckingPasswordPolicy ||
        state.passwordValidation == null ||
        state.passwordValidation?.isValid == false) {
      _shakeController.forward(from: 0.0);
      return;
    }

    setState(() => _currentStep = 1);
  }

  void _handleRegister() {
    final state = context.read<AuthBloc>().state;

    if (!_validateUsernameStep()) {
      _shakeController.forward(from: 0.0);
      return;
    }

    if (state.isCheckingUsername || state.usernameAvailable != true) {
      _shakeController.forward(from: 0.0);
      return;
    }

    if (state.isCheckingPasswordPolicy ||
        state.passwordValidation == null ||
        state.passwordValidation?.isValid == false) {
      setState(() => _currentStep = 0);
      _shakeController.forward(from: 0.0);
      return;
    }

    context.read<AuthBloc>().add(
      AuthRegisterRequested(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        username: _usernameController.text.trim(),
        displayName: _displayNameController.text.trim(),
        phone: '',
      ),
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

  void _queueUsernameAvailabilityCheck(
    String username, {
    bool immediate = false,
  }) {
    _usernameDebounceTimer?.cancel();

    final normalized = username.trim().toLowerCase();
    final isValid = Validators.validateUsername(normalized) == null;
    setState(() {
      _submittedUsernameStep = false;
    });

    if (!isValid) {
      context.read<AuthBloc>().add(
        const AuthUsernameCheckRequested(username: ''),
      );
      return;
    }

    final authBloc = context.read<AuthBloc>();

    void triggerCheck() {
      if (!mounted) return;
      if (_usernameController.text.trim().toLowerCase() != normalized) {
        return;
      }
      authBloc.add(AuthUsernameCheckRequested(username: normalized));
    }

    if (immediate) {
      triggerCheck();
      return;
    }

    _usernameDebounceTimer = Timer(
      const Duration(milliseconds: 500),
      triggerCheck,
    );
  }

  void _handleUsernameSuggestionTap(String username) {
    _usernameController.text = username;
    _usernameController.selection = TextSelection.collapsed(
      offset: username.length,
    );
    _queueUsernameAvailabilityCheck(username, immediate: true);
  }

  List<String> _generateUsernameSuggestions(String displayName) {
    final normalized = displayName
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    final base = normalized.isEmpty ? 'pulse_user' : normalized;
    final suggestions = <String>[];

    void addSuggestion(String value) {
      final candidate = value.trim().toLowerCase();
      if (candidate.isEmpty || suggestions.contains(candidate)) {
        return;
      }
      suggestions.add(candidate);
    }

    addSuggestion(base);
    final compact = base.replaceAll('_', '');
    addSuggestion(compact);

    var suffix = 1;
    while (suggestions.length < 3) {
      addSuggestion('$base$suffix');
      suffix++;
    }

    return suggestions.take(3).toList();
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

  @override
  Widget build(BuildContext context) {
    if (!_didPrefillRouteArgs) {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      final prefilledDisplayName = args?['displayName'] as String?;
      final prefilledEmail = args?['email'] as String?;
      if (prefilledDisplayName != null && prefilledDisplayName.isNotEmpty) {
        _displayNameController.text = prefilledDisplayName;
      }
      if (prefilledEmail != null && prefilledEmail.isNotEmpty) {
        _emailController.text = prefilledEmail;
      }
      _didPrefillRouteArgs = true;
    }

    final state = context.watch<AuthBloc>().state;
    final isLoading = state.status == AuthStatus.loading;

    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (previous, current) => previous.status != current.status,
          listener: (context, state) {
            if (state.status == AuthStatus.emailVerificationSent) {
              final email = state.user?.email ?? _emailController.text.trim();
              final displayName =
                  state.user?.displayName ?? _displayNameController.text.trim();

              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.emailVerification,
                (route) => false,
                arguments: <String, String>{
                  'email': email,
                  'displayName': displayName,
                },
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
              _showStatusMessage(
                state.errorMessage ?? 'Unknown error',
                AppColors.error,
              );
            }
          },
        ),
      ],
      child: AuthFlowScaffold(
        eyebrow: 'CREATE ACCOUNT',
        title: 'Set up your Pulse account.',
        subtitle:
            'Work through the account details first, then claim the username your group will see.',
        maxWidth: 480,
        showBackButton: true,
        footer: _staggerIn(
          show: _showBottom,
          child: _buildLoginPrompt(isLoading),
        ),
        child: _staggerIn(
          show: _showForm,
          child: _buildFormCard(state, isLoading),
        ),
      ),
    );
  }

  Widget _buildFormCard(AuthState state, bool isLoading) {
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStepHeader(),
              const SizedBox(height: AppDimensions.spacingLg),
              AnimatedSize(
                duration: AppAnimations.medium,
                curve: AppAnimations.defaultCurve,
                child: AnimatedSwitcher(
                  duration: AppAnimations.medium,
                  switchInCurve: AppAnimations.defaultCurve,
                  switchOutCurve: AppAnimations.defaultCurve,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.04, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: _currentStep == 0
                      ? _buildAccountStep(isLoading, state)
                      : _buildUsernameStep(isLoading, state),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _StepDot(isActive: _currentStep == 0, label: '1'),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                height: 2,
                color:
                    (_currentStep == 1
                            ? AppColors.primary
                            : AppColors.secondary)
                        .withValues(alpha: 0.35),
              ),
            ),
            const SizedBox(width: 10),
            _StepDot(isActive: _currentStep == 1, label: '2'),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingMd),
        Text(
          _currentStep == 0 ? 'Step 1 · Account' : 'Step 2 · Username',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingXs),
        Text(
          _currentStep == 0 ? 'Create your account.' : 'Choose your username.',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountStep(bool isLoading, AuthState state) {
    return Form(
      key: _accountFormKey,
      autovalidateMode: _submittedAccountStep
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: Column(
        key: const ValueKey('account-step'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassTextField(
            key: const ValueKey('register-display-name'),
            controller: _displayNameController,
            enabled: !isLoading,
            validator: Validators.validateName,
            labelText: 'Display Name',
            hintText: 'What should your group call you?',
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(
              Icons.person_outline_rounded,
              color: AppColors.textTeal,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          GlassTextField(
            key: const ValueKey('register-email'),
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            enabled: !isLoading,
            validator: Validators.validateEmail,
            labelText: 'Email',
            hintText: 'name@email.com',
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(
              Icons.email_outlined,
              color: AppColors.textTeal,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          GlassTextField(
            key: const ValueKey('register-password'),
            controller: _passwordController,
            obscureText: _obscurePassword,
            enabled: !isLoading,
            validator: Validators.validatePassword,
            labelText: 'Password',
            hintText: 'Checked against your live Firebase password policy',
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
              color: AppColors.textTeal,
            ),
            onChanged: (value) {
              _passwordDebounceTimer?.cancel();
              final trimmed = value.trim();
              final authBloc = context.read<AuthBloc>();

              if (trimmed.isEmpty) {
                authBloc.add(
                  const AuthPasswordPolicyCheckRequested(password: ''),
                );
                return;
              }

              _passwordDebounceTimer = Timer(
                const Duration(milliseconds: 500),
                () {
                  if (!mounted) return;
                  if (_passwordController.text.trim() != trimmed) {
                    return;
                  }
                  authBloc.add(
                    AuthPasswordPolicyCheckRequested(password: trimmed),
                  );
                },
              );
            },
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.textTeal,
              ),
              tooltip: _obscurePassword ? 'Show password' : 'Hide password',
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
          if (state.isCheckingPasswordPolicy) ...[
            const SizedBox(height: AppDimensions.spacingSm),
            const _InlineNotice(
              icon: Icons.sync_rounded,
              title: 'Checking Firebase policy',
              description:
                  'We are validating your password against the live policy configured in Firebase Auth.',
            ),
          ] else if (state.passwordValidation != null) ...[
            const SizedBox(height: AppDimensions.spacingSm),
            _PasswordPolicyChecklist(validation: state.passwordValidation!),
          ] else if (state.passwordValidationError != null) ...[
            const SizedBox(height: AppDimensions.spacingSm),
            _InlineNotice(
              icon: Icons.wifi_off_rounded,
              title: 'Password policy check unavailable',
              description:
                  '${state.passwordValidationError} We will verify it again when you create the account.',
            ),
          ],
          const SizedBox(height: AppDimensions.spacingLg),
          GlassTextField(
            key: const ValueKey('register-confirm-password'),
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            enabled: !isLoading,
            validator: (value) => Validators.validateConfirmPassword(
              value,
              _passwordController.text,
            ),
            labelText: 'Confirm Password',
            hintText: 'Re-enter your password',
            textInputAction: TextInputAction.done,
            prefixIcon: const Icon(
              Icons.verified_user_outlined,
              color: AppColors.textTeal,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.textTeal,
              ),
              tooltip: _obscureConfirmPassword
                  ? 'Show password'
                  : 'Hide password',
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
          ),
          const SizedBox(height: AppDimensions.spacingLg),
          GlassButton(
            key: const ValueKey('register-continue'),
            text: 'Continue',
            onPressed: isLoading ? () {} : () => _handleNextStep(state),
            isPrimary: true,
            icon: Icons.arrow_forward_rounded,
            width: double.infinity,
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          const _AuthDivider(label: 'or'),
          const SizedBox(height: AppDimensions.spacingMd),
          GlassButton(
            key: const ValueKey('register-google'),
            text: 'Continue with Google',
            onPressed: () =>
                context.read<AuthBloc>().add(AuthGoogleSignInRequested()),
            isLoading: isLoading,
            icon: Icons.account_circle_outlined,
            width: double.infinity,
          ),
        ],
      ),
    );
  }

  Widget _buildUsernameStep(bool isLoading, AuthState state) {
    final suggestions = _generateUsernameSuggestions(
      _displayNameController.text,
    );
    final isUsernameChecking = state.isCheckingUsername;
    final usernameAvailability = state.usernameAvailable;
    final usernameCheckError = state.errorMessage;

    return Form(
      key: _usernameFormKey,
      autovalidateMode: _submittedUsernameStep
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: Column(
        key: const ValueKey('username-step'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassTextField(
            key: const ValueKey('register-username'),
            controller: _usernameController,
            enabled: !isLoading,
            validator: Validators.validateUsername,
            labelText: 'Username',
            hintText: 'your_unique_id',
            textInputAction: TextInputAction.done,
            prefixIcon: const Icon(
              Icons.alternate_email_rounded,
              color: AppColors.textTeal,
            ),
            suffixIcon: isUsernameChecking
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : usernameAvailability == true
                ? const Icon(Icons.check_circle, color: AppColors.success)
                : usernameAvailability == false
                ? const Icon(Icons.cancel, color: AppColors.error)
                : null,
            onChanged: _queueUsernameAvailabilityCheck,
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          _buildUsernameStatus(
            isUsernameChecking: isUsernameChecking,
            usernameAvailability: usernameAvailability,
            usernameCheckError: usernameCheckError,
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          Text(
            'Suggestions based on your display name',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final suggestion in suggestions)
                ActionChip(
                  key: ValueKey('username-suggestion-$suggestion'),
                  onPressed: isLoading
                      ? null
                      : () => _handleUsernameSuggestionTap(suggestion),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.35),
                  ),
                  label: Text(
                    suggestion,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingLg),
          Row(
            children: [
              Expanded(
                child: GlassButton(
                  key: const ValueKey('register-back'),
                  text: 'Back',
                  onPressed: isLoading
                      ? () {}
                      : () => setState(() => _currentStep = 0),
                  icon: Icons.arrow_back_rounded,
                  width: double.infinity,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingMd),
              Expanded(
                child: GlassButton(
                  key: const ValueKey('register-create-account'),
                  text: 'Create Account',
                  onPressed: _handleRegister,
                  isLoading: isLoading,
                  isPrimary: true,
                  icon: Icons.check_circle_outline_rounded,
                  width: double.infinity,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUsernameStatus({
    required bool isUsernameChecking,
    required bool? usernameAvailability,
    required String? usernameCheckError,
  }) {
    if (isUsernameChecking) {
      return const _InlineNotice(
        icon: Icons.sync_rounded,
        title: 'Checking availability',
        description:
            'We are checking whether this username is available right now.',
      );
    }

    if (usernameAvailability == true) {
      return const _InlineNotice(
        icon: Icons.check_circle_outline,
        title: 'Username available',
        description: 'You can keep this one or choose another suggestion.',
      );
    }

    if (usernameAvailability == false) {
      return const _InlineNotice(
        icon: Icons.cancel_outlined,
        title: 'Username taken',
        description: 'Pick another option or tap a suggested username below.',
      );
    }

    if (usernameCheckError != null &&
        _usernameController.text.trim().isNotEmpty &&
        Validators.validateUsername(_usernameController.text.trim()) == null) {
      return _InlineNotice(
        icon: Icons.cloud_off_rounded,
        title: 'Unable to check username',
        description: usernameCheckError,
      );
    }

    if (_submittedUsernameStep) {
      return const _InlineNotice(
        icon: Icons.info_outline,
        title: 'Check availability before continuing',
        description:
            'Choose a valid username and wait for the availability check to complete.',
      );
    }

    return const _InlineNotice(
      icon: Icons.info_outline,
      title: 'Pick a unique username',
      description:
          'Tap a suggestion or enter your own. Availability will update as you type.',
    );
  }

  Widget _buildLoginPrompt(bool isLoading) {
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
              'Already set up?',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: isLoading
                ? null
                : () {
                    context.read<AuthBloc>().add(AuthErrorReset());
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    } else {
                      Navigator.pushNamed(context, AppRoutes.login);
                    }
                  },
            child: const Text(
              'Return to sign in',
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

  bool _validateAccountFields() {
    return Validators.validateName(_displayNameController.text.trim()) ==
            null &&
        Validators.validateEmail(_emailController.text.trim()) == null &&
        Validators.validatePassword(_passwordController.text) == null &&
        Validators.validateConfirmPassword(
              _confirmPasswordController.text,
              _passwordController.text,
            ) ==
            null;
  }

  bool _validateUsernameFields() {
    return Validators.validateUsername(_usernameController.text.trim()) == null;
  }
}

class _StepDot extends StatelessWidget {
  final bool isActive;
  final String label;

  const _StepDot({required this.isActive, required this.label});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppAnimations.fast,
      height: 28,
      width: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: (isActive ? AppColors.primary : AppColors.secondary).withValues(
          alpha: isActive ? 0.22 : 0.12,
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: (isActive ? AppColors.primary : AppColors.secondary)
              .withValues(alpha: 0.42),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isActive ? AppColors.primary : AppColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
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

class _PasswordPolicyChecklist extends StatelessWidget {
  final PasswordPolicyValidation validation;

  const _PasswordPolicyChecklist({required this.validation});

  @override
  Widget build(BuildContext context) {
    final requirements = <({String label, bool met})>[
      (
        label: 'At least ${validation.minPasswordLength} characters',
        met: validation.meetsMinPasswordLength,
      ),
      if (validation.maxPasswordLength != null)
        (
          label: 'No more than ${validation.maxPasswordLength} characters',
          met: validation.meetsMaxPasswordLength,
        ),
      if (validation.requiresUppercase)
        (
          label: 'One uppercase letter',
          met: validation.meetsUppercaseRequirement,
        ),
      if (validation.requiresLowercase)
        (
          label: 'One lowercase letter',
          met: validation.meetsLowercaseRequirement,
        ),
      if (validation.requiresDigits)
        (label: 'One digit', met: validation.meetsDigitsRequirement),
      if (validation.requiresSymbols)
        (label: 'One symbol', met: validation.meetsSymbolsRequirement),
    ];

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
          const Text(
            'Password policy',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          for (final requirement in requirements) ...[
            _PolicyRequirementRow(
              label: requirement.label,
              met: requirement.met,
            ),
            const SizedBox(height: AppDimensions.spacingXs),
          ],
          if (!validation.isValid) ...[
            const SizedBox(height: AppDimensions.spacingXs),
            Text(
              validation.failureMessage,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
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

class _PolicyRequirementRow extends StatelessWidget {
  final String label;
  final bool met;

  const _PolicyRequirementRow({required this.label, required this.met});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          met ? Icons.check_circle : Icons.radio_button_unchecked,
          color: met ? AppColors.success : AppColors.textSecondary,
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: met ? AppColors.textPrimary : AppColors.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
