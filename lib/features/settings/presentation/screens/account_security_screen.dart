import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../features/auth/domain/entities/password_policy_validation.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/glass_text_field.dart';

class AccountSecurityScreen extends StatefulWidget {
  const AccountSecurityScreen({super.key});

  @override
  State<AccountSecurityScreen> createState() => _AccountSecurityScreenState();
}

class _AccountSecurityScreenState extends State<AccountSecurityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  Timer? _passwordDebounceTimer;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(AuthAccountSecurityRequested());
    context.read<AuthBloc>().add(
      const AuthPasswordPolicyCheckRequested(password: ''),
    );
  }

  @override
  void dispose() {
    _passwordDebounceTimer?.cancel();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _queuePasswordPolicyCheck(String value) {
    _passwordDebounceTimer?.cancel();
    final trimmed = value.trim();
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

  void _handleSetPassword() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    context.read<AuthBloc>().add(
      AuthSetPasswordRequested(password: _passwordController.text.trim()),
    );
  }

  String? _validateConfirmPassword(String? value) {
    return Validators.validateConfirmPassword(value, _passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          previous.errorMessage != current.errorMessage ||
          previous.accountSecurityMessage != current.accountSecurityMessage,
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (state.accountSecurityMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.accountSecurityMessage!),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: GlassAppBar(
          title: 'Account Security',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final security = state.authSecurity;
            final hasPasswordInput = _passwordController.text.trim().isNotEmpty;
            final isBusy =
                state.isLoadingAccountSecurity || state.isSettingPassword;

            return ListView(
              padding: const EdgeInsets.all(AppDimensions.spacingMd),
              children: [
                GlassCard(
                  padding: const EdgeInsets.all(AppDimensions.spacingLg),
                  child: state.isLoadingAccountSecurity && security == null
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(AppDimensions.spacingLg),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Sign-in methods',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: AppDimensions.spacingSm),
                            Text(
                              security?.email.isNotEmpty == true
                                  ? security!.email
                                  : 'Email unavailable',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: AppDimensions.spacingLg),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _MethodChip(
                                  label: 'Password',
                                  enabled:
                                      security?.hasPasswordProvider ?? false,
                                ),
                                _MethodChip(
                                  label: 'Google',
                                  enabled: security?.hasGoogleProvider ?? false,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppDimensions.spacingLg),
                            if (security?.hasPasswordProvider ?? false)
                              const _InlineNotice(
                                icon: Icons.verified_user_outlined,
                                title: 'Password sign-in is enabled',
                                description:
                                    'This account already has email and password access enabled.',
                              )
                            else ...[
                              const _InlineNotice(
                                icon: Icons.password_rounded,
                                title: 'Add password sign-in',
                                description:
                                    'Create a password now so you can sign in on another device without Google.',
                              ),
                              const SizedBox(height: AppDimensions.spacingLg),
                              Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    GlassTextField(
                                      key: const ValueKey(
                                        'account-security-password',
                                      ),
                                      controller: _passwordController,
                                      obscureText: _obscurePassword,
                                      enabled: !isBusy,
                                      validator: Validators.validatePassword,
                                      labelText: 'Password',
                                      hintText:
                                          'Checked against your live Firebase password policy',
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
                                            _obscurePassword =
                                                !_obscurePassword;
                                          });
                                        },
                                      ),
                                    ),
                                    if (hasPasswordInput &&
                                        state.isCheckingPasswordPolicy) ...[
                                      const SizedBox(
                                        height: AppDimensions.spacingSm,
                                      ),
                                      const _InlineNotice(
                                        icon: Icons.sync_rounded,
                                        title: 'Checking Firebase policy',
                                        description:
                                            'We are validating your password against the live policy configured in Firebase Auth.',
                                      ),
                                    ] else if (hasPasswordInput &&
                                        state.passwordValidation != null) ...[
                                      const SizedBox(
                                        height: AppDimensions.spacingSm,
                                      ),
                                      _PasswordPolicyChecklist(
                                        validation: state.passwordValidation!,
                                      ),
                                    ] else if (hasPasswordInput &&
                                        state.passwordValidationError !=
                                            null) ...[
                                      const SizedBox(
                                        height: AppDimensions.spacingSm,
                                      ),
                                      _InlineNotice(
                                        icon: Icons.wifi_off_rounded,
                                        title:
                                            'Password policy check unavailable',
                                        description:
                                            '${state.passwordValidationError} We will verify it again when you save.',
                                      ),
                                    ],
                                    const SizedBox(
                                      height: AppDimensions.spacingMd,
                                    ),
                                    GlassTextField(
                                      key: const ValueKey(
                                        'account-security-confirm-password',
                                      ),
                                      controller: _confirmPasswordController,
                                      obscureText: _obscureConfirmPassword,
                                      enabled: !isBusy,
                                      validator: _validateConfirmPassword,
                                      labelText: 'Confirm password',
                                      hintText: 'Re-enter your password',
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
                                    const SizedBox(
                                      height: AppDimensions.spacingLg,
                                    ),
                                    GlassButton(
                                      text: 'Set Password',
                                      onPressed: _handleSetPassword,
                                      isLoading: state.isSettingPassword,
                                      isPrimary: true,
                                      icon: Icons.lock_reset_rounded,
                                      width: double.infinity,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MethodChip extends StatelessWidget {
  final String label;
  final bool enabled;

  const _MethodChip({required this.label, required this.enabled});

  @override
  Widget build(BuildContext context) {
    final color = enabled ? AppColors.success : AppColors.textSecondary;
    final background = enabled
        ? AppColors.success.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.04);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            enabled ? Icons.check_circle : Icons.remove_circle_outline,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: enabled ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
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
