import React, { useState, useEffect } from 'react';
import { supabase } from './supabase';
import type { User } from '@supabase/supabase-js';
import KlubbDashboard from './components/KlubbDashboard';
import TrenerDashboard from './components/TrenerDashboard';
import DommerDashboard from './components/DommerDashboard';
import './App.css';

type Role = 'dommer' | 'klubb' | 'trener';
type Tab = 'logginn' | 'registrer';

function App() {
  const [bruker, setBruker] = useState<User | null>(null);
  const [laster, setLaster] = useState(true);
  const [rolle, setRolle] = useState<Role>('dommer');
  const [fane, setFane] = useState<Tab>('logginn');
  const [epost, setEpost] = useState('');
  const [passord, setPassord] = useState('');
  const [navn, setNavn] = useState('');
  const [klubbkode, setKlubbkode] = useState('');
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
      if ((rolle === 'trener' || rolle === 'dommer') && klubbkode.trim().length !== 5) {
        setFeil('Klubbkoden må være 5 tegn.');
        setSender(false);
        return;
      }
      const { error } = await supabase.auth.signUp({
        email: epost,
        password: passord,
        options: { data: { navn, rolle, invite_code: klubbkode.toUpperCase() } },
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

    if (brukerRolle === 'trener') {
      return (
        <TrenerDashboard
          userId={bruker.id}
          inviteCode={bruker.user_metadata?.invite_code ?? null}
          onLoggUt={loggUt}
        />
      );
    }

    return <DommerDashboard bruker={bruker} onLoggUt={loggUt} />;
  }

  return (
    <div className="login-page">
      <div className="login-container">
        <div className="login-logo">
          <h1>DommerJob</h1>
          <p>Kobler dommere og klubber</p>
        </div>

        <div className="role-selector role-selector-tre">
          {(['dommer', 'klubb', 'trener'] as Role[]).map((r, i) => (
            <div
              key={r}
              className={`role-card ${rolle === r ? 'active' : ''}`}
              onClick={() => setRolle(r)}
              style={{ animationDelay: `${0.1 + i * 0.1}s` }}
            >
              <span className="role-label">
                {r === 'dommer' ? 'Dommer' : r === 'klubb' ? 'Klubb' : 'Trener'}
              </span>
            </div>
          ))}
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

            {fane === 'registrer' && (rolle === 'trener' || rolle === 'dommer') && (
              <div className="form-group">
                <label htmlFor="klubbkode">
                  {rolle === 'trener' ? 'Trenerkode fra klubben' : 'Dommerkode fra klubben'}
                </label>
                <input
                  id="klubbkode"
                  type="text"
                  placeholder="5-tegns kode fra klubben"
                  value={klubbkode}
                  onChange={e => setKlubbkode(e.target.value.toUpperCase())}
                  maxLength={5}
                  required
                  className="kode-input"
                />
              </div>
            )}

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
