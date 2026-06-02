import React, { useState } from 'react';
import { supabase } from '../supabase';

interface Props {
  userId: string;
  onKlubbOpprettet: () => void;
}

export default function OpprettKlubb({ userId, onKlubbOpprettet }: Props) {
  const [navn, setNavn] = useState('');
  const [ikon, setIkon] = useState<File | null>(null);
  const [ikonPreview, setIkonPreview] = useState<string | null>(null);
  const [sender, setSender] = useState(false);
  const [feil, setFeil] = useState('');

  const velgBilde = (e: React.ChangeEvent<HTMLInputElement>) => {
    const fil = e.target.files?.[0];
    if (!fil) return;
    setIkon(fil);
    setIkonPreview(URL.createObjectURL(fil));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setFeil('');
    setSender(true);

    let icon_url = null;

    if (ikon) {
      const filnavn = `${userId}-${Date.now()}.${ikon.name.split('.').pop()}`;
      const { error: opplastingsFeil } = await supabase.storage
        .from('club-icons')
        .upload(filnavn, ikon, { upsert: true });

      if (opplastingsFeil) {
        setFeil('Kunne ikke laste opp bildet: ' + opplastingsFeil.message);
        setSender(false);
        return;
      }

      const { data } = supabase.storage.from('club-icons').getPublicUrl(filnavn);
      icon_url = data.publicUrl;
    }

    const { error } = await supabase.from('clubs').insert({
      user_id: userId,
      name: navn,
      icon_url,
    });

    if (error) {
      setFeil('Noe gikk galt: ' + error.message);
    } else {
      onKlubbOpprettet();
    }

    setSender(false);
  };

  return (
    <div className="login-page">
      <div className="login-container">
        <div className="login-logo">
          <h1>DommerJob</h1>
          <p>Opprett din klubb</p>
        </div>
        <div className="login-form">
          <h2>Ny klubb</h2>
          <form onSubmit={handleSubmit}>
            <div className="ikon-velger">
              <label htmlFor="ikon-input" className="ikon-label">
                {ikonPreview ? (
                  <img src={ikonPreview} alt="Klubbikon" className="ikon-preview" />
                ) : (
                  <div className="ikon-placeholder">
                    <span>Velg klubbikon</span>
                    <small>Trykk for å velge bilde</small>
                  </div>
                )}
              </label>
              <input
                id="ikon-input"
                type="file"
                accept="image/*"
                onChange={velgBilde}
                style={{ display: 'none' }}
              />
            </div>

            <div className="form-group">
              <label htmlFor="klubbnavn">Klubbnavn</label>
              <input
                id="klubbnavn"
                type="text"
                placeholder="F.eks. Brann FK"
                value={navn}
                onChange={e => setNavn(e.target.value)}
                required
              />
            </div>

            {feil && <p className="feil-melding">{feil}</p>}

            <button type="submit" className="login-btn" disabled={sender}>
              {sender ? 'Oppretter...' : 'Opprett klubb'}
            </button>
          </form>
        </div>
      </div>
    </div>
  );
}
