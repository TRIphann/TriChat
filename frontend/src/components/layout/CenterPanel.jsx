import { useEffect, useRef, useState } from 'react';
import { useChatStore } from '../../store/chatStore';
import { useUiStore } from '../../store/uiStore';
import { useCallStore } from '../../store/callStore';
import { Avatar } from '../ui';
import MessageBubble from '../chat/MessageBubble';
import ChatComposer from '../chat/ChatComposer';
import NewsfeedView from './NewsfeedView';
import { ProfileSection } from './RightPanel';
import { formatLastSeen } from '../../lib/format';
import './centerPanel.css';

export default function CenterPanel() {
  const centerMode = useUiStore((s) => s.centerMode);
  const setCenterMode = useUiStore((s) => s.setCenterMode);
  const activeConvId = useUiStore((s) => s.activeConvId);
  const closeConversation = useUiStore((s) => s.closeConversation);
  const activeUserId = useUiStore((s) => s.activeUserId);
  const closeProfileInCenter = useUiStore((s) => s.closeProfileInCenter);
  const conversations = useChatStore((s) => s.conversations);
  const activeConv = useChatStore((s) => s.activeConversation);
  const openConversation = useChatStore((s) => s.openConversation);
  const chatService = useChatServiceLazy();

  // Resolve current conversation object
  const conv =
    conversations.find((c) => c.id === activeConvId) || activeConv;

  useEffect(() => {
    if (!activeConvId) return;
    const c = conversations.find((x) => x.id === activeConvId);
    if (c) {
      if (!activeConv || activeConv.id !== c.id) openConversation(c);
    } else {
      chatService.getConversation(activeConvId)
        .then((c) => openConversation(c))
        .catch(() => {});
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [activeConvId, conversations.length]);

  return (
    <div className="center-panel">
      <CenterToolbar
        centerMode={centerMode}
        setCenterMode={setCenterMode}
        conv={conv}
        onBack={centerMode === 'profile' ? closeProfileInCenter : closeConversation}
        activeUserId={activeUserId}
      />

      <div className="center-panel__body">
        {centerMode === 'chat' ? (
          <ChatArea conv={conv} />
        ) : centerMode === 'profile' ? (
          <ProfileSection userId={activeUserId || 'me'} />
        ) : (
          <NewsfeedView embedded />
        )}
      </div>
    </div>
  );
}

function useChatServiceLazy() {
  return { getConversation: async (id) => {
    const { chatService } = await import('../../services/chat.service');
    return chatService.getConversation(id);
  } };
}

function CenterToolbar({ centerMode, setCenterMode, conv, onBack, activeUserId }) {
  const onlineStatuses = useChatStore((s) => s.onlineStatuses);
  const otherOnline = conv?.otherUserId ? onlineStatuses[conv.otherUserId] : false;
  const startOutgoing = useCallStore((s) => s.startOutgoing);
  const setActiveUserId = useUiStore((s) => s.setActiveUserId);

  const otherName = conv?.displayName || 'Hội thoại';

  // PROFILE MODE — chỉ hiện tiêu đề + nút đóng (back), không có mode switch
  if (centerMode === 'profile') {
    const title = activeUserId === 'me' ? 'Hồ sơ của bạn' : 'Hồ sơ';
    return (
      <header className="center-panel__header center-panel__header--simple">
        <div className="center-panel__conv">
          <button
            className="center-panel__back"
            onClick={onBack}
            aria-label="Đóng"
            title="Đóng"
          >×</button>
          <div className="center-panel__info">
            <div>
              <div className="center-panel__name">{title}</div>
            </div>
          </div>
        </div>
      </header>
    );
  }

  return (
    <header className="center-panel__header">
      <div className="center-panel__conv">
        {conv && (
          <button className="center-panel__back" onClick={onBack} aria-label="Đóng">×</button>
        )}
        <button
          className="center-panel__info"
          onClick={() => {
            if (!conv) return;
            if (conv.type === 'private') setActiveUserId(conv.otherUserId);
            else setActiveUserId(conv.id); // group: mở profile nhóm
          }}
        >
          <Avatar
            src={conv?.otherUserAvatar || conv?.groupAvatarUrl}
            name={otherName}
            size={40}
            online={conv?.type === 'private' ? otherOnline : undefined}
          />
          <div>
            <div className="center-panel__name">{otherName}</div>
            <div className="center-panel__status">
              {conv
                ? conv.type === 'private'
                  ? otherOnline
                    ? 'Đang hoạt động'
                    : conv?.otherUserLastSeen
                    ? `Hoạt động ${formatLastSeen(conv.otherUserLastSeen)}`
                    : 'Ngoại tuyến'
                  : `${conv?.participants?.length || 0} thành viên`
                : 'Chọn một cuộc trò chuyện'}
            </div>
          </div>
        </button>

        {conv?.type === 'private' && (
          <div className="center-panel__actions">
            <button
              className="center-panel__icon"
              aria-label="Gọi thoại"
              title="Gọi thoại"
              onClick={() =>
                startOutgoing({
                  conversationId: conv.id,
                  calleeId: conv.otherUserId,
                  isVideo: false,
                  remoteName: conv.displayName,
                  remoteAvatar: conv.otherUserAvatar,
                })
              }
            >
              Gọi
            </button>
            <button
              className="center-panel__icon"
              aria-label="Gọi video"
              title="Gọi video"
              onClick={() =>
                startOutgoing({
                  conversationId: conv.id,
                  calleeId: conv.otherUserId,
                  isVideo: true,
                  remoteName: conv.displayName,
                  remoteAvatar: conv.otherUserAvatar,
                })
              }
            >
              Video
            </button>
          </div>
        )}
      </div>

      <div className="center-panel__mode-switch">
        <button
          className={`center-panel__mode-btn ${centerMode === 'chat' ? 'is-active' : ''}`}
          onClick={() => setCenterMode('chat')}
        >
          Trò chuyện
        </button>
        <button
          className={`center-panel__mode-btn ${centerMode === 'feed' ? 'is-active' : ''}`}
          onClick={() => setCenterMode('feed')}
        >
          Bảng tin
        </button>
      </div>
    </header>
  );
}

function ChatArea({ conv }) {
  const messages = useChatStore((s) => s.messages);
  const loadingMessages = useChatStore((s) => s.loadingMessages);
  const sendMessage = useChatStore((s) => s.sendMessage);
  const reactToMessage = useChatStore((s) => s.reactToMessage);
  const deleteMessage = useChatStore((s) => s.deleteMessage);
  const markAsRead = useChatStore((s) => s.markAsRead);

  const [replyTo, setReplyTo] = useState(null);
  const scrollRef = useRef(null);

  useEffect(() => {
    if (!scrollRef.current) return;
    scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
  }, [messages.length]);

  useEffect(() => {
    if (!conv) return;
    const last = messages[messages.length - 1];
    if (last && !last.isMine) markAsRead(conv.id, last.id);
  }, [messages.length, conv?.id, markAsRead]);

  function onSend(payload) {
    sendMessage({ ...payload, replyToMessageId: replyTo?.id });
    setReplyTo(null);
  }

  if (!conv) {
    return (
      <div className="center-panel__placeholder">
        <div className="placeholder-art">
          <div className="placeholder-art__ball" />
          <div className="placeholder-art__ball placeholder-art__ball--2" />
          <div className="placeholder-art__ball placeholder-art__ball--3" />
        </div>
        <h2>Chào mừng đến với TriChat</h2>
        <p>Chọn một cuộc trò chuyện ở bên trái, hoặc mở Bảng tin để xem bài viết mới.</p>
      </div>
    );
  }

  return (
    <>
      {replyTo && (
        <div className="chat-room__reply-banner">
          <span>
            Đang trả lời: <strong>{replyTo.content?.slice(0, 80) || 'Tin nhắn'}</strong>
          </span>
          <button onClick={() => setReplyTo(null)} aria-label="Hủy">×</button>
        </div>
      )}

      <div className="chat-room__messages no-scrollbar" ref={scrollRef}>
        {loadingMessages && messages.length === 0 ? (
          <div style={{ textAlign: 'center', color: 'var(--text-3)', padding: 40 }}>
            Đang tải...
          </div>
        ) : (
          messages.map((m) => (
            <MessageBubble
              key={m.id}
              message={m}
              onReply={setReplyTo}
              onReact={(emoji) => reactToMessage(conv.id, m.id, emoji)}
              onDelete={(msg) => deleteMessage(conv.id, msg.id)}
              onRetry={(msg) => {
                sendMessage({
                  type: msg.type,
                  content: msg.content,
                  mediaUrl: msg.mediaUrl,
                  fileName: msg.fileName,
                });
              }}
            />
          ))
        )}
      </div>

      <ChatComposer onSend={onSend} disabled={!conv} />
    </>
  );
}
