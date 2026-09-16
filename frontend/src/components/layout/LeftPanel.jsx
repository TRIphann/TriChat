import { useEffect, useRef, useState } from 'react';
import { useChatStore } from '../../store/chatStore';
import { useFriendStore } from '../../store/friendStore';
import { useUiStore } from '../../store/uiStore';
import { useAuthStore } from '../../store/authStore';
import { Avatar, Badge } from '../ui';
import { formatLastSeen, formatRelativeShort } from '../../lib/format';
import { staggerCards, pageIn } from '../../lib/anime';
import './leftPanel.css';

export default function LeftPanel() {
  const leftTab = useUiStore((s) => s.leftTab);
  const setLeftTab = useUiStore((s) => s.setLeftTab);
  const setActiveUserId = useUiStore((s) => s.setActiveUserId);
  const rootRef = useRef(null);

  useEffect(() => {
    pageIn(rootRef.current?.querySelector('.left-panel__inner'));
  }, [leftTab]);

  return (
    <div className="left-panel" ref={rootRef}>
      {/* User strip — top of left column */}
      <MyAvatarStrip onProfile={() => setActiveUserId('me')} />

      {/* Sub-tabs */}
      <div className="left-panel__tabs">
        <button
          className={`left-panel__tab ${leftTab === 'chats' ? 'is-active' : ''}`}
          onClick={() => setLeftTab('chats')}
        >
          💬 Trò chuyện
        </button>
        <button
          className={`left-panel__tab ${leftTab === 'friends' ? 'is-active' : ''}`}
          onClick={() => setLeftTab('friends')}
        >
          👥 Bạn bè
        </button>
        <button
          className={`left-panel__tab ${leftTab === 'requests' ? 'is-active' : ''}`}
          onClick={() => setLeftTab('requests')}
        >
          📨 Lời mời
        </button>
      </div>

      <div className="left-panel__inner">
        {leftTab === 'chats' && <ChatsList />}
        {leftTab === 'friends' && <FriendsList />}
        {leftTab === 'requests' && <RequestsList />}
      </div>
    </div>
  );
}

function MyAvatarStrip({ onProfile }) {
  const profile = useAuthStore((s) => s.profile);
  const user = useAuthStore((s) => s.user);
  const fullName =
    profile?.fullName ||
    `${profile?.firstName || ''} ${profile?.lastName || ''}`.trim() ||
    user?.email ||
    'Bạn';
  return (
    <button className="left-panel__me" onClick={onProfile}>
      <Avatar src={profile?.avatar} name={fullName} size={40} />
      <div className="left-panel__me-text">
        <div className="left-panel__me-name">{fullName}</div>
        <div className="left-panel__me-sub">Xem hồ sơ của bạn</div>
      </div>
      <span className="left-panel__me-chev" aria-hidden>›</span>
    </button>
  );
}

function ChatsList() {
  const conversations = useChatStore((s) => s.conversations);
  const loading = useChatStore((s) => s.loadingConversations);
  const onlineStatuses = useChatStore((s) => s.onlineStatuses);
  const loadConversations = useChatStore((s) => s.loadConversations);
  const activeConvId = useUiStore((s) => s.activeConvId);
  const openConversation = useUiStore((s) => s.openConversation);
  const setRightFeedId = useUiStore((s) => s.setRightFeedId);
  const setActiveUserId = useUiStore((s) => s.setActiveUserId);
  const listRef = useRef(null);

  useEffect(() => {
    loadConversations();
    const t = setInterval(loadConversations, 30_000);
    return () => clearInterval(t);
  }, [loadConversations]);

  useEffect(() => {
    if (listRef.current && conversations.length) {
      staggerCards(listRef.current.querySelectorAll('.conv-tile'), { gap: 40, dur: 480, y: 14 });
    }
  }, [conversations.length]);

  return (
    <>
      <div className="left-panel__heading">
        <h2 className="left-panel__title">Tin nhắn</h2>
        <span className="left-panel__count">{conversations.length}</span>
      </div>

      {loading && conversations.length === 0 ? (
        <SkeletonList count={6} />
      ) : conversations.length === 0 ? (
        <div className="empty-state empty-state--compact">
          <div className="empty-state__icon">💬</div>
          <h3>Chưa có hội thoại nào</h3>
          <p>Mời bạn bè để bắt đầu trò chuyện.</p>
        </div>
      ) : (
        <ul className="left-panel__items no-scrollbar" ref={listRef}>
          {conversations.map((c) => (
            <li key={c.id}>
              <ConversationTile
                conv={c}
                online={onlineStatuses[c.otherUserId]}
                active={c.id === activeConvId}
                onClick={() => openConversation(c.id)}
                onAvatar={() => {
                  if (c.type === 'group') setRightFeedId(c.id);
                  else setActiveUserId(c.otherUserId);
                }}
              />
            </li>
          ))}
        </ul>
      )}
    </>
  );
}

