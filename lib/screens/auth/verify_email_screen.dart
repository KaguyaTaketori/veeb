// lib/screens/auth/verify_email_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../api/auth_api.dart';
import '../../exceptions/app_exception.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/ui_core/vee_error_banner.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  final String email;
  final String? debugCode;

  const VerifyEmailScreen({
    super.key,
    required this.email,
    this.debugCode,
  });

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  late final TextEditingController _codeCtrl;
  bool _loading   = false;
  bool _resending = false;
  String? _error;
  int _countdown  = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _codeCtrl = TextEditingController(text: widget.debugCode ?? '');
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
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

  Future<void> _verify() async {
    final l10n = AppLocalizations.of(context)!;
    final code = _codeCtrl.text.trim();
    if (code.length != 6) {
      setState(() => _error = l10n.enter6DigitCode);
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ref.read(authApiProvider).verifyEmail(
            email: widget.email, code: code);
      await AuthService.instance.saveTokens(
        accessToken:  data['access_token']  as String,
        refreshToken: data['refresh_token'] as String,
      );
      await ref.read(authProvider.notifier).refreshProfile();
    } on AppException catch (e) {
      setState(() { _error = e.message; });
    } catch (_) {
      setState(() { _error = l10n.verificationFailed; });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    final l10n = AppLocalizations.of(context)!;
    if (_countdown > 0 || _resending) return;
    setState(() { _resending = true; _error = null; });
    try {
      await ref.read(authApiProvider).resendCode(widget.email);
      _startCountdown();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.verificationSent),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (_) {
      setState(() => _error = l10n.sendFailed);
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(backgroundColor: Colors.transparent, centerTitle: true,
          title: Text(l10n.verifyEmailTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.mark_email_unread_outlined,
                    size: 56, color: theme.colorScheme.primary),
                const SizedBox(height: 20),
                Text(l10n.checkVerificationCode, textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(l10n.verificationSentTo(widget.email),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600], height: 1.5)),
                const SizedBox(height: 32),

                if (_error != null) ...[
                  VeeErrorBanner(message: _error!),
                  const SizedBox(height: 16),
                ],

                TextFormField(
                  controller: _codeCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold,
                      letterSpacing: 12),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '------',
                    hintStyle: TextStyle(
                        color: Colors.grey.shade300,
                        fontSize: 28, letterSpacing: 12),
                    filled: true, fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade300)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                            color: theme.colorScheme.primary, width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 20),
                  ),
                  onChanged: (v) { if (v.length == 6) _verify(); },
                ),
                const SizedBox(height: 24),

                SizedBox(
                  height: 52,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14))),
                    onPressed: _loading ? null : _verify,
                    child: _loading
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text(l10n.verifyAndActivate,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 16),

                TextButton(
                  onPressed: _countdown > 0 ? null : _resend,
                  child: Text(_countdown > 0
                      ? l10n.resendCodeWithCountdown(_countdown)
                      : l10n.didNotReceiveResend,
                      style: const TextStyle(fontSize: 14)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}