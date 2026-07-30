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

At <https://discord.com/developers/applications>, click **New Application**.
You'll need two values from it, and the wizard tells you where to click:

- **Bot** tab → **Reset Token**. No privileged intents are needed — leave them off.
- **OAuth2** tab → **Client Secret** → **Reset Secret**.

### 2. Invite the bot to *both* servers

**OAuth2 → URL Generator**, tick scopes `bot` and `applications.commands`, then
tick the **Create Instant Invite** permission. That permission is what
authorizes the add-member call — without it in the *target* server, `/join`
fails with a 403. Open the generated URL once per server.

### 3. Run the wizard

```bash
cd bot
npm install
npm run setup
```

It validates your bot token against Discord on the spot, detects your client ID
automatically, lists the servers the bot is in so you can pick the target from a
menu (flagging any that lack **Create Invite**), generates the encryption key,
and writes `.env` for you. It also prints the exact redirect URL to paste into
**OAuth2 → Redirects** — that has to match character for character.

### 4. Check and start

```bash
npm run doctor   # verifies token, permissions, and redirect URI
npm start
```

Slash commands register themselves on startup, so there's no separate deploy
step. `npm run doctor` is the thing to run whenever something behaves oddly — it
checks each external dependency and tells you which one is wrong.

## Making it reachable

The wizard defaults to `http://localhost:3000`, and Discord does accept
`http://localhost` redirect URIs, so **you can test the whole flow on your own
machine with no tunnel**. Authorize yourself, then run `/join` and watch it work.

For other members to opt in, though, the page has to be reachable from *their*
browsers, so localhost isn't enough. Two options:

**Quick tunnel** — good for a one-off migration you supervise:

```bash
cloudflared tunnel --url http://localhost:3000
```

Put the printed `https://…trycloudflare.com` URL into `PUBLIC_BASE_URL`, add
`<that URL>/callback` to the portal's redirect list, and restart. Note the URL
changes every time you restart the tunnel, and you have to update both places
again — which is why this suits a single sitting rather than a permanent setup.

**Deploy it** — for something that stays up. A `Dockerfile` is included:

```bash
docker build -t join-bot .
docker run -d --env-file .env -p 3000:3000 -v join-bot-data:/app/data join-bot
```

Mount the volume. `data/consents.json` holds every authorization you've
collected, and losing it means asking everyone to opt in again. Set
`PUBLIC_BASE_URL` to your real domain and register the matching `/callback`.

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
rejection), and OAuth state signing. The parts that talk to Discord — token
exchange, member adds, rate-limit retries — aren't covered by automated tests;
`npm run doctor` is what exercises those against the live API.

## Relationship to the rest of this repo

This directory is self-contained and has its own `package.json`. The root
Create React App project and its GitHub Pages deploy don't build, bundle, or
depend on anything in here.
