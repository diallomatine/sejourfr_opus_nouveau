"""Comptage de mots identique au serveur, et bornes officielles EE.

Reproduit ``ProductionPayloadSupport.sanitizeText`` (NFC + ``String.strip()``)
puis ``countWords`` (``trim().split("\\s+")``). En Java, ``\\s`` sans
UNICODE_CHARACTER_CLASS ne couvre que les blancs ASCII : une espace insécable
n'est donc PAS un séparateur, contrairement au ``\\s`` de Python.
"""
from __future__ import annotations

import re
import unicodedata

_JAVA_WS = re.compile(r"[ \t\n\x0b\f\r]+")

# Contrainte SQL chk_prod_task_tcf_irn_ee_word_bounds (V756) ; refus 422 hors bornes.
OFFICIAL_BOUNDS = {
    "EE_TASK_1": (30, 60),
    "EE_TASK_2": (40, 90),
    "EE_TASK_3": (40, 90),
}

TASK_NUMBER = {"EE_TASK_1": 1, "EE_TASK_2": 2, "EE_TASK_3": 3}


def _java_is_whitespace(ch: str) -> bool:
    """Character.isWhitespace : séparateurs Unicode SAUF insécables, plus \\t\\n\\x0b\\f\\r et \\x1c-\\x1f."""
    if ch in "   ":
        return False
    if ch in "\t\n\x0b\f\r\x1c\x1d\x1e\x1f":
        return True
    return unicodedata.category(ch) in ("Zs", "Zl", "Zp")


def java_strip(text: str) -> str:
    start, end = 0, len(text)
    while start < end and _java_is_whitespace(text[start]):
        start += 1
    while end > start and _java_is_whitespace(text[end - 1]):
        end -= 1
    return text[start:end]


def sanitize(text: str) -> str:
    return java_strip(unicodedata.normalize("NFC", text))


def count_words(text: str | None) -> int:
    if text is None:
        return 0
    t = sanitize(text)
    # String.trim() retire en plus tout caractère <= U+0020.
    t = t.strip("".join(chr(c) for c in range(0x21)))
    if not t:
        return 0
    return len(_JAVA_WS.split(t))


def length_info(task_type: str, text: str) -> dict:
    wc = count_words(text)
    lo, hi = OFFICIAL_BOUNDS[task_type]
    return {
        "word_count": wc,
        "official_min": lo,
        "official_max": hi,
        "below_official_min": wc < lo,
        "above_official_max": wc > hi,
        "official_length_compliant": lo <= wc <= hi,
    }