function ConversationTile({ conv, online, active, onClick, onAvatar }) {
  const lastMsg = conv.lastMessage;
  const preview =
    lastMsg?.content ||
    (lastMsg?.type === 'image'
      ? '📷 Hình ảnh'
      : lastMsg?.type === 'audio'
      ? '🎙️ Tin nhắn thoại'
      : 'Chưa có tin nhắn');
  return (
    <div className={`conv-tile ${active ? 'is-active' : ''}`}>
      <Avatar
        src={conv.otherUserAvatar || conv.groupAvatarUrl}
        name={conv.displayName}
        size={48}
        online={conv.type === 'private' ? online : undefined}
        onClick={onAvatar}
      />
      <button className="conv-tile__body" onClick={onClick}>
        <div className="conv-tile__row1">
          <span className="conv-tile__name">{conv.displayName}</span>
          <span className="conv-tile__time">
            {lastMsg ? formatRelativeShort(lastMsg.createdAt) : ''}
          </span>
        </div>
        <div className="conv-tile__row2">
          <span className="conv-tile__preview">{preview}</span>
          {conv.unreadCount > 0 && (
            <span className="conv-tile__badge">{conv.unreadCount}</span>
          )}
        </div>
      </button>
    </div>
  );
}

function FriendsList() {
  const friends = useFriendStore((s) => s.friends);
  const loadAll = useFriendStore((s) => s.loadAll);
  const setActiveUserId = useUiStore((s) => s.setActiveUserId);
  const startChat = useChatStore((s) => s.startChatWithUser);
  const openConversation = useUiStore((s) => s.openConversation);
  const setCenterMode = useUiStore((s) => s.setCenterMode);
  const listRef = useRef(null);

  useEffect(() => {
    loadAll();
  }, [loadAll]);

  useEffect(() => {
    if (listRef.current && friends.length) {
      staggerCards(listRef.current.querySelectorAll('.conv-tile'), { gap: 40, dur: 480 });
    }
  }, [friends.length]);

  return (
    <>
      <div className="left-panel__heading">
        <h2 className="left-panel__title">Bạn bè</h2>
        <span className="left-panel__count">{friends.length}</span>
      </div>
      {friends.length === 0 ? (
        <div className="empty-state empty-state--compact">
          <div className="empty-state__icon">👥</div>
          <h3>Chưa có bạn bè nào</h3>
          <p>Hãy thêm bạn để bắt đầu trò chuyện.</p>
        </div>
      ) : (
        <ul className="left-panel__items no-scrollbar" ref={listRef}>
          {friends.map((f) => {
            const name = f.fullName || `${f.firstName || ''} ${f.lastName || ''}`.trim();
            return (
              <li key={f.friendId}>
                <div className="conv-tile">
                  <Avatar
                    src={f.avatar}
                    name={name}
                    size={48}
                    onClick={() => setActiveUserId(f.friendId)}
                  />
                  <button
                    className="conv-tile__body"
                    onClick={async () => {
                      const conv = await startChat(f.friendId);
                      openConversation(conv.id);
                      setCenterMode('chat');
                    }}
                  >
                    <div className="conv-tile__row1">
                      <span className="conv-tile__name">{name}</span>
                    </div>
                    <div className="conv-tile__row2">
                      <span className="conv-tile__preview">Bấm để nhắn tin</span>
                    </div>
                  </button>
                </div>
              </li>
            );
          })}
        </ul>
      )}
    </>
  );
}

