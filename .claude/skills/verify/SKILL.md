---
name: verify
description: Build, serve, and drive the Garden Shop site (CRA + GitHub Pages) with Playwright to verify changes end-to-end.
---

# Verify Garden Shop

The app is Create React App with `homepage: /dommer/`, so the build expects to be
served under a `/dommer/` path prefix. Hash routing (`#/shop`, `#/cart`, `#/checkout`,
`#/claim`, `#/admin`) — no server rewrites needed.

## Build & serve

```bash
CI=true npm run build
mkdir -p /tmp/site && ln -sfn "$PWD/build" /tmp/site/dommer
(cd /tmp/site && python3 -m http.server 8734 &)
# site at http://localhost:8734/dommer/
```

## Drive (headless chromium)

Playwright is not a repo dependency — `npm install playwright` in a scratch dir and
launch with `executablePath: '/opt/pw-browsers/chromium-1194/chrome-linux/chrome'`
(the bare `/opt/pw-browsers/chromium` symlink is not the executable).

Flows worth driving: hero → Shop Now scroll → add to cart (badge + toast) →
cart qty controls → checkout form → order confirmation (grab `.order-id`) →
`#/claim` with that ID + email → `#/admin` (passcode `garden123` in `src/store.tsx`)
shows online/visitors/orders tiles and the orders table.

## Gotchas

- Cart/orders/stats live in localStorage; each fresh browser context starts clean.
- The sandbox agent-proxy resets chromium's connection to external hosts even with
  `proxy:` configured — fonts are therefore self-hosted in `src/fonts/` (don't move
  them back to Google Fonts CDN). Use `proxy: { server: process.env.HTTPS_PROXY,
  bypass: 'localhost' }` if external requests are ever needed.
