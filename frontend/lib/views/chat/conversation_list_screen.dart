import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../models/chat/conversation.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/chat/conversation_tile.dart';
import 'chat_screen.dart';
import 'new_conversation_screen.dart';

class ConversationListScreen extends StatefulWidget {
  const ConversationListScreen({super.key});

  @override
  _ConversationListScreenState createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadConversations();
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
    setState(() {});
  }

  Future<void> _loadConversations() async {
    try {
      await context.read<ChatProvider>().loadConversations();
    } catch (e) {
      if (mounted) {
        _showError('Không thể tải danh sách hội thoại');
      }
    }
  }

  List<Conversation> _filterConversations(List<Conversation> all, String type) {
    final query = _searchQuery.toLowerCase();
    final filtered = all.where((conv) {
      if (query.isEmpty) return true;
      return conv.displayName.toLowerCase().contains(query);
    }).toList();

    final result = filtered.where((c) => c.type == type).toList();

    result.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Tin nhắn',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: _showSearch,
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.black),
            onPressed: _showNewConversationOptions,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryBlue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primaryBlue,
          tabs: const [
            Tab(text: 'Tất cả'),
            Tab(text: 'Nhóm'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildConversationList('private'),
          _buildConversationList('group'),
        ],
      ),
    );
  }

  Widget _buildConversationList(String type) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, _) {
        if (chatProvider.conversationsState == ChatLoadingState.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (chatProvider.conversationsState == ChatLoadingState.error) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  chatProvider.errorMessage ?? 'Lỗi khi tải hội thoại',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadConversations,
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        final conversations = _filterConversations(
          chatProvider.conversations,
          type,
        );

        if (conversations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'Chưa có cuộc hội thoại nào',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _showNewConversationOptions,
                  icon: const Icon(Icons.add),
                  label: const Text('Tạo cuộc hội thoại mới'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadConversations,
          color: AppColors.primaryBlue,
          child: ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              return ConversationTile(
                conversation: conversation,
                onTap: () => _openChat(conversation),
                onDelete: (id) => _deleteConversation(id),
                onPin: (id) => _togglePin(id),
                onMute: (id) => _toggleMute(id),
              );
            },
          ),
        );
      },
    );
  }

  void _showSearch() {
    showSearch(
      context: context,
      delegate: ConversationSearchDelegate(
        context.read<ChatProvider>().conversations,
      ),
    );
  }

  void _showNewConversationOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue[100],
                child: const Icon(Icons.person_add, color: Colors.blue),
              ),
              title: const Text('Tin nhắn mới'),
              subtitle: const Text('Bắt đầu cuộc trò chuyện 1-1'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const NewConversationScreen(type: 'private'),
                  ),
                );
              },
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green[100],
                child: const Icon(Icons.group_add, color: Colors.green),
              ),
              title: const Text('Tạo nhóm'),
              subtitle: const Text('Tạo nhóm chat mới'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NewConversationScreen(type: 'group'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openChat(Conversation conversation) {
    context.read<ChatProvider>().openConversation(conversation);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(conversation: conversation),
      ),
    ).then((_) => _loadConversations());
  }

  void _deleteConversation(String conversationId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa cuộc hội thoại'),
        content: const Text('Bạn có chắc chắn muốn xóa cuộc hội thoại này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await context.read<ChatProvider>().chatService.deleteConversation(conversationId);
                if (mounted) {
                  _showSuccess('Đã xóa cuộc hội thoại');
                  _loadConversations();
                }
              } catch (_) {
                if (mounted) _showError('Không thể xóa hội thoại');
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _togglePin(String conversationId) {
    _showSuccess('Đã ghim cuộc hội thoại');
    _loadConversations();
  }

  void _toggleMute(String conversationId) {
    _showSuccess('Đã tắt thông báo');
    _loadConversations();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }
}

class ConversationSearchDelegate extends SearchDelegate<Conversation?> {
  final List<Conversation> conversations;

  ConversationSearchDelegate(this.conversations);

  @override
  String get searchFieldLabel => 'Tìm kiếm...';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final results = conversations.where((conv) {
      return conv.displayName.toLowerCase().contains(query.toLowerCase());
    }).toList();

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy kết quả',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final conversation = results[index];
        return ConversationTile(
          conversation: conversation,
          onTap: () => close(context, conversation),
        );
      },
    );
  }
}
