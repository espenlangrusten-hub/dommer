import React, { useEffect, useState } from 'react';
import './App.css';

type Page = 'home' | 'work' | 'about' | 'pricing';

const clients = [
  { name: 'StudioErrors', subs: '30K+ Subs', color: '#6c5ce7' },
  { name: 'Voltraz', subs: '30K+ Subs', color: '#0984e3' },
  { name: 'Foltyn', subs: '10M+ Subs', color: '#e17055' },
  { name: 'TanqR', subs: '5M+ Subs', color: '#00cec9' },
  { name: 'Uzoth', subs: '4M+ Subs', color: '#fdcb6e' },
  { name: 'MitchMarsell', subs: '2M+ Subs', color: '#fab1a0' },
  { name: 'MrBooshot', subs: '2M+ Subs', color: '#d63031' },
  { name: 'KaiM', subs: '300K+ Subs', color: '#a29bfe' },
];

const recentWork = [
  { name: 'Uzoth', tag: '1/10 Rank by views', tagColor: '#8e44ad', gradient: 'linear-gradient(135deg,#1b9cfc,#3b3b98)' },
  { name: 'TanqR', tag: '200K Views in 24h', tagColor: '#d63031', gradient: 'linear-gradient(135deg,#2d3436,#000)' },
  { name: 'Foltyn', tag: '2.2M Views', tagColor: '#0984e3', gradient: 'linear-gradient(135deg,#e17055,#fdcb6e)' },
];

const workFilters = ['Before/After', 'Cartoony', 'Realistic'] as const;

const beforeAfter = [
  { gradA: 'linear-gradient(135deg,#74b9ff,#0984e3)', gradB: 'linear-gradient(135deg,#e17055,#d63031)' },
  { gradA: 'linear-gradient(135deg,#2d3436,#636e72)', gradB: 'linear-gradient(135deg,#00cec9,#0984e3)' },
  { gradA: 'linear-gradient(135deg,#636e72,#2d3436)', gradB: 'linear-gradient(135deg,#fdcb6e,#e17055)' },
  { gradA: 'linear-gradient(135deg,#b2bec3,#636e72)', gradB: 'linear-gradient(135deg,#00b894,#0984e3)' },
  { gradA: 'linear-gradient(135deg,#dfe6e9,#636e72)', gradB: 'linear-gradient(135deg,#fab1a0,#e17055)' },
  { gradA: 'linear-gradient(135deg,#a29bfe,#6c5ce7)', gradB: 'linear-gradient(135deg,#fd79a8,#d63031)' },
];

const collabWork = [
  { gradA: 'linear-gradient(135deg,#636e72,#2d3436)', gradB: 'linear-gradient(135deg,#00cec9,#0984e3)' },
  { gradA: 'linear-gradient(135deg,#d35400,#8e7a34)', gradB: 'linear-gradient(135deg,#e17055,#d63031)' },
  { gradA: 'linear-gradient(135deg,#0984e3,#74b9ff)', gradB: 'linear-gradient(135deg,#fdcb6e,#e17055)' },
];

function getPageFromHash(): Page {
  const hash = window.location.hash.replace('#', '');
  if (hash === 'work' || hash === 'about' || hash === 'pricing') return hash;
  return 'home';
}

