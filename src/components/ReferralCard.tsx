import React, { useState } from 'react';
import { Referral, REFERRAL_REWARD, referralLink } from '../lib/store';

type Props = {
  code: string;
  referrals: Referral[];
};

export default function ReferralCard({ code, referrals }: Props) {
  const [copied, setCopied] = useState<'link' | 'code' | null>(null);
  const link = referralLink(code);

  const copy = async (value: string, what: 'link' | 'code') => {
    try {
      await navigator.clipboard.writeText(value);
    } catch {
      window.prompt('Copy your invite:', value);
    }
    setCopied(what);
    window.setTimeout(() => setCopied(null), 1800);
  };

  const share = async () => {
    const text = `Come farm with me in Grow a Garden 2 — use my code ${code} and we both get credits:`;
    if (navigator.share) {
      try {
        await navigator.share({ title: 'Seed Circle', text, url: link });
        return;
      } catch {
        /* user dismissed the share sheet */
      }
    }
    copy(`${text} ${link}`, 'link');
  };

  return (
    <section className="card">
      <header className="card-head">
        <h2>Invite friends</h2>
        <span className="pill">+{REFERRAL_REWARD} credits each</span>
      </header>

      <p className="card-sub">
        They sign in with Roblox using your link, you both get paid. No cap.
      </p>

      <div className="code-display" onClick={() => copy(code, 'code')} title="Copy code">
        <span className="code-label">Your code</span>
        <span className="code-value">{code}</span>
        <span className="code-hint">{copied === 'code' ? 'Copied!' : 'Tap to copy'}</span>
      </div>

      <div className="link-row">
        <input readOnly value={link} aria-label="Your referral link" onFocus={e => e.currentTarget.select()} />
        <button className="ghost-btn" onClick={() => copy(link, 'link')}>
          {copied === 'link' ? 'Copied' : 'Copy'}
        </button>
        <button className="primary-btn" onClick={share}>
          Share
        </button>
      </div>

      <div className="referral-list">
        <div className="referral-list-head">
          <span>Friends joined</span>
          <b>{referrals.length}</b>
        </div>
        {referrals.length === 0 ? (
          <p className="empty">
            Nobody yet. Drop your link in a Discord or a group chat.
          </p>
        ) : (
          <ul>
            {referrals.map(r => (
              <li key={r.code}>
                <span className="avatar-dot">{r.username.slice(0, 1).toUpperCase()}</span>
                <span className="referral-name">{r.username}</span>
                <span className="referral-credits">+{REFERRAL_REWARD} credits</span>
              </li>
            ))}
          </ul>
        )}
      </div>
    </section>
  );
}
