import React, { useEffect, useMemo, useRef, useState } from 'react';
import CoinIcon from './CoinIcon';
import './TikTokLookup.css';
import {
  LookupError,
  TikTokProfile,
  lookupProfile,
  normalizeUsername,
  profileUrlFor,
} from './tiktok';

const numberFormat = new Intl.NumberFormat();

/** The amounts shown in the grid, following TikTok's own coin bundles. */
const COIN_AMOUNTS = [70, 350, 700, 1400, 3500, 7000, 17500, 35000, 70000];

function initialOf(username: string): string {
  const letter = username.replace(/[^A-Za-z0-9]/g, '')[0];
  return letter ? letter.toUpperCase() : '?';
}

function TikTokLookup() {
  const [query, setQuery] = useState('');
  const [coins, setCoins] = useState('');
  const [profile, setProfile] = useState<TikTokProfile | null>(null);
  const [manualAvatar, setManualAvatar] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<{ message: string; attempts: string[] } | null>(null);
  const [sentTo, setSentTo] = useState<string | null>(null);
  const fileInput = useRef<HTMLInputElement>(null);

  // The confirmation is cosmetic - it fades out on its own after a moment.
  useEffect(() => {
    if (!sentTo) return;
    const timer = setTimeout(() => setSentTo(null), 2600);
    return () => clearTimeout(timer);
  }, [sentTo]);

  const coinValue = coins === '' ? null : Number(coins);
  const formattedCoins = useMemo(
    () => (coinValue === null ? null : numberFormat.format(coinValue)),
    [coinValue]
  );

  const avatarUrl = manualAvatar ?? profile?.avatarUrl ?? null;

  const handleSearch = async (event: React.FormEvent) => {
    event.preventDefault();
    const username = normalizeUsername(query);

    if (!username) {
      setProfile(null);
      setManualAvatar(null);
      setError({
        message: 'That is not a valid TikTok username. Use letters, numbers, dots or underscores - or paste the profile link.',
        attempts: [],
      });
      return;
    }

    setLoading(true);
    setError(null);
    setManualAvatar(null);
    setProfile(null);

    try {
      setProfile(await lookupProfile(username));
    } catch (caught) {
      // Still show the card: the username is valid, only the picture is missing.
      setProfile({ username, profileUrl: profileUrlFor(username), source: 'not found' });
      setError({
        message: (caught as Error).message,
        attempts: caught instanceof LookupError ? caught.attempts : [],
      });
    } finally {
      setLoading(false);
    }
  };

  const handleCoinChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const digitsOnly = event.target.value.replace(/[^\d]/g, '').slice(0, 12);
    setCoins(digitsOnly);
  };

  const handleUpload = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;
    setManualAvatar(URL.createObjectURL(file));
  };

  return (
    <div className="tt-page">
      <header className="tt-header">
        <CoinIcon size={44} />
        <h1>TikTok Profile Lookup</h1>
        <p>Type a username to pull up the profile picture, and add a coin number to the card.</p>
      </header>

      <form className="tt-panel" onSubmit={handleSearch}>
        <label className="tt-label" htmlFor="tt-username">
          TikTok username
        </label>
        <div className="tt-row">
          <div className="tt-field">
            <span className="tt-adornment" aria-hidden="true">@</span>
            <input
              id="tt-username"
              className="tt-input"
              type="text"
              placeholder="charlidamelio"
              autoComplete="off"
              autoCapitalize="none"
              spellCheck={false}
              value={query}
              onChange={event => setQuery(event.target.value.replace(/^@+/, ''))}
            />
          </div>
          <button className="tt-button" type="submit" disabled={loading}>
            {loading ? 'Looking up...' : 'Look up'}
          </button>
        </div>

        <label className="tt-label" htmlFor="tt-coins">
          Number of coins
        </label>
        <div className="tt-field">
          <span className="tt-adornment" aria-hidden="true">
            <CoinIcon size={22} />
          </span>
          <input
            id="tt-coins"
            className="tt-input"
            type="text"
            inputMode="numeric"
            placeholder="0"
            value={coins}
            onChange={handleCoinChange}
          />
        </div>
      </form>

      {error && (
        <div className="tt-error" role="status">
          <strong>{error.message}</strong>
          {error.attempts.length > 0 && (
            <>
              <p>What was tried:</p>
              <ul>
                {error.attempts.map(attempt => (
                  <li key={attempt}>{attempt}</li>
                ))}
              </ul>
              <p className="tt-hint">
                You can still set the picture yourself below, or open the profile on TikTok.
              </p>
            </>
          )}
        </div>
      )}

      {profile && (
        <section className="tt-card">
          <div className="tt-avatar-wrap">
            {avatarUrl ? (
              <img
                className="tt-avatar"
                src={avatarUrl}
                alt={`@${profile.username} on TikTok`}
                referrerPolicy="no-referrer"
                onError={() => setManualAvatar(null)}
              />
            ) : (
              <div className="tt-avatar tt-avatar-fallback" aria-hidden="true">
                {initialOf(profile.username)}
              </div>
            )}
          </div>

          {profile.nickname && <h2 className="tt-nickname">{profile.nickname}</h2>}
          <a className="tt-handle" href={profile.profileUrl} target="_blank" rel="noreferrer noopener">
            @{profile.username}
          </a>

          {typeof profile.followerCount === 'number' && (
            <p className="tt-followers">{numberFormat.format(profile.followerCount)} followers</p>
          )}

          <p className="tt-balance">
            <CoinIcon size={30} />
            <span>{formattedCoins ?? '0'}</span>
          </p>

          <div className="tt-amounts">
            {COIN_AMOUNTS.map(amount => (
              <button
                type="button"
                key={amount}
                className={`tt-amount ${coinValue === amount ? 'is-selected' : ''}`}
                aria-pressed={coinValue === amount}
                onClick={() => setCoins(String(amount))}
              >
                <CoinIcon size={15} />
                <span>{numberFormat.format(amount)}</span>
              </button>
            ))}
          </div>

          <button
            type="button"
            className="tt-send"
            onClick={() => setSentTo(profile.username)}
          >
            Send
          </button>

          <div className="tt-manual">
            <button type="button" className="tt-link-button" onClick={() => fileInput.current?.click()}>
              Use a picture from this device
            </button>
            <input
              ref={fileInput}
              type="file"
              accept="image/*"
              hidden
              onChange={handleUpload}
            />
            <input
              className="tt-input tt-input-plain"
              type="url"
              placeholder="...or paste an image URL"
              onChange={event => setManualAvatar(event.target.value.trim() || null)}
            />
          </div>

          {!manualAvatar && profile.avatarUrl && (
            <p className="tt-source">Picture found via {profile.source}</p>
          )}
        </section>
      )}

      {sentTo && (
        <div className="tt-toast" role="status" aria-live="polite">
          <CoinIcon size={20} />
          <span>
            Sent {formattedCoins ?? '0'} to @{sentTo}
            <small>Nothing actually left this page.</small>
          </span>
        </div>
      )}

      <footer className="tt-footer">
        TikTok has no public API for this, so the lookup goes through public proxies and can fail.
        The coin number is just a label you type - it is not a balance and it changes nothing on TikTok.
        <br />
        <a className="tt-handle" href="#/dommer">DommerJob login</a>
      </footer>
    </div>
  );
}

export default TikTokLookup;
