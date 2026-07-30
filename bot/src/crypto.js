import { createCipheriv, createDecipheriv, randomBytes, createHmac, timingSafeEqual } from 'node:crypto';

const ALGORITHM = 'aes-256-gcm';
const IV_LENGTH = 12;

/**
 * OAuth access/refresh tokens let anyone holding them act as the user, so they
 * never touch disk in plaintext.
 */
export function encrypt(plaintext, key) {
  const iv = randomBytes(IV_LENGTH);
  const cipher = createCipheriv(ALGORITHM, key, iv);
  const ciphertext = Buffer.concat([cipher.update(plaintext, 'utf8'), cipher.final()]);
  return [iv.toString('base64'), cipher.getAuthTag().toString('base64'), ciphertext.toString('base64')].join('.');
}

export function decrypt(payload, key) {
  const [iv, tag, ciphertext] = payload.split('.');
  if (!iv || !tag || !ciphertext) throw new Error('Malformed encrypted payload');
  const decipher = createDecipheriv(ALGORITHM, key, Buffer.from(iv, 'base64'));
  decipher.setAuthTag(Buffer.from(tag, 'base64'));
  return Buffer.concat([decipher.update(Buffer.from(ciphertext, 'base64')), decipher.final()]).toString('utf8');
}

const STATE_TTL_MS = 10 * 60 * 1000;

/** Stateless CSRF token for the OAuth round trip, so a restart mid-flow is harmless. */
export function signState(key) {
  const nonce = randomBytes(16).toString('base64url');
  const issuedAt = Date.now().toString(36);
  const body = `${nonce}.${issuedAt}`;
  const signature = createHmac('sha256', key).update(body).digest('base64url');
  return `${body}.${signature}`;
}

export function verifyState(state, key) {
  if (typeof state !== 'string') return false;
  const parts = state.split('.');
  if (parts.length !== 3) return false;
  const [nonce, issuedAt, signature] = parts;

  const expected = createHmac('sha256', key).update(`${nonce}.${issuedAt}`).digest('base64url');
  const a = Buffer.from(signature);
  const b = Buffer.from(expected);
  if (a.length !== b.length || !timingSafeEqual(a, b)) return false;

  const age = Date.now() - parseInt(issuedAt, 36);
  return Number.isFinite(age) && age >= 0 && age < STATE_TTL_MS;
}
