import React, { useEffect, useState } from 'react';
import { supabase } from '../supabase';
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
  inviteCode: string | null;
  onLoggUt: () => void;
}

export default function TrenerDashboard({ userId, inviteCode, onLoggUt }: Props) {
  const [klubb, setKlubb] = useState<Klubb | null>(null);
  const [kamper, setKamper] = useState<Kamp[]>([]);
  const [laster, setLaster] = useState(true);
  const [feil, setFeil] = useState('');
  const [visOpprettKamp, setVisOpprettKamp] = useState(false);

  useEffect(() => {
    init();
  }, [userId]);

  const init = async () => {
    // Check if already member
    const { data: membership } = await supabase
      .from('coach_memberships')
      .select('club_id')
      .eq('coach_id', userId)
      .single();

    if (membership) {
      await lastKlubb(membership.club_id);
    } else if (inviteCode) {
      // Join club via invite code
      const { data: klubbData, error: klubbFeil } = await supabase
        .from('clubs')
        .select('id, name, icon_url')
        .eq('invite_code', inviteCode.toUpperCase())
        .single();

      if (klubbFeil || !klubbData) {
        setFeil('Ugyldig klubbkode. Ta kontakt med klubben.');
        setLaster(false);
        return;
      }

      const { error: joinFeil } = await supabase
        .from('coach_memberships')
        .insert({ coach_id: userId, club_id: klubbData.id });

      if (joinFeil) {
        setFeil('Kunne ikke koble til klubb: ' + joinFeil.message);
        setLaster(false);
        return;
      }

      await lastKlubb(klubbData.id);
    } else {
      setFeil('Ingen klubbkode registrert. Registrer deg på nytt med en gyldig kode.');
      setLaster(false);
    }
  };

  const lastKlubb = async (clubId: string) => {
    const { data } = await supabase
      .from('clubs')
      .select('id, name, icon_url')
      .eq('id', clubId)
      .single();
    setKlubb(data ?? null);
    if (data) await lastKamper(data.id);
    setLaster(false);
  };

  const lastKamper = async (clubId: string) => {
    const { data } = await supabase
      .from('matches')
      .select('*')
      .eq('club_id', clubId)
      .order('match_date', { ascending: true });
    setKamper(data ?? []);
  };

  const formatDato = (iso: string) => {
    const d = new Date(iso);
    return d.toLocaleDateString('nb-NO', {
      weekday: 'short', day: 'numeric', month: 'long',
    }) + ' kl. ' + d.toLocaleTimeString('nb-NO', { hour: '2-digit', minute: '2-digit' });
  };

  if (laster) return <div className="login-page"><p>Laster...</p></div>;

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
    <div className="dashboard">
      <header className="dash-header">
        <div className="dash-logo">
          {klubb?.icon_url ? (
            <img src={klubb.icon_url} alt="Klubbikon" className="klubb-ikon" />
          ) : (
            <div className="klubb-ikon-placeholder">{klubb?.name[0]}</div>
          )}
          <div>
            <span className="dash-klubbnavn">{klubb?.name}</span>
            <span className="trener-badge">Trener</span>
          </div>
        </div>
        <button className="loggut-knapp" onClick={onLoggUt}>Logg ut</button>
      </header>

      <main className="dash-innhold">
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

        {klubb && (
          <button className="ny-kamp-knapp" onClick={() => setVisOpprettKamp(true)}>
            + Opprett ny kamp
          </button>
        )}
      </main>

      {visOpprettKamp && klubb && (
        <OpprettKamp
          clubId={klubb.id}
          onLukk={() => setVisOpprettKamp(false)}
          onKampPostet={() => {
            setVisOpprettKamp(false);
            lastKamper(klubb.id);
          }}
        />
      )}
    </div>
  );
}
