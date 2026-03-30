import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:country_picker/country_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/avatar_widget.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/glass_text_field.dart';
import '../../../../shared/widgets/international_phone_field.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _paymentIdentityController =
      TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  Country _selectedPhoneCountry = Validators.defaultPhoneCountry();
  String? _phoneError;
  AuthStatus? _previousStatus;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    _populateFromAuthState(authState);
  }

  void _populateFromAuthState(AuthState authState) {
    if (authState.user != null) {
      _nameController.text = authState.user!.displayName;
      _selectedPhoneCountry = Validators.countryFromPhone(
        authState.user!.phone,
      );
      _phoneController.text = Validators.nationalNumberForEditing(
        authState.user!.phone,
        fallbackCountry: _selectedPhoneCountry,
      );
      _paymentIdentityController.text = authState.user!.paymentIdentity ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _paymentIdentityController.dispose();
    super.dispose();
  }

  void _updateProfile() {
    final trimmedName = _nameController.text.trim();
    if (trimmedName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Name cannot be empty')));
      return;
    }
    if (trimmedName.length > 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name must be 50 characters or less')),
      );
      return;
    }

    final trimmedPhone = _phoneController.text.trim();
    final formattedPhone = Validators.normalizePhoneForStorage(
      trimmedPhone,
      country: _selectedPhoneCountry,
    );
    if (trimmedPhone.isNotEmpty && formattedPhone == null) {
      setState(() {
        _phoneError = AppStrings.errorInvalidPhone;
      });
      return;
    }

    context.read<AuthBloc>().add(
      AuthProfileUpdateRequested(
        displayName: trimmedName,
        phone: formattedPhone ?? '',
        paymentIdentity: _paymentIdentityController.text.trim(),
      ),
    );
  }

  Future<void> _showImageSourceSheet() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated && state.user != null) {
          _populateFromAuthState(state);
          if (_previousStatus == AuthStatus.loading) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Profile updated successfully'),
                backgroundColor: AppColors.success.withValues(alpha: 0.9),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else if (state.status == AuthStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${state.errorMessage ?? 'Unknown error'}'),
              backgroundColor: AppColors.error.withValues(alpha: 0.9),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        _previousStatus = state.status;
      },
      child: Scaffold(
        appBar: GlassAppBar(
          title: 'Edit Profile',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(icon: const Icon(Icons.save), onPressed: _updateProfile),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppDimensions.spacingMd),
          children: [
            Center(
              child: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  return Stack(
                    children: [
                      AvatarWidget(
                        imageUrl: state.user?.photoUrl,
                        name: state.user?.displayName,
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
                            onPressed: state.isUploadingPhoto
                                ? null
                                : _showImageSourceSheet,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: AppDimensions.spacingXl),
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                final username = state.user?.username ?? '';
                final email = state.user?.email ?? '';
                return GlassCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      const ListTile(
                        leading: Icon(
                          Icons.badge_outlined,
                          color: AppColors.primary,
                        ),
                        title: Text('Username'),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.spacingMd,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            username.isNotEmpty ? '@$username' : 'Not set',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingSm),
                      const Divider(height: 1, color: AppColors.glassBorder),
                      const ListTile(
                        leading: Icon(
                          Icons.email_outlined,
                          color: AppColors.primary,
                        ),
                        title: Text('Email'),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppDimensions.spacingMd,
                          0,
                          AppDimensions.spacingMd,
                          AppDimensions.spacingMd,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            email.isNotEmpty ? email : 'Not set',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: AppDimensions.spacingMd),
            GlassTextField(
              controller: _nameController,
              labelText: 'Display Name',
              prefixIcon: const Icon(Icons.person),
            ),
            const SizedBox(height: AppDimensions.spacingMd),
            InternationalPhoneField(
              key: const ValueKey('edit-profile-phone'),
              controller: _phoneController,
              selectedCountry: _selectedPhoneCountry,
              onCountryChanged: (country) {
                setState(() {
                  _selectedPhoneCountry = country;
                  _phoneError = null;
                });
              },
              labelText: 'Phone',
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
              controller: _paymentIdentityController,
              labelText: 'Payment Identity',
              hintText: 'Bank recipient / DuitNow name',
              prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
            ),
            const SizedBox(height: AppDimensions.spacingXl),
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                final isLoading = state.status == AuthStatus.loading;
                return GlassButton(
                  text: 'Save Changes',
                  onPressed: _updateProfile,
                  isLoading: isLoading,
                  isPrimary: true,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
