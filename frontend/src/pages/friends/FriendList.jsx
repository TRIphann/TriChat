import { useEffect, useRef, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useFriendStore } from '../../store/friendStore';
import { Avatar, Badge } from '../../components/ui';
import { staggerCards } from '../../lib/anime';
import { useChatStore } from '../../store/chatStore';
import './friends.css';

export default function FriendList() {
  const nav = useNavigate();
  const friends = useFriendStore((s) => s.friends);
  const pendingReceived = useFriendStore((s) => s.pendingReceived);
  const loadAll = useFriendStore((s) => s.loadAll);
  const listRef = useRef(null);
  const [tab, setTab] = useState('friends');

  useEffect(() => {
    loadAll();
  }, [loadAll]);

  useEffect(() => {
    if (listRef.current && friends.length) {
      staggerCards(listRef.current.querySelectorAll('.friend-card'), { gap: 60, dur: 540 });
    }
  }, [friends.length, tab]);

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
        friends.length === 0 ? (
          <div className="empty-state">
            <div className="empty-state__icon">👥</div>
            <h3>Chưa có bạn bè nào</h3>
            <p>Hãy thêm bạn bè để bắt đầu trò chuyện.</p>
            <button className="btn btn--primary btn--md" onClick={() => nav('/add-friend')}>Thêm bạn</button>
          </div>
        ) : (
          <div className="friends-page__grid" ref={listRef}>
            {friends.map((f) => (
              <FriendCard key={f.friendId} friend={f} />
            ))}
          </div>
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
