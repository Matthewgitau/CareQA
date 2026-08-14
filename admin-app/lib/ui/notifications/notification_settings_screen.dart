import 'package:flutter/material.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  // Notification type settings
  bool _shiftNotifications = true;
  bool _trainingNotifications = true;
  bool _documentNotifications = true;
  bool _safeguardingNotifications = true;
  bool _actionPlanNotifications = true;
  bool _incidentNotifications = true;
  bool _financialNotifications = false;
  bool _systemNotifications = true;

  // Delivery settings
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _smsNotifications = false;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('Notification Types', [
            _buildSwitchTile(
              'Shift Notifications',
              'Shift assignments, cancellations, and swaps',
              _shiftNotifications,
              (v) => setState(() => _shiftNotifications = v),
            ),
            _buildSwitchTile(
              'Training Notifications',
              'Training due dates and overdue alerts',
              _trainingNotifications,
              (v) => setState(() => _trainingNotifications = v),
            ),
            _buildSwitchTile(
              'Document Notifications',
              'Document expiry and renewal reminders',
              _documentNotifications,
              (v) => setState(() => _documentNotifications = v),
            ),
            _buildSwitchTile(
              'Safeguarding Alerts',
              'Critical safeguarding notifications',
              _safeguardingNotifications,
              (v) => setState(() => _safeguardingNotifications = v),
            ),
            _buildSwitchTile(
              'Action Plan Notifications',
              'Action plan assignments and overdue alerts',
              _actionPlanNotifications,
              (v) => setState(() => _actionPlanNotifications = v),
            ),
            _buildSwitchTile(
              'Incident Notifications',
              'Incident reports and updates',
              _incidentNotifications,
              (v) => setState(() => _incidentNotifications = v),
            ),
            _buildSwitchTile(
              'Financial Notifications',
              'Invoices, payments, and billing alerts',
              _financialNotifications,
              (v) => setState(() => _financialNotifications = v),
            ),
            _buildSwitchTile(
              'System Notifications',
              'System alerts and announcements',
              _systemNotifications,
              (v) => setState(() => _systemNotifications = v),
            ),
          ]),
          const SizedBox(height: 24),
          _buildSection('Delivery Methods', [
            _buildSwitchTile(
              'Push Notifications',
              'Receive notifications on your device',
              _pushNotifications,
              (v) => setState(() => _pushNotifications = v),
            ),
            _buildSwitchTile(
              'Email Notifications',
              'Receive notifications via email',
              _emailNotifications,
              (v) => setState(() => _emailNotifications = v),
            ),
            _buildSwitchTile(
              'SMS Notifications',
              'Receive notifications via SMS (charges may apply)',
              _smsNotifications,
              (v) => setState(() => _smsNotifications = v),
            ),
          ]),
          const SizedBox(height: 24),
          _buildSection('Preferences', [
            _buildSwitchTile(
              'Sound',
              'Play sound for notifications',
              _soundEnabled,
              (v) => setState(() => _soundEnabled = v),
            ),
            _buildSwitchTile(
              'Vibration',
              'Vibrate for notifications',
              _vibrationEnabled,
              (v) => setState(() => _vibrationEnabled = v),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1565C0),
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontSize: 15)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }

  void _saveSettings() {
    // Save settings to shared preferences or database
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved'),
        backgroundColor: Colors.green,
      ),
    );
  }
}