import { useEffect, useRef, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useFriendStore } from '../../store/friendStore';
import { Avatar } from '../../components/ui';
import { staggerCards } from '../../lib/anime';
import { formatRelativeShort } from '../../lib/format';

export default function FriendRequests() {
  const nav = useNavigate();
  const received = useFriendStore((s) => s.pendingReceived);
  const sent = useFriendStore((s) => s.pendingSent);
  const loadAll = useFriendStore((s) => s.loadAll);
  const respond = useFriendStore((s) => s.respond);
  const cancel = useFriendStore((s) => s.cancelRequest);
  const [tab, setTab] = useState('received');
  const listRef = useRef(null);

  useEffect(() => {
    loadAll();
  }, [loadAll]);

  useEffect(() => {
    if (listRef.current) {
      staggerCards(listRef.current.querySelectorAll('.req-row'), { gap: 60, dur: 540 });
    }
  }, [received.length, sent.length, tab]);

  const list = tab === 'received' ? received : sent;

  return (
    <div>
      <button className="chat-list__new" onClick={() => nav(-1)} style={{ marginBottom: 16 }}>← Quay lại</button>
      <h1 className="text-serif" style={{ fontSize: 32, margin: '0 0 24px' }}>Lời mời kết bạn</h1>

      <div className="friends-page__tabs">
        <button className={`friends-page__tab ${tab === 'received' ? 'is-active' : ''}`} onClick={() => setTab('received')}>
          Đã nhận ({received.length})
        </button>
        <button className={`friends-page__tab ${tab === 'sent' ? 'is-active' : ''}`} onClick={() => setTab('sent')}>
          Đã gửi ({sent.length})
        </button>
      </div>

      {list.length === 0 ? (
        <div className="empty-state">
          <div className="empty-state__icon">📩</div>
          <p>Không có lời mời nào.</p>
        </div>
      ) : (
        <ul style={{ listStyle: 'none', padding: 0, display: 'flex', flexDirection: 'column', gap: 8 }} ref={listRef}>
          {list.map((r) => (
            <li key={r.id} className="req-row conv-tile">
              <Avatar src={r.senderAvatar || r.addresseeAvatar} name={r.senderName || r.addresseeName} size={48} />
              <div className="conv-tile__body">
                <div className="conv-tile__name">{r.senderName || r.addresseeName}</div>
                <div className="conv-tile__preview">{formatRelativeShort(r.createdAt)}</div>
              </div>
              <div style={{ display: 'flex', gap: 8 }}>
                {tab === 'received' ? (
                  <>
                    <button className="btn btn--primary btn--sm" onClick={() => respond(r.id, true)}>Chấp nhận</button>
                    <button className="btn btn--ghost btn--sm" onClick={() => respond(r.id, false)}>Từ chối</button>
                  </>
                ) : (
                  <button className="btn btn--ghost btn--sm" onClick={() => cancel(r.id)}>Hủy</button>
                )}
              </div>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
