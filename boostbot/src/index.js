const { Client, GatewayIntentBits } = require("discord.js");
const config = require("./config");
const boostorder = require("./commands/boostorder");
const setupChannels = require("./commands/setupChannels");
const flow = require("./lib/flow");

process.on("unhandledRejection", (err) => {
  console.error("Unhandled rejection:", err);
});

const client = new Client({ intents: [GatewayIntentBits.Guilds] });

client.once("ready", () => {
  console.log(`Logged in as ${client.user.tag}`);
});

client.on("interactionCreate", async (interaction) => {
  try {
    if (interaction.isChatInputCommand()) {
      if (interaction.commandName === "boostorder") return boostorder.run(interaction);
      if (interaction.commandName === "setup-channels") return setupChannels.run(interaction);
      return;
    }

    if (interaction.isStringSelectMenu()) {
      const [name, arg] = interaction.customId.split(":");
      if (name === "boost_duration") return flow.handleDurationSelect(interaction);
      if (name === "boost_package") return flow.handlePackageSelect(interaction, arg);
      return;
    }

    if (interaction.isButton()) {
      const [name, ...args] = interaction.customId.split(":");
      if (name === "pay") return flow.handlePayButton(interaction, args[0], args[1]);
      if (name === "capture") return flow.handleCaptureButton(interaction, args[0]);
      if (name === "admin_confirm") return flow.handleAdminConfirm(interaction, args[0]);
      if (name === "admin_decline") return flow.handleAdminDecline(interaction, args[0]);
      if (name === "fulfill_sent") return flow.handleFulfillSent(interaction, args[0]);
      if (name === "fulfill_delayed") return flow.handleFulfillDelayed(interaction, args[0]);
      return;
    }
  } catch (err) {
    console.error(err);
    const payload = { content: "Something went wrong. Please try again.", ephemeral: true };
    if (interaction.deferred || interaction.replied) {
      await interaction.followUp(payload).catch(() => {});
    } else {
      await interaction.reply(payload).catch(() => {});
    }
  }
});

client.login(config.discordToken);
