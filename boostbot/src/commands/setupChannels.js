const { PermissionFlagsBits, ChannelType } = require("discord.js");
const config = require("../config");

async function run(interaction) {
  if (interaction.user.id !== config.ownerId) {
    return interaction.reply({
      content: "Only the server owner can run this command.",
      ephemeral: true,
    });
  }

  const guild = interaction.guild;
  const overwrites = [
    {
      id: guild.roles.everyone.id,
      deny: [PermissionFlagsBits.ViewChannel],
    },
    {
      id: config.ownerId,
      allow: [PermissionFlagsBits.ViewChannel, PermissionFlagsBits.SendMessages],
    },
    {
      id: interaction.client.user.id,
      allow: [PermissionFlagsBits.ViewChannel, PermissionFlagsBits.SendMessages],
    },
  ];

  const orders = await guild.channels.create({
    name: "orders",
    type: ChannelType.GuildText,
    permissionOverwrites: overwrites,
  });

  const fulfillment = await guild.channels.create({
    name: "fulfillment",
    type: ChannelType.GuildText,
    permissionOverwrites: overwrites,
  });

  config.saveRuntimeConfig({
    ordersChannelId: orders.id,
    fulfillmentChannelId: fulfillment.id,
  });

  return interaction.reply({
    content: `Created private channels: ${orders} and ${fulfillment}.`,
    ephemeral: true,
  });
}

module.exports = { run };
