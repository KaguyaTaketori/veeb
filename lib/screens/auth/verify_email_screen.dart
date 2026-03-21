// lib/screens/auth/verify_email_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../api/auth_api.dart';
import '../../exceptions/app_exception.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/ui_core/vee_tokens.dart';
import '../../widgets/ui_core/vee_text_styles.dart';
import '../../widgets/ui_core/vee_error_banner.dart';
import '../../widgets/ui_core/vee_submit_button.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  final String email;
  final String? debugCode;

  const VerifyEmailScreen({super.key, required this.email, this.debugCode});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  late final TextEditingController _codeCtrl;
  bool _loading = false;
  bool _resending = false;
  String? _error;
  int _countdown = 0;
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
      if (_countdown <= 1) {
        t.cancel();
        setState(() => _countdown = 0);
      } else {
        setState(() => _countdown--);
      }
    });
  }

  Future<void> _verify() async {
    final l10n = AppLocalizations.of(context)!;
    final code = _codeCtrl.text.trim();
    if (code.length != 6) {
      setState(() => _error = l10n.enter6DigitCode);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ref
          .read(authApiProvider)
          .verifyEmail(email: widget.email, code: code);
      await AuthService.instance.saveTokens(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String,
      );
      await ref.read(authProvider.notifier).refreshProfile();
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = l10n.verificationFailed);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    final l10n = AppLocalizations.of(context)!;
    if (_countdown > 0 || _resending) return;
    setState(() {
      _resending = true;
      _error = null;
    });
    try {
      await ref.read(authApiProvider).resendCode(widget.email);
      _startCountdown();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.verificationSent),
            behavior: SnackBarBehavior.floating,
          ),
        );
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
      appBar: AppBar(title: Text(l10n.verifyEmailTitle), centerTitle: true),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: VeeTokens.maxFormWidth),
          child: Padding(
            padding: VeeTokens.formPadding.copyWith(
              top: VeeTokens.s24,
              bottom: VeeTokens.s24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── 图标 ──────────────────────────────────────────────
                Icon(
                  Icons.mark_email_unread_outlined,
                  size: VeeTokens.iconHero - 8,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: VeeTokens.spacingLg),

                // ── 标题 & 说明 ────────────────────────────────────────
                Text(
                  l10n.checkVerificationCode,
                  textAlign: TextAlign.center,
                  style: context.veeText.sectionTitle,
                ),
                const SizedBox(height: VeeTokens.spacingXs),
                Text(
                  l10n.verificationSentTo(widget.email),
                  textAlign: TextAlign.center,
                  style: context.veeText.caption.copyWith(
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: VeeTokens.s32),

                // ── 错误提示 ───────────────────────────────────────────
                if (_error != null) VeeErrorBanner(message: _error!),

                // ── 验证码输入框 ───────────────────────────────────────
                TextFormField(
                  controller: _codeCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: context.veeText.monoCode,
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '------',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade300,
                      fontSize: 28,
                      letterSpacing: 12,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: VeeTokens.spacingLg,
                    ),
                  ),
                  onChanged: (v) {
                    if (v.length == 6) _verify();
                  },
                ),
                const SizedBox(height: VeeTokens.s24),

                // ── 验证按钮 ───────────────────────────────────────────
                VeeSubmitButton(
                  label: l10n.verifyAndActivate,
                  onPressed: _loading ? null : _verify,
                  isLoading: _loading,
                ),
                const SizedBox(height: VeeTokens.spacingMd),

                // ── 重发验证码 ─────────────────────────────────────────
                TextButton(
                  onPressed: _countdown > 0 ? null : _resend,
                  child: Text(
                    _countdown > 0
                        ? l10n.resendCodeWithCountdown(_countdown)
                        : l10n.didNotReceiveResend,
                    style: context.veeText.bodyDefault,
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
