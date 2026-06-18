const {
  ActionRowBuilder,
  StringSelectMenuBuilder,
  ButtonBuilder,
  ButtonStyle,
  EmbedBuilder,
} = require("discord.js");
const config = require("../config");
const { getDurations, getPackages, getPackage, getPrice } = require("./products");
const paypal = require("./paypal");
const store = require("./store");

async function handleDurationSelect(interaction) {
  const durationId = interaction.values[0];
  const select = new StringSelectMenuBuilder()
    .setCustomId(`boost_package:${durationId}`)
    .setPlaceholder("Choose a package")
    .addOptions(
      getPackages(durationId).map((p) => ({
        label: `${p.boosts} Server Boosts${p.tag ? ` (${p.tag})` : ""}`,
        description: `$${getPrice(p).toFixed(2)}`,
        value: p.id,
      }))
    );

  return interaction.update({
    content: `Duration: **${getDurations().find((d) => d.id === durationId).label}**\nNow pick a package:`,
    components: [new ActionRowBuilder().addComponents(select)],
  });
}

async function handlePackageSelect(interaction, durationId) {
  const packageId = interaction.values[0];
  const pkg = getPackage(durationId, packageId);
  const price = getPrice(pkg);

  const payButton = new ButtonBuilder()
    .setCustomId(`pay:${durationId}:${packageId}`)
    .setLabel("Pay with PayPal")
    .setStyle(ButtonStyle.Primary);

  return interaction.update({
    content: `**${pkg.boosts} Server Boosts** — $${price.toFixed(2)}\n\nSelect a payment method:`,
    components: [new ActionRowBuilder().addComponents(payButton)],
  });
}

async function handlePayButton(interaction, durationId, packageId) {
  const pkg = getPackage(durationId, packageId);
  const price = getPrice(pkg);

  await interaction.update({
    content: "Creating your PayPal order...",
    components: [],
  });

  const { orderId, approveLink } = await paypal.createOrder(
    price,
    `${pkg.boosts} Server Boosts`
  );

  store.createOrder(orderId, {
    userId: interaction.user.id,
    durationId,
    packageId,
    boosts: pkg.boosts,
    price,
    status: "awaiting_payment",
  });

  const payLink = new ButtonBuilder()
    .setLabel("Pay on PayPal")
    .setStyle(ButtonStyle.Link)
    .setURL(approveLink);

  const confirmButton = new ButtonBuilder()
    .setCustomId(`capture:${orderId}`)
    .setLabel("I've completed payment")
    .setStyle(ButtonStyle.Success);

  return interaction.editReply({
    content: `**${pkg.boosts} Server Boosts** — $${price.toFixed(2)}\n\n1. Click **Pay on PayPal** and complete the payment.\n2. Come back here and click **I've completed payment**.`,
    components: [new ActionRowBuilder().addComponents(payLink, confirmButton)],
  });
}

async function handleCaptureButton(interaction, orderId) {
  await interaction.update({ content: "Verifying payment...", components: [] });

  const order = store.getOrder(orderId);
  if (!order) {
    return interaction.editReply({ content: "Order not found.", components: [] });
  }

  const capture = await paypal.captureOrder(orderId);
  if (!capture) {
    return interaction.editReply({
      content:
        "Your payment didn't go through. Please try again, or use a different PayPal account.",
      components: [],
    });
  }

  store.updateOrder(orderId, {
    status: "pending_review",
    captureId: capture.captureId,
  });

  await interaction.editReply({
    content: `Payment received! Waiting for an admin to confirm your order (**${order.boosts} Server Boosts**, $${order.price.toFixed(2)}). You'll get a message here shortly.`,
    components: [],
  });

  return postOrderForReview(interaction, orderId);
}

async function postOrderForReview(interaction, orderId) {
  const order = store.getOrder(orderId);
  const channelId = config.ordersChannelId;
  if (!channelId) {
    console.error("ORDERS_CHANNEL_ID not configured; run /setup-channels.");
    return;
  }
  const channel = await interaction.client.channels.fetch(channelId);

  const embed = new EmbedBuilder()
    .setTitle("New Order")
    .addFields(
      { name: "User", value: `<@${order.userId}>`, inline: true },
      { name: "Boosts", value: String(order.boosts), inline: true },
      { name: "Amount Paid", value: `$${order.price.toFixed(2)}`, inline: true },
      { name: "PayPal Order ID", value: order.orderId }
    )
    .setColor(0x5865f2);

  const confirmButton = new ButtonBuilder()
    .setCustomId(`admin_confirm:${orderId}`)
    .setLabel("Confirm")
    .setStyle(ButtonStyle.Success);
  const declineButton = new ButtonBuilder()
    .setCustomId(`admin_decline:${orderId}`)
    .setLabel("Decline & Refund")
    .setStyle(ButtonStyle.Danger);

  await channel.send({
    embeds: [embed],
    components: [new ActionRowBuilder().addComponents(confirmButton, declineButton)],
  });
}

