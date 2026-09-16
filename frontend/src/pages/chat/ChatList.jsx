import { useEffect, useRef, useState } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { useChatStore } from '../../store/chatStore';
import { useFriendStore } from '../../store/friendStore';
import { Avatar } from '../../components/ui';
import { formatLastSeen, formatRelativeShort } from '../../lib/format';
import { staggerCards, pageIn } from '../../lib/anime';
import './chatList.css';

export default function ChatList() {
  const nav = useNavigate();
  const conversations = useChatStore((s) => s.conversations);
  const loading = useChatStore((s) => s.loadingConversations);
  const onlineStatuses = useChatStore((s) => s.onlineStatuses);
  const loadConversations = useChatStore((s) => s.loadConversations);

  const listRef = useRef(null);

  useEffect(() => {
    pageIn(listRef.current);
  }, []);

  useEffect(() => {
    loadConversations();
    const t = setInterval(loadConversations, 30_000);
    return () => clearInterval(t);
  }, [loadConversations]);

  useEffect(() => {
    if (listRef.current && conversations.length) {
      staggerCards(listRef.current.querySelectorAll('.conv-tile'), { gap: 60, dur: 540, y: 18 });
    }
  }, [conversations.length]);

  return (
    <div className="chat-list" ref={listRef}>
      <header className="chat-list__header">
        <h1 className="chat-list__title text-serif">Trò chuyện</h1>
        <button className="chat-list__new" onClick={() => nav('/new-conversation')}>
          + Cuộc trò chuyện mới
        </button>
      </header>

      {loading && conversations.length === 0 ? (
        <SkeletonList />
      ) : conversations.length === 0 ? (
        <EmptyState onCreate={() => nav('/new-conversation')} />
      ) : (
        <ul className="chat-list__items no-scrollbar" ref={listRef}>
          {conversations.map((c) => (
            <li key={c.id}>
              <ConversationTile
                conv={c}
                online={onlineStatuses[c.otherUserId]}
                onClick={() => nav(`/chat-list/${c.id}`)}
              />
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}

function ConversationTile({ conv, online, onClick }) {
  const lastMsg = conv.lastMessage;
  const preview = lastMsg?.content || (lastMsg?.type === 'image' ? '📷 Hình ảnh' : lastMsg?.type === 'audio' ? '🎙️ Tin nhắn thoại' : 'Chưa có tin nhắn');
  return (
    <button className="conv-tile" onClick={onClick}>
      <Avatar
        src={conv.otherUserAvatar || conv.groupAvatarUrl}
        name={conv.displayName}
        size={52}
        online={conv.type === 'private' ? online : undefined}
      />
      <div className="conv-tile__body">
        <div className="conv-tile__row1">
          <span className="conv-tile__name">{conv.displayName}</span>
          <span className="conv-tile__time">{lastMsg ? formatRelativeShort(lastMsg.createdAt) : ''}</span>
        </div>
        <div className="conv-tile__row2">
          <span className="conv-tile__preview">{preview}</span>
          {conv.unreadCount > 0 && <span className="conv-tile__badge">{conv.unreadCount}</span>}
        </div>
      </div>
    </button>
  );
}

function SkeletonList() {
  return (
    <ul className="chat-list__items">
      {Array.from({ length: 6 }).map((_, i) => (
        <li key={i} className="conv-tile">
          <span className="skeleton" style={{ width: 52, height: 52, borderRadius: '50%' }} />
          <div style={{ flex: 1 }}>
            <span className="skeleton" style={{ width: '40%', height: 16, marginBottom: 8 }} />
            <span className="skeleton" style={{ width: '70%', height: 12 }} />
          </div>
        </li>
      ))}
    </ul>
  );
}

function EmptyState({ onCreate }) {
  return (
    <div className="empty-state">
      <div className="empty-state__icon">💬</div>
      <h3>Chưa có hội thoại nào</h3>
      <p>Hãy bắt đầu cuộc trò chuyện đầu tiên của bạn.</p>
      <button className="btn btn--primary btn--md" onClick={onCreate}>Bắt đầu</button>
    </div>
  );
}
