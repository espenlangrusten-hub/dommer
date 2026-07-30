import { createInterface } from 'node:readline/promises';
import { stdin as input, stdout as output } from 'node:process';
import { writeFile, readFile } from 'node:fs/promises';
import { randomBytes } from 'node:crypto';

const API = 'https://discord.com/api/v10';
const CREATE_INSTANT_INVITE = 1n << 0n;

const bold = (text) => `\x1b[1m${text}\x1b[0m`;
const dim = (text) => `\x1b[2m${text}\x1b[0m`;
const green = (text) => `\x1b[32m${text}\x1b[0m`;
const red = (text) => `\x1b[31m${text}\x1b[0m`;
const yellow = (text) => `\x1b[33m${text}\x1b[0m`;

const rl = createInterface({ input, output });

// Ctrl-C / Ctrl-D mid-wizard should read as "cancelled". `finished` is set
// before any deliberate exit so this never masks a real error on the way out.
let finished = false;
rl.on('close', () => {
  if (!finished) {
    console.log('\n\n  Setup cancelled — no .env was written.\n');
    process.exit(1);
  }
});

function exit(code) {
  finished = true;
  rl.close();
  process.exit(code);
}

async function ask(question, fallback = '') {
  const answer = (await rl.question(fallback ? `${question} ${dim(`[${fallback}]`)} ` : `${question} `)).trim();
  return answer || fallback;
}

/** Never throws — a blocked network and a bad token need different advice. */
async function discordGet(path, token) {
  try {
    const response = await fetch(`${API}${path}`, { headers: { Authorization: `Bot ${token}` } });
    if (response.ok) return { ok: true, data: await response.json() };
    return { ok: false, reason: `Discord rejected the request (HTTP ${response.status})` };
  } catch (error) {
    return { ok: false, reason: `Could not reach discord.com — ${error.message}`, network: true };
  }
}

async function main() {
  console.log(`\n${bold('dommer-join-bot setup')}\n`);
  console.log('This writes a .env file for you. Have the Discord developer portal open:');
  console.log(dim('  https://discord.com/developers/applications\n'));

  // --- Bot token, validated live ---------------------------------------------
  console.log(bold('1. Bot token'));
  console.log(dim('   Your app → Bot → Reset Token → copy.\n'));

  let token;
  let identity;
  for (;;) {
    token = await ask('   Paste the bot token:');
    if (!token) continue;

    const result = await discordGet('/users/@me', token);
    if (result.ok) {
      identity = result.data;
      break;
    }

    console.log(red(`   ${result.reason}`));
    if (result.network) {
      console.log(dim('   Check your internet connection, then try again.\n'));
    } else {
      console.log(dim('   Make sure you copied the bot token, not the client secret.\n'));
    }
  }
  console.log(green(`   ✓ Logged in as ${identity.username}\n`));

  // The bot user's ID is the application ID, so there is nothing to ask here.
  const clientId = identity.id;
  console.log(bold('2. Client secret'));
  console.log(dim('   Your app → OAuth2 → Client Secret → Reset Secret → copy.'));
  console.log(dim(`   (Client ID detected automatically: ${clientId})\n`));

  let clientSecret = '';
  while (!clientSecret) clientSecret = await ask('   Paste the client secret:');

  // --- Target servers --------------------------------------------------------
  console.log(`\n${bold('3. Target server')}`);
  console.log(dim('   Which server should /join add people to?\n'));

  const guildResult = await discordGet('/users/@me/guilds', token);
  if (!guildResult.ok) {
    console.log(red(`   ${guildResult.reason}\n`));
    exit(1);
  }

  const guilds = guildResult.data;
  if (guilds.length === 0) {
    console.log(red('   This bot is not in any servers yet.'));
    console.log('   Invite it to both servers first, then re-run setup. See the README for the invite URL.\n');
    exit(1);
  }

  guilds.forEach((guild, index) => {
    const canInvite = (BigInt(guild.permissions) & CREATE_INSTANT_INVITE) !== 0n;
    console.log(
      `   ${String(index + 1).padStart(2)}. ${guild.name} ${dim(`(${guild.id})`)} ` +
        (canInvite ? green('✓') : red('✗ missing Create Invite')),
    );
  });

  let targets = [];
  while (targets.length === 0) {
    const picked = await ask('\n   Enter the number(s), comma-separated:');
    targets = picked
      .split(',')
      .map((part) => guilds[Number(part.trim()) - 1])
      .filter(Boolean);
    if (targets.length === 0) console.log(red('   No valid selection.'));
  }

  for (const guild of targets) {
    if ((BigInt(guild.permissions) & CREATE_INSTANT_INVITE) === 0n) {
      console.log(yellow(`   ! ${guild.name} is missing "Create Invite" — /join will fail until you grant it.`));
    }
  }
  console.log(green(`   ✓ Target(s): ${targets.map((guild) => guild.name).join(', ')}\n`));

  // --- Where the opt-in page lives -------------------------------------------
  console.log(bold('4. Where will the opt-in page be reachable?'));
  console.log(dim('   localhost is fine to test the flow yourself.'));
  console.log(dim('   To let other members opt in, this must be a public URL (see README).\n'));

  const port = await ask('   Port:', '3000');
  const baseUrl = (await ask('   Public base URL:', `http://localhost:${port}`)).replace(/\/$/, '');
  const redirectUri = `${baseUrl}/callback`;

  console.log(`\n   ${bold('Add this exact URL')} to your app → OAuth2 → Redirects:`);
  console.log(`   ${green(redirectUri)}\n`);
  await ask(dim('   Press Enter once you have added and saved it.'));

  // --- Write it out ----------------------------------------------------------
  try {
    await readFile('.env', 'utf8');
    const overwrite = await ask(yellow('   .env already exists. Overwrite? (y/N)'), 'N');
    if (!overwrite.toLowerCase().startsWith('y')) {
      console.log('\n   Cancelled — your existing .env was left alone.\n');
      exit(0);
    }
  } catch {
    // No existing .env, nothing to preserve.
  }

  const env = `# Generated by \`npm run setup\` on ${new Date().toISOString()}
DISCORD_TOKEN=${token}
DISCORD_CLIENT_ID=${clientId}
DISCORD_CLIENT_SECRET=${clientSecret}

OAUTH_REDIRECT_URI=${redirectUri}
PUBLIC_BASE_URL=${baseUrl}
PORT=${port}

ALLOWED_TARGET_GUILDS=${targets.map((guild) => guild.id).join(',')}

ENCRYPTION_KEY=${randomBytes(32).toString('hex')}
DATA_FILE=./data/consents.json
DEV_GUILD_ID=${guilds[0].id}
`;

  await writeFile('.env', env, { mode: 0o600 });
  console.log(green('   ✓ Wrote .env\n'));

  console.log(bold('Done. Start the bot with:\n'));
  console.log('   npm start\n');
  console.log(dim('Slash commands register automatically on startup.'));
  console.log(dim('Then run /post-opt-in in your server, and /join once people have authorized.\n'));

  exit(0);
}

try {
  await main();
} catch (error) {
  finished = true;
  console.error(red(`\n  Setup failed: ${error.message}\n`));
  process.exit(1);
}
