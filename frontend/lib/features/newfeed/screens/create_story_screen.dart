import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/config/app_spacing.dart';
import 'package:frontend/features/newfeed/services/story_service.dart';

/// Dark premium story creation screen — camera + gallery + text overlay
class CreateStoryScreen extends StatefulWidget {
  final Uint8List? preSelectedBytes;
  final String? preSelectedPath;

  const CreateStoryScreen({
    super.key,
    this.preSelectedBytes,
    this.preSelectedPath,
  });

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _selectedBytes;
  String? _selectedPath;
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _selectedBytes = widget.preSelectedBytes;
    _selectedPath = widget.preSelectedPath;
    if (_selectedBytes == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showImageSourceDialog());
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.darkTextSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.camera_alt, color: AppColors.primaryOrange),
              title: Text('Chụp ảnh', style: TextStyle(color: AppColors.darkTextPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                _pickFromCamera();
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: AppColors.primaryOrange),
              title: Text('Thư viện ảnh', style: TextStyle(color: AppColors.darkTextPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                _pickFromGallery();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromCamera() async {
    if (_isLoading) return;
    setState(() => _errorMessage = '');

    // Camera is not supported on web - use gallery as fallback
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera không khả dụng trên web. Đang mở thư viện ảnh...'),
          duration: Duration(seconds: 2),
        ),
      );
      await _pickFromGallery();
      return;
    }

    try {
      // Try to request camera permission first
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1080,
        maxHeight: 1920,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          if (mounted) setState(() => _selectedBytes = bytes);
        } else {
          if (mounted) setState(() => _selectedPath = image.path);
        }
      } else {
        // Camera returned null - this happens on:
        // 1. Emulators without camera support
        // 2. Permission denied
        // 3. No camera available
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể truy cập camera. Vui lòng chọn ảnh từ thư viện.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Không thể chụp ảnh: $e');
        // Try gallery as fallback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi camera: $e. Đang mở thư viện ảnh...'),
            duration: const Duration(seconds: 2),
          ),
        );
        await _pickFromGallery();
      }
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isLoading) return;
    setState(() => _errorMessage = '');

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1080,
        maxHeight: 1920,
      );

      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          if (mounted) setState(() => _selectedBytes = bytes);
        } else {
          if (mounted) setState(() => _selectedPath = image.path);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Không thể chọn ảnh: $e');
      }
    }
  }

  Future<void> _postStory() async {
    if (_selectedBytes == null && _selectedPath == null) return;
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      XFile file;
      if (kIsWeb && _selectedBytes != null) {
        file = XFile.fromData(_selectedBytes!, name: 'story.jpg', mimeType: 'image/jpeg');
      } else if (_selectedPath != null) {
        file = XFile(_selectedPath!);
      } else {
        file = XFile.fromData(_selectedBytes!, name: 'story.jpg', mimeType: 'image/jpeg');
      }

      await StoryService.createStory(imageFile: file);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đăng story thành công!'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkPremiumBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkPremiumSurface,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.darkPremiumTextPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Tạo Story',
          style: TextStyle(
            color: AppColors.darkPremiumTextPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _postStory,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.neonRoyal,
                    ),
                  )
                : const Text(
                    'Đăng',
                    style: TextStyle(
                      color: AppColors.neonRoyal,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_errorMessage.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              color: AppColors.error.withValues(alpha: 0.1),
              child: Text(
                _errorMessage,
                style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 13,
                ),
              ),
            ),
          Expanded(
            child: _selectedBytes != null || _selectedPath != null
                ? _buildPreview()
                : _buildEmptyState(),
          ),
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.lg),
        constraints: const BoxConstraints(maxHeight: 480),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.darkPremiumBorder,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: _selectedBytes != null
              ? Image.memory(
                  _selectedBytes!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildErrorTile(),
                )
              : _selectedPath != null
                  ? Image.asset(
                      _selectedPath!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildErrorTile(),
                    )
                  : _buildErrorTile(),
        ),
      ),
    );
  }

  Widget _buildErrorTile() {
    return Container(
      width: 200,
      height: 200,
      color: AppColors.darkPremiumElevated,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, color: AppColors.darkPremiumTextSecondary, size: 48),
          SizedBox(height: 8),
          Text(
            'Không thể tải ảnh',
            style: TextStyle(color: AppColors.darkPremiumTextSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.neonRoyal.withValues(alpha: 0.15),
                  AppColors.neonPink.withValues(alpha: 0.15),
                ],
              ),
            ),
            child: const Icon(
              Icons.add_a_photo_rounded,
              color: AppColors.neonRoyal,
              size: 40,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'Chụp hoặc chọn ảnh để tạo story',
            style: TextStyle(
              color: AppColors.darkPremiumTextSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    // Camera is not supported on web - show only gallery button
    if (kIsWeb) {
      return Container(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.md,
          bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
        ),
        decoration: const BoxDecoration(
          color: AppColors.darkPremiumSurface,
          border: Border(
            top: BorderSide(color: AppColors.darkPremiumBorder, width: 1),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.photo_library_rounded,
                label: 'Thư viện',
                color: AppColors.neonOnline,
                onTap: _isLoading ? null : _pickFromGallery,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: AppColors.darkPremiumSurface,
        border: Border(
          top: BorderSide(color: AppColors.darkPremiumBorder, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              icon: Icons.camera_alt_rounded,
              label: 'Camera',
              color: AppColors.neonRed,
              onTap: _isLoading ? null : _pickFromCamera,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _buildActionButton(
              icon: Icons.photo_library_rounded,
              label: 'Thư viện',
              color: AppColors.neonOnline,
              onTap: _isLoading ? null : _pickFromGallery,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
