function fatal(heading, detail, hint) {
  console.error(`\n  ${heading}\n`);
  console.error(`    ${detail}\n`);
  if (hint) console.error(`  ${hint}\n`);
  process.exit(1);
}

// config.js validates on import, so load it dynamically to turn a missing or
// malformed .env into an instruction rather than a stack trace.
let config;
try {
  ({ config } = await import('./config.js'));
} catch (error) {
  fatal('Configuration problem', error.message, 'Run  npm run setup  to generate a .env file.');
}

const { ConsentStore } = await import('./store.js');
const { createBot } = await import('./bot.js');
const { createServer } = await import('./server.js');

const store = await new ConsentStore(config.dataFile, config.encryptionKey).load();
const { getTargetGuildNames, login } = createBot(store);

const server = createServer(store, getTargetGuildNames).listen(config.port, () => {
  console.log(`[web] listening on port ${config.port}`);
  console.log(`[web] opt-in link: ${config.publicBaseUrl}/auth`);
});

server.on('error', (error) => {
  if (error.code === 'EADDRINUSE') {
    fatal('Port already in use', `Something else is already listening on port ${config.port}.`, 'Set PORT in .env to a free port, or stop the other process.');
  }
  throw error;
});

try {
  await login();
} catch (error) {
  fatal('Could not log in to Discord', error.message, 'Check DISCORD_TOKEN in .env, or re-run  npm run setup.');
}

for (const signal of ['SIGINT', 'SIGTERM']) {
  process.on(signal, () => {
    console.log(`\n[app] ${signal} received, shutting down`);
    server.close();
    process.exit(0);
  });
}
