import React, { useEffect, useRef, useState } from 'react';
import { AD_DURATION_S, AD_REWARD, creditLabel } from '../lib/store';

type Props = {
  onClaim: () => void;
  onClose: () => void;
};

/**
 * Rewarded-ad placeholder. Drop a real network's rewarded unit into the
 * `ad-stage` element and call onClaim from its reward callback instead of the
 * timer — the surrounding cooldown/limit logic stays the same.
 */
export default function AdModal({ onClaim, onClose }: Props) {
  const [left, setLeft] = useState(AD_DURATION_S);
  const [claimed, setClaimed] = useState(false);
  const closeRef = useRef<HTMLButtonElement>(null);

  useEffect(() => {
    if (left <= 0) return;
    const t = window.setTimeout(() => setLeft(s => s - 1), 1000);
    return () => window.clearTimeout(t);
  }, [left]);

  useEffect(() => {
    closeRef.current?.focus();
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose();
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [onClose]);

  const done = left <= 0;
  const pct = ((AD_DURATION_S - left) / AD_DURATION_S) * 100;

  return (
    <div className="modal-backdrop" onClick={onClose}>
      <div
        className="modal"
        role="dialog"
        aria-modal="true"
        aria-label="Rewarded ad"
        onClick={e => e.stopPropagation()}
      >
        <div className="modal-head">
          <h3>{done ? 'Reward unlocked' : 'Watching ad…'}</h3>
          <button ref={closeRef} className="icon-btn" onClick={onClose} aria-label="Close">
            ✕
          </button>
        </div>

        <div className="ad-stage" id="ad-stage">
          {done ? (
            <div className="ad-done">
              <span className="ad-done-icon">🌱</span>
              <p>You earned {creditLabel(AD_REWARD)}.</p>
            </div>
          ) : (
            <div className="ad-placeholder">
              <span className="ad-badge">Ad</span>
              <p>Your sponsor message plays here.</p>
              <span className="ad-timer">{left}s</span>
            </div>
          )}
        </div>

        <div className="ad-progress">
          <div className="ad-progress-fill" style={{ width: `${pct}%` }} />
        </div>

        <button
          className="primary-btn"
          disabled={!done || claimed}
          onClick={() => {
            setClaimed(true);
            onClaim();
          }}
        >
          {done ? `Claim +${creditLabel(AD_REWARD)}` : `Claim in ${left}s`}
        </button>
      </div>
    </div>
  );
}
