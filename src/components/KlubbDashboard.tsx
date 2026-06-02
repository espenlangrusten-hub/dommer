import React, { useEffect, useState, useRef } from 'react';
import { supabase } from '../supabase';
import OpprettKlubb from './OpprettKlubb';
import OpprettKamp from './OpprettKamp';

interface Klubb {
  id: string;
  name: string;
  icon_url: string | null;
  invite_code: string | null;
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

function genererKode(): string {
  const tegn = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  return Array.from({ length: 5 }, () => tegn[Math.floor(Math.random() * tegn.length)]).join('');
}

export default function KlubbDashboard({ userId, onLoggUt }: Props) {
  const [klubb, setKlubb] = useState<Klubb | null>(null);
  const [kamper, setKamper] = useState<Kamp[]>([]);
  const [antallTrenere, setAntallTrenere] = useState(0);
  const [laster, setLaster] = useState(true);
  const [visOpprettKamp, setVisOpprettKamp] = useState(false);
  const [visKodeModal, setVisKodeModal] = useState(false);
  const [kopiertKode, setKopiertKode] = useState(false);
  const knappRef = useRef<HTMLButtonElement>(null);
  const [tilt, setTilt] = useState({ x: 0, y: 0, near: false });

  const handleMouseMove = (e: React.MouseEvent<HTMLButtonElement>) => {
    const btn = knappRef.current;
    if (!btn) return;
    const rect = btn.getBoundingClientRect();
    const cx = rect.left + rect.width / 2;
    const cy = rect.top + rect.height / 2;
    const dx = (e.clientX - cx) / (rect.width / 2);
    const dy = (e.clientY - cy) / (rect.height / 2);
    setTilt({ x: dy * 14, y: -dx * 14, near: true });
  };

  const handleMouseLeave = () => setTilt({ x: 0, y: 0, near: false });

  const hentKlubb = async () => {
    const { data } = await supabase
      .from('clubs')
      .select('*')
      .eq('user_id', userId)
      .single();
    setKlubb(data ?? null);
    if (data) {
      await hentKamper(data.id);
      await hentAntallTrenere(data.id);
    }
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

  const hentAntallTrenere = async (clubId: string) => {
    const { count } = await supabase
      .from('coach_memberships')
      .select('*', { count: 'exact', head: true })
      .eq('club_id', clubId);
    setAntallTrenere(count ?? 0);
  };

  const åpneKodeModal = async () => {
    if (!klubb) return;
    if (!klubb.invite_code) {
      const kode = genererKode();
      const { data } = await supabase
        .from('clubs')
        .update({ invite_code: kode })
        .eq('id', klubb.id)
        .select()
        .single();
      if (data) setKlubb(data);
    }
    setVisKodeModal(true);
  };

  const kopierKode = () => {
    if (klubb?.invite_code) {
      navigator.clipboard.writeText(klubb.invite_code);
      setKopiertKode(true);
      setTimeout(() => setKopiertKode(false), 2000);
    }
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
        <div className="header-knapper">
          <button className="legg-til-trener-knapp" onClick={åpneKodeModal}>
            + Legg til trenere
          </button>
          <button className="loggut-knapp" onClick={onLoggUt}>Logg ut</button>
        </div>
      </header>

      <main className="dash-innhold">
        <div className="statistikk-kort">
          <div className="stat-tall">{antallTrenere}</div>
          <div className="stat-label">Trenere i klubben</div>
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

        <button
          ref={knappRef}
          className="ny-kamp-knapp"
          onClick={() => setVisOpprettKamp(true)}
          onMouseMove={handleMouseMove}
          onMouseLeave={handleMouseLeave}
          style={{
            transform: `perspective(600px) rotateX(${tilt.x}deg) rotateY(${tilt.y}deg) scale(${tilt.near ? 1.04 : 1})`,
            transition: tilt.near ? 'transform 0.08s ease' : 'transform 0.4s ease',
            boxShadow: tilt.near ? '0 8px 30px rgba(37,99,235,0.35)' : undefined,
          }}
        >
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

      {visKodeModal && (
        <div className="modal-overlay" onClick={() => setVisKodeModal(false)}>
          <div className="modal kode-modal" onClick={e => e.stopPropagation()}>
            <div className="modal-header">
              <h2>Trenerkode</h2>
              <button className="lukk-btn" onClick={() => setVisKodeModal(false)}>✕</button>
            </div>
            <p className="kode-beskrivelse">
              Del denne koden med trenere. De oppgir den når de registrerer seg som trener.
            </p>
            <div className="kode-visning" onClick={kopierKode}>
              <span className="kode-tekst">{klubb.invite_code}</span>
              <span className="kopier-hint">{kopiertKode ? 'Kopiert!' : 'Trykk for å kopiere'}</span>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
