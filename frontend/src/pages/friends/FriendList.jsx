import { useEffect, useRef, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  useFriendStore,
  FRIENDS_PAGE_SIZE,
} from '../../store/friendStore';
import { Avatar, Badge, Spinner } from '../../components/ui';
import { useChatStore } from '../../store/chatStore';
import './friends.css';

export default function FriendList() {
  const nav = useNavigate();
  const friends        = useFriendStore((s) => s.friends);
  const friendsTotal   = useFriendStore((s) => s.friendsTotal);
  const friendsHasMore = useFriendStore((s) => s.friendsHasMore);
  const friendsState   = useFriendStore((s) => s.friendsState);
  const pendingReceived = useFriendStore((s) => s.pendingReceived);
  const loadFriendsPage = useFriendStore((s) => s.loadFriendsPage);
  const [tab, setTab] = useState('friends');

  // Tải page đầu khi vào trang
  useEffect(() => {
    loadFriendsPage({ reset: true });
  }, [loadFriendsPage]);

  // Infinite scroll
  const sentinelRef = useRef(null);
  const loadingRef  = useRef(false);
  useEffect(() => {
    const node = sentinelRef.current;
    if (!node) return;
    const observer = new IntersectionObserver(
      (entries) => {
        for (const entry of entries) {
          if (entry.isIntersecting && friendsHasMore && !loadingRef.current &&
              friendsState !== 'loading') {
            loadingRef.current = true;
            loadFriendsPage({ reset: false }).finally(() => {
              loadingRef.current = false;
            });
          }
        }
      },
      { rootMargin: '300px 0px' },
    );
    observer.observe(node);
    return () => observer.disconnect();
  }, [friendsHasMore, friendsState, loadFriendsPage]);

  return (
    <div className="friends-page">
      <header className="friends-page__header">
        <h1 className="text-serif">Bạn bè</h1>
        <div className="friends-page__actions">
          <button className="chat-list__new" onClick={() => nav('/add-friend')}>+ Thêm bạn</button>
          <button className="chat-list__new" onClick={() => nav('/friend-requests')}>
            Lời mời {pendingReceived.length > 0 && <Badge variant="primary">{pendingReceived.length}</Badge>}
          </button>
        </div>
      </header>

      <div className="friends-page__tabs">
        {['friends', 'groups', 'contacts'].map((t) => (
          <button
            key={t}
            className={`friends-page__tab ${tab === t ? 'is-active' : ''}`}
            onClick={() => setTab(t)}
          >
            {t === 'friends' ? 'Bạn bè' : t === 'groups' ? 'Nhóm' : 'Liên hệ'}
          </button>
        ))}
      </div>

      {tab === 'friends' && (
        friendsTotal === 0 && friendsState !== 'loading' ? (
          <div className="empty-state">
            <div className="empty-state__icon">👥</div>
            <h3>Chưa có bạn bè nào</h3>
            <p>Hãy thêm bạn bè để bắt đầu trò chuyện.</p>
            <button className="btn btn--primary btn--md" onClick={() => nav('/add-friend')}>Thêm bạn</button>
          </div>
        ) : (
          <>
            <p className="friends-page__count">
              {friends.length}/{friendsTotal} bạn — sắp xếp theo người nhắn gần đây
            </p>
            <div className="friends-page__grid">
              {friends.map((f) => (
                <FriendCard key={f.friendId} friend={f} />
              ))}
            </div>
            {friendsHasMore && (
              <div ref={sentinelRef} className="friends-page__sentinel">
                {friendsState === 'loading' && <Spinner size="sm" />}
              </div>
            )}
            {!friendsHasMore && friendsTotal > 0 && (
              <p className="friends-page__end">— Đã hết danh sách bạn bè —</p>
            )}
            {friendsState === 'loading' && friends.length === 0 && (
              <div className="friends-page__loading">
                <Spinner size="md" /> Đang tải…
              </div>
            )}
          </>
        )
      )}

      {tab === 'groups' && <p style={{ textAlign: 'center', color: 'var(--text-3)', marginTop: 60 }}>Chưa có nhóm nào.</p>}
      {tab === 'contacts' && <p style={{ textAlign: 'center', color: 'var(--text-3)', marginTop: 60 }}>Chuyển sang trang Liên hệ.</p>}
    </div>
  );
}

function FriendCard({ friend }) {
  const nav = useNavigate();
  const startChat = useChatStore.getState().startChatWithUser;
  const name = friend.fullName || `${friend.firstName} ${friend.lastName}`;
  return (
    <article className="friend-card">
      <Avatar src={friend.avatar} name={name} size={64} />
      <h3>{name}</h3>
      <div className="friend-card__actions">
        <button
          className="btn btn--secondary btn--sm"
          onClick={async () => {
            const conv = await startChat(friend.friendId);
            nav(`/chat-list/${conv.id}`);
          }}
        >💬 Nhắn tin</button>
      </div>
    </article>
  );
}
