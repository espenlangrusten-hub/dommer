import React, { useEffect, useState } from 'react';
import { supabase } from '../supabase';
import type { User } from '@supabase/supabase-js';

interface Registrering {
  id: string;
  home_team: string;
  away_team: string;
  match_type: string;
  amount: number;
  status: string;
  created_at: string;
  clubs: { name: string } | null;
}

interface Props {
  bruker: User;
  onLoggUt: () => void;
}

const statusFarge: Record<string, string> = {
  venter: '#f59e0b',
  godkjent: '#3b82f6',
  betalt: '#22c55e',
};

const statusTekst: Record<string, string> = {
  venter: 'Venter',
  godkjent: 'Godkjent',
  betalt: 'Betalt',
};

export default function MinProfilTab({ bruker, onLoggUt }: Props) {
  const [registreringer, setRegistreringer] = useState<Registrering[]>([]);
  const [laster, setLaster] = useState(true);

  useEffect(() => {
    supabase
      .from('referee_registrations')
      .select('*, clubs(name)')
      .eq('referee_id', bruker.id)
      .order('created_at', { ascending: false })
      .then(({ data }) => {
        setRegistreringer((data as Registrering[]) ?? []);
        setLaster(false);
      });
  }, [bruker.id]);

  const totalTjent = registreringer
    .filter(r => r.status === 'betalt')
    .reduce((sum, r) => sum + r.amount, 0);

  const venterBeloep = registreringer
    .filter(r => r.status !== 'betalt')
    .reduce((sum, r) => sum + r.amount, 0);

  return (
    <div className="tab-innhold">
      <h2 className="tab-tittel">Min profil</h2>

      <div className="profil-kort">
        <div className="profil-avatar">{(bruker.user_metadata?.navn ?? bruker.email ?? 'D')[0].toUpperCase()}</div>
        <div>
          <div className="profil-navn">{bruker.user_metadata?.navn ?? 'Dommer'}</div>
          <div className="profil-epost">{bruker.email}</div>
        </div>
      </div>

      <div className="inntekt-grid">
        <div className="inntekt-kort">
          <span className="inntekt-tall">{totalTjent} kr</span>
          <span className="inntekt-label">Totalt tjent</span>
        </div>
        <div className="inntekt-kort">
          <span className="inntekt-tall venter-farge">{venterBeloep} kr</span>
          <span className="inntekt-label">Venter betaling</span>
        </div>
      </div>

      <h3 className="seksjon-undertittel">Kamphistorikk</h3>
      {laster ? (
        <p className="ingen-kamper">Laster...</p>
      ) : registreringer.length === 0 ? (
        <p className="ingen-kamper">Ingen registrerte kamper ennå.</p>
      ) : (
        <div className="historikk-liste">
          {registreringer.map(r => (
            <div className="historikk-rad" key={r.id}>
              <div>
                <div className="historikk-kamp">{r.home_team} vs {r.away_team}</div>
                <div className="historikk-meta">{r.clubs?.name} · {r.match_type}er · {r.amount} kr</div>
              </div>
              <span
                className="status-badge"
                style={{ background: statusFarge[r.status] + '22', color: statusFarge[r.status] }}
              >
                {statusTekst[r.status] ?? r.status}
              </span>
            </div>
          ))}
        </div>
      )}

      <div className="betaling-satser">
        <h3 className="seksjon-undertittel">Betalingssatser</h3>
        {[['5er fotball', 150], ['7er fotball', 200], ['9er fotball', 250], ['11er fotball', 300]].map(([label, kr]) => (
          <div className="sats-rad" key={label}>
            <span>{label}</span>
            <span className="sats-beloep">{kr} kr</span>
          </div>
        ))}
      </div>

      <button className="login-btn loggut-btn" onClick={onLoggUt} style={{ marginTop: 24 }}>
        Logg ut
      </button>
    </div>
  );
}
