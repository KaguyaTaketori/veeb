import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'vee_tokens.dart';
import 'vee_text_styles.dart';

class VeeImagePicker extends StatelessWidget {
  final File? pendingFile;
  final String? remoteUrl;
  final bool uploading;
  final VoidCallback? onCamera;
  final VoidCallback? onGallery;
  final VoidCallback? onRemove;
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

  // ── State A: 空占位 ─────────────────────────────────────────────────────
  // dotted_border 替代自定义 VeeDashedBorder + _DashedBorderPainter

  Widget _buildEmpty(BuildContext context) {
    return DottedBorder(
      options: RoundedRectDottedBorderOptions(
        color: VeeTokens.borderColor,
        strokeWidth: 1.8,
        dashPattern: const [8, 4],
        radius: const Radius.circular(VeeTokens.rLg),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(VeeTokens.rLg),
        child: Container(
          height: emptyHeight,
          width: double.infinity,
          color: Theme.of(context).colorScheme.surface,
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
      ),
    );
  }

  // ── State B/C: 图片预览 ──────────────────────────────────────────────────
  // CachedNetworkImage 替代 Image.network：
  //   - 自动缓存到磁盘，重复查看不重新下载
  //   - 内置 placeholder（骨架占位）和 errorWidget
  //   - 与 Image.network 接口完全兼容，切换零迁移成本

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
              : CachedNetworkImage(
                  imageUrl: remoteUrl!,
                  height: previewHeight,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    height: previewHeight,
                    width: double.infinity,
                    color: VeeTokens.surfaceSunken,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    height: previewHeight,
                    width: double.infinity,
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
// _PickButton（与原版相同）
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
