"""Rédaction LOCALE des données personnelles d'une production réelle, AVANT tout stockage.

Remplace par [EMAIL], [URL], [TELEPHONE], [ADRESSE], [PERSONNE] (le code postal + ville
devient [ADRESSE]). Prudence : on ne détruit pas le texte ; seuls les motifs évidents
sont remplacés. Les prénoms qui figurent dans la consigne ou le contexte (personnages
fictifs du sujet, ex. « Lucia ») ne sont PAS des données personnelles : ils sont gardés.

Le texte original n'est jamais conservé : l'appelant ne garde que le texte rédigé, un
compteur par type et, pour l'audit local, le contexte (5 mots) autour de chaque
remplacement — jamais la valeur remplacée.
"""
from __future__ import annotations

import re
from collections import Counter

MAJ = r"[A-ZÀÂÄÇÉÈÊËÎÏÔÖÙÛÜŸ]"
MIN = r"[a-zàâäçéèêëîïôöùûüÿœæ'’-]"
LET = r"[a-zàâäçéèêëîïôöùûüÿœæ]"
NOM = rf"{MAJ}{LET}+(?:[- ]{MAJ}{LET}+){{0,2}}"  # Prénom, Prénom-Composé, Prénom Nom, Titre Prénom Nom

EMAIL = re.compile(r"[\w.+-]+@[\w-]+(?:\.[\w-]+)+")
URL = re.compile(r"\b(?:https?://|www\.)\S+", re.I)
TEL = re.compile(r"(?<!\w)(?:\+\d{1,3}[\s.-]?)?(?:\(?0\)?[\s.-]?)?\d(?:[\s.-]?\d{2}){4}(?!\w)"
                 r"|(?<!\w)\+\d{1,3}(?:[\s.-]?\d{2,4}){2,5}(?!\w)")
VOIE = r"(?:rue|avenue|av\.|boulevard|bd|place|chemin|allée|allee|impasse|route|quai|cours|square|résidence|residence)"
ADRESSE = re.compile(rf"\b\d{{1,4}}\s?(?:bis|ter)?,?\s+{VOIE}\b(?:\s+(?:de|du|des|d'|d’|la|le|l'|l’)?\s*{MAJ}[\w'’-]*){{1,4}}", re.I)
CP_VILLE = re.compile(rf"\b\d{{5}}\s+{MAJ}[\w'’-]+(?:[- ]{MAJ}[\w'’-]+)*")

# Nom après une formule d'adresse ou de présentation.
APRES_FORMULE = re.compile(
    rf"(?P<f>\b(?:[Cc]h[eè]re?s?|[Bb]onjour|[Bb]onsoir|[Ss]alut|[Cc]oucou|[Hh]ello|"
    rf"[Mm]adame|[Mm]onsieur|Mme\.?|M\.|Mlle\.?|[Jj]e m['’]appelle|[Mm]oi,? c['’]est|[Mm]on nom est|"
    rf"[Mm]on (?:ami|amie|voisin|voisine|collègue|frère|sœur|mari|fils|cousin|cousine) )\s*)(?P<nom>{NOM})")
RELATION = (r"(?:chéri|chérie|cher|chère|copain|copine|ami|amie|voisin|voisine|collègue|frère|sœur|soeur|mari|"
            r"femme|fils|fille|cousin|cousine|oncle|tante|neveu|nièce|belle-sœur|beau-frère|patron|patronne|"
            r"chef|meilleur ami|meilleure amie|fiancé|fiancée|époux|épouse|bébé|petit-fils|petite-fille)")
APRES_RELATION = re.compile(rf"(?P<f>\b(?:[Mm]on|[Mm]a|[Mm]es|[Tt]on|[Tt]a|[Ss]on|[Ss]a|[Nn]otre)\s+{RELATION}s?\s*,?\s+)(?P<nom>{NOM})")
AVANT_RELATION = re.compile(rf"(?P<nom>{NOM})(?P<f>,?\s+(?:mon|ma|mes|ton|ta|son|sa|notre)\s+{RELATION}\b)")
APRES_AVEC = re.compile(rf"(?P<f>\b(?:avec|(?:anniversaire|mariage|baptême|part|nouvelles?)\s+(?:de\s+|d['’]\s*))"
                        rf"\s*)(?P<nom>{NOM})")
# Énumération de prénoms : « Assia, Nour et Hanane » (au moins deux noms capitalisés reliés).
ENUMERATION = re.compile(rf"(?<![.!?]\s)(?<!^)\b(?P<liste>{MAJ}{LET}+(?:\s*,\s*{MAJ}{LET}+)*(?:\s*,?\s+et\s+|\s+)"
                         rf"{MAJ}{LET}+(?:\s*,?\s+et\s+{MAJ}{LET}+)?)")
