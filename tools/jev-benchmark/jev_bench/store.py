"""Schéma SQLite du benchmark. Append-only : un run, une répétition = de nouvelles lignes."""
from __future__ import annotations

import json
import sqlite3
from datetime import datetime, timezone

from . import config

SCHEMA = """
CREATE TABLE IF NOT EXISTS sample (
    sample_id              TEXT PRIMARY KEY,
    source                 TEXT NOT NULL,
    titre                  TEXT,
    task_type              TEXT NOT NULL,
    task_type_source       TEXT,
    task_type_justification TEXT,
    consigne               TEXT NOT NULL,
    contexte               TEXT,
    production             TEXT NOT NULL,
    word_count             INTEGER NOT NULL,
    official_min           INTEGER,
    official_max           INTEGER,
    below_official_min     INTEGER,
    above_official_max     INTEGER,
    official_length_compliant INTEGER,
    niveau_vise            TEXT,
    niveau_vise_code       TEXT,
    niveau_vise_alternatif TEXT,
    niveau_vise_source     TEXT,
    playground_json        TEXT,
    fixture_json           TEXT NOT NULL,
    imported_at            TEXT NOT NULL,
    -- ACTIVE ou RETIRED : un cas retiré reste en base pour trace, exclu des sélections et des stats.
    status                 TEXT NOT NULL DEFAULT 'ACTIVE',
    replaced_by            TEXT,
    retired_reason         TEXT,
    -- SYNTHETIC ou REAL : les statistiques des deux origines ne se mélangent JAMAIS.
    origin                 TEXT NOT NULL DEFAULT 'SYNTHETIC',
    -- REAL : CECRL, A1_NON_ATTEINT, NON_EVALUABLE, PLAFOND (strates isolées hors CECRL).
    stratum                TEXT,
    repeat_subset          INTEGER NOT NULL DEFAULT 0,
    word_count_redacted    INTEGER,
    redactions_json        TEXT,
    attempt_type           TEXT,
    submitted_month        TEXT
);

-- Pseudo-candidat (md5(sel || user_id)) : contrôle LOCAL du plafond par candidat uniquement.
-- Jamais envoyé à JEV, jamais exporté.
CREATE TABLE IF NOT EXISTS real_candidate (
    sample_id     TEXT PRIMARY KEY REFERENCES sample(sample_id),
    candidate_key TEXT NOT NULL
);

-- Effectifs par cellule de l'extraction réelle (disponible / après plafond candidat / retenu).
CREATE TABLE IF NOT EXISTS real_extraction_count (
    extraction_id TEXT NOT NULL,
    tache_numero  INTEGER NOT NULL,
    strate        TEXT NOT NULL,
    niveau        TEXT NOT NULL,
    disponible    INTEGER, candidats_disponibles INTEGER,
    apres_plafond INTEGER, retenu INTEGER, candidats_retenus INTEGER,
    PRIMARY KEY (extraction_id, tache_numero, strate, niveau)
);

CREATE TABLE IF NOT EXISTS benchmark_run (
    run_id          TEXT PRIMARY KEY,
    created_at      TEXT NOT NULL,
    mode            TEXT NOT NULL CHECK (mode IN ('dry', 'real')),
    model_requested TEXT NOT NULL,
    prompt_version  TEXT NOT NULL,
    questions_hash  TEXT NOT NULL,
    repeat          INTEGER NOT NULL,
    filters_json    TEXT,
    n_samples       INTEGER,
    estimated_input_tokens INTEGER,
    estimated_cost_usd REAL,
    notes           TEXT
);

CREATE TABLE IF NOT EXISTS jev_result (
    id                 INTEGER PRIMARY KEY AUTOINCREMENT,
    sample_id          TEXT NOT NULL REFERENCES sample(sample_id),
    run_id             TEXT NOT NULL REFERENCES benchmark_run(run_id),
    repeat_index       INTEGER NOT NULL,
    created_at         TEXT NOT NULL,
    model_requested    TEXT,
    model_returned     TEXT,
    prompt_version     TEXT NOT NULL,
    questions_hash     TEXT NOT NULL,
    response_id        TEXT,
    http_status        INTEGER,
    attempts           INTEGER,
    latency_ms         INTEGER,
    niveau_global_choice TEXT, niveau_global_probs TEXT, niveau_global_confidence REAL,
    pertinence_choice    TEXT, pertinence_probs    TEXT, pertinence_confidence    REAL,
    communiquer_choice   TEXT, communiquer_probs   TEXT, communiquer_confidence   REAL,
    interagir_choice     TEXT, interagir_probs     TEXT, interagir_confidence     REAL,
    lexique_choice       TEXT, lexique_probs       TEXT, lexique_confidence       REAL,
    morphosyntaxe_choice TEXT, morphosyntaxe_probs TEXT, morphosyntaxe_confidence REAL,
    -- SECONDAIRE : niveau via formule SejourFR (conversion des 4 critères JEV), jamais le résultat principal.
    secondaire_formule_argmax_niveau TEXT, secondaire_formule_argmax_note REAL, secondaire_formule_argmax_json TEXT,
    secondaire_formule_esperance_niveau TEXT, secondaire_formule_esperance_note REAL,
    secondaire_formule_esperance_json TEXT,
    input_tokens       INTEGER,
    output_tokens      INTEGER,
    cost_usd           REAL,
    raw_response_json  TEXT,
    error              TEXT
);
CREATE INDEX IF NOT EXISTS idx_jev_result_key ON jev_result(sample_id, run_id, repeat_index);

CREATE TABLE IF NOT EXISTS sejourfr_result (
    id                   INTEGER PRIMARY KEY AUTOINCREMENT,
    sample_id            TEXT NOT NULL REFERENCES sample(sample_id),
    created_at           TEXT NOT NULL,
    status               TEXT NOT NULL,
    word_count           INTEGER,
    mots_min             INTEGER,
    mots_max             INTEGER,
    production_task_id   TEXT,
    attempt_id           TEXT,
    submission_id        TEXT,
    client_submission_id TEXT,
    niveau_cecrl         TEXT,
    niveau_cecrl_ia      TEXT,
    note_sur_20          REAL,
    note_communiquer     REAL,
    note_interagir       REAL,
    note_lexique         REAL,
    note_morphosyntaxe   REAL,
    scores_criteres_json TEXT,
    confiance            TEXT,
    plafond_niveau       TEXT,
    evaluabilite         TEXT,
    modele_utilise       TEXT,
    prompt_version       TEXT,
    rubrics_version      TEXT,
    versions_ok          INTEGER,
    error                TEXT
);
CREATE INDEX IF NOT EXISTS idx_sejourfr_result_sample ON sejourfr_result(sample_id);
"""

