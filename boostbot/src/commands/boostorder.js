const {
  ActionRowBuilder,
  StringSelectMenuBuilder,
} = require("discord.js");
const { getDurations } = require("../lib/products");

async function run(interaction) {
  const select = new StringSelectMenuBuilder()
    .setCustomId("boost_duration")
    .setPlaceholder("Choose a duration")
    .addOptions(
      getDurations().map((d) => ({ label: d.label, value: d.id }))
    );

  return interaction.reply({
    content: "Pick a boost package duration to get started:",
    components: [new ActionRowBuilder().addComponents(select)],
    ephemeral: true,
  });
}

module.exports = { run };
