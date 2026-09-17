import { create } from 'zustand';
import { chatService } from '../services/chat.service';
import { useChatStore } from './chatStore';
import { useAuthStore } from './authStore';
import { buildChannelName, joinAgora, leaveAgora, makeAgoraClient } from '../lib/agora';

/**
 * currentUid được inject từ authStore khi init() được gọi (useAppBootstrap).
 * KHÔNG khởi tạo mặc định ở module-level — sẽ luôn null và sai callerId.
 */
export const useCallStore = create((set, get) => ({
  currentCall: null,
  status: 'idle', // idle | dialing | ringing | active | ended | rejected | missed
  seconds: 0,
  isMuted: false,
  isVideoOff: false,
  isSpeakerOn: false,

  agoraClient: null,
  timer: null,

  // Sync uid từ authStore — gọi khi vào màn hình call hoặc khi user thay đổi.
  syncCurrentUid() {
    const u = useAuthStore.getState().user;
    set({ currentUid: u?.uid || null });
    return u?.uid || null;
  },

  // Caller side
  async startOutgoing({ conversationId, calleeId, isVideo, remoteName, remoteAvatar }) {
    const myUid = get().syncCurrentUid();
    if (!myUid) {
      throw new Error('Bạn cần đăng nhập để thực hiện cuộc gọi');
    }

    set({
      currentCall: {
        conversationId,
        callerId: myUid,
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
      // Backend ChatHub.InitiateCall nhận 6 POSITIONAL args (không phải object):
      //   (conversationId, calleeId, callType, callerId, callerName, callerAvatar)
      // callerName/callerAvatar là của CALLER (mình), không phải remote.
      const me = useAuthStore.getState().profile || {};
      const callerName = me.full_name || me.fullName || 'Người dùng';
      const callerAvatar = me.avatar || '';
      const callType = isVideo ? 'video' : 'voice';
      await chatStore.signalR?.invoke?.(
        'InitiateCall',
        conversationId,
        calleeId,
        callType,
        myUid,
        callerName,
        callerAvatar,
      );
    } catch (e) {
      console.warn('[call] initiate failed', e);
    }
  },

  receiveIncoming({ conversationId, callerId, callerName, callerAvatar, callType }) {
    const myUid = get().syncCurrentUid();
    set({
      currentCall: {
        conversationId,
        callerId,
        calleeId: myUid,
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
      // AcceptCall(conversationId, callerId)
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
    const myUid = get().syncCurrentUid();
    const otherId = call.callerId === myUid ? call.calleeId : call.callerId;
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
    // Log call message — backend snake_case (conversation_id, type, content)
    chatService
      .sendMessage({
        conversation_id: call.conversationId,
        type: 'call',
        content: call.isVideo ? 'Cuộc gọi video nhỡ' : 'Cuộc gọi thoại nhỡ',
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
