// lib/screens/auth/register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../api/auth_api.dart';
import '../../exceptions/app_exception.dart';
import 'verify_email_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl  = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    try {
      final data = await ref.read(authApiProvider).register(
            username: _usernameCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
          );

      if (!mounted) return;

      // debug_code 存在时直接传给验证页预填
      final debugCode = data['debug_code'] as String?;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => VerifyEmailScreen(
            email: _emailCtrl.text.trim(),
            debugCode: debugCode,   // ← 传过去
          ),
        ),
      );
    } on AppException catch (e) {
      setState(() { _error = e.message; });
    } catch (_) {
      setState(() { _error = '注册失败，请稍后重试'; });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('创建账号'),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null) ...[
                    _ErrorBanner(_error!),
                    const SizedBox(height: 16),
                  ],

                  _Field(
                    controller: _usernameCtrl,
                    label: '用户名',
                    icon: Icons.badge_outlined,
                    hint: '3-30位字母、数字或下划线',
                    action: TextInputAction.next,
                    validator: (v) {
                      if (v == null || v.trim().length < 3) return '用户名至少 3 位';
                      if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v.trim()))
                        return '只能包含字母、数字、下划线';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  _Field(
                    controller: _emailCtrl,
                    label: '邮箱',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    action: TextInputAction.next,
                    validator: (v) {
                      if (v == null || !v.contains('@')) return '请输入有效邮箱';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  _Field(
                    controller: _passwordCtrl,
                    label: '密码',
                    icon: Icons.lock_outline,
                    obscure: _obscure,
                    action: TextInputAction.next,
                    suffix: IconButton(
                      icon: Icon(
                          _obscure ? Icons.visibility_off_outlined
                                   : Icons.visibility_outlined,
                          size: 20),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                    validator: (v) {
                      if (v == null || v.length < 8) return '密码至少 8 位';
                      if (!v.contains(RegExp(r'[0-9]'))) return '需包含至少一个数字';
                      if (!v.contains(RegExp(r'[a-zA-Z]'))) return '需包含至少一个字母';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  _Field(
                    controller: _confirmCtrl,
                    label: '确认密码',
                    icon: Icons.lock_outline,
                    obscure: _obscure,
                    action: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    validator: (v) =>
                        v != _passwordCtrl.text ? '两次密码不一致' : null,
                  ),
                  const SizedBox(height: 28),

                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('注册',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),

                  const SizedBox(height: 12),
                  Text(
                    '注册即表示您同意我们的服务条款和隐私政策',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── 复用子组件 ─────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner(this.message);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Icon(Icons.error_outline, size: 18, color: Colors.red.shade700),
          const SizedBox(width: 8),
          Expanded(child: Text(message,
              style: TextStyle(color: Colors.red.shade700, fontSize: 13))),
        ]),
      );
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? action;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final void Function(String)? onSubmitted;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.obscure = false,
    this.keyboardType,
    this.action,
    this.suffix,
    this.validator,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        textInputAction: action,
        onFieldSubmitted: onSubmitted,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 13),
          prefixIcon: Icon(icon, size: 20),
          suffixIcon: suffix,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary, width: 1.5)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: validator,
      );
}