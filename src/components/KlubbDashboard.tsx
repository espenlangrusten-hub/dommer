import React, { useEffect, useState } from 'react';
import { supabase } from '../supabase';
import OpprettKlubb from './OpprettKlubb';
import OpprettKamp from './OpprettKamp';

interface Klubb {
  id: string;
  name: string;
  icon_url: string | null;
}

interface Kamp {
  id: string;
  home_team: string;
  away_team: string;
  match_date: string;
  age_group: string;
}

interface Props {
  userId: string;
  onLoggUt: () => void;
}

export default function KlubbDashboard({ userId, onLoggUt }: Props) {
  const [klubb, setKlubb] = useState<Klubb | null>(null);
  const [kamper, setKamper] = useState<Kamp[]>([]);
  const [antallDommere, setAntallDommere] = useState(0);
  const [laster, setLaster] = useState(true);
  const [visOpprettKamp, setVisOpprettKamp] = useState(false);

  const hentKlubb = async () => {
    const { data } = await supabase
      .from('clubs')
      .select('*')
      .eq('user_id', userId)
      .single();
    setKlubb(data ?? null);
    if (data) await hentKamper(data.id);
    setLaster(false);
  };

  const hentKamper = async (clubId: string) => {
    const { data } = await supabase
      .from('matches')
      .select('*')
      .eq('club_id', clubId)
      .order('match_date', { ascending: true });
    setKamper(data ?? []);
  };

  useEffect(() => {
    hentKlubb();
  }, [userId]);

  const formatDato = (iso: string) => {
    const d = new Date(iso);
    return d.toLocaleDateString('nb-NO', {
      weekday: 'short', day: 'numeric', month: 'long', year: 'numeric',
    }) + ' kl. ' + d.toLocaleTimeString('nb-NO', { hour: '2-digit', minute: '2-digit' });
  };

  if (laster) return <div className="login-page"><p>Laster...</p></div>;

  if (!klubb) {
    return <OpprettKlubb userId={userId} onKlubbOpprettet={hentKlubb} />;
  }

  return (
    <div className="dashboard">
      <header className="dash-header">
        <div className="dash-logo">
          {klubb.icon_url ? (
            <img src={klubb.icon_url} alt="Klubbikon" className="klubb-ikon" />
          ) : (
            <div className="klubb-ikon-placeholder">{klubb.name[0]}</div>
          )}
          <span className="dash-klubbnavn">{klubb.name}</span>
        </div>
        <button className="loggut-knapp" onClick={onLoggUt}>Logg ut</button>
      </header>

      <main className="dash-innhold">
        <div className="statistikk-kort">
          <div className="stat-tall">{antallDommere}</div>
          <div className="stat-label">Dommere i klubben</div>
        </div>

        <div className="seksjon-header">
          <h2>Kamper</h2>
        </div>

        {kamper.length === 0 ? (
          <p className="ingen-kamper">Ingen kamper lagt ut ennå.</p>
        ) : (
          <div className="kamp-liste">
            {kamper.map(kamp => (
              <div className="kamp-kort" key={kamp.id}>
                <div className="kamp-lag">
                  <span>{kamp.home_team}</span>
                  <span className="vs">vs</span>
                  <span>{kamp.away_team}</span>
                </div>
                <div className="kamp-info">
                  <span className="aldersgruppe-badge">{kamp.age_group}</span>
                  <span className="kamp-dato">{formatDato(kamp.match_date)}</span>
                </div>
              </div>
            ))}
          </div>
        )}

        <button className="ny-kamp-knapp" onClick={() => setVisOpprettKamp(true)}>
          + Opprett ny kamp
        </button>
      </main>

      {visOpprettKamp && (
        <OpprettKamp
          clubId={klubb.id}
          onLukk={() => setVisOpprettKamp(false)}
          onKampPostet={() => {
            setVisOpprettKamp(false);
            hentKamper(klubb.id);
          }}
        />
      )}
    </div>
  );
}
