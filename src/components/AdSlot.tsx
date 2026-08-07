import React, { useEffect, useRef, useState } from 'react';
import {
  ADSENSE_CLIENT,
  isAdsenseConfigured,
  loadAdsense,
  requestNonPersonalizedAds,
} from '../lib/adsense';

type Props = {
  slot: string;
  /** 'sidebar' is a tall rail unit, 'inline' a responsive banner. */
  variant: 'sidebar' | 'inline';
};

export default function AdSlot({ slot, variant }: Props) {
  const insRef = useRef<HTMLModElement>(null);
  const pushed = useRef(false);
  const [failed, setFailed] = useState(false);

  const active = isAdsenseConfigured && slot.length > 0;

  useEffect(() => {
    if (!active || pushed.current) return;
    // React 19 StrictMode runs effects twice in dev; one push per <ins> only.
    pushed.current = true;

    let cancelled = false;
    loadAdsense()
      .then(() => {
        if (cancelled || !insRef.current) return;
        requestNonPersonalizedAds();
        (window.adsbygoogle = window.adsbygoogle || []).push({});
      })
      .catch(() => {
        // Blocked by an ad blocker, or the script never arrived.
        if (!cancelled) setFailed(true);
      });

    return () => {
      cancelled = true;
    };
  }, [active]);

  if (!active || failed) {
    return (
      <div className={`ad-slot ad-slot-${variant} ad-slot-empty`}>
        <span className="ad-badge">Ad</span>
        <p>
          {failed
            ? 'Ad could not load.'
            : 'Ad space — set REACT_APP_ADSENSE_CLIENT to go live.'}
        </p>
      </div>
    );
  }

  return (
    <div className={`ad-slot ad-slot-${variant}`}>
      <span className="ad-label">Advertisement</span>
      <ins
        ref={insRef}
        className="adsbygoogle"
        style={{ display: 'block', width: '100%' }}
        data-ad-client={ADSENSE_CLIENT}
        data-ad-slot={slot}
        data-ad-format={variant === 'sidebar' ? 'vertical' : 'auto'}
        data-full-width-responsive={variant === 'inline' ? 'true' : 'false'}
      />
    </div>
  );
}
