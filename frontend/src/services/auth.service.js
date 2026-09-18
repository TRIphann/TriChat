import { http } from '../lib/httpClient';
import { auth } from '../lib/firebase';
import {
  createUserWithEmailAndPassword,
  signInWithEmailAndPassword,
} from 'firebase/auth';

// Map mã lỗi Firebase Auth → thông điệp hữu ích kèm hướng dẫn.
// Firebase throw error với code có prefix "auth/" (vd "auth/email-already-in-use").
// Hàm mapAuthError nhận code đã được chuẩn hoá (không prefix).
export function mapAuthError(code) {
  if (!code) return '';
  // Tách phần sau dấu "/" cuối cùng để chuẩn hoá ("auth/email-already-in-use" → "email-already-in-use").
  const normalized = String(code).split('/').pop();
  const map = {
    'email-already-in-use': 'Email này đã có tài khoản. Hãy đăng nhập hoặc dùng email khác.',
    'weak-password': 'Mật khẩu quá yếu. Hãy dùng ≥ 8 ký tự gồm chữ HOA, chữ thường và số.',
    'invalid-email': 'Email chưa đúng định dạng. Ví dụ hợp lệ: ten@example.com',
    'user-not-found': 'Email chưa đăng ký. Hãy kiểm tra lại hoặc tạo tài khoản mới.',
    'wrong-password': 'Sai mật khẩu. Mật khẩu phân biệt HOA/thường — hãy tắt Caps Lock và thử lại.',
    'invalid-credential': 'Email hoặc mật khẩu không đúng. Vui lòng kiểm tra lại.',
    'invalid-login-credentials': 'Email hoặc mật khẩu không đúng. Vui lòng kiểm tra lại.',
    'user-disabled': 'Tài khoản đã bị vô hiệu hóa. Liên hệ quản trị viên để được hỗ trợ.',
    'too-many-requests': 'Quá nhiều lần thử sai. Vui lòng đợi vài phút rồi thử lại.',
    'network-request-failed': 'Không kết nối được máy chủ. Kiểm tra mạng và thử lại.',
    'operation-not-allowed': 'Đăng nhập email/mật khẩu chưa được bật. Liên hệ quản trị viên.',
  };
  return map[normalized] || '';
}

/**
 * Helper lấy message thân thiện từ một error bất kỳ:
 * - Nếu có code Firebase đã biết → trả về message Tiếng Việt từ map.
 * - Nếu là Error thường → trả về e.message.
 * - Nếu không hiểu được → fallback.
 */
export function friendlyAuthError(e, fallback = 'Đã có lỗi xảy ra. Vui lòng thử lại.') {
  const friendly = mapAuthError(e?.code);
  if (friendly) return friendly;
  return e?.message || fallback;
}

export const authService = {
  // Firebase Auth — đăng nhập email/password (modular SDK)
  async signIn(email, password) {
    const cred = await signInWithEmailAndPassword(auth, email, password);
    return cred.user;
  },

  async signOut() {
    await auth.signOut();
  },

  /**
   * Đăng ký tài khoản mới.
   * Bước 1: tạo user trên Firebase Auth (modular SDK).
   * Bước 2: gọi backend POST /api/user để tạo profile Firestore.
   * Backend dùng SnakeCaseLower JSON → gửi snake_case.
   * Lưu ý: CreateUserRequestValidator yêu cầu DateOfBirth bắt buộc (yyyy-MM-dd, ngày trong quá khứ).
   */
  async register(req) {
    const cred = await createUserWithEmailAndPassword(auth, req.email, req.password);
    const uid = cred.user.uid;

    // DateOfBirth là bắt buộc theo validator — backend nhận string yyyy-MM-dd.
    const dob = req.dateOfBirth || req.date_of_birth;
    if (!dob) {
      // Rollback: xoá user Firebase để tránh tài khoản "ma" không có profile.
      await cred.user.delete().catch(() => {});
      throw new Error('Ngày sinh là bắt buộc để tạo tài khoản.');
    }

    await http.post('/api/user', {
      id: uid,
      first_name: req.firstName,
      last_name: req.lastName,
      email: req.email,
      password: req.password,
      date_of_birth: dob,
      bio: req.bio || '',
    });
    return uid;
  },

  // OTP — public endpoints
  async sendOtp(email) {
    const res = await http.post('/api/otp/generate', { email });
    return res;
  },

  async verifyOtp(email, otp, cachedOtp) {
    return http.post('/api/otp/verify', {
      email,
      otp,
      ...(cachedOtp ? { cached_otp: cachedOtp } : {}),
    });
  },

  // User profile endpoints
  async getMe() {
    return http.get('/api/user/me');
  },

  async getById(id) {
    return http.get(`/api/user/${id}`);
  },

  async search(q) {
    return http.get('/api/user/search', { q });
  },

  /**
   * UpdateUserRequest: tất cả field optional, snake_case theo SnakeCaseLower JSON config.
   * Truyền đúng key để ASP.NET Core bind được.
   */
  async updateMe(payload) {
    return http.put('/api/user/me', payload);
  },

  async updateAvatar(file) {
    const fd = new FormData();
    fd.append('File', file);
    return http.upload('/api/user/avatar', fd);
  },

  async deleteMe(id) {
    return http.delete(`/api/user/${id}`);
  },
};

let lastOtpCache = null;
let lastOtpCacheTime = null;
const OTP_TTL_MIN = 5;

export function cacheFallbackOtp(otp) {
  lastOtpCache = otp;
  lastOtpCacheTime = new Date();
}

export function getCachedOtp() {
  if (!lastOtpCache || !lastOtpCacheTime) return null;
  const elapsed = (Date.now() - lastOtpCacheTime.getTime()) / 60000;
  if (elapsed >= OTP_TTL_MIN) {
    lastOtpCache = null;
    lastOtpCacheTime = null;
    return null;
  }
  return lastOtpCache;
}

export function clearCachedOtp() {
  lastOtpCache = null;
  lastOtpCacheTime = null;
}
