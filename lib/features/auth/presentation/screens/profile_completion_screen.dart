import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:country_picker/country_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/avatar_widget.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/glass_text_field.dart';
import '../../../../shared/widgets/international_phone_field.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_flow_scaffold.dart';

class ProfileCompletionScreen extends StatefulWidget {
  const ProfileCompletionScreen({super.key});

  @override
  State<ProfileCompletionScreen> createState() =>
      _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _paymentIdentityController =
      TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  Country _selectedPhoneCountry = Validators.defaultPhoneCountry();
  String? _phoneError;
  bool _saveRequested = false;
  bool _skipRequested = false;

  @override
  void initState() {
    super.initState();
    _populateFromState(context.read<AuthBloc>().state);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _paymentIdentityController.dispose();
    super.dispose();
  }

  void _populateFromState(AuthState state) {
    final user = state.user;
    if (user == null) {
      return;
    }

    _selectedPhoneCountry = Validators.countryFromPhone(user.phone);
    _phoneController.text = Validators.nationalNumberForEditing(
      user.phone,
      fallbackCountry: _selectedPhoneCountry,
    );
    _paymentIdentityController.text = user.paymentIdentity ?? '';
  }

  void _submit() {
    final authState = context.read<AuthBloc>().state;
    final user = authState.user;
    if (user == null) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.authIntro,
        (route) => false,
      );
      return;
    }

    final trimmedPhone = _phoneController.text.trim();
    final normalizedPhone = Validators.normalizePhoneForStorage(
      trimmedPhone,
      country: _selectedPhoneCountry,
    );
    final phoneError = normalizedPhone == null && trimmedPhone.isNotEmpty
        ? AppStrings.errorInvalidPhone
        : null;
    if (phoneError != null) {
      setState(() {
        _phoneError = phoneError;
      });
      return;
    }

    setState(() {
      _phoneError = null;
      _saveRequested = true;
      _skipRequested = false;
    });

    context.read<AuthBloc>().add(
      AuthProfileUpdateRequested(
        displayName: user.displayName,
        phone: normalizedPhone ?? '',
        paymentIdentity: _paymentIdentityController.text.trim(),
      ),
    );
  }

  void _skip() {
    setState(() {
      _skipRequested = true;
      _saveRequested = false;
    });
    context.read<AuthBloc>().add(AuthProfileCompletionSkipped());
  }

  Future<void> _showImageSourceSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (pickedFile != null && mounted) {
        context.read<AuthBloc>().add(
          AuthProfilePictureUpdateRequested(imagePath: pickedFile.path),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to pick image: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.isUploadingPhoto != current.isUploadingPhoto,
      listener: (context, state) {
        if (state.status == AuthStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Profile update failed'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
          setState(() {
            _saveRequested = false;
            _skipRequested = false;
          });
          return;
        }

        if (state.status == AuthStatus.authenticated &&
            (_saveRequested || _skipRequested)) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.home,
            (route) => false,
          );
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final isSaving =
              state.status == AuthStatus.loading || state.isUploadingPhoto;
          final user = state.user;

          return AuthFlowScaffold(
            eyebrow: 'SET UP YOUR PROFILE',
            title: 'Add the details your crew uses.',
            subtitle:
                'Phone, payment identity, and profile photo are optional now, but adding them makes it easier to get found and paid back later.',
            maxWidth: 480,
            child: GlassCard(
              padding: const EdgeInsets.all(AppDimensions.spacingLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Stack(
                      children: [
                        AvatarWidget(
                          imageUrl: user?.photoUrl,
                          name: user?.displayName,
                          size: AppDimensions.avatarXl,
                        ),
                        if (state.isUploadingPhoto)
                          Positioned.fill(
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: state.uploadProgress,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            backgroundColor: AppColors.primary,
                            radius: 20,
                            child: IconButton(
                              icon: const Icon(
                                Icons.camera_alt,
                                size: 20,
                                color: Colors.white,
                              ),
                              onPressed: isSaving
                                  ? null
                                  : _showImageSourceSheet,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingLg),
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.spacingMd),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusLg,
                      ),
                      border: Border.all(
                        color: AppColors.secondary.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.person_outline_rounded,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: AppDimensions.spacingSm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.displayName ?? 'Pulse',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user?.email ?? '',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingMd),
                  InternationalPhoneField(
                    key: const ValueKey('profile-completion-phone'),
                    controller: _phoneController,
                    selectedCountry: _selectedPhoneCountry,
                    onCountryChanged: (country) {
                      setState(() {
                        _selectedPhoneCountry = country;
                        _phoneError = null;
                      });
                    },
                    enabled: !isSaving,
                    labelText: 'Phone number',
                    errorText: _phoneError,
                    onChanged: (_) {
                      if (_phoneError != null) {
                        setState(() {
                          _phoneError = null;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: AppDimensions.spacingMd),
                  GlassTextField(
                    key: const ValueKey('profile-completion-payment-identity'),
                    controller: _paymentIdentityController,
                    enabled: !isSaving,
                    labelText: 'Payment identity',
                    hintText: 'Bank recipient / DuitNow name',
                    prefixIcon: const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: AppColors.textTeal,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingLg),
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.spacingMd),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusLg,
                      ),
                      border: Border.all(
                        color: AppColors.secondary.withValues(alpha: 0.18),
                      ),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.schedule_outlined,
                          color: AppColors.primary,
                          size: 18,
                        ),
                        SizedBox(width: AppDimensions.spacingSm),
                        Expanded(
                          child: Text(
                            'You can skip this for now and finish it later in profile settings.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingLg),
                  Row(
                    children: [
                      Expanded(
                        child: GlassButton(
                          key: const ValueKey('profile-completion-skip'),
                          text: 'Skip for now',
                          onPressed: isSaving ? () {} : _skip,
                          width: double.infinity,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spacingMd),
                      Expanded(
                        child: GlassButton(
                          key: const ValueKey('profile-completion-save'),
                          text: 'Save and continue',
                          onPressed: _submit,
                          isLoading: isSaving && _saveRequested,
                          isPrimary: true,
                          icon: Icons.arrow_forward_rounded,
                          width: double.infinity,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
