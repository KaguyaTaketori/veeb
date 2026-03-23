import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/ui_core/vee_tokens.dart';
import '../../widgets/ui_core/vee_text_styles.dart';
import '../../widgets/ui_core/vee_error_banner.dart';
import '../../widgets/ui_core/vee_text_field.dart';
import '../../widgets/ui_core/vee_submit_button.dart';

class LoginScreen extends HookConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final identCtrl = useTextEditingController();
    final passwordCtrl = useTextEditingController();
    final formKey = useMemoized(GlobalKey<FormState>.new);

    // auth の loading と error は Provider から取得
    final auth = ref.watch(authProvider);

    Future<void> submit() async {
      if (!formKey.currentState!.validate()) return;
      final success = await ref
          .read(authProvider.notifier)
          .login(identCtrl.text.trim(), passwordCtrl.text);
      if (success && context.mounted) {
        context.go('/transactions');
      }
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: VeeTokens.maxFormWidth),
            child: SingleChildScrollView(
              padding: VeeTokens.formPadding.copyWith(
                top: VeeTokens.s40,
                bottom: VeeTokens.s40,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ロゴ部分（変更なし）
                    Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: VeeTokens.selectedTint(
                              Theme.of(context).colorScheme.primary,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.receipt_long_outlined,
                            size: VeeTokens.iconXxl - 4,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: VeeTokens.spacingMd),
                        Text(
                          'Vee',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        const SizedBox(height: VeeTokens.spacingXxs),
                        Text(
                          l10n.smartBillAssistant,
                          style: context.veeText.caption.copyWith(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: VeeTokens.s40),

                    if (auth.error != null)
                      VeeErrorBanner(message: auth.error!),

                    VeeTextField(
                      controller: identCtrl,
                      label: l10n.usernameOrEmail,
                      prefixIcon: Icons.person_outline,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (v) =>
                          v!.isEmpty ? l10n.enterUsernameOrEmail : null,
                    ),
                    const SizedBox(height: VeeTokens.spacingMd),
                    VeeTextField(
                      controller: passwordCtrl,
                      label: l10n.password,
                      prefixIcon: Icons.lock_outline,
                      isPassword: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => submit(),
                      validator: (v) =>
                          v == null || v.isEmpty ? l10n.enterPassword : null,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.push('/forgot-password'),
                        child: Text(
                          l10n.forgotPassword,
                          style: context.veeText.chipLabel,
                        ),
                      ),
                    ),
                    const SizedBox(height: VeeTokens.spacingXs),
                    VeeSubmitButton(
                      label: l10n.login,
                      onPressed: auth.loading ? null : submit,
                      isLoading: auth.loading,
                    ),
                    const SizedBox(height: VeeTokens.s24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.dontHaveAccount,
                          style: context.veeText.caption.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/register'),
                          child: Text(
                            l10n.signUp,
                            style: context.veeText.chipLabel.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
