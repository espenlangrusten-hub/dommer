# Garden Rewards — referrals & rewards for Grow a Garden 2

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

The currency is **credits**.

| Action | Reward |
| --- | --- |
| Signing in the first time | 2 credits |
| Signing in through someone's invite link | a free 1x Super Sprinkler to you, 2 credits to them |
| Watching an ad | 2 credits, 1 minute cooldown, 20 per day |

Earn rates live at the top of `src/lib/store.ts`; the reward catalogue and its
prices live in `src/lib/rewards.ts`. At the current rates a maxed-out day of
ads is 40 credits, so the 75-credit Raccoon is about two days of watching, or
38 invites.

### Garden Valley catalogue

| Reward | Cost |
| --- | --- |
| 1x Super Sprinkler | 2 |
| 1x Super Watering Can | 3 |
| 1x Dragon's Breath Seed | 5 |
| 1x Unicorn | 10 |
| 1x Golden Dragonfly | 10 |
| 1x Star Fruit Seed | 15 |
| 1x Raccoon | 75 |

### Reward artwork

Each reward looks for `public/rewards/<id>.png`, where `<id>` is the reward's
`id` in `src/lib/rewards.ts`:

```
public/rewards/super-sprinkler.png
public/rewards/super-watering-can.png
public/rewards/dragons-breath.png
public/rewards/unicorn.png
public/rewards/golden-dragonfly.png
public/rewards/star-fruit.png
public/rewards/raccoon.png
```

Square images look best — they're cropped to a square tile. Any file that is
missing falls back to an emoji stand-in, so the shop never shows a broken
image; `golden-dragonfly.png` and `raccoon.png` are still stand-ins.

## Sending out the rewards

`#admin` (the "Claims" link in the header) lists every claim with the Roblox
username, the Roblox user ID, the reward, the claim code and the date, so items
can be delivered in-game. Rows can be ticked off as sent, and the whole list
copies out as CSV.

Restrict it with `REACT_APP_ADMIN_ROBLOX_IDS` — a comma-separated list of
Roblox user IDs. Leaving it empty lets any signed-in player open the page.
Client-side gating is a speed bump, not security; it is only adequate because
there is no shared data behind it yet.

**The page reads localStorage, so it only shows claims made in the browser you
open it in.** That is the honest limit of a site with no server: other people's
redemptions live in their own browsers. Two ways out:

1. Set `REACT_APP_CLAIM_WEBHOOK` to a Discord webhook URL. Every claim is
   posted there the moment it happens, so nothing is missed. The URL is visible
   in the public bundle, so anyone can find it and post junk to that channel.
2. Build the backend (below). Then the admin page reads one shared list, and
   balances stop being editable by the players who own them.

## Ads

There are two separate ad surfaces, and they are not the same product:

**Display ads (sidebar).** A 300px rail on wide screens, and a responsive
banner below the cards on narrow ones. Both are AdSense units driven by
`REACT_APP_ADSENSE_CLIENT`, `REACT_APP_ADSENSE_SLOT_SIDEBAR` and
`REACT_APP_ADSENSE_SLOT_INLINE` (see `.env.example`). Without a publisher ID
they render as labelled placeholders, so the site is safe to deploy before the
account exists. Requests are set to non-personalised.

Before these can serve for real:

- **ads.txt** — AdSense will ask for a `public/ads.txt` containing
  `google.com, pub-0000000000000000, DIRECT, f08c47fec0942fa0` with your real
  publisher ID. It is deliberately not committed: an ads.txt with no valid
  records marks *every* seller unauthorised and can block monetisation
  outright.
- **A consent banner** — EEA/UK traffic needs a Google-certified CMP before
  AdSense serves anything. Norway is in the EEA, so this is required, not
  optional.
- **Child-directed treatment** — the audience skews young; this is configured
  on the AdSense account.

**Rewarded ads (the watch-and-earn button).** Still the placeholder described
below. AdSense does not offer a rewarded format for the open web, and its
policies prohibit rewarding users for viewing ads — so the rewarded unit has to
come from a network built for incentivised traffic (AdGate, Ayet, Torox,
Adsterra, or Ad Manager rewarded for web games). Note that running incentivised
traffic and AdSense units on the same page carries a real risk to the AdSense
account.

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