function App() {
  const [page, setPage] = useState<Page>(getPageFromHash());
  const [filter, setFilter] = useState<typeof workFilters[number]>('Before/After');

  useEffect(() => {
    const onHashChange = () => setPage(getPageFromHash());
    window.addEventListener('hashchange', onHashChange);
    return () => window.removeEventListener('hashchange', onHashChange);
  }, []);

  const navigate = (p: Page) => {
    window.location.hash = p === 'home' ? 'home' : p;
    setPage(p);
  };

  return (
    <div className="site">
      <nav className="navbar">
        <div className="logo" onClick={() => navigate('home')}>jac0ob</div>
        <div className="nav-links">
          <button className={page === 'home' ? 'active' : ''} onClick={() => navigate('home')}>Home</button>
          <button className={page === 'work' ? 'active' : ''} onClick={() => navigate('work')}>Work</button>
          <button className={page === 'about' ? 'active' : ''} onClick={() => navigate('about')}>About</button>
          <button className={page === 'pricing' ? 'active' : ''} onClick={() => navigate('pricing')}>Pricing</button>
        </div>
        <button className="contact-btn">Get In Contact <span>&rarr;</span></button>
      </nav>

      {page === 'home' && (
        <>
          <header className="hero">
            <div className="pill"><span className="dot" /> ROBLOX THUMBNAIL ARTIST</div>
            <h1>Thumbnails That <span className="accent">Get Clicks</span></h1>
            <p className="subtitle">I design high-CTR Roblox thumbnails trusted by creators with millions of subscribers.</p>
            <div className="hero-actions">
              <button className="primary-btn" onClick={() => navigate('pricing')}>Get In Contact</button>
              <button className="secondary-btn" onClick={() => navigate('work')}>View Work</button>
            </div>
          </header>

          <section className="clients-strip">
            {clients.map(c => (
              <div className="client" key={c.name}>
                <div className="client-avatar" style={{ background: c.color }} />
                <div>
                  <div className="client-name">{c.name}</div>
                  <div className="client-subs">{c.subs}</div>
                </div>
              </div>
            ))}
          </section>

          <section className="recent-work">
            <div className="section-heading">
              <div>
                <h2>Recent Work</h2>
                <p className="muted">Updates weekly!</p>
              </div>
              <button className="link-btn" onClick={() => navigate('work')}>VIEW ALL &rarr;</button>
            </div>
            <div className="work-grid">
              {recentWork.map(w => (
                <div className="work-card" key={w.name}>
                  <div className="work-thumb" style={{ background: w.gradient }}>
                    <span className="work-tag" style={{ background: w.tagColor }}>{w.tag}</span>
                  </div>
                  <div className="work-name">{w.name}</div>
                </div>
              ))}
            </div>
          </section>

          <section className="cta-banner">
            <h2>Ready to stand out?</h2>
            <p className="muted">Slots fill up fast. Secure your spot in my queue today and let's create something amazing.</p>
            <button className="primary-btn">Get in Contact</button>
          </section>
        </>
      )}

      {page === 'work' && (
        <section className="work-page">
          <h1 className="page-title">Past Work</h1>
          <div className="filter-tabs">
            {workFilters.map(f => (
              <button
                key={f}
                className={filter === f ? 'tab active' : 'tab'}
                onClick={() => setFilter(f)}
              >
                {f}
              </button>
            ))}
          </div>

          <h3 className="subheading">My Recents</h3>
          <div className="ba-grid">
            {beforeAfter.map((b, i) => (
              <div className="ba-card" key={i}>
                <div className="ba-half" style={{ background: b.gradA }}>
                  <span className="tool-badge">Blender</span>
                </div>
                <div className="ba-half" style={{ background: b.gradB }}>
                  <span className="tool-badge">Ps</span>
                </div>
              </div>
            ))}
          </div>

          <h3 className="subheading">Thumbnails in collaboration with <span className="accent">IrfanDesigns</span></h3>
          <div className="ba-grid">
            {collabWork.map((b, i) => (
              <div className="ba-card" key={i}>
                <div className="ba-half" style={{ background: b.gradA }} />
                <div className="ba-half" style={{ background: b.gradB }} />
              </div>
            ))}
          </div>
        </section>
      )}

      {page === 'about' && (
        <section className="about-page">
          <div className="about-grid">
            <div className="about-text">
              <div className="pill"><span className="dot" /> GMT+1 (WINTER) / GMT+2 (SUMMER)</div>
              <h1>About jac0ob</h1>
              <p>My name is <strong>jac0ob</strong>, I'm a Roblox thumbnail artist with years of experience creating eye-catching thumbnails for top creators.</p>
              <p>I've worked with some of the biggest names in the Roblox community and my thumbnails have helped drive massive growth in views and engagement.</p>
              <p>My focus is on creating effective thumbnails that drive high <span className="accent">CTR</span> and consistent viewer engagement.</p>
              <div className="stack-label">SOFTWARE STACK</div>
              <div className="stack-badges">
                <span className="stack-badge">Roblox Studio</span>
                <span className="stack-badge">Blender</span>
                <span className="stack-badge">Photoshop</span>
              </div>
            </div>
            <div className="stats-grid">
              <div className="stat-card"><div className="stat-number">180M+</div><div className="stat-label">TOTAL VIEWS GENERATED</div></div>
              <div className="stat-card"><div className="stat-number">90+</div><div className="stat-label">SATISFIED CLIENTS</div></div>
              <div className="stat-card"><div className="stat-number">400+</div><div className="stat-label">THUMBNAILS CREATED</div></div>
              <div className="stat-card"><div className="stat-stars">★★★★★</div><div className="stat-label">80+ REVIEWS</div></div>
              <div className="stat-card wide"><div className="stat-number accent">20M+</div><div className="stat-label">COMBINED CLIENT SUBSCRIBERS</div></div>
            </div>
          </div>
        </section>
      )}

      {page === 'pricing' && (
        <section className="pricing-page">
          <h1 className="page-title">Simple Pricing</h1>
          <p className="subtitle center">Professional quality with fast turnaround times.</p>
          <div className="pill center"><span className="dot" /> COMMISSIONS OPEN</div>

          <div className="pricing-grid">
            <div className="price-card">
              <h3>Realistic</h3>
              <div className="price">€70<span>/thumbnail</span></div>
              <ul>
                <li>~36h Delivery Time</li>
                <li>2 Revisions</li>
              </ul>
              <button className="secondary-btn full">Get In Contact</button>
            </div>

            <div className="price-card popular">
              <div className="popular-badge">Most Popular</div>
              <h3>Priority</h3>
              <div className="price">€80<span>/thumbnail</span></div>
              <ul>
                <li>~24h Delivery Time</li>
                <li>Dedicated Slot</li>
              </ul>
              <button className="primary-btn full">Get In Contact</button>
            </div>

            <div className="price-card">
              <h3>Cartoony</h3>
              <div className="price">€60<span>/thumbnail</span></div>
              <ul>
                <li>~36h Delivery Time</li>
                <li>High Quality Renders</li>
              </ul>
              <button className="secondary-btn full">Get In Contact</button>
            </div>
          </div>
        </section>
      )}

      <footer className="footer">
        <div>© {new Date().getFullYear()} jac0ob. All rights reserved.</div>
        <div className="footer-socials">
          <span>𝕏</span>
          <span>◐</span>
        </div>
      </footer>
    </div>
  );
}

export default App;
