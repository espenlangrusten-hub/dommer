import 'dotenv/config';

function required(name) {
  const value = process.env[name];
  if (!value) throw new Error(`Missing required environment variable: ${name}`);
  return value;
}

const encryptionKey = required('ENCRYPTION_KEY');
if (!/^[0-9a-f]{64}$/i.test(encryptionKey)) {
  throw new Error('ENCRYPTION_KEY must be 64 hex characters (32 bytes). Generate one with: npm run gen-key');
}

const allowedTargetGuilds = (process.env.ALLOWED_TARGET_GUILDS ?? '')
  .split(',')
  .map((id) => id.trim())
  .filter(Boolean);

if (allowedTargetGuilds.length === 0) {
  throw new Error(
    'ALLOWED_TARGET_GUILDS must list at least one guild ID. Members consent to being added ' +
      'to those specific servers, so the bot refuses to run without the list.',
  );
}

export const config = {
  token: required('DISCORD_TOKEN'),
  clientId: required('DISCORD_CLIENT_ID'),
  clientSecret: required('DISCORD_CLIENT_SECRET'),
  redirectUri: required('OAUTH_REDIRECT_URI'),
  publicBaseUrl: (process.env.PUBLIC_BASE_URL ?? '').replace(/\/$/, '') || required('OAUTH_REDIRECT_URI'),
  encryptionKey: Buffer.from(encryptionKey, 'hex'),
  allowedTargetGuilds,
  dataFile: process.env.DATA_FILE ?? './data/consents.json',
  port: Number(process.env.PORT ?? 3000),
  devGuildId: process.env.DEV_GUILD_ID || null,
};

export const API = 'https://discord.com/api/v10';
