import React, { useState, useEffect } from 'react';
import { supabase } from './supabase';
import type { User } from '@supabase/supabase-js';
import KlubbDashboard from './components/KlubbDashboard';
import './App.css';

type Role = 'dommer' | 'klubb';
type Tab = 'logginn' | 'registrer';

function App() {
  const [bruker, setBruker] = useState<User | null>(null);
  const [laster, setLaster] = useState(true);
  const [rolle, setRolle] = useState<Role>('dommer');
  const [fane, setFane] = useState<Tab>('logginn');
  const [epost, setEpost] = useState('');
  const [passord, setPassord] = useState('');
  const [navn, setNavn] = useState('');
  const [feil, setFeil] = useState('');
  const [melding, setMelding] = useState('');
  const [sender, setSender] = useState(false);

  useEffect(() => {
    supabase.auth.getSession().then(({ data }) => {
      setBruker(data.session?.user ?? null);
      setLaster(false);
    });
    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      setBruker(session?.user ?? null);
    });
    return () => subscription.unsubscribe();
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setFeil('');
    setMelding('');
    setSender(true);

    if (fane === 'registrer') {
      const { error } = await supabase.auth.signUp({
        email: epost,
        password: passord,
        options: { data: { navn, rolle } },
      });
      if (error) {
        setFeil(error.message);
      } else {
        setMelding('Sjekk e-posten din for å bekrefte kontoen.');
      }
    } else {
      const { error } = await supabase.auth.signInWithPassword({ email: epost, password: passord });
      if (error) setFeil('Feil e-post eller passord.');
    }
    setSender(false);
  };

  const loggUt = async () => {
    await supabase.auth.signOut();
  };

  if (laster) return null;

  if (bruker) {
    const brukerRolle = bruker.user_metadata?.rolle ?? 'dommer';

    if (brukerRolle === 'klubb') {
      return <KlubbDashboard userId={bruker.id} onLoggUt={loggUt} />;
    }

    return (
      <div className="login-page">
        <div className="login-container">
          <div className="login-logo">
            <h1>DommerJob</h1>
            <p>Kobler dommere og klubber</p>
          </div>
          <div className="login-form">
            <h2>Velkommen, {bruker.user_metadata?.navn ?? bruker.email}!</h2>
            <p className="bruker-info">
              Logget inn som <strong>Dommer</strong><br />{bruker.email}
            </p>
            <button className="login-btn loggut-btn" onClick={loggUt}>Logg ut</button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="login-page">
      <div className="login-container">
        <div className="login-logo">
          <h1>DommerJob</h1>
          <p>Kobler dommere og klubber</p>
        </div>

        <div className="role-selector">
          <div
            className={`role-card ${rolle === 'dommer' ? 'active' : ''}`}
            onClick={() => setRolle('dommer')}
          >
            <span className="role-label">Dommer</span>
          </div>
          <div
            className={`role-card ${rolle === 'klubb' ? 'active' : ''}`}
            onClick={() => setRolle('klubb')}
          >
            <span className="role-label">Klubb</span>
          </div>
        </div>

        <div className="login-form">
          <div className="fane-velger">
            <button
              className={`fane-btn ${fane === 'logginn' ? 'active' : ''}`}
              onClick={() => { setFane('logginn'); setFeil(''); setMelding(''); }}
            >
              Logg inn
            </button>
            <button
              className={`fane-btn ${fane === 'registrer' ? 'active' : ''}`}
              onClick={() => { setFane('registrer'); setFeil(''); setMelding(''); }}
            >
              Registrer
            </button>
          </div>

          <form onSubmit={handleSubmit}>
            {fane === 'registrer' && (
              <div className="form-group">
                <label htmlFor="navn">Navn</label>
                <input
                  id="navn"
                  type="text"
                  placeholder="Ditt navn"
                  value={navn}
                  onChange={e => setNavn(e.target.value)}
                  required
                />
              </div>
            )}
            <div className="form-group">
              <label htmlFor="epost">E-postadresse</label>
              <input
                id="epost"
                type="email"
                placeholder="din@epost.no"
                value={epost}
                onChange={e => setEpost(e.target.value)}
                required
              />
            </div>
            <div className="form-group">
              <label htmlFor="passord">Passord</label>
              <input
                id="passord"
                type="password"
                placeholder="••••••••"
                value={passord}
                onChange={e => setPassord(e.target.value)}
                required
              />
            </div>

            {feil && <p className="feil-melding">{feil}</p>}
            {melding && <p className="suksess-melding">{melding}</p>}

            <button type="submit" className="login-btn" disabled={sender}>
              {sender ? 'Vennligst vent...' : fane === 'logginn' ? 'Logg inn' : 'Opprett konto'}
            </button>
          </form>
        </div>
      </div>
    </div>
  );
}

export default App;
