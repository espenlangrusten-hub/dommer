import { normalizeUsername, parseProfile, profileUrlFor } from './tiktok';

describe('normalizeUsername', () => {
  it('accepts a plain username, an @handle and a full profile URL', () => {
    expect(normalizeUsername('charlidamelio')).toBe('charlidamelio');
    expect(normalizeUsername('  @charli.damelio ')).toBe('charli.damelio');
    expect(normalizeUsername('https://www.tiktok.com/@some_user?lang=en')).toBe('some_user');
  });

  it('rejects empty input and illegal characters', () => {
    expect(normalizeUsername('')).toBeNull();
    expect(normalizeUsername('   ')).toBeNull();
    expect(normalizeUsername('bad name')).toBeNull();
    expect(normalizeUsername('bad/name')).toBeNull();
  });
});

describe('profileUrlFor', () => {
  it('builds the canonical profile link', () => {
    expect(profileUrlFor('someone')).toBe('https://www.tiktok.com/@someone');
  });
});

describe('parseProfile', () => {
  it('reads avatar, nickname and followers from the embedded JSON', () => {
    const html = `<script id="__UNIVERSAL_DATA_FOR_REHYDRATION__">{"user":{"uniqueId":"someone",
      "nickname":"Some One","avatarThumb":"https://p16.tiktokcdn.com\\u002Fthumb.jpeg",
      "avatarLarger":"https://p16.tiktokcdn.com\\u002Flarge.jpeg"},"stats":{"followerCount":1234567}}</script>`;

    const parsed = parseProfile(html);

    expect(parsed.avatarUrl).toBe('https://p16.tiktokcdn.com/large.jpeg');
    expect(parsed.nickname).toBe('Some One');
    expect(parsed.followerCount).toBe(1234567);
  });

  it('falls back to the og:image meta tag when the JSON is absent', () => {
    const html = `<html><head>
      <meta property="og:title" content="Some One (@someone) | TikTok" />
      <meta property="og:image" content="https://p77.tiktokcdn.com/og.jpeg?x=1&amp;y=2" />
      </head></html>`;

    const parsed = parseProfile(html);

    expect(parsed.avatarUrl).toBe('https://p77.tiktokcdn.com/og.jpeg?x=1&y=2');
    expect(parsed.nickname).toBe('Some One');
    expect(parsed.followerCount).toBeUndefined();
  });

  it('finds the avatar in the markdown a text proxy returns', () => {
    const html = 'Profile\n\n![avatar](https://p16-sign.tiktokcdn-us.com/avatar~c5_720x720.jpeg)\n';

    expect(parseProfile(html).avatarUrl).toBe(
      'https://p16-sign.tiktokcdn-us.com/avatar~c5_720x720.jpeg'
    );
  });

  it('returns nothing usable when TikTok serves a bot check', () => {
    const html = '<html><body>Verify to continue</body></html>';

    expect(parseProfile(html).avatarUrl).toBeUndefined();
  });
});
