import React, { useEffect, useState } from 'react';
import type { User } from '@supabase/supabase-js';
import { supabase } from '../supabase';
import KamperTab from './KamperTab';
import RegistrerKampTab from './RegistrerKampTab';
import MinProfilTab from './MinProfilTab';

type Fane = 'kamper' | 'registrer' | 'profil';

interface Props {
  bruker: User;
  onLoggUt: () => void;
}

export default function DommerDashboard({ bruker, onLoggUt }: Props) {
  const [fane, setFane] = useState<Fane>('kamper');
  const [klubbId, setKlubbId] = useState<string | null>(null);
  const [feil, setFeil] = useState('');

  useEffect(() => {
    init();
  }, [bruker.id]);

  const init = async () => {
    const { data: membership } = await supabase
      .from('referee_memberships')
      .select('club_id')
      .eq('referee_id', bruker.id)
      .single();

    if (membership) {
      setKlubbId(membership.club_id);
      return;
    }

    const inviteCode = bruker.user_metadata?.invite_code;
    if (!inviteCode) { setFeil('Ingen dommerkode registrert.'); return; }

    const { data: klubb, error } = await supabase
      .from('clubs')
      .select('id')
      .eq('referee_code', inviteCode)
      .single();

    if (error || !klubb) { setFeil('Ugyldig dommerkode. Ta kontakt med klubben.'); return; }

    await supabase.from('referee_memberships').insert({ referee_id: bruker.id, club_id: klubb.id });
    setKlubbId(klubb.id);
  };

  if (feil) {
    return (
      <div className="login-page">
        <div className="login-container">
          <div className="login-logo"><h1>DommerJob</h1></div>
          <div className="login-form">
            <p className="feil-melding">{feil}</p>
            <button className="login-btn loggut-btn" onClick={onLoggUt}>Logg ut</button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="dommer-dashboard">
      <header className="dash-header">
        <div className="dash-logo">
          <div className="klubb-ikon-placeholder">D</div>
          <span className="dash-klubbnavn">DommerJob</span>
        </div>
      </header>

      <main className="dommer-innhold">
        {fane === 'kamper' && <KamperTab klubbId={klubbId} />}
        {fane === 'registrer' && <RegistrerKampTab refereeId={bruker.id} klubbId={klubbId} />}
        {fane === 'profil' && <MinProfilTab bruker={bruker} onLoggUt={onLoggUt} />}
      </main>

      <nav className="bunn-nav">
        <button className={`bunn-nav-knapp ${fane === 'kamper' ? 'active' : ''}`} onClick={() => setFane('kamper')}>
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
            <rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/>
          </svg>
          Kamper
        </button>
        <button className={`bunn-nav-knapp ${fane === 'registrer' ? 'active' : ''}`} onClick={() => setFane('registrer')}>
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
            <circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="16"/><line x1="8" y1="12" x2="16" y2="12"/>
          </svg>
          Registrer kamp
        </button>
        <button className={`bunn-nav-knapp ${fane === 'profil' ? 'active' : ''}`} onClick={() => setFane('profil')}>
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
            <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/>
          </svg>
          Min profil
        </button>
      </nav>
    </div>
  );
}
