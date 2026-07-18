import React from 'react';
import { CardArt } from '../art';
import { getProduct } from '../products';
import { formatMoney, useCart } from '../store';

export default function CartPage() {
  const { items, remove, setQty, total } = useCart();

  if (items.length === 0) {
    return (
      <section className="narrow-page page-top">
        <h2 className="section-title">Your Cart</h2>
        <p className="empty-note">Your cart is empty. Go grab some pets! 🦝</p>
        <a className="btn btn-red" href="#/shop">
          Shop Now →
        </a>
      </section>
    );
  }

  return (
    <section className="narrow-page page-top">
      <h2 className="section-title">Your Cart</h2>
      <div className="cart-list">
        {items.map(item => {
          const p = getProduct(item.id);
          if (!p) return null;
          return (
            <div className="cart-row" key={item.id}>
              <div className="cart-thumb">
                <CardArt kind={p.art} />
              </div>
              <div className="cart-info">
                <strong>{p.name}</strong>
                <span className="price">{formatMoney(p.price)}</span>
              </div>
              <div className="qty-controls">
                <button className="qty-btn" onClick={() => setQty(item.id, item.qty - 1)} aria-label="Decrease">
                  −
                </button>
                <span className="qty">{item.qty}</span>
                <button className="qty-btn" onClick={() => setQty(item.id, item.qty + 1)} aria-label="Increase">
                  +
                </button>
              </div>
              <span className="cart-line-total">{formatMoney(p.price * item.qty)}</span>
              <button className="remove-btn" onClick={() => remove(item.id)} aria-label="Remove">
                ✕
              </button>
            </div>
          );
        })}
      </div>
      <div className="cart-summary">
        <span>Total</span>
        <strong>{formatMoney(total)}</strong>
      </div>
      <a className="btn btn-red checkout-btn" href="#/checkout">
        Proceed to Checkout →
      </a>
    </section>
  );
}
