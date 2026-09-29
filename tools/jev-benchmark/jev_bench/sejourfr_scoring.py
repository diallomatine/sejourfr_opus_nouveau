"""Notation des fixtures par le correcteur SejourFR ACTUEL, via le backend LOCAL de dev.

Parcours identique à celui des fronts pour un entraînement EE :
``POST /api/auth/login`` → ``POST /api/attempts/production`` (TCF / TCF_EE,
entraînement libre) → ``POST /api/production-submissions`` (JSON, avec
``clientSubmissionId``) → poll ``GET /api/production-submissions/{id}`` jusqu'à
EVALUATED / FAILED. Le résultat est ensuite relu en SQL local (session
read-only) dans ``ai_evaluations``.

Écritures dans la base LOCALE (et nulle part ailleurs) :
- une ``production_tasks`` par (tâche, consigne, contexte) des fixtures,
  titre préfixé « [JEV-BENCH] », id déterministe (UUIDv5), activée le temps du
  scoring puis désactivée ;
- ce que le backend écrit lui-même en traitant une soumission (attempt,
  submission, évaluation, observations du Plan…).
Nettoyage : ``jev_bench/sql/cleanup_local_sejourfr_db.sql``.

Idempotence : ``clientSubmissionId`` = UUIDv5(fixture, texte) ; un relancement
rend la MÊME soumission sans second appel LLM ; une fixture déjà EVALUATED
dans SQLite n'est pas resoumise.
"""
from __future__ import annotations

import hashlib
import json
import subprocess
import time
import uuid
from urllib.parse import urlparse

import httpx

from . import config, store
from .length import OFFICIAL_BOUNDS, TASK_NUMBER, count_words

NS = uuid.UUID("6f1d3c52-2b8e-5f0a-9f63-4a1b5e7c0d21")
TITRE_PREFIX = "[JEV-BENCH]"
TERMINAL = {"EVALUATED", "FAILED"}


class Blocked(Exception):
    pass


def _check_local(base_url: str) -> None:
    host = urlparse(base_url).hostname
    if host not in config.ALLOWED_BACKEND_HOSTS:
        raise SystemExit(f"Refus : backend non local ({host}). Seuls {sorted(config.ALLOWED_BACKEND_HOSTS)} sont admis.")


def _psql(sql: str, variables: dict | None = None, readonly: bool = True) -> str:
    args = ["psql", "-X", "-q", "-At", "-v", "ON_ERROR_STOP=1",
            "-d", config.LOCAL_DB_NAME, "-U", config.LOCAL_DB_USER]
    for k, v in (variables or {}).items():
        args += ["-v", f"{k}={v}"]
    prefix = "SET default_transaction_read_only = on;\n" if readonly else ""
    res = subprocess.run(args, input=prefix + sql, capture_output=True, text=True, timeout=60)
    if res.returncode != 0:
        raise RuntimeError(f"psql : {res.stderr.strip()[:500]}")
    return res.stdout


def task_id_for(task_type: str, consigne: str, contexte: str | None) -> uuid.UUID:
    return uuid.uuid5(NS, f"jev-bench|task|{task_type}|{consigne}|{contexte or ''}")


def client_submission_id(sample: dict) -> uuid.UUID:
    digest = hashlib.sha256(sample["production"].encode("utf-8")).hexdigest()
    return uuid.uuid5(NS, f"jev-bench|submission|{sample['sample_id']}|{digest}")


def _niveau_cible_indicatif(task_type: str) -> str:
    rub = json.loads(config.RUBRICS_V15_FILE.read_text(encoding="utf-8"))
    return rub["rubrics"][f"EE_T{TASK_NUMBER[task_type]}"]["niveau_cible_indicatif"]


def ensure_task(task_type: str, consigne: str, contexte: str | None) -> uuid.UUID:
    """Insère (ou réactive) la tâche [JEV-BENCH] portant la consigne de la fixture."""
    tid = task_id_for(task_type, consigne, contexte)
    lo, hi = OFFICIAL_BOUNDS[task_type]
    titre = f"{TITRE_PREFIX} {task_type} {tid.hex[:8]}"
    sql = (
        "INSERT INTO production_tasks (id, epreuve, tache_numero, niveau_cible, consigne, contexte, "
        "mots_min, mots_max, is_active, titre) VALUES (:'tid'::uuid, 'TCF_EE', :tache, :'niveau', :'consigne', "
        "NULLIF(:'contexte', ''), :mmin, :mmax, true, :'titre') "
        "ON CONFLICT (id) DO UPDATE SET is_active = true;\n"
        "SELECT consigne = :'consigne' AND coalesce(contexte,'') = :'contexte' FROM production_tasks "
        "WHERE id = :'tid'::uuid;\n"
    )
    out = _psql(sql, {"tid": str(tid), "tache": TASK_NUMBER[task_type], "niveau": _niveau_cible_indicatif(task_type),
                      "consigne": consigne, "contexte": contexte or "", "mmin": lo, "mmax": hi, "titre": titre},
                readonly=False)
    if out.strip().splitlines()[-1] != "t":
        raise Blocked(f"tâche {tid} présente mais contenu différent")
    return tid


