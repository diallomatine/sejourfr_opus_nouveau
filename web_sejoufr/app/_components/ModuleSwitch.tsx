"use client";

import type { Module } from "@/lib/types";

export function ModuleSwitch({
  value,
  onChange,
}: {
  value: Module;
  onChange: (m: Module) => void;
}) {
  return (
    <div className="module-switch" role="tablist" aria-label="Choix du module">
      <button
        type="button"
        role="tab"
        aria-selected={value === "CIVIQUE"}
        className={`ms-opt ${value === "CIVIQUE" ? "is-active is-blue" : ""}`}
        onClick={() => onChange("CIVIQUE")}
      >
        <span className="ms-letter">C</span>
        <span className="ms-label">
          <span className="ms-title">Civique</span>
          <span className="ms-sub">CSP · CR · Naturalisation</span>
        </span>
      </button>
      <button
        type="button"
        role="tab"
        aria-selected={value === "TCF"}
        className={`ms-opt ${value === "TCF" ? "is-active is-red" : ""}`}
        onClick={() => onChange("TCF")}
      >
        <span className="ms-letter">T</span>
        <span className="ms-label">
          <span className="ms-title">TCF IRN</span>
          <span className="ms-sub">A2 · B1 · B2</span>
        </span>
      </button>

      <style>{`
        .module-switch {
          display: grid;
          grid-template-columns: 1fr 1fr;
          gap: 8px;
          padding: 6px;
          background: var(--color-paper-2);
          border-radius: 14px;
        }
        .ms-opt {
          display: flex; align-items: center; gap: 10px;
          padding: 10px 12px;
          background: transparent;
          border: 1px solid transparent;
          border-radius: 10px;
          cursor: pointer;
          text-align: left;
          transition: all 0.15s;
          font-family: var(--font-sans);
        }
        .ms-opt:hover { background: rgba(255,255,255,0.6); }
        .ms-opt.is-active {
          background: #fff;
          border-color: var(--color-line);
          box-shadow: 0 4px 14px -6px rgba(15, 24, 57, 0.18);
        }
        .ms-letter {
          width: 36px; height: 36px;
          border-radius: 9px;
          background: var(--color-line-2);
          color: var(--color-muted);
          display: flex; align-items: center; justify-content: center;
          font-family: var(--font-display);
          font-weight: 600; font-size: 18px;
          flex-shrink: 0;
        }
        .ms-opt.is-blue.is-active .ms-letter {
          background: var(--color-blue); color: #fff;
        }
        .ms-opt.is-red.is-active .ms-letter {
          background: var(--color-red); color: #fff;
        }
        .ms-label { display: flex; flex-direction: column; min-width: 0; }
        .ms-title {
          font-weight: 700; font-size: 14.5px;
          color: var(--color-ink);
          line-height: 1.2;
        }
        .ms-sub {
          font-family: var(--font-mono);
          font-size: 9.5px; letter-spacing: 0.12em;
          color: var(--color-muted);
          margin-top: 3px;
          text-transform: uppercase;
        }
      `}</style>
    </div>
  );
}
