import { REST, Routes } from 'discord.js';
import { config } from './config.js';
import { commands } from './commands.js';

/**
 * Pushes the slash command definitions to Discord. Registering to a single
 * guild is instant; global registration can take up to an hour to appear, so
 * DEV_GUILD_ID is set by the setup wizard to keep the first run quick.
 */
export async function registerCommands() {
  const rest = new REST({ version: '10' }).setToken(config.token);
  const route = config.devGuildId
    ? Routes.applicationGuildCommands(config.clientId, config.devGuildId)
    : Routes.applicationCommands(config.clientId);

  const registered = await rest.put(route, { body: commands.map((command) => command.data.toJSON()) });
  return { count: registered.length, scope: config.devGuildId ? `guild ${config.devGuildId}` : 'globally' };
}
