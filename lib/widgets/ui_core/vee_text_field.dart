// lib/widgets/ui_core/vee_text_field.dart
//
// VeeTextField — 统一文本输入框
// Phase 2 更新：
//   - 大量依赖全局 InputDecorationTheme（Phase 1 已在 VeeApp 注入）
//   - 不再手写 border / fillColor / contentPadding（继承全局 Theme）
//   - 仅处理组件层面的差异化（label、icon、密码显示/隐藏、校验器）

import 'package:flutter/material.dart';
import 'vee_tokens.dart';
import 'vee_text_styles.dart';

class VeeTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final bool isPassword;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onSubmitted;
  final void Function(String)? onChanged;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool readOnly;
  final int? maxLines;
  final int? maxLength;

  const VeeTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.isPassword = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onSubmitted,
    this.onChanged,
    this.focusNode,
    this.autofocus = false,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
  });

  @override
  State<VeeTextField> createState() => _VeeTextFieldState();
}

class _VeeTextFieldState extends State<VeeTextField> {
  late bool _obscure;

  @override
  void initState() {
    super.initState();
    _obscure = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    // 全局 InputDecorationTheme（Phase 1 注入）已处理：
    //   - border / enabledBorder / focusedBorder / errorBorder
    //   - filled / fillColor / contentPadding / hintStyle / labelStyle
    // 此处只声明差异化的属性即可。

    return TextFormField(
      controller:       widget.controller,
      focusNode:        widget.focusNode,
      autofocus:        widget.autofocus,
      readOnly:         widget.readOnly,
      obscureText:      _obscure,
      keyboardType:     widget.keyboardType,
      textInputAction:  widget.textInputAction,
      onFieldSubmitted: widget.onSubmitted,
      onChanged:        widget.onChanged,
      validator:        widget.validator,
      maxLines:         widget.isPassword ? 1 : widget.maxLines,
      maxLength:        widget.maxLength,
      style: context.veeText.bodyDefault,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText:  widget.hint,
        prefixIcon: widget.prefixIcon != null
            ? Icon(widget.prefixIcon, size: VeeTokens.iconMd)
            : null,
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: VeeTokens.iconMd,
                  color: VeeTokens.textPlaceholderVal,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
                tooltip: _obscure ? '显示密码' : '隐藏密码',
              )
            : null,
        // border / fillColor / contentPadding 均继承自全局 Theme，不在此处重复声明
      ),
    );
  }
}