import React, { useEffect, useRef, useState } from 'react';
import { supabase } from '../supabase';

interface Kamp {
  id: string;
  home_team: string;
  away_team: string;
  match_date: string;
  age_group: string;
  clubs: { name: string; icon_url: string | null } | null;
}

interface ValgtKamp {
  kamp: Kamp;
}

export default function KamperTab() {
  const [kamper, setKamper] = useState<Kamp[]>([]);
  const [valgt, setValgt] = useState<ValgtKamp | null>(null);
  const [laster, setLaster] = useState(true);

  useEffect(() => {
    supabase
      .from('matches')
      .select('*, clubs(name, icon_url)')
      .order('match_date', { ascending: true })
      .then(({ data }) => {
        setKamper((data as Kamp[]) ?? []);
        setLaster(false);
      });
  }, []);

  const formatDato = (iso: string) => {
    const d = new Date(iso);
    return d.toLocaleDateString('nb-NO', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' });
  };

  const formatTid = (iso: string) =>
    new Date(iso).toLocaleTimeString('nb-NO', { hour: '2-digit', minute: '2-digit' });

  if (laster) return <div className="tab-laster">Laster kamper...</div>;

  if (valgt) {
    const k = valgt.kamp;
    return (
      <div className="kamp-detalj">
        <button className="tilbake-knapp" onClick={() => setValgt(null)}>← Tilbake</button>
        <div className="detalj-kort">
          {k.clubs?.icon_url && <img src={k.clubs.icon_url} alt="klubb" className="detalj-klubb-ikon" />}
          <p className="detalj-klubb-navn">{k.clubs?.name}</p>
          <div className="detalj-lag">
            <span>{k.home_team}</span>
            <span className="vs">vs</span>
            <span>{k.away_team}</span>
          </div>
          <div className="detalj-info-rad">
            <div className="detalj-info-boks">
              <span className="detalj-info-label">Dato</span>
              <span className="detalj-info-verdi">{formatDato(k.match_date)}</span>
            </div>
            <div className="detalj-info-boks">
              <span className="detalj-info-label">Tid</span>
              <span className="detalj-info-verdi">{formatTid(k.match_date)}</span>
            </div>
            <div className="detalj-info-boks">
              <span className="detalj-info-label">Aldersgruppe</span>
              <span className="detalj-info-verdi">{k.age_group}</span>
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="tab-innhold">
      <h2 className="tab-tittel">Kamper</h2>
      {kamper.length === 0 ? (
        <p className="ingen-kamper">Ingen kamper tilgjengelig.</p>
      ) : (
        <div className="kamp-liste">
          {kamper.map(kamp => (
            <div className="kamp-kort kamp-kort-klikkbar" key={kamp.id} onClick={() => setValgt({ kamp })}>
              <div className="kamp-klubb-rad">
                {kamp.clubs?.icon_url && <img src={kamp.clubs.icon_url} alt="" className="kamp-klubb-mini-ikon" />}
                <span className="kamp-klubb-navn">{kamp.clubs?.name}</span>
              </div>
              <div className="kamp-lag">
                <span>{kamp.home_team}</span>
                <span className="vs">vs</span>
                <span>{kamp.away_team}</span>
              </div>
              <div className="kamp-info">
                <span className="aldersgruppe-badge">{kamp.age_group}</span>
                <span className="kamp-dato">{formatDato(kamp.match_date)} kl. {formatTid(kamp.match_date)}</span>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
