import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/l10n.dart';
import '../../core/storage.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import 'quick_add_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameCtrl = TextEditingController();
  bool _editing = false;
  String? _localAvatarPath;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = context.read<AuthProvider>().user?.name ?? '';
    _loadAvatar();
  }

  Future<void> _loadAvatar() async {
    final path = await Storage.getLocalAvatar();
    if (mounted) setState(() => _localAvatarPath = path);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final s = context.l10n;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2))),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: Text(s.takePhoto),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(s.chooseGallery),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              if (_localAvatarPath != null)
                ListTile(
                  leading:
                      const Icon(Icons.delete_outline, color: Colors.red),
                  title: Text(s.removePhoto,
                      style: const TextStyle(color: Colors.red)),
                  onTap: () => Navigator.pop(context, null),
                ),
            ],
          ),
        ),
      ),
    );

    if (source == null && _localAvatarPath != null) {
      await Storage.clearLocalAvatar();
      setState(() => _localAvatarPath = null);
      return;
    }
    if (source == null) return;

    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: source, imageQuality: 85, maxWidth: 512);
    if (picked != null) {
      await Storage.saveLocalAvatar(picked.path);
      setState(() => _localAvatarPath = picked.path);
    }
  }

  Future<void> _saveProfile() async {
    final s = context.l10n;
    final ok =
        await context.read<AuthProvider>().updateProfile(name: _nameCtrl.text.trim());
    if (mounted) {
      setState(() => _editing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? s.profileUpdated : s.updateFailed),
          backgroundColor: ok ? kIncomeColor : kExpenseColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final user = context.watch<AuthProvider>().user;
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(s.settingsTitle),
        actions: [
          if (_editing)
            TextButton(onPressed: _saveProfile, child: Text(s.save))
          else
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => setState(() => _editing = true),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Avatar ────────────────────────────────────────────────
          Center(
            child: Stack(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: kPrimaryColor,
                    backgroundImage: _localAvatarPath != null
                        ? FileImage(File(_localAvatarPath!))
                        : null,
                    child: _localAvatarPath == null
                        ? Text(
                            user?.name.isNotEmpty == true
                                ? user!.name[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.w700),
                          )
                        : null,
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: kPrimaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            width: 2),
                      ),
                      child: const Icon(Icons.camera_alt,
                          color: Colors.white, size: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(s.tapToChangePhoto,
                style:
                    TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          ),
          const SizedBox(height: 24),

          // ── Profile info ──────────────────────────────────────────
          _SectionLabel(label: s.profile),
          const SizedBox(height: 8),
          if (_editing) ...[
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                  labelText: s.fullName,
                  prefixIcon: const Icon(Icons.person_outline)),
            ),
            const SizedBox(height: 16),
          ] else
            _InfoRow(label: s.nameLabel, value: user?.name ?? ''),
          _InfoRow(label: s.email, value: user?.email ?? ''),

          const SizedBox(height: 28),

          // ── Appearance ────────────────────────────────────────────
          _SectionLabel(label: s.appearance),
          const SizedBox(height: 8),
          _SettingCard(
            icon: Icons.brightness_6_outlined,
            iconColor: const Color(0xFFF4A935),
            title: s.theme,
            trailing: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                    value: ThemeMode.light,
                    icon: Icon(Icons.light_mode, size: 16)),
                ButtonSegment(
                    value: ThemeMode.system,
                    icon: Icon(Icons.phone_android, size: 16)),
                ButtonSegment(
                    value: ThemeMode.dark,
                    icon: Icon(Icons.dark_mode, size: 16)),
              ],
              selected: {themeProvider.themeMode},
              onSelectionChanged: (s) => themeProvider.setThemeMode(s.first),
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),

          const SizedBox(height: 12),

          _SettingCard(
            icon: Icons.language_outlined,
            iconColor: const Color(0xFF1677FF),
            title: s.language,
            trailing: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: themeProvider.language,
                isDense: true,
                items: const [
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(value: 'id', child: Text('Indonesia')),
                  DropdownMenuItem(value: 'zh', child: Text('中文')),
                ],
                onChanged: (v) {
                  if (v != null) themeProvider.setLanguage(v, context: context);
                },
              ),
            ),
          ),

          const SizedBox(height: 12),

          _SettingCard(
            icon: Icons.monetization_on_outlined,
            iconColor: const Color(0xFF52C41A),
            title: s.currency,
            trailing: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: themeProvider.currency,
                isDense: true,
                items: const [
                  DropdownMenuItem(value: 'IDR', child: Text('IDR')),
                  DropdownMenuItem(value: 'USD', child: Text('USD')),
                  DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                  DropdownMenuItem(value: 'SGD', child: Text('SGD')),
                ],
                onChanged: (v) {
                  if (v != null) themeProvider.setCurrency(v, context: context);
                },
              ),
            ),
          ),

          const SizedBox(height: 28),

          // ── Shortcuts ─────────────────────────────────────────────
          _SectionLabel(label: s.shortcuts),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            tileColor: Theme.of(context).cardTheme.color,
            leading: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: kPrimaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.bolt, color: kPrimaryColor, size: 18),
            ),
            title: Text(s.quickAddSettings, style: const TextStyle(fontWeight: FontWeight.w500)),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const QuickAddSettingsScreen()),
            ),
          ),

          const SizedBox(height: 28),

          // ── Danger zone ───────────────────────────────────────────
          _SectionLabel(label: s.account),
          const SizedBox(height: 8),
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            tileColor: kExpenseColor.withValues(alpha: 0.07),
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: kExpenseColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9)),
              child: const Icon(Icons.logout, color: kExpenseColor, size: 18),
            ),
            title: Text(s.signOut,
                style: const TextStyle(
                    color: kExpenseColor, fontWeight: FontWeight.w600)),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(s.signOutTitle),
                  content: Text(s.signOutMsg),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(s.cancel)),
                    TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(s.signOut,
                            style: const TextStyle(color: Colors.red))),
                  ],
                ),
              );
              if (confirmed == true && context.mounted) {
                context.read<AuthProvider>().logout();
              }
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(
        label.toUpperCase(),
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade500,
            letterSpacing: 0.8),
      );
}

class _SettingCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget trailing;

  const _SettingCard(
      {required this.icon,
      required this.iconColor,
      required this.title,
      required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Text(title,
                  style: const TextStyle(fontWeight: FontWeight.w500))),
          trailing,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)
          ],
        ),
        child: Row(
          children: [
            SizedBox(
                width: 72,
                child: Text(label,
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 13))),
            Expanded(
                child: Text(value,
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 14))),
          ],
        ),
      );
}
