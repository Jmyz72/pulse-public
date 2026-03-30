import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../location/presentation/bloc/location_bloc.dart';
import '../bloc/settings_bloc.dart';

/// Privacy settings screen
class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  String get _currentUserId => context.read<AuthBloc>().state.user?.id ?? '';

  @override
  void initState() {
    super.initState();
    final userId = _currentUserId;
    if (userId.isNotEmpty) {
      context.read<SettingsBloc>().add(SettingsLoadRequested(userId: userId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<SettingsBloc, SettingsState>(
      listener: (context, state) {
        if (state.status == SettingsStatus.error && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.error.withValues(alpha: 0.9),
            ),
          );
          context.read<SettingsBloc>().add(SettingsErrorCleared());
        } else if (state.status == SettingsStatus.updated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(AppStrings.settingUpdated),
              duration: Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: GlassAppBar(
            title: 'Privacy Settings',
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: _buildContent(theme, state),
        );
      },
    );
  }

  Widget _buildContent(ThemeData theme, SettingsState state) {
    if (state.status == SettingsStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == SettingsStatus.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: AppDimensions.spacingMd),
            const Text(AppStrings.failedToLoadSettings),
            const SizedBox(height: AppDimensions.spacingSm),
            GlassButton(
              text: 'Retry',
              onPressed: () {
                final userId = _currentUserId;
                if (userId.isNotEmpty) {
                  context.read<SettingsBloc>().add(SettingsLoadRequested(userId: userId));
                }
              },
            ),
          ],
        ),
      );
    }

    final settings = state.settings;
    if (settings == null) {
      return const Center(child: Text(AppStrings.noSettingsAvailable));
    }

    final userId = _currentUserId;

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingMd),
          child: Text(
            'Profile Privacy',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        SwitchListTile(
          title: const Text('Show Profile'),
          subtitle: const Text('Allow others to see your profile'),
          value: settings.showProfile,
          onChanged: (value) {
            context.read<SettingsBloc>().add(
              PrivacySettingToggled(userId: userId, key: 'showProfile', value: value),
            );
          },
        ),
        SwitchListTile(
          title: const Text('Show Timeline'),
          subtitle: const Text('Allow others to see your activity timeline'),
          value: settings.showTimeline,
          onChanged: (value) {
            context.read<SettingsBloc>().add(
              PrivacySettingToggled(userId: userId, key: 'showTimeline', value: value),
            );
          },
        ),
        const Divider(color: AppColors.glassBorder),
        Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingMd),
          child: Text(
            'Activity Status',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        SwitchListTile(
          title: const Text('Invisible Mode'),
          subtitle: const Text('Hide your online status from others'),
          value: settings.invisibleMode,
          onChanged: (value) {
            context.read<SettingsBloc>().add(
              PrivacySettingToggled(userId: userId, key: 'invisibleMode', value: value),
            );
          },
        ),
        const Divider(color: AppColors.glassBorder),
        Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingMd),
          child: Text(
            'Location',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        BlocBuilder<LocationBloc, LocationState>(
          builder: (context, locationState) {
            return SwitchListTile(
              title: const Text('Share Location'),
              subtitle: const Text('Allow friends to see your location on the map'),
              value: locationState.isSharing,
              onChanged: (value) {
                context.read<LocationBloc>().add(
                  LocationSharingToggled(isSharing: value),
                );
              },
            );
          },
        ),
        const Divider(color: AppColors.glassBorder),
        Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingMd),
          child: Text(
            'Notifications',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        SwitchListTile(
          title: const Text('Enable Notifications'),
          subtitle: const Text('Receive push notifications'),
          value: settings.notificationsEnabled,
          onChanged: (value) {
            context.read<SettingsBloc>().add(
              PrivacySettingToggled(userId: userId, key: 'notificationsEnabled', value: value),
            );
          },
        ),
        const Divider(color: AppColors.glassBorder),
        Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingMd),
          child: Text(
            'Discoverability',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        SwitchListTile(
          title: const Text('Searchable by Username'),
          subtitle: const Text('Allow others to find you by username'),
          value: settings.searchableByUsername,
          onChanged: (value) {
            context.read<SettingsBloc>().add(
              PrivacySettingToggled(userId: userId, key: 'searchableByUsername', value: value),
            );
          },
        ),
        SwitchListTile(
          title: const Text('Searchable by Email'),
          subtitle: const Text('Allow others to find you by email'),
          value: settings.searchableByEmail,
          onChanged: (value) {
            context.read<SettingsBloc>().add(
              PrivacySettingToggled(userId: userId, key: 'searchableByEmail', value: value),
            );
          },
        ),
        SwitchListTile(
          title: const Text('Searchable by Phone'),
          subtitle: const Text('Allow others to find you by phone number'),
          value: settings.searchableByPhone,
          onChanged: (value) {
            context.read<SettingsBloc>().add(
              PrivacySettingToggled(userId: userId, key: 'searchableByPhone', value: value),
            );
          },
        ),
        const Divider(color: AppColors.glassBorder),
        Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingMd),
          child: Text(
            'Appearance',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        SwitchListTile(
          title: const Text('Dark Mode'),
          subtitle: const Text('Use dark theme'),
          value: settings.darkMode,
          onChanged: (value) {
            context.read<SettingsBloc>().add(
              PrivacySettingToggled(userId: userId, key: 'darkMode', value: value),
            );
          },
        ),
        const Divider(color: AppColors.glassBorder),
        const ListTile(
          leading: Icon(Icons.block, color: AppColors.textTertiary),
          title: Text('Blocked Users'),
          subtitle: Text('Coming soon'),
          trailing: Icon(Icons.arrow_forward_ios),
          onTap: null,
        ),
      ],
    );
  }
}
