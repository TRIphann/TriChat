import { useState, useRef } from 'react';
import { useChatStore } from '../../store/chatStore';
import { pickFile, readAsDataUrl } from '../../lib/format';
import './chatComposer.css';

export default function ChatComposer({ onSend, disabled }) {
  const [text, setText] = useState('');
  const [recording, setRecording] = useState(false);
  const sendTyping = useChatStore((s) => s.sendTyping);
  const inputRef = useRef(null);
  const recorderRef = useRef(null);

  function send() {
    if (!text.trim() || disabled) return;
    onSend({ type: 'text', content: text.trim() });
    setText('');
    sendTyping?.(useChatStore.getState().activeConversation?.id, false);
  }

  async function sendImage() {
    const file = await pickFile('image/*');
    if (!file) return;
    const preview = await readAsDataUrl(file);
    onSend({ type: 'image', content: 'Hình ảnh', mediaBlob: file, mediaUrl: preview, fileName: file.name, fileSize: file.size });
  }

  async function sendFile() {
    const file = await pickFile('*/*');
    if (!file) return;
    onSend({ type: 'file', content: file.name, mediaBlob: file, fileName: file.name, fileSize: file.size });
  }

  async function sendLocation() {
    if (!navigator.geolocation) return;
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        onSend({
          type: 'location',
          content: 'Vị trí',
          latitude: pos.coords.latitude,
          longitude: pos.coords.longitude,
        });
      },
      () => alert('Không lấy được vị trí'),
    );
  }

  async function toggleRecord() {
    if (recording) {
      const { blob, duration } = await recorderRef.current.stop();
      setRecording(false);
      onSend({
        type: 'audio',
        content: 'Tin nhắn thoại',
        mediaBlob: blob,
        fileName: `rec-${Date.now()}.webm`,
        fileSize: blob.size,
        duration,
      });
    } else {
      try {
        const { recordAudio } = await import('../../lib/mediaRecorder');
        recorderRef.current = await recordAudio();
        setRecording(true);
      } catch (e) {
        alert('Không thể truy cập microphone');
      }
    }
  }

  return (
    <div className="composer">
      <button className="composer__icon" onClick={sendImage} aria-label="Gửi ảnh" title="Gửi ảnh">Ảnh</button>
      <button className="composer__icon" onClick={sendFile} aria-label="Gửi file" title="Gửi file">File</button>
      <button className="composer__icon" onClick={sendLocation} aria-label="Vị trí" title="Vị trí">Vị trí</button>
      <input
        ref={inputRef}
        className="composer__input"
        placeholder={recording ? 'Đang ghi âm...' : 'Nhập tin nhắn...'}
        value={text}
        onChange={(e) => {
          setText(e.target.value);
          const id = useChatStore.getState().activeConversation?.id;
          if (id) sendTyping?.(id, e.target.value.length > 0);
        }}
        onKeyDown={(e) => e.key === 'Enter' && !e.shiftKey && send()}
        disabled={disabled}
      />
      {text.trim() ? (
        <button className="composer__send" onClick={send} aria-label="Gửi">→</button>
      ) : (
        <button className={`composer__mic ${recording ? 'is-recording' : ''}`} onClick={toggleRecord} aria-label={recording ? 'Dừng ghi âm' : 'Ghi âm'} title={recording ? 'Dừng ghi âm' : 'Ghi âm'}>
          {recording ? 'Dừng' : 'Mic'}
        </button>
      )}
    </div>
  );
}
