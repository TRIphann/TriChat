import 'package:flutter/material.dart';

import '../config/app_colors.dart';
import '../config/app_spacing.dart';

/// AppBar tuỳ biến theo brand TriChat — Minimalist (trắng / đen, không gradient).
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

  /// Màu nền — mặc định trắng.
  final Color? backgroundColor;

  /// Màu chữ/Icon — mặc định đen.
  final Color? foregroundColor;

  /// Có bo cong góc dưới hay không (mặc định false).
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
    this.backgroundColor,
    this.foregroundColor,
    this.roundedBottom = false,
    this.titleSpacing = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = backgroundColor ??
        (isDark ? AppColors.darkSurface : AppColors.neutralWhite);
    final fg = foregroundColor ?? theme.colorScheme.onSurface;
    final Widget leadingWidget = leading ??
        (showBackButton
            ? IconButton(
                icon: Icon(backIcon, color: fg, size: 22),
                splashRadius: 22,
                onPressed: onBack ?? () => Navigator.of(context).maybePop(),
              )
            : const SizedBox.shrink());

    final Widget titleContent = titleWidget ??
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            color: fg,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: roundedBottom
            ? const BorderRadius.vertical(
                bottom: Radius.circular(AppRadius.lg),
              )
            : null,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkDivider : AppColors.neutralGray200,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: kToolbarHeight,
          child: Row(
            children: [
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

/// AppBar kiểu tối giản — nền trắng / đen, border hairline bên dưới.
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
    final isDark = theme.brightness == Brightness.dark;
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
        color: isDark ? AppColors.darkSurface : AppColors.neutralWhite,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkDivider : AppColors.neutralGray200,
            width: 1,
          ),
        ),
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
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
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
