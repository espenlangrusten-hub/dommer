import React from 'react';
import { REWARDS } from '../lib/rewards';
import { Claim } from '../lib/store';

type Props = {
  balance: number;
  claims: Claim[];
  onRedeem: (rewardId: string) => void;
};

export default function RewardsShop({ balance, claims, onRedeem }: Props) {
  return (
    <section className="card">
      <header className="card-head">
        <h2>Rewards</h2>
        <span className="pill">{balance.toLocaleString()} 🌱 available</span>
      </header>

      <div className="reward-grid">
        {REWARDS.map(r => {
          const affordable = balance >= r.cost;
          return (
            <div key={r.id} className={`reward tier-${r.tier}`}>
              <span className="reward-icon">{r.icon}</span>
              <div className="reward-body">
                <h3>{r.name}</h3>
                <p>{r.blurb}</p>
              </div>
              <button
                className={affordable ? 'primary-btn small' : 'ghost-btn small'}
                disabled={!affordable}
                onClick={() => onRedeem(r.id)}
              >
                {affordable ? `Redeem ${r.cost} 🌱` : `${r.cost} 🌱`}
              </button>
            </div>
          );
        })}
      </div>

      {claims.length > 0 && (
        <div className="claims">
          <h3>Your claim codes</h3>
          <p className="card-sub">Enter these in-game at the Seed Circle stand.</p>
          <ul>
            {claims.map(c => (
              <li key={c.id}>
                <span className="claim-reward">{c.reward}</span>
                <code>{c.code}</code>
                <span className="claim-date">
                  {new Date(c.at).toLocaleDateString()}
                </span>
              </li>
            ))}
          </ul>
        </div>
      )}
    </section>
  );
}