function RequestsList() {
  const pendingReceived = useFriendStore((s) => s.pendingReceived);
  const pendingSent = useFriendStore((s) => s.pendingSent);
  const respond = useFriendStore((s) => s.respond);
  const loadAll = useFriendStore((s) => s.loadAll);
  const setActiveUserId = useUiStore((s) => s.setActiveUserId);
  const [tab, setTab] = useState('received');

  useEffect(() => {
    loadAll();
  }, [loadAll]);

  const list = tab === 'received' ? pendingReceived : pendingSent;

  return (
    <>
      <div className="left-panel__heading">
        <h2 className="left-panel__title">Lời mời</h2>
        <span className="left-panel__count">{pendingReceived.length}</span>
      </div>

      <div className="left-panel__subtabs">
        <button
          className={`left-panel__subtab ${tab === 'received' ? 'is-active' : ''}`}
          onClick={() => setTab('received')}
        >
          Đã nhận
          {pendingReceived.length > 0 && (
            <Badge variant="primary">{pendingReceived.length}</Badge>
          )}
        </button>
        <button
          className={`left-panel__subtab ${tab === 'sent' ? 'is-active' : ''}`}
          onClick={() => setTab('sent')}
        >
          Đã gửi
        </button>
      </div>

      {list.length === 0 ? (
        <div className="empty-state empty-state--compact">
          <div className="empty-state__icon">📨</div>
          <h3>Không có lời mời nào</h3>
          <p>Các lời mời kết bạn sẽ hiển thị ở đây.</p>
        </div>
      ) : (
        <ul className="left-panel__items no-scrollbar">
          {list.map((req) => {
            const otherId = tab === 'received' ? req.senderId : req.addresseeId;
            const otherName =
              tab === 'received'
                ? req.senderName || req.senderId
                : req.addresseeName || req.addresseeId;
            return (
              <li key={req.id}>
                <div className="conv-tile">
                  <Avatar
                    src={req.senderAvatar || req.addresseeAvatar}
                    name={otherName}
                    size={48}
                    onClick={() => setActiveUserId(otherId)}
                  />
                  <div className="conv-tile__body">
                    <div className="conv-tile__row1">
                      <span className="conv-tile__name">{otherName}</span>
                    </div>
                    <div className="conv-tile__row2">
                      {tab === 'received' ? (
                        <div className="request-actions">
                          <button
                            className="btn btn--primary btn--sm"
                            onClick={() => respond(req.id, true)}
                          >
                            Chấp nhận
                          </button>
                          <button
                            className="btn btn--ghost btn--sm"
                            onClick={() => respond(req.id, false)}
                          >
                            Từ chối
                          </button>
                        </div>
                      ) : (
                        <span className="conv-tile__preview">Đang chờ phản hồi</span>
                      )}
                    </div>
                  </div>
                </div>
              </li>
            );
          })}
        </ul>
      )}
    </>
  );
}

function SkeletonList({ count = 6 }) {
  return (
    <ul className="left-panel__items">
      {Array.from({ length: count }).map((_, i) => (
        <li key={i} className="conv-tile">
          <span
            className="skeleton"
            style={{ width: 48, height: 48, borderRadius: '50%' }}
          />
          <div style={{ flex: 1 }}>
            <span
              className="skeleton"
              style={{ width: '40%', height: 14, marginBottom: 8, display: 'block' }}
            />
            <span
              className="skeleton"
              style={{ width: '70%', height: 12, display: 'block' }}
            />
          </div>
        </li>
      ))}
    </ul>
  );
}
