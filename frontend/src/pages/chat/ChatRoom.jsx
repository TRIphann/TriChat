import { useEffect, useRef, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { useChatStore } from '../../store/chatStore';
import { useCallStore } from '../../store/callStore';
import { chatService } from '../../services/chat.service';
import { Avatar } from '../../components/ui';
import MessageBubble from '../../components/chat/MessageBubble';
import ChatComposer from '../../components/chat/ChatComposer';
import { formatLastSeen } from '../../lib/format';
import './chatRoom.css';

export default function ChatRoom() {
  const { id } = useParams();
  const nav = useNavigate();
  const messages = useChatStore((s) => s.messages);
  const conversations = useChatStore((s) => s.conversations);
  const activeConv = useChatStore((s) => s.activeConversation);
  const onlineStatuses = useChatStore((s) => s.onlineStatuses);
  const loadingMessages = useChatStore((s) => s.loadingMessages);
  const sendMessage = useChatStore((s) => s.sendMessage);
  const openConversation = useChatStore((s) => s.openConversation);
  const startOutgoing = useCallStore((s) => s.startOutgoing);

  const [replyTo, setReplyTo] = useState(null);
  const scrollRef = useRef(null);

  useEffect(() => {
    const conv = conversations.find((c) => c.id === id) || activeConv;
    if (conv && conv.id === id) {
      openConversation(conv);
    } else if (id) {
      chatService.getConversation(id).then((c) => openConversation(c)).catch(() => {});
    }
  }, [id, openConversation, conversations.length]);

  useEffect(() => {
    if (!scrollRef.current) return;
    scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
  }, [messages.length]);

  const conv = conversations.find((c) => c.id === id) || activeConv;
  const otherOnline = conv?.otherUserId ? onlineStatuses[conv.otherUserId] : false;

  function onSend(payload) {
    sendMessage({
      ...payload,
      replyToMessageId: replyTo?.id,
    });
    setReplyTo(null);
  }

  return (
    <div className="chat-room">
      <header className="chat-room__header">
        <button className="chat-room__back" onClick={() => nav('/chat-list')}>←</button>
        <button className="chat-room__info" onClick={() => conv?.type === 'group' && nav(`/group-info/${conv.id}`)}>
          <Avatar src={conv?.otherUserAvatar || conv?.groupAvatarUrl} name={conv?.displayName} size={40} online={otherOnline} />
          <div>
            <div className="chat-room__name">{conv?.displayName || 'Hội thoại'}</div>
            <div className="chat-room__status">
              {conv?.type === 'private'
                ? (otherOnline ? 'Đang hoạt động' : (conv?.otherUserLastSeen ? `Hoạt động ${formatLastSeen(conv.otherUserLastSeen)}` : 'Ngoại tuyến'))
                : `${conv?.participants?.length || 0} thành viên`}
            </div>
          </div>
        </button>
        <div className="chat-room__actions">
          <button
            className="chat-room__icon"
            aria-label="Gọi thoại"
            onClick={() => conv?.otherUserId && startOutgoing({
              conversationId: conv.id,
              calleeId: conv.otherUserId,
              isVideo: false,
              remoteName: conv.displayName,
              remoteAvatar: conv.otherUserAvatar,
            })}
          >📞</button>
          <button
            className="chat-room__icon"
            aria-label="Gọi video"
            onClick={() => conv?.otherUserId && startOutgoing({
              conversationId: conv.id,
              calleeId: conv.otherUserId,
              isVideo: true,
              remoteName: conv.displayName,
              remoteAvatar: conv.otherUserAvatar,
            })}
          >📹</button>
        </div>
      </header>

      {replyTo && (
        <div className="chat-room__reply-banner">
          <span>Đang trả lời: <strong>{replyTo.content?.slice(0, 80) || 'Tin nhắn'}</strong></span>
          <button onClick={() => setReplyTo(null)} aria-label="Hủy">×</button>
        </div>
      )}

      <div className="chat-room__messages no-scrollbar" ref={scrollRef}>
        {loadingMessages && messages.length === 0 ? (
          <div style={{ textAlign: 'center', color: 'var(--text-3)', padding: 40 }}>Đang tải...</div>
        ) : (
          messages.map((m) => (
            <MessageBubble key={m.id} message={m} onReply={() => setReplyTo(m)} />
          ))
        )}
      </div>

      <ChatComposer onSend={onSend} disabled={!conv} />
    </div>
  );
}
