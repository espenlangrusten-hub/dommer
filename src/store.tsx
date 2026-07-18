import React, {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
} from 'react';
import { getProduct } from './products';

/** Passcode for the /#/admin dashboard. Change this to your own secret. */
export const ADMIN_PASSCODE = 'garden123';

// ---------- localStorage helpers ----------

function load<T>(key: string, fallback: T): T {
  try {
    const raw = localStorage.getItem(key);
    return raw ? (JSON.parse(raw) as T) : fallback;
  } catch {
    return fallback;
  }
}

function save(key: string, value: unknown) {
  try {
    localStorage.setItem(key, JSON.stringify(value));
  } catch {
    // storage full or blocked — ignore
  }
}

// ---------- Cart ----------

export interface CartItem {
  id: string;
  qty: number;
}

interface CartContextValue {
  items: CartItem[];
  add: (id: string, qty?: number) => void;
  remove: (id: string) => void;
  setQty: (id: string, qty: number) => void;
  clear: () => void;
  count: number;
  total: number;
}

const CartContext = createContext<CartContextValue | null>(null);

export function CartProvider({ children }: { children: React.ReactNode }) {
  const [items, setItems] = useState<CartItem[]>(() => load('gs_cart', []));

  useEffect(() => {
    save('gs_cart', items);
  }, [items]);

  const add = useCallback((id: string, qty = 1) => {
    setItems(prev => {
      const existing = prev.find(i => i.id === id);
      if (existing) {
        return prev.map(i => (i.id === id ? { ...i, qty: i.qty + qty } : i));
      }
      return [...prev, { id, qty }];
    });
  }, []);

  const remove = useCallback((id: string) => {
    setItems(prev => prev.filter(i => i.id !== id));
  }, []);

  const setQty = useCallback((id: string, qty: number) => {
    setItems(prev =>
      qty <= 0 ? prev.filter(i => i.id !== id) : prev.map(i => (i.id === id ? { ...i, qty } : i))
    );
  }, []);

  const clear = useCallback(() => setItems([]), []);

  const { count, total } = useMemo(() => {
    let c = 0;
    let t = 0;
    for (const item of items) {
      const p = getProduct(item.id);
      if (!p) continue;
      c += item.qty;
      t += p.price * item.qty;
    }
    return { count: c, total: t };
  }, [items]);

  const value = useMemo(
    () => ({ items, add, remove, setQty, clear, count, total }),
    [items, add, remove, setQty, clear, count, total]
  );

  return <CartContext.Provider value={value}>{children}</CartContext.Provider>;
}

export function useCart(): CartContextValue {
  const ctx = useContext(CartContext);
  if (!ctx) throw new Error('useCart must be used inside CartProvider');
  return ctx;
}

// ---------- Orders ----------

export interface OrderLine {
  id: string;
  name: string;
  qty: number;
  price: number;
}

export interface Order {
  id: string;
  date: number;
  email: string;
  username: string;
  payment: string;
  items: OrderLine[];
  total: number;
  status: 'Preparing delivery' | 'Delivered';
}

export function loadOrders(): Order[] {
  return load<Order[]>('gs_orders', []);
}

export function placeOrder(order: Omit<Order, 'id' | 'date' | 'status'>): Order {
  const id =
    'GS-' +
    Math.random().toString(36).slice(2, 6).toUpperCase() +
    Math.random().toString(36).slice(2, 6).toUpperCase();
  const full: Order = { ...order, id, date: Date.now(), status: 'Preparing delivery' };
  const orders = loadOrders();
  orders.unshift(full);
  save('gs_orders', orders);
  return full;
}

export function findOrder(id: string, email: string): Order | undefined {
  return loadOrders().find(
    o => o.id.toUpperCase() === id.trim().toUpperCase() && o.email.toLowerCase() === email.trim().toLowerCase()
  );
}

// ---------- Analytics (visits + presence) ----------
// NOTE: this site is fully static (GitHub Pages), so stats are stored in the
// browser's localStorage. They cover this browser/device only — plugging in a
// real backend later will make them global.

interface Stats {
  totalVisits: number;
  days: Record<string, number>;
}

function todayKey(): string {
  return new Date().toISOString().slice(0, 10);
}

export function initAnalytics() {
  // Count one visit per browser session.
  if (!sessionStorage.getItem('gs_visited')) {
    sessionStorage.setItem('gs_visited', '1');
    const stats = load<Stats>('gs_stats', { totalVisits: 0, days: {} });
    stats.totalVisits += 1;
    stats.days[todayKey()] = (stats.days[todayKey()] || 0) + 1;
    save('gs_stats', stats);
  }

  // Presence heartbeat: lets the admin page count tabs open right now.
  let tabId = sessionStorage.getItem('gs_tab');
  if (!tabId) {
    tabId = Math.random().toString(36).slice(2, 10);
    sessionStorage.setItem('gs_tab', tabId);
  }
  const beat = () => {
    const presence = load<Record<string, number>>('gs_presence', {});
    const now = Date.now();
    presence[tabId as string] = now;
    for (const key of Object.keys(presence)) {
      if (now - presence[key] > 60_000) delete presence[key];
    }
    save('gs_presence', presence);
  };
  beat();
  const interval = window.setInterval(beat, 15_000);
  window.addEventListener('beforeunload', () => {
    window.clearInterval(interval);
    const presence = load<Record<string, number>>('gs_presence', {});
    delete presence[tabId as string];
    save('gs_presence', presence);
  });
}

export function getOnlineCount(): number {
  const presence = load<Record<string, number>>('gs_presence', {});
  const now = Date.now();
  return Object.values(presence).filter(ts => now - ts <= 45_000).length;
}

export function getStats(): { totalVisits: number; visitsToday: number } {
  const stats = load<Stats>('gs_stats', { totalVisits: 0, days: {} });
  return { totalVisits: stats.totalVisits, visitsToday: stats.days[todayKey()] || 0 };
}

export function resetStats() {
  localStorage.removeItem('gs_stats');
  localStorage.removeItem('gs_orders');
}

export function formatMoney(n: number): string {
  return '$' + n.toFixed(2);
}
