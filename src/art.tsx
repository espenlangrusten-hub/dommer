import React, { useState } from 'react';

type Palette = Record<string, string>;

interface SpriteProps {
  grid: string[];
  palette: Palette;
  x?: number;
  y?: number;
  s?: number;
}

function Px({ grid, palette, x = 0, y = 0, s = 1 }: SpriteProps) {
  const rects: React.ReactNode[] = [];
  grid.forEach((row, ry) => {
    for (let rx = 0; rx < row.length; rx++) {
      const fill = palette[row[rx]];
      if (!fill) continue;
      rects.push(
        <rect
          key={`${rx}-${ry}`}
          x={x + rx * s}
          y={y + ry * s}
          width={s + 0.06}
          height={s + 0.06}
          fill={fill}
        />
      );
    }
  });
  return <g>{rects}</g>;
}

const CRATE = [
  'bbbbbbbbbb',
  'bxwwwwwwxb',
  'bwxwwwwxwb',
  'bwwxwwxwwb',
  'bwwwxxwwwb',
  'bwwwxxwwwb',
  'bwwxwwxwwb',
  'bwxwwwwxwb',
  'bxwwwwwwxb',
  'bbbbbbbbbb',
];
const CRATE_PAL: Palette = { b: '#7a4a1f', w: '#c98a3d', x: '#a56a28' };

const CRATE_TOP = ['rgpyorgpyr'];
const CRATE_TOP_PAL: Palette = {
  r: '#e84a5f',
  g: '#4caf50',
  p: '#8e44ad',
  y: '#f1c40f',
  o: '#e67e22',
};
const CRATE_TOP_BLUE_PAL: Palette = {
  r: '#5b4ae8',
  g: '#7e6bf0',
  p: '#4a3ac0',
  y: '#8f7ff5',
  o: '#6a58e0',
};

const DRAGON = [
  '....ww..........',
  '...wwww.........',
  '..wwwwww........',
  '..wwwww.........',
  '...wwww....ddd..',
  'dd.bwwwb..ddddd.',
  'bbbbbbbbbbbdded.',
  '.bbbbbbbbbbdddd.',
  '..bbbbbbbbbb....',
  '...bbb..bbb.....',
  '...bb....bb.....',
];
const DRAGON_BLACK: Palette = { b: '#1d1d26', w: '#2c2c3a', d: '#15151d', e: '#a34bff' };
const DRAGON_PURPLE: Palette = { b: '#5a1f85', w: '#7a35ad', d: '#43135f', e: '#ff5cf0' };

const RACCOON = [
  'ee......ee',
  'eww....wwe',
  '.wwwwwwww.',
  '.wggwwggw.',
  '.wgkwwkgw.',
  '.wwwwwwww.',
  '.wwwkkwww.',
  '..wwwwww..',
  '..ww..ww..',
  '..gg..gg..',
];
const RACCOON_PAL: Palette = {
  e: '#3a3a44',
  w: '#f4f4f8',
  g: '#9aa0ad',
  k: '#23232b',
};

const UNICORN = [
  '..3..........',
  '..2m.........',
  '.1wwm........',
  '.wewwm.......',
  '.wwww........',
  '.wwwwwwwwww..',
  '.wwwwwwwwwwm.',
  '.wwwwwwwwww..',
  '.ww.....ww...',
  '.hh.....hh...',
];
const UNICORN_PAL: Palette = {
  w: '#f6f6fa',
  m: '#f08fd0',
  e: '#2b2b33',
  h: '#c9c9d4',
  '1': '#ffd34d',
  '2': '#ff9d4d',
  '3': '#ff5c7a',
};

const DRAGONFLY = [
  '..WW....WW......',
  '.WWWW..WWWW.....',
  '..WWWWWWWW......',
  '...gggggg.......',
  'eggggddddgggggg.',
  '...gggggg....gg.',
  '..WWWWWWWW......',
  '.WWWW..WWWW.....',
  '..WW....WW......',
];
const DRAGONFLY_PAL: Palette = {
  g: '#e8b23a',
  d: '#c4902a',
  W: '#f7dc8a',
  e: '#2b2b33',
};

