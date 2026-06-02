import React, { useState } from 'react';
import { supabase } from '../supabase';

interface Props {
  clubId: string;
  onLukk: () => void;
  onKampPostet: () => void;
}

const aldersgrupper = [
  'G6', 'G7', 'G8', 'G9', 'G10', 'G11', 'G12', 'G13', 'G14', 'G15', 'G16', 'G17', 'G18', 'G19',
  'J6', 'J7', 'J8', 'J9', 'J10', 'J11', 'J12', 'J13', 'J14', 'J15', 'J16', 'J17', 'J18', 'J19',
  'Senior menn', 'Senior kvinner', 'Veteran',
];

export default function OpprettKamp({ clubId, onLukk, onKampPostet }: Props) {
  const [hjemmelag, setHjemmelag] = useState('');
  const [bortelag, setBortelag] = useState('');
  const [dato, setDato] = useState('');
  const [tid, setTid] = useState('');
  const [aldersgruppe, setAldersgruppe] = useState('');
  const [sender, setSender] = useState(false);
  const [feil, setFeil] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setFeil('');
    setSender(true);

    const match_date = new Date(`${dato}T${tid}`).toISOString();

    const { error } = await supabase.from('matches').insert({
      club_id: clubId,
      home_team: hjemmelag,
      away_team: bortelag,
      match_date,
      age_group: aldersgruppe,
    });

    if (error) {
      setFeil('Noe gikk galt: ' + error.message);
      setSender(false);
    } else {
      onKampPostet();
    }
  };

  return (
    <div className="modal-overlay" onClick={onLukk}>
      <div className="modal" onClick={e => e.stopPropagation()}>
        <div className="modal-header">
          <h2>Ny kamp</h2>
          <button className="lukk-btn" onClick={onLukk}>✕</button>
        </div>

        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label>Hjemmelag</label>
            <input
              type="text"
              placeholder="F.eks. Brann FK"
              value={hjemmelag}
              onChange={e => setHjemmelag(e.target.value)}
              required
            />
          </div>
          <div className="form-group">
            <label>Bortelag</label>
            <input
              type="text"
              placeholder="F.eks. Viking FK"
              value={bortelag}
              onChange={e => setBortelag(e.target.value)}
              required
            />
          </div>
          <div className="form-rad">
            <div className="form-group">
              <label>Dato</label>
              <input
                type="date"
                value={dato}
                onChange={e => setDato(e.target.value)}
                required
              />
            </div>
            <div className="form-group">
              <label>Tid</label>
              <input
                type="time"
                value={tid}
                onChange={e => setTid(e.target.value)}
                required
              />
            </div>
          </div>
          <div className="form-group">
            <label>Aldersgruppe</label>
            <select
              value={aldersgruppe}
              onChange={e => setAldersgruppe(e.target.value)}
              required
              className="form-select"
            >
              <option value="">Velg aldersgruppe</option>
              {aldersgrupper.map(a => (
                <option key={a} value={a}>{a}</option>
              ))}
            </select>
          </div>

          {feil && <p className="feil-melding">{feil}</p>}

          <button type="submit" className="login-btn" disabled={sender}>
            {sender ? 'Poster...' : 'Post kamp'}
          </button>
        </form>
      </div>
    </div>
  );
}