def deactivate_tasks() -> None:
    _psql(f"UPDATE production_tasks SET is_active = false WHERE titre LIKE '{TITRE_PREFIX}%';", readonly=False)


def read_evaluation(submission_id: str) -> dict | None:
    sql = (
        "SELECT row_to_json(t) FROM (SELECT niveau_cecrl, niveau_cecrl_ia, note_sur_20, "
        "feedback_json->'scores_criteres' AS scores_criteres, feedback_json->>'confiance' AS confiance, "
        "feedback_json->>'plafond_niveau' AS plafond_niveau, evaluabilite, modele_utilise, prompt_version, "
        "rubrics_version FROM ai_evaluations WHERE submission_id = :'sid'::uuid "
        "ORDER BY evaluated_at DESC LIMIT 1) t;"
    )
    out = _psql(sql, {"sid": submission_id}).strip()
    return json.loads(out) if out else None


class Backend:
    def __init__(self, base_url: str):
        _check_local(base_url)
        self.base = base_url.rstrip("/")
        self.http = httpx.Client(timeout=httpx.Timeout(60.0, connect=10.0))
        self.token = None

    def health(self) -> bool:
        try:
            r = self.http.get(f"{self.base}/actuator/health")
            return r.status_code == 200
        except httpx.HTTPError:
            return False

    def login(self, email: str, password: str) -> None:
        r = self.http.post(f"{self.base}/api/auth/login", json={"email": email, "password": password})
        if r.status_code != 200:
            raise Blocked(f"login {email} : HTTP {r.status_code}")
        self.token = r.json()["accessToken"]

    def _h(self) -> dict:
        return {"Authorization": f"Bearer {self.token}"}

    def start_training_attempt(self) -> str:
        r = self.http.post(f"{self.base}/api/attempts/production", headers=self._h(),
                           json={"module": "TCF", "epreuve": "TCF_EE"})
        if r.status_code != 200:
            raise Blocked(f"création attempt : HTTP {r.status_code} {r.text[:300]}")
        return r.json()["id"]

    def submit(self, task_id: str, attempt_id: str, texte: str, key: str) -> httpx.Response:
        return self.http.post(f"{self.base}/api/production-submissions", headers=self._h(),
                              json={"productionTaskId": task_id, "attemptId": attempt_id,
                                    "texte": texte, "clientSubmissionId": key})

    def poll(self, submission_id: str, timeout_s: float, every_s: float = 3.0) -> dict:
        deadline = time.monotonic() + timeout_s
        last = {}
        while time.monotonic() < deadline:
            r = self.http.get(f"{self.base}/api/production-submissions/{submission_id}", headers=self._h())
            if r.status_code == 401:
                raise Blocked("jeton expiré pendant le poll")
            if r.status_code == 200:
                last = r.json()
                if last.get("statut") in TERMINAL:
                    return last
            time.sleep(every_s)
        last["_timeout"] = True
        return last


def _insert(conn, row: dict) -> None:
    row = {"created_at": store.now_iso(), **row}
    conn.execute(f"INSERT INTO sejourfr_result({','.join(row)}) VALUES ({','.join('?' * len(row))})",
                 list(row.values()))
    conn.commit()


def _latest(conn, sample_id: str):
    return conn.execute("SELECT * FROM sejourfr_result WHERE sample_id=? ORDER BY id DESC LIMIT 1",
                        (sample_id,)).fetchone()


