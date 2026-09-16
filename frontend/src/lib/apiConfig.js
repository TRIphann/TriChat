const fromEnv = (import.meta.env.VITE_API_BASE_URL || '').trim();
const hubFromEnv = (import.meta.env.VITE_HUB_BASE_URL || '').trim();

const fallback = typeof window !== 'undefined' ? window.location.origin : 'http://localhost:5244';

export const API_BASE_URL = fromEnv || fallback;
export const HUB_BASE_URL = hubFromEnv || API_BASE_URL;

export const IS_DEV = import.meta.env.DEV;
export const IS_PROD = import.meta.env.PROD;

export function buildHubUrl(path, query = {}) {
  const qs = new URLSearchParams(query).toString();
  return `${HUB_BASE_URL}${path}${qs ? `?${qs}` : ''}`;
}
