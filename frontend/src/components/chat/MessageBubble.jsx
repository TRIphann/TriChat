import { fxBurst } from '../../lib/anime';
import { formatTime } from '../../lib/format';
import './messageBubble.css';

const REACTIONS = ['❤️', '👍', '😂', '😮', '😢', '😡'];

export default function MessageBubble({ message, onReply, onReact, onDelete, onRetry }) {
  const isMine = message.isMine;
  const onDouble = (e) => {
    if (message.type === 'text' || !message.type) {
      fxBurst(e.currentTarget);
      onReact?.('❤️');
    }
  };

  return (
    <div className={`bubble ${isMine ? 'bubble--mine' : 'bubble--theirs'}`}>
      {message.replyToMessageId && (
        <div className="bubble__reply">
          <span className="bubble__reply-name">{message.replyToSenderName || '...'}</span>
          <span className="bubble__reply-text">{message.replyToContent?.slice(0, 80)}</span>
        </div>
      )}
      <div
        className={`bubble__surface ${message.type || 'text'}`}
        onDoubleClick={onDouble}
        onClick={() => onReply?.(message)}
      >
        {message.isDeleted ? (
          <span className="bubble__deleted">Tin nhắn đã bị thu hồi</span>
        ) : (
          <BubbleContent message={message} />
        )}
      </div>
      <div className="bubble__meta">
        <time>{formatTime(message.createdAt)}</time>
        {message.isEdited && <span className="bubble__edited">· đã sửa</span>}
        {isMine && message.status === 'sending' && <span className="bubble__sending">đang gửi</span>}
        {isMine && message.status === 'failed' && (
          <button className="bubble__retry" onClick={() => onRetry?.(message)}>↻ Thử lại</button>
        )}
        {isMine && message.status === 'sent' && <span>✓</span>}
        {isMine && message.status === 'delivered' && <span className="bubble__delivered">✓✓</span>}
        {isMine && message.status === 'read' && <span className="bubble__read">✓✓</span>}
      </div>

      {message.reactions && Object.keys(message.reactions).length > 0 && (
        <div className="bubble__reactions">
          {Object.entries(message.reactions).map(([emoji, list]) => (
            <span key={emoji} className="bubble__reaction">
              {emoji} {Array.isArray(list) ? list.length : 1}
            </span>
          ))}
        </div>
      )}

      {onReply && !message.isDeleted && (
        <div className="bubble__actions">
          {REACTIONS.map((e) => (
            <button key={e} className="bubble__action" onClick={() => onReact?.(e)} aria-label={`React ${e}`}>{e}</button>
          ))}
          {onReply && (
            <button className="bubble__action" onClick={() => onReply(message)} aria-label="Reply" title="Trả lời">Trả lời</button>
          )}
          {isMine && onDelete && (
            <button className="bubble__action" onClick={() => onDelete(message)} aria-label="Delete" title="Thu hồi">Xóa</button>
          )}
        </div>
      )}
    </div>
  );
}

function BubbleContent({ message }) {
  switch (message.type) {
    case 'image':
      return (
        <img
          src={message.mediaUrl || message.localPreview}
          alt="image"
          className="bubble__image"
          loading="lazy"
        />
      );
    case 'video':
      return (
        <video
          src={message.mediaUrl}
          controls
          className="bubble__video"
        />
      );
    case 'audio':
      return (
        <audio src={message.mediaUrl || message.localPreview} controls className="bubble__audio" />
      );
    case 'location':
      return (
        <div className="bubble__location">
          Vị trí: {message.address || `${message.latitude?.toFixed?.(4)}, ${message.longitude?.toFixed?.(4)}`}
        </div>
      );
    case 'call':
      return <div className="bubble__call">{message.content}</div>;
    case 'file':
      return (
        <a href={message.mediaUrl} target="_blank" rel="noreferrer" className="bubble__file">
          File: {message.fileName || 'Tệp đính kèm'}
        </a>
      );
    default:
      return <p className="bubble__text">{message.content}</p>;
  }
}
