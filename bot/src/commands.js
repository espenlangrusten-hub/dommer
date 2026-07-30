import {
  SlashCommandBuilder,
  PermissionFlagsBits,
  EmbedBuilder,
  ActionRowBuilder,
  ButtonBuilder,
  ButtonStyle,
  MessageFlags,
} from 'discord.js';
import { config } from './config.js';
import { parseTarget } from './targets.js';
import { joinAll } from './joiner.js';

const BRAND = 0x5865f2;
const authUrl = () => `${config.publicBaseUrl}/auth`;

function optInEmbed(guildNames) {
  return new EmbedBuilder()
    .setColor(BRAND)
    .setTitle('Let admins move you between our servers')
    .setDescription(
      'Authorize once and an admin can add you straight into our other servers — ' +
        'no chasing invite links.\n\nThis only ever applies to:\n' +
        guildNames.map((name) => `• **${name}**`).join('\n'),
    )
    .setFooter({ text: 'Withdraw any time with /forget-me, or in User Settings → Authorized Apps.' });
}

const linkRow = () =>
  new ActionRowBuilder().addComponents(
    new ButtonBuilder().setLabel('Authorize with Discord').setStyle(ButtonStyle.Link).setURL(authUrl()),
  );

/** Turns an invite link, invite code, or guild ID into a validated target guild. */
async function resolveTargetGuild(client, input) {
  const target = parseTarget(input);
  if (!target) {
    return { error: 'That doesn\'t look like an invite link, invite code, or server ID.' };
  }

  let guildId = target.value;
  if (target.type === 'inviteCode') {
    try {
      const invite = await client.fetchInvite(target.value);
      guildId = invite.guild?.id;
    } catch {
      return { error: 'I couldn\'t resolve that invite — it may have expired or been revoked.' };
    }
    if (!guildId) return { error: 'That invite doesn\'t point at a server I can read.' };
  }

  if (!config.allowedTargetGuilds.includes(guildId)) {
    return {
      error:
        `Server \`${guildId}\` isn't on the allowlist, so I won't add anyone to it.\n` +
        'Members consented to a specific set of servers. Add it to `ALLOWED_TARGET_GUILDS` and restart if that\'s intended.',
    };
  }

  const guild = client.guilds.cache.get(guildId);
  if (!guild) {
    return { error: 'I\'m not a member of that server, so I can\'t add anyone to it. Invite me there first.' };
  }
  if (!guild.members.me?.permissions.has(PermissionFlagsBits.CreateInstantInvite)) {
    return { error: `I need the **Create Invite** permission in **${guild.name}** before I can add members.` };
  }

  return { guild };
}

function summarise(results, guildName) {
  const lines = [
    `**${results.added.length}** added to **${guildName}**`,
    `**${results.alreadyMember.length}** were already there`,
  ];
  if (results.revoked.length) lines.push(`**${results.revoked.length}** had revoked access (removed from the list)`);
  if (results.failed.length) lines.push(`**${results.failed.length}** failed`);

  const embed = new EmbedBuilder()
    .setColor(results.failed.length ? 0xed4245 : 0x57f287)
    .setTitle('Done')
    .setDescription(lines.join('\n'))
    .setFooter({ text: `${results.total} authorized member(s) processed` });

  if (results.failed.length) {
    embed.addFields({
      name: 'Failures',
      value: results.failed
        .slice(0, 5)
        .map((entry) => `• ${entry.username}: ${entry.reason}`)
        .join('\n')
        .slice(0, 1024),
    });
  }
  return embed;
}

export const commands = [
  {
    data: new SlashCommandBuilder()
      .setName('opt-in')
      .setDescription('Get your personal link to authorize being moved between our servers')
      .setDMPermission(false),
    async execute(interaction, { store, getTargetGuildNames }) {
      const embed = optInEmbed(getTargetGuildNames());
      if (store.has(interaction.user.id)) {
        embed.setDescription(`✅ You're already authorized — re-authorizing is harmless.\n\n${embed.data.description}`);
      }
      await interaction.reply({ embeds: [embed], components: [linkRow()], flags: MessageFlags.Ephemeral });
    },
  },

  {
    data: new SlashCommandBuilder()
      .setName('post-opt-in')
      .setDescription('Post the public authorization message in this channel')
      .setDefaultMemberPermissions(PermissionFlagsBits.ManageGuild)
      .setDMPermission(false),
    async execute(interaction, { getTargetGuildNames }) {
      await interaction.channel.send({ embeds: [optInEmbed(getTargetGuildNames())], components: [linkRow()] });
      await interaction.reply({ content: 'Posted.', flags: MessageFlags.Ephemeral });
    },
  },

  {
    data: new SlashCommandBuilder()
      .setName('join')
      .setDescription('Add every authorized member to another server')
      .addStringOption((option) =>
        option
          .setName('server')
          .setDescription('Invite link, invite code, or server ID (must be on the allowlist)')
          .setRequired(true),
      )
      .setDefaultMemberPermissions(PermissionFlagsBits.Administrator)
      .setDMPermission(false),
    async execute(interaction, { store }) {
      await interaction.deferReply();

      const { guild, error } = await resolveTargetGuild(interaction.client, interaction.options.getString('server'));
      if (error) {
        await interaction.editReply({ content: `❌ ${error}` });
        return;
      }

      if (store.size === 0) {
        await interaction.editReply({
          content: 'Nobody has authorized yet. Run `/post-opt-in` so members can opt in first.',
        });
        return;
      }

      console.log(`[join] ${interaction.user.tag} adding ${store.size} member(s) to ${guild.name}`);

      let lastEdit = 0;
      const results = await joinAll(store, guild.id, {
        onProgress: (progress) => {
          const now = Date.now();
          if (now - lastEdit < 3000) return;
          lastEdit = now;
          interaction
            .editReply({ content: `Working… ${progress.processed}/${progress.total} processed.` })
            .catch(() => {});
        },
      });

      await interaction.editReply({ content: '', embeds: [summarise(results, guild.name)] });
    },
  },

  {
    data: new SlashCommandBuilder()
      .setName('status')
      .setDescription('Show how many members have authorized')
      .setDefaultMemberPermissions(PermissionFlagsBits.ManageGuild)
      .setDMPermission(false),
    async execute(interaction, { store, getTargetGuildNames }) {
      const embed = new EmbedBuilder()
        .setColor(BRAND)
        .setTitle('Authorization status')
        .addFields(
          { name: 'Authorized members', value: String(store.size), inline: true },
          { name: 'Allowed targets', value: getTargetGuildNames().join('\n') || 'none', inline: true },
        );
      await interaction.reply({ embeds: [embed], flags: MessageFlags.Ephemeral });
    },
  },

  {
    data: new SlashCommandBuilder()
      .setName('forget-me')
      .setDescription('Withdraw your authorization and delete your stored tokens')
      .setDMPermission(false),
    async execute(interaction, { store }) {
      const removed = await store.delete(interaction.user.id);
      await interaction.reply({
        content: removed
          ? 'Done — your tokens are deleted and you won\'t be added to anything. ' +
            'To fully revoke access, also remove the app under **User Settings → Authorized Apps**.'
          : 'You weren\'t on the list, so there was nothing to delete.',
        flags: MessageFlags.Ephemeral,
      });
    },
  },
];
