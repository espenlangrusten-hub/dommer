export type Reward = {
  id: string;
  name: string;
  blurb: string;
  cost: number;
  icon: string;
  tier: 'common' | 'rare' | 'legendary';
};

/** The reward catalogue. Costs are in Seeds 🌱. */
export const REWARDS: Reward[] = [
  {
    id: 'sprinkler',
    name: 'Basic Sprinkler',
    blurb: 'Speeds up growth on a 3x3 plot.',
    cost: 150,
    icon: '💦',
    tier: 'common',
  },
  {
    id: 'seedpack',
    name: 'Mystery Seed Pack',
    blurb: 'Five random seeds, one guaranteed rare.',
    cost: 300,
    icon: '🎁',
    tier: 'common',
  },
  {
    id: 'fertilizer',
    name: 'Golden Fertilizer',
    blurb: '2x harvest value for 24 hours.',
    cost: 500,
    icon: '✨',
    tier: 'rare',
  },
  {
    id: 'watering-can',
    name: 'Rainmaker Can',
    blurb: 'Waters your whole garden in one tap.',
    cost: 750,
    icon: '🪣',
    tier: 'rare',
  },
  {
    id: 'pet-egg',
    name: 'Garden Pet Egg',
    blurb: 'Hatches a helper that auto-collects crops.',
    cost: 1200,
    icon: '🥚',
    tier: 'rare',
  },
  {
    id: 'plot',
    name: 'Extra Garden Plot',
    blurb: 'Permanently expands your farm by one plot.',
    cost: 2000,
    icon: '🌾',
    tier: 'legendary',
  },
  {
    id: 'candy-tree',
    name: 'Candy Blossom Tree',
    blurb: 'Limited-time legendary crop, glows at night.',
    cost: 3500,
    icon: '🍬',
    tier: 'legendary',
  },
  {
    id: 'crown',
    name: 'Gardener Crown',
    blurb: 'Cosmetic flex. Everyone sees it on your avatar.',
    cost: 5000,
    icon: '👑',
    tier: 'legendary',
  },
];