const FIREFLY = [
  '.ww....ww.',
  'wwww..wwww',
  '.bbbbbbbb.',
  '.blblblbl.',
  '.bebllbeb.',
  '.bllllllb.',
  '.bbbbbbbb.',
  '..y....y..',
];
const FIREFLY_PAL: Palette = {
  w: '#dcdce6',
  b: '#7a4a2a',
  l: '#9c6236',
  e: '#23232b',
  y: '#ffe14d',
};

const FLOWER = [
  '.....cc.....',
  '....cCCc....',
  '...cCCCCc...',
  '..cCCiiCCc..',
  '.ppCCiiCCpp.',
  '.pppCCCCppp.',
  '..ppCCCCpp..',
  '...cCCCCc...',
  '....cccc....',
  '.....ss.....',
  '....s..s....',
];
const FLOWER_PAL: Palette = {
  c: '#bfe8ff',
  C: '#8fd4ff',
  i: '#e8f8ff',
  p: '#f2a4e8',
  s: '#7fd0e8',
};

const SEEDBOX = [
  'dddddddddddd',
  'dSsSsSsSsSsd',
  'dsSsSsSsSsSd',
  'dSsSsSsSsSsd',
  'dddddddddddd',
  'oooooooooooo',
  'ooddooddoodd',
  'oooooooooooo',
  'oooooooooooo',
  'dddddddddddd',
];
const SEEDBOX_PAL: Palette = {
  d: '#8f4a1c',
  o: '#c46a2a',
  S: '#2438c9',
  s: '#4a5df0',
};

const SEED = [
  '..x..',
  '.xx..',
  '.xxx.',
  'xxxx.',
  'xxxxx',
  '.xxx.',
  '..x..',
];
const seedPal = (c: string): Palette => ({ x: c });

function Streaks() {
  return (
    <g opacity="0.55">
      <path d="M-10 20 Q 30 12 60 22 T 115 18" stroke="#6cc0ff" strokeWidth="4" fill="none" strokeLinecap="round" />
      <path d="M-10 45 Q 40 35 75 46 T 120 40" stroke="#57b4ff" strokeWidth="6" fill="none" strokeLinecap="round" />
      <path d="M-10 72 Q 25 66 55 74 T 115 70" stroke="#6cc0ff" strokeWidth="4" fill="none" strokeLinecap="round" />
      <path d="M-10 92 Q 45 84 80 93 T 120 88" stroke="#57b4ff" strokeWidth="5" fill="none" strokeLinecap="round" />
      <circle cx="15" cy="32" r="1.6" fill="#bfe3ff" />
      <circle cx="82" cy="28" r="1.3" fill="#bfe3ff" />
      <circle cx="70" cy="58" r="1.6" fill="#bfe3ff" />
      <circle cx="24" cy="82" r="1.3" fill="#bfe3ff" />
      <circle cx="90" cy="80" r="1.6" fill="#bfe3ff" />
    </g>
  );
}

function BigLabel({ text, x, y }: { text: string; x: number; y: number }) {
  return (
    <text
      x={x}
      y={y}
      fontSize="13"
      fontWeight={900}
      fontStyle="italic"
      fill="#ffffff"
      stroke="#1c3d63"
      strokeWidth="0.8"
      paintOrder="stroke"
      fontFamily="'Poppins', sans-serif"
    >
      {text}
    </text>
  );
}

