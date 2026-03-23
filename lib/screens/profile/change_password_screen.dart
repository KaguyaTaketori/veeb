import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../exceptions/app_exception.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/ui_core/vee_tokens.dart';
import '../../widgets/ui_core/vee_error_banner.dart';
import '../../widgets/ui_core/vee_text_field.dart';
import '../../widgets/ui_core/vee_submit_button.dart';

class ChangePasswordScreen extends HookConsumerWidget {
  const ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final oldCtrl = useTextEditingController();
    final newCtrl = useTextEditingController();
    final confCtrl = useTextEditingController();
    final loading = useState(false);
    final error = useState<String?>(null);

    Future<void> submit() async {
      if (newCtrl.text.length < 8) {
        error.value = l10n.passwordMinLength;
        return;
      }
      if (newCtrl.text != confCtrl.text) {
        error.value = l10n.passwordsDoNotMatch;
        return;
      }
      loading.value = true;
      error.value = null;
      try {
        await ref
            .read(authProvider.notifier)
            .changePassword(
              oldPassword: oldCtrl.text,
              newPassword: newCtrl.text,
            );
        await ref.read(authProvider.notifier).logout();
        // logout で authProvider が unauthenticated になり
        // router が /login にリダイレクト
      } on AppException catch (e) {
        error.value = e.message;
      } catch (_) {
        error.value = l10n.changePasswordFailed;
      } finally {
        loading.value = false;
      }
    }

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
                if (error.value != null) VeeErrorBanner(message: error.value!),
                VeeTextField(
                  controller: oldCtrl,
                  label: l10n.currentPassword,
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: VeeTokens.s14),
                VeeTextField(
                  controller: newCtrl,
                  label: l10n.newPassword,
                  hint: l10n.passwordMinLength,
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: VeeTokens.s14),
                VeeTextField(
                  controller: confCtrl,
                  label: l10n.confirmNewPassword,
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: VeeTokens.s28),
                VeeSubmitButton(
                  label: l10n.confirm,
                  onPressed: loading.value ? null : submit,
                  isLoading: loading.value,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
