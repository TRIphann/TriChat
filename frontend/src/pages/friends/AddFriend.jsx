import { useEffect, useRef, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { friendService } from '../../services/friend.service';
import { useFriendStore } from '../../store/friendStore';
import { Avatar } from '../../components/ui';
import { Input } from '../../components/ui';
import { staggerCards } from '../../lib/anime';
import { useUiStore } from '../../store/uiStore';
import { useChatStore } from '../../store/chatStore';

export default function AddFriend() {
  const nav = useNavigate();
  const [query, setQuery] = useState('');
  const [results, setResults] = useState([]);
  const [loading, setLoading] = useState(false);
  const sendRequest = useFriendStore((s) => s.sendRequest);
  const showToast = useUiStore((s) => s.showToast);
  const startChat = useChatStore.getState().startChatWithUser;
  const listRef = useRef(null);

  useEffect(() => {
    if (!query || query.length < 2) {
      setResults([]);
      return;
    }
    const t = setTimeout(async () => {
      setLoading(true);
      try {
        const r = await friendService.searchUsers(query);
        setResults(r || []);
      } finally {
        setLoading(false);
      }
    }, 300);
    return () => clearTimeout(t);
  }, [query]);

  useEffect(() => {
    if (listRef.current && results.length) {
      staggerCards(listRef.current.querySelectorAll('.search-row'), { gap: 60, dur: 540 });
    }
  }, [results.length]);

  async function onAdd(user) {
    try {
      await sendRequest(user.id);
      showToast(`Đã gửi lời mời tới ${user.fullName}`, 'success');
    } catch (e) {
      showToast(e.message, 'error');
    }
  }

  return (
    <div>
      <button className="chat-list__new" onClick={() => nav(-1)} style={{ marginBottom: 16 }}>← Quay lại</button>
      <h1 className="text-serif" style={{ fontSize: 32, margin: '0 0 24px' }}>Thêm bạn</h1>
      <Input
        placeholder="Tìm kiếm theo tên hoặc email..."
        value={query}
        onChange={(e) => setQuery(e.target.value)}
        autoFocus
      />
      {loading && <p style={{ color: 'var(--text-3)', marginTop: 16 }}>Đang tìm...</p>}
      <ul ref={listRef} style={{ listStyle: 'none', padding: 0, marginTop: 16, display: 'flex', flexDirection: 'column', gap: 8 }}>
        {results.map((u) => (
          <li key={u.id} className="search-row conv-tile">
            <Avatar src={u.avatar} name={u.fullName} size={48} />
            <div className="conv-tile__body">
              <div className="conv-tile__name">{u.fullName}</div>
              <div className="conv-tile__preview">{u.email}</div>
            </div>
            <div style={{ display: 'flex', gap: 8 }}>
              <button
                className="btn btn--secondary btn--sm"
                onClick={async () => {
                  const conv = await startChat(u.id);
                  nav(`/chat-list/${conv.id}`);
                }}
              >💬 Nhắn</button>
              <button className="btn btn--primary btn--sm" onClick={() => onAdd(u)}>+ Kết bạn</button>
            </div>
          </li>
        ))}
      </ul>
    </div>
  );
}
