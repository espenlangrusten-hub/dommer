import React, { useState } from 'react';
import { ProductCard, UsersShoppingBadge } from '../components';
import { Game, GAMES, PRODUCTS } from '../products';

export default function Shop() {
  const [game, setGame] = useState<Game | 'all'>('all');
  const [query, setQuery] = useState('');

  const products = PRODUCTS.filter(p => {
    if (game !== 'all' && p.game !== game) return false;
    if (query && !p.name.toLowerCase().includes(query.toLowerCase())) return false;
    return true;
  });

  return (
    <section className="shop-section page-top">
      <div className="shop-head">
        <div>
          <p className="section-eyebrow">• ALL ITEMS •</p>
          <h2 className="section-title">Shop Everything!</h2>
          <UsersShoppingBadge />
        </div>
        <div className="shop-controls">
          <input
            className="search-input"
            type="search"
            placeholder="Search items…"
            value={query}
            autoFocus
            onChange={e => setQuery(e.target.value)}
          />
          <div className="game-tabs">
            <button className={`game-tab ${game === 'all' ? 'active' : ''}`} onClick={() => setGame('all')}>
              All
            </button>
            {GAMES.map(g => (
              <button
                key={g.id}
                className={`game-tab ${game === g.id ? 'active' : ''}`}
                onClick={() => setGame(g.id)}
              >
                {g.label}
              </button>
            ))}
          </div>
        </div>
      </div>
      {products.length === 0 ? (
        <p className="empty-note">No items match “{query}”.</p>
      ) : (
        <div className="product-grid">
          {products.map(p => (
            <ProductCard key={p.id} product={p} />
          ))}
        </div>
      )}
    </section>
  );
}
