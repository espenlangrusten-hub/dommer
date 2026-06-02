import React, { useEffect, useRef, useState } from 'react';
import { supabase } from '../supabase';

interface Klubb { id: string; name: string; }

interface Props { refereeId: string; klubbId: string | null; }

const kampTyper = [
  { label: '5er fotball', verdi: '5', betaling: 150 },
  { label: '7er fotball', verdi: '7', betaling: 200 },
  { label: '9er fotball', verdi: '9', betaling: 250 },
  { label: '11er fotball', verdi: '11', betaling: 300 },
];

const aldersgrupper = [
  'G6','G7','G8','G9','G10','G11','G12','G13','G14','G15','G16','G17','G18','G19',
  'J6','J7','J8','J9','J10','J11','J12','J13','J14','J15','J16','J17','J18','J19',
  'Senior menn','Senior kvinner','Veteran',
];

export default function RegistrerKampTab({ refereeId, klubbId }: Props) {
  const [klubber, setKlubber] = useState<Klubb[]>([]);
  const [valgtKlubbId, setValgtKlubbId] = useState(klubbId ?? '');
  const [hjemmelag, setHjemmelag] = useState('');
  const [bortelag, setBortelag] = useState('');
  const [aldersgruppe, setAldersgruppe] = useState('');
  const [kampType, setKampType] = useState('');
  const [tegner, setTegner] = useState(false);
  const [harSignatur, setHarSignatur] = useState(false);
  const [sender, setSender] = useState(false);
  const [suksess, setSuksess] = useState(false);
  const [feil, setFeil] = useState('');
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const tegnerRef = useRef(false);
  const lastPosRef = useRef({ x: 0, y: 0 });

  useEffect(() => {
    supabase.from('clubs').select('id, name').then(({ data }) => setKlubber(data ?? []));
  }, []);

  const startTegning = (e: React.PointerEvent) => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    tegnerRef.current = true;
    canvas.setPointerCapture(e.pointerId);
    const rect = canvas.getBoundingClientRect();
    lastPosRef.current = { x: e.clientX - rect.left, y: e.clientY - rect.top };
  };

  const tegnLinje = (e: React.PointerEvent) => {
    if (!tegnerRef.current) return;
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;
    const rect = canvas.getBoundingClientRect();
    const x = e.clientX - rect.left;
    const y = e.clientY - rect.top;
    ctx.beginPath();
    ctx.moveTo(lastPosRef.current.x, lastPosRef.current.y);
    ctx.lineTo(x, y);
    ctx.strokeStyle = '#1d4ed8';
    ctx.lineWidth = 2.5;
    ctx.lineCap = 'round';
    ctx.stroke();
    lastPosRef.current = { x, y };
    setHarSignatur(true);
  };

  const stoppTegning = () => { tegnerRef.current = false; };

  const slettSignatur = () => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    canvas.getContext('2d')?.clearRect(0, 0, canvas.width, canvas.height);
    setHarSignatur(false);
  };

  const valgtType = kampTyper.find(k => k.verdi === kampType);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!harSignatur) { setFeil('Treneren må signere.'); return; }
    setFeil('');
    setSender(true);

    const canvas = canvasRef.current;
    const signatur = canvas?.toDataURL('image/png') ?? '';

    const { error } = await supabase.from('referee_registrations').insert({
      referee_id: refereeId,
      club_id: valgtKlubbId,
      home_team: hjemmelag,
      away_team: bortelag,
      age_group: aldersgruppe,
      match_type: kampType,
      coach_signature: signatur,
      amount: valgtType?.betaling ?? 0,
      status: 'venter',
    });

    if (error) {
      setFeil('Noe gikk galt: ' + error.message);
    } else {
      setSuksess(true);
      setHjemmelag(''); setBortelag(''); setAldersgruppe('');
      setKampType(''); setKlubbId(''); setHarSignatur(false);
      slettSignatur();
      setTimeout(() => setSuksess(false), 4000);
    }
    setSender(false);
  };

  return (
    <div className="tab-innhold">
      <h2 className="tab-tittel">Registrer kamp</h2>
      <form onSubmit={handleSubmit}>
        {!klubbId && (
          <div className="form-group">
            <label>Klubb</label>
            <select className="form-select" value={valgtKlubbId} onChange={e => setValgtKlubbId(e.target.value)} required>
              <option value="">Velg klubb</option>
              {klubber.map(k => <option key={k.id} value={k.id}>{k.name}</option>)}
            </select>
          </div>
        )}

        <div className="form-group">
          <label>Hjemmelag</label>
          <input type="text" placeholder="F.eks. Brann FK" value={hjemmelag} onChange={e => setHjemmelag(e.target.value)} required />
        </div>
        <div className="form-group">
          <label>Bortelag</label>
          <input type="text" placeholder="F.eks. Viking FK" value={bortelag} onChange={e => setBortelag(e.target.value)} required />
        </div>

        <div className="form-group">
          <label>Aldersgruppe</label>
          <select className="form-select" value={aldersgruppe} onChange={e => setAldersgruppe(e.target.value)} required>
            <option value="">Velg aldersgruppe</option>
            {aldersgrupper.map(a => <option key={a} value={a}>{a}</option>)}
          </select>
        </div>

        <div className="form-group">
          <label>Kamptype</label>
          <div className="kamptype-grid">
            {kampTyper.map(kt => (
              <div
                key={kt.verdi}
                className={`kamptype-kort ${kampType === kt.verdi ? 'active' : ''}`}
                onClick={() => setKampType(kt.verdi)}
              >
                <span className="kamptype-label">{kt.label}</span>
                <span className="kamptype-betaling">{kt.betaling} kr</span>
              </div>
            ))}
          </div>
        </div>

        <div className="form-group">
          <div className="signatur-header">
            <label>Treners signatur</label>
            {harSignatur && <button type="button" className="slett-signatur" onClick={slettSignatur}>Slett</button>}
          </div>
          <div className="signatur-wrapper">
            <canvas
              ref={canvasRef}
              width={340}
              height={120}
              className="signatur-canvas"
              onPointerDown={startTegning}
              onPointerMove={tegnLinje}
              onPointerUp={stoppTegning}
              onPointerLeave={stoppTegning}
            />
            {!harSignatur && <span className="signatur-hint">Trener signerer her</span>}
          </div>
        </div>

        {valgtType && (
          <div className="betaling-rad">
            <span>Din betaling for denne kampen:</span>
            <span className="betaling-beloep">{valgtType.betaling} kr</span>
          </div>
        )}

        {feil && <p className="feil-melding">{feil}</p>}
        {suksess && <p className="suksess-melding">Registrering sendt til klubben!</p>}

        <button type="submit" className="login-btn" disabled={sender || !kampType}>
          {sender ? 'Sender...' : 'Send til klubb'}
        </button>
      </form>
    </div>
  );
}
