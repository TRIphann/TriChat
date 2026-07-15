import 'package:flutter/material.dart';
import 'package:frontend/component/buttons.dart';
import 'package:frontend/component/inputs.dart';
import 'package:frontend/component/loading_dialog.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/config/app_spacing.dart';
import 'package:frontend/config/app_typography.dart';
import 'package:go_router/go_router.dart';

class EnterNameView extends StatefulWidget {
  const EnterNameView({
    super.key,
    required this.email,
    required this.password,
    this.name,
  });

  final String email;
  final String password;
  final String? name;

  @override
  State<EnterNameView> createState() => _EnterNameViewState();
}

class _EnterNameViewState extends State<EnterNameView> {
  final TextEditingController _nameController = TextEditingController();

  bool _isLongEnough = false;
  bool _hasNoNumbers = true;
  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    if (widget.name != null && widget.name!.isNotEmpty) {
      _nameController.text = widget.name!;
    }
    _nameController.addListener(_validateName);
  }

  void _validateName() {
    final text = _nameController.text.trim();

    setState(() {
      _isLongEnough = text.length >= 2 && text.length <= 40;
      _hasNoNumbers = !RegExp(r'\d').hasMatch(text);
      _isButtonEnabled = text.isNotEmpty && _isLongEnough && _hasNoNumbers;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nhập tên TriChat',
                style: AppTypography.headlineLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Hãy dùng tên thật để bạn bè dễ nhận ra bạn.',
                style: AppTypography.bodyMedium.copyWith(
                  color: theme.hintColor,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              TriTextField(
                controller: _nameController,
                hintText: 'Nguyễn Văn A',
                prefixIcon: const Icon(Icons.person_outline_rounded, size: 18),
                suffixIcon: _nameController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.cancel_rounded, size: 18),
                        onPressed: () {
                          _nameController.clear();
                          _validateName();
                        },
                      )
                    : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildConditionItem(
                'Dài từ 2 đến 40 ký tự',
                _isLongEnough,
                theme,
              ),
              _buildConditionItem(
                'Không chứa số',
                _hasNoNumbers,
                theme,
              ),
              _buildConditionItem(
                'Tuân thủ quy định đặt tên TriChat',
                true,
                theme,
                isLink: true,
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Tiếp tục',
                onPressed: _isButtonEnabled
                    ? () async {
                        LoadingDialog.show(context, message: "Đang xử lý...");
                        await Future.delayed(const Duration(seconds: 1));
                        if (context.mounted) {
                          LoadingDialog.hide(context);
                        }
                        if (context.mounted) {
                          context.push('/personal-info', extra: {
                            'email': widget.email,
                            'password': widget.password,
                            'name': _nameController.text.trim(),
                          });
                        }
                      }
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConditionItem(
    String text,
    bool isMet,
    ThemeData theme, {
    bool isLink = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_rounded : Icons.radio_button_unchecked_rounded,
            size: 14,
            color: isMet
                ? AppColors.neutralBlack
                : AppColors.neutralGray400,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTypography.bodySmall.copyWith(
                  color: isMet
                      ? theme.colorScheme.onSurface
                      : AppColors.neutralGray500,
                ),
                children: [
                  TextSpan(
                    text: text.replaceAll('quy định đặt tên TriChat', ''),
                  ),
                  if (isLink)
                    TextSpan(
                      text: 'quy định đặt tên TriChat',
                      style: AppTypography.bodySmall.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
