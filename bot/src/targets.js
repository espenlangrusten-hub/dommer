const INVITE_PATTERNS = [
  /^https?:\/\/(?:www\.)?(?:discord\.gg|discord(?:app)?\.com\/invite)\/([a-z0-9-]+)\/?$/i,
  /^([a-z0-9-]{2,32})$/i,
];

/**
 * Accepts what people actually paste: an invite URL, a bare invite code, or a
 * raw guild ID. Returns null for anything unrecognisable.
 */
export function parseTarget(input) {
  const trimmed = String(input ?? '').trim();
  if (!trimmed) return null;

  if (/^\d{17,20}$/.test(trimmed)) {
    return { type: 'guildId', value: trimmed };
  }

  for (const pattern of INVITE_PATTERNS) {
    const match = trimmed.match(pattern);
    if (match) return { type: 'inviteCode', value: match[1] };
  }

  return null;
}
