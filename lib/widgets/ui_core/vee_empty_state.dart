// lib/widgets/ui_core/vee_empty_state.dart
//
// VeeEmptyState — 空状态占位组件
//
// v2 변경사항 (Fix 10):
//   이전: 아이콘이 흰 배경에 그대로 떠있어 시각적 무게감 없음
//         Icon(icon, size: iconHero, color: Colors.grey.shade300)
//
//   이후: 아이콘을 브랜드/의미론적 색상의 원형 컨테이너에 담아
//         "의도적으로 설계된 빈 상태"처럼 느껴지도록 개선
//         - 컨테이너: 72×72 원형, selectedTint(color) 배경
//         - 아이콘: iconXxl(48px), color 자체로 채색
//         - 기본 iconColor가 null이면 primary 색상 사용 (회색 → 브랜드 색)
//         - 에러 상태는 VeeTokens.error 전달 → 빨간 원형 컨테이너
//
// 시각적 효과:
//   - Profile Guest 헤더의 아바타 컨테이너와 동일한 처리 방식으로 통일
//   - 아이콘 하나가 아니라 "아이콘 + 원형 배경"이 함께 읽혀 정보 계층 형성
//   - 브랜드 오렌지 기본값: 빈 상태가 에러처럼 느껴지지 않고 부드럽게 안내

import 'package:flutter/material.dart';
import 'vee_tokens.dart';
import 'vee_text_styles.dart';

class VeeEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// 아이콘 및 컨테이너 색상.
  /// null이면 Theme.colorScheme.primary 사용 (브랜드 오렌지).
  /// 에러 상태: VeeTokens.error
  /// 성공 상태: VeeTokens.success
  final Color? iconColor;

  /// 원형 컨테이너를 표시할지 여부.
  /// false로 설정하면 v1 동작(아이콘만 표시)으로 폴백.
  final bool showContainer;

  /// 원형 컨테이너 크기, 기본 72px
  final double containerSize;

  const VeeEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.iconColor,
    this.showContainer = true,
    this.containerSize = 72.0,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = iconColor ?? Theme.of(context).colorScheme.primary;

    return Center(
      child: Padding(
        padding: VeeTokens.formPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── 아이콘 영역 ────────────────────────────────────────────────
            if (showContainer)
              _IconContainer(
                icon: icon,
                color: effectiveColor,
                containerSize: containerSize,
              )
            else
              Icon(
                icon,
                size: VeeTokens.iconHero,
                color: effectiveColor.withOpacity(0.35),
              ),

            const SizedBox(height: VeeTokens.spacingMd),

            // ── 제목 ────────────────────────────────────────────────────────
            Text(
              title,
              style: context.veeText.cardTitle.copyWith(
                color: VeeTokens.textSecondaryVal,
              ),
              textAlign: TextAlign.center,
            ),

            // ── 부제목 ──────────────────────────────────────────────────────
            if (subtitle != null) ...[
              const SizedBox(height: VeeTokens.spacingXs),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: context.veeText.caption.copyWith(
                  color: VeeTokens.textPlaceholderVal,
                  height: 1.5,
                ),
              ),
            ],

            // ── 액션 버튼 ────────────────────────────────────────────────────
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: VeeTokens.spacingLg),
              FilledButton.tonal(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _IconContainer extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double containerSize;

  const _IconContainer({
    required this.icon,
    required this.color,
    required this.containerSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: containerSize + 24,
      height: containerSize + 24,
      decoration: BoxDecoration(
        color: VeeTokens.surfaceTint(color),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Container(
        width: containerSize,
        height: containerSize,
        decoration: BoxDecoration(
          color: VeeTokens.selectedTint(color),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: VeeTokens.iconXxl, color: color),
      ),
    );
  }
}
