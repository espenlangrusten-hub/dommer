export type Reward = {
  id: string;
  name: string;
  cost: number;
  tier: 'common' | 'rare' | 'legendary';
  /** Emoji shown until the artwork in public/rewards/<id>.png is added. */
  fallback: string;
};

/** Where a reward's artwork lives. Drop <id>.png into public/rewards/. */
export function rewardImage(id: string): string {
  return `${process.env.PUBLIC_URL || ''}/rewards/${id}.png`;
}

export const SHOP_NAME = 'Garden Valley';

/** The reward catalogue. Costs are in credits. */
export const REWARDS: Reward[] = [
  { id: 'super-sprinkler', name: '1x Super Sprinkler', cost: 2, tier: 'common', fallback: '💦' },
  { id: 'super-watering-can', name: '1x Super Watering Can', cost: 3, tier: 'common', fallback: '🪣' },
  { id: 'dragons-breath', name: "1x Dragon's Breath Seed", cost: 5, tier: 'common', fallback: '🔥' },
  { id: 'unicorn', name: '1x Unicorn', cost: 10, tier: 'rare', fallback: '🦄' },
  { id: 'golden-dragonfly', name: '1x Golden Dragonfly', cost: 10, tier: 'rare', fallback: '🪰' },
  { id: 'star-fruit', name: '1x Star Fruit Seed', cost: 15, tier: 'rare', fallback: '⭐' },
  { id: 'raccoon', name: '1x Raccoon', cost: 75, tier: 'legendary', fallback: '🦝' },
];
