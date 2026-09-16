// Design tokens — High-end editorial palette.
// Đổi một dòng ở đây là đổi theme toàn app.

export const tokens = {
  brand: {
    amber: '#D97706',
    amberSoft: '#FEF3C7',
    amberDeep: '#92400E',
    ember: '#EA580C',
    emberSoft: '#FFEDD5',
    rose: '#E11D48',
    roseSoft: '#FFE4E6',
    plasma: '#7C3AED',
    plasmaSoft: '#EDE9FE',
    ink: '#0C0A09',
    bone: '#FAF8F5',
  },
  surface: {
    canvasLight: '#FAF8F5',
    cardLight: '#FFFFFF',
    elevatedLight: '#FFFCF9',
    surfaceLight: '#F4EFE8',
    canvasDark: '#0A0907',
    cardDark: '#161412',
    elevatedDark: '#1F1B17',
    surfaceDark: '#221D18',
  },
  text: {
    primaryLight: '#1C1917',
    secondaryLight: '#57534E',
    tertiaryLight: '#A8A29E',
    primaryDark: '#FAF8F5',
    secondaryDark: '#A8A29E',
    tertiaryDark: '#78716C',
  },
  border: {
    hairlineLight: 'rgba(28,25,23,0.08)',
    hairlineDark: 'rgba(250,248,245,0.08)',
    dividerLight: '#F0EBE3',
    dividerDark: '#221D18',
    strong: '#D6D3D1',
  },
  state: {
    success: '#16A34A',
    successSoft: '#DCFCE7',
    warning: '#D97706',
    warningSoft: '#FEF3C7',
    danger: '#DC2626',
    dangerSoft: '#FEE2E2',
    info: '#2563EB',
    infoSoft: '#DBEAFE',
  },
  chat: {
    bubbleMineLight: 'linear-gradient(135deg, #D97706 0%, #B45309 100%)',
    bubbleTheirsLight: '#F4EFE8',
    bubbleMineDark: 'linear-gradient(135deg, #292524 0%, #1C1917 100%)',
    bubbleTheirsDark: '#161412',
    textOnMine: '#FFFFFF',
  },
  radius: {
    xs: 6,
    sm: 10,
    md: 14,
    lg: 20,
    xl: 28,
    xxl: 36,
    pill: 999,
  },
  space: {
    1: 4,
    2: 8,
    3: 12,
    4: 16,
    5: 20,
    6: 24,
    7: 28,
    8: 32,
    10: 40,
    12: 48,
    14: 56,
    16: 64,
    20: 80,
    24: 96,
  },
  font: {
    sans: '"Inter", "InterVariable", -apple-system, BlinkMacSystemFont, "Segoe UI", system-ui, sans-serif',
    serif: '"Fraunces", "Source Serif Pro", Georgia, serif',
    mono: '"JetBrains Mono", ui-monospace, SFMono-Regular, monospace',
  },
  shadow: {
    soft: '0 1px 2px rgba(28,25,23,0.04), 0 8px 24px rgba(28,25,23,0.06)',
    medium: '0 4px 8px rgba(28,25,23,0.06), 0 16px 40px rgba(28,25,23,0.10)',
    glass: '0 1px 0 rgba(255,255,255,0.6) inset, 0 24px 60px rgba(28,25,23,0.18)',
    aurora: '0 24px 80px rgba(217,119,6,0.18), 0 8px 24px rgba(124,58,237,0.18)',
    inner: 'inset 0 1px 0 rgba(255,255,255,0.5), inset 0 -1px 0 rgba(0,0,0,0.05)',
    focus: '0 0 0 3px rgba(217,119,6,0.32)',
  },
  ease: {
    spring: 'cubic-bezier(0.22, 1, 0.36, 1)',
    overshoot: 'cubic-bezier(0.34, 1.56, 0.64, 1)',
    soft: 'cubic-bezier(0.4, 0, 0.2, 1)',
  },
};

export const avatarPalette = [
  '#D97706',
  '#16A34A',
  '#2563EB',
  '#DC2626',
  '#7C3AED',
  '#DB2777',
];

export function avatarColorFor(name = '') {
  if (!name) return avatarPalette[0];
  const code = name.toLowerCase().charCodeAt(0) || 0;
  return avatarPalette[code % avatarPalette.length];
}
