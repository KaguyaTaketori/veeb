// lib/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../home/home_screen.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import '../../widgets/ui_core/vee_tokens.dart';
import '../../widgets/ui_core/vee_text_styles.dart';
import '../../widgets/ui_core/vee_error_banner.dart';
import '../../widgets/ui_core/vee_text_field.dart';
import '../../widgets/ui_core/vee_submit_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _identCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref
        .read(authProvider.notifier)
        .login(_identCtrl.text.trim(), _passwordCtrl.text);
    if (success && mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = ref.watch(authProvider);
    final theme = Theme.of(context);

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
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Logo 区域 ──────────────────────────────────────
                    Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: VeeTokens.selectedTint(
                              theme.colorScheme.primary,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.receipt_long_outlined,
                            size: VeeTokens.iconXxl - 4,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: VeeTokens.spacingMd),
                        Text(
                          'Vee',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.primary,
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

                    // ── 错误提示 ───────────────────────────────────────
                    if (auth.error != null)
                      VeeErrorBanner(message: auth.error!),

                    // ── 用户名/邮箱 ────────────────────────────────────
                    VeeTextField(
                      controller: _identCtrl,
                      label: l10n.usernameOrEmail,
                      prefixIcon: Icons.person_outline,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (v) =>
                          v!.isEmpty ? l10n.enterUsernameOrEmail : null,
                    ),
                    const SizedBox(height: VeeTokens.spacingMd),

                    // ── 密码 ───────────────────────────────────────────
                    VeeTextField(
                      controller: _passwordCtrl,
                      label: l10n.password,
                      prefixIcon: Icons.lock_outline,
                      isPassword: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      validator: (v) =>
                          v == null || v.isEmpty ? l10n.enterPassword : null,
                    ),

                    // ── 忘记密码 ───────────────────────────────────────
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ForgotPasswordScreen(),
                          ),
                        ),
                        child: Text(
                          l10n.forgotPassword,
                          style: context.veeText.chipLabel,
                        ),
                      ),
                    ),
                    const SizedBox(height: VeeTokens.spacingXs),

                    // ── 登录按钮 ───────────────────────────────────────
                    VeeSubmitButton(
                      label: l10n.login,
                      onPressed: auth.loading ? null : _submit,
                      isLoading: auth.loading,
                    ),
                    const SizedBox(height: VeeTokens.s24),

                    // ── 注册入口 ───────────────────────────────────────
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
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          ),
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
