// lib/screens/auth/forgot_password_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../api/auth_api.dart';
import '../../exceptions/app_exception.dart';

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
  bool _obscure   = true;
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
    if (_emailCtrl.text.trim().isEmpty) {
      setState(() => _error = '请输入邮箱');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authApiProvider).forgotPassword(_emailCtrl.text.trim());
      setState(() => _step = 1);
      _startCountdown();
    } catch (_) {
      setState(() => _error = '发送失败，请稍后重试');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_codeCtrl.text.trim().length != 6) {
      setState(() => _error = '请输入 6 位验证码');
      return;
    }
    if (_newPwCtrl.text.length < 8) {
      setState(() => _error = '密码至少 8 位');
      return;
    }
    if (_newPwCtrl.text != _confirmCtrl.text) {
      setState(() => _error = '两次密码不一致');
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
          const SnackBar(content: Text('密码重置成功，请重新登录'),
              behavior: SnackBarBehavior.floating));
      Navigator.pop(context);
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = '重置失败，请检查验证码');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(backgroundColor: Colors.transparent,
          title: const Text('重置密码'), centerTitle: true),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12)),
                    child: Text(_error!,
                        style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
                  ),
                  const SizedBox(height: 16),
                ],

                if (_step == 0) ...[
                  Text('输入注册邮箱', style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('我们将向您的邮箱发送重置验证码',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _deco('邮箱', Icons.email_outlined),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(height: 52,
                    child: FilledButton(
                      style: FilledButton.styleFrom(shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14))),
                      onPressed: _loading ? null : _sendCode,
                      child: _loading
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('发送验证码',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ] else ...[
                  Text('设置新密码', style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('验证码已发送至 ${_emailCtrl.text}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  const SizedBox(height: 24),

                  TextFormField(
                    controller: _codeCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: _deco('6位验证码', Icons.pin_outlined)
                        .copyWith(counterText: ''),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _newPwCtrl,
                    obscureText: _obscure,
                    decoration: _deco('新密码', Icons.lock_outline, suffix:
                      IconButton(icon: Icon(_obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined, size: 20),
                        onPressed: () => setState(() => _obscure = !_obscure))),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirmCtrl,
                    obscureText: _obscure,
                    decoration: _deco('确认新密码', Icons.lock_outline),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(height: 52,
                    child: FilledButton(
                      style: FilledButton.styleFrom(shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14))),
                      onPressed: _loading ? null : _resetPassword,
                      child: _loading
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('确认重置',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _countdown > 0 ? null : _sendCode,
                    child: Text(_countdown > 0
                        ? '重新发送（${_countdown}s）' : '重新发送验证码'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _deco(String label, IconData icon, {Widget? suffix}) =>
      InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: suffix,
        filled: true, fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      );
}