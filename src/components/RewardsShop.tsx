import React, { useState } from 'react';
import { REWARDS, Reward, SHOP_NAME, rewardImage } from '../lib/rewards';
import { Claim, creditLabel } from '../lib/store';

type Props = {
  balance: number;
  claims: Claim[];
  onRedeem: (rewardId: string) => void;
};

export default function RewardsShop({ balance, claims, onRedeem }: Props) {
  return (
    <section className="card">
      <header className="card-head">
        <h2>{SHOP_NAME}</h2>
        <span className="pill">{balance.toLocaleString()} credits</span>
      </header>
      <p className="card-sub">
        Spend your credits. Every redemption gives you a claim code.
      </p>

      <div className="reward-grid">
        {REWARDS.map(r => (
          <RewardCard
            key={r.id}
            reward={r}
            affordable={balance >= r.cost}
            onRedeem={() => onRedeem(r.id)}
          />
        ))}
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

function RewardCard({
  reward,
  affordable,
  onRedeem,
}: {
  reward: Reward;
  affordable: boolean;
  onRedeem: () => void;
}) {
  // Artwork is optional — until public/rewards/<id>.png exists we show the
  // emoji stand-in rather than a broken image.
  const [artMissing, setArtMissing] = useState(false);

  return (
    <div className={`reward tier-${reward.tier}`}>
      <div className="reward-art">
        {artMissing ? (
          <span className="reward-fallback">{reward.fallback}</span>
        ) : (
          <img
            src={rewardImage(reward.id)}
            alt={reward.name}
            loading="lazy"
            onError={() => setArtMissing(true)}
          />
        )}
      </div>
      <h3>{reward.name}</h3>
      <button
        className={affordable ? 'primary-btn small' : 'ghost-btn small'}
        disabled={!affordable}
        onClick={onRedeem}
      >
        {creditLabel(reward.cost)}
      </button>
    </div>
  );
}
