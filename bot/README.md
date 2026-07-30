# dommer-join-bot

A Discord bot that adds your members to another server you run, using Discord's
OAuth2 `guilds.join` scope.

## Read this part first

**A bot cannot move members who haven't authorized it.** There is no setting for
that, on your side or theirs. The only supported mechanism is `guilds.join`:
each member clicks an authorize link once and sees Discord's own consent screen
listing **"Join servers for you"**. After they accept, the bot can add that
member to a server via `PUT /guilds/{guild}/members/{user}`.

So the flow is:

1. You post the opt-in message with `/post-opt-in`.
2. Members click **Authorize** (one time, ~5 seconds).
3. You run `/join <invite link>` and everyone who opted in lands in the other server.

Members who never authorized are simply skipped. That's the API's rule, not a
restriction this bot adds — and it's what keeps the whole thing on the right
side of Discord's Terms of Service. Anything that promises to move *all* members
regardless of consent is a selfbot/raid tool: it needs other people's account
tokens, and it gets every account involved permanently banned.

### The allowlist

`ALLOWED_TARGET_GUILDS` is required and has no default. `/join` refuses any
server not on that list, and the opt-in message shows members exactly which
servers they're agreeing to. This keeps the consent you collect honest and
specific — it's the difference between this and the "backup bot" scams that farm
authorizations and then mass-add people to unrelated servers. Keep the list to
servers you actually run.

## Setup

### 1. Create the application

At <https://discord.com/developers/applications>, create an app, then:

- **Bot** tab → **Reset Token** → copy it into `DISCORD_TOKEN`.
  No privileged intents are needed; leave them all off.
- **OAuth2** tab → copy the **Client ID** and **Client Secret**.
- **OAuth2** tab → **Redirects** → add your callback URL, e.g.
  `https://your-domain.example/callback`. It must match `OAUTH_REDIRECT_URI`
  character for character.

### 2. Invite the bot to *both* servers

Use the OAuth2 URL Generator with scopes `bot` + `applications.commands`, and
the **Create Instant Invite** permission. That permission is what authorizes the
add-member call — without it in the *target* server, `/join` fails with a 403.

### 3. Configure and run

```bash
cd bot
npm install
cp .env.example .env
npm run gen-key          # paste the output into ENCRYPTION_KEY
# fill in the rest of .env
npm run deploy-commands  # registers the slash commands
npm start
```

Set `DEV_GUILD_ID` while testing so commands appear instantly instead of taking
up to an hour to propagate globally.

The web server must be reachable at `OAUTH_REDIRECT_URI` over HTTPS — Discord
won't redirect to bare `localhost`. For local testing, front it with a tunnel:

```bash
cloudflared tunnel --url http://localhost:3000
```

## Commands

| Command | Who | What it does |
| --- | --- | --- |
| `/opt-in` | everyone | Ephemeral authorize link for the person who ran it |
| `/post-opt-in` | Manage Server | Posts the public opt-in message with an authorize button |
| `/join <server>` | Administrator | Adds every authorized member to the target server |
| `/status` | Manage Server | How many members have authorized, and the allowed targets |
| `/forget-me` | everyone | Deletes that member's stored tokens |

`/join` accepts an invite link (`https://discord.gg/abc123`), a bare invite
code, or a raw guild ID. Invite codes are resolved to a guild ID and checked
against the allowlist before anything happens.

## Notes on behaviour

- **Already a member?** Discord returns 204 and the bot counts them under
  "already there" rather than treating it as an error.
- **Rate limits.** Calls are paced ~350ms apart, and 429s are retried using
  Discord's own `retry_after`. A run of a few hundred members takes a couple of
  minutes; progress updates appear in the reply.
- **Revoked access.** If a member removes the app, their refresh fails, and the
  bot drops their record automatically on the next run.
- **Token storage.** Access and refresh tokens are encrypted with AES-256-GCM
  before being written to `data/consents.json`. That file and your `.env` are
  gitignored — keep them that way, since the tokens act on behalf of your
  members. Losing `ENCRYPTION_KEY` means every stored consent has to be
  collected again.

## Tests

```bash
npm test
```

Covers invite/guild-ID parsing, the encryption round-trip (including tamper
rejection), and OAuth state signing.

## Relationship to the rest of this repo

This directory is self-contained and has its own `package.json`. The root
Create React App project and its GitHub Pages deploy don't build, bundle, or
depend on anything in here.
