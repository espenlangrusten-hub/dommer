/**
 * All progress lives in localStorage — this site has no backend.
 *
 * That means referrals only credit across visits on the same browser. To make
 * referrals real (and cheat-proof), the ledger below has to move to a server
 * that verifies each Roblox account once; see README for the shape of it.
 */

import { RobloxUser } from "./roblox";

export type Referral = { code: string; username: string; at: number };
export type Claim = { id: string; reward: string; code: string; at: number };

export type Profile = {
  userId: string;
  username: string;
  credits: number;
  totalEarned: number;
  referralCode: string;
  referredBy: string | null;
  adsWatched: number;
  adsToday: number;
  adDay: string;
  lastAdAt: number;
  claims: Claim[];
};

export const AD_REWARD: number = 2;
export const REFERRAL_REWARD: number = 2;
export const WELCOME_BONUS: number = 2;
export const JOIN_REWARD = "1x Super Sprinkler"; // handed to anyone who joins via an invite
export const AD_COOLDOWN_MS = 60_000;
export const AD_DAILY_LIMIT = 20;
export const AD_DURATION_S = 30;

const PROFILE_KEY = "gg2.v2.profile";
const LEDGER_KEY = "gg2.v2.ledger";
const PENDING_REF_KEY = "gg2.pendingRef";
const SESSION_KEY = "gg2.v2.session";

type Ledger = Record<string, Referral[]>;

function read<T>(key: string, fallback: T): T {
  try {
    const raw = window.localStorage.getItem(key);
    return raw ? (JSON.parse(raw) as T) : fallback;
  } catch {
    return fallback;
  }
}

function write(key: string, value: unknown): void {
  try {
    window.localStorage.setItem(key, JSON.stringify(value));
  } catch {
    /* storage full or blocked (private mode) — progress just won't persist */
  }
}

/** "1 credit" / "2 credits" */
export function creditLabel(n: number): string {
  return `${n} ${n === 1 ? "credit" : "credits"}`;
}

export function today(): string {
  return new Date().toISOString().slice(0, 10);
}

export function referralCodeFor(userId: string): string {
  let hash = 2166136261;
  for (let i = 0; i < userId.length; i++) {
    hash ^= userId.charCodeAt(i);
    hash = Math.imul(hash, 16777619) >>> 0;
  }
  return `GG2-${hash.toString(36).toUpperCase().padStart(6, "0").slice(0, 6)}`;
}

export function referralLink(code: string): string {
  const base = process.env.PUBLIC_URL || "";
  return `${window.location.origin}${base}/?ref=${code}`;
}

/** Stashes ?ref=CODE from the URL so it survives the trip through Roblox login. */
export function captureRefFromUrl(): void {
  const url = new URL(window.location.href);
  const ref = url.searchParams.get("ref");
  if (!ref) return;
  if (!window.localStorage.getItem(PENDING_REF_KEY)) {
    write(PENDING_REF_KEY, ref.toUpperCase());
  }
  url.searchParams.delete("ref");
  window.history.replaceState({}, "", url.toString());
}

export function pendingRef(): string | null {
  return read<string | null>(PENDING_REF_KEY, null);
}

export function loadSession(): RobloxUser | null {
  return read<RobloxUser | null>(SESSION_KEY, null);
}

export function saveSession(user: RobloxUser | null): void {
  if (user) write(SESSION_KEY, user);
  else window.localStorage.removeItem(SESSION_KEY);
}

export function loadProfile(user: RobloxUser): Profile {
  const stored = read<Profile | null>(PROFILE_KEY + "." + user.id, null);
  if (stored) return rollDay(stored);

  const code = referralCodeFor(user.id);
  const ref = pendingRef();
  const fresh: Profile = {
    userId: user.id,
    username: user.username,
    credits: WELCOME_BONUS,
    totalEarned: WELCOME_BONUS,
    referralCode: code,
    referredBy: ref && ref !== code ? ref : null,
    adsWatched: 0,
    adsToday: 0,
    adDay: today(),
    lastAdAt: 0,
    claims: [],
  };

  if (fresh.referredBy) {
    creditReferrer(fresh.referredBy, {
      code,
      username: user.username,
      at: Date.now(),
    });
    // Invited players get the item itself rather than credits.
    fresh.claims = [makeClaim(JOIN_REWARD)];
    notifyClaim(fresh, fresh.claims[0]);
    window.localStorage.removeItem(PENDING_REF_KEY);
  }

  saveProfile(fresh);
  return fresh;
}

export function saveProfile(profile: Profile): void {
  write(PROFILE_KEY + "." + profile.userId, profile);
}

/** Resets the daily ad counter when the date has rolled over. */
function rollDay(profile: Profile): Profile {
  const day = today();
  if (profile.adDay === day) return profile;
  const rolled = { ...profile, adDay: day, adsToday: 0 };
  saveProfile(rolled);
  return rolled;
}

function creditReferrer(code: string, referral: Referral): void {
  const ledger = read<Ledger>(LEDGER_KEY, {});
  const list = ledger[code] || [];
  if (list.some((r) => r.code === referral.code)) return; // one credit per player
  ledger[code] = list.concat(referral);
  write(LEDGER_KEY, ledger);
}

export function referralsFor(code: string): Referral[] {
  return read<Ledger>(LEDGER_KEY, {})[code] || [];
}

