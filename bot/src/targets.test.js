import test from 'node:test';
import assert from 'node:assert/strict';
import { parseTarget } from './targets.js';
import { encrypt, decrypt, signState, verifyState } from './crypto.js';
import { randomBytes } from 'node:crypto';

test('parseTarget recognises raw guild IDs', () => {
  assert.deepEqual(parseTarget('123456789012345678'), { type: 'guildId', value: '123456789012345678' });
});

test('parseTarget recognises invite URLs', () => {
  for (const url of [
    'https://discord.gg/abc123',
    'http://discord.gg/abc123',
    'https://www.discord.gg/abc123',
    'https://discord.com/invite/abc123',
    'https://discordapp.com/invite/abc123/',
  ]) {
    assert.deepEqual(parseTarget(url), { type: 'inviteCode', value: 'abc123' }, url);
  }
});

test('parseTarget recognises bare invite codes', () => {
  assert.deepEqual(parseTarget('my-cool-server'), { type: 'inviteCode', value: 'my-cool-server' });
});

test('parseTarget rejects junk', () => {
  for (const input of ['', '   ', null, undefined, 'https://example.com/not-discord', 'a']) {
    assert.equal(parseTarget(input), null, JSON.stringify(input));
  }
});

test('encrypt/decrypt round-trips', () => {
  const key = randomBytes(32);
  const secret = 'an-oauth-access-token';
  const sealed = encrypt(secret, key);
  assert.notEqual(sealed, secret);
  assert.equal(decrypt(sealed, key), secret);
});

test('decrypt rejects a tampered payload', () => {
  const key = randomBytes(32);
  const sealed = encrypt('token', key);
  const [iv, tag, ciphertext] = sealed.split('.');
  const flipped = Buffer.from(ciphertext, 'base64');
  flipped[0] ^= 0xff;
  assert.throws(() => decrypt([iv, tag, flipped.toString('base64')].join('.'), key));
});

test('state signature round-trips and rejects tampering', () => {
  const key = randomBytes(32);
  const state = signState(key);
  assert.equal(verifyState(state, key), true);
  assert.equal(verifyState(state, randomBytes(32)), false);
  assert.equal(verifyState(`${state}x`, key), false);
  assert.equal(verifyState('nonsense', key), false);
  assert.equal(verifyState(undefined, key), false);
});
