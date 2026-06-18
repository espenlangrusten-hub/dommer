const { REST, Routes, SlashCommandBuilder } = require("discord.js");
const config = require("./config");

const commands = [
  new SlashCommandBuilder()
    .setName("boostorder")
    .setDescription("Order server boosts"),
  new SlashCommandBuilder()
    .setName("setup-channels")
    .setDescription(
      "(Owner only) Create the private orders/fulfillment channels"
    ),
].map((c) => c.toJSON());

const rest = new REST().setToken(config.discordToken);

(async () => {
  const route = config.guildId
    ? Routes.applicationGuildCommands(config.clientId, config.guildId)
    : Routes.applicationCommands(config.clientId);

  await rest.put(route, { body: commands });
  console.log("Slash commands registered.");
})().catch((err) => {
  console.error(err);
  process.exit(1);
});
