import React, { useCallback, useEffect, useState } from 'react';
import './App.css';
import Login from './components/Login';
import AdModal from './components/AdModal';
import ReferralCard from './components/ReferralCard';
import RewardsShop from './components/RewardsShop';
import Leaderboard from './components/Leaderboard';
import { REWARDS } from './lib/rewards';
import { callbackError, completeLogin, RobloxUser } from './lib/roblox';
import {
  AD_DAILY_LIMIT,
  AD_REWARD,
  Profile,
  adReady,
  creditLabel,
  captureRefFromUrl,
  grantAdReward,
  loadProfile,
  loadSession,
  redeem,
  referralCredits,
  referralsFor,
  saveSession,
  spendableCredits,
} from './lib/store';

export default function App() {
  const [user, setUser] = useState<RobloxUser | null>(null);
  const [profile, setProfile] = useState<Profile | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(true);
  const [adOpen, setAdOpen] = useState(false);
  const [toast, setToast] = useState<string | null>(null);
  const [now, setNow] = useState(Date.now());

  const signIn = useCallback((u: RobloxUser) => {
    saveSession(u);
    setUser(u);
    setProfile(loadProfile(u));
  }, []);

  // Resume a session, or finish the Roblox redirect we came back from.
  useEffect(() => {
    captureRefFromUrl();
    const oauthError = callbackError();
    if (oauthError) {
      setError(oauthError);
      setBusy(false);
      return;
    }

    let cancelled = false;
    completeLogin()
      .then(u => {
        if (cancelled) return;
        if (u) {
          signIn(u);
        } else {
          const existing = loadSession();
          if (existing) signIn(existing);
        }
      })
      .catch(e => {
        if (!cancelled) setError(e instanceof Error ? e.message : 'Login failed.');
      })
      .finally(() => {
        if (!cancelled) setBusy(false);
      });

    return () => {
      cancelled = true;
    };
  }, [signIn]);

  // Ticks the ad cooldown display.
  useEffect(() => {
    const t = window.setInterval(() => setNow(Date.now()), 1000);
    return () => window.clearInterval(t);
  }, []);

  const flash = (msg: string) => {
    setToast(msg);
    window.setTimeout(() => setToast(null), 2600);
  };

  const signOut = () => {
    saveSession(null);
    setUser(null);
    setProfile(null);
  };

  if (!user || !profile) {
    return (
      <div className="page">
        <Login onDemoLogin={signIn} error={error} busy={busy} />
      </div>
    );
  }

  const referrals = referralsFor(profile.referralCode);
  const balance = spendableCredits(profile);
  const ad = adReady(profile);
  const cooldown = Math.max(0, Math.ceil((profile.lastAdAt + 60_000 - now) / 1000));

  const handleClaimAd = () => {
    setProfile(grantAdReward(profile));
    setAdOpen(false);
    flash(`+${creditLabel(AD_REWARD)} added`);
  };

  const handleRedeem = (rewardId: string) => {
    const reward = REWARDS.find(r => r.id === rewardId);
    if (!reward) return;
    const next = redeem(profile, reward.name, reward.cost);
    if (!next) {
      flash('Not enough credits yet.');
      return;
    }
    setProfile(next);
    flash(`${reward.name} unlocked — claim code below`);
  };

  return (
    <div className="page">
      <header className="topbar">
        <div className="brand small">
          <span className="brand-mark">🌱</span>
          <div>
            <h1>Seed Circle</h1>
            <p className="brand-sub">Grow a Garden 2</p>
          </div>
        </div>
        <div className="account">
          <div className="balance">
            <span className="balance-value">{balance.toLocaleString()}</span>
            <span className="balance-label">credits</span>
          </div>
          {user.avatar ? (
            <img className="avatar" src={user.avatar} alt="" />
          ) : (
            <span className="avatar-dot big">
              {user.username.slice(0, 1).toUpperCase()}
            </span>
          )}
          <div className="account-meta">
            <b>{user.displayName}</b>
            <button className="link-btn" onClick={signOut}>
              Sign out
            </button>
          </div>
        </div>
      </header>

      {user.demo && (
        <div className="demo-strip">
          Demo mode — progress is saved in this browser only.
        </div>
      )}

      <main className="layout">
        <section className="card hero-card">
          <header className="card-head">
            <h2>Watch &amp; earn</h2>
            <span className="pill">
              {profile.adsToday}/{AD_DAILY_LIMIT} today
            </span>
          </header>
          <p className="card-sub">
            One short ad, {creditLabel(AD_REWARD)}. There's a one-minute
            cooldown between them.
          </p>
          <button
            className="watch-btn"
            disabled={!ad.ok}
            onClick={() => setAdOpen(true)}
          >
            <span className="watch-icon">▶</span>
            {ad.ok
              ? `Watch an ad · +${creditLabel(AD_REWARD)}`
              : cooldown > 0 && profile.adsToday < AD_DAILY_LIMIT
              ? `Next ad in ${cooldown}s`
              : ad.reason}
          </button>

          <div className="stats">
            <div>
              <b>{profile.adsWatched}</b>
              <span>ads watched</span>
            </div>
            <div>
              <b>{referrals.length}</b>
              <span>friends invited</span>
            </div>
            <div>
              <b>{(profile.totalEarned + referralCredits(profile.referralCode)).toLocaleString()}</b>
              <span>credits earned</span>
            </div>
          </div>
        </section>

        <ReferralCard code={profile.referralCode} referrals={referrals} />
        <RewardsShop balance={balance} claims={profile.claims} onRedeem={handleRedeem} />
        <Leaderboard username={user.username} referrals={referrals.length} />
      </main>

      <footer className="footer">
        Fan-made. Not affiliated with or endorsed by Roblox Corporation or the
        Grow a Garden developers.
      </footer>

      {adOpen && <AdModal onClaim={handleClaimAd} onClose={() => setAdOpen(false)} />}
      {toast && <div className="toast">{toast}</div>}
    </div>
  );
}
