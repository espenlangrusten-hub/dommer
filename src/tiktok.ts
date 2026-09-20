/**
 * Best-effort TikTok profile lookup from a static site.
 *
 * TikTok has no public, CORS-enabled API for "username -> avatar", and a
 * browser cannot fetch tiktok.com directly (no Access-Control-Allow-Origin).
 * So we route the profile page through public CORS proxies and pull the
 * avatar out of the JSON that TikTok embeds in the HTML.
 *
 * This is best-effort by nature: TikTok often serves a bot-check page to
 * datacenter IPs, and the public proxies rate-limit. The UI therefore always
 * offers a manual fallback instead of pretending the lookup succeeded.
 *
 * For a reliable version, point REACT_APP_TIKTOK_API at your own endpoint
 * (see readAvatarApi below) - any small serverless function that returns
 * { avatarUrl, nickname, followerCount } for ?username=xyz.
 */

export type TikTokProfile = {
  username: string;
  profileUrl: string;
  avatarUrl?: string;
  nickname?: string;
  followerCount?: number;
  source: string;
};

const FETCH_TIMEOUT_MS = 12000;

/** Accepts "name", "@name" or a full profile URL. Returns null if invalid. */
export function normalizeUsername(raw: string): string | null {
  let value = raw.trim();
  if (!value) return null;

  const fromUrl = value.match(/tiktok\.com\/@([A-Za-z0-9._]+)/i);
  if (fromUrl) value = fromUrl[1];

  value = value.replace(/^@+/, '').trim();
  return /^[A-Za-z0-9._]{1,24}$/.test(value) ? value : null;
}

export function profileUrlFor(username: string): string {
  return `https://www.tiktok.com/@${username}`;
}

function decode(value: string): string {
  return value
    .replace(/\\u002[fF]/g, '/')
    .replace(/\\\//g, '/')
    .replace(/&amp;/g, '&')
    .replace(/\\"/g, '"');
}

function firstMatch(html: string, patterns: RegExp[]): string | undefined {
  for (const pattern of patterns) {
    const match = html.match(pattern);
    if (match && match[1]) return decode(match[1]);
  }
  return undefined;
}

/** Pulls avatar/nickname/followers out of a TikTok profile page. */
export function parseProfile(html: string): Omit<TikTokProfile, 'username' | 'profileUrl' | 'source'> {
  const avatarUrl = firstMatch(html, [
    /"avatarLarger":"([^"]+)"/,
    /"avatarMedium":"([^"]+)"/,
    /"avatarThumb":"([^"]+)"/,
    /<meta[^>]+property=["']og:image["'][^>]*content=["']([^"']+)["']/i,
    /<meta[^>]+content=["']([^"']+)["'][^>]*property=["']og:image["']/i,
    // r.jina.ai returns markdown, so the avatar shows up as an image link.
    /!\[[^\]]*\]\((https:\/\/[^\s)]*tiktokcdn[^\s)]*)\)/i,
    /(https:\/\/p\d{1,3}[-\w]*\.tiktokcdn[^"'\s)\\]+)/i,
  ]);

  const nickname = firstMatch(html, [
    /"nickname":"([^"]*)"/,
    /<meta[^>]+property=["']og:title["'][^>]*content=["']([^"']+?)\s*\(@/i,
  ]);

  const followers = firstMatch(html, [/"followerCount":(\d+)/]);

  return {
    avatarUrl,
    nickname: nickname || undefined,
    followerCount: followers ? Number(followers) : undefined,
  };
}

async function fetchText(url: string): Promise<string> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), FETCH_TIMEOUT_MS);
  try {
    const response = await fetch(url, { signal: controller.signal });
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    return await response.text();
  } finally {
    clearTimeout(timer);
  }
}

type Proxy = { name: string; build: (target: string) => string };

const PROXIES: Proxy[] = [
  { name: 'allorigins', build: t => `https://api.allorigins.win/raw?url=${encodeURIComponent(t)}` },
  { name: 'corsproxy.io', build: t => `https://corsproxy.io/?url=${encodeURIComponent(t)}` },
  { name: 'r.jina.ai', build: t => `https://r.jina.ai/${t}` },
];

/** Optional own backend: REACT_APP_TIKTOK_API=https://example.com/api/tiktok */
async function readAvatarApi(username: string): Promise<TikTokProfile | null> {
  const base = process.env.REACT_APP_TIKTOK_API;
  if (!base) return null;

  const separator = base.includes('?') ? '&' : '?';
  const raw = await fetchText(`${base}${separator}username=${encodeURIComponent(username)}`);
  const data = JSON.parse(raw);
  if (!data || !data.avatarUrl) return null;

  return {
    username,
    profileUrl: profileUrlFor(username),
    avatarUrl: data.avatarUrl,
    nickname: data.nickname,
    followerCount: typeof data.followerCount === 'number' ? data.followerCount : undefined,
    source: 'your API',
  };
}

export class LookupError extends Error {
  readonly attempts: string[];
  constructor(message: string, attempts: string[]) {
    super(message);
    this.name = 'LookupError';
    this.attempts = attempts;
  }
}

export async function lookupProfile(username: string): Promise<TikTokProfile> {
  const attempts: string[] = [];

  try {
    const fromApi = await readAvatarApi(username);
    if (fromApi) return fromApi;
  } catch (error) {
    attempts.push(`your API: ${(error as Error).message}`);
  }

  const target = profileUrlFor(username);

  for (const proxy of PROXIES) {
    try {
      const html = await fetchText(proxy.build(target));
      const parsed = parseProfile(html);
      if (parsed.avatarUrl) {
        return { username, profileUrl: target, source: proxy.name, ...parsed };
      }
      attempts.push(`${proxy.name}: no avatar in response (TikTok likely served a bot check)`);
    } catch (error) {
      attempts.push(`${proxy.name}: ${(error as Error).message}`);
    }
  }

  throw new LookupError(
    'Could not read the profile automatically. TikTok blocks direct browser requests, and every public proxy failed just now.',
    attempts
  );
}
