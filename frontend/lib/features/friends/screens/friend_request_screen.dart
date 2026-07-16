import 'package:flutter/material.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/features/friends/friends.dart';
import 'package:frontend/features/friends/screens/received_request_tab.dart';
import 'package:frontend/features/friends/screens/sent_request_tab.dart';
import 'package:provider/provider.dart';

class FriendRequestScreen extends StatelessWidget {
  const FriendRequestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FriendProvider>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.darkBackground,
        appBar: AppBar(
          backgroundColor: AppColors.darkSurface,
          elevation: 0,
          leadingWidth: 50,
          leading: IconButton(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.arrow_back, color: AppColors.darkTextPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          titleSpacing: 8,
          title: const Text(
            'Lời mời kết bạn',
            style: TextStyle(color: AppColors.darkTextPrimary, fontSize: 18, fontWeight: FontWeight.w600),
          ),
          centerTitle: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings, color: AppColors.darkTextPrimary),
              onPressed: () {},
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.darkSurface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TabBar(
                indicator: UnderlineTabIndicator(
                  borderSide: BorderSide(color: AppColors.primaryOrange, width: 3.5),
                  insets: EdgeInsets.symmetric(horizontal: 16),
                ),
                indicatorSize: TabBarIndicatorSize.label,
                labelColor: AppColors.primaryOrange,
                unselectedLabelColor: AppColors.darkTextSecondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Đã nhận'),
                        const SizedBox(width: 6),
                        if (provider.pendingReceived.isNotEmpty)
                          Badge(
                            label: Text(
                              '${provider.pendingReceived.length}',
                              style: const TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                            backgroundColor: AppColors.error,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                          ),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Đã gửi'),
                        const SizedBox(width: 6),
                        if (provider.pendingSent.isNotEmpty)
                          Badge(
                            label: Text(
                              '${provider.pendingSent.length}',
                              style: const TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                            backgroundColor: AppColors.darkTextSecondary,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            ReceivedRequestsTab(),
            SentRequestsTab(),
          ],
        ),
      ),
    );
  }
}
