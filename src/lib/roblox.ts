/**
 * Roblox "Sign in with Roblox" (OAuth 2.0 / OpenID Connect) using PKCE.
 *
 * This site is a static build (GitHub Pages), so it authenticates as a *public*
 * OAuth client: no client secret, authorization-code flow with PKCE.
 *
 * Set REACT_APP_ROBLOX_CLIENT_ID in a .env file to enable it. Without it, the
 * app runs in demo mode where you pick a username locally.
 */

export type RobloxUser = {
  id: string;
  username: string;
  displayName: string;
  avatar: string | null;
  demo: boolean;
};

const AUTH_URL = 'https://apis.roblox.com/oauth/v1/authorize';
const TOKEN_URL = 'https://apis.roblox.com/oauth/v1/token';
const USERINFO_URL = 'https://apis.roblox.com/oauth/v1/userinfo';
const SCOPES = 'openid profile';

const VERIFIER_KEY = 'gg2.pkce.verifier';
const STATE_KEY = 'gg2.pkce.state';

export const clientId = process.env.REACT_APP_ROBLOX_CLIENT_ID || '';
export const isRobloxConfigured = clientId.length > 0;

/** The redirect URI must match one registered on the Roblox app exactly. */
export function redirectUri(): string {
  const base = process.env.PUBLIC_URL || '';
  return `${window.location.origin}${base}/`;
}

function randomString(bytes = 32): string {
  const buf = new Uint8Array(bytes);
  window.crypto.getRandomValues(buf);
  let out = '';
  for (let i = 0; i < buf.length; i++) {
    out += buf[i].toString(16).padStart(2, '0');
  }
  return out;
}

function base64Url(buf: ArrayBuffer): string {
  const bytes = new Uint8Array(buf);
  let binary = '';
  for (let i = 0; i < bytes.length; i++) {
    binary += String.fromCharCode(bytes[i]);
  }
  return window
    .btoa(binary)
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');
}

async function challengeFor(verifier: string): Promise<string> {
  const data = new TextEncoder().encode(verifier);
  const digest = await window.crypto.subtle.digest('SHA-256', data);
  return base64Url(digest);
}

/** Kicks the browser over to Roblox's consent screen. */
export async function startLogin(): Promise<void> {
  const verifier = randomString(48);
  const state = randomString(16);
  sessionStorage.setItem(VERIFIER_KEY, verifier);
  sessionStorage.setItem(STATE_KEY, state);

  const params = new URLSearchParams({
    client_id: clientId,
    redirect_uri: redirectUri(),
    scope: SCOPES,
    response_type: 'code',
    state,
    code_challenge: await challengeFor(verifier),
    code_challenge_method: 'S256',
  });
  window.location.assign(`${AUTH_URL}?${params.toString()}`);
}

/**
 * Completes the flow when Roblox redirects back with ?code=...&state=...
 * Returns null when the current URL is not an OAuth callback.
 */
export async function completeLogin(): Promise<RobloxUser | null> {
  const url = new URL(window.location.href);
  const code = url.searchParams.get('code');
  const state = url.searchParams.get('state');
  if (!code) return null;

  const verifier = sessionStorage.getItem(VERIFIER_KEY);
  const expectedState = sessionStorage.getItem(STATE_KEY);
  sessionStorage.removeItem(VERIFIER_KEY);
  sessionStorage.removeItem(STATE_KEY);
  clearCallbackParams();

  if (!verifier) throw new Error('Login session expired — please try again.');
  if (!state || state !== expectedState) {
    throw new Error('State mismatch — login was rejected for safety.');
  }

  const body = new URLSearchParams({
    client_id: clientId,
    grant_type: 'authorization_code',
    code,
    code_verifier: verifier,
    redirect_uri: redirectUri(),
  });

  const tokenRes = await fetch(TOKEN_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: body.toString(),
  });
  if (!tokenRes.ok) {
    throw new Error(`Roblox rejected the login (HTTP ${tokenRes.status}).`);
  }
  const token = (await tokenRes.json()) as { access_token: string };

  const infoRes = await fetch(USERINFO_URL, {
    headers: { Authorization: `Bearer ${token.access_token}` },
  });
  if (!infoRes.ok) {
    throw new Error(`Could not read your Roblox profile (HTTP ${infoRes.status}).`);
  }
  const info = (await infoRes.json()) as {
    sub: string;
    name?: string;
    nickname?: string;
    preferred_username?: string;
    picture?: string;
  };

  return {
    id: info.sub,
    username: info.preferred_username || info.nickname || info.name || 'Player',
    displayName: info.name || info.nickname || info.preferred_username || 'Player',
    avatar: info.picture || null,
    demo: false,
  };
}

/** Roblox sends errors back on the redirect too (e.g. the user hit "Cancel"). */
export function callbackError(): string | null {
  const url = new URL(window.location.href);
  const err = url.searchParams.get('error');
  if (!err) return null;
  clearCallbackParams();
  return url.searchParams.get('error_description') || err;
}

function clearCallbackParams(): void {
  const url = new URL(window.location.href);
  ['code', 'state', 'error', 'error_description'].forEach(k =>
    url.searchParams.delete(k)
  );
  window.history.replaceState({}, '', url.toString());
}

/** Demo identity used when no Roblox client ID is configured. */
export function demoUser(username: string): RobloxUser {
  const clean = username.trim().slice(0, 20) || 'Gardener';
  let hash = 0;
  for (let i = 0; i < clean.length; i++) {
    hash = (hash * 31 + clean.charCodeAt(i)) >>> 0;
  }
  return {
    id: `demo-${hash.toString(36)}`,
    username: clean,
    displayName: clean,
    avatar: null,
    demo: true,
  };
}
