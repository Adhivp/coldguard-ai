import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:code_card_ai/core/utils/responsive.dart';
import 'package:code_card_ai/features/settings/presentation/widgets/setting_switch.dart';
import 'package:code_card_ai/shared_widgets/section_header.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _alertsEnabled = true;
  bool _pushNotifications = true;
  bool _realTimeSync = false;
  bool _darkMode = false;
  bool _highAccuracy = true;

  @override
  Widget build(BuildContext context) {
    bool isMobile = Responsive.isMobile(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: ListView(
          padding: EdgeInsets.all(isMobile ? 24.0 : 36.0),
          children: [
            Text(
              'Settings',
              style: GoogleFonts.outfit(
                fontSize: isMobile ? 28 : 32,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            Text(
              'Configure application rules and connection settings',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 24),

            const SectionHeader(title: 'System Configurations'),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  SettingSwitch(
                    label: 'Temperature Alerts',
                    subtitle: 'Notify if threshold is breached',
                    value: _alertsEnabled,
                    icon: Icons.add_alert_rounded,
                    onChanged: (val) => setState(() => _alertsEnabled = val),
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  SettingSwitch(
                    label: 'Push Notifications',
                    subtitle: 'Enable visual/audible alarms',
                    value: _pushNotifications,
                    icon: Icons.notifications_active_rounded,
                    onChanged: (val) => setState(() => _pushNotifications = val),
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  SettingSwitch(
                    label: 'Real-time Syncing',
                    subtitle: 'Upload data continuously (more battery)',
                    value: _realTimeSync,
                    icon: Icons.sync_rounded,
                    onChanged: (val) => setState(() => _realTimeSync = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const SectionHeader(title: 'Preferences'),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  SettingSwitch(
                    label: 'Dark Mode',
                    subtitle: 'Switch theme to dark elements',
                    value: _darkMode,
                    icon: Icons.dark_mode_rounded,
                    onChanged: (val) => setState(() => _darkMode = val),
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  SettingSwitch(
                    label: 'High Accuracy GPS',
                    subtitle: 'Track gateway coordinates exactly',
                    value: _highAccuracy,
                    icon: Icons.gps_fixed_rounded,
                    onChanged: (val) => setState(() => _highAccuracy = val),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