CRITERES = ("communiquer", "interagir", "lexique", "morphosyntaxe")
ORIGINS = ("SYNTHETIC", "REAL")


def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


# Renommages non destructifs (ALTER TABLE … RENAME COLUMN) des bases créées avant la séparation
# « résultat principal JEV » / « secondaire : niveau via formule SejourFR ».
_RENAMES = {"jev_result": {f"formule_{v}_{f}": f"secondaire_formule_{v}_{f}"
                           for v in ("argmax", "esperance") for f in ("niveau", "note", "json")}}


_ADDED_COLUMNS = {"sample": {"status": "TEXT NOT NULL DEFAULT 'ACTIVE'", "replaced_by": "TEXT",
                              "retired_reason": "TEXT", "origin": "TEXT NOT NULL DEFAULT 'SYNTHETIC'",
                              "stratum": "TEXT", "repeat_subset": "INTEGER NOT NULL DEFAULT 0",
                              "word_count_redacted": "INTEGER", "redactions_json": "TEXT",
                              "attempt_type": "TEXT", "submitted_month": "TEXT"}}


def _migrate(conn: sqlite3.Connection) -> None:
    for table, cols_to_add in _ADDED_COLUMNS.items():
        cols = {r[1] for r in conn.execute(f"PRAGMA table_info({table})")}
        for col, ddl in cols_to_add.items():
            if cols and col not in cols:
                conn.execute(f"ALTER TABLE {table} ADD COLUMN {col} {ddl}")
    for table, renames in _RENAMES.items():
        cols = {r[1] for r in conn.execute(f"PRAGMA table_info({table})")}
        for old, new in renames.items():
            if old in cols and new not in cols:
                conn.execute(f"ALTER TABLE {table} RENAME COLUMN {old} TO {new}")
    conn.commit()


def connect(readonly: bool = False) -> sqlite3.Connection:
    if readonly:
        if not config.DB_FILE.exists():
            raise FileNotFoundError(str(config.DB_FILE))
        conn = sqlite3.connect(f"file:{config.DB_FILE}?mode=ro", uri=True)
    else:
        config.DATA_DIR.mkdir(parents=True, exist_ok=True)
        conn = sqlite3.connect(config.DB_FILE)
        existed = conn.execute("SELECT 1 FROM sqlite_master WHERE name='jev_result'").fetchone()
        if existed:
            _migrate(conn)
        conn.executescript(SCHEMA)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    return conn


def dumps(obj) -> str | None:
    return None if obj is None else json.dumps(obj, ensure_ascii=False, sort_keys=True)


def samples(conn, task: str | None = None, niveau_vise: str | None = None,
            limit: int | None = None, ids: list[str] | None = None, include_retired: bool = False,
            origin: str = "SYNTHETIC", repeat_subset: bool = False) -> list[dict]:
    """Échantillons d'UNE origine (SYNTHETIC par défaut) : jamais les deux à la fois."""
    if origin not in ORIGINS:
        raise ValueError(f"origine inconnue : {origin}")
    sql = "SELECT * FROM sample WHERE origin = ?"
    args: list = [origin]
    if repeat_subset:
        sql += " AND repeat_subset = 1"
    if not include_retired:
        sql += " AND status = 'ACTIVE'"
    if task:
        sql += " AND task_type = ?"
        args.append(task)
    if niveau_vise:
        sql += " AND niveau_vise_code = ?"
        args.append(niveau_vise)
    if ids:
        sql += f" AND sample_id IN ({','.join('?' * len(ids))})"
        args.extend(ids)
    sql += " ORDER BY sample_id"
    if limit:
        sql += " LIMIT ?"
        args.append(limit)
    return [dict(r) for r in conn.execute(sql, args)]


def successful_jev(conn, sample_id: str, run_id: str, repeat_index: int) -> bool:
    row = conn.execute(
        "SELECT 1 FROM jev_result WHERE sample_id=? AND run_id=? AND repeat_index=? AND error IS NULL LIMIT 1",
        (sample_id, run_id, repeat_index)).fetchone()
    return row is not None
