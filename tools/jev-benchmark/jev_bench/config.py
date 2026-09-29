"""Chemins, constantes et lecture de la clé JEV (jamais affichée)."""
from __future__ import annotations

import os
from pathlib import Path

TOOL_DIR = Path(__file__).resolve().parent.parent
REPO_ROOT = TOOL_DIR.parent.parent
PACKAGE_DIR = TOOL_DIR / "jev_bench"
PROMPTS_DIR = PACKAGE_DIR / "prompts"
SQL_DIR = PACKAGE_DIR / "sql"
FIXTURES_FILE = TOOL_DIR / "fixtures" / "synthetic_ee_v1.jsonl"
DATA_DIR = TOOL_DIR / "data"
DB_FILE = DATA_DIR / "benchmark.sqlite"
DRY_RUN_DIR = DATA_DIR / "dry-run"
EXPORT_DIR = DATA_DIR / "exports"
ENV_FILE = TOOL_DIR / ".env"

BACKEND_DIR = REPO_ROOT / "backend_sejourfr"
RUBRICS_V15_FILE = BACKEND_DIR / "src/main/resources/prompts/production-rubrics-v15.json"
APPLICATION_YAML = BACKEND_DIR / "src/main/resources/application.yaml"

JEV_URL = "https://api.typesafe.ai/v1/systemone"
DEFAULT_MODEL = "jev-latest"
# Deux versions coexistantes, JAMAIS mélangées dans une statistique.
PROMPT_VERSION = "jev-independent-v1"          # benchmark PRINCIPAL (critères §19–22 de la spec)
PROMPT_VERSION_V15 = "jev-v15-aligned-v1"      # benchmark SECONDAIRE de sensibilité (descripteurs v15)
PROMPT_VERSIONS = (PROMPT_VERSION, PROMPT_VERSION_V15)
# Tarif JEV : 0,042 $ par million de tokens d'entrée ; la sortie est gratuite.
PRICE_USD_PER_M_INPUT = 0.042
# Contexte JEV : 32k tokens de state + la question la plus longue.
STATE_TOKEN_LIMIT = 32_000

KEY_ENV = "JEV_API_KEY"

EXPECTED_RUBRICS_VERSION = "v15"
EXPECTED_PROMPT_VERSION = "v9"

# Backend SejourFR : LOCAL uniquement.
LOCAL_BACKEND_DEFAULT = "http://localhost:8080"
ALLOWED_BACKEND_HOSTS = {"localhost", "127.0.0.1"}
LOCAL_DB_NAME = "sejourfr_db"
LOCAL_DB_USER = "diallomatine"
SEED_USER_EMAIL = "user@sejourfr.fr"
SEED_USER_PASSWORD = "User123!"


def _read_env_file(path: Path) -> dict[str, str]:
    """Parseur minimal KEY=VALUE (commentaires #, guillemets simples ou doubles)."""
    out: dict[str, str] = {}
    if not path.is_file():
        return out
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        if line.startswith("export "):
            line = line[len("export "):]
        key, _, value = line.partition("=")
        value = value.strip()
        if len(value) >= 2 and value[0] == value[-1] and value[0] in "'\"":
            value = value[1:-1]
        out[key.strip()] = value
    return out


def load_api_key() -> str | None:
    """Clé JEV : environnement du processus, sinon tools/jev-benchmark/.env. Jamais loggée."""
    value = os.environ.get(KEY_ENV)
    if value:
        return value.strip()
    value = _read_env_file(ENV_FILE).get(KEY_ENV)
    return value.strip() if value else None


def redact(text: str, secret: str | None) -> str:
    """Masque la clé dans tout texte destiné à une trace ou à la base."""
    if not text:
        return text
    if secret:
        text = text.replace(secret, "***")
    return text
