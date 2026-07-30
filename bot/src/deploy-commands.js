import { REST, Routes } from 'discord.js';
import { config } from './config.js';
import { commands } from './commands.js';

const body = commands.map((command) => command.data.toJSON());
const rest = new REST({ version: '10' }).setToken(config.token);

const route = config.devGuildId
  ? Routes.applicationGuildCommands(config.clientId, config.devGuildId)
  : Routes.applicationCommands(config.clientId);

const registered = await rest.put(route, { body });

console.log(`Registered ${registered.length} command(s) ${config.devGuildId ? `in guild ${config.devGuildId}` : 'globally'}:`);
for (const command of registered) console.log(`  /${command.name}`);
if (!config.devGuildId) console.log('\nGlobal commands can take up to an hour to appear. Set DEV_GUILD_ID for instant registration while testing.');
