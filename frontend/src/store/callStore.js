import { create } from 'zustand';
import { chatService } from '../services/chat.service';
import { useChatStore } from './chatStore';
import { buildChannelName, joinAgora, leaveAgora, makeAgoraClient } from '../lib/agora';

export const useCallStore = create((set, get) => ({
  currentCall: null,
  status: 'idle', // idle | dialing | ringing | active | ended | rejected | missed
  seconds: 0,
  isMuted: false,
  isVideoOff: false,
  isSpeakerOn: false,

  agoraClient: null,
  timer: null,

  // Caller side
  async startOutgoing({ conversationId, calleeId, isVideo, remoteName, remoteAvatar }) {
    set({
      currentCall: {
        conversationId,
        callerId: get().currentUid,
        calleeId,
        isVideo,
        isIncoming: false,
        remoteName,
        remoteAvatar,
      },
      status: 'dialing',
      seconds: 0,
    });

    // 30s timeout — nếu không ai bắt thì lưu log missed
    setTimeout(() => {
      if (get().status === 'dialing') {
        get().markMissed();
      }
    }, 30_000);

    try {
      const chatStore = useChatStore.getState();
      await chatStore.signalR?.invoke?.('InitiateCall', {
        conversation_id: conversationId,
        callee_id: calleeId,
        call_type: isVideo ? 'video' : 'voice',
        caller_id: get().currentUid,
        caller_name: remoteName,
        caller_avatar: remoteAvatar,
      });
    } catch (e) {
      console.warn('[call] initiate failed', e);
    }
  },

  receiveIncoming({ conversationId, callerId, callerName, callerAvatar, callType }) {
    set({
      currentCall: {
        conversationId,
        callerId,
        calleeId: get().currentUid,
        isVideo: callType === 'video',
        isIncoming: true,
        remoteName: callerName,
        remoteAvatar: callerAvatar,
      },
      status: 'ringing',
    });
  },

  async accept() {
    const call = get().currentCall;
    if (!call) return;
    set({ status: 'active' });
    get().startTimer();
    try {
      const chatStore = useChatStore.getState();
      await chatStore.signalR?.invoke?.('AcceptCall', call.conversationId, call.callerId);
    } catch {}
    await get().joinAgora();
  },

  async reject(reason = 'rejected') {
    const call = get().currentCall;
    if (!call) return;
    set({ status: 'rejected' });
    try {
      const chatStore = useChatStore.getState();
      await chatStore.signalR?.invoke?.('RejectCall', call.conversationId, call.callerId, reason);
    } catch {}
    setTimeout(() => get().endCallLocal('rejected'), 1500);
  },

  async endCall() {
    const call = get().currentCall;
    if (!call) return;
    const otherId = call.callerId === get().currentUid ? call.calleeId : call.callerId;
    if (!otherId) {
      await get().endCallLocal('ended');
      return;
    }
    try {
      const chatStore = useChatStore.getState();
      await chatStore.signalR?.invoke?.('EndCall', call.conversationId, otherId);
    } catch {}
    await get().endCallLocal('ended');
  },

  markMissed() {
    const call = get().currentCall;
    if (!call) return;
    set({ status: 'missed' });
    // Log call message
    chatService
      .sendMessage({
        ConversationId: call.conversationId,
        Type: 'call',
        Content: call.isVideo ? 'Cuộc gọi video nhỡ' : 'Cuộc gọi thoại nhỡ',
      })
      .catch(() => {});
    setTimeout(() => get().endCallLocal('missed'), 1500);
  },

  async endCallLocal(_reason) {
    if (get().timer) {
      clearInterval(get().timer);
    }
    try {
      await leaveAgora(get().agoraClient);
    } catch {}
    set({
      currentCall: null,
      status: 'idle',
      seconds: 0,
      isMuted: false,
      isVideoOff: false,
      isSpeakerOn: false,
      agoraClient: null,
      timer: null,
    });
  },

  startTimer() {
    if (get().timer) clearInterval(get().timer);
    const t = setInterval(() => {
      set((s) => ({ seconds: s.seconds + 1 }));
    }, 1000);
    set({ timer: t });
  },

  toggleMute() {
    set((s) => ({ isMuted: !s.isMuted }));
  },
  toggleVideo() {
    set((s) => ({ isVideoOff: !s.isVideoOff }));
  },
  toggleSpeaker() {
    set((s) => ({ isSpeakerOn: !s.isSpeakerOn }));
  },

  async joinAgora() {
    const call = get().currentCall;
    if (!call) return;
    try {
      const channel = buildChannelName(call.callerId, call.calleeId);
      const client = makeAgoraClient();
      await joinAgora(client, channel, '', 0);
      set({ agoraClient: client });
    } catch (e) {
      console.warn('[agora] join failed', e);
    }
  },
}));

useCallStore.setState({ currentUid: null });
