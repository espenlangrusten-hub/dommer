const STYLE = `
  :root { color-scheme: light dark; }
  body {
    font-family: system-ui, -apple-system, "Segoe UI", sans-serif;
    display: grid; place-items: center; min-height: 100vh; margin: 0;
    background: #f5f5f7; color: #1c1c1e;
  }
  main { max-width: 32rem; padding: 2.5rem; text-align: center; }
  h1 { font-size: 1.5rem; margin: 0 0 0.75rem; }
  p { line-height: 1.6; color: #48484a; margin: 0 0 1rem; }
  ul { text-align: left; display: inline-block; color: #48484a; line-height: 1.6; }
  .badge { font-size: 3rem; margin-bottom: 0.5rem; }
  a.button {
    display: inline-block; margin-top: 0.5rem; padding: 0.75rem 1.5rem;
    background: #5865f2; color: white; border-radius: 0.5rem;
    text-decoration: none; font-weight: 600;
  }
  code { background: rgba(120,120,128,0.16); padding: 0.1rem 0.35rem; border-radius: 0.25rem; }
  @media (prefers-color-scheme: dark) {
    body { background: #1c1c1e; color: #f5f5f7; }
    p, ul { color: #aeaeb2; }
  }
`;

function page(title, body) {
  return `<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${title}</title><style>${STYLE}</style></head>
<body><main>${body}</main></body></html>`;
}

const escapeHtml = (value) =>
  String(value).replace(/[&<>"']/g, (char) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[char]);

export function landingPage(guildNames, authorizeUrl) {
  const list = guildNames.map((name) => `<li>${escapeHtml(name)}</li>`).join('');
  return page(
    'Authorize server moves',
    `<div class="badge">🔗</div>
     <h1>Let the bot move you between servers</h1>
     <p>If you authorize, a server admin can add your account to the servers listed below
        without you needing to click an invite each time.</p>
     <ul>${list}</ul>
     <p>Only these servers. You can withdraw at any time with <code>/forget-me</code> in Discord,
        or from <strong>User Settings → Authorized Apps</strong>.</p>
     <a class="button" href="${escapeHtml(authorizeUrl)}">Authorize with Discord</a>`,
  );
}

export function successPage(username, guildNames) {
  const list = guildNames.map((name) => `<li>${escapeHtml(name)}</li>`).join('');
  return page(
    'Authorized',
    `<div class="badge">✅</div>
     <h1>Thanks, ${escapeHtml(username)}</h1>
     <p>You're on the list. An admin can now add you to:</p>
     <ul>${list}</ul>
     <p>Changed your mind? Run <code>/forget-me</code> in Discord, or remove the app under
        <strong>User Settings → Authorized Apps</strong>. You can close this tab.</p>`,
  );
}

export function errorPage(message) {
  return page(
    'Something went wrong',
    `<div class="badge">⚠️</div>
     <h1>Authorization failed</h1>
     <p>${escapeHtml(message)}</p>
     <p>Head back to Discord and try the link again.</p>`,
  );
}
