import 'package:flutter/foundation.dart';
import 'package:frontend/component/buttons.dart';
import 'package:frontend/component/loading_dialog.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/config/app_spacing.dart';
import 'package:frontend/config/app_typography.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class UpdateAvatarView extends StatefulWidget {
  const UpdateAvatarView({super.key});

  @override
  State<UpdateAvatarView> createState() => _UpdateAvatarViewState();
}

class _UpdateAvatarViewState extends State<UpdateAvatarView> {
  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final XFile? selectedImage = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (selectedImage != null) {
        setState(() {
          _imageFile = selectedImage;
        });
      }
    } catch (_) {}
  }

  Future<void> _uploadAvatar() async {
    try {
      LoadingDialog.show(context, message: "Đang tải ảnh...");
      // Gọi API upload ảnh lên server, sau đó cập nhật URL ảnh đại diện vào Database
      // await AuthService.updateAvatar(_imageFile!);

      if (mounted) {
        LoadingDialog.hide(context);
        context.go('/chat-list');
      }
    } catch (e) {
      if (mounted) {
        LoadingDialog.hide(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi upload: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cập nhật ảnh đại diện',
                style: AppTypography.headlineLarge.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Đặt ảnh đại diện để mọi người nhận ra bạn.',
                style: AppTypography.bodyMedium.copyWith(
                  color: theme.hintColor,
                ),
              ),
              const SizedBox(height: AppSpacing.huge),
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: _imageFile == null
                      ? Container(
                          width: 140,
                          height: 140,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.brightness == Brightness.dark
                                ? AppColors.darkCard
                                : AppColors.neutralGray100,
                            border: Border.all(
                              color: theme.dividerColor,
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.person_outline_rounded,
                            size: 64,
                            color: theme.colorScheme.onSurface,
                          ),
                        )
                      : Container(
                          width: 140,
                          height: 140,
                          clipBehavior: Clip.antiAlias,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          child: Image.network(
                            _imageFile!.path,
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
              ),
              PrimaryButton(
                label: _imageFile == null ? 'Cập nhật' : 'Đổi ảnh khác',
                icon: Icons.image_outlined,
                onPressed: _pickImage,
              ),
              const SizedBox(height: AppSpacing.md),
              SecondaryButton(
                label: _imageFile == null ? 'Bỏ qua' : 'Tiếp tục',
                onPressed: () async {
                  if (_imageFile == null) {
                    context.go('/chat-list');
                    return;
                  }
                  await _uploadAvatar();
                },
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
