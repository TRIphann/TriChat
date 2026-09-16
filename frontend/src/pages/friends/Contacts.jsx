import { useEffect, useState } from 'react';
import { useFriendStore } from '../../store/friendStore';
import { authService } from '../../services/auth.service';
import { Avatar } from '../../components/ui';

export default function Contacts() {
  const friends = useFriendStore((s) => s.friends);
  const loadAll = useFriendStore((s) => s.loadAll);
  const [birthdays, setBirthdays] = useState([]);

  useEffect(() => {
    loadAll();
  }, [loadAll]);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        const res = await Promise.all(
          friends.slice(0, 10).map((f) =>
            authService.getById(f.friendId).catch(() => null),
          ),
        );
        if (!cancelled) setBirthdays(res.filter(Boolean));
      } catch (e) {
        // ignore
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [friends]);

  return (
    <div>
      <h1 className="text-serif" style={{ fontSize: 32, margin: '0 0 24px' }}>Danh bạ</h1>

      <h2 style={{ fontSize: 18, marginBottom: 12 }}>Sinh nhật bạn bè</h2>
      <ul style={{ listStyle: 'none', padding: 0, marginBottom: 32, display: 'flex', flexDirection: 'column', gap: 8 }}>
        {birthdays.map((u) => (
          <li key={u.id} className="conv-tile">
            <Avatar src={u.avatar} name={u.fullName} size={48} />
            <div className="conv-tile__body">
              <div className="conv-tile__name">{u.fullName}</div>
              <div className="conv-tile__preview">🎂 {u.dateOfBirth || u.dob || '—'}</div>
            </div>
          </li>
        ))}
        {birthdays.length === 0 && <p style={{ color: 'var(--text-3)' }}>Không có dữ liệu.</p>}
      </ul>

      <h2 style={{ fontSize: 18, marginBottom: 12 }}>Tất cả bạn bè ({friends.length})</h2>
      <ul style={{ listStyle: 'none', padding: 0, display: 'flex', flexDirection: 'column', gap: 8 }}>
        {friends.map((f) => (
          <li key={f.friendId} className="conv-tile">
            <Avatar src={f.avatar} name={f.fullName} size={48} />
            <div className="conv-tile__body">
              <div className="conv-tile__name">{f.fullName}</div>
            </div>
          </li>
        ))}
      </ul>
    </div>
  );
}
