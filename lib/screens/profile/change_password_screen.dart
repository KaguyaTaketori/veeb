// lib/screens/profile/change_password_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../exceptions/app_exception.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/ui_core/vee_tokens.dart';
import '../../widgets/ui_core/vee_text_styles.dart';
import '../../widgets/ui_core/vee_error_banner.dart';
import '../../widgets/ui_core/vee_text_field.dart';
import '../../widgets/ui_core/vee_submit_button.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (_newCtrl.text.length < 8) {
      setState(() => _error = l10n.passwordMinLength);
      return;
    }
    if (_newCtrl.text != _confCtrl.text) {
      setState(() => _error = l10n.passwordsDoNotMatch);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(authProvider.notifier)
          .changePassword(
            oldPassword: _oldCtrl.text,
            newPassword: _newCtrl.text,
          );
      await ref.read(authProvider.notifier).logout();
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = l10n.changePasswordFailed);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.changePasswordTitle), centerTitle: true),
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

                // ── 当前密码 ─────────────────────────────────────────
                VeeTextField(
                  controller: _oldCtrl,
                  label: l10n.currentPassword,
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: VeeTokens.s14),

                // ── 新密码 ───────────────────────────────────────────
                VeeTextField(
                  controller: _newCtrl,
                  label: l10n.newPassword,
                  hint: l10n.passwordMinLength,
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: VeeTokens.s14),

                // ── 确认新密码 ───────────────────────────────────────
                VeeTextField(
                  controller: _confCtrl,
                  label: l10n.confirmNewPassword,
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: VeeTokens.s28),

                // ── 提交按钮 ─────────────────────────────────────────
                VeeSubmitButton(
                  label: l10n.confirm,
                  onPressed: _loading ? null : _submit,
                  isLoading: _loading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
