"""Exécution d'un run JEV : dry-run (aucun appel) ou réel."""
from __future__ import annotations

import json
import uuid

from . import config, formule, prompts, store
from .length import TASK_NUMBER

# Hypothèse d'estimation : ~4 caractères par token pour du français sérialisé en JSON.
CHARS_PER_TOKEN = 4


def estimate_tokens(text: str) -> int:
    return -(-len(text) // CHARS_PER_TOKEN)


def estimate_request(payload: dict) -> dict:
    """Estimation CONSERVATRICE : chaque question est facturée state + question, séparément."""
    state_tokens = estimate_tokens(prompts.canonical(payload["state"]))
    per_question = {k: estimate_tokens(prompts.canonical(q)) for k, q in payload["questions"].items()}
    total = sum(state_tokens + qt for qt in per_question.values())
    return {
        "state_tokens": state_tokens,
        "question_tokens": per_question,
        "longest_question_tokens": max(per_question.values()),
        "input_tokens_conservative": total,
        "within_context": state_tokens <= config.STATE_TOKEN_LIMIT,
    }


def cost_usd(input_tokens: int | None) -> float | None:
    if input_tokens is None:
        return None
    return input_tokens * config.PRICE_USD_PER_M_INPUT / 1_000_000


def _new_run(conn, mode: str, model: str, repeat: int, filters: dict, n: int,
             est_tokens: int, est_cost: float, version: str, run_id: str | None = None,
             notes: str | None = None) -> str:
    run_id = run_id or f"{mode}-{store.now_iso().replace(':', '').replace('+0000', 'Z')}-{uuid.uuid4().hex[:6]}"
    conn.execute(
        "INSERT INTO benchmark_run(run_id, created_at, mode, model_requested, prompt_version, questions_hash, "
        "repeat, filters_json, n_samples, estimated_input_tokens, estimated_cost_usd, notes) "
        "VALUES (?,?,?,?,?,?,?,?,?,?,?,?)",
        (run_id, store.now_iso(), mode, model, version, prompts.all_questions_hash(version), repeat,
         json.dumps(filters, ensure_ascii=False, sort_keys=True), n, est_tokens, est_cost, notes))
    conn.commit()
    return run_id


def calibration_ratio(conn, version: str) -> dict | None:
    """Tokens d'entrée RÉELS / estimés sur le dernier run réel complet de la même version."""
    run = conn.execute(
        "SELECT run_id, estimated_input_tokens FROM benchmark_run WHERE mode='real' AND prompt_version=? "
        "AND COALESCE(notes,'') NOT LIKE 'test%' AND estimated_input_tokens > 0 ORDER BY created_at DESC LIMIT 1",
        (version,)).fetchone()
    if not run:
        return None
    real = conn.execute("SELECT SUM(input_tokens) FROM jev_result WHERE run_id=? AND error IS NULL",
                        (run["run_id"],)).fetchone()[0]
    if not real:
        return None
    return {"run_id": run["run_id"], "tokens_reels": real, "tokens_estimes": run["estimated_input_tokens"],
            "ratio": round(real / run["estimated_input_tokens"], 4)}


def dry_run(conn, samples: list[dict], model: str, repeat: int, filters: dict,
            version: str = config.PROMPT_VERSION) -> dict:
    per_sample = [(s, prompts.build_payload(s, model, version)) for s in samples]
    ests = [estimate_request(p) for _, p in per_sample]
    tokens_one_pass = sum(e["input_tokens_conservative"] for e in ests)
    total_tokens = tokens_one_pass * repeat
    total_cost = cost_usd(total_tokens)
    run_id = _new_run(conn, "dry", model, repeat, filters, len(samples), total_tokens, total_cost, version)
    out_dir = config.DRY_RUN_DIR / run_id
    out_dir.mkdir(parents=True, exist_ok=True)
    for (s, payload), est in zip(per_sample, ests):
        (out_dir / f"{s['sample_id']}.json").write_text(
            json.dumps({"payload": payload, "estimation": est,
                        "questions_hash": prompts.questions_hash(payload["questions"])},
                       ensure_ascii=False, indent=2), encoding="utf-8")
    calib = calibration_ratio(conn, version)
    summary = {
        "run_id": run_id,
        "mode": "dry",
        "model": model,
        "prompt_version": version,
        "questions_hash_global": prompts.all_questions_hash(version),
        "questions_hash_par_tache": {t: prompts.questions_hash(prompts.build_questions(t, version))
                                     for t in prompts.TASK_TYPES},
        "n_samples": len(samples),
        "repeat": repeat,
        "http_requests": len(samples) * repeat,
        "questions_par_requete": len(prompts.QUESTION_KEYS),
        "hypothese_tokens": f"~{CHARS_PER_TOKEN} caractères / token (JSON canonique) ; chaque question facturée "
                            "state + question séparément (conservateur)",
        "tokens_entree_par_passage": tokens_one_pass,
        "tokens_entree_total": total_tokens,
        "prix_usd_par_million_entree": config.PRICE_USD_PER_M_INPUT,
        "cout_estime_usd": round(total_cost, 6),
        "ratio_reel_sur_estime": calib,
        "tokens_entree_cales_sur_reel": round(total_tokens * calib["ratio"]) if calib else None,
        "cout_cale_sur_reel_usd": round(cost_usd(total_tokens * calib["ratio"]), 6) if calib else None,
        "state_tokens_max": max(e["state_tokens"] for e in ests) if ests else 0,
        "question_tokens_max": max(e["longest_question_tokens"] for e in ests) if ests else 0,
        "tous_dans_le_contexte_32k": all(e["within_context"] for e in ests),
        "payloads_dir": str(out_dir),
    }
    (out_dir / "_summary.json").write_text(json.dumps(summary, ensure_ascii=False, indent=2), encoding="utf-8")
    return summary


def _answer(body: dict, key: str) -> dict:
    return ((body or {}).get("answers") or {}).get(key) or {}


def _row_from_response(sample: dict, run_id: str, repeat_index: int, model: str, qhash: str,
                       call, api_key: str | None, version: str = config.PROMPT_VERSION) -> dict:
    body = call.body or {}
    usage = body.get("usage") or {}
    in_tok = usage.get("input_tokens")
    row = {
        "sample_id": sample["sample_id"], "run_id": run_id, "repeat_index": repeat_index,
        "created_at": store.now_iso(), "model_requested": model, "model_returned": body.get("model"),
        "prompt_version": version, "questions_hash": qhash,
        "response_id": None if body.get("id") is None else str(body.get("id")),
        "http_status": call.status, "attempts": call.attempts, "latency_ms": call.latency_ms,
        "input_tokens": in_tok, "output_tokens": usage.get("output_tokens"), "cost_usd": cost_usd(in_tok),
        "raw_response_json": config.redact(json.dumps(body, ensure_ascii=False), api_key) if call.body else None,
        "error": call.error,
    }
    for key, col in (("niveau_global", "niveau_global"), ("pertinence", "pertinence"),
                     ("critere_communiquer", "communiquer"), ("critere_interagir", "interagir"),
                     ("critere_lexique", "lexique"), ("critere_morphosyntaxe", "morphosyntaxe")):
        a = _answer(body, key)
        row[f"{col}_choice"] = a.get("choice")
        row[f"{col}_probs"] = store.dumps(a.get("probabilities"))
        row[f"{col}_confidence"] = a.get("confidence")
    if call.ok:
        answers = body.get("answers") or {}
        missing = [k for k in prompts.QUESTION_KEYS if not (answers.get(k) or {}).get("choice")]
        if missing:
            row["error"] = f"réponse incomplète : {', '.join(missing)}"
        tn = TASK_NUMBER[sample["task_type"]]
        for variant, prefix in (("argmax_milieu", "secondaire_formule_argmax"),
                                ("esperance", "secondaire_formule_esperance")):
            f = formule.niveau_via_formule(answers, tn, variant)
            row[f"{prefix}_niveau"] = f.get("niveau")
            row[f"{prefix}_note"] = f.get("note_sur_20")
            row[f"{prefix}_json"] = store.dumps(f)
    return row


def spent_usd(conn, run_id: str | None = None) -> float:
    """Coût RÉEL (usage renvoyé par l'API) : d'un run, ou de tous les appels stockés."""
    if run_id:
        return float(conn.execute("SELECT COALESCE(SUM(cost_usd), 0) FROM jev_result WHERE run_id=?",
                                  (run_id,)).fetchone()[0])
    return float(conn.execute("SELECT COALESCE(SUM(cost_usd), 0) FROM jev_result").fetchone()[0])


FORBIDDEN_IN_STATE = ("niveau", "note_sur_20", "scores", "score", "confiance", "plafond", "evaluabilite",
                      "sample_id", "sample_key", "candidate", "user", "attempt", "submission", "rubrics",
                      "prompt_version", "modele")


def verify_payloads(conn, samples: list[dict], model: str, version: str) -> list[str]:
    """Contrôle AVANT envoi : state strictement limité aux 6 champs autorisés, aucun identifiant ni sel."""
    problems = []
    secrets_ = set()
    salt_file = config.DATA_DIR / ".salt"
    if salt_file.exists():
        secrets_.add(salt_file.read_text(encoding="utf-8").strip())
    for r in conn.execute("SELECT sample_id, json_extract(fixture_json, '$.sample_key') k FROM sample"):
        secrets_.update(x for x in (r["sample_id"], r["k"]) if x)
    secrets_.update(r[0] for r in conn.execute("SELECT candidate_key FROM real_candidate"))
    for s in samples:
        payload = prompts.build_payload(s, model, version)
        st = payload["state"]
        if set(payload) != {"model", "state", "questions"}:
            problems.append(f"{s['sample_id']} : clés de payload {sorted(payload)}")
        if tuple(st) != prompts.STATE_FIELDS:
            problems.append(f"{s['sample_id']} : champs du state {list(st)}")
        if any(k in FORBIDDEN_IN_STATE for k in st):
            problems.append(f"{s['sample_id']} : champ interdit dans le state")
        blob = json.dumps(payload, ensure_ascii=False)
        if any(x and x in blob for x in secrets_):
            problems.append(f"{s['sample_id']} : identifiant ou sel présent dans le payload")
    return problems


def real_run(conn, samples: list[dict], model: str, repeat: int, filters: dict,
             resume_run_id: str | None = None, version: str = config.PROMPT_VERSION,
             budget_usd: float = 0.20, notes: str | None = None, repeat_subset_only: bool = False) -> dict:
    """Run JEV réel. ``repeat_subset_only`` : ``repeat`` répétitions pour les cas du sous-ensemble
    « repeat », UNE pour les autres (la répétition 1 est partagée : pas d'appel en double).
    Le budget porte sur le coût RÉEL de CE run. Arrêt immédiat sur une erreur 4xx (hors 408/429,
    déjà retentées par le client) ou si le modèle renvoyé diffère d'un modèle épinglé."""
    from .jev_client import JevClient

    api_key = config.load_api_key()
    if not api_key:
        raise SystemExit(f"{config.KEY_ENV} introuvable : définir la variable ou tools/jev-benchmark/.env")
    problems = verify_payloads(conn, samples, model, version)
    if problems:
        raise SystemExit("payloads refusés avant envoi :\n  " + "\n  ".join(problems[:20]))
    print(f"  contrôle avant envoi : {len(samples)} payloads conformes (6 champs de state, aucun identifiant ni sel)")

    def reps_for(s):
        return repeat if (not repeat_subset_only or s.get("repeat_subset")) else 1

    ests = [estimate_request(prompts.build_payload(s, model, version)) for s in samples]
    est_tokens = sum(e["input_tokens_conservative"] * reps_for(s) for s, e in zip(samples, ests))
    if resume_run_id:
        run = conn.execute("SELECT * FROM benchmark_run WHERE run_id=?", (resume_run_id,)).fetchone()
        if not run or run["mode"] != "real":
            raise SystemExit(f"run réel introuvable : {resume_run_id}")
        version = run["prompt_version"]
        if run["questions_hash"] != prompts.all_questions_hash(version):
            raise SystemExit("les prompts ont changé depuis ce run : reprise refusée")
        run_id, model, repeat = run["run_id"], run["model_requested"], run["repeat"]
    else:
        run_id = _new_run(conn, "real", model, repeat, filters, len(samples), est_tokens, cost_usd(est_tokens),
                          version, notes=notes)
    pinned = model != config.DEFAULT_MODEL
    done = skipped = failed = 0
    stopped = None
    with JevClient(api_key) as client:
        for s in samples:
            if stopped:
                break
            payload = prompts.build_payload(s, model, version)
            qhash = prompts.questions_hash(payload["questions"])
            for r in range(1, reps_for(s) + 1):
                if store.successful_jev(conn, s["sample_id"], run_id, r):
                    skipped += 1
                    continue
                spent = spent_usd(conn, run_id)
                if spent > budget_usd:
                    stopped = f"budget dépassé : {spent:.4f} $ > {budget_usd} $ (usage réel de ce run)"
                    print("  ARRÊT — " + stopped)
                    break
                call = client.call(payload)
                row = _row_from_response(s, run_id, r, model, qhash, call, api_key, version)
                cols = ",".join(row)
                conn.execute(f"INSERT INTO jev_result({cols}) VALUES ({','.join('?' * len(row))})",
                             list(row.values()))
                conn.commit()
                if row["error"]:
                    failed += 1
                    print(f"  {s['sample_id']} r{r} : ERREUR {row['error'][:200]}")
                    if call.status and 400 <= call.status < 500:
                        stopped = f"erreur {call.status} (non retentée) : arrêt du run"
                        print("  ARRÊT — " + stopped)
                        break
                else:
                    done += 1
                    print(f"  {s['sample_id']} r{r} : {row['niveau_global_choice']} "
                          f"(conf {row['niveau_global_confidence']}) modèle {row['model_returned']}")
                if pinned and row["model_returned"] and row["model_returned"] != model:
                    stopped = f"modèle renvoyé {row['model_returned']} ≠ modèle épinglé {model} : arrêt"
                    print("  ARRÊT — " + stopped)
                    break
    return {"run_id": run_id, "prompt_version": version, "modele_demande": model, "ok": done,
            "deja_faits": skipped, "erreurs": failed, "cout_reel_run_usd": round(spent_usd(conn, run_id), 6),
            "cout_reel_cumule_usd": round(spent_usd(conn), 6), "arret": stopped}
