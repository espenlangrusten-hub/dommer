import React from 'react';

type Props = {
  username: string;
  referrals: number;
};

/**
 * Sample board — the rivals are fixed so the player can see where they'd land.
 * A real board needs the server-side ledger described in the README.
 */
const RIVALS = [
  { name: 'PixelPumpkin', referrals: 41 },
  { name: 'sprout_kai', referrals: 33 },
  { name: 'MegaMelonXD', referrals: 27 },
  { name: 'lunavines', referrals: 18 },
  { name: 'Tomato_Tycoon', referrals: 12 },
  { name: 'bloomboy77', referrals: 7 },
  { name: 'quietcarrot', referrals: 3 },
];

export default function Leaderboard({ username, referrals }: Props) {
  const rows = RIVALS.concat({ name: username, referrals })
    .sort((a, b) => b.referrals - a.referrals)
    .slice(0, 8);

  return (
    <section className="card">
      <header className="card-head">
        <h2>Top inviters</h2>
        <span className="pill muted">This season</span>
      </header>
      <ol className="board">
        {rows.map((r, i) => (
          <li key={r.name + i} className={r.name === username ? 'me' : ''}>
            <span className="rank">{i + 1}</span>
            <span className="board-name">{r.name}</span>
            <span className="board-score">{r.referrals} invites</span>
          </li>
        ))}
      </ol>
    </section>
  );
}
