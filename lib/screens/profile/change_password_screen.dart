// lib/screens/profile/change_password_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../api/auth_api.dart';
import '../../exceptions/app_exception.dart';
import '../../providers/auth_provider.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});
  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _oldCtrl  = TextEditingController();
  final _newCtrl  = TextEditingController();
  final _confCtrl = TextEditingController();
  bool _obscure = true, _loading = false;
  String? _error;

  @override
  void dispose() {
    _oldCtrl.dispose(); _newCtrl.dispose(); _confCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_newCtrl.text.length < 8) {
      setState(() => _error = '新密码至少 8 位');
      return;
    }
    if (_newCtrl.text != _confCtrl.text) {
      setState(() => _error = '两次密码不一致');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(meApiProvider).changePassword(
            oldPassword: _oldCtrl.text,
            newPassword: _newCtrl.text,
          );
      // 修改密码后服务端吊销所有 token，强制重新登录
      await ref.read(authProvider.notifier).logout();
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = '修改失败，请稍后重试');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(backgroundColor: Colors.transparent,
          title: const Text('修改密码'), centerTitle: true),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12)),
                    child: Text(_error!, style: TextStyle(
                        color: Colors.red.shade700, fontSize: 13)),
                  ),
                  const SizedBox(height: 16),
                ],
                _pwField(_oldCtrl, '当前密码'),
                const SizedBox(height: 14),
                _pwField(_newCtrl, '新密码', hint: '至少 8 位，含字母和数字'),
                const SizedBox(height: 14),
                _pwField(_confCtrl, '确认新密码'),
                const SizedBox(height: 28),
                SizedBox(height: 52,
                  child: FilledButton(
                    style: FilledButton.styleFrom(shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('确认修改',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pwField(TextEditingController ctrl, String label, {String? hint}) =>
      TextFormField(
        controller: ctrl,
        obscureText: _obscure,
        decoration: InputDecoration(
          labelText: label, hintText: hint,
          hintStyle: const TextStyle(fontSize: 13),
          prefixIcon: const Icon(Icons.lock_outline, size: 20),
          suffixIcon: IconButton(
            icon: Icon(_obscure ? Icons.visibility_off_outlined
                                 : Icons.visibility_outlined, size: 20),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
          filled: true, fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      );
}