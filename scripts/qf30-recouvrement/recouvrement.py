"""Q-F30 partie 1, etape 2 — RECOUVREMENT entre les listes officielles.

Repond a la seule question de Q-F30 (D-28) : les listes publiques se recouvrent-elles,
ou portent-elles des contenus distincts ? Se lit sur les TSV produits par extraire.py,
SANS rattacher quoi que ce soit aux 16 unites officielles (D-40).

Deux appariements, tous deux deterministes :
  - STRICT   : egalite de la cle normalisee (casse, accents, ponctuation, apostrophes).
  - QUASI    : Jaccard >= 0,60 sur les mots de plus de 3 lettres, parmi les exclusifs.

AUCUN APPEL LLM (D-40). Si l'appariement echoue, on remonte le chiffre d'echec.
"""
import csv, re
from collections import defaultdict, Counter

def lire(m):
    with open(f"{m}.tsv", encoding="utf-8") as f:
        return list(csv.DictReader(f, delimiter="\t"))

csp, cr = lire("CSP"), lire("CR")
kc = {r["cle"]: r for r in csp}
kr = {r["cle"]: r for r in cr}

# --- 1. appariement strict (clé normalisée) ---
communs = set(kc) & set(kr)
print(f"Énoncés distincts  CSP {len(kc)}   CR {len(kr)}")
print(f"Appariement STRICT (clé normalisée) : {len(communs)} communs")
print(f"  exclusifs CSP {len(kc)-len(communs)}   exclusifs CR {len(kr)-len(communs)}")
u = len(kc) + len(kr) - len(communs)
print(f"  Jaccard = {len(communs)}/{u} = {len(communs)/u:.1%}")
print(f"  part de CSP couverte par CR : {len(communs)/len(kc):.1%}")
print(f"  part de CR couverte par CSP : {len(communs)/len(kr):.1%}")

# --- 2. par thématique ---
print("\nPar thématique (strict) :")
print(f"{'':4} {'CSP':>4} {'CR':>4} {'communs':>8} {'excl.CSP':>9} {'excl.CR':>8}")
for t in ("T1","T2","T3","T4","T5"):
    a = {k for k,v in kc.items() if v["theme"]==t}
    b = {k for k,v in kr.items() if v["theme"]==t}
    # un énoncé commun peut changer de thématique entre listes : on compte l'intersection globale
    inter = (a|b) & communs
    print(f"{t:4} {len(a):>4} {len(b):>4} {len(a&b):>8} {len(a-communs):>9} {len(b-communs):>8}")

# --- 3. énoncés communs rangés dans une thématique DIFFÉRENTE ---
diff = [(kc[k]["theme"], kr[k]["theme"], kc[k]["enonce"]) for k in communs
        if kc[k]["theme"] != kr[k]["theme"]]
print(f"\nÉnoncés communs rangés dans une thématique DIFFÉRENTE : {len(diff)}")
for a,b,e in diff[:10]: print(f"  {a}→{b}  {e[:88]}")

# --- 4. quasi-appariement : mots en commun (Jaccard sur tokens) ---
def toks(s): return set(w for w in s.split() if len(w) > 3)
restants_c = [k for k in kc if k not in communs]
restants_r = [k for k in kr if k not in communs]
tr = [(k, toks(k)) for k in restants_r]
quasi = []
for k in restants_c:
    tc = toks(k)
    if not tc: continue
    best, score = None, 0.0
    for k2, t2 in tr:
        if not t2: continue
        j = len(tc & t2) / len(tc | t2)
        if j > score: best, score = k2, j
    if score >= 0.60: quasi.append((score, kc[k]["enonce"], kr[best]["enonce"]))
quasi.sort(reverse=True)
print(f"\nQuasi-appariements (tokens ≥ 0,60) parmi les exclusifs : {len(quasi)}")
for s,a,b in quasi[:12]: print(f"  {s:.2f}  CSP: {a[:72]}\n        CR : {b[:72]}")

tot = len(communs) + len(quasi)
print(f"\nRecouvrement strict + quasi : {tot} / {len(kc)} CSP = {tot/len(kc):.1%}")
print(f"                              {tot} / {len(kr)} CR  = {tot/len(kr):.1%}")

# doublon interne CSP
d = [k for k,n in Counter(r["cle"] for r in csp).items() if n > 1]
print(f"\nDoublon interne CSP : {[kc[k]['enonce'] for k in d]}")
