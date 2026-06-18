# boostbot

Discord bot for selling server boost packages with real PayPal payment
verification (no manual "send money to this email" step — payments go
through PayPal's Orders API and are verified server-side before any order
is treated as paid).

## Order flow

1. `/boostorder` lets the customer pick a duration and package (price shown
   is double the listed base price, per the storefront packages).
2. The bot creates a real PayPal order and gives the customer an approval
   link. After paying, they click "I've completed payment."
3. The bot calls PayPal's capture API and only proceeds if the capture
   actually completed. If it didn't, the customer is told the truth — the
   payment failed.
4. On a successful capture, the order is posted to a private `orders`
   channel (visible only to the owner and the bot) with Confirm / Decline
   buttons.
   - **Confirm**: DMs the customer "order confirmed," and posts to a
     private `fulfillment` channel with Sent / Delayed buttons. Whichever
     one the owner picks, the customer gets a DM saying so.
   - **Decline**: automatically refunds the captured payment via PayPal
     and DMs the customer that they were refunded.

## Setup

1. `npm install`
2. Copy `.env.example` to `.env` and fill in:
   - Discord bot token/client id (from the Discord Developer Portal) and
     your guild id and Discord user id (`OWNER_ID`).
   - PayPal REST API credentials from developer.paypal.com. Use a sandbox
     app while testing (`PAYPAL_ENV=sandbox`), switch to a live app +
     `PAYPAL_ENV=live` when ready to take real payments.
3. `npm run deploy-commands` to register the slash commands.
4. `npm start` to run the bot.
5. In your server, run `/setup-channels` as the owner to create the
   private `orders` and `fulfillment` channels (only you and the bot can
   see them). This saves the channel ids to `runtime-config.json`.
6. Run `/boostorder` to test the full flow end-to-end with a sandbox
   PayPal account before going live.

Order state is stored in `orders.json` (created automatically) — fine for
a single bot instance; swap for a real database if you need multi-instance
or higher reliability.
