import { Client, GatewayIntentBits, Events, MessageFlags } from 'discord.js';
import { config } from './config.js';
import { commands } from './commands.js';

export function createBot(store) {
  // Guilds is enough — nothing here reads message content or member lists.
  const client = new Client({ intents: [GatewayIntentBits.Guilds] });
  const registry = new Map(commands.map((command) => [command.data.name, command]));

  const getTargetGuildNames = () =>
    config.allowedTargetGuilds.map((id) => client.guilds.cache.get(id)?.name ?? `Unknown server (${id})`);

  client.once(Events.ClientReady, (ready) => {
    console.log(`[bot] logged in as ${ready.user.tag}`);
    console.log(`[bot] ${store.size} stored consent(s)`);

    for (const id of config.allowedTargetGuilds) {
      const guild = client.guilds.cache.get(id);
      if (guild) {
        const canInvite = guild.members.me?.permissions.has('CreateInstantInvite');
        console.log(`[bot] target ${guild.name} (${id}) — Create Invite: ${canInvite ? 'yes' : 'NO, /join will fail'}`);
      } else {
        console.warn(`[bot] target ${id} is allowlisted but I'm not in that server`);
      }
    }
  });

  client.on(Events.InteractionCreate, async (interaction) => {
    if (!interaction.isChatInputCommand()) return;

    const command = registry.get(interaction.commandName);
    if (!command) return;

    try {
      await command.execute(interaction, { store, getTargetGuildNames });
    } catch (error) {
      console.error(`[bot] /${interaction.commandName} failed:`, error);
      const message = { content: 'Something broke running that command. Check the logs.', flags: MessageFlags.Ephemeral };
      if (interaction.deferred || interaction.replied) {
        await interaction.editReply(message).catch(() => {});
      } else {
        await interaction.reply(message).catch(() => {});
      }
    }
  });

  return { client, getTargetGuildNames, login: () => client.login(config.token) };
}
