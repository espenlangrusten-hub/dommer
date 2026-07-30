/**
 * Preflight check: verifies every external thing the bot depends on before you
 * try to use it in front of people.
 */
const green = (text) => `\x1b[32m${text}\x1b[0m`;
const red = (text) => `\x1b[31m${text}\x1b[0m`;
const dim = (text) => `\x1b[2m${text}\x1b[0m`;

const API = 'https://discord.com/api/v10';
const CREATE_INSTANT_INVITE = 1n << 0n;

let failures = 0;
const pass = (message) => console.log(`  ${green('✓')} ${message}`);
const fail = (message, hint) => {
  failures += 1;
  console.log(`  ${red('✗')} ${message}`);
  if (hint) console.log(`    ${dim(hint)}`);
};

console.log('\nChecking configuration…\n');

let config;
try {
  ({ config } = await import('./config.js'));
  pass('.env loads and all required values are present');
} catch (error) {
  fail(error.message, 'Run  npm run setup  to generate a .env file.');
  console.log(`\n${red('1 problem')} — nothing else can be checked until this is fixed.\n`);
  process.exit(1);
}

const identity = await fetch(`${API}/users/@me`, { headers: { Authorization: `Bot ${config.token}` } });
if (identity.ok) {
  const bot = await identity.json();
  pass(`bot token is valid (${bot.username})`);
  if (bot.id !== config.clientId) {
    fail(
      `DISCORD_CLIENT_ID (${config.clientId}) does not match this bot's application ID (${bot.id})`,
      'Slash command registration will fail. Re-run  npm run setup.',
    );
  } else {
    pass('client ID matches the bot token');
  }
} else {
  fail(`bot token rejected by Discord (HTTP ${identity.status})`, 'Reset it under your app → Bot, then re-run  npm run setup.');
}

const guildResponse = await fetch(`${API}/users/@me/guilds`, { headers: { Authorization: `Bot ${config.token}` } });
if (guildResponse.ok) {
  const guilds = await guildResponse.json();
  for (const id of config.allowedTargetGuilds) {
    const guild = guilds.find((candidate) => candidate.id === id);
    if (!guild) {
      fail(`not a member of allowlisted server ${id}`, 'Invite the bot to that server, or drop it from ALLOWED_TARGET_GUILDS.');
    } else if ((BigInt(guild.permissions) & CREATE_INSTANT_INVITE) === 0n) {
      fail(`missing "Create Invite" in ${guild.name}`, '/join returns 403 without it. Grant the permission in Server Settings → Roles.');
    } else {
      pass(`target server ready: ${guild.name}`);
    }
  }
} else {
  fail(`could not list the bot's servers (HTTP ${guildResponse.status})`);
}

if (config.redirectUri === `${config.publicBaseUrl}/callback`) {
  pass('redirect URI matches the public base URL');
} else {
  fail(
    `OAUTH_REDIRECT_URI (${config.redirectUri}) is not ${config.publicBaseUrl}/callback`,
    'These must agree, and the redirect URI must be registered in the portal verbatim.',
  );
}

if (config.publicBaseUrl.startsWith('http://localhost') || config.publicBaseUrl.startsWith('http://127.0.0.1')) {
  console.log(`  ${dim('!')} ${dim('running on localhost — only you can reach the opt-in page.')}`);
  console.log(`    ${dim('Fine for testing; other members need a public URL. See the README.')}`);
}

console.log(
  failures === 0
    ? `\n${green('All checks passed.')} Start the bot with  npm start\n`
    : `\n${red(`${failures} problem${failures === 1 ? '' : 's'} found.`)} Fix the above, then re-run  npm run doctor\n`,
);
process.exit(failures === 0 ? 0 : 1);
