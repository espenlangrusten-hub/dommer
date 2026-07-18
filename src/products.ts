export type Game = 'gag2' | 'sab' | 'gag';

export const GAMES: { id: Game; label: string }[] = [
  { id: 'gag2', label: 'Grow A Garden 2' },
  { id: 'sab', label: 'Steal A Brainrot' },
  { id: 'gag', label: 'Grow A Garden' },
];

export interface Product {
  id: string;
  name: string;
  price: number;
  oldPrice: number;
  game: Game;
  art: string;
  isNew?: boolean;
  best?: boolean;
}

export function discountPct(p: Product): number {
  return Math.floor((1 - p.price / p.oldPrice) * 100);
}

export const PRODUCTS: Product[] = [
  // Best sellers (Grow A Garden 2)
  { id: 'super-gear-bundle', name: 'Super Gear Bundle', price: 8.49, oldPrice: 39.99, game: 'gag2', art: 'gear-crates-100', best: true },
  { id: 'pro-bundle', name: 'Pro Bundle', price: 6.8, oldPrice: 12.39, game: 'gag2', art: 'pro-bundle', best: true, isNew: true },
  { id: 'ultimate-seed-bundle', name: 'Ultimate Seed Bundle (New Seed)', price: 12.19, oldPrice: 23.49, game: 'gag2', art: 'seed-bundle', best: true, isNew: true },
  { id: 'black-dragon', name: 'Black Dragon', price: 48.92, oldPrice: 79.99, game: 'gag2', art: 'dragon-black', best: true },
  { id: 'rainbow-black-dragon', name: 'Rainbow Black Dragon', price: 149.99, oldPrice: 229.99, game: 'gag2', art: 'dragon-purple', best: true },
  { id: 'raccoon', name: 'Raccoon', price: 6.2, oldPrice: 18.49, game: 'gag2', art: 'raccoon', best: true },
  { id: 'hypno-bloom-seed', name: 'Hypno Bloom Seed', price: 3.96, oldPrice: 7.59, game: 'gag2', art: 'flower', best: true },
  { id: '100x-mega-seeds', name: '100X MEGA SEEDS', price: 7.49, oldPrice: 8.99, game: 'gag2', art: 'seedbox', best: true },

  // New items
  { id: 'ultra-gag2-bundle', name: 'Ultra GAG 2 Bundle', price: 7.49, oldPrice: 139.99, game: 'gag2', art: 'ultra-bundle', isNew: true },
  { id: '3x-racoon-bundle', name: '3X Racoon Bundle', price: 9.99, oldPrice: 19.99, game: 'gag2', art: 'raccoon3', isNew: true },
  { id: '3x-firefly-bundle', name: '3X Firefly Bundle', price: 7.27, oldPrice: 12.99, game: 'gag2', art: 'firefly3', isNew: true },
  { id: 'ultimate-gear-bundle', name: 'Ultimate Gear Bundle', price: 19.27, oldPrice: 27.99, game: 'gag2', art: 'gear-crates-1000', isNew: true },
  { id: '12x-golden-dragonfly-bundle', name: '12X Golden Dragonfly Bundle', price: 4.79, oldPrice: 12.99, game: 'gag2', art: 'dragonfly12', isNew: true },
  { id: '12x-unicorn-bundle', name: '12X Unicorn Bundle', price: 4.39, oldPrice: 23.49, game: 'gag2', art: 'unicorn12', isNew: true },

  // Steal A Brainrot
  { id: 'sab-starter-bundle', name: 'Brainrot Starter Bundle', price: 5.49, oldPrice: 14.99, game: 'sab', art: 'pro-bundle' },
  { id: 'sab-secret-pet', name: 'Secret Brainrot Pet', price: 24.99, oldPrice: 49.99, game: 'sab', art: 'dragon-purple' },
  { id: 'sab-cash-crate', name: 'Mega Cash Crate', price: 9.99, oldPrice: 21.99, game: 'sab', art: 'gear-crates-100' },

  // Grow A Garden (original)
  { id: 'gag-sheckle-pack', name: '10T Sheckles Pack', price: 6.99, oldPrice: 15.99, game: 'gag', art: 'seedbox' },
  { id: 'gag-pet-bundle', name: 'Legendary Pet Bundle', price: 11.49, oldPrice: 24.99, game: 'gag', art: 'raccoon3' },
  { id: 'gag-seed-pack', name: 'Rare Seed Pack', price: 4.29, oldPrice: 9.99, game: 'gag', art: 'seed-bundle' },
];

export function getProduct(id: string): Product | undefined {
  return PRODUCTS.find(p => p.id === id);
}