function renderKind(kind: string): React.ReactNode {
  switch (kind) {
    case 'gear-crates-100':
      return (
        <g>
          <Px grid={CRATE_TOP} palette={CRATE_TOP_PAL} x={12} y={22} s={2.4} />
          <Px grid={CRATE} palette={CRATE_PAL} x={12} y={24} s={2.4} />
          <Px grid={CRATE_TOP} palette={CRATE_TOP_BLUE_PAL} x={52} y={48} s={2.4} />
          <Px grid={CRATE} palette={CRATE_PAL} x={52} y={50} s={2.4} />
          <BigLabel text="100X" x={38} y={18} />
          <BigLabel text="100X" x={58} y={46} />
        </g>
      );
    case 'gear-crates-1000':
      return (
        <g>
          <Px grid={CRATE_TOP} palette={CRATE_TOP_BLUE_PAL} x={8} y={20} s={2.8} />
          <Px grid={CRATE} palette={CRATE_PAL} x={8} y={22} s={2.8} />
          <Px grid={CRATE_TOP} palette={CRATE_TOP_PAL} x={52} y={48} s={2.6} />
          <Px grid={CRATE} palette={CRATE_PAL} x={52} y={50} s={2.6} />
          <BigLabel text="1000X" x={30} y={16} />
          <BigLabel text="1000X" x={54} y={46} />
        </g>
      );
    case 'pro-bundle':
      return (
        <g>
          <Px grid={RACCOON} palette={RACCOON_PAL} x={10} y={12} s={3.4} />
          <Px grid={DRAGONFLY} palette={DRAGONFLY_PAL} x={52} y={14} s={2.6} />
          <Px grid={UNICORN} palette={UNICORN_PAL} x={34} y={54} s={3.2} />
        </g>
      );
    case 'seed-bundle':
      return (
        <g>
          <Px grid={SEED} palette={seedPal('#ffd34d')} x={16} y={10} s={3} />
          <Px grid={SEED} palette={seedPal('#ff7a3d')} x={62} y={12} s={3} />
          <Px grid={SEED} palette={seedPal('#c0392b')} x={38} y={26} s={3} />
          <Px grid={SEED} palette={seedPal('#8e44ad')} x={72} y={42} s={3} />
          <Px grid={SEED} palette={seedPal('#4caf50')} x={12} y={44} s={3} />
          <Px grid={FLOWER} palette={FLOWER_PAL} x={32} y={52} s={3.4} />
          <Px grid={SEED} palette={seedPal('#e84a8a')} x={74} y={72} s={3} />
        </g>
      );
    case 'dragon-black':
      return <Px grid={DRAGON} palette={DRAGON_BLACK} x={10} y={22} s={5} />;
    case 'dragon-purple':
      return <Px grid={DRAGON} palette={DRAGON_PURPLE} x={10} y={22} s={5} />;
    case 'raccoon':
      return <Px grid={RACCOON} palette={RACCOON_PAL} x={20} y={15} s={6} />;
    case 'raccoon3':
      return (
        <g>
          <Px grid={RACCOON} palette={RACCOON_PAL} x={8} y={10} s={3.6} />
          <Px grid={RACCOON} palette={RACCOON_PAL} x={56} y={16} s={3.6} />
          <Px grid={RACCOON} palette={RACCOON_PAL} x={30} y={54} s={3.6} />
        </g>
      );
    case 'flower':
      return <Px grid={FLOWER} palette={FLOWER_PAL} x={17} y={12} s={5.5} />;
    case 'seedbox':
      return <Px grid={SEEDBOX} palette={SEEDBOX_PAL} x={14} y={22} s={6} />;
    case 'ultra-bundle':
      return (
        <g>
          <Px grid={DRAGONFLY} palette={DRAGONFLY_PAL} x={6} y={8} s={2.2} />
          <Px grid={DRAGON} palette={DRAGON_PURPLE} x={50} y={6} s={2.4} />
          <Px grid={RACCOON} palette={RACCOON_PAL} x={12} y={40} s={2.8} />
          <Px grid={SEED} palette={seedPal('#e84a5f')} x={62} y={44} s={2.6} />
          <Px grid={UNICORN} palette={UNICORN_PAL} x={34} y={68} s={2.6} />
          <Px grid={SEED} palette={seedPal('#8e44ad')} x={76} y={68} s={2.6} />
        </g>
      );
    case 'dragonfly12': {
      const flies: React.ReactNode[] = [];
      for (let r = 0; r < 3; r++) {
        for (let c = 0; c < 4; c++) {
          flies.push(
            <Px
              key={`${r}-${c}`}
              grid={DRAGONFLY}
              palette={DRAGONFLY_PAL}
              x={4 + c * 24}
              y={10 + r * 28}
              s={1.4}
            />
          );
        }
      }
      return <g>{flies}</g>;
    }
    case 'unicorn12': {
      const ponies: React.ReactNode[] = [];
      for (let r = 0; r < 3; r++) {
        for (let c = 0; c < 4; c++) {
          ponies.push(
            <Px
              key={`${r}-${c}`}
              grid={UNICORN}
              palette={UNICORN_PAL}
              x={3 + c * 24}
              y={6 + r * 30}
              s={1.7}
            />
          );
        }
      }
      return <g>{ponies}</g>;
    }
    case 'firefly3':
      return (
        <g>
          <Px grid={FIREFLY} palette={FIREFLY_PAL} x={10} y={12} s={3.4} />
          <Px grid={FIREFLY} palette={FIREFLY_PAL} x={54} y={26} s={3.4} />
          <Px grid={FIREFLY} palette={FIREFLY_PAL} x={26} y={58} s={3.4} />
        </g>
      );
    default:
      return <Px grid={SEED} palette={seedPal('#ffd34d')} x={40} y={36} s={4} />;
  }
}

