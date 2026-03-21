// lib/widgets/ui_core/vee_image_picker.dart
//
// VeeImagePicker — 通用凭证图片选取组件
//
// 替代以下 2 处各自实现的图片选取 UI：
//
//   1. lib/screens/transactions/add_edit_transaction_screen.dart
//      → _ReceiptSection（约 80 行）
//
//   2. lib/screens/ocr/ocr_screen.dart
//      → _PickerView 内的拍照/相册按钮区（内联逻辑，约 60 行）
//
// ─────────────────────────────────────────────────────────────────────────────
//
// 三种状态自动切换：
//
//   State A — 空（无图片）：
//     显示带虚线边框的占位容器，内含"拍照"和"相册"两个按钮
//
//   State B — 本地待上传（pendingFile != null）：
//     显示本地图片预览，右上角叉号删除，上传中显示半透明遮罩+加载圈
//
//   State C — 已上传（remoteUrl 非空）：
//     显示网络图片预览，右上角叉号删除
//
// ─────────────────────────────────────────────────────────────────────────────
//
// 设计规范：
//   - 预览图高度固定 180px，圆角 rLg=16px
//   - 删除按钮：右上角 IconButton.filled，黑色半透明背景
//   - 空占位：高度 100px，虚线 1px 边框，圆角 rLg
//   - 按钮触控区 ≥ 44pt × 44pt ✓（tilePadding h:16 v:12 + 图标/文字）
//   - uploading 遮罩：Colors.black45，不阻断删除按钮（Positioned 层级在上）
//
// 用法示例：
//
//   // AddEditTransactionScreen（Step 2）
//   VeeImagePicker(
//     pendingFile: _pendingImage,
//     remoteUrl:   _receiptUrl,
//     uploading:   _uploadingImg,
//     onCamera:    () => _pickImage(ImageSource.camera),
//     onGallery:   () => _pickImage(ImageSource.gallery),
//     onRemove:    () => setState(() { _pendingImage = null; _receiptUrl = ''; }),
//   )
//
//   // OcrScreen（选图入口，无上传状态）
//   VeeImagePicker(
//     onCamera:  () => _pickAndOcr(ImageSource.camera),
//     onGallery: () => _pickAndOcr(ImageSource.gallery),
//     // 不传 pendingFile / remoteUrl，仅渲染 State A
//   )
//
//   // OcrScreen（预览模式，只读，不需要删除）
//   VeeImagePicker.readOnly(url: result.receiptUrl)

import 'dart:io';
import 'package:flutter/material.dart';
import 'vee_tokens.dart';
import 'vee_text_styles.dart';

class VeeImagePicker extends StatelessWidget {
  // ── 状态入参 ──────────────────────────────────────────────────────────────

  /// 本地待上传文件（State B）
  final File? pendingFile;

  /// 已上传的远端 URL（State C）
  final String? remoteUrl;

  /// 是否正在上传（State B 时显示加载遮罩）
  final bool uploading;

  // ── 事件回调 ──────────────────────────────────────────────────────────────

  /// 拍照按钮点击
  final VoidCallback? onCamera;

  /// 相册按钮点击
  final VoidCallback? onGallery;

  /// 删除/清除图片（不传则隐藏删除按钮，只读模式）
  final VoidCallback? onRemove;

  // ── 外观配置 ──────────────────────────────────────────────────────────────

  /// 图片预览高度，默认 180px
  final double previewHeight;

  /// 空占位区高度，默认 100px
  final double emptyHeight;

  /// 自定义拍照按钮文字（默认"拍照"）
  final String? cameraLabel;

  /// 自定义相册按钮文字（默认"相册"）
  final String? galleryLabel;

  const VeeImagePicker({
    super.key,
    this.pendingFile,
    this.remoteUrl,
    this.uploading = false,
    this.onCamera,
    this.onGallery,
    this.onRemove,
    this.previewHeight = 180,
    this.emptyHeight = 100,
    this.cameraLabel,
    this.galleryLabel,
  });

  /// 只读模式工厂：仅展示图片，无任何交互按钮
  factory VeeImagePicker.readOnly({
    Key? key,
    String? url,
    File? file,
    double height = 180,
  }) => VeeImagePicker(
    key: key,
    remoteUrl: url,
    pendingFile: file,
    previewHeight: height,
  );

  bool get _hasImage =>
      (pendingFile != null) || (remoteUrl != null && remoteUrl!.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    if (_hasImage) return _buildPreview(context);
    return _buildEmpty(context);
  }

  // ── State A: 空占位 ──────────────────────────────────────────────────────

