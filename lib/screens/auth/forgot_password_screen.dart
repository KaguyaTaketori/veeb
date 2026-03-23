import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../api/auth_api.dart';
import '../../exceptions/app_exception.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/ui_core/vee_tokens.dart';
import '../../widgets/ui_core/vee_text_styles.dart';
import '../../widgets/ui_core/vee_error_banner.dart';
import '../../widgets/ui_core/vee_text_field.dart';
import '../../widgets/ui_core/vee_submit_button.dart';

class ForgotPasswordScreen extends HookConsumerWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    // Controller はフックが dispose を自動管理
    final emailCtrl = useTextEditingController();
    final codeCtrl = useTextEditingController();
    final newPwCtrl = useTextEditingController();
    final confirmCtrl = useTextEditingController();

    final step = useState(0); // 0=メール入力, 1=コード+新PW入力
    final loading = useState(false);
    final countdown = useState(0);
    final error = useState<String?>(null);

    // タイマーは useEffect で管理。countdown が 0 以外のときだけ起動
    useEffect(() {
      if (countdown.value <= 0) return null;
      final timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (countdown.value <= 1) {
          t.cancel();
          countdown.value = 0;
        } else {
          countdown.value--;
        }
      });
      return timer.cancel; // Widget 破棄時に自動キャンセル
    }, [countdown.value > 0]); // countdown が 0→1 になったときだけ再実行

    Future<void> sendCode() async {
      if (emailCtrl.text.trim().isEmpty) {
        error.value = l10n.enterEmail;
        return;
      }
      loading.value = true;
      error.value = null;
      try {
        await ref.read(authApiProvider).forgotPassword({
          'email': emailCtrl.text.trim(),
        });
        step.value = 1;
        countdown.value = 60; // useEffect が検知してタイマー起動
      } catch (_) {
        error.value = l10n.sendFailed;
      } finally {
        loading.value = false;
      }
    }

    Future<void> resetPassword() async {
      if (codeCtrl.text.trim().length != 6) {
        error.value = l10n.enter6DigitCode;
        return;
      }
      if (newPwCtrl.text.length < 8) {
        error.value = l10n.passwordMinLength;
        return;
      }
      if (newPwCtrl.text != confirmCtrl.text) {
        error.value = l10n.passwordsDoNotMatch;
        return;
      }
      loading.value = true;
      error.value = null;
      try {
        await ref.read(authApiProvider).resetPassword({
          'email': emailCtrl.text.trim(),
          'code': codeCtrl.text.trim(),
          'new_password': newPwCtrl.text,
        });
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.resetPasswordSuccess)));
          context.pop();
        }
      } on AppException catch (e) {
        error.value = e.message;
      } catch (_) {
        error.value = l10n.verificationFailed;
      } finally {
        loading.value = false;
      }
    }

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
                if (error.value != null) VeeErrorBanner(message: error.value!),

                if (step.value == 0) ...[
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
                    controller: emailCtrl,
                    label: l10n.email,
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: VeeTokens.s24),
                  VeeSubmitButton(
                    label: l10n.sendVerificationCode,
                    onPressed: loading.value ? null : sendCode,
                    isLoading: loading.value,
                  ),
                ] else ...[
                  Text(
                    l10n.setNewPassword,
                    style: context.veeText.sectionTitle,
                  ),
                  const SizedBox(height: VeeTokens.s24),
                  VeeTextField(
                    controller: codeCtrl,
                    label: l10n.sixDigitCode,
                    prefixIcon: Icons.pin_outlined,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: VeeTokens.s12),
                  VeeTextField(
                    controller: newPwCtrl,
                    label: l10n.newPassword,
                    prefixIcon: Icons.lock_outline,
                    isPassword: true,
                  ),
                  const SizedBox(height: VeeTokens.s12),
                  VeeTextField(
                    controller: confirmCtrl,
                    label: l10n.confirmNewPassword,
                    prefixIcon: Icons.lock_outline,
                    isPassword: true,
                  ),
                  const SizedBox(height: VeeTokens.s24),
                  VeeSubmitButton(
                    label: l10n.confirmReset,
                    onPressed: loading.value ? null : resetPassword,
                    isLoading: loading.value,
                  ),
                  const SizedBox(height: VeeTokens.s12),
                  TextButton(
                    onPressed: countdown.value > 0 ? null : sendCode,
                    child: Text(
                      countdown.value > 0
                          ? l10n.resendCodeWithCountdown(countdown.value)
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
