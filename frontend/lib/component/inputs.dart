import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/app_colors.dart';
import '../config/app_spacing.dart';
import '../config/app_typography.dart';

/// ════════════════════════════════════════════════════════════════
/// HIGH-END INPUTS — Premium Input System
/// ════════════════════════════════════════════════════════════════
///
/// Design Language:
/// - Warm cream surfaces
/// - Soft borders with amber focus state
/// - Large input padding for premium feel
/// - Floating labels with smooth transitions

class TriTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final String? helperText;
  final String? errorText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool enabled;
  final int? maxLines;
  final int? minLines;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;
  final FormFieldValidator<String>? validator;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final TextStyle? style;
  final AutovalidateMode? autovalidateMode;

  const TriTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.helperText,
    this.errorText,
    this.keyboardType,
    this.obscureText = false,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.focusNode,
    this.textInputAction,
    this.inputFormatters,
    this.style,
    this.autovalidateMode,
  });

  @override
  State<TriTextField> createState() => _TriTextFieldState();
}

class _TriTextFieldState extends State<TriTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: AppCurves.durationNormal,
          curve: AppCurves.primary,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: AppColors.primaryAmber.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: TextFormField(
            controller: widget.controller,
            keyboardType: widget.keyboardType,
            obscureText: widget.obscureText,
            enabled: widget.enabled,
            maxLines: widget.obscureText ? 1 : widget.maxLines,
            minLines: widget.minLines,
            focusNode: _focusNode,
            textInputAction: widget.textInputAction,
            inputFormatters: widget.inputFormatters,
            autovalidateMode: widget.autovalidateMode ?? AutovalidateMode.onUserInteraction,
            validator: widget.validator,
            onChanged: widget.onChanged,
            onFieldSubmitted: (_) => widget.onSubmitted?.call(),
            style: widget.style ??
                AppTypography.bodyLarge.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
            decoration: InputDecoration(
              hintText: widget.hintText,
              labelText: widget.labelText,
              helperText: widget.helperText,
              errorText: widget.errorText,
              prefixIcon: widget.prefixIcon,
              suffixIcon: widget.suffixIcon,
              filled: true,
              fillColor: isDark ? AppColors.darkElevated : AppColors.creamElevated,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.borderDefault,
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.borderDefault,
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide: const BorderSide(
                  color: AppColors.primaryAmber,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide: const BorderSide(
                  color: AppColors.error,
                  width: 1.5,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide: const BorderSide(
                  color: AppColors.error,
                  width: 2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Premium search field with soft rounded design
class TriSearchField extends StatelessWidget {
  final String? hintText;
  final TextEditingController? controller;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final Widget? leadingIcon;
  final Widget? trailing;
  final Color? background;
  final Color? filledBackground;

  const TriSearchField({
    super.key,
    this.hintText,
    this.controller,
    this.onTap,
    this.onChanged,
    this.readOnly = false,
    this.leadingIcon,
    this.trailing,
    this.background,
    this.filledBackground,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = background ?? filledBackground ??
        (isDark ? AppColors.darkElevated : AppColors.creamElevated);

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.borderDefault,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: InkWell(
          onTap: readOnly ? onTap : null,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                leadingIcon ??
                    Icon(
                      Icons.search_rounded,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                      size: 20,
                    ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextField(
                    controller: controller,
                    readOnly: readOnly,
                    onTap: onTap,
                    onChanged: onChanged,
                    style: AppTypography.bodyMedium.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: hintText ?? 'Tìm kiếm...',
                      hintStyle: AppTypography.bodyMedium.copyWith(
                        color: isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.textTertiary,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                      filled: false,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// OTP input with premium styling and smooth animations
class TriOtpInput extends StatefulWidget {
  final int length;
  final ValueChanged<String> onCompleted;
  final ValueChanged<String>? onChanged;

  const TriOtpInput({
    super.key,
    this.length = 6,
    required this.onCompleted,
    this.onChanged,
  });

  @override
  State<TriOtpInput> createState() => _TriOtpInputState();
}

class _TriOtpInputState extends State<TriOtpInput>
    with SingleTickerProviderStateMixin {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _shakeController.dispose();
    super.dispose();
  }

  void _handleChange(int index, String value) {
    if (value.length > 1) {
      final clean = value.replaceAll(RegExp(r'[^0-9]'), '');
      final limit = clean.length > widget.length ? widget.length : clean.length;
      for (int i = 0; i < limit; i++) {
        final targetIndex = index + i;
        if (targetIndex < widget.length) {
          _controllers[targetIndex].text = clean[i];
        }
      }
      _focusNodes[(index + limit - 1).clamp(0, widget.length - 1)]
          .requestFocus();
    } else if (value.isNotEmpty && index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }

    final otp = _controllers.map((c) => c.text).join();
    widget.onChanged?.call(otp);
    if (otp.length == widget.length) {
      widget.onCompleted(otp);
    }
  }

  void _handleKey(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _controllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();
      widget.onChanged?.call(_controllers.map((c) => c.text).join());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(widget.length, (index) {
        return AnimatedBuilder(
          animation: _shakeController,
          builder: (context, child) {
            final shake = _shakeController.value *
                8 *
                (index % 2 == 0 ? 1 : -1) *
                (1 - _shakeController.value);
            return Transform.translate(
              offset: Offset(shake, 0),
              child: child,
            );
          },
          child: KeyboardListener(
            focusNode: FocusNode(),
            onKeyEvent: (event) => _handleKey(index, event),
            child: AnimatedContainer(
              duration: AppCurves.durationNormal,
              curve: AppCurves.primary,
              width: 52,
              height: 60,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkElevated : AppColors.creamElevated,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: _focusNodes[index].hasFocus
                      ? AppColors.primaryAmber
                      : (isDark ? AppColors.darkBorder : AppColors.borderDefault),
                  width: _focusNodes[index].hasFocus ? 2 : 1.5,
                ),
                boxShadow: _focusNodes[index].hasFocus
                    ? [
                        BoxShadow(
                          color: AppColors.primaryAmber.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: TextFormField(
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: AppTypography.headlineMedium.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  filled: false,
                  counterText: '',
                ),
                onChanged: (v) => _handleChange(index, v),
              ),
            ),
          ),
        );
      }),
    );
  }
}
