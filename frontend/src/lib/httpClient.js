import { API_BASE_URL } from './apiConfig';
import { auth } from './firebase';

let refreshing = null;

async function refreshToken() {
  const u = auth.currentUser;
  if (!u) return null;
  if (!refreshing) refreshing = u.getIdToken(true);
  try {
    return await refreshing;
  } finally {
    refreshing = null;
  }
}

async function authHeader() {
  const u = auth.currentUser;
  if (!u) return {};
  const tok = await u.getIdToken(false);
  return { Authorization: `Bearer ${tok}` };
}

function extractMessage(data, status) {
  if (data && typeof data === 'object') {
    return data.message || data.Message || data.error || `HTTP ${status}`;
  }
  return typeof data === 'string' && data ? data : `HTTP ${status}`;
}

export async function api(
  path,
  { method = 'GET', body, headers = {}, isForm = false, retried = false } = {},
) {
  const finalHeaders = { ...(await authHeader()), ...headers };
  if (!isForm && body && !(body instanceof FormData)) {
    finalHeaders['Content-Type'] = 'application/json';
  }

  let res;
  try {
    res = await fetch(`${API_BASE_URL}${path}`, {
      method,
      headers: finalHeaders,
      body: isForm ? body : body ? JSON.stringify(body) : undefined,
    });
  } catch (e) {
    const err = new Error('network_error');
    err.cause = e;
    throw err;
  }

  if (res.status === 401 && !retried) {
    const tok = await refreshToken();
    if (tok) {
      finalHeaders.Authorization = `Bearer ${tok}`;
      return api(path, { method, body, headers: finalHeaders, isForm, retried: true });
    }
  }

  const text = await res.text();
  let data;
  try {
    data = text ? JSON.parse(text) : null;
  } catch {
    data = text;
  }

  if (!res.ok) {
    const err = new Error(extractMessage(data, res.status));
    err.status = res.status;
    err.payload = data;
    throw err;
  }

  // Backend trả về { success, code, message, result }
  if (data && typeof data === 'object' && 'result' in data) return data.result;
  return data;
}

export const http = {
  get: (p, q) => api(p + (q ? `?${new URLSearchParams(q)}` : '')),
  post: (p, b, h) => api(p, { method: 'POST', body: b, headers: h }),
  put: (p, b, h) => api(p, { method: 'PUT', body: b, headers: h }),
  patch: (p, b, h) => api(p, { method: 'PATCH', body: b, headers: h }),
  delete: (p, h) => api(p, { method: 'DELETE', headers: h }),
  upload: (p, fd) => api(p, { method: 'POST', body: fd, isForm: true }),
};
