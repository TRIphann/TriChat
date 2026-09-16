import { useCallback } from 'react';
import { fxBurst, ripple } from '../lib/anime';

export function useFx() {
  const burst = useCallback((el, opts) => {
    fxBurst(el, opts);
  }, []);
  const press = useCallback((el, opts) => {
    ripple(el, opts);
  }, []);
  return { burst, press };
}
