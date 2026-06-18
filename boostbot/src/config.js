require("dotenv").config();
const fs = require("fs");
const path = require("path");

const RUNTIME_CONFIG_PATH = path.join(__dirname, "..", "runtime-config.json");

function loadRuntimeConfig() {
  if (!fs.existsSync(RUNTIME_CONFIG_PATH)) return {};
  return JSON.parse(fs.readFileSync(RUNTIME_CONFIG_PATH, "utf8"));
}

function saveRuntimeConfig(partial) {
  const current = loadRuntimeConfig();
  const next = { ...current, ...partial };
  fs.writeFileSync(RUNTIME_CONFIG_PATH, JSON.stringify(next, null, 2));
  return next;
}

const runtime = loadRuntimeConfig();

module.exports = {
  discordToken: process.env.DISCORD_TOKEN,
  clientId: process.env.DISCORD_CLIENT_ID,
  guildId: process.env.DISCORD_GUILD_ID,
  ownerId: process.env.OWNER_ID,
  paypal: {
    clientId: process.env.PAYPAL_CLIENT_ID,
    clientSecret: process.env.PAYPAL_CLIENT_SECRET,
    env: process.env.PAYPAL_ENV || "sandbox",
  },
  get ordersChannelId() {
    return loadRuntimeConfig().ordersChannelId || process.env.ORDERS_CHANNEL_ID;
  },
  get fulfillmentChannelId() {
    return loadRuntimeConfig().fulfillmentChannelId || process.env.FULFILLMENT_CHANNEL_ID;
  },
  saveRuntimeConfig,
};