export function CardArt({ kind }: { kind: string }) {
  return (
    <svg viewBox="0 0 100 100" className="card-art" preserveAspectRatio="xMidYMid slice" role="img">
      <rect width="100" height="100" fill="#2e9bf5" />
      <Streaks />
      {renderKind(kind)}
    </svg>
  );
}

// ---------- Real product images ----------
// Drop transparent PNGs into public/img/items/ (raccoon.png, black-dragon.png, …)
// and the cards below switch from the drawn art to the real renders automatically.
// A missing file makes that card fall back to the drawn art.

const IMG_BASE = `${process.env.PUBLIC_URL}/img/items/`;

interface ImgSpec {
  img: string;
  x: number; // % from left
  y: number; // % from top
  w: number; // % width
  rot?: number; // degrees
}

interface ImgLayout {
  items: ImgSpec[];
  labels?: { text: string; x: number; y: number }[];
}

function grid(img: string, cols: number, rows: number): ImgSpec[] {
  const items: ImgSpec[] = [];
  const w = 82 / cols;
  for (let r = 0; r < rows; r++) {
    for (let c = 0; c < cols; c++) {
      items.push({
        img,
        x: 6 + c * (88 / cols),
        y: 6 + r * (88 / rows),
        w,
        rot: (r + c) % 2 === 0 ? -6 : 6,
      });
    }
  }
  return items;
}