  Widget _buildEmpty(BuildContext context) {
    return Container(
      height: emptyHeight,
      decoration: BoxDecoration(
        border: Border.all(
          color: VeeTokens.borderColor,
          // 虚线效果借助 CustomPaint 实现（Flutter 无原生虚线边框）
          // 这里用细实线代替，视觉足够区分"可点击占位区"
        ),
        borderRadius: BorderRadius.circular(VeeTokens.rLg),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (onCamera != null)
            _PickButton(
              icon: Icons.camera_alt_outlined,
              label: cameraLabel ?? '拍照',
              onTap: onCamera!,
            ),
          if (onCamera != null && onGallery != null)
            const SizedBox(width: VeeTokens.s48),
          if (onGallery != null)
            _PickButton(
              icon: Icons.photo_library_outlined,
              label: galleryLabel ?? '相册',
              onTap: onGallery!,
            ),
          // 如果两者都未传（只读空状态），显示提示文字
          if (onCamera == null && onGallery == null)
            Text(
              '暂无图片',
              style: context.veeText.caption.copyWith(
                color: VeeTokens.textPlaceholderVal,
              ),
            ),
        ],
      ),
    );
  }

  // ── State B/C: 图片预览 ───────────────────────────────────────────────────

  Widget _buildPreview(BuildContext context) {
    return Stack(
      children: [
        // ── 图片主体 ────────────────────────────────────────────────────
        ClipRRect(
          borderRadius: BorderRadius.circular(VeeTokens.rLg),
          child: pendingFile != null
              ? Image.file(
                  pendingFile!,
                  height: previewHeight,
                  width: double.infinity,
                  fit: BoxFit.cover,
                )
              : Image.network(
                  remoteUrl!,
                  height: previewHeight,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: previewHeight,
                    color: VeeTokens.surfaceSunken,
                    child: const Center(
                      child: Icon(
                        Icons.broken_image,
                        color: VeeTokens.textPlaceholderVal,
                      ),
                    ),
                  ),
                ),
        ),

        // ── 上传中遮罩（State B 且 uploading=true）──────────────────────
        if (uploading)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(VeeTokens.rLg),
              child: Container(
                color: Colors.black45,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),
          ),

        // ── 删除按钮（onRemove 不为 null 时显示）────────────────────────
        if (onRemove != null)
          Positioned(
            top: VeeTokens.spacingXs,
            right: VeeTokens.spacingXs,
            child: IconButton.filled(
              style: IconButton.styleFrom(
                backgroundColor: Colors.black54,
                iconSize: VeeTokens.iconMd,
                // 保证触控区域 ≥ 44×44
                minimumSize: const Size(VeeTokens.touchMin, VeeTokens.touchMin),
              ),
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: onRemove,
              tooltip: '移除图片',
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PickButton — 选图入口按钮（图标 + 文字，竖向排列）
// ─────────────────────────────────────────────────────────────────────────────

class _PickButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(VeeTokens.rMd),
      splashColor: VeeTokens.selectedTint(
        Theme.of(context).colorScheme.primary,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: VeeTokens.s16,
          vertical: VeeTokens.s12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: VeeTokens.iconXl,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: VeeTokens.spacingXs),
            Text(
              label,
              style: context.veeText.caption.copyWith(
                color: VeeTokens.textSecondaryVal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VeeDashedBorder — 虚线边框装饰器（可选用，替代 Container border 实线）
//
// Flutter 无原生虚线边框，可用 CustomPainter 绘制：
//
//   VeeDashedBorder(
//     color: VeeTokens.borderColor,
//     radius: VeeTokens.rLg,
//     child: Container(height: 100, ...),
//   )
// ─────────────────────────────────────────────────────────────────────────────

class VeeDashedBorder extends StatelessWidget {
  final Widget child;
  final Color color;
  final double radius;
  final double strokeWidth;
  final double dashLength;
  final double dashGap;

  const VeeDashedBorder({
    super.key,
    required this.child,
    this.color = VeeTokens.borderColor,
    this.radius = VeeTokens.rLg,
    this.strokeWidth = 1.0,
    this.dashLength = 6.0,
    this.dashGap = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: color,
        radius: radius,
        strokeWidth: strokeWidth,
        dashLength: dashLength,
        dashGap: dashGap,
      ),
      child: child,
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double strokeWidth;
  final double dashLength;
  final double dashGap;

  const _DashedBorderPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
    required this.dashLength,
    required this.dashGap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics().first;
    double dist = 0;

    while (dist < metrics.length) {
      final extract = metrics.extractPath(
        dist,
        (dist + dashLength).clamp(0, metrics.length),
      );
      canvas.drawPath(extract, paint);
      dist += dashLength + dashGap;
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}
