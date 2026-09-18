import { useEffect, useRef, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  useFriendStore,
  REQUESTS_PAGE_SIZE,
} from '../../store/friendStore';
import { Avatar } from '../../components/ui';
import { staggerCards } from '../../lib/anime';
import { formatRelativeShort } from '../../lib/format';

export default function FriendRequests() {
  const nav = useNavigate();
  const received         = useFriendStore((s) => s.pendingReceived);
  const receivedTotal    = useFriendStore((s) => s.pendingReceivedTotal);
  const receivedHasMore  = useFriendStore((s) => s.pendingReceivedHasMore);
  const receivedState    = useFriendStore((s) => s.pendingReceivedState);
  const sent             = useFriendStore((s) => s.pendingSent);
  const sentTotal        = useFriendStore((s) => s.pendingSentTotal);
  const sentHasMore      = useFriendStore((s) => s.pendingSentHasMore);
  const sentState        = useFriendStore((s) => s.pendingSentState);
  const loadReceivedPage = useFriendStore((s) => s.loadPendingReceivedPage);
  const loadSentPage     = useFriendStore((s) => s.loadPendingSentPage);
  const respond          = useFriendStore((s) => s.respond);
  const cancel           = useFriendStore((s) => s.cancelRequest);
  const [tab, setTab] = useState('received');
  const listRef = useRef(null);

  useEffect(() => {
    loadReceivedPage({ reset: true });
    loadSentPage({ reset: true });
  }, [loadReceivedPage, loadSentPage]);

  useEffect(() => {
    if (listRef.current) {
      staggerCards(listRef.current.querySelectorAll('.req-row'), { gap: 60, dur: 540 });
    }
  }, [received.length, sent.length, tab]);

  const [receivedShow, setReceivedShow] = useState(REQUESTS_PAGE_SIZE);
  const [sentShow, setSentShow]         = useState(REQUESTS_PAGE_SIZE);

  // Reset khi total đổi
  useEffect(() => { setReceivedShow(REQUESTS_PAGE_SIZE); }, [receivedTotal]);
  useEffect(() => { setSentShow(REQUESTS_PAGE_SIZE); },     [sentTotal]);

  const visibleReceived = received.slice(0, receivedShow);
  const visibleSent     = sent.slice(0, sentShow);

  function handleShowMoreReceived() {
    if (receivedHasMore || visibleReceived.length < receivedTotal) {
      loadReceivedPage({ reset: false });
    }
    setReceivedShow((n) => n + REQUESTS_PAGE_SIZE);
  }

  function handleShowMoreSent() {
    if (sentHasMore || visibleSent.length < sentTotal) {
      loadSentPage({ reset: false });
    }
    setSentShow((n) => n + REQUESTS_PAGE_SIZE);
  }

  return (
    <div>
      <button className="chat-list__new" onClick={() => nav(-1)} style={{ marginBottom: 16 }}>← Quay lại</button>
      <h1 className="text-serif" style={{ fontSize: 32, margin: '0 0 24px' }}>Lời mời kết bạn</h1>

      <div className="friends-page__tabs">
        <button className={`friends-page__tab ${tab === 'received' ? 'is-active' : ''}`} onClick={() => setTab('received')}>
          Đã nhận ({receivedTotal})
        </button>
        <button className={`friends-page__tab ${tab === 'sent' ? 'is-active' : ''}`} onClick={() => setTab('sent')}>
          Đã gửi ({sentTotal})
        </button>
      </div>

      {tab === 'received' && (
        receivedTotal === 0 && receivedState !== 'loading' ? (
          <div className="empty-state">
            <div className="empty-state__icon">📩</div>
            <p>Không có lời mời nào.</p>
          </div>
        ) : (
          <>
            <ul style={{ listStyle: 'none', padding: 0, display: 'flex', flexDirection: 'column', gap: 8 }} ref={listRef}>
              {visibleReceived.map((r) => (
                <li key={r.id} className="req-row conv-tile">
                  <Avatar src={r.senderAvatar} name={r.senderName || r.senderId} size={48} />
                  <div className="conv-tile__body">
                    <div className="conv-tile__name">{r.senderName || r.senderId}</div>
                    <div className="conv-tile__preview">{formatRelativeShort(r.createdAt)}</div>
                  </div>
                  <div style={{ display: 'flex', gap: 8 }}>
                    <button className="btn btn--primary btn--sm" onClick={() => respond(r.id, true)}>Chấp nhận</button>
                    <button className="btn btn--ghost btn--sm" onClick={() => respond(r.id, false)}>Từ chối</button>
                  </div>
                </li>
              ))}
            </ul>
            {(receivedHasMore || visibleReceived.length < receivedTotal) && (
              <button
                type="button"
                className="friends-page__more"
                onClick={handleShowMoreReceived}
                disabled={receivedState === 'loading'}
              >
                {receivedState === 'loading' ? 'Đang tải…' : 'Xem thêm'}
              </button>
            )}
            {!receivedHasMore && receivedTotal > 0 && (
              <p className="friends-page__end">— Đã hết danh sách —</p>
            )}
          </>
        )
      )}

      {tab === 'sent' && (
        sentTotal === 0 && sentState !== 'loading' ? (
          <div className="empty-state">
            <div className="empty-state__icon">📤</div>
            <p>Chưa gửi lời mời nào.</p>
          </div>
        ) : (
          <>
            <ul style={{ listStyle: 'none', padding: 0, display: 'flex', flexDirection: 'column', gap: 8 }}>
              {visibleSent.map((r) => (
                <li key={r.id} className="req-row conv-tile">
                  <Avatar src={r.addresseeAvatar} name={r.addresseeName || r.addresseeId} size={48} />
                  <div className="conv-tile__body">
                    <div className="conv-tile__name">{r.addresseeName || r.addresseeId}</div>
                    <div className="conv-tile__preview">{formatRelativeShort(r.createdAt)}</div>
                  </div>
                  <div style={{ display: 'flex', gap: 8 }}>
                    <button className="btn btn--ghost btn--sm" onClick={() => cancel(r.id)}>Thu hồi</button>
                  </div>
                </li>
              ))}
            </ul>
            {(sentHasMore || visibleSent.length < sentTotal) && (
              <button
                type="button"
                className="friends-page__more"
                onClick={handleShowMoreSent}
                disabled={sentState === 'loading'}
              >
                {sentState === 'loading' ? 'Đang tải…' : 'Xem thêm'}
              </button>
            )}
            {!sentHasMore && sentTotal > 0 && (
              <p className="friends-page__end">— Đã hết danh sách —</p>
            )}
          </>
        )
      )}
    </div>
  );
}
