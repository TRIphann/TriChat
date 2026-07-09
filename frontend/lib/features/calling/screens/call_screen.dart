import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';
import '../../../models/call_model.dart';
import '../../../providers/call_provider.dart';
import '../../../providers/chat_provider.dart';
import 'package:frontend/config/app_colors.dart';

class CallScreen extends StatefulWidget {
  final CallModel call;

  const CallScreen({super.key, required this.call});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  bool _hasPopped = false;
  bool _remoteStreamReady = false;

  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  bool _rendererInited = false;

  @override
  void initState() {
    super.initState();
    _initRenderers();
  }

  Future<void> _initRenderers() async {
    await _remoteRenderer.initialize();
    await _localRenderer.initialize();
    if (mounted) setState(() => _rendererInited = true);
    await _initPeerConnection();
  }

  Future<void> _initPeerConnection() async {
    final call = widget.call;

    // 1. Get local media
    _localStream = await navigator.mediaDevices.getUserMedia(
      call.isVideo
          ? {'video': true, 'audio': true}
          : {'audio': true},
    );
    await _localRenderer.setSrcObject(stream: _localStream!);
    if (mounted) setState(() {});

    // 2. Create peer connection with public STUN servers
    _pc = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
      ],
    });

    // 3. Add local tracks to peer connection
    for (final track in _localStream!.getTracks()) {
      _pc!.addTrack(track, _localStream!);
    }

    // 4. Listen for remote tracks
    _pc!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
        _remoteRenderer.setSrcObject(stream: _remoteStream);
        if (mounted) {
          setState(() => _remoteStreamReady = true);
        }
      }
    };

    // 5. Gather ICE candidates and send via SignalR
    _pc!.onIceCandidate = (RTCIceCandidate candidate) {
      _sendIceCandidate(candidate);
    };

    // 6. Listen for ICE connection state changes
    _pc!.onIceConnectionState = (RTCIceConnectionState state) {
      debugPrint('[PeerConnection] ICE state: $state');
      if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
        debugPrint('[PeerConnection] ICE failed — retry with new candidates');
        _pc?.restartIce();
      }
    };

    // 7. Register WebRTC signaling handlers from SignalR
    _registerSignalingHandlers();

    // 8. Initiate or respond based on call direction
    if (call.isIncoming) {
      // Callee: wait for offer (already received via IncomingCall signal)
    } else {
      // Caller: create offer and send
      await _createOffer();
    }
  }

  void _registerSignalingHandlers() {
    final chatProvider = context.read<ChatProvider>();
    final signalR = chatProvider.signalR;
    if (signalR == null) return;

    signalR.onWebRtcOffer = _handleOffer;
    signalR.onWebRtcAnswer = _handleAnswer;
    signalR.onWebRtcIceCandidate = _handleIceCandidate;
  }

  Future<void> _createOffer() async {
    final call = widget.call;
    final chatProvider = context.read<ChatProvider>();
    final signalR = chatProvider.signalR;
    if (signalR == null || _pc == null) return;

    final offer = await _pc!.createOffer();
    await _pc!.setLocalDescription(offer);

    await signalR.send(
      'SendOffer',
      args: [
        call.conversationId,
        call.remoteUserId,
        offer.sdp ?? '',
      ],
    );
  }

  Future<void> _handleOffer(String conversationId, String callerId, String sdp) async {
    final call = widget.call;
    if (call.conversationId != conversationId) return;

    debugPrint('[CallScreen] Received WebRTC offer from $callerId');

    try {
      await _pc?.setRemoteDescription(
        RTCSessionDescription(sdp, 'offer'),
      );

      final answer = await _pc!.createAnswer();
      await _pc!.setLocalDescription(answer);

      final signalR = context.read<ChatProvider>().signalR;
      await signalR?.send(
        'SendAnswer',
        args: [
          conversationId,
          callerId,
          answer.sdp ?? '',
        ],
      );
    } catch (e) {
      debugPrint('[CallScreen] Error handling offer: $e');
    }
  }

  Future<void> _handleAnswer(String conversationId, String calleeId, String sdp) async {
    final call = widget.call;
    if (call.conversationId != conversationId) return;

    debugPrint('[CallScreen] Received WebRTC answer from $calleeId');

    try {
      await _pc?.setRemoteDescription(
        RTCSessionDescription(sdp, 'answer'),
      );
    } catch (e) {
      debugPrint('[CallScreen] Error handling answer: $e');
    }
  }

  Future<void> _handleIceCandidate(
    String conversationId,
    String senderId,
    String candidateStr,
  ) async {
    final call = widget.call;
    if (call.conversationId != conversationId) return;

    debugPrint('[CallScreen] Received ICE candidate from $senderId');

    try {
      final parts = candidateStr.split('|');
      if (parts.length >= 3) {
        final candidate = RTCIceCandidate(
          parts[2], // sdp
          parts[0], // sdpMid
          int.tryParse(parts[1]) ?? 0, // sdpMLineIndex
        );
        await _pc?.addCandidate(candidate);
      }
    } catch (e) {
      debugPrint('[CallScreen] Error adding ICE candidate: $e');
    }
  }

  Future<void> _sendIceCandidate(RTCIceCandidate candidate) async {
    final call = widget.call;
    final signalR = context.read<ChatProvider>().signalR;
    if (signalR == null) return;

    final candidateStr = [
      candidate.sdpMid ?? '',
      candidate.sdpMLineIndex.toString(),
      candidate.candidate,
    ].join('|');

    await signalR.send(
      'SendIceCandidate',
      args: [
        call.conversationId,
        call.remoteUserId,
        candidateStr,
      ],
    );
  }

  Future<void> _endCall({bool remoteLeft = false}) async {
    if (_hasPopped) return;
    _hasPopped = true;

    final callProvider = context.read<CallProvider>();
    final chatProvider = context.read<ChatProvider>();
    final call = widget.call;

    if (!chatProvider.callLogSaved &&
        call.status == CallStatus.active &&
        !call.isIncoming) {
      chatProvider.markCallLogSaved();
      await chatProvider.saveCallMessage(
        conversationId: call.conversationId,
        callType: call.isVideo ? 'video' : 'voice',
        status: 'answered',
        durationSeconds: callProvider.seconds,
      );
    } else if (!chatProvider.callLogSaved &&
        call.status == CallStatus.dialing &&
        !remoteLeft) {
      chatProvider.markCallLogSaved();
      await chatProvider.saveCallMessage(
        conversationId: call.conversationId,
        callType: call.isVideo ? 'video' : 'voice',
        status: 'cancelled',
        durationSeconds: 0,
      );
    }

    if (!remoteLeft) {
      await chatProvider.endCallSignal(call.conversationId, call.remoteUserId);
    }

    await _cleanup();
    callProvider.endCall();

    if (mounted) Navigator.of(context, rootNavigator: true).pop();
  }

  Future<void> _cleanup() async {
    await _pc?.close();
    await _localStream?.dispose();
    await _remoteStream?.dispose();
    _remoteRenderer.dispose();
    _localRenderer.dispose();
  }

  @override
  void dispose() {
    _unregisterSignalingHandlers();
    _cleanup();
    super.dispose();
  }

  void _unregisterSignalingHandlers() {
    final signalR = context.read<ChatProvider>().signalR;
    signalR?.onWebRtcOffer = null;
    signalR?.onWebRtcAnswer = null;
    signalR?.onWebRtcIceCandidate = null;
  }

  @override
  Widget build(BuildContext context) {
    final callProvider = context.watch<CallProvider>();
    final call = widget.call;

    final shouldClose = !callProvider.hasActiveCall ||
        call.status == CallStatus.rejected ||
        call.status == CallStatus.missed ||
        call.status == CallStatus.ended;
    if (shouldClose && !_hasPopped) {
      _hasPopped = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context, rootNavigator: true).pop();
      });
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video or voice background
          if (call.isVideo && _remoteStreamReady && _rendererInited)
            Positioned.fill(child: RTCVideoView(_remoteRenderer))
          else
            Positioned.fill(child: _buildVoiceCallView(call, callProvider)),

          // Local video preview
          if (call.isVideo && _rendererInited && _localStream != null)
            Positioned(
              top: 60,
              right: 16,
              width: 100,
              height: 140,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: RTCVideoView(_localRenderer),
              ),
            ),

          // Controls
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ControlBtn(
                  icon: callProvider.isMuted ? Icons.mic_off : Icons.mic,
                  label: callProvider.isMuted ? 'Bật mic' : 'Tắt mic',
                  onTap: () {
                    callProvider.toggleMute();
                    _localStream?.getAudioTracks().forEach((track) {
                      track.enabled = !callProvider.isMuted;
                    });
                  },
                ),
                _ControlBtn(
                  icon: Icons.call_end,
                  label: 'Cúp máy',
                  color: Colors.red,
                  size: 64,
                  onTap: () => _endCall(),
                ),
                if (call.isVideo)
                  _ControlBtn(
                    icon: Icons.flip_camera_ios,
                    label: 'Đổi cam',
                    onTap: _switchCamera,
                  )
                else
                  _ControlBtn(
                    icon: callProvider.isSpeakerOn ? Icons.volume_up : Icons.hearing,
                    label: callProvider.isSpeakerOn ? 'Tai nghe' : 'Loa ngoài',
                    onTap: () => callProvider.toggleSpeaker(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _switchCamera() async {
    if (_localStream == null) return;
    final videoTrack = _localStream!.getVideoTracks().firstOrNull;
    if (videoTrack != null) {
      await Helper.switchCamera(videoTrack);
    }
  }

  Widget _buildVoiceCallView(CallModel call, CallProvider provider) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryOrange, Color(0xFF004CC8)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 64,
            backgroundImage: call.remoteAvatar.isNotEmpty
                ? NetworkImage(call.remoteAvatar)
                : null,
            backgroundColor: Colors.white24,
            child: call.remoteAvatar.isEmpty
                ? Text(call.remoteName[0].toUpperCase(),
                    style: const TextStyle(
                        fontSize: 48,
                        color: Colors.white,
                        fontWeight: FontWeight.bold))
                : null,
          ),
          const SizedBox(height: 24),
          Text(call.remoteName,
              style: const TextStyle(
                  color: Colors.white, fontSize: 26, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Text(
            call.status == CallStatus.active
                ? provider.formattedDuration
                : 'Đang gọi...',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _ControlBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final double size;
  final VoidCallback onTap;

  const _ControlBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = Colors.white24,
    this.size = 52,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: size / 2,
            backgroundColor: color,
            child: Icon(icon, color: Colors.white, size: size * 0.5),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }
}