/**
 * Referral credits are computed from the ledger rather than stored on the
 * profile, so invites that land while you're signed out still count.
 */
export function referralCredits(code: string): number {
  return referralsFor(code).length * REFERRAL_REWARD;
}

export function spendableCredits(profile: Profile): number {
  return profile.credits + referralCredits(profile.referralCode);
}

export function adReady(profile: Profile): {
  ok: boolean;
  waitMs: number;
  reason?: string;
} {
  if (profile.adsToday >= AD_DAILY_LIMIT) {
    return {
      ok: false,
      waitMs: 0,
      reason: "Daily ad limit reached — come back tomorrow.",
    };
  }
  const waitMs = Math.max(0, profile.lastAdAt + AD_COOLDOWN_MS - Date.now());
  if (waitMs > 0) return { ok: false, waitMs, reason: "Cooling down" };
  return { ok: true, waitMs: 0 };
}

export function grantAdReward(profile: Profile): Profile {
  const next: Profile = {
    ...rollDay(profile),
    credits: profile.credits + AD_REWARD,
    totalEarned: profile.totalEarned + AD_REWARD,
    adsWatched: profile.adsWatched + 1,
    adsToday: profile.adsToday + 1,
    lastAdAt: Date.now(),
  };
  saveProfile(next);
  return next;
}

function makeClaim(rewardName: string): Claim {
  return {
    id: `${Date.now()}-${Math.random().toString(36).slice(2, 8)}`,
    reward: rewardName,
    code: claimCode(),
    at: Date.now(),
  };
}

export function redeem(
  profile: Profile,
  rewardName: string,
  cost: number,
): Profile | null {
  if (spendableCredits(profile) < cost) return null;
  const claim = makeClaim(rewardName);
  const next: Profile = {
    ...profile,
    credits: profile.credits - cost,
    claims: [claim].concat(profile.claims).slice(0, 25),
  };
  saveProfile(next);
  notifyClaim(next, claim);
  return next;
}

function claimCode(): string {
  const alphabet = "ABCDEFGHJKMNPQRSTUVWXYZ23456789";
  const buf = new Uint8Array(9);
  window.crypto.getRandomValues(buf);
  let out = "";
  for (let i = 0; i < buf.length; i++) {
    if (i === 3 || i === 6) out += "-";
    out += alphabet[buf[i] % alphabet.length];
  }
  return out;
}

/* ------------------------------------------------------------------ *
 * Fulfilment — what the site owner needs to actually send the items.
 * ------------------------------------------------------------------ */

const FULFILLED_KEY = "gg2.v2.fulfilled";

export type ClaimRow = Claim & {
  userId: string;
  username: string;
  sent: boolean;
};

/**
 * Every claim stored in this browser, newest first.
 *
 * localStorage is per-browser, so this only sees players who redeemed on THIS
 * device. Set REACT_APP_CLAIM_WEBHOOK to get every claim pushed to you as it
 * happens, or move to the backend described in the README for a real record.
 */
export function allClaims(): ClaimRow[] {
  const fulfilled = read<Record<string, number>>(FULFILLED_KEY, {});
  const rows: ClaimRow[] = [];

  for (let i = 0; i < window.localStorage.length; i++) {
    const key = window.localStorage.key(i);
    if (!key || !key.startsWith(PROFILE_KEY + ".")) continue;
    const profile = read<Profile | null>(key, null);
    if (!profile) continue;
    for (const claim of profile.claims || []) {
      rows.push({
        ...claim,
        userId: profile.userId,
        username: profile.username,
        sent: Boolean(fulfilled[claim.code]),
      });
    }
  }

  return rows.sort((a, b) => b.at - a.at);
}

export function setFulfilled(code: string, sent: boolean): void {
  const fulfilled = read<Record<string, number>>(FULFILLED_KEY, {});
  if (sent) fulfilled[code] = Date.now();
  else delete fulfilled[code];
  write(FULFILLED_KEY, fulfilled);
}

export function claimsToCsv(rows: ClaimRow[]): string {
  const escape = (v: string) => `"${v.replace(/"/g, '""')}"`;
  const head = [
    "date",
    "roblox_user",
    "roblox_id",
    "reward",
    "claim_code",
    "sent",
  ];
  const body = rows.map((r) =>
    [
      new Date(r.at).toISOString(),
      r.username,
      r.userId,
      r.reward,
      r.code,
      r.sent ? "yes" : "no",
    ]
      .map(escape)
      .join(","),
  );
  return [head.join(","), ...body].join("\n");
}

/**
 * Pushes a claim to a webhook (a Discord webhook URL works as-is) so the owner
 * hears about redemptions made on other people's devices.
 *
 * The URL ships inside the JS bundle and is therefore public — anyone can read
 * it and post to it. It is a stopgap for a real backend, not a secret.
 */
export function notifyClaim(profile: Profile, claim: Claim): void {
  const url = process.env.REACT_APP_CLAIM_WEBHOOK;
  if (!url) return;

  const content =
    `**${profile.username}** (Roblox ID \`${profile.userId}\`) claimed ` +
    `**${claim.reward}** — code \`${claim.code}\``;

  fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      content,
      claim,
      user: profile.username,
      userId: profile.userId,
    }),
    keepalive: true,
  }).catch(() => {
    /* delivery is best-effort; the claim is still stored locally */
  });
}