export const IMAGE_LAYOUTS: Record<string, ImgLayout> = {
  'gear-crates-100': {
    items: [
      { img: 'gear-crate', x: 6, y: 20, w: 40, rot: -4 },
      { img: 'gear-crate', x: 48, y: 48, w: 40, rot: 3 },
    ],
    labels: [
      { text: '100X', x: 42, y: 8 },
      { text: '100X', x: 58, y: 38 },
    ],
  },
  'gear-crates-1000': {
    items: [
      { img: 'gear-crate', x: 6, y: 20, w: 42, rot: -4 },
      { img: 'gear-crate', x: 50, y: 50, w: 38, rot: 3 },
    ],
    labels: [
      { text: '1000X', x: 36, y: 8 },
      { text: '1000X', x: 56, y: 40 },
    ],
  },
  'pro-bundle': {
    items: [
      { img: 'raccoon', x: 4, y: 6, w: 42, rot: -5 },
      { img: 'golden-dragonfly', x: 48, y: 8, w: 46, rot: 8 },
      { img: 'unicorn', x: 26, y: 48, w: 46, rot: 2 },
    ],
  },
  'seed-bundle': {
    items: [
      { img: 'seeds', x: 4, y: 6, w: 36, rot: -8 },
      { img: 'seeds', x: 60, y: 10, w: 32, rot: 12 },
      { img: 'hypno-bloom', x: 28, y: 36, w: 44 },
      { img: 'seeds', x: 8, y: 58, w: 30, rot: 6 },
    ],
  },
  'dragon-black': { items: [{ img: 'black-dragon', x: 8, y: 10, w: 84 }] },
  'dragon-purple': { items: [{ img: 'rainbow-black-dragon', x: 8, y: 10, w: 84 }] },
  raccoon: { items: [{ img: 'raccoon', x: 16, y: 10, w: 68 }] },
  raccoon3: {
    items: [
      { img: 'raccoon', x: 6, y: 6, w: 40, rot: -6 },
      { img: 'raccoon', x: 54, y: 12, w: 40, rot: 6 },
      { img: 'raccoon', x: 28, y: 50, w: 42 },
    ],
  },
  flower: { items: [{ img: 'hypno-bloom', x: 18, y: 10, w: 64 }] },
  seedbox: { items: [{ img: 'seed-box', x: 13, y: 14, w: 74 }] },
  'ultra-bundle': {
    items: [
      { img: 'golden-dragonfly', x: 2, y: 4, w: 38, rot: -8 },
      { img: 'rainbow-black-dragon', x: 50, y: 2, w: 44, rot: 6 },
      { img: 'raccoon', x: 6, y: 42, w: 34, rot: -4 },
      { img: 'seeds', x: 66, y: 46, w: 28, rot: 10 },
      { img: 'unicorn', x: 30, y: 60, w: 38 },
    ],
  },
  dragonfly12: { items: grid('golden-dragonfly', 4, 3) },
  unicorn12: { items: grid('unicorn', 4, 3) },
  firefly3: {
    items: [
      { img: 'firefly', x: 8, y: 8, w: 38, rot: -8 },
      { img: 'firefly', x: 54, y: 20, w: 38, rot: 8 },
      { img: 'firefly', x: 24, y: 54, w: 38, rot: -3 },
    ],
  },
};

/** Images we already know are missing, so re-mounted cards skip the retry. */
const missingImages = new Set<string>();

/**
 * Product card image: real PNG collage when the files exist in
 * public/img/items/, drawn pixel art otherwise.
 */
export function SmartArt({ kind }: { kind: string }) {
  const layout = IMAGE_LAYOUTS[kind];
  const [fallback, setFallback] = useState(
    () => !layout || layout.items.some(it => missingImages.has(it.img))
  );

  if (fallback || !layout) return <CardArt kind={kind} />;

  return (
    <div className="img-art">
      <svg viewBox="0 0 100 100" className="card-art" preserveAspectRatio="xMidYMid slice">
        <rect width="100" height="100" fill="#2e9bf5" />
        <Streaks />
      </svg>
      {layout.items.map((it, i) => (
        <img
          key={i}
          src={`${IMG_BASE}${it.img}.png`}
          alt=""
          draggable={false}
          className="img-art-item"
          style={{
            left: `${it.x}%`,
            top: `${it.y}%`,
            width: `${it.w}%`,
            transform: it.rot ? `rotate(${it.rot}deg)` : undefined,
          }}
          onError={() => {
            missingImages.add(it.img);
            setFallback(true);
          }}
        />
      ))}
      {layout.labels?.map((l, i) => (
        <span key={i} className="img-art-label" style={{ left: `${l.x}%`, top: `${l.y}%` }}>
          {l.text}
        </span>
      ))}
    </div>
  );
}

