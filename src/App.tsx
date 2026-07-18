import React, { useEffect, useState } from 'react';
import './App.css';
import { FloatingWidgets, Footer, Header, ToastProvider } from './components';
import Admin from './pages/Admin';
import CartPage from './pages/CartPage';
import Checkout from './pages/Checkout';
import Claim from './pages/Claim';
import Home from './pages/Home';
import Shop from './pages/Shop';
import { CartProvider, initAnalytics } from './store';

function useHashRoute(): string {
  const [route, setRoute] = useState(() => window.location.hash.replace(/^#/, '') || '/');
  useEffect(() => {
    const onChange = () => {
      setRoute(window.location.hash.replace(/^#/, '') || '/');
      window.scrollTo({ top: 0 });
    };
    window.addEventListener('hashchange', onChange);
    return () => window.removeEventListener('hashchange', onChange);
  }, []);
  return route;
}

function Page({ route }: { route: string }) {
  switch (route) {
    case '/shop':
      return <Shop />;
    case '/cart':
      return <CartPage />;
    case '/checkout':
      return <Checkout />;
    case '/claim':
      return <Claim />;
    case '/admin':
      return <Admin />;
    default:
      return <Home />;
  }
}

function App() {
  const route = useHashRoute();

  useEffect(() => {
    initAnalytics();
  }, []);

  return (
    <CartProvider>
      <ToastProvider>
        <div className="site">
          <Header />
          <main>
            <Page route={route} />
          </main>
          <Footer />
          <FloatingWidgets />
        </div>
      </ToastProvider>
    </CartProvider>
  );
}

export default App;
