import express from 'express';
import { config } from './config.js';
import { signState, verifyState } from './crypto.js';
import { buildAuthorizeUrl, exchangeCode, fetchCurrentUser, SCOPES } from './oauth.js';
import { landingPage, successPage, errorPage } from './pages.js';

export function createServer(store, getTargetGuildNames) {
  const app = express();
  app.disable('x-powered-by');

  app.get('/healthz', (_request, response) => {
    response.json({ ok: true, consents: store.size });
  });

  app.get('/', (_request, response) => {
    response.type('html').send(landingPage(getTargetGuildNames(), '/auth'));
  });

  app.get('/auth', (_request, response) => {
    response.redirect(buildAuthorizeUrl(signState(config.encryptionKey)));
  });

  app.get('/callback', async (request, response) => {
    const { code, state, error: oauthError } = request.query;

    if (oauthError) {
      response.status(400).type('html').send(errorPage('You declined the authorization request.'));
      return;
    }
    if (!code || !verifyState(state, config.encryptionKey)) {
      response
        .status(400)
        .type('html')
        .send(errorPage('That link was invalid or expired. Start again from the beginning.'));
      return;
    }

    try {
      const tokens = await exchangeCode(code);

      const granted = (tokens.scope ?? '').split(' ');
      if (!SCOPES.every((scope) => granted.includes(scope))) {
        response
          .status(400)
          .type('html')
          .send(errorPage('The required permissions were not granted, so nothing was saved.'));
        return;
      }

      const user = await fetchCurrentUser(tokens.access_token);
      await store.upsert({
        userId: user.id,
        username: user.global_name || user.username,
        accessToken: tokens.access_token,
        refreshToken: tokens.refresh_token,
        expiresIn: tokens.expires_in,
      });

      console.log(`[oauth] consent recorded for ${user.username} (${user.id})`);
      response.type('html').send(successPage(user.global_name || user.username, getTargetGuildNames()));
    } catch (error) {
      console.error('[oauth] callback failed:', error);
      response.status(500).type('html').send(errorPage('We could not complete the handshake with Discord.'));
    }
  });

  return app;
}
