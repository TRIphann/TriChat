// Agora RTC cho web — voice + video call
import AgoraRTC from 'agora-rtc-sdk-ng';

export function makeAgoraClient() {
  return AgoraRTC.createClient({ mode: 'rtc', codec: 'vp8' });
}

export async function joinAgora(client, channel, token, uid) {
  const appId = import.meta.env.VITE_AGORA_APP_ID;
  await client.join(appId, channel, token || null, uid);
  return client;
}

export async function leaveAgora(client) {
  try {
    await client?.leave();
  } catch (e) {
    console.warn('[agora] leave failed:', e);
  }
}

/** Channel name deterministic: sorted [uid1, uid2].join('_') */
export function buildChannelName(a, b) {
  return [String(a), String(b)].sort().join('_');
}

/** Sinh Agora token từ AppCertificate — gọn cho demo. Production nên dùng server.
 *  Dự án TriChat cũng generate token client-side, giữ nguyên. */
export async function generateAgoraToken(channelName, uid) {
  const appId = import.meta.env.VITE_AGORA_APP_ID;
  const appCert = import.meta.env.VITE_AGORA_APP_CERTIFICATE;
  if (!appId || !appCert) return '';
  // Nếu không có agora-access-token package, fallback trả chuỗi rỗng để Agora cấp free token.
  try {
    const mod = await import('agora-access-token').catch(() => null);
    if (!mod) return '';
    const { RtcTokenBuilder, RtcRole } = mod;
    const expirationTimeInSeconds = 3600;
    const currentTimestamp = Math.floor(Date.now() / 1000);
    const privilegeExpiredTs = currentTimestamp + expirationTimeInSeconds;
    return RtcTokenBuilder.buildTokenWithUid(
      appId,
      appCert,
      channelName,
      uid,
      RtcRole.PUBLISHER,
      privilegeExpiredTs,
    );
  } catch {
    return '';
  }
}
