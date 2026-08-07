import React, { useMemo, useState } from "react";
import { RobloxUser } from "../lib/roblox";
import { ClaimRow, allClaims, claimsToCsv, setFulfilled } from "../lib/store";

type Props = {
  user: RobloxUser;
  onBack: () => void;
};

/** Roblox user IDs allowed to open this page, comma-separated. */
const ADMIN_IDS = (process.env.REACT_APP_ADMIN_ROBLOX_IDS || "")
  .split(",")
  .map((s) => s.trim())
  .filter(Boolean);

export function isAdmin(user: RobloxUser): boolean {
  if (ADMIN_IDS.length === 0) return true; // nothing to check against yet
  return ADMIN_IDS.includes(user.id);
}

export default function AdminPage({ user, onBack }: Props) {
  const [rows, setRows] = useState<ClaimRow[]>(() => allClaims());
  const [filter, setFilter] = useState<"all" | "pending" | "sent">("pending");
  const [copied, setCopied] = useState(false);

  const shown = useMemo(
    () =>
      rows.filter((r) =>
        filter === "all" ? true : filter === "sent" ? r.sent : !r.sent,
      ),
    [rows, filter],
  );

  const pending = rows.filter((r) => !r.sent).length;

  const toggle = (row: ClaimRow) => {
    setFulfilled(row.code, !row.sent);
    setRows(allClaims());
  };

  const copyCsv = async () => {
    const csv = claimsToCsv(rows);
    try {
      await navigator.clipboard.writeText(csv);
    } catch {
      window.prompt("Copy the CSV:", csv);
    }
    setCopied(true);
    window.setTimeout(() => setCopied(false), 1800);
  };

  if (!isAdmin(user)) {
    return (
      <main className="layout">
        <section className="card">
          <h2>Not your page</h2>
          <p className="card-sub">This account isn't on the admin list.</p>
          <button className="ghost-btn" onClick={onBack}>
            Back to the site
          </button>
        </section>
      </main>
    );
  }

  return (
    <main className="layout">
      <section className="card hero-card">
        <header className="card-head">
          <h2>Claims to send</h2>
          <span className="pill">{pending} pending</span>
        </header>
        <p className="card-sub">
          Every redemption made in this browser. Tick one off once you've
          delivered the item in-game.
        </p>

        <div className="admin-bar">
          <div className="filters">
            {(["pending", "sent", "all"] as const).map((f) => (
              <button
                key={f}
                className={`chip ${filter === f ? "chip-on" : ""}`}
                onClick={() => setFilter(f)}
              >
                {f}
              </button>
            ))}
          </div>
          <div className="admin-actions">
            <button
              className="ghost-btn small"
              onClick={() => setRows(allClaims())}
            >
              Refresh
            </button>
            <button className="ghost-btn small" onClick={copyCsv}>
              {copied ? "Copied" : "Copy CSV"}
            </button>
            <button className="ghost-btn small" onClick={onBack}>
              Back
            </button>
          </div>
        </div>

        {shown.length === 0 ? (
          <p className="empty">Nothing here.</p>
        ) : (
          <div className="table-scroll">
            <table className="claims-table">
              <thead>
                <tr>
                  <th>Date</th>
                  <th>Roblox user</th>
                  <th>Reward</th>
                  <th>Claim code</th>
                  <th>Sent</th>
                </tr>
              </thead>
              <tbody>
                {shown.map((r) => (
                  <tr key={r.code} className={r.sent ? "row-sent" : ""}>
                    <td>{new Date(r.at).toLocaleString()}</td>
                    <td>
                      {r.username}
                      <span className="row-id">{r.userId}</span>
                    </td>
                    <td>{r.reward}</td>
                    <td>
                      <code>{r.code}</code>
                    </td>
                    <td>
                      <input
                        type="checkbox"
                        checked={r.sent}
                        onChange={() => toggle(r)}
                        aria-label={`Mark ${r.code} as sent`}
                      />
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        <p className="fineprint admin-warning">
          This list is read from this browser's storage, so it only shows claims
          made on this device. Until the backend exists, use a claim webhook to
          receive everyone else's redemptions.
        </p>
      </section>
    </main>
  );
}
