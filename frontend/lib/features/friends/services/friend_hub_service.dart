import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:frontend/config/api_config.dart';

import 'friend_service.dart';

enum FriendHubEvent {
  friendRequestReceived,
  friendRequestAccepted,
  friendRequestDeclined,
  friendRequestCancelled,
  friendUnfriended,
}

class FriendRealtimeEvent {
  final FriendHubEvent type;
  final FriendshipModel friendship;

  const FriendRealtimeEvent({required this.type, required this.friendship});
}

class FriendHubService {
  static const String _hubPath = '/hubs/friend';

  HubConnection? _connection;
  final _controller = StreamController<FriendRealtimeEvent>.broadcast();

  Stream<FriendRealtimeEvent> get events => _controller.stream;
  bool get isConnected => _connection?.state == HubConnectionState.Connected;

  Future<void> connect() async {
    if (isConnected) return;

    final token = await _getToken();
    if (token == null) return;

    final url = '${ApiConfig.baseUrl}$_hubPath';

    _connection = HubConnectionBuilder()
        .withUrl(
          url,
          options: HttpConnectionOptions(
            transport: HttpTransportType.WebSockets,
            skipNegotiation: true,
            accessTokenFactory: () async => token,
          ),
        )
        .withAutomaticReconnect(retryDelays: [2000, 5000, 10000, 30000]).build();

    _connection!.on('FriendRequestReceived', (args) {
      final data = _parseArgs(args);
      if (data == null) return;
      _emit(FriendHubEvent.friendRequestReceived, data);
    });
    _connection!.on('FriendRequestAccepted', (args) {
      final data = _parseArgs(args);
      if (data == null) return;
      _emit(FriendHubEvent.friendRequestAccepted, data);
    });

    _connection!.on('FriendRequestDeclined', (args) {
      final data = _parseArgs(args);
      if (data == null) return;
      _emit(FriendHubEvent.friendRequestDeclined, data);
    });

    _connection!.on('FriendRequestCancelled', (args) {
      final data = _parseArgs(args);
      if (data == null) return;
      _emit(FriendHubEvent.friendRequestCancelled, data);
    });

    _connection!.on('FriendUnfriended', (args) {
      final data = _parseArgs(args);
      if (data == null) return;
      _emit(FriendHubEvent.friendUnfriended, data);
    });

    _connection!.onclose(({error}) {});
    _connection!.onreconnecting(({error}) {});
    _connection!.onreconnected(({connectionId}) {});

    try {
      await _connection!.start();
    } catch (_) {}
  }

  Future<void> disconnect() async {
    await _connection?.stop();
    _connection = null;
  }

  void dispose() {
    _controller.close();
    disconnect();
  }

  Future<String?> _getToken() async {
    try {
      return await FirebaseAuth.instance.currentUser?.getIdToken(false);
    } catch (_) {
      return null;
    }
  }

  void _emit(FriendHubEvent type, FriendshipModel friendship) {
    if (!_controller.isClosed) {
      _controller.add(
        FriendRealtimeEvent(
          type: type,
          friendship: friendship,
        ),
      );
    }
  }

  FriendshipModel? _parseArgs(List<Object?>? args) {
    if (args == null || args.isEmpty) return null;
    try {
      final raw = args[0];
      if (raw is Map<String, dynamic>) {
        return FriendshipModel.fromJson(raw);
      }
      if (raw is Map) {
        final json = raw.map((k, v) => MapEntry(k.toString(), v));
        return FriendshipModel.fromJson(json);
      }
    } catch (_) {}
    return null;
  }
}
