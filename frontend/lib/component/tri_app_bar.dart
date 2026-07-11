import 'package:flutter/material.dart';

import '../config/app_colors.dart';
import '../config/app_spacing.dart';

/// AppBar tuỳ biến theo brand TriChat — gradient cam cháy nhẹ,
/// bo tròn góc dưới, shadow mềm, có hỗ trợ leading/title/actions.
///
/// Thay thế cho ZaloAppBar (cũ - màu xanh cứng) và các AppBar ad-hoc
/// rải rác trong app.
class TriAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Tiêu đề hiển thị ở giữa/trái.
  final String title;

  /// Widget tuỳ biến thay cho title text. Nếu truyền thì [title] bị bỏ.
  final Widget? titleWidget;

  /// Nút leading. Mặc định là nút back nếu [showBackButton] = true.
  final Widget? leading;

  /// Icon hiển thị leading nếu không truyền [leading].
  final IconData backIcon;

  /// Hành động khi ấn leading/back.
  final VoidCallback? onBack;

  /// Có hiển thị nút back hay không.
  final bool showBackButton;

  /// Danh sách action ở bên phải.
  final List<Widget> actions;

  /// Màu nền gradient — mặc định dùng [AppColors.appBarGradient].
  final List<Color>? gradientColors;

  /// Màu chữ/Icon — mặc định trắng.
  final Color foregroundColor;

  /// Có bo cong góc dưới hay không (mặc định true).
  final bool roundedBottom;

  /// Padding ngang custom cho title.
  final double titleSpacing;

  const TriAppBar({
    super.key,
    this.title = '',
    this.titleWidget,
    this.leading,
    this.backIcon = Icons.arrow_back_rounded,
    this.onBack,
    this.showBackButton = false,
    this.actions = const [],
    this.gradientColors,
    this.foregroundColor = Colors.white,
    this.roundedBottom = true,
    this.titleSpacing = 0,
  });

  @override
  Widget build(BuildContext context) {
    final colors = gradientColors ?? AppColors.appBarGradient;
    final Widget leadingWidget = leading ??
        (showBackButton
            ? IconButton(
                icon: Icon(backIcon, color: foregroundColor, size: 22),
                splashRadius: 22,
                onPressed: onBack ?? () => Navigator.of(context).maybePop(),
              )
            : const SizedBox.shrink());

    final Widget titleContent = titleWidget ??
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Roboto',
            color: foregroundColor,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: roundedBottom
            ? const BorderRadius.vertical(
                bottom: Radius.circular(AppRadius.lg),
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: kToolbarHeight,
          child: Row(
            children: [
              SizedBox(width: leadingWidget is SizedBox ? 0 : 0),
              leadingWidget,
              if (titleSpacing > 0) SizedBox(width: titleSpacing),
              Expanded(child: titleContent),
              if (actions.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: actions,
                ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// AppBar kiểu tối giản dùng cho các màn hình có nền trắng (auth, settings).
/// Không gradient, không shadow — để nội dung bên dưới nổi bật.
class TriLightAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? leading;
  final IconData backIcon;
  final VoidCallback? onBack;
  final bool showBackButton;
  final List<Widget> actions;

  const TriLightAppBar({
    super.key,
    this.title = '',
    this.leading,
    this.backIcon = Icons.arrow_back_rounded,
    this.onBack,
    this.showBackButton = false,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = theme.colorScheme.onSurface;
    final Widget leadingWidget = leading ??
        (showBackButton
            ? IconButton(
                icon: Icon(backIcon, color: fg, size: 22),
                splashRadius: 22,
                onPressed: onBack ?? () => Navigator.of(context).maybePop(),
              )
            : const SizedBox.shrink());

    return Container(
      decoration: BoxDecoration(
        color: AppColors.creamWhite,
        border: Border(
          bottom: BorderSide(
            color: AppColors.neutralGray300.withValues(alpha: 0.6),
            width: 0.6,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentBrown.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: kToolbarHeight,
          child: Row(
            children: [
              leadingWidget,
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (actions.isNotEmpty)
                Row(mainAxisSize: MainAxisSize.min, children: actions),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}