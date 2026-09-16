import { useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useCallStore } from '../../store/callStore';
import { Avatar } from '../../components/ui';
import { useChatStore } from '../../store/chatStore';
import './callRoom.css';

export default function CallRoom() {
  const nav = useNavigate();
  const call = useCallStore((s) => s.currentCall);
  const status = useCallStore((s) => s.status);
  const seconds = useCallStore((s) => s.seconds);
  const isMuted = useCallStore((s) => s.isMuted);
  const isVideoOff = useCallStore((s) => s.isVideoOff);
  const accept = useCallStore((s) => s.accept);
  const reject = useCallStore((s) => s.reject);
  const endCall = useCallStore((s) => s.endCall);
  const toggleMute = useCallStore((s) => s.toggleMute);
  const toggleVideo = useCallStore((s) => s.toggleVideo);

  // Listen for incoming call events
  useEffect(() => {
    const onIncoming = (e) => {
      const { conversation_id, caller_id, caller_name, caller_avatar, call_type } = e.detail || {};
      useCallStore.getState().receiveIncoming({
        conversationId: conversation_id,
        callerId: caller_id,
        remoteName: caller_name,
        remoteAvatar: caller_avatar,
        isVideo: call_type === 'video',
      });
    };
    window.addEventListener('trichat:incoming-call', onIncoming);
    return () => window.removeEventListener('trichat:incoming-call', onIncoming);
  }, []);

  if (!call) {
    return (
      <div className="call-room">
        <p style={{ textAlign: 'center', color: 'var(--text-3)', padding: 40 }}>Không có cuộc gọi nào đang diễn ra.</p>
        <button className="btn btn--ghost" onClick={() => nav(-1)}>← Quay lại</button>
      </div>
    );
  }

  return (
    <div className="call-room">
      <div className="call-room__bg" />
      <div className="call-room__avatar">
        <Avatar src={call.remoteAvatar} name={call.remoteName} size={160} />
      </div>
      <h1 className="call-room__name">{call.remoteName}</h1>
      <p className="call-room__status">
        {status === 'dialing' && 'Đang gọi...'}
        {status === 'ringing' && 'Đang đổ chuông...'}
        {status === 'active' && formatSec(seconds)}
        {status === 'ended' && 'Đã kết thúc'}
        {status === 'rejected' && 'Đã từ chối'}
        {status === 'missed' && 'Cuộc gọi nhỡ'}
      </p>

      {status === 'ringing' && (
        <div className="call-room__actions">
          <button className="call-room__btn call-room__btn--accept" onClick={accept}>📞</button>
          <button className="call-room__btn call-room__btn--reject" onClick={() => reject()}>✕</button>
        </div>
      )}

      {(status === 'active' || status === 'dialing') && (
        <div className="call-room__actions">
          <button className={`call-room__btn ${isMuted ? 'is-active' : ''}`} onClick={toggleMute}>{isMuted ? '🔇' : '🎙'}</button>
          <button className={`call-room__btn ${isVideoOff ? 'is-active' : ''}`} onClick={toggleVideo}>{isVideoOff ? '📷' : '🎥'}</button>
          <button className="call-room__btn call-room__btn--reject" onClick={endCall}>✕</button>
        </div>
      )}
    </div>
  );
}

function formatSec(s) {
  const m = Math.floor(s / 60).toString().padStart(2, '0');
  const sec = (s % 60).toString().padStart(2, '0');
  return `${m}:${sec}`;
}
