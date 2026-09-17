import { useEffect, useRef, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useFriendStore } from '../../store/friendStore';
import { useChatStore } from '../../store/chatStore';
import { Avatar } from '../../components/ui';
import { staggerCards } from '../../lib/anime';

export default function NewConversation() {
  const nav = useNavigate();
  const friends = useFriendStore((s) => s.friends);
  const listRef = useRef(null);
  const [error, setError] = useState('');
  const [busyId, setBusyId] = useState(null);

  useEffect(() => {
    if (listRef.current && friends.length) {
      staggerCards(listRef.current.querySelectorAll('.conv-tile'), { gap: 60, dur: 540 });
    }
  }, [friends.length]);

  async function pick(userId) {
    setError('');
    setBusyId(userId);
    try {
      const conv = await useChatStore.getState().startChatWithUser(userId);
      nav(`/chat-list/${conv.id}`);
    } catch (e) {
      setError(e.message);
    } finally {
      setBusyId(null);
    }
  }

  return (
    <div className="chat-list">
      <header className="chat-list__header">
        <button className="chat-list__new" onClick={() => nav(-1)}>← Quay lại</button>
        <h1 className="chat-list__title text-serif">Cuộc trò chuyện mới</h1>
        <div />
      </header>
      {error && <p style={{ color: 'var(--danger)', marginBottom: 12 }}>{error}</p>}
      {friends.length === 0 ? (
        <p className="empty-state">Bạn chưa có bạn bè nào. Hãy thêm bạn trước.</p>
      ) : (
        <ul className="chat-list__items" ref={listRef}>
          {friends.map((f) => {
            const name = f.fullName || `${f.firstName || ''} ${f.lastName || ''}`.trim();
            return (
              <li key={f.friendId}>
                <button
                  className="conv-tile"
                  onClick={() => pick(f.friendId)}
                  disabled={busyId === f.friendId}
                >
                  <Avatar src={f.avatar} name={name || f.friendId} size={52} />
                  <div className="conv-tile__body">
                    <div className="conv-tile__row1">
                      <span className="conv-tile__name">{name || f.friendId}</span>
                    </div>
                  </div>
                </button>
              </li>
            );
          })}
        </ul>
      )}
    </div>
  );
}
