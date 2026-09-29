"""Client HTTP de l'API JEV (TypeSafe System One).

- timeout explicite ; retry BORNÉ avec backoff exponentiel sur erreur réseau,
  5xx, 408 et 429 (``Retry-After`` respecté, plafonné) ; aucun retry sur les
  autres 4xx ;
- la clé n'apparaît dans AUCUNE trace : l'en-tête Authorization n'est jamais
  journalisé et tout message d'erreur passe par ``config.redact``.
"""
from __future__ import annotations

import random
import time
from dataclasses import dataclass

import httpx

from . import config

RETRYABLE_STATUS = {408, 429, 500, 502, 503, 504}
MAX_RETRY_AFTER_S = 60.0


@dataclass
class JevCall:
    ok: bool
    status: int | None
    body: dict | None
    error: str | None
    attempts: int
    latency_ms: int


class JevClient:
    def __init__(self, api_key: str, url: str = config.JEV_URL, timeout_s: float = 120.0,
                 max_attempts: int = 4, backoff_base_s: float = 2.0):
        if not api_key:
            raise ValueError(f"{config.KEY_ENV} absente (environnement ou tools/jev-benchmark/.env)")
        self._key = api_key
        self._url = url
        self._max_attempts = max_attempts
        self._backoff = backoff_base_s
        self._client = httpx.Client(
            timeout=httpx.Timeout(timeout_s, connect=15.0),
            headers={"Content-Type": "application/json"},
        )

    def close(self) -> None:
        self._client.close()

    def __enter__(self):
        return self

    def __exit__(self, *exc):
        self.close()

    def _headers(self) -> dict:
        return {"Authorization": f"Bearer {self._key}"}

    def _safe(self, text: str) -> str:
        return config.redact(text, self._key)[:2000]

    @staticmethod
    def _retry_after(resp: httpx.Response) -> float | None:
        raw = resp.headers.get("Retry-After")
        if not raw:
            return None
        try:
            return min(float(raw), MAX_RETRY_AFTER_S)
        except ValueError:
            return None

    def call(self, payload: dict) -> JevCall:
        started = time.monotonic()
        last_error = None
        last_status = None
        for attempt in range(1, self._max_attempts + 1):
            wait = None
            try:
                resp = self._client.post(self._url, json=payload, headers=self._headers())
            except httpx.HTTPError as exc:
                last_error = self._safe(f"{type(exc).__name__}: {exc}")
                last_status = None
            else:
                last_status = resp.status_code
                if 200 <= resp.status_code < 300:
                    try:
                        body = resp.json()
                    except ValueError:
                        return JevCall(False, resp.status_code, None,
                                       self._safe("réponse non JSON : " + resp.text), attempt,
                                       int((time.monotonic() - started) * 1000))
                    return JevCall(True, resp.status_code, body, None, attempt,
                                   int((time.monotonic() - started) * 1000))
                last_error = self._safe(f"HTTP {resp.status_code}: {resp.text}")
                if resp.status_code not in RETRYABLE_STATUS:
                    break
                wait = self._retry_after(resp)
            if attempt < self._max_attempts:
                if wait is None:
                    wait = self._backoff * (2 ** (attempt - 1)) + random.uniform(0, 0.5)
                time.sleep(wait)
        return JevCall(False, last_status, None, last_error, attempt,
                       int((time.monotonic() - started) * 1000))
