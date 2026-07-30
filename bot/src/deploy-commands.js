import { registerCommands } from './register.js';

const { count, scope } = await registerCommands();
console.log(`Registered ${count} command(s) ${scope}.`);
if (scope === 'globally') {
  console.log('Global commands can take up to an hour to appear. Set DEV_GUILD_ID for instant registration.');
}
