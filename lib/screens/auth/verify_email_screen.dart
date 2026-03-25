import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pinput/pinput.dart';
import '../../api/auth_api.dart';
import '../../exceptions/app_exception.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/ui_core/vee_tokens.dart';
import '../../widgets/ui_core/vee_text_styles.dart';
import '../../widgets/ui_core/vee_error_banner.dart';
import '../../widgets/ui_core/vee_submit_button.dart';

class VerifyEmailScreen extends HookConsumerWidget {
  final String email;
  final String? debugCode;

  const VerifyEmailScreen({super.key, required this.email, this.debugCode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    final codeCtrl = useTextEditingController(text: debugCode ?? '');
    final loading = useState(false);
    final resending = useState(false);
    final error = useState<String?>(null);
    final countdown = useState(0);

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
      return timer.cancel;
    }, [countdown.value > 0]);

    Future<void> verify() async {
      final code = codeCtrl.text.trim();
      if (code.length != 6) {
        error.value = l10n.enter6DigitCode;
        return;
      }
      loading.value = true;
      error.value = null;
      try {
        final data =
            await ref.read(authApiProvider).verifyEmail({
                  'email': email,
                  'code': code,
                })
                as Map<String, dynamic>;
        await AuthService.instance.saveTokens(
          accessToken: data['access_token'] as String,
          refreshToken: data['refresh_token'] as String,
        );
        await ref.read(authProvider.notifier).refreshProfile();
      } on AppException catch (e) {
        error.value = e.message;
      } catch (_) {
        error.value = l10n.verificationFailed;
      } finally {
        loading.value = false;
      }
    }

    Future<void> resend() async {
      if (countdown.value > 0 || resending.value) return;
      resending.value = true;
      error.value = null;
      try {
        await ref.read(authApiProvider).resendCode({'email': email});
        countdown.value = 60;
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.verificationSent)));
        }
      } catch (_) {
        error.value = l10n.sendFailed;
      } finally {
        resending.value = false;
      }
    }

    // ── Pinput 三态样式 ─────────────────────────────────────────────────────

    final defaultTheme = PinTheme(
      width: 48,
      height: 56,
      textStyle: context.veeText.sectionTitle,
      decoration: BoxDecoration(
        border: Border.all(color: VeeTokens.borderColor),
        borderRadius: BorderRadius.circular(VeeTokens.rMd),
        color: Theme.of(context).colorScheme.surface,
      ),
    );

    final focusedTheme = defaultTheme.copyWith(
      textStyle: context.veeText.sectionTitle.copyWith(
        color: Theme.of(context).colorScheme.primary,
      ),
      decoration: defaultTheme.decoration!.copyWith(
        border: Border.all(
          color: Theme.of(context).colorScheme.primary,
          width: 1.5,
        ),
        color: VeeTokens.selectedTint(Theme.of(context).colorScheme.primary),
      ),
    );

    final submittedTheme = defaultTheme.copyWith(
      decoration: defaultTheme.decoration!.copyWith(
        color: VeeTokens.surfaceSunken,
        border: Border.all(color: VeeTokens.borderColor),
      ),
    );

    final errorTheme = defaultTheme.copyWith(
      decoration: defaultTheme.decoration!.copyWith(
        border: Border.all(color: VeeTokens.error, width: 1.5),
        color: VeeTokens.errorSurface,
      ),
    );

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
                Icon(
                  Icons.mark_email_unread_outlined,
                  size: VeeTokens.iconHero - 8,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: VeeTokens.spacingLg),
                Text(
                  l10n.checkVerificationCode,
                  textAlign: TextAlign.center,
                  style: context.veeText.sectionTitle,
                ),
                const SizedBox(height: VeeTokens.spacingXs),
                Text(
                  l10n.verificationSentTo(email),
                  textAlign: TextAlign.center,
                  style: context.veeText.caption.copyWith(
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: VeeTokens.s32),

                if (error.value != null) VeeErrorBanner(message: error.value!),

                // ── Pinput 替代 TextFormField ─────────────────────────────
                // 每格独立高亮；输满 6 位自动调用 verify()；
                // 删除了 hintText:'------' / letterSpacing:12 等视觉 hack
                Center(
                  child: Pinput(
                    length: 6,
                    controller: codeCtrl,
                    autofocus: true,
                    defaultPinTheme: defaultTheme,
                    focusedPinTheme: focusedTheme,
                    submittedPinTheme: submittedTheme,
                    errorPinTheme: errorTheme,
                    hapticFeedbackType: HapticFeedbackType.lightImpact,
                    onCompleted: (_) => verify(),
                    errorText: null,
                  ),
                ),

                const SizedBox(height: VeeTokens.s24),
                VeeSubmitButton(
                  label: l10n.verifyAndActivate,
                  onPressed: loading.value ? null : verify,
                  isLoading: loading.value,
                ),
                const SizedBox(height: VeeTokens.spacingMd),
                TextButton(
                  onPressed: countdown.value > 0 ? null : resend,
                  child: Text(
                    countdown.value > 0
                        ? l10n.resendCodeWithCountdown(countdown.value)
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
