import React from 'react';

type Props = { size?: number; className?: string };

/**
 * Gold TikTok-style coin, drawn inline so it stays crisp at any size and
 * follows the page in both themes. Swap for an <img> if you prefer a bitmap.
 */
function CoinIcon({ size = 24, className }: Props) {
  return (
    <svg
      className={className}
      width={size}
      height={size}
      viewBox="0 0 120 120"
      role="img"
      aria-label="coins"
      focusable="false"
    >
      <circle cx="60" cy="60" r="58" fill="#f0d878" />
      <circle cx="60" cy="60" r="58" fill="none" stroke="#d9b94e" strokeWidth="2" />
      <circle cx="60" cy="60" r="46" fill="#f0a23c" />
      <g transform="translate(28.4 22.2) scale(0.62)" fill="#f7e08c">
        <path
          d="M58 20h16c0 12 8 20 20 21v16c-9 0-17-3-24-8v22c0 17-14 31-31 31S8 88 8 71s14-31 31-31c2 0 3 0 5 1v17c-2-1-3-1-5-1-8 0-14 6-14 14s6 14 14 14 14-6 14-14z"
        />
      </g>
    </svg>
  );
}

export default CoinIcon;
