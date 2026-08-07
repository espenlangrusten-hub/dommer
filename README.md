# Seed Circle — referrals & rewards for Grow a Garden 2

A fan site where players sign in with their Roblox account, invite friends,
watch rewarded ads, and trade the seeds they earn for in-game loot.

Built with Create React App + TypeScript, deployed as a static site to GitHub
Pages.

## Running it

```bash
npm install
npm start          # http://localhost:3000
npm run build      # production build into ./build
```

Pushing to `main` triggers `.github/workflows/deploy.yml`, which builds and
publishes to GitHub Pages.

## Sign in with Roblox

The site uses Roblox's OAuth 2.0 / OpenID Connect with PKCE, so it works
without a server or client secret.

1. Create an OAuth app at
   [create.roblox.com/dashboard/credentials](https://create.roblox.com/dashboard/credentials).
2. Set the app type to **public** (PKCE), scopes `openid` and `profile`.
3. Add the redirect URI — it has to match exactly, including the trailing
   slash:
   - `https://espenlangrusten-hub.github.io/dommer/`
   - `http://localhost:3000/` for local development
4. Copy `.env.example` to `.env` and set `REACT_APP_ROBLOX_CLIENT_ID`.

For the GitHub Pages build, add the same value as a repository variable and
pass it to the build step in the workflow.

**Without a client ID the site runs in demo mode** — you type a username and
everything else works locally. That's the state it ships in, so the site is
usable before the Roblox app exists.

If the browser blocks the token request with a CORS error, Roblox has not
whitelisted the origin for that app; the fix is to proxy
`POST /oauth/v1/token` through a small backend rather than to loosen anything
client-side.

## How the economy works

| Action | Reward |
| --- | --- |
| Signing in the first time | 100 seeds |
| Signing in through someone's invite link | 50 seeds to you, 250 to them |
| Watching an ad | 25 seeds, 1 minute cooldown, 20 per day |

Seeds are spent in the rewards shop, which mints a claim code the player
redeems in-game. Costs and items live in `src/lib/rewards.ts`.

## What is not real yet

Two things are deliberately stubbed, because both need infrastructure this
static site doesn't have:

**Referrals are stored in `localStorage`** (`src/lib/store.ts`). A friend who
opens your link on their own phone gets their bonus, but their signup can't
credit your browser, and nothing stops someone from editing their own balance.
Making this real needs a small backend with:

- a `users` table keyed by the Roblox `sub` from the ID token, so one Roblox
  account can be referred exactly once,
- a `referrals` table written server-side at first sign-in,
- a balance the client reads but never writes.

**The ad is a 30-second placeholder** (`src/components/AdModal.tsx`). Mount a
real rewarded unit in the `#ad-stage` element and call `onClaim` from the
network's reward callback instead of the timer. The cooldown, daily cap, and
payout logic around it stay as they are — but note that a client-side call is
still spoofable, so the payout should move behind the network's
server-side-verification callback at the same time as the backend above.

## Layout

```
src/
  App.tsx                  shell, session handling, wiring
  lib/roblox.ts            OAuth PKCE flow + demo identities
  lib/store.ts             balances, referral ledger, ad limits (localStorage)
  lib/rewards.ts           the reward catalogue
  components/              Login, AdModal, ReferralCard, RewardsShop, Leaderboard
```

Not affiliated with or endorsed by Roblox Corporation or the Grow a Garden
developers.
