import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_animations.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/utils/validators.dart';
import '../../domain/entities/password_policy_validation.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/glass_text_field.dart';
import '../../../../shared/widgets/initials_avatar.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_flow_scaffold.dart';

class GoogleUsernameSetupScreen extends StatefulWidget {
  const GoogleUsernameSetupScreen({super.key});

  @override
  State<GoogleUsernameSetupScreen> createState() =>
      _GoogleUsernameSetupScreenState();
}

class _GoogleUsernameSetupScreenState extends State<GoogleUsernameSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  Timer? _usernameDebounceTimer;
  Timer? _passwordDebounceTimer;
  bool _submitted = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _usernameDebounceTimer?.cancel();
    _passwordDebounceTimer?.cancel();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _queueUsernameAvailabilityCheck(
    String username, {
    bool immediate = false,
  }) {
    _usernameDebounceTimer?.cancel();

    final normalized = username.trim().toLowerCase();
    if (Validators.validateUsername(normalized) != null) {
      context.read<AuthBloc>().add(
        const AuthUsernameCheckRequested(username: ''),
      );
      return;
    }

    void runCheck() {
      if (!mounted) return;
      if (_usernameController.text.trim().toLowerCase() != normalized) {
        return;
      }
      context.read<AuthBloc>().add(
        AuthUsernameCheckRequested(username: normalized),
      );
    }

    if (immediate) {
      runCheck();
      return;
    }

    _usernameDebounceTimer = Timer(const Duration(milliseconds: 450), runCheck);
  }

  void _queuePasswordPolicyCheck(String password) {
    _passwordDebounceTimer?.cancel();
    final trimmed = password.trim();
    final authBloc = context.read<AuthBloc>();

    if (trimmed.isEmpty) {
      authBloc.add(const AuthPasswordPolicyCheckRequested(password: ''));
      setState(() {});
      return;
    }

    setState(() {});
    _passwordDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      if (_passwordController.text.trim() != trimmed) {
        return;
      }
      authBloc.add(AuthPasswordPolicyCheckRequested(password: trimmed));
    });
  }

  String? _validateOptionalConfirmPassword(String? value) {
    if (_passwordController.text.isEmpty) {
      return null;
    }
    return Validators.validateConfirmPassword(value, _passwordController.text);
  }

  void _submit(AuthState state) {
    setState(() => _submitted = true);
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (state.isCheckingUsername || state.usernameAvailable != true) {
      return;
    }

    context.read<AuthBloc>().add(
      AuthGoogleUsernameCompletionRequested(
        username: _usernameController.text.trim().toLowerCase(),
        password: _passwordController.text.trim().isEmpty
            ? null
            : _passwordController.text.trim(),
      ),
    );
  }

  List<String> _generateSuggestions(String displayName) {
    final normalized = displayName
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final base = normalized.isEmpty ? 'pulse_user' : normalized;
    final suggestions = <String>{base, base.replaceAll('_', '')};
    var suffix = 1;
    while (suggestions.length < 3) {
      suggestions.add('$base$suffix');
      suffix++;
    }
    return suggestions.take(3).toList();
  }

  Widget _buildStatus(AuthState state) {
    if (state.isCheckingUsername) {
      return const _InlineState(
        icon: Icons.sync_rounded,
        title: 'Checking availability',
        description: 'We are checking this username right now.',
      );
    }

    if (state.usernameAvailable == true) {
      return const _InlineState(
        icon: Icons.check_circle_outline,
        title: 'Username available',
        description: 'This username is ready to claim.',
      );
    }

    if (state.usernameAvailable == false) {
      return const _InlineState(
        icon: Icons.cancel_outlined,
        title: 'Username taken',
        description: 'Pick another option or try one of the suggestions below.',
      );
    }

    if (state.errorMessage != null &&
        _usernameController.text.trim().isNotEmpty &&
        Validators.validateUsername(_usernameController.text.trim()) == null) {
      return _InlineState(
        icon: Icons.cloud_off_rounded,
        title: 'Unable to check username',
        description: state.errorMessage!,
      );
    }

    if (_submitted) {
      return const _InlineState(
        icon: Icons.info_outline,
        title: 'Choose an available username',
        description: 'Wait for the availability check before continuing.',
      );
    }

    return const _InlineState(
      icon: Icons.info_outline,
      title: 'Choose your app username',
      description: 'Your group will use this to find you in Pulse.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthBloc>().state;
    final profile = state.pendingGoogleProfileData;
    final displayName = profile?.displayName ?? 'Google user';
    final email = profile?.email ?? '';
    final photoUrl = profile?.photoUrl;
    final suggestions = _generateSuggestions(displayName);
    final isLoading = state.status == AuthStatus.loading;
    final hasPasswordInput = _passwordController.text.trim().isNotEmpty;

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
        } else if (state.status == AuthStatus.unauthenticated) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.authIntro,
            (route) => false,
          );
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
        eyebrow: 'GOOGLE SIGN-IN',
        title: 'Choose your username.',
        subtitle:
            'Google already confirmed your identity. Finish the account with the username your group will search for.',
        maxWidth: 480,
        child: GlassCard(
          padding: const EdgeInsets.all(AppDimensions.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.center,
                child: InitialsAvatar(
                  name: displayName,
                  imageUrl: photoUrl,
                  size: 72,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingMd),
              Text(
                displayName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (email.isNotEmpty) ...[
                const SizedBox(height: AppDimensions.spacingXs),
                Text(
                  email,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: AppDimensions.spacingLg),
              Form(
                key: _formKey,
                autovalidateMode: _submitted
                    ? AutovalidateMode.onUserInteraction
                    : AutovalidateMode.disabled,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GlassTextField(
                      key: const ValueKey('google-username-field'),
                      controller: _usernameController,
                      enabled: !isLoading,
                      validator: Validators.validateUsername,
                      labelText: 'Username',
                      hintText: 'your_unique_id',
                      prefixIcon: const Icon(
                        Icons.alternate_email_rounded,
                        color: AppColors.textTeal,
                      ),
                      suffixIcon: state.isCheckingUsername
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : state.usernameAvailable == true
                          ? const Icon(
                              Icons.check_circle,
                              color: AppColors.success,
                            )
                          : state.usernameAvailable == false
                          ? const Icon(Icons.cancel, color: AppColors.error)
                          : null,
                      onChanged: _queueUsernameAvailabilityCheck,
                    ),
                    const SizedBox(height: AppDimensions.spacingSm),
                    _buildStatus(state),
                    const SizedBox(height: AppDimensions.spacingMd),
                    Text(
                      'Suggestions based on your Google profile',
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
                            key: ValueKey('google-username-$suggestion'),
                            onPressed: isLoading
                                ? null
                                : () {
                                    _usernameController.text = suggestion;
                                    _usernameController.selection =
                                        TextSelection.collapsed(
                                          offset: suggestion.length,
                                        );
                                    _queueUsernameAvailabilityCheck(
                                      suggestion,
                                      immediate: true,
                                    );
                                  },
                            backgroundColor: AppColors.primary.withValues(
                              alpha: 0.12,
                            ),
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
                    const _InlineState(
                      icon: Icons.password_rounded,
                      title: 'Optional password sign-in',
                      description:
                          'Add a password now if you also want to sign in with email and password later.',
                    ),
                    const SizedBox(height: AppDimensions.spacingMd),
                    GlassTextField(
                      key: const ValueKey('google-password-field'),
                      controller: _passwordController,
                      enabled: !isLoading,
                      obscureText: _obscurePassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return null;
                        }
                        return Validators.validatePassword(value);
                      },
                      labelText: 'Password (optional)',
                      hintText:
                          'Link email/password while finishing Google sign-up',
                      textInputAction: TextInputAction.next,
                      prefixIcon: const Icon(
                        Icons.lock_outline_rounded,
                        color: AppColors.textTeal,
                      ),
                      onChanged: _queuePasswordPolicyCheck,
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
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    if (hasPasswordInput) ...[
                      const SizedBox(height: AppDimensions.spacingMd),
                      GlassTextField(
                        key: const ValueKey('google-confirm-password-field'),
                        controller: _confirmPasswordController,
                        enabled: !isLoading,
                        obscureText: _obscureConfirmPassword,
                        validator: _validateOptionalConfirmPassword,
                        labelText: 'Confirm password',
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
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                    ],
                    if (hasPasswordInput && state.isCheckingPasswordPolicy) ...[
                      const SizedBox(height: AppDimensions.spacingSm),
                      const _InlineState(
                        icon: Icons.sync_rounded,
                        title: 'Checking Firebase policy',
                        description:
                            'We are validating your password against the live policy configured in Firebase Auth.',
                      ),
                    ] else if (hasPasswordInput &&
                        state.passwordValidation != null) ...[
                      const SizedBox(height: AppDimensions.spacingSm),
                      _PasswordPolicyChecklist(
                        validation: state.passwordValidation!,
                      ),
                    ] else if (hasPasswordInput &&
                        state.passwordValidationError != null) ...[
                      const SizedBox(height: AppDimensions.spacingSm),
                      _InlineState(
                        icon: Icons.wifi_off_rounded,
                        title: 'Password policy check unavailable',
                        description:
                            '${state.passwordValidationError} We will verify it again when you finish setup.',
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spacingLg),
              GlassButton(
                key: const ValueKey('google-username-continue'),
                text: 'Continue into Pulse',
                onPressed: () => _submit(state),
                isLoading: isLoading,
                isPrimary: true,
                icon: Icons.arrow_forward_rounded,
                width: double.infinity,
              ),
              const SizedBox(height: AppDimensions.spacingMd),
              GlassButton(
                key: const ValueKey('google-username-cancel'),
                text: 'Cancel Google sign-in',
                onPressed: isLoading
                    ? () {}
                    : () {
                        context.read<AuthBloc>().add(
                          AuthGoogleOnboardingCancelled(),
                        );
                      },
                icon: Icons.close_rounded,
                width: double.infinity,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _InlineState({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppAnimations.fast,
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
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
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
