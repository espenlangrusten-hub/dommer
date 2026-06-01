import React, { useState } from 'react';
import './App.css';

type Role = 'dommer' | 'klubb';

function App() {
  const [rolle, setRolle] = useState<Role>('dommer');
  const [epost, setEpost] = useState('');
  const [passord, setPassord] = useState('');

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    alert(`Logger inn som ${rolle === 'dommer' ? 'dommer' : 'klubb'}: ${epost}`);
  };

  return (
    <div className="login-page">
      <div className="login-container">
        <div className="login-logo">
          <h1>DommerJob</h1>
          <p>Kobler dommere og klubber</p>
        </div>

        <div className="role-selector">
          <div
            className={`role-card ${rolle === 'dommer' ? 'active' : ''}`}
            onClick={() => setRolle('dommer')}
          >
            <span className="role-label">Dommer</span>
          </div>
          <div
            className={`role-card ${rolle === 'klubb' ? 'active' : ''}`}
            onClick={() => setRolle('klubb')}
          >
            <span className="role-label">Klubb</span>
          </div>
        </div>

        <div className="login-form">
          <h2>
            {rolle === 'dommer' ? 'Logg inn som dommer' : 'Logg inn som klubb'}
          </h2>
          <form onSubmit={handleSubmit}>
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
            <button type="submit" className="login-btn">
              Logg inn
            </button>
          </form>

          <div className="divider">eller</div>

          <div className="form-footer">
            <a href="#glemtpassord">Glemt passord?</a>
            &nbsp;&nbsp;·&nbsp;&nbsp;
            Ny bruker? <a href="#registrer">Registrer deg</a>
          </div>
        </div>
      </div>
    </div>
  );
}

export default App;
