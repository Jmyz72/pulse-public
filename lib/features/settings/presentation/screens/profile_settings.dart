import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../shared/widgets/confirmation_dialog.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/avatar_widget.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/settings_bloc.dart';

/// Settings hub screen with categorized sections.
class ProfileSettingsScreen extends StatelessWidget {
  const ProfileSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: GlassAppBar(
        title: 'Settings',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingMd),
        children: [
          // Header: avatar + name + username
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final user = state.user;
              final displayName = user?.displayName ?? '';
              final username = user?.username ?? '';

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingMd,
                  vertical: AppDimensions.spacingSm,
                ),
                child: Row(
                  children: [
                    AvatarWidget(
                      imageUrl: user?.photoUrl,
                      name: displayName,
                      size: AppDimensions.avatarLg,
                    ),
                    const SizedBox(width: AppDimensions.spacingMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (username.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              '@$username',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          const Divider(color: AppColors.glassBorder),

          // Account
          const _SectionHeader(title: 'Account'),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Profile'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.pushNamed(context, AppRoutes.editProfile),
          ),
          ListTile(
            leading: const Icon(Icons.security, color: AppColors.primary),
            title: const Text('Account Security'),
            subtitle: const Text(
              'Manage your sign-in methods and add password access.',
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.accountSecurity),
          ),
          const Divider(color: AppColors.glassBorder),

          // Privacy
          const _SectionHeader(title: 'Privacy'),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Privacy Settings'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.privacySettings),
          ),
          const ListTile(
            leading: Icon(Icons.block, color: AppColors.textTertiary),
            title: Text('Blocked Users'),
            subtitle: Text('Coming soon'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: null,
          ),
          const Divider(color: AppColors.glassBorder),

          // Preferences
          const _SectionHeader(title: 'Preferences'),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.pushNamed(context, AppRoutes.notifications),
          ),
          const ListTile(
            leading: Icon(Icons.language, color: AppColors.textTertiary),
            title: Text('Language'),
            subtitle: Text('Coming soon'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: null,
          ),
          BlocBuilder<SettingsBloc, SettingsState>(
            builder: (context, state) {
              final darkMode = state.settings?.darkMode ?? false;
              return SwitchListTile(
                secondary: const Icon(Icons.dark_mode),
                title: const Text('Dark Mode'),
                value: darkMode,
                onChanged: (value) {
                  final userId = context.read<AuthBloc>().state.user?.id ?? '';
                  if (userId.isNotEmpty) {
                    context.read<SettingsBloc>().add(
                      PrivacySettingToggled(
                        userId: userId,
                        key: 'darkMode',
                        value: value,
                      ),
                    );
                  }
                },
              );
            },
          ),
          const Divider(color: AppColors.glassBorder),

          // Support
          const _SectionHeader(title: 'Support'),
          const ListTile(
            leading: Icon(Icons.help, color: AppColors.textTertiary),
            title: Text('Help & Support'),
            subtitle: Text('Coming soon'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: null,
          ),
          ListTile(
            leading: const Icon(Icons.info, color: AppColors.primary),
            title: const Text('About'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Pulse',
                applicationVersion: '1.0.0',
                applicationLegalese: 'A co-living management app',
              );
            },
          ),
          const Divider(color: AppColors.glassBorder),
          const SizedBox(height: AppDimensions.spacingMd),

          // Sign Out
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingMd,
            ),
            child: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                final isLoading = state.status == AuthStatus.loading;
                return ElevatedButton(
                  onPressed: isLoading ? null : () => _handleSignOut(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppDimensions.spacingMd,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMd,
                      ),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: AppColors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Sign Out',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                );
              },
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMd),
        ],
      ),
    );
  }

  void _handleSignOut(BuildContext context) {
    ConfirmationDialog.show(
      context,
      title: 'Sign Out',
      message: 'Are you sure you want to sign out?',
      confirmText: 'Sign Out',
      isDestructive: true,
      onConfirm: () {
        context.read<AuthBloc>().add(AuthLogoutRequested());
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.spacingMd,
        AppDimensions.spacingMd,
        AppDimensions.spacingMd,
        AppDimensions.spacingXs,
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
