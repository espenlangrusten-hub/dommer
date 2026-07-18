# Garden Shop 🌱

A dark-themed store front for Grow a Garden items — built with React (Create React App)
and deployed to GitHub Pages.

## Features

- **Hero landing page** with the dripping-red Garden Shop logo, trust stats and a
  Shop Now button that scrolls into the store.
- **Best Sellers + New Items** product grids with pixel-art product images, discount
  badges, ~2 min delivery tags, and game filter tabs (Grow A Garden 2 / Steal A
  Brainrot / Grow A Garden), plus a View All page with search.
- **Working shopping cart** (add, remove, change quantity — persisted in the browser)
  and a **checkout** flow that generates an order ID.
- **Claim Order** page: look up an order with order ID + email.
- **Owner dashboard** at `#/admin` showing live "online right now", visitors today,
  total visitors, order count, revenue and the full order list.
  - Passcode is `ADMIN_PASSCODE` in `src/store.tsx` — change it before going live.
  - Stats are stored in localStorage (static hosting, no backend), so they cover one
    browser at a time. Hook up a small backend (e.g. Firebase) for global stats.

## Development

```bash
npm install
npm start        # dev server at http://localhost:3000
npm run build    # production build (served under /dommer/)
```

Pushes to `main` deploy automatically to GitHub Pages via
`.github/workflows/deploy.yml`.

## Custom domain (gardenshop.gg)

1. Buy `gardenshop.gg` at a registrar that supports `.gg` (e.g. Namecheap or Porkbun).
2. In the repo settings → Pages, set the custom domain to `gardenshop.gg`.
3. At the registrar, add a `CNAME`/`ALIAS` record pointing to
   `espenlangrusten-hub.github.io` (GitHub will also ask for a `CNAME` file in the
   build — add `public/CNAME` once the domain is active).
4. Change `homepage` in `package.json` to `https://gardenshop.gg` and redeploy.

Not affiliated with Roblox Corporation.
