/**
 * Google AdSense display units.
 *
 * Everything is driven by env vars so the site stays deployable before an
 * AdSense account exists — with no publisher ID the slots render as labelled
 * placeholders instead of firing invalid ad requests.
 */

declare global {
  interface Window {
    adsbygoogle?: Array<Record<string, unknown>> & {
      requestNonPersonalizedAds?: number;
    };
  }
}

export const ADSENSE_CLIENT = process.env.REACT_APP_ADSENSE_CLIENT || '';
export const SLOT_SIDEBAR = process.env.REACT_APP_ADSENSE_SLOT_SIDEBAR || '';
export const SLOT_INLINE = process.env.REACT_APP_ADSENSE_SLOT_INLINE || '';

export const isAdsenseConfigured = /^ca-pub-\d+$/.test(ADSENSE_CLIENT);

const SCRIPT_SRC = 'https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js';

let loader: Promise<void> | null = null;

/** Injects the AdSense loader once, no matter how many slots ask for it. */
export function loadAdsense(): Promise<void> {
  if (!isAdsenseConfigured) return Promise.reject(new Error('AdSense not configured'));
  if (loader) return loader;

  loader = new Promise<void>((resolve, reject) => {
    const existing = document.querySelector<HTMLScriptElement>(`script[src^="${SCRIPT_SRC}"]`);
    if (existing) {
      resolve();
      return;
    }
    const script = document.createElement('script');
    script.src = `${SCRIPT_SRC}?client=${encodeURIComponent(ADSENSE_CLIENT)}`;
    script.async = true;
    script.crossOrigin = 'anonymous';
    script.onload = () => resolve();
    script.onerror = () => reject(new Error('AdSense script blocked or failed to load'));
    document.head.appendChild(script);
  });

  return loader;
}

/**
 * Ask for non-personalised ads. The audience here skews young, and this keeps
 * requests out of behavioural targeting.
 *
 * This is not a substitute for the consent work: EEA/UK traffic needs a
 * Google-certified CMP before AdSense will serve at all, and child-directed
 * tagging is configured on the AdSense account, not here.
 */
export function requestNonPersonalizedAds(): void {
  window.adsbygoogle = window.adsbygoogle || [];
  window.adsbygoogle.requestNonPersonalizedAds = 1;
}
