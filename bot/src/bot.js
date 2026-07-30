import { Client, GatewayIntentBits, Events, MessageFlags, PermissionFlagsBits } from 'discord.js';
import { config } from './config.js';
import { commands } from './commands.js';
import { registerCommands } from './register.js';

export function createBot(store) {
  // Guilds is enough — nothing here reads message content or member lists.
  const client = new Client({ intents: [GatewayIntentBits.Guilds] });
  const registry = new Map(commands.map((command) => [command.data.name, command]));

  const getTargetGuildNames = () =>
    config.allowedTargetGuilds.map((id) => client.guilds.cache.get(id)?.name ?? `Unknown server (${id})`);

  client.once(Events.ClientReady, async (ready) => {
    console.log(`[bot] logged in as ${ready.user.tag}`);
    console.log(`[bot] ${store.size} stored consent(s)`);

    // Registering on every boot keeps the commands in sync without a separate
    // step, which is one less thing to forget after editing a command.
    try {
      const { count, scope } = await registerCommands();
      console.log(`[bot] registered ${count} slash command(s) ${scope}`);
    } catch (error) {
      console.error('[bot] could not register slash commands:', error.message);
      console.error('[bot] check DISCORD_CLIENT_ID — the commands may be stale until this succeeds');
    }

    for (const id of config.allowedTargetGuilds) {
      const guild = client.guilds.cache.get(id);
      if (!guild) {
        console.warn(`[bot] ⚠ target ${id} is allowlisted but I'm not in that server — invite me there`);
      } else if (!guild.members.me?.permissions.has(PermissionFlagsBits.CreateInstantInvite)) {
        console.warn(`[bot] ⚠ missing "Create Invite" in ${guild.name} — /join will fail with a 403`);
      } else {
        console.log(`[bot] ✓ target ready: ${guild.name}`);
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