# Signature : dernière(s) ligne(s) faite(s) d'un nom seul, après une formule de clôture.
CLOTURE = re.compile(r"(?i)^(?:cordialement|bien (?:à|a) (?:toi|vous)|amicalement|amitiés|bises|bisous|"
                     r"(?:à|a) (?:bientôt|bientot|très vite|plus)|merci(?: beaucoup)?|salutations|"
                     r"je t['’]embrasse|gros bisous|bonne (?:journée|soirée)|au revoir)\b.*$")
SIGNATURE = re.compile(rf"^\s*(?:{NOM})(?:\s+{MAJ}\.?)?\s*[.!]?\s*$")
# Mots capitalisés qui ne sont pas des noms (formules, début de salutation).
MOTS_COURANTS = {
    "je", "j", "tu", "il", "elle", "on", "nous", "vous", "ils", "elles", "moi", "toi", "lui", "eux", "ce", "c", "ça",
    "ca", "cela", "ceci", "le", "la", "les", "l", "un", "une", "des", "du", "de", "d", "mon", "ma", "mes", "ton", "ta",
    "tes", "son", "sa", "ses", "notre", "votre", "nos", "vos", "leur", "leurs", "et", "ou", "mais", "donc", "car", "ni",
    "si", "que", "qui", "quoi", "quand", "comment", "pourquoi", "est", "suis", "es", "sommes", "êtes", "sont", "ai",
    "as", "a", "avons", "avez", "ont", "voilà", "voici", "oui", "non", "merci", "bonjour", "salut", "bonsoir",
    "hello", "coucou", "cher", "chère", "chers", "chères", "tous", "toutes", "tout", "toute", "madame", "monsieur",
    "mesdames", "messieurs", "mademoiselle", "cordialement", "bises", "bisous", "amitiés", "amicalement", "j’espère",
    "j'espère", "espère", "comment", "ça", "va", "vas", "dans", "pour", "avec", "sans", "sur", "sous", "chez", "par",
    "en", "au", "aux", "alors", "aujourd'hui", "aujourd’hui", "hier", "demain", "désolé", "désolée", "mon", "après",
    "ensuite", "enfin", "bien", "très", "félicitations", "joyeux", "joyeuse", "bonne", "bon", "super", "voila",
}


def _courant(word: str) -> bool:
    w = word.strip(",.;:!?()«»\"'’").lower()
    return w in MOTS_COURANTS or w.split("'")[0] in MOTS_COURANTS or w.split("’")[0] in MOTS_COURANTS


NON_NOMS = {"Madame", "Monsieur", "Cordialement", "Merci", "Bonjour", "Salut", "Bonsoir", "Bises", "Bisous",
            "Amitiés", "Coucou", "Hello", "Chère", "Cher", "Chers", "Chères", "Tous", "Toi", "Vous", "Le", "La",
            "Les", "Mon", "Ma", "Mes", "Madame,", "Monsieur,"}


LIEUX = {"France", "Paris", "Lyon", "Marseille", "Toulouse", "Nice", "Nantes", "Strasbourg", "Montpellier",
         "Bordeaux", "Lille", "Rennes", "Reims", "Grenoble", "Dijon", "Angers", "Nîmes", "Brest", "Tours", "Limoges",
         "Metz", "Rouen", "Caen", "Orléans", "Mulhouse", "Perpignan", "Besançon", "Europe", "Afrique", "Maroc",
         "Algérie", "Tunisie", "Sénégal", "Cameroun", "Mali", "Guinée", "Congo", "Espagne", "Italie", "Portugal",
         "Allemagne", "Belgique", "Suisse", "Canada", "Brésil", "Chine", "Inde", "Turquie", "Syrie", "Ukraine",
         "Russie", "Afghanistan", "Iran", "Égypte", "Colombie", "Mexique", "Noël", "Pâques", "Ramadan", "Aïd",
         "Internet", "Facebook", "WhatsApp", "Instagram", "Google", "Youtube", "YouTube", "TikTok", "Netflix"}


def _allowed_names(consigne: str | None, contexte: str | None) -> set[str]:
    src = f"{consigne or ''} {contexte or ''}"
    return {w for w in re.findall(rf"{MAJ}{MIN}+", src)}


