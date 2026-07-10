// Native implementation - uses flutter_webrtc
// This file is imported when NOT on web

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
    _setupWebRTC();
  }

  Future<void> _initRenderers() async {
    await _remoteRenderer.initialize();
    await _localRenderer.initialize();
    if (mounted) {
      setState(() => _rendererInited = true);
    }
  }

  Future<void> _setupWebRTC() async {
    final config = <String, dynamic>{
      'servers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ]
    };

    _pc = await createPeerConnection(config);

    _pc!.onIceCandidate = (candidate) {
      if (candidate != null) {
        final signalR = context.read<ChatProvider>().signalR;
        signalR?.send('SendIceCandidate', args: [
          widget.call.conversationId,
          widget.call.callerId,
          candidate.candidate ?? '',
          candidate.sdpMid ?? '',
          candidate.sdpMLineIndex ?? 0,
        ]);
      }
    };

    _pc!.onAddStream = (stream) {
      if (mounted) {
        setState(() {
          _remoteStream = stream;
          _remoteRenderer.srcObject = stream;
          _remoteStreamReady = true;
        });
      }
    };

    try {
      final stream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': widget.call.isVideo
            ? {'facingMode': 'user'}
            : false,
      });

      _localStream = stream;
      _localRenderer.srcObject = stream;
      _pc!.addStream(stream);
    } catch (_) {}
  }

  @override
  void dispose() {
    _localStream?.dispose();
    _remoteStream?.dispose();
    _remoteRenderer.dispose();
    _localRenderer.dispose();
    _pc?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Remote video or placeholder
          if (_remoteStreamReady && _rendererInited)
            Positioned.fill(
              child: RTCVideoView(
                _remoteRenderer,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              ),
            )
          else
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person, size: 80, color: Colors.white54),
                  SizedBox(height: 16),
                  Text(
                    'Đang kết nối...',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),

          // Local video preview
          if (widget.call.isVideo && _rendererInited)
            Positioned(
              right: 16,
              top: 60,
              child: Container(
                width: 100,
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                clipBehavior: Clip.antiAlias,
                child: RTCVideoView(
                  _localRenderer,
                  mirror: true,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
              ),
            ),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          widget.call.remoteName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.call.isVideo ? 'Video call' : 'Voice call',
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton(
                  icon: Icons.mic,
                  isActive: true,
                  onTap: () {},
                ),
                _buildControlButton(
                  icon: Icons.call_end,
                  isActive: false,
                  bgColor: Colors.red,
                  onTap: () => Navigator.pop(context),
                ),
                _buildControlButton(
                  icon: widget.call.isVideo ? Icons.videocam : Icons.videocam_off,
                  isActive: true,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required bool isActive,
    Color? bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: bgColor ?? (isActive ? Colors.white24 : Colors.transparent),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}
