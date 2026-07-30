import { config, API } from './config.js';

export const SCOPES = ['identify', 'guilds.join'];

export function buildAuthorizeUrl(state) {
  const params = new URLSearchParams({
    client_id: config.clientId,
    redirect_uri: config.redirectUri,
    response_type: 'code',
    scope: SCOPES.join(' '),
    state,
    prompt: 'consent',
  });
  return `https://discord.com/oauth2/authorize?${params}`;
}

async function tokenRequest(body) {
  const response = await fetch(`${API}/oauth2/token`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      client_id: config.clientId,
      client_secret: config.clientSecret,
      ...body,
    }),
  });

  if (!response.ok) {
    throw new Error(`Token request failed (${response.status}): ${await response.text()}`);
  }
  return response.json();
}

export function exchangeCode(code) {
  return tokenRequest({
    grant_type: 'authorization_code',
    code,
    redirect_uri: config.redirectUri,
  });
}

export function refreshAccessToken(refreshToken) {
  return tokenRequest({
    grant_type: 'refresh_token',
    refresh_token: refreshToken,
  });
}

export async function fetchCurrentUser(accessToken) {
  const response = await fetch(`${API}/users/@me`, {
    headers: { Authorization: `Bearer ${accessToken}` },
  });
  if (!response.ok) throw new Error(`Failed to fetch user (${response.status})`);
  return response.json();
}

const REFRESH_MARGIN_MS = 5 * 60 * 1000;

/**
 * Returns a usable access token, refreshing first when the stored one is close
 * to expiry. Returns null when the user has revoked the app, in which case the
 * caller should drop the record.
 */
export async function getFreshAccessToken(store, record) {
  if (record.expiresAt - Date.now() > REFRESH_MARGIN_MS) {
    return store.decryptAccessToken(record);
  }

  try {
    const tokens = await refreshAccessToken(store.decryptRefreshToken(record));
    await store.updateTokens(record.userId, {
      accessToken: tokens.access_token,
      refreshToken: tokens.refresh_token,
      expiresIn: tokens.expires_in,
    });
    return tokens.access_token;
  } catch {
    return null;
  }
}
