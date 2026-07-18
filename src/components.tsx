import React, { createContext, useContext, useEffect, useRef, useState } from 'react';
import { Logo, SmartArt } from './art';
import { discountPct, Product } from './products';
import { formatMoney, useCart } from './store';

export function navigate(to: string) {
  window.location.hash = to;
}

// ---------- Toast ----------

const ToastContext = createContext<(msg: string) => void>(() => {});

export function ToastProvider({ children }: { children: React.ReactNode }) {
  const [msg, setMsg] = useState<string | null>(null);
  const timer = useRef<number | undefined>(undefined);

  const show = (m: string) => {
    setMsg(m);
    window.clearTimeout(timer.current);
    timer.current = window.setTimeout(() => setMsg(null), 2200);
  };

  return (
    <ToastContext.Provider value={show}>
      {children}
      {msg && <div className="toast">{msg}</div>}
    </ToastContext.Provider>
  );
}

export function useToast() {
  return useContext(ToastContext);
}

// ---------- Header ----------

export function Header() {
  const { count } = useCart();
  return (
    <header className="site-header">
      <a
        className="logo-link"
        href="#/"
        onClick={() => window.scrollTo({ top: 0 })}
        aria-label="Garden Shop home"
      >
        <Logo height={52} />
      </a>
      <nav className="header-nav">
        <a className="nav-link" href="#/claim">
          Claim Order
        </a>
      </nav>
      <div className="header-icons">
        <a className="icon-btn" href="#/shop" aria-label="Search">
          <svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
            <circle cx="11" cy="11" r="7" />
            <line x1="16.5" y1="16.5" x2="21" y2="21" />
          </svg>
        </a>
        <a className="icon-btn" href="#/admin" aria-label="Account">
          <svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
            <circle cx="12" cy="8" r="4" />
            <path d="M4 21c1.5-4 5-6 8-6s6.5 2 8 6" />
          </svg>
        </a>
        <a className="icon-btn cart-btn" href="#/cart" aria-label="Cart">
          <svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
            <circle cx="9" cy="20" r="1.6" />
            <circle cx="17" cy="20" r="1.6" />
            <path d="M3 4h2l2.4 11.2a1.5 1.5 0 0 0 1.5 1.2h7.9a1.5 1.5 0 0 0 1.5-1.1L20.5 8H6" />
          </svg>
          {count > 0 && <span className="cart-badge">{count}</span>}
        </a>
      </div>
    </header>
  );
}

// ---------- Product card ----------

export function ProductCard({ product }: { product: Product }) {
  const { add } = useCart();
  const toast = useToast();
  return (
    <div className="product-card">
      <div className="card-image">
        <SmartArt kind={product.art} />
        <span className="badge badge-discount">-{discountPct(product)}%</span>
        {product.isNew && <span className="badge badge-new">NEW</span>}
        <span className="badge badge-delivery">⚡ ~2 min</span>
      </div>
      <div className="card-body">
        <h3 className="card-title">{product.name}</h3>
        <div className="card-prices">
          <span className="price">{formatMoney(product.price)}</span>
          <span className="old-price">{formatMoney(product.oldPrice)}</span>
        </div>
        <button
          className="btn btn-red card-add"
          onClick={() => {
            add(product.id);
            toast(`${product.name} added to cart!`);
          }}
        >
          Add to Cart
        </button>
      </div>
    </div>
  );
}

// ---------- Users-shopping badge ----------

export function UsersShoppingBadge() {
  const [n, setN] = useState(() => 95 + Math.floor(Math.random() * 40));
  useEffect(() => {
    const t = window.setInterval(() => {
      setN(prev => Math.max(80, Math.min(160, prev + Math.floor(Math.random() * 9) - 4)));
    }, 8000);
    return () => window.clearInterval(t);
  }, []);
  return (
    <span className="users-badge">
      <span className="pulse-dot" /> {n} <span className="users-badge-label">Users Shopping</span>
    </span>
  );
}

// ---------- Footer & floating widgets ----------

export function Footer() {
  return (
    <footer className="site-footer">
      <Logo height={40} />
      <p>The fastest, most trusted place to get your Grow a Garden items.</p>
      <nav className="footer-nav">
        <a href="#/shop">Shop</a>
        <a href="#/claim">Claim Order</a>
        <a href="#/cart">Cart</a>
      </nav>
      <p className="footer-fine">
        © {new Date().getFullYear()} gardenshop.gg — Not affiliated with Roblox Corporation.
      </p>
    </footer>
  );
}

export function FloatingWidgets() {
  const [chatOpen, setChatOpen] = useState(false);
  return (
    <>
      <div className="locale-pill">
        <span className="flag">🇺🇸</span> United States&nbsp;&nbsp;($)&nbsp;&nbsp;English
      </div>
      <button className="chat-fab" onClick={() => setChatOpen(o => !o)}>
        <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
          <path d="M21 12a8 8 0 0 1-8 8H5l-2 2V12a8 8 0 0 1 8-8h2a8 8 0 0 1 8 8z" />
        </svg>
        Chat
      </button>
      {chatOpen && (
        <div className="chat-popover">
          <strong>Need help?</strong>
          <p>
            Email us at <a href="mailto:support@gardenshop.gg">support@gardenshop.gg</a> and we
            will get back to you 24/7.
          </p>
        </div>
      )}
    </>
  );
}
