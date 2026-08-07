import React, { useState } from 'react';
import { isRobloxConfigured, startLogin, demoUser, RobloxUser } from '../lib/roblox';
import { AD_DAILY_LIMIT, AD_REWARD, pendingRef, REFERRAL_REWARD, WELCOME_BONUS } from '../lib/store';

type Props = {
  onDemoLogin: (user: RobloxUser) => void;
  error: string | null;
  busy: boolean;
};

export default function Login({ onDemoLogin, error, busy }: Props) {
  const [name, setName] = useState('');
  const [failed, setFailed] = useState<string | null>(null);
  const ref = pendingRef();

  const signIn = async () => {
    try {
      await startLogin();
    } catch (e) {
      setFailed(e instanceof Error ? e.message : 'Could not reach Roblox.');
    }
  };

  return (
    <div className="login-shell">
      <div className="login-card">
        <div className="brand">
          <span className="brand-mark">🌱</span>
          <div>
            <h1>Seed Circle</h1>
            <p className="brand-sub">Referrals &amp; rewards for Grow a Garden 2</p>
          </div>
        </div>

        <p className="pitch">
          Invite friends, watch a few ads, and turn it all into in-game loot.
          Sign in with Roblox so we know which garden to send it to.
        </p>

        {ref && (
          <div className="ref-banner">
            <span className="ref-banner-icon">🎉</span>
            <span>
              You were invited with code <b>{ref}</b> — sign in and you both get
              credits.
            </span>
          </div>
        )}

        {(error || failed) && <div className="alert">{error || failed}</div>}

        {isRobloxConfigured ? (
          <button className="roblox-btn" onClick={signIn} disabled={busy}>
            <RobloxLogo />
            {busy ? 'Signing you in…' : 'Sign in with Roblox'}
          </button>
        ) : (
          <form
            className="demo-form"
            onSubmit={e => {
              e.preventDefault();
              if (name.trim()) onDemoLogin(demoUser(name));
            }}
          >
            <button className="roblox-btn" type="button" disabled title="Add REACT_APP_ROBLOX_CLIENT_ID to enable">
              <RobloxLogo />
              Sign in with Roblox
            </button>
            <p className="demo-note">
              Roblox login isn't configured on this deployment yet. Try it in
              demo mode:
            </p>
            <div className="demo-row">
              <input
                value={name}
                onChange={e => setName(e.target.value)}
                placeholder="Roblox username"
                maxLength={20}
                aria-label="Roblox username"
              />
              <button type="submit" className="ghost-btn" disabled={!name.trim()}>
                Continue
              </button>
            </div>
          </form>
        )}

        <ul className="perks">
          <li>
            <b>+{WELCOME_BONUS}</b> credits just for joining
          </li>
          <li>
            <b>+{REFERRAL_REWARD}</b> credits per friend who signs in
          </li>
          <li>
            <b>+{AD_REWARD}</b> credit per ad, up to {AD_DAILY_LIMIT} a day
          </li>
        </ul>

        <p className="fineprint">
          Fan-made. Not affiliated with or endorsed by Roblox Corporation or the
          Grow a Garden developers.
        </p>
      </div>
    </div>
  );
}

function RobloxLogo() {
  return (
    <svg viewBox="0 0 24 24" width="20" height="20" aria-hidden="true">
      <path
        fill="currentColor"
        d="M4.9 0 0 19.1 19.1 24 24 4.9 4.9 0Zm5.2 9.1 4.9 1.3-1.3 4.9-4.9-1.3 1.3-4.9Z"
      />
    </svg>
  );
}
