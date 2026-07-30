import { config, API } from './config.js';
import { getFreshAccessToken } from './oauth.js';

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

/** Small gap between calls so a normal run never trips the rate limiter. */
const PACING_MS = 350;
const MAX_RATE_LIMIT_RETRIES = 5;

/**
 * PUT /guilds/{guild}/members/{user} adds a user who has granted guilds.join.
 * 201 means added, 204 means they were already in the server.
 */
async function addMember(guildId, userId, accessToken) {
  for (let attempt = 0; attempt <= MAX_RATE_LIMIT_RETRIES; attempt += 1) {
    const response = await fetch(`${API}/guilds/${guildId}/members/${userId}`, {
      method: 'PUT',
      headers: {
        Authorization: `Bot ${config.token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ access_token: accessToken }),
    });

    if (response.status === 201) return { status: 'added' };
    if (response.status === 204) return { status: 'already_member' };

    if (response.status === 429) {
      const body = await response.json().catch(() => ({}));
      await sleep(Math.ceil((body.retry_after ?? 1) * 1000) + 100);
      continue;
    }

    const detail = await response.text().catch(() => '');
    if (response.status === 403) {
      return { status: 'failed', reason: 'Bot lacks Create Invite permission in the target server' };
    }
    if (response.status === 401) {
      return { status: 'revoked', reason: 'Authorization was revoked by the user' };
    }
    return { status: 'failed', reason: `HTTP ${response.status} ${detail}`.trim() };
  }

  return { status: 'failed', reason: 'Gave up after repeated rate limiting' };
}

/**
 * Walks every consenting member and adds them to the target guild.
 * `onProgress` is invoked with the running tally so callers can report live.
 */
export async function joinAll(store, guildId, { onProgress } = {}) {
  const records = store.all();
  const results = { added: [], alreadyMember: [], revoked: [], failed: [], total: records.length };

  for (const [index, record] of records.entries()) {
    const accessToken = await getFreshAccessToken(store, record);

    if (!accessToken) {
      results.revoked.push(record);
      await store.delete(record.userId);
    } else {
      const outcome = await addMember(guildId, record.userId, accessToken);

      if (outcome.status === 'added') results.added.push(record);
      else if (outcome.status === 'already_member') results.alreadyMember.push(record);
      else if (outcome.status === 'revoked') {
        results.revoked.push(record);
        await store.delete(record.userId);
      } else {
        results.failed.push({ ...record, reason: outcome.reason });
      }
    }

    onProgress?.({ ...results, processed: index + 1 });
    if (index < records.length - 1) await sleep(PACING_MS);
  }

  return results;
}
