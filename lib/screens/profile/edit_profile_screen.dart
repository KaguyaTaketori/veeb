// lib/screens/profile/edit_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../exceptions/app_exception.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/ui_core/vee_error_banner.dart';
import '../../widgets/ui_core/vee_text_field.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final UserProfile user;
  const EditProfileScreen({super.key, required this.user});
  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _nameCtrl;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.displayName ?? '');
  }

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = l10n.nicknameRequired);
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authProvider.notifier).updateProfile(
            displayName: _nameCtrl.text.trim());
      if (mounted) Navigator.pop(context, true);
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = l10n.saveFailed);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(l10n.editProfileTitle),
        centerTitle: true,
        actions: [
          if (_loading)
            const Center(child: Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            ))
          else
            TextButton(onPressed: _save,
                child: Text(l10n.save, style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 15))),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null) ...[
                  VeeErrorBanner(message: _error!),
                  const SizedBox(height: 16),
                ],
                VeeTextField(
                  controller: _nameCtrl,
                  label: l10n.fullName,
                  prefixIcon: Icons.person_outline,
                  validator: (v) => (v?.trim().isEmpty ?? true) ? l10n.nicknameRequired : null,
                ),
                const SizedBox(height: 8),
                Text(l10n.usernameEmailCannotChange,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
          ),
        ),
      ),
    );
  }
}