function requireOwner(interaction) {
  return interaction.user.id === config.ownerId;
}

async function handleAdminConfirm(interaction, orderId) {
  if (!requireOwner(interaction)) {
    return interaction.reply({ content: "Owner only.", ephemeral: true });
  }
  const order = store.updateOrder(orderId, { status: "confirmed" });
  if (!order) return interaction.reply({ content: "Order not found.", ephemeral: true });

  await interaction.update({
    content: `${interaction.message.content}\n\n**Confirmed by ${interaction.user.tag}**`,
    components: [],
  });

  const user = await interaction.client.users.fetch(order.userId);
  await user.send(
    `Order confirmed! Your ${order.boosts} boosts will come shortly.`
  ).catch(() => {});

  return postFulfillmentPrompt(interaction, orderId);
}

async function handleAdminDecline(interaction, orderId) {
  if (!requireOwner(interaction)) {
    return interaction.reply({ content: "Owner only.", ephemeral: true });
  }
  const order = store.getOrder(orderId);
  if (!order) return interaction.reply({ content: "Order not found.", ephemeral: true });

  await interaction.update({
    content: `${interaction.message.content}\n\n**Declining and refunding...**`,
    components: [],
  });

  await paypal.refundCapture(order.captureId);
  store.updateOrder(orderId, { status: "declined" });

  const user = await interaction.client.users.fetch(order.userId);
  await user.send(
    `Your order for ${order.boosts} boosts was declined and a refund of $${order.price.toFixed(2)} has been issued to your PayPal account.`
  ).catch(() => {});

  return interaction.editReply({
    content: `${interaction.message.content}\n\n**Declined and refunded by ${interaction.user.tag}**`,
  });
}

async function postFulfillmentPrompt(interaction, orderId) {
  const order = store.getOrder(orderId);
  const channelId = config.fulfillmentChannelId;
  if (!channelId) {
    console.error("FULFILLMENT_CHANNEL_ID not configured; run /setup-channels.");
    return;
  }
  const channel = await interaction.client.channels.fetch(channelId);

  const embed = new EmbedBuilder()
    .setTitle("Fulfill Order")
    .addFields(
      { name: "User", value: `<@${order.userId}>`, inline: true },
      { name: "Boosts", value: String(order.boosts), inline: true }
    )
    .setColor(0x5865f2);

  const sentButton = new ButtonBuilder()
    .setCustomId(`fulfill_sent:${orderId}`)
    .setLabel("Boosts Sent")
    .setStyle(ButtonStyle.Success);
  const delayedButton = new ButtonBuilder()
    .setCustomId(`fulfill_delayed:${orderId}`)
    .setLabel("Delayed")
    .setStyle(ButtonStyle.Secondary);

  await channel.send({
    embeds: [embed],
    components: [new ActionRowBuilder().addComponents(sentButton, delayedButton)],
  });
}

async function handleFulfillSent(interaction, orderId) {
  if (!requireOwner(interaction)) {
    return interaction.reply({ content: "Owner only.", ephemeral: true });
  }
  const order = store.updateOrder(orderId, { status: "fulfilled" });
  await interaction.update({
    content: `${interaction.message.content}\n\n**Marked sent by ${interaction.user.tag}**`,
    components: [],
  });
  const user = await interaction.client.users.fetch(order.userId);
  await user.send(`Your ${order.boosts} boosts have been sent. Enjoy!`).catch(() => {});
}

async function handleFulfillDelayed(interaction, orderId) {
  if (!requireOwner(interaction)) {
    return interaction.reply({ content: "Owner only.", ephemeral: true });
  }
  const order = store.updateOrder(orderId, { status: "delayed" });
  await interaction.update({
    content: `${interaction.message.content}\n\n**Marked delayed by ${interaction.user.tag}**`,
    components: [],
  });
  const user = await interaction.client.users.fetch(order.userId);
  await user.send(
    `Your order for ${order.boosts} boosts has been delayed. We'll update you as soon as it's ready.`
  ).catch(() => {});
}

module.exports = {
  handleDurationSelect,
  handlePackageSelect,
  handlePayButton,
  handleCaptureButton,
  handleAdminConfirm,
  handleAdminDecline,
  handleFulfillSent,
  handleFulfillDelayed,
};
