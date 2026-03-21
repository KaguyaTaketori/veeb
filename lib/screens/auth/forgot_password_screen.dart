// lib/screens/auth/forgot_password_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../api/auth_api.dart';
import '../../exceptions/app_exception.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/ui_core/vee_submit_button.dart';
import '../../widgets/ui_core/vee_error_banner.dart';
import '../../widgets/ui_core/vee_text_field.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailCtrl    = TextEditingController();
  final _codeCtrl     = TextEditingController();
  final _newPwCtrl    = TextEditingController();
  final _confirmCtrl  = TextEditingController();

  int  _step      = 0;   // 0=输邮箱, 1=输验证码+新密码
  bool _loading   = false;
  int  _countdown = 0;
  Timer? _timer;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose(); _codeCtrl.dispose();
    _newPwCtrl.dispose(); _confirmCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    setState(() => _countdown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown <= 1) { t.cancel(); setState(() => _countdown = 0); }
      else { setState(() => _countdown--); }
    });
  }

  Future<void> _sendCode() async {
    final l10n = AppLocalizations.of(context)!;
    if (_emailCtrl.text.trim().isEmpty) {
      setState(() => _error = l10n.enterEmail);
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authApiProvider).forgotPassword(_emailCtrl.text.trim());
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
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authApiProvider).resetPassword(
            email: _emailCtrl.text.trim(),
            code: _codeCtrl.text.trim(),
            newPassword: _newPwCtrl.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.resetPasswordSuccess),
              behavior: SnackBarBehavior.floating));
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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(backgroundColor: Colors.transparent,
          title: Text(l10n.resetPasswordTitle), centerTitle: true),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null) ...[
                  VeeErrorBanner(message: _error!),
                  const SizedBox(height: 16),
                ],

                if (_step == 0) ...[
                  Text(l10n.enterRegisteredEmail, style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(l10n.willSendResetCode,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  const SizedBox(height: 24),
                  VeeTextField(
                    controller: _emailCtrl,
                    label: l10n.email,
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => (v?.isEmpty ?? true) || !v!.contains('@') ? l10n.enterValidEmail : null,
                  ),
                  const SizedBox(height: 24),
                  VeeSubmitButton(
                    label: l10n.sendVerificationCode,
                    onPressed: _loading ? null : _sendCode,
                    isLoading: _loading,
                  ),
                ] else ...[
                  Text(l10n.setNewPassword, style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(l10n.verificationSentTo(_emailCtrl.text),
                      style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  const SizedBox(height: 24),

                  VeeTextField(
                    controller: _codeCtrl,
                    label: l10n.sixDigitCode,
                    prefixIcon: Icons.pin_outlined,
                    keyboardType: TextInputType.number,
                    validator: (v) => (v?.isEmpty ?? true) || v!.length != 6 ? l10n.enter6DigitCode : null,
                  ),
                  const SizedBox(height: 12),
                  VeeTextField(
                    controller: _newPwCtrl,
                    label: l10n.newPassword,
                    prefixIcon: Icons.lock_outline,
                    isPassword: true,
                    validator: (v) => (v?.isEmpty ?? true) ? l10n.enterPassword : null,
                  ),
                  const SizedBox(height: 12),
                  VeeTextField(
                    controller: _confirmCtrl,
                    label: l10n.confirmNewPassword,
                    prefixIcon: Icons.lock_outline,
                    isPassword: true,
                    validator: (v) => v != _newPwCtrl.text ? l10n.passwordsDoNotMatch : null,
                  ),
                  const SizedBox(height: 24),
                  VeeSubmitButton(
                    label: l10n.confirmReset,
                    onPressed: _loading ? null : _resetPassword,
                    isLoading: _loading,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _countdown > 0 ? null : _sendCode,
                    child: Text(_countdown > 0
                        ? l10n.resendCodeWithCountdown(_countdown) : l10n.resendCode),
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