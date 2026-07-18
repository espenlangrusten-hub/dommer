import React, { useEffect, useState } from 'react';
import {
  ADMIN_PASSCODE,
  formatMoney,
  getOnlineCount,
  getStats,
  loadOrders,
  resetStats,
} from '../store';

export default function Admin() {
  const [authed, setAuthed] = useState(() => sessionStorage.getItem('gs_admin') === '1');
  const [pass, setPass] = useState('');
  const [error, setError] = useState(false);
  const [tick, setTick] = useState(0);

  // Refresh the dashboard every 5 seconds so "online now" stays live.
  useEffect(() => {
    if (!authed) return;
    const t = window.setInterval(() => setTick(x => x + 1), 5000);
    return () => window.clearInterval(t);
  }, [authed]);

  if (!authed) {
    return (
      <section className="narrow-page page-top">
        <h2 className="section-title">Owner Login</h2>
        <form
          className="checkout-form claim-form"
          onSubmit={e => {
            e.preventDefault();
            if (pass === ADMIN_PASSCODE) {
              sessionStorage.setItem('gs_admin', '1');
              setAuthed(true);
            } else {
              setError(true);
            }
          }}
        >
          <label>
            Passcode
            <input
              type="password"
              required
              placeholder="••••••••"
              value={pass}
              onChange={e => {
                setPass(e.target.value);
                setError(false);
              }}
            />
          </label>
          {error && <p className="error-note">Wrong passcode.</p>}
          <button type="submit" className="btn btn-red">
            Log In →
          </button>
        </form>
      </section>
    );
  }

  void tick; // dashboard re-renders on the interval above
  const orders = loadOrders();
  const stats = getStats();
  const revenue = orders.reduce((sum, o) => sum + o.total, 0);

  return (
    <section className="wide-page page-top">
      <div className="admin-head">
        <h2 className="section-title">Owner Dashboard</h2>
        <button
          className="link-btn"
          onClick={() => {
            sessionStorage.removeItem('gs_admin');
            window.location.hash = '/';
          }}
        >
          Log out
        </button>
      </div>

      <div className="stat-tiles">
        <div className="stat-tile">
          <span className="stat-tile-value green-text">
            <span className="pulse-dot" /> {getOnlineCount()}
          </span>
          <span className="stat-tile-label">Online right now</span>
        </div>
        <div className="stat-tile">
          <span className="stat-tile-value">{stats.visitsToday}</span>
          <span className="stat-tile-label">Visitors today</span>
        </div>
        <div className="stat-tile">
          <span className="stat-tile-value">{stats.totalVisits}</span>
          <span className="stat-tile-label">Total visitors</span>
        </div>
        <div className="stat-tile">
          <span className="stat-tile-value">{orders.length}</span>
          <span className="stat-tile-label">Orders (buyers)</span>
        </div>
        <div className="stat-tile">
          <span className="stat-tile-value">{formatMoney(revenue)}</span>
          <span className="stat-tile-label">Revenue</span>
        </div>
      </div>

      <p className="pay-note admin-note">
        This site is hosted statically (GitHub Pages), so stats are stored in each visitor's own
        browser — the numbers above only cover <em>this</em> device. To count every visitor and
        order globally, connect a small backend (e.g. Firebase) later.
      </p>

      <h3 className="admin-sub">Orders</h3>
      {orders.length === 0 ? (
        <p className="empty-note">No orders yet.</p>
      ) : (
        <div className="table-wrap">
          <table className="orders-table">
            <thead>
              <tr>
                <th>Order ID</th>
                <th>Date</th>
                <th>Email</th>
                <th>Roblox user</th>
                <th>Items</th>
                <th>Total</th>
                <th>Status</th>
              </tr>
            </thead>
            <tbody>
              {orders.map(o => (
                <tr key={o.id}>
                  <td className="order-id">{o.id}</td>
                  <td>{new Date(o.date).toLocaleString()}</td>
                  <td>{o.email}</td>
                  <td>{o.username}</td>
                  <td>{o.items.map(l => `${l.name} ×${l.qty}`).join(', ')}</td>
                  <td>{formatMoney(o.total)}</td>
                  <td>{o.status}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      <button
        className="link-btn danger"
        onClick={() => {
          if (window.confirm('Reset all stats and orders on this device?')) {
            resetStats();
            setTick(x => x + 1);
          }
        }}
      >
        Reset stats &amp; orders
      </button>
    </section>
  );
}
