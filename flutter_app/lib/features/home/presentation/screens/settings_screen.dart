import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/providers/locale_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late Box _settingsBox;
  bool _notifyDisease = true;
  bool _notifyClimate = true;
  bool _notifyMandi = true;

  @override
  void initState() {
    super.initState();
    _settingsBox = Hive.box(AppConstants.settingsBox);
    _notifyDisease = _settingsBox.get('notify_disease', defaultValue: true) as bool;
    _notifyClimate = _settingsBox.get('notify_climate', defaultValue: true) as bool;
    _notifyMandi = _settingsBox.get('notify_mandi', defaultValue: true) as bool;
  }

  void _toggleNotification(String key, bool value) {
    setState(() {
      if (key == 'notify_disease') {
        _notifyDisease = value;
      } else if (key == 'notify_climate') {
        _notifyClimate = value;
      } else {
        _notifyMandi = value;
      }
    });
    _settingsBox.put(key, value);
  }

  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}
    if (mounted) {
      context.go(AppRoutes.onboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);
    final user = Supabase.instance.client.auth.currentUser;
    final phone = user?.phone ?? 'Guest User';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        children: [
          // User profile card
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppTheme.primaryGreen,
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: Text(
                phone,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(user != null ? l10n.authenticatedAccount : l10n.offlineGuestMode),
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),

          // i18n Language Dropdown
          Text(
            l10n.language,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd, vertical: 4),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: locale.languageCode,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'en', child: Text('English')),
                    DropdownMenuItem(value: 'hi', child: Text('हिन्दी')),
                    DropdownMenuItem(value: 'mr', child: Text('मराठी')),
                    DropdownMenuItem(value: 'ta', child: Text('தமிழ்')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      ref.read(localeProvider.notifier).setLocale(Locale(val));
                    }
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // Push Notifications Toggles
          Text(
            l10n.notifications,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  value: _notifyDisease,
                  onChanged: (val) => _toggleNotification('notify_disease', val),
                  title: Text(l10n.diseaseOutbreakAlerts),
                  subtitle: Text(l10n.notifyDiseaseSubtitle),
                  activeColor: AppTheme.primaryGreen,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: _notifyClimate,
                  onChanged: (val) => _toggleNotification('notify_climate', val),
                  title: Text(l10n.climateWeatherWarnings),
                  subtitle: Text(l10n.notifyClimateSubtitle),
                  activeColor: AppTheme.primaryGreen,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: _notifyMandi,
                  onChanged: (val) => _toggleNotification('notify_mandi', val),
                  title: Text(l10n.mandiPriceAlerts),
                  subtitle: Text(l10n.notifyMandiSubtitle),
                  activeColor: AppTheme.primaryGreen,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // Log out button
          ElevatedButton.icon(
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
            label: Text(l10n.logout),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // Version Footer
          Center(
            child: Text(
              '${l10n.appVersion}: ${AppConstants.appVersion}',
              style: const TextStyle(color: AppTheme.textHint, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
