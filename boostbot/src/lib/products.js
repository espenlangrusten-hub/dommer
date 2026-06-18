// Base prices taken from the storefront. Customers pay double the base price,
// computed at runtime so there is a single source of truth per package.
const CATALOG = {
  "3m": {
    label: "3 Months",
    packages: [
      { id: "2", boosts: 2, basePrice: 3.49 },
      { id: "6", boosts: 6, basePrice: 9.99 },
      { id: "8", boosts: 8, basePrice: 13.99 },
      { id: "14", boosts: 14, basePrice: 23.99, tag: "Most Popular" },
      { id: "20", boosts: 20, basePrice: 34.99, tag: "Trending" },
      { id: "30", boosts: 30, basePrice: 49.99 },
    ],
  },
  "1m": {
    label: "1 Month",
    packages: [
      { id: "2", boosts: 2, basePrice: 1.49 },
      { id: "6", boosts: 6, basePrice: 4.49 },
      { id: "8", boosts: 8, basePrice: 5.99 },
      { id: "14", boosts: 14, basePrice: 9.99, tag: "Most Popular" },
      { id: "20", boosts: 20, basePrice: 14.99, tag: "Trending" },
      { id: "30", boosts: 30, basePrice: 21.99 },
    ],
  },
};

function getDurations() {
  return Object.entries(CATALOG).map(([id, v]) => ({ id, label: v.label }));
}

function getPackages(durationId) {
  return CATALOG[durationId]?.packages || [];
}

function getPackage(durationId, packageId) {
  return getPackages(durationId).find((p) => p.id === packageId);
}

function getPrice(pkg) {
  return Math.round(pkg.basePrice * 2 * 100) / 100;
}

module.exports = { CATALOG, getDurations, getPackages, getPackage, getPrice };
