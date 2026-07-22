import 'package:flutter/material.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/component/avatars.dart';

class GroupItemWidget extends StatelessWidget {
  final String name;
  final String sub;
  final String time;
  final bool isMute;

  const GroupItemWidget({
    super.key,
    required this.name,
    required this.sub,
    required this.time,
    required this.isMute,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.darkPremiumSurface,
      child: InkWell(
        onTap: () {},
        highlightColor: Colors.black.withValues(alpha: 0.05),
        splashColor: Colors.transparent,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.neonRoyal.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.groups, color: AppColors.neonRoyal, size: 28),
          ),
          title: Text(
            name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.darkPremiumTextPrimary,
            ),
          ),
          subtitle: Text(
            sub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppColors.darkPremiumTextSecondary, fontSize: 14),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isMute)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.notifications_off_outlined, size: 16, color: AppColors.darkPremiumTextSecondary),
                ),
              Text(time, style: TextStyle(fontSize: 12, color: AppColors.darkPremiumTextSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}