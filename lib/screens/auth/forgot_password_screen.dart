// lib/screens/auth/forgot_password_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../api/auth_api.dart';
import '../../exceptions/app_exception.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/ui_core/vee_tokens.dart';
import '../../widgets/ui_core/vee_text_styles.dart';
import '../../widgets/ui_core/vee_error_banner.dart';
import '../../widgets/ui_core/vee_text_field.dart';
import '../../widgets/ui_core/vee_submit_button.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _newPwCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  int _step = 0; // 0=输邮箱, 1=输验证码+新密码
  bool _loading = false;
  int _countdown = 0;
  Timer? _timer;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _newPwCtrl.dispose();
    _confirmCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    setState(() => _countdown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown <= 1) {
        t.cancel();
        setState(() => _countdown = 0);
      } else {
        setState(() => _countdown--);
      }
    });
  }

  Future<void> _sendCode() async {
    final l10n = AppLocalizations.of(context)!;
    if (_emailCtrl.text.trim().isEmpty) {
      setState(() => _error = l10n.enterEmail);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authApiProvider).forgotPassword({
        'email': _emailCtrl.text.trim(),
      });
      setState(() => _step = 1);
      _startCountdown();
    } catch (_) {
      setState(() => _error = l10n.sendFailed);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final l10n = AppLocalizations.of(context)!;
    if (_codeCtrl.text.trim().length != 6) {
      setState(() => _error = l10n.enter6DigitCode);
      return;
    }
    if (_newPwCtrl.text.length < 8) {
      setState(() => _error = l10n.passwordMinLength);
      return;
    }
    if (_newPwCtrl.text != _confirmCtrl.text) {
      setState(() => _error = l10n.passwordsDoNotMatch);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authApiProvider).resetPassword({
        'email': _emailCtrl.text.trim(),
        'code': _codeCtrl.text.trim(),
        'new_password': _newPwCtrl.text,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.resetPasswordSuccess),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = l10n.verificationFailed);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.resetPasswordTitle), centerTitle: true),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: VeeTokens.maxFormWidth),
          child: SingleChildScrollView(
            padding: VeeTokens.formPadding.copyWith(
              top: VeeTokens.s24,
              bottom: VeeTokens.s24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── 错误提示 ─────────────────────────────────────────
                if (_error != null) VeeErrorBanner(message: _error!),

                if (_step == 0) ...[
                  // ── Step 0：输入邮箱 ─────────────────────────────
                  Text(
                    l10n.enterRegisteredEmail,
                    style: context.veeText.sectionTitle,
                  ),
                  const SizedBox(height: VeeTokens.spacingXs),
                  Text(
                    l10n.willSendResetCode,
                    style: context.veeText.caption.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: VeeTokens.s24),

                  VeeTextField(
                    controller: _emailCtrl,
                    label: l10n.email,
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => (v?.isEmpty ?? true) || !v!.contains('@')
                        ? l10n.enterValidEmail
                        : null,
                  ),
                  const SizedBox(height: VeeTokens.s24),

                  VeeSubmitButton(
                    label: l10n.sendVerificationCode,
                    onPressed: _loading ? null : _sendCode,
                    isLoading: _loading,
                  ),
                ] else ...[
                  // ── Step 1：输入验证码 + 新密码 ──────────────────
                  Text(
                    l10n.setNewPassword,
                    style: context.veeText.sectionTitle,
                  ),
                  const SizedBox(height: VeeTokens.spacingXs),
                  Text(
                    l10n.verificationSentTo(_emailCtrl.text),
                    style: context.veeText.caption.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: VeeTokens.s24),

                  VeeTextField(
                    controller: _codeCtrl,
                    label: l10n.sixDigitCode,
                    prefixIcon: Icons.pin_outlined,
                    keyboardType: TextInputType.number,
                    validator: (v) => (v?.isEmpty ?? true) || v!.length != 6
                        ? l10n.enter6DigitCode
                        : null,
                  ),
                  const SizedBox(height: VeeTokens.s12),

                  VeeTextField(
                    controller: _newPwCtrl,
                    label: l10n.newPassword,
                    prefixIcon: Icons.lock_outline,
                    isPassword: true,
                    validator: (v) =>
                        (v?.isEmpty ?? true) ? l10n.enterPassword : null,
                  ),
                  const SizedBox(height: VeeTokens.s12),

                  VeeTextField(
                    controller: _confirmCtrl,
                    label: l10n.confirmNewPassword,
                    prefixIcon: Icons.lock_outline,
                    isPassword: true,
                    validator: (v) =>
                        v != _newPwCtrl.text ? l10n.passwordsDoNotMatch : null,
                  ),
                  const SizedBox(height: VeeTokens.s24),

                  VeeSubmitButton(
                    label: l10n.confirmReset,
                    onPressed: _loading ? null : _resetPassword,
                    isLoading: _loading,
                  ),
                  const SizedBox(height: VeeTokens.s12),

                  // ── 重发验证码 ────────────────────────────────────
                  TextButton(
                    onPressed: _countdown > 0 ? null : _sendCode,
                    child: Text(
                      _countdown > 0
                          ? l10n.resendCodeWithCountdown(_countdown)
                          : l10n.resendCode,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
