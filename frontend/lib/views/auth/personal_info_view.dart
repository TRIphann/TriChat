import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:frontend/component/buttons.dart';
import 'package:frontend/component/inputs.dart';
import 'package:frontend/component/loading_dialog.dart';
import 'package:frontend/component/success_dialog.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/config/app_spacing.dart';
import 'package:frontend/config/app_typography.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class PersonalInfoView extends StatefulWidget {
  const PersonalInfoView({
    super.key,
    required this.email,
    required this.password,
    required this.name,
  });

  final String email;
  final String password;
  final String name;

  @override
  State<PersonalInfoView> createState() => _PersonalInfoViewState();
}

class _PersonalInfoViewState extends State<PersonalInfoView> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _birthController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();

  DateTime _tempDate = DateTime(2000, 1, 1);
  bool _isButtonEnabled = false;

  void _updateButtonState() {
    setState(() {
      _isButtonEnabled = _birthController.text.isNotEmpty &&
          _genderController.text.isNotEmpty;
    });
  }

  void _showDatePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (BuildContext context) {
        return Container(
          height: 360,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Chọn ngày sinh",
                    style: AppTypography.titleLarge,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: DateTime(2000, 1, 1),
                  onDateTimeChanged: (DateTime newDate) {
                    _tempDate = newDate;
                  },
                ),
              ),
              const Text(
                "Bạn cần đủ 14 tuổi để sử dụng TriChat",
                style: AppTypography.bodySmall,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.md,
                  AppSpacing.xl,
                  AppSpacing.lg,
                ),
                child: PrimaryButton(
                  label: 'Chọn',
                  onPressed: () {
                    setState(() {
                      _birthController.text =
                          DateFormat('dd/MM/yyyy').format(_tempDate);
                    });
                    _updateButtonState();
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showGenderPicker() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.sm,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Chọn giới tính',
                      style: AppTypography.titleLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _genderOption(context, 'Nam'),
                _genderOption(context, 'Nữ'),
                _genderOption(context, 'Không chia sẻ'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _genderOption(BuildContext context, String label) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _genderController.text = label;
          });
          _updateButtonState();
          Navigator.pop(context);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: AppTypography.bodyLarge.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Thêm thông tin cá nhân',
                style: AppTypography.headlineLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Thông tin này giúp bạn bè dễ nhận ra bạn hơn.',
                style: AppTypography.bodyMedium.copyWith(
                  color: theme.hintColor,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              GestureDetector(
                onTap: _showDatePicker,
                child: AbsorbPointer(
                  child: TriTextField(
                    controller: _birthController,
                    hintText: 'Sinh nhật',
                    prefixIcon: const Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                    ),
                    suffixIcon: const Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              GestureDetector(
                onTap: _showGenderPicker,
                child: AbsorbPointer(
                  child: TriTextField(
                    controller: _genderController,
                    hintText: 'Giới tính',
                    prefixIcon: const Icon(Icons.person_outline_rounded, size: 18),
                    suffixIcon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Tiếp tục',
                onPressed: _isButtonEnabled
                    ? () async {
                        LoadingDialog.show(context);

                        try {
                          final nameParts =
                              widget.name.trim().split(RegExp(r'\s+'));
                          final firstName =
                              nameParts.isNotEmpty ? nameParts.first : '';
                          final lastName = nameParts.length > 1
                              ? nameParts.sublist(1).join(' ')
                              : '';

                          await AuthService.register(
                            RegisterRequest(
                              email: widget.email.trim(),
                              password: widget.password,
                              firstName: firstName,
                              lastName: lastName,
                              dateOfBirth:
                                  _birthController.text.isNotEmpty
                                      ? DateFormat('yyyy-MM-dd').format(
                                          DateFormat('dd/MM/yyyy')
                                              .parse(_birthController.text),
                                        )
                                      : null,
                              bio: '',
                            ),
                          );
                          if (!mounted) return;
                          LoadingDialog.hide(context);

                          SuccessDialog.show(context, () {
                            context.pushReplacement('/chat-list');
                          });
                        } catch (e) {
                          if (!mounted) return;
                          LoadingDialog.hide(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                e.toString().replaceAll('Exception: ', ''),
                              ),
                              backgroundColor: AppColors.error,
                            ),
                          );
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
}
