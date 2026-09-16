// Anime.js v4 — preset animations cho TriChat
import { animate, stagger, utils } from 'animejs';

const prefersReducedMotion = () =>
  typeof window !== 'undefined' &&
  window.matchMedia('(prefers-reduced-motion: reduce)').matches;

function skipIfReduced(animation) {
  if (prefersReducedMotion()) {
    if (typeof animation === 'function') animation({});
    return false;
  }
  return true;
}

/** Card stagger reveal — cho Newsfeed, FriendList, ConversationList */
export function staggerCards(els, { gap = 70, dur = 640, y = 28 } = {}) {
  if (!els || (els.length ?? 0) === 0) return;
  const list = Array.from(els);
  if (!skipIfReduced()) return;
  utils.set(list, { opacity: 0, translateY: y });
  animate(list, {
    opacity: [0, 1],
    translateY: [y, 0],
    delay: stagger(gap),
    duration: dur,
    ease: 'out(3)',
  });
}

/** Hand-arc FAB menu — khi mở SpeedDial / NewChat */
export function handArc(els, { radius = 72, count } = {}) {
  if (!els || (els.length ?? 0) === 0) return;
  const list = Array.from(els);
  const n = count || list.length;
  if (!skipIfReduced()) return;
  utils.set(list, { translateX: 0, translateY: 0, scale: 0.6, opacity: 0 });
  animate(list, {
    translateX: (_, i) => Math.cos((Math.PI / (n + 1)) * (i + 1)) * radius,
    translateY: (_, i) => -Math.sin((Math.PI / (n + 1)) * (i + 1)) * radius,
    scale: [0.6, 1],
    opacity: [0, 1],
    delay: stagger(40),
    duration: 520,
    ease: 'out(4)',
  });
}

export function handArcClose(els, cb) {
  if (!els || (els.length ?? 0) === 0) return cb?.();
  const list = Array.from(els);
  if (!skipIfReduced()) return cb?.();
  animate(list, {
    translateX: 0,
    translateY: 0,
    scale: [1, 0.6],
    opacity: [1, 0],
    delay: stagger(20),
    duration: 320,
    ease: 'in(3)',
    onComplete: () => cb?.(),
  });
}

/** FX burst — khi gửi message / like / react */
export function fxBurst(targetEl, { color = 'rgba(217,119,6,0.85)' } = {}) {
  if (!targetEl || prefersReducedMotion()) return;
  const rect = targetEl.getBoundingClientRect();
  const cx = rect.left + rect.width / 2;
  const cy = rect.top + rect.height / 2;
  const burst = document.createElement('div');
  burst.className = 'fx-burst';
  burst.style.cssText = `left:${cx}px;top:${cy}px;background:radial-gradient(circle at 30% 30%, ${color}, transparent 70%);`;
  document.body.appendChild(burst);
  animate(burst, {
    scale: [0, 1.6, 0],
    opacity: [0, 1, 0],
    duration: 720,
    ease: 'out(3)',
    onComplete: () => burst.remove(),
  });
}

/** Ripple — avatar click, button press */
export function ripple(targetEl, { color = 'rgba(217,119,6,0.35)' } = {}) {
  if (!targetEl || prefersReducedMotion()) return;
  const position = getComputedStyle(targetEl).position;
  if (position === 'static') targetEl.style.position = 'relative';
  targetEl.style.overflow = 'hidden';
  const r = document.createElement('span');
  const rect = targetEl.getBoundingClientRect();
  const size = Math.max(rect.width, rect.height);
  r.style.cssText = `position:absolute;border-radius:999px;pointer-events:none;background:${color};width:${size}px;height:${size}px;left:${rect.width / 2 - size / 2}px;top:${rect.height / 2 - size / 2}px;`;
  targetEl.appendChild(r);
  animate(r, {
    scale: [0, 2.4],
    opacity: [0.6, 0],
    duration: 700,
    ease: 'out(3)',
    onComplete: () => r.remove(),
  });
}

/** Page transition */
export function pageIn(el) {
  if (!el) return;
  if (!skipIfReduced()) {
    el.style.opacity = '1';
    el.style.transform = 'none';
    return;
  }
  animate(el, {
    opacity: [0, 1],
    translateY: [12, 0],
    duration: 480,
    ease: 'out(3)',
  });
}

/** Modal/Sheet entrance */
export function sheetIn(el) {
  if (!el) return;
  if (!skipIfReduced()) return;
  animate(el, {
    translateY: [24, 0],
    opacity: [0, 1],
    duration: 420,
    ease: 'out(4)',
  });
}

/** Like bounce — scale + spring overshoot */
export function likeBounce(el) {
  if (!el) return;
  if (!skipIfReduced()) return;
  animate(el, {
    scale: [
      { to: 1.4, duration: 220, ease: 'out(3)' },
      { to: 1, duration: 380, ease: 'out(5)' },
    ],
  });
}
