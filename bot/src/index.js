import { config } from './config.js';
import { ConsentStore } from './store.js';
import { createBot } from './bot.js';
import { createServer } from './server.js';

const store = await new ConsentStore(config.dataFile, config.encryptionKey).load();
const { getTargetGuildNames, login } = createBot(store);

const server = createServer(store, getTargetGuildNames).listen(config.port, () => {
  console.log(`[web] listening on port ${config.port}`);
  console.log(`[web] opt-in link: ${config.publicBaseUrl}/auth`);
});

await login();

for (const signal of ['SIGINT', 'SIGTERM']) {
  process.on(signal, () => {
    console.log(`\n[app] ${signal} received, shutting down`);
    server.close();
    process.exit(0);
  });
}
