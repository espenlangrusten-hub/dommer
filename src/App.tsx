import React, { useEffect, useState } from 'react';
import TikTokLookup from './TikTokLookup';
import DommerLogin from './DommerLogin';

type Route = 'tiktok' | 'dommer';

const ROUTES: Route[] = ['tiktok', 'dommer'];

/**
 * Tiny hash router. Unknown hashes (the "#glemtpassord" style anchors inside
 * the pages) keep you on the page you are already on.
 */
function routeFromHash(fallback: Route): Route {
  const raw = window.location.hash.replace(/^#\/?/, '').toLowerCase();
  return (ROUTES as string[]).includes(raw) ? (raw as Route) : fallback;
}

function App() {
  const [route, setRoute] = useState<Route>(() => routeFromHash('tiktok'));

  useEffect(() => {
    const onHashChange = () => setRoute(current => routeFromHash(current));
    window.addEventListener('hashchange', onHashChange);
    return () => window.removeEventListener('hashchange', onHashChange);
  }, []);

  return route === 'dommer' ? <DommerLogin /> : <TikTokLookup />;
}

export default App;
