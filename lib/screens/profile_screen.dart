import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../widgets/modern_ui.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _resumeController;
  late final TextEditingController _locationController;
  late final TextEditingController _salaryController;

  @override
  void initState() {
    super.initState();
    final profile = context.read<AppState>().profile;
    _nameController = TextEditingController(text: profile.name);
    _emailController = TextEditingController(text: profile.email);
    _resumeController = TextEditingController(text: profile.resumeText);
    _locationController =
        TextEditingController(text: profile.preferredLocation);
    _salaryController = TextEditingController(text: profile.salaryExpectation);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _resumeController.dispose();
    _locationController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        final profile = state.profile;
        final name = profile.name.trim().isEmpty ? 'User' : profile.name.trim();
        final email = profile.email.trim().isEmpty
            ? state.user?.email ?? 'No email'
            : profile.email.trim();

        return ModernPage(
          children: [
            Text(
              'Settings',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 22),
            ModernCard(
              child: Row(
                children: [
                  const ModernIconBox(
                    icon: Icons.person,
                    size: 62,
                    background: ModernColors.softPurple,
                    color: ModernColors.purple,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: ModernColors.muted,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => _showEditProfile(context, state),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            const SectionChip(label: 'Appearance'),
            const SizedBox(height: 12),
            ModernCard(
              child: _SettingsSwitchRow(
                icon: Icons.dark_mode_outlined,
                iconColor: ModernColors.purple,
                iconBackground: ModernColors.softPurple,
                title: 'Dark Mode',
                subtitle:
                    profile.darkMode ? 'Currently dark' : 'Currently light',
                value: profile.darkMode,
                onChanged: (value) => state.updateProfile(darkMode: value),
              ),
            ),
            const SizedBox(height: 26),
            const SectionChip(label: 'Notifications'),
            const SizedBox(height: 12),
            ModernCard(
              child: Column(
                children: [
                  _SettingsSwitchRow(
                    icon: Icons.notifications_none,
                    iconColor: ModernColors.mint,
                    iconBackground: ModernColors.softMint,
                    title: 'Job Alerts',
                    subtitle: 'New matching jobs',
                    value: profile.jobAlerts,
                    onChanged: (value) => state.updateProfile(jobAlerts: value),
                  ),
                  const Divider(height: 28),
                  _SettingsSwitchRow(
                    icon: Icons.trending_up,
                    iconColor: ModernColors.violet,
                    iconBackground: ModernColors.softPurple,
                    title: 'Application Updates',
                    subtitle: 'Status changes',
                    value: profile.applicationUpdates,
                    onChanged: (value) =>
                        state.updateProfile(applicationUpdates: value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            const SectionChip(label: 'Job Preferences'),
            const SizedBox(height: 12),
            ModernCard(
              child: Column(
                children: [
                  _PreferenceRow(
                    icon: Icons.location_on_outlined,
                    iconColor: ModernColors.teal,
                    iconBackground: ModernColors.softCyan,
                    title: 'Job Location',
                    value: profile.preferredLocation,
                    onTap: () => _showPreferenceDialog(
                      context: context,
                      title: 'Job Location',
                      controller: _locationController,
                      onSave: (value) =>
                          state.updateProfile(preferredLocation: value),
                    ),
                  ),
                  const Divider(height: 30),
                  _PreferenceRow(
                    icon: Icons.attach_money,
                    iconColor: ModernColors.mint,
                    iconBackground: ModernColors.softMint,
                    title: 'Salary Expectation',
                    value: profile.salaryExpectation,
                    onTap: () => _showPreferenceDialog(
                      context: context,
                      title: 'Salary Expectation',
                      controller: _salaryController,
                      onSave: (value) =>
                          state.updateProfile(salaryExpectation: value),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => state.logout(),
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditProfile(BuildContext context, AppState state) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.person_outline),
                labelText: 'Name',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.mail_outline),
                labelText: 'Email',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _resumeController,
              minLines: 5,
              maxLines: 8,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.description_outlined),
                labelText: 'Default resume text',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                state.updateProfile(
                  name: _nameController.text.trim(),
                  email: _emailController.text.trim(),
                  resumeText: _resumeController.text,
                );
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.save),
              label: const Text('Save profile'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPreferenceDialog({
    required BuildContext context,
    required String title,
    required TextEditingController controller,
    required ValueChanged<String> onSave,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              onSave(controller.text.trim());
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _SettingsSwitchRow extends StatelessWidget {
  const _SettingsSwitchRow({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ModernIconBox(icon: icon, color: iconColor, background: iconBackground),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ModernColors.muted,
                    ),
              ),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}

class _PreferenceRow extends StatelessWidget {
  const _PreferenceRow({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Row(
        children: [
          ModernIconBox(
              icon: icon, color: iconColor, background: iconBackground),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: ModernColors.muted,
                ),
          ),
        ],
      ),
    );
  }
}
