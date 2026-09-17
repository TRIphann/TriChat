// Voice recorder — sử dụng MediaRecorder API
export async function recordAudio() {
  if (!navigator.mediaDevices?.getUserMedia) {
    throw new Error('microphone_not_available');
  }
  const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
  const rec = new MediaRecorder(stream);
  const chunks = [];
  const startedAt = Date.now();
  rec.ondataavailable = (e) => {
    if (e.data && e.data.size > 0) chunks.push(e.data);
  };
  rec.start(100);

  return {
    startedAt,
    pause: () => rec.pause(),
    resume: () => rec.resume(),
    stop: () =>
      new Promise((resolve) => {
        rec.onstop = () => {
          stream.getTracks().forEach((t) => t.stop());
          const blob = new Blob(chunks, { type: rec.mimeType || 'audio/webm' });
          const duration = Math.round((Date.now() - startedAt) / 1000);
          resolve({ blob, duration, mimeType: rec.mimeType });
        };
        rec.stop();
      }),
  };
}

/** Format seconds → mm:ss */
export function formatDuration(seconds) {
  const m = Math.floor(seconds / 60).toString().padStart(2, '0');
  const s = (seconds % 60).toString().padStart(2, '0');
  return `${m}:${s}`;
}
