import { readFile, writeFile, rename, mkdir } from 'node:fs/promises';
import { dirname } from 'node:path';
import { encrypt, decrypt } from './crypto.js';

/**
 * Consent records, keyed by Discord user ID. A JSON file is plenty for the
 * scale this bot operates at (one community, hundreds of members) and keeps the
 * install free of native dependencies.
 */
export class ConsentStore {
  #path;
  #key;
  #records = new Map();
  #writeChain = Promise.resolve();

  constructor(path, encryptionKey) {
    this.#path = path;
    this.#key = encryptionKey;
  }

  async load() {
    try {
      const raw = await readFile(this.#path, 'utf8');
      for (const record of JSON.parse(raw)) {
        this.#records.set(record.userId, record);
      }
    } catch (error) {
      if (error.code !== 'ENOENT') throw error;
    }
    return this;
  }

  /** Serialised so concurrent OAuth callbacks can't interleave and lose a record. */
  #persist() {
    this.#writeChain = this.#writeChain.then(async () => {
      const temp = `${this.#path}.tmp`;
      await mkdir(dirname(this.#path), { recursive: true });
      await writeFile(temp, JSON.stringify([...this.#records.values()], null, 2), 'utf8');
      await rename(temp, this.#path);
    });
    return this.#writeChain;
  }

  async upsert({ userId, username, accessToken, refreshToken, expiresIn }) {
    const existing = this.#records.get(userId);
    this.#records.set(userId, {
      userId,
      username,
      accessToken: encrypt(accessToken, this.#key),
      refreshToken: encrypt(refreshToken, this.#key),
      expiresAt: Date.now() + expiresIn * 1000,
      authorizedAt: existing?.authorizedAt ?? new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    });
    await this.#persist();
  }

  async updateTokens(userId, { accessToken, refreshToken, expiresIn }) {
    const record = this.#records.get(userId);
    if (!record) return;
    record.accessToken = encrypt(accessToken, this.#key);
    record.refreshToken = encrypt(refreshToken, this.#key);
    record.expiresAt = Date.now() + expiresIn * 1000;
    record.updatedAt = new Date().toISOString();
    await this.#persist();
  }

  async delete(userId) {
    const existed = this.#records.delete(userId);
    if (existed) await this.#persist();
    return existed;
  }

  get(userId) {
    return this.#records.get(userId) ?? null;
  }

  has(userId) {
    return this.#records.has(userId);
  }

  all() {
    return [...this.#records.values()];
  }

  get size() {
    return this.#records.size;
  }

  decryptAccessToken(record) {
    return decrypt(record.accessToken, this.#key);
  }

  decryptRefreshToken(record) {
    return decrypt(record.refreshToken, this.#key);
  }
}
