import 'package:flutter/material.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/component/avatars.dart';

class RequestItemWidget extends StatelessWidget {
  final String name;
  final String message;
  final String avatar;

  final bool isReceived;

  final bool isAccepted;

  final bool isRecalled;

  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  final VoidCallback? onRecall;
  final VoidCallback? onAddFriend;

  final VoidCallback? onMessage;

  const RequestItemWidget({
    super.key,
    required this.name,
    required this.message,
    required this.avatar,
    required this.isReceived,

    this.isAccepted = false,

    this.isRecalled = false,

    this.onAccept,
    this.onDecline,

    this.onRecall,
    this.onAddFriend,

    this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    final bool showTwoButtons =
        isReceived && !isAccepted;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.darkPremiumSurface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.darkPremiumBorder,
          ),
        ),
      ),

      child: Column(
        children: [
          // =========================================
          // HÀNG CHÍNH
          // =========================================

          Row(
            crossAxisAlignment:
                CrossAxisAlignment.center,
            children: [
              // AVATAR
              TriAvatar(
                imageUrl: avatar,
                name: name,
                size: 56,
              ),

              const SizedBox(width: 12),

              // =====================================
              // TEXT
              // =====================================

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w600,
                        color: AppColors.darkPremiumTextPrimary,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      message,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.darkPremiumTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // =====================================
              // NÚT 1 BUTTON
              // =====================================

              if (!showTwoButtons)
                _buildSingleActionButton(),
            ],
          ),

          // =========================================
          // 2 BUTTONS
          // =========================================

          if (showTwoButtons) ...[
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: _buildDarkButton(
                    text: 'Từ chối',
                    bgColor: AppColors.darkPremiumElevated,
                    textColor: AppColors.darkPremiumTextSecondary,
                    onTap: onDecline,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: _buildDarkButton(
                    text: 'Đồng ý',
                    bgColor: AppColors.neonRoyal,
                    textColor: Colors.white,
                    onTap: onAccept,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSingleActionButton() {
    // =========================
    // NHẮN TIN
    // =========================

    if (isAccepted) {
      return _buildDarkButton(
        text: 'Nhắn tin',
        bgColor: AppColors.neonRoyal,
        textColor: Colors.white,
        onTap: onMessage,
        width: 100,
      );
    }

    // =========================
    // THU HỒI
    // =========================

    if (!isReceived && !isRecalled) {
      return _buildDarkButton(
        text: 'Thu hồi',
        bgColor: AppColors.darkPremiumElevated,
        textColor: AppColors.darkPremiumTextSecondary,
        onTap: onRecall,
        width: 100,
      );
    }

    // =========================
    // KẾT BẠN LẠI
    // =========================

    if (!isReceived && isRecalled) {
      return _buildDarkButton(
        text: 'Kết bạn lại',
        bgColor: AppColors.neonRoyal,
        textColor: Colors.white,
        onTap: onAddFriend,
        width: 110,
      );
    }

    return const SizedBox();
  }

  Widget _buildDarkButton({
    required String text,
    required Color bgColor,
    required Color textColor,
    required VoidCallback? onTap,
    double width = double.infinity,
  }) {
    return SizedBox(
      height: 36,
      width: width,
      child: ElevatedButton(
        onPressed: onTap,

        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: textColor,
          elevation: 0,

          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(18),
          ),
        ),

        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
