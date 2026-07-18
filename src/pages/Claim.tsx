import React, { useState } from 'react';
import { findOrder, formatMoney, Order } from '../store';

export default function Claim() {
  const [orderId, setOrderId] = useState('');
  const [email, setEmail] = useState('');
  const [result, setResult] = useState<Order | null>(null);
  const [searched, setSearched] = useState(false);

  const submit = (e: React.FormEvent) => {
    e.preventDefault();
    setResult(findOrder(orderId, email) ?? null);
    setSearched(true);
  };

  return (
    <section className="narrow-page page-top">
      <h2 className="section-title">Claim Your Order</h2>
      <p className="hero-sub">Enter your order ID and email to check your delivery status.</p>
      <form className="checkout-form claim-form" onSubmit={submit}>
        <label>
          Order ID
          <input
            type="text"
            required
            placeholder="GS-XXXXXXXX"
            value={orderId}
            onChange={e => setOrderId(e.target.value)}
          />
        </label>
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
        <button type="submit" className="btn btn-red">
          Find My Order →
        </button>
      </form>

      {searched && !result && (
        <p className="empty-note">No order found for that ID + email combination.</p>
      )}
      {result && (
        <div className="order-confirm claim-result">
          <h3>
            Order <span className="order-id">{result.id}</span>
          </h3>
          <p>
            Status: <strong className="green-text">{result.status}</strong>
          </p>
          <p>Placed: {new Date(result.date).toLocaleString()}</p>
          <ul>
            {result.items.map(l => (
              <li key={l.id}>
                {l.name} × {l.qty} — {formatMoney(l.price * l.qty)}
              </li>
            ))}
          </ul>
          <p>
            Total: <strong>{formatMoney(result.total)}</strong>
          </p>
          <p className="pay-note">
            Join the private server link sent to your email and we will trade your items to{' '}
            <strong>{result.username}</strong> in-game.
          </p>
        </div>
      )}
    </section>
  );
}
