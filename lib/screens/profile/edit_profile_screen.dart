// lib/screens/profile/edit_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vee_app/widgets/ui_core/vee_button_spinner.dart';
import '../../exceptions/app_exception.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/ui_core/vee_tokens.dart';
import '../../widgets/ui_core/vee_text_styles.dart';
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
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = l10n.nicknameRequired);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(authProvider.notifier)
          .updateProfile(displayName: _nameCtrl.text.trim());
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
      appBar: AppBar(
        title: Text(l10n.editProfileTitle),
        centerTitle: true,
        actions: [
          // 保存按钮放在 AppBar actions，loading 时换成 indicator
          if (_loading)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: VeeTokens.s16),
                child: VeeButtonSpinner(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: Text(
                l10n.save,
                style: context.veeText.chipLabel.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: VeeTokens.maxFormWidth),
          child: Padding(
            padding: VeeTokens.formPadding.copyWith(
              top: VeeTokens.s24,
              bottom: VeeTokens.s24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── 错误提示 ─────────────────────────────────────────
                if (_error != null) VeeErrorBanner(message: _error!),

                // ── 昵称输入框 ───────────────────────────────────────
                VeeTextField(
                  controller: _nameCtrl,
                  label: l10n.fullName,
                  prefixIcon: Icons.person_outline,
                  validator: (v) => (v?.trim().isEmpty ?? true)
                      ? l10n.nicknameRequired
                      : null,
                ),
                const SizedBox(height: VeeTokens.spacingXs),

                // ── 不可修改提示 ─────────────────────────────────────
                Text(
                  l10n.usernameEmailCannotChange,
                  style: context.veeText.micro.copyWith(
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
