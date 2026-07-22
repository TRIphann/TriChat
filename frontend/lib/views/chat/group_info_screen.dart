import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:frontend/component/avatars.dart';
import '../../models/chat/conversation.dart';
import '../../models/chat/participant.dart';

class GroupInfoScreen extends StatefulWidget {
  final Conversation conversation;

  const GroupInfoScreen({super.key, required this.conversation});

  @override
  _GroupInfoScreenState createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  late Conversation _conversation;

  @override
  void initState() {
    super.initState();
    _conversation = widget.conversation;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkPremiumBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkPremiumSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.darkPremiumTextPrimary),
          onPressed: () => GoRouter.of(context).pop(),
        ),
        title: Text(
          'Thông tin nhóm',
          style: TextStyle(
            color: AppColors.darkPremiumTextPrimary,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildGroupHeader(),
            SizedBox(height: 8),
            _buildGroupActions(),
            SizedBox(height: 8),
            _buildMembersSection(),
            SizedBox(height: 8),
            _buildMediaSection(),
            SizedBox(height: 8),
            _buildSettingsSection(),
            SizedBox(height: 8),
            _buildDangerZone(),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupHeader() {
    return Container(
      color: AppColors.darkPremiumSurface,
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          Stack(
            children: [
              TriAvatar(
                imageUrl: _conversation.groupAvatarUrl ?? '',
                name: _conversation.groupName ?? 'Nhóm',
                size: 100,
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            _conversation.groupName ?? 'Nhóm',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.darkPremiumTextPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '${_conversation.participants.length} thành viên',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.darkPremiumTextSecondary,
            ),
          ),
          if (_conversation.groupDescription?.isNotEmpty == true) ...[
            SizedBox(height: 12),
            Text(
              _conversation.groupDescription!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.darkPremiumTextSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGroupActions() {
    return Container(
      color: AppColors.darkPremiumSurface,
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            icon: Icons.search,
            label: 'Tìm kiếm',
            onTap: _searchInConversation,
          ),
          _buildActionButton(
            icon: _conversation.isMuted ? Icons.volume_off : Icons.volume_up,
            label: _conversation.isMuted ? 'Bật thông báo' : 'Tắt thông báo',
            onTap: () => _toggleMute(!_conversation.isMuted),
          ),
          _buildActionButton(
            icon: Icons.push_pin,
            label: 'Ghim',
            onTap: _togglePin,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          children: [
            Icon(icon, color: AppColors.neonRoyal),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.darkPremiumTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersSection() {
    return Container(
      color: AppColors.darkPremiumSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Thành viên (${_conversation.participants.length})',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkPremiumTextPrimary,
                  ),
                ),
                TextButton.icon(
                  onPressed: _addMembers,
                  icon: Icon(Icons.person_add, size: 20, color: AppColors.neonRoyal),
                  label: Text('Thêm', style: TextStyle(color: AppColors.neonRoyal)),
                ),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _conversation.participants.length,
            itemBuilder: (context, index) {
              final participant = _conversation.participants[index];
              return _buildMemberTile(participant);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMemberTile(Participant participant) {
    final isAdmin = participant.role == 'admin';

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.darkPremiumBorder, width: 0.5),
        ),
      ),
      child: ListTile(
        leading: Stack(
          children: [
            TriAvatar(
              imageUrl: participant.avatar,
              name: participant.userName,
              size: 48,
            ),
            if (participant.isOnline)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.darkPremiumSurface, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                participant.displayName,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppColors.darkPremiumTextPrimary,
                ),
              ),
            ),
            if (isAdmin)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.neonRoyal.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Quản trị viên',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.neonRoyal,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(
          participant.isOnline ? 'Đang hoạt động' : 'Không hoạt động',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.darkPremiumTextSecondary,
          ),
        ),
        trailing: PopupMenuButton(
          icon: Icon(Icons.more_vert, color: AppColors.darkPremiumTextSecondary),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'profile',
              child: Text('Xem trang cá nhân', style: TextStyle(color: AppColors.darkPremiumTextPrimary)),
            ),
            if (!isAdmin)
              PopupMenuItem(
                value: 'make_admin',
                child: Text('Đặt làm quản trị viên', style: TextStyle(color: AppColors.darkPremiumTextPrimary)),
              ),
            if (!isAdmin)
              PopupMenuItem(
                value: 'remove',
                child: Text('Xóa khỏi nhóm', style: TextStyle(color: AppColors.accentRed)),
              ),
          ],
          onSelected: (value) => _handleMemberAction(participant, value.toString()),
        ),
      ),
    );
  }

  Widget _buildMediaSection() {
    return Container(
      color: AppColors.darkPremiumSurface,
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.photo_library, color: AppColors.neonRoyal),
            title: Text('Ảnh/Video', style: TextStyle(color: AppColors.darkPremiumTextPrimary)),
            trailing: Icon(Icons.chevron_right, color: AppColors.darkPremiumTextSecondary),
            onTap: _viewMedia,
          ),
          Divider(height: 1, color: AppColors.darkPremiumBorder),
          ListTile(
            leading: Icon(Icons.insert_drive_file, color: AppColors.neonRoyal),
            title: Text('Tệp', style: TextStyle(color: AppColors.darkPremiumTextPrimary)),
            trailing: Icon(Icons.chevron_right, color: AppColors.darkPremiumTextSecondary),
            onTap: _viewFiles,
          ),
          Divider(height: 1, color: AppColors.darkPremiumBorder),
          ListTile(
            leading: Icon(Icons.link, color: AppColors.neonRoyal),
            title: Text('Liên kết', style: TextStyle(color: AppColors.darkPremiumTextPrimary)),
            trailing: Icon(Icons.chevron_right, color: AppColors.darkPremiumTextSecondary),
            onTap: _viewLinks,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      color: AppColors.darkPremiumSurface,
      child: Column(
        children: [
          SwitchListTile(
            secondary: Icon(Icons.edit, color: AppColors.neonRoyal),
            title: Text(
              'Chỉ quản trị viên có thể gửi tin nhắn',
              style: TextStyle(color: AppColors.darkPremiumTextPrimary),
            ),
            value: _conversation.onlyAdminCanSend,
            onChanged: _toggleOnlyAdminCanSend,
          ),
          Divider(height: 1, color: AppColors.darkPremiumBorder),
          SwitchListTile(
            secondary: Icon(Icons.info, color: AppColors.neonRoyal),
            title: Text(
              'Chỉ quản trị viên có thể sửa thông tin nhóm',
              style: TextStyle(color: AppColors.darkPremiumTextPrimary),
            ),
            value: _conversation.onlyAdminCanEditInfo,
            onChanged: _toggleOnlyAdminCanEditInfo,
          ),
          Divider(height: 1, color: AppColors.darkPremiumBorder),
          ListTile(
            leading: Icon(Icons.color_lens, color: AppColors.neonRoyal),
            title: Text('Đổi chủ đề', style: TextStyle(color: AppColors.darkPremiumTextPrimary)),
            trailing: Icon(Icons.chevron_right, color: AppColors.darkPremiumTextSecondary),
            onTap: _changeTheme,
          ),
          Divider(height: 1, color: AppColors.darkPremiumBorder),
          ListTile(
            leading: Icon(Icons.wallpaper, color: AppColors.neonRoyal),
            title: Text('Đổi hình nền', style: TextStyle(color: AppColors.darkPremiumTextPrimary)),
            trailing: Icon(Icons.chevron_right, color: AppColors.darkPremiumTextSecondary),
            onTap: _changeBackground,
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZone() {
    return Container(
      color: AppColors.darkPremiumSurface,
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.delete_outline, color: AppColors.accentRed),
            title: Text(
              'Xóa lịch sử trò chuyện',
              style: TextStyle(color: AppColors.accentRed),
            ),
            onTap: _clearHistory,
          ),
          Divider(height: 1, color: AppColors.darkPremiumBorder),
          ListTile(
            leading: Icon(Icons.exit_to_app, color: AppColors.accentRed),
            title: Text('Rời khỏi nhóm', style: TextStyle(color: AppColors.accentRed)),
            onTap: _leaveGroup,
          ),
        ],
      ),
    );
  }

  void _searchInConversation() {
    _showInfo('Tính năng tìm kiếm đang được phát triển');
  }

  void _toggleMute(bool value) {
    setState(() {});
    _showSuccess(value ? 'Đã tắt thông báo' : 'Đã bật thông báo');
  }

  void _togglePin() {
    _showInfo('Đã ghim cuộc hội thoại');
  }

  void _addMembers() {
    _showInfo('Tính năng thêm thành viên đang được phát triển');
  }

  void _handleMemberAction(Participant participant, String action) {
    switch (action) {
      case 'profile':
        _showInfo('Xem trang cá nhân ${participant.displayName}');
        break;
      case 'make_admin':
        _confirmMakeAdmin(participant);
        break;
      case 'remove':
        _confirmRemoveMember(participant);
        break;
    }
  }

  void _confirmMakeAdmin(Participant participant) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkPremiumSurface,
        title: Text('Đặt làm quản trị viên', style: TextStyle(color: AppColors.darkPremiumTextPrimary)),
        content: Text(
          'Bạn có chắc chắn muốn đặt ${participant.displayName} làm quản trị viên?',
          style: TextStyle(color: AppColors.darkPremiumTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy', style: TextStyle(color: AppColors.darkPremiumTextSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showSuccess('Đã đặt ${participant.displayName} làm quản trị viên');
            },
            child: Text('Xác nhận', style: TextStyle(color: AppColors.neonRoyal)),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveMember(Participant participant) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkPremiumSurface,
        title: Text('Xóa thành viên', style: TextStyle(color: AppColors.darkPremiumTextPrimary)),
        content: Text(
          'Bạn có chắc chắn muốn xóa ${participant.displayName} khỏi nhóm?',
          style: TextStyle(color: AppColors.darkPremiumTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy', style: TextStyle(color: AppColors.darkPremiumTextSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showSuccess('Đã xóa ${participant.displayName} khỏi nhóm');
            },
            child: Text('Xóa', style: TextStyle(color: AppColors.accentRed)),
          ),
        ],
      ),
    );
  }

  void _viewMedia() {
    _showInfo('Tính năng xem ảnh/video đang được phát triển');
  }

  void _viewFiles() {
    _showInfo('Tính năng xem tệp đang được phát triển');
  }

  void _viewLinks() {
    _showInfo('Tính năng xem liên kết đang được phát triển');
  }

  void _toggleOnlyAdminCanSend(bool value) {
    setState(() {});
    _showSuccess(
      value
          ? 'Chỉ quản trị viên có thể gửi tin nhắn'
          : 'Tất cả thành viên có thể gửi tin nhắn',
    );
  }

  void _toggleOnlyAdminCanEditInfo(bool value) {
    setState(() {});
    _showSuccess(
      value
          ? 'Chỉ quản trị viên có thể sửa thông tin'
          : 'Tất cả thành viên có thể sửa thông tin',
    );
  }

  void _changeTheme() {
    _showInfo('Tính năng đổi chủ đề đang được phát triển');
  }

  void _changeBackground() {
    _showInfo('Tính năng đổi hình nền đang được phát triển');
  }

  void _clearHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkPremiumSurface,
        title: Text('Xóa lịch sử trò chuyện', style: TextStyle(color: AppColors.darkPremiumTextPrimary)),
        content: Text(
          'Bạn có chắc chắn muốn xóa toàn bộ lịch sử trò chuyện?',
          style: TextStyle(color: AppColors.darkPremiumTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy', style: TextStyle(color: AppColors.darkPremiumTextSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showSuccess('Đã xóa lịch sử trò chuyện');
            },
            child: Text('Xóa', style: TextStyle(color: AppColors.accentRed)),
          ),
        ],
      ),
    );
  }

  void _leaveGroup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkPremiumSurface,
        title: Text('Rời khỏi nhóm', style: TextStyle(color: AppColors.darkPremiumTextPrimary)),
        content: Text(
          'Bạn có chắc chắn muốn rời khỏi nhóm này?',
          style: TextStyle(color: AppColors.darkPremiumTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy', style: TextStyle(color: AppColors.darkPremiumTextSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              GoRouter.of(context).pop();
              GoRouter.of(context).pop();
              _showSuccess('Đã rời khỏi nhóm');
            },
            child: Text('Rời nhóm', style: TextStyle(color: AppColors.accentRed)),
          ),
        ],
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.neonRoyal,
      ),
    );
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.darkPremiumSurface,
      ),
    );
  }
}
