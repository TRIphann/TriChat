import { useNavigate, useParams } from 'react-router-dom';
import { useChatStore } from '../../store/chatStore';
import { Avatar, Button } from '../../components/ui';

export default function GroupInfo() {
  const { id } = useParams();
  const conv = useChatStore((s) => s.conversations.find((c) => c.id === id));
  const nav = useNavigate();

  if (!conv) return <p>Không tìm thấy nhóm.</p>;
  return (
    <div style={{ padding: 24 }}>
      <button className="chat-list__new" onClick={() => nav(-1)} style={{ marginBottom: 16 }}>← Quay lại</button>
      <div style={{ textAlign: 'center', marginBottom: 32 }}>
        <Avatar src={conv.groupAvatarUrl} name={conv.groupName} size={120} ring />
        <h1 style={{ fontFamily: 'var(--font-serif)', fontSize: 28, marginTop: 16 }}>{conv.groupName}</h1>
        <p style={{ color: 'var(--text-2)' }}>{conv.participants?.length || 0} thành viên</p>
      </div>
      <section>
        <h2 style={{ fontSize: 18, marginBottom: 12 }}>Thành viên</h2>
        <ul style={{ listStyle: 'none', padding: 0 }}>
          {(conv.participants || []).map((p) => (
            <li key={p.userId || p.id} className="conv-tile">
              <Avatar src={p.avatar} name={p.fullName || p.userId} size={40} />
              <div className="conv-tile__body">
                <div className="conv-tile__name">{p.fullName || p.userId}</div>
              </div>
            </li>
          ))}
        </ul>
      </section>
      <Button variant="danger" style={{ marginTop: 32 }} fullWidth>Rời nhóm</Button>
    </div>
  );
}
