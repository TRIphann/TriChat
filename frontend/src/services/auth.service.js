import { http } from '../lib/httpClient';
import { auth } from '../lib/firebase';

export const authService = {
  // Firebase Auth — đăng nhập email/password
  async signIn(email, password) {
    const cred = await auth.signInWithEmailAndPassword(email, password);
    return cred.user;
  },

  async signOut() {
    await auth.signOut();
  },

  async register(req) {
    const cred = await auth.createUserWithEmailAndPassword(req.email, req.password);
    const uid = cred.user.uid;
    // Backend bind snake_case cho /api/user (create user)
    await http.post('/api/user', {
      id: uid,
      first_name: req.firstName,
      last_name: req.lastName,
      email: req.email,
      password: req.password,
      date_of_birth: req.dateOfBirth,
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

  async updateMe(payload) {
    // UpdateUserRequest DTO — PascalCase
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
