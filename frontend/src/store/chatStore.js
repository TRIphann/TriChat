import { create } from 'zustand';
import { chatService } from '../services/chat.service';
import { createChatConnection } from '../lib/signalr';

export const useChatStore = create((set, get) => ({
  conversations: [],
  loadingConversations: false,
  error: null,

  activeConversation: null,
  messages: [],
  loadingMessages: false,

  onlineStatuses: {}, // userId -> isOnline
  typing: {}, // conversationId -> { userId, isTyping }

  signalR: null,
  heartbeatTimer: null,
  currentUid: null,

  async init(uid) {
    if (get().currentUid === uid && get().signalR) return;
    set({ currentUid: uid });
    await get().connectSignalR(uid);
    await get().loadConversations();
    get().startHeartbeat();
  },

  async connectSignalR(uid) {
    if (get().signalR) return;
    const conn = createChatConnection({ userId: uid });

    conn.on('ReceiveMessage', (msg) => get().handleReceiveMessage(msg));
    conn.on('MessageSent', (msg) => get().handleMessageSent(msg));
    conn.on('UserTyping', (data) => get().handleUserTyping(data));
    conn.on('MessageRead', (data) => get().handleMessageRead(data));
    conn.on('MessageDelivered', (data) => get().handleMessageDelivered(data));
    conn.on('MessageReactionUpdated', (data) => get().handleReactionUpdated(data));
    conn.on('MessageDeleted', (data) => get().handleMessageDeleted(data));
    conn.on('MessageUpdated', (msg) => get().handleMessageUpdated(msg));
    conn.on('UserStatusChanged', (data) => get().handleUserStatus(data));
    conn.on('ConversationCreated', (conv) => get().handleConversationCreated(conv));
    conn.on('GroupUpdated', (conv) => get().handleGroupUpdated(conv));
    conn.on('ParticipantsAdded', () => {});
    conn.on('ParticipantRemoved', (data) => get().handleParticipantRemoved(data));
    conn.on('RemovedFromConversation', (data) => get().handleRemoved(data));
    conn.on('IncomingCall', (data) => get().handleIncomingCall?.(data));
    conn.on('CallAccepted', () => get().handleCallAccepted?.());
    conn.on('CallRejected', (data) => get().handleCallRejected?.(data));
    conn.on('CallEnded', () => get().handleCallEnded?.());
    conn.on('Error', (data) => {
      const { message, clientTempId } = data || {};
      if (clientTempId) {
        set((s) => ({
          messages: s.messages.map((m) =>
            m.id === clientTempId ? { ...m, status: 'failed' } : m,
          ),
        }));
      }
    });

    try {
      await conn.start();
      // Backend SetOnline/SetOffline/Heartbeat đều yêu cầu userId positional arg
      await conn.invoke('SetOnline', uid);
      set({ signalR: conn });
    } catch (e) {
      console.warn('[chat] signalr connect failed:', e);
    }
  },

  startHeartbeat() {
    if (get().heartbeatTimer) clearInterval(get().heartbeatTimer);
    const t = setInterval(() => {
      const uid = get().currentUid;
      if (!uid) return;
      get().signalR?.invoke?.('Heartbeat', uid).catch(() => {});
    }, 3 * 60 * 1000);
    set({ heartbeatTimer: t });
  },

  async loadConversations() {
    set({ loadingConversations: true, error: null });
    try {
      const list = await chatService.getConversations();
      set({ conversations: list || [], loadingConversations: false });
      const seeded = {};
      for (const c of list || []) {
        if (c.type === 'private' && c.otherUserId && c.otherUserOnline != null) {
          seeded[c.otherUserId] = c.otherUserOnline;
        }
      }
      set((s) => ({ onlineStatuses: { ...s.onlineStatuses, ...seeded } }));
    } catch (e) {
      set({ loadingConversations: false, error: e.message });
    }
  },

  async openConversation(conv) {
    set({
      activeConversation: conv,
      messages: [],
      typing: { ...get().typing, [conv.id]: null },
    });
    await get().loadMessages(conv.id);
  },

  async loadMessages(conversationId) {
    set({ loadingMessages: true });
    try {
      const list = await chatService.getMessages(conversationId);
      set({ messages: list || [], loadingMessages: false });
    } catch (e) {
      set({ loadingMessages: false, error: e.message });
    }
  },

  async sendMessage({ content, type = 'text', mediaUrl, fileName, fileSize, duration, latitude, longitude, address, replyToMessageId, mediaBlob }) {
    const conv = get().activeConversation;
    if (!conv) return;
    const tempId = `_pending_${Date.now()}`;
    const optimistic = {
      id: tempId,
      conversationId: conv.id,
      senderId: get().currentUid,
      senderName: 'Bạn',
      senderAvatar: '',
      type,
      content,
      mediaUrl: mediaUrl || null,
      fileName: fileName || null,
      fileSize: fileSize || null,
      duration: duration || null,
      replyToMessageId: replyToMessageId || null,
      status: 'sending',
      createdAt: new Date().toISOString(),
      isMine: true,
      reactions: {},
      totalReactions: 0,
    };

    // Local blob preview (image / audio)
    if (mediaBlob) {
      optimistic.localPreview = URL.createObjectURL(mediaBlob);
    }

    set((s) => ({ messages: [...s.messages, optimistic] }));

    try {
      let finalMediaUrl = mediaUrl;
      if (mediaBlob) {
        const up = await chatService.uploadMedia(conv.id, mediaBlob);
        finalMediaUrl = up?.media_url || up?.mediaUrl || null;
      }

      await get().signalR?.invoke?.('SendMessage', {
        conversation_id: conv.id,
        type,
        content,
        media_url: finalMediaUrl || undefined,
        file_name: fileName || undefined,
        file_size: fileSize || undefined,
        duration: duration || undefined,
        reply_to_message_id: replyToMessageId || undefined,
        latitude,
        longitude,
        address,
        client_temp_id: tempId,
      }, get().currentUid);
    } catch (e) {
      set((s) => ({
        messages: s.messages.map((m) => (m.id === tempId ? { ...m, status: 'failed' } : m)),
        error: e.message,
      }));
    }
  },

  async sendTyping(conversationId, isTyping) {
    try {
      await get().signalR?.invoke?.('UserTyping', conversationId, get().currentUid, isTyping);
    } catch {}
  },

  async markAsRead(conversationId, messageId) {
    try {
      await get().signalR?.invoke?.('MarkAsRead', conversationId, messageId, get().currentUid);
    } catch {}
  },

  async reactToMessage(conversationId, messageId, emoji) {
    try {
      await get().signalR?.invoke?.('ReactToMessage', {
        conversation_id: conversationId,
        message_id: messageId,
        emoji,
      }, get().currentUid);
    } catch {}
  },

  async deleteMessage(conversationId, messageId) {
    try {
      await get().signalR?.invoke?.('DeleteMessage', conversationId, messageId, get().currentUid);
    } catch {}
  },

  async createConversation(payload) {
    return chatService.createConversation(payload);
  },

  async startChatWithUser(userId) {
    if (userId === get().currentUid) {
      throw new Error('Không thể nhắn tin cho chính mình');
    }
    const existing = get().conversations.find(
      (c) => c.type === 'private' && c.otherUserId === userId,
    );
    if (existing) {
      await get().openConversation(existing);
      return existing;
    }
    // Backend CreateConversationRequest: snake_case (type, participant_ids, ...)
    const conv = await chatService.createConversation({
      type: 'private',
      participant_ids: [userId],
    });
    set((s) => ({ conversations: [conv, ...s.conversations] }));
    await get().openConversation(conv);
    return conv;
  },

  // Realtime handlers
  handleReceiveMessage(msg) {
    const m = withMine(msg, get().currentUid);
    set((s) => {
      const list = [...s.messages];
      const exists = list.some((x) => x.id === m.id);
      if (!exists) list.push(m);
      return {
        messages: list,
        conversations: updateConvLastMessage(s.conversations, m, get().currentUid),
      };
    });
  },

  handleMessageSent(msg) {
    const m = withMine(msg, get().currentUid);
    set((s) => {
      let list = [...s.messages];
      if (m.clientTempId) {
        const idx = list.findIndex((x) => x.id === m.clientTempId);
        if (idx !== -1) {
          list[idx] = m;
        } else if (!list.some((x) => x.id === m.id)) {
          list.push(m);
        }
      } else if (!list.some((x) => x.id === m.id)) {
        list.push(m);
      }
      return {
        messages: list,
        conversations: updateConvLastMessage(s.conversations, m, get().currentUid),
      };
    });
  },

  handleUserTyping(data) {
    if (!data) return;
    const { conversation_id, user_id, is_typing } = data;
    set((s) => ({
      typing: { ...s.typing, [conversation_id]: is_typing ? user_id : null },
    }));
  },

  handleMessageRead(data) {
    const { conversation_id, message_id } = data || {};
    if (!conversation_id || !message_id) return;
    set((s) => ({
      messages: s.messages.map((m) => {
        if (m.conversationId !== conversation_id || !m.isMine) return m;
        // mark this + any earlier message of mine as read
        if (s.messages.findIndex((x) => x.id === message_id) >=
            s.messages.findIndex((x) => x.id === m.id)) {
          return m.status === 'read' ? m : { ...m, status: 'read' };
        }
        return m;
      }),
    }));
  },

  handleMessageDelivered(data) {
    const { conversation_id, message_id } = data || {};
    set((s) => ({
      messages: s.messages.map((m) =>
        m.conversationId === conversation_id && m.id === message_id && m.status === 'sent'
          ? { ...m, status: 'delivered' }
          : m,
      ),
    }));
  },

  handleReactionUpdated(data) {
    const { conversation_id, message_id, reactions } = data || {};
    set((s) => ({
      messages: s.messages.map((m) =>
        m.conversationId === conversation_id && m.id === message_id
          ? { ...m, reactions: reactions || {}, totalReactions: totalOf(reactions) }
          : m,
      ),
    }));
  },

  handleMessageDeleted(data) {
    const { conversation_id, message_id } = data || {};
    set((s) => ({
      messages: s.messages.map((m) =>
        m.conversationId === conversation_id && m.id === message_id
          ? { ...m, isDeleted: true, content: 'Tin nhắn đã bị thu hồi' }
          : m,
      ),
    }));
  },

  handleMessageUpdated(msg) {
    const m = withMine(msg, get().currentUid);
    set((s) => ({
      messages: s.messages.map((x) => (x.id === m.id ? m : x)),
    }));
  },

  handleUserStatus(data) {
    const { user_id, is_online } = data || {};
    set((s) => ({ onlineStatuses: { ...s.onlineStatuses, [user_id]: is_online } }));
  },

  handleConversationCreated(conv) {
    set((s) =>
      s.conversations.some((c) => c.id === conv.id)
        ? s
        : { conversations: [conv, ...s.conversations] },
    );
  },

  handleGroupUpdated(conv) {
    set((s) => ({
      conversations: s.conversations.map((c) => (c.id === conv.id ? conv : c)),
      activeConversation:
        s.activeConversation?.id === conv.id ? conv : s.activeConversation,
    }));
  },

  handleParticipantRemoved(data) {
    const { conversation_id, removed_user_id } = data || {};
    if (removed_user_id === get().currentUid) {
      set((s) => ({
        conversations: s.conversations.filter((c) => c.id !== conversation_id),
        activeConversation:
          s.activeConversation?.id === conversation_id ? null : s.activeConversation,
        messages: s.activeConversation?.id === conversation_id ? [] : s.messages,
      }));
    }
  },

  handleRemoved(data) {
    const { conversation_id } = data || {};
    set((s) => ({
      conversations: s.conversations.filter((c) => c.id !== conversation_id),
      activeConversation:
        s.activeConversation?.id === conversation_id ? null : s.activeConversation,
      messages: s.activeConversation?.id === conversation_id ? [] : s.messages,
    }));
  },

  handleIncomingCall(data) {
    // bridge sang callStore qua window event
    window.dispatchEvent(new CustomEvent('trichat:incoming-call', { detail: data }));
  },

  handleCallAccepted() {
    window.dispatchEvent(new CustomEvent('trichat:call-accepted'));
  },

  handleCallRejected(data) {
    window.dispatchEvent(new CustomEvent('trichat:call-rejected', { detail: data }));
  },

  handleCallEnded() {
    window.dispatchEvent(new CustomEvent('trichat:call-ended'));
  },

  async dispose() {
    try {
      // Backend yêu cầu userId positional
      const uid = get().currentUid;
      if (uid) await get().signalR?.invoke?.('SetOffline', uid);
      await get().signalR?.stop();
    } catch {}
    if (get().heartbeatTimer) clearInterval(get().heartbeatTimer);
    set({ signalR: null, heartbeatTimer: null, currentUid: null });
  },
}));

function withMine(msg, currentUid) {
  if (!msg) return msg;
  return { ...msg, isMine: msg.senderId === currentUid || msg.sender_id === currentUid };
}

function totalOf(reactions) {
  if (!reactions) return 0;
  return Object.values(reactions).reduce((sum, v) => sum + (Array.isArray(v) ? v.length : 0), 0);
}

function updateConvLastMessage(conversations, m) {
  const idx = conversations.findIndex((c) => c.id === m.conversationId);
  if (idx === -1) return conversations;
  const list = [...conversations];
  const conv = {
    ...list[idx],
    lastMessage: m,
    updatedAt: m.createdAt || new Date().toISOString(),
  };
  // active conversation check via store state, not direct get()
  if (!m.isMine && typeof useChatStore !== 'undefined') {
    const active = useChatStore.getState().activeConversation;
    const isActive = active?.id === m.conversationId;
    conv.unreadCount = isActive ? 0 : (conv.unreadCount || 0) + 1;
  }
  list.splice(idx, 1);
  list.unshift(conv);
  return list;
}