def redact(text: str, consigne: str | None = None, contexte: str | None = None) -> tuple[str, Counter, list]:
    """(texte rédigé, compteur par type, audit [(type, contexte 5 mots)])."""
    allowed = _allowed_names(consigne, contexte)
    counts: Counter = Counter()

    def sub(pattern, label, s, group=None):
        def repl(m):
            if group:
                val = m.group(group)
                parts = val.split()
                if parts[0] in NON_NOMS:  # « Bonjour Madame Diaz » : on garde le titre
                    if len(parts) == 1:
                        return m.group(0)
                    parts = parts[1:]
                    val = " ".join(parts)
                if parts[0].strip(",.") in allowed or val in NON_NOMS or _courant(parts[0]):
                    return m.group(0)
                counts[label] += 1
                start = m.start(group) - m.start(0)
                whole = m.group(0)
                i = whole.index(val, start)
                return whole[:i] + f"[{label}]" + whole[i + len(val):]
            counts[label] += 1
            return f"[{label}]"
        return pattern.sub(repl, s)

    out = text
    out = sub(EMAIL, "EMAIL", out)
    out = sub(URL, "URL", out)
    out = sub(ADRESSE, "ADRESSE", out)
    out = sub(CP_VILLE, "ADRESSE", out)
    out = sub(TEL, "TELEPHONE", out)
    out = sub(APRES_FORMULE, "PERSONNE", out, group="nom")
    out = sub(APRES_RELATION, "PERSONNE", out, group="nom")
    out = sub(AVANT_RELATION, "PERSONNE", out, group="nom")
    out = sub(APRES_AVEC, "PERSONNE", out, group="nom")

    def enum_repl(m):
        words = re.findall(rf"{MAJ}{LET}+", m.group("liste"))
        if len(words) < 2 or any(_courant(w) or w in allowed or w in LIEUX for w in words):
            return m.group(0)
        counts["PERSONNE"] += 1
        return "[PERSONNE]"
    out = ENUMERATION.sub(enum_repl, out)

    # Signature : ligne « nom seul » après une ligne de clôture (ou dernière ligne après clôture).
    lines = out.split("\n")
    seen_closing = False
    for i, line in enumerate(lines):
        stripped = line.strip()
        if CLOTURE.match(stripped):
            seen_closing = True
            # « Cordialement, Karim » sur la même ligne
            m = re.search(rf"(?:[,:!]\s*|\s+)({NOM})\s*[.!]?\s*$", stripped)
            if (m and m.group(1).split()[0] not in allowed and m.group(1) not in NON_NOMS
                    and not _courant(m.group(1).split()[0]) and m.start(1) > 0):
                lines[i] = line.replace(m.group(1), "[PERSONNE]", 1)
                counts["PERSONNE"] += 1
            continue
        if seen_closing and SIGNATURE.match(stripped):
            first = stripped.split()[0].strip(".,!")
            if first not in allowed and first not in NON_NOMS and not _courant(first):
                lines[i] = line.replace(stripped.rstrip(".! "), "[PERSONNE]", 1)
                counts["PERSONNE"] += 1
    out = "\n".join(lines)

    audit = []
    words = out.split()
    for idx, w in enumerate(words):
        for label in ("EMAIL", "URL", "TELEPHONE", "ADRESSE", "PERSONNE"):
            if f"[{label}]" in w:
                audit.append((label, " ".join(words[max(0, idx - 5): idx + 6])))
    return out, counts, audit


RESIDU_MAJ = re.compile(rf"(?<![.!?\n«\"]\s)(?<!^)\b{MAJ}{MIN}{{2,}}\b")
RESIDU_CHIFFRES = re.compile(r"\d[\d\s.-]{3,}\d")


def residues(text: str, consigne: str | None = None, contexte: str | None = None) -> list[tuple[str, str]]:
    """Indices à vérifier à la main : majuscules hors début de phrase, chiffres longs, @."""
    allowed = _allowed_names(consigne, contexte) | NON_NOMS | LIEUX
    out = []
    text_sans_balises = re.sub(r"\[(?:EMAIL|URL|TELEPHONE|ADRESSE|PERSONNE)\]", "", text)
    for line in text.split("\n"):
        # retire le premier mot de chaque phrase
        for sent in re.split(r"(?<=[.!?])\s+", line.strip()):
            toks = sent.split()
            for j, tok in enumerate(toks[1:], start=1):
                w = tok.strip(",.;:!?()«»\"'’")
                if re.fullmatch(rf"{MAJ}{MIN}{{2,}}", w) and w not in allowed:
                    out.append(("MAJUSCULE", " ".join(toks[max(0, j - 3): j + 4])))
    for m in RESIDU_CHIFFRES.finditer(text):
        if len(re.sub(r"\D", "", m.group(0))) >= 4:
            out.append(("CHIFFRES", text[max(0, m.start() - 25): m.end() + 25].replace("\n", " ")))
    for m in re.finditer(r"\b[A-ZÀÂÄÇÉÈÊËÎÏÔÖÙÛÜŸ]{3,}\b", text_sans_balises):
        out.append(("MAJUSCULES_CONTINUES", m.group(0)))
    if "@" in text:
        out.append(("AROBASE", "@ présent"))
    return out
