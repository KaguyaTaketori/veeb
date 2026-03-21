// lib/widgets/ui_core/vee_image_picker.dart
//
// 变更说明（Layer 3 升级）：
//   - VeeImagePicker._buildEmpty：
//     原来使用 Container(decoration: BoxDecoration(border: Border.all(...)))，
//     实线边框在视觉上与其他表单卡片没有区别，无法传达"这是一个可上传的占位区"。
//     现在改用已定义在本文件底部的 VeeDashedBorder 包裹，虚线边框更直观地
//     表达"这里可以放东西进来"的 drop-zone 语义。
//   - VeeDashedBorder 及其 _DashedBorderPainter 代码完全不变。
//   - 其余功能、接口与原版完全一致。

import 'dart:io';
import 'package:flutter/material.dart';
import 'vee_tokens.dart';
import 'vee_text_styles.dart';

class VeeImagePicker extends StatelessWidget {
  // ── 状态入参 ──────────────────────────────────────────────────────────────

  final File? pendingFile;
  final String? remoteUrl;
  final bool uploading;

  // ── 事件回调 ──────────────────────────────────────────────────────────────

  final VoidCallback? onCamera;
  final VoidCallback? onGallery;
  final VoidCallback? onRemove;

  // ── 外观配置 ──────────────────────────────────────────────────────────────

  final double previewHeight;
  final double emptyHeight;
  final String? cameraLabel;
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

  // ── State A: 空占位（Layer 3 升级：实线边框 → VeeDashedBorder）──────────
  //
  // 虚线边框在 UI 设计中是"拖拽放置区 / 可上传占位区"的通用语义，
  // 比实线边框更清晰地告诉用户"这里可以添加图片"。
  // VeeDashedBorder 已在本文件底部定义，无需额外 import。

  Widget _buildEmpty(BuildContext context) {
    return VeeDashedBorder(
      color: VeeTokens.borderColor,
      radius: VeeTokens.rLg,
      strokeWidth: 1.8,
      dashLength: 8.0,
      dashGap: 4.0,
      child: Container(
        height: emptyHeight,
        decoration: BoxDecoration(
          // 去掉 border，由 VeeDashedBorder 统一绘制
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
            if (onCamera == null && onGallery == null)
              Text(
                '暂无图片',
                style: context.veeText.caption.copyWith(
                  color: VeeTokens.textPlaceholderVal,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── State B/C: 图片预览（与原版完全相同）─────────────────────────────────

  Widget _buildPreview(BuildContext context) {
    return Stack(
      children: [
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

        if (onRemove != null)
          Positioned(
            top: VeeTokens.spacingXs,
            right: VeeTokens.spacingXs,
            child: IconButton.filled(
              style: IconButton.styleFrom(
                backgroundColor: Colors.black54,
                iconSize: VeeTokens.iconMd,
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
// _PickButton（与原版完全相同）
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
// VeeDashedBorder（与原版完全相同，现在被 _buildEmpty 实际使用）
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