def score_all(conn, samples: list[dict], base_url: str, poll_timeout_s: float = 300.0) -> list[dict]:
    backend = Backend(base_url)
    if not backend.health():
        raise SystemExit(f"backend local injoignable sur {base_url} (lancer : ./mvnw spring-boot:run "
                         "-Dspring-boot.run.profiles=dev)")
    backend.login(config.SEED_USER_EMAIL, config.SEED_USER_PASSWORD)
    report = []
    attempt_id = None
    try:
        for s in samples:
            sid = s["sample_id"]
            prev = _latest(conn, sid)
            if prev is not None and prev["status"] == "EVALUATED":
                report.append({"sample_id": sid, "status": "EVALUATED (déjà en base)", "niveau": prev["niveau_cecrl"]})
                continue
            wc = count_words(s["production"])
            lo, hi = OFFICIAL_BOUNDS[s["task_type"]]
            key = str(client_submission_id(s))
            if not lo <= wc <= hi:
                if prev is None or prev["status"] != "HORS_BORNES_NON_NOTABLE":
                    _insert(conn, {"sample_id": sid, "status": "HORS_BORNES_NON_NOTABLE", "word_count": wc,
                                   "mots_min": lo, "mots_max": hi, "client_submission_id": key,
                                   "error": f"{wc} mots hors bornes {lo}-{hi} : refus 422 attendu, non soumis"})
                report.append({"sample_id": sid, "status": "HORS_BORNES_NON_NOTABLE", "mots": wc})
                continue
            task_id = str(ensure_task(s["task_type"], s["consigne"], s.get("contexte")))
            if attempt_id is None:
                attempt_id = backend.start_training_attempt()
            base_row = {"sample_id": sid, "word_count": wc, "mots_min": lo, "mots_max": hi,
                        "production_task_id": task_id, "attempt_id": attempt_id, "client_submission_id": key}
            r = backend.submit(task_id, attempt_id, s["production"], key)
            for _ in range(12):  # rate-limit production (20 / 10 min) : on attend, même clé ⇒ pas de double appel
                if r.status_code != 429:
                    break
                wait = min(float(r.headers.get("Retry-After") or 60), 120.0)
                print(f"  {sid} : 429 rate-limit, attente {wait:.0f}s")
                time.sleep(wait)
                r = backend.submit(task_id, attempt_id, s["production"], key)
            if r.status_code == 422:
                _insert(conn, {**base_row, "status": "HORS_BORNES_NON_NOTABLE", "error": f"422 serveur : {r.text[:300]}"})
                report.append({"sample_id": sid, "status": "HORS_BORNES_NON_NOTABLE (422 serveur)", "mots": wc})
                continue
            if r.status_code != 200:
                _insert(conn, {**base_row, "status": "ERROR", "error": f"HTTP {r.status_code} : {r.text[:500]}"})
                report.append({"sample_id": sid, "status": f"ERROR HTTP {r.status_code}"})
                continue
            sub = r.json()
            sub_id = sub["id"]
            if sub.get("attemptId") and sub["attemptId"] != attempt_id:
                base_row["attempt_id"] = sub["attemptId"]  # rejeu idempotent d'une soumission antérieure
            final = backend.poll(sub_id, poll_timeout_s)
            statut = final.get("statut")
            if final.get("_timeout"):
                _insert(conn, {**base_row, "submission_id": sub_id, "status": "TIMEOUT",
                               "error": f"statut {statut} après {poll_timeout_s}s"})
                report.append({"sample_id": sid, "status": "TIMEOUT"})
                continue
            ev = read_evaluation(sub_id) if statut == "EVALUATED" else None
            row = {**base_row, "submission_id": sub_id, "status": statut,
                   "error": final.get("erreurMessage") if statut == "FAILED" else None}
            if ev:
                scores = ev.get("scores_criteres") or []
                by_code = {x.get("code"): x.get("note_sur_20") for x in scores if isinstance(x, dict)}
                ok = ev.get("rubrics_version") == config.EXPECTED_RUBRICS_VERSION and \
                    ev.get("prompt_version") == config.EXPECTED_PROMPT_VERSION
                row.update({
                    "niveau_cecrl": ev.get("niveau_cecrl"), "niveau_cecrl_ia": ev.get("niveau_cecrl_ia"),
                    "note_sur_20": ev.get("note_sur_20"),
                    "note_communiquer": by_code.get("communiquer"), "note_interagir": by_code.get("interagir"),
                    "note_lexique": by_code.get("lexique"), "note_morphosyntaxe": by_code.get("morphosyntaxe"),
                    "scores_criteres_json": store.dumps(scores), "confiance": ev.get("confiance"),
                    "plafond_niveau": ev.get("plafond_niveau"), "evaluabilite": ev.get("evaluabilite"),
                    "modele_utilise": ev.get("modele_utilise"), "prompt_version": ev.get("prompt_version"),
                    "rubrics_version": ev.get("rubrics_version"), "versions_ok": int(ok),
                })
                if not ok:
                    row["error"] = (f"versions inattendues : rubrics={ev.get('rubrics_version')} "
                                    f"prompt={ev.get('prompt_version')} (attendu v15/v9)")
            _insert(conn, row)
            report.append({"sample_id": sid, "status": statut, "niveau": row.get("niveau_cecrl"),
                           "note": row.get("note_sur_20"), "mots": wc})
    finally:
        try:
            deactivate_tasks()
        except Exception as exc:  # noqa: BLE001 — on signale sans masquer l'erreur principale
            print(f"  (désactivation des tâches [JEV-BENCH] impossible : {exc})")
    return report
