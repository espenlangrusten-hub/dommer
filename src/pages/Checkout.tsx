import React, { useState } from 'react';
import { navigate } from '../components';
import { getProduct } from '../products';
import { formatMoney, Order, placeOrder, useCart } from '../store';

const PAYMENT_METHODS = ['Card', 'PayPal', 'Crypto'];

export default function Checkout() {
  const { items, total, clear } = useCart();
  const [email, setEmail] = useState('');
  const [username, setUsername] = useState('');
  const [payment, setPayment] = useState(PAYMENT_METHODS[0]);
  const [placed, setPlaced] = useState<Order | null>(null);

  if (placed) {
    return (
      <section className="narrow-page page-top">
        <div className="order-confirm">
          <span className="confirm-icon">✅</span>
          <h2 className="section-title">Order placed!</h2>
          <p>
            Your order ID is <strong className="order-id">{placed.id}</strong>
          </p>
          <p>
            Save this ID — you can track your delivery any time on the{' '}
            <a href="#/claim">Claim Order</a> page (order ID + email). Delivery usually takes{' '}
            <strong>~2 minutes</strong>: we will send a private server link to{' '}
            <strong>{placed.email}</strong> and trade the items to{' '}
            <strong>{placed.username}</strong> in-game.
          </p>
          <a className="btn btn-red" href="#/">
            Back to Shop →
          </a>
        </div>
      </section>
    );
  }

  if (items.length === 0) {
    return (
      <section className="narrow-page page-top">
        <h2 className="section-title">Checkout</h2>
        <p className="empty-note">Your cart is empty — nothing to check out yet.</p>
        <a className="btn btn-red" href="#/shop">
          Shop Now →
        </a>
      </section>
    );
  }

  const submit = (e: React.FormEvent) => {
    e.preventDefault();
    const lines = items
      .map(i => {
        const p = getProduct(i.id);
        return p ? { id: p.id, name: p.name, qty: i.qty, price: p.price } : null;
      })
      .filter((l): l is NonNullable<typeof l> => l !== null);
    const order = placeOrder({ email, username, payment, items: lines, total });
    clear();
    setPlaced(order);
    window.scrollTo({ top: 0 });
  };

  return (
    <section className="narrow-page page-top">
      <h2 className="section-title">Checkout</h2>
      <div className="checkout-grid">
        <form className="checkout-form" onSubmit={submit}>
          <label>
            Email address
            <input
              type="email"
              required
              placeholder="you@email.com"
              value={email}
              onChange={e => setEmail(e.target.value)}
            />
          </label>
          <label>
            Roblox username
            <input
              type="text"
              required
              placeholder="Your in-game name"
              value={username}
              onChange={e => setUsername(e.target.value)}
            />
          </label>
          <span className="field-label">Payment method</span>
          <div className="pay-tabs">
            {PAYMENT_METHODS.map(m => (
              <button
                type="button"
                key={m}
                className={`game-tab ${payment === m ? 'active' : ''}`}
                onClick={() => setPayment(m)}
              >
                {m}
              </button>
            ))}
          </div>
          <p className="pay-note">
            Demo checkout — no real payment is taken yet. Hook up Stripe/PayPal later and this
            form is ready to go.
          </p>
          <button type="submit" className="btn btn-red checkout-btn">
            Place Order — {formatMoney(total)}
          </button>
        </form>
        <aside className="order-summary">
          <h3>Order Summary</h3>
          {items.map(i => {
            const p = getProduct(i.id);
            if (!p) return null;
            return (
              <div className="summary-row" key={i.id}>
                <span>
                  {p.name} × {i.qty}
                </span>
                <span>{formatMoney(p.price * i.qty)}</span>
              </div>
            );
          })}
          <div className="summary-row summary-total">
            <span>Total</span>
            <span>{formatMoney(total)}</span>
          </div>
        </aside>
      </div>
      <button className="link-btn" onClick={() => navigate('/cart')}>
        ← Back to cart
      </button>
    </section>
  );
}