/** Floating collage of pets used in the hero, on a transparent background. */
export function HeroArt() {
  return (
    <svg viewBox="0 0 100 100" className="hero-art" role="img">
      <g transform="rotate(-8 50 50)">
        <Px grid={DRAGONFLY} palette={DRAGONFLY_PAL} x={40} y={2} s={3.2} />
      </g>
      <g transform="rotate(6 30 70)">
        <Px grid={UNICORN} palette={UNICORN_PAL} x={4} y={52} s={3.4} />
      </g>
      <Px grid={RACCOON} palette={RACCOON_PAL} x={40} y={42} s={3.8} />
      <g transform="rotate(10 80 70)">
        <Px grid={DRAGON} palette={DRAGON_PURPLE} x={52} y={58} s={2.6} />
      </g>
      <Px grid={SEED} palette={seedPal('#ff7a3d')} x={10} y={16} s={3.4} />
      <Px grid={FLOWER} palette={FLOWER_PAL} x={72} y={26} s={2.6} />
    </svg>
  );
}

/** The dripping red GARDEN SHOP logo with a lens-flare streak. */
export function Logo({ height = 44 }: { height?: number }) {
  return (
    <svg
      viewBox="0 0 340 96"
      style={{ height, width: 'auto', display: 'block' }}
      className="gs-logo"
      role="img"
      aria-label="Garden Shop"
    >
      <defs>
        <linearGradient id="gsLogoGrad" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stopColor="#ff4b4b" />
          <stop offset="0.55" stopColor="#f01f2e" />
          <stop offset="1" stopColor="#b60f1e" />
        </linearGradient>
        <filter id="gsFlareBlur" x="-20%" y="-300%" width="140%" height="700%">
          <feGaussianBlur stdDeviation="2.2" />
        </filter>
        <filter id="gsGlow" x="-30%" y="-30%" width="160%" height="160%">
          <feGaussianBlur stdDeviation="3" />
        </filter>
      </defs>
      <g transform="rotate(-5 170 48)">
        <text
          x="170"
          y="58"
          textAnchor="middle"
          fontFamily="'Luckiest Guy', 'Poppins', cursive"
          fontSize="46"
          fill="url(#gsLogoGrad)"
          stroke="#7d0d14"
          strokeWidth="1.6"
          paintOrder="stroke"
          filter="url(#gsGlow)"
          opacity="0.6"
        >
          GARDEN SHOP
        </text>
        <text
          x="170"
          y="58"
          textAnchor="middle"
          fontFamily="'Luckiest Guy', 'Poppins', cursive"
          fontSize="46"
          fill="url(#gsLogoGrad)"
          stroke="#7d0d14"
          strokeWidth="1.6"
          paintOrder="stroke"
        >
          GARDEN SHOP
        </text>
        {/* drips */}
        <g fill="#c11322">
          <path d="M28 60 q2 10 0 14 q-2 -4 -3 -8 z" />
          <ellipse cx="27" cy="78" rx="2" ry="2.6" />
          <path d="M78 62 q2 8 0 12 q-2 -3 -3 -7 z" />
          <ellipse cx="77" cy="79" rx="1.8" ry="2.4" />
          <path d="M128 61 q2 12 0 16 q-2 -5 -3 -9 z" />
          <ellipse cx="127" cy="83" rx="2" ry="2.6" />
          <path d="M196 62 q2 9 0 13 q-2 -4 -3 -8 z" />
          <ellipse cx="195" cy="80" rx="1.8" ry="2.4" />
          <path d="M248 61 q2 11 0 15 q-2 -5 -3 -9 z" />
          <ellipse cx="247" cy="82" rx="2" ry="2.6" />
          <path d="M300 60 q2 13 0 17 q-2 -5 -3 -10 z" />
          <ellipse cx="299" cy="83" rx="2" ry="2.6" />
        </g>
        {/* lens flare */}
        <rect x="-20" y="42" width="380" height="3.4" fill="#ffffff" opacity="0.85" filter="url(#gsFlareBlur)" />
        <circle cx="150" cy="43.5" r="7" fill="#ffffff" opacity="0.9" filter="url(#gsFlareBlur)" />
        <circle cx="150" cy="43.5" r="2.6" fill="#ffffff" />
      </g>
    </svg>
  );
}
