"""Q-F30 partie 1, etape 1 — EXTRACTION des listes officielles de questions.

Source : les pages publiques du ministere de l'Interieur (art. 3 de l'arrete du
10 octobre 2025, NOR INTV2527907A : « Les questions de connaissances sont rendues
publiques sur le site internet du ministere charge des naturalisations »).

  CSP : formation-civique.interieur.gouv.fr/examen-civique/liste-officielle-des-questions-de-connaissance-csp/
  CR  : formation-civique.interieur.gouv.fr/examen-civique/liste-officielle-des-questions-de-connaissance-cr/
  NAT : INDISPONIBLE — immigration.interieur.gouv.fr est derriere Cloudflare (403).

Selecteur : les enonces sont les <li data-block-key="..."> du corps de page ; la
navigation porte <li class="fr-nav__item">. La thematique se deduit de la position
relative aux marqueurs <b>Label :</b>.

AUCUN APPEL LLM. C'est du parsing HTML, et rien d'autre (D-40).
"""
import re, sys, html, unicodedata
from collections import Counter

THEMES = [("T1","Principes et valeurs de la République"),
          ("T2","Système institutionnel et politique"),
          ("T3","Droits et devoirs"),
          ("T4","Histoire géographie et culture"),
          ("T5","Vivre dans la société française")]

def txt(s):
    return re.sub(r'\s+', ' ', html.unescape(re.sub(r'<[^>]+>', ' ', s))).replace('\xa0',' ').strip()

def cle(s):
    """Comparaison : casse, accents, ponctuation, espaces, apostrophes neutralisés."""
    s = unicodedata.normalize('NFD', s.lower().replace("’","'").replace("œ","oe").replace("æ","ae"))
    s = ''.join(c for c in s if unicodedata.category(c) != 'Mn')
    return re.sub(r'\s+', ' ', re.sub(r"[^a-z0-9]+", " ", s)).strip()

def extraire(path, mention):
    h = open(path, encoding="utf-8").read()
    # Les marqueurs de thématique : <b>Label :</b>
    bornes = []
    for code, label in THEMES:
        m = re.search(r'<b>\s*' + re.escape(label) + r'\s*:', h)
        if not m:
            print(f"!! {mention}: marqueur introuvable « {label} »", file=sys.stderr); sys.exit(2)
        bornes.append((code, m.start()))
    assert [b[1] for b in bornes] == sorted(b[1] for b in bornes), f"{mention}: marqueurs désordonnés"

    # Les énoncés : <li data-block-key="..."> — jamais la navigation (fr-nav__item)
    rows = []
    for m in re.finditer(r'<li data-block-key="[^"]*">(.*?)</li>', h, re.S):
        t = txt(m.group(1))
        if not t: continue
        code = None
        for c, pos in bornes:
            if m.start() > pos: code = c
        if code is None:
            print(f"!! {mention}: énoncé avant le 1er marqueur : {t[:60]}", file=sys.stderr); sys.exit(2)
        rows.append((code, t))
    return rows

tous = {}
for mention, path in [("CSP","csp.html"), ("CR","cr.html")]:
    rows = extraire(path, mention)
    tous[mention] = rows
    with open(f"{mention}.tsv","w",encoding="utf-8") as f:
        f.write("mention\ttheme\tenonce\tcle\n")
        for code,t in rows: f.write(f"{mention}\t{code}\t{t}\t{cle(t)}\n")
    c = Counter(code for code,_ in rows)
    doublons = len(rows) - len({cle(t) for _,t in rows})
    print(f"{mention}: {len(rows):>3} énoncés  " + "  ".join(f"{k}={c[k]:>2}" for k,_ in THEMES)
          + f"   | doublons internes: {doublons}")
