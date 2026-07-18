import React, { useState } from 'react';
import { HeroArt } from '../art';
import { ProductCard, UsersShoppingBadge } from '../components';
import { Game, GAMES, PRODUCTS } from '../products';

export default function Home() {
  const [game, setGame] = useState<Game>('gag2');

  const bestSellers = PRODUCTS.filter(p => p.game === game && (game !== 'gag2' || p.best));
  const newItems = PRODUCTS.filter(p => p.isNew);

  const scrollToShop = () => {
    document.getElementById('shop')?.scrollIntoView({ behavior: 'smooth' });
  };

  return (
    <>
      <section className="hero">
        <div className="hero-left">
          <p className="hero-eyebrow">Trusted by 200,000+ players</p>
          <p className="hero-stars">
            <span className="stars">★★★★★</span> <strong>200,000+</strong>&nbsp; happy customers
          </p>
          <h1 className="hero-title">
            <em className="red">Instantly</em> Buy Your Favorite Items — <em className="red">Fast</em>,{' '}
            <em className="red">Safe</em>, and <em className="red">Easy</em>!
          </h1>
          <p className="hero-sub">The fastest, most trusted place to get your Grow a Garden items.</p>
          <button className="btn btn-red hero-cta" onClick={scrollToShop}>
            <svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <path d="M6 7h12l1 13H5L6 7z" />
              <path d="M9 10V6a3 3 0 0 1 6 0v4" />
            </svg>
            Shop Now
            <span className="cta-arrow">→</span>
          </button>
          <div className="hero-stats">
            <div className="stat">
              <span className="stat-icon">🏆</span>
              <span className="stat-value green">200k+</span>
              <span className="stat-label">Customers</span>
            </div>
            <div className="stat">
              <span className="stat-icon">🎧</span>
              <span className="stat-value green">24/7</span>
              <span className="stat-label">Support</span>
            </div>
          </div>
        </div>
        <div className="hero-right">
          <HeroArt />
        </div>
      </section>

      <section className="shop-section" id="shop">
        <div className="shop-head">
          <div>
            <p className="section-eyebrow">
              • {GAMES.find(g => g.id === game)?.label.toUpperCase()} •
            </p>
            <h2 className="section-title">Shop Best Sellers!</h2>
            <UsersShoppingBadge />
          </div>
          <div className="game-tabs">
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
        <div className="product-grid">
          {bestSellers.map(p => (
            <ProductCard key={p.id} product={p} />
          ))}
        </div>
      </section>

      <section className="shop-section new-items">
        <p className="section-eyebrow center green-text">• JUST DROPPED •</p>
        <h2 className="section-title center">NEW ITEMS!!!</h2>
        <div className="product-grid">
          {newItems.map(p => (
            <ProductCard key={p.id} product={p} />
          ))}
        </div>
        <div className="view-all-wrap">
          <a className="btn btn-outline view-all" href="#/shop">
            View All →
          </a>
        </div>
      </section>
    </>
  );
}
