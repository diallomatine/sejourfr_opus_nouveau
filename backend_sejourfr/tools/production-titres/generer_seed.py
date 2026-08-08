#!/usr/bin/env python3
"""Convertit les 6 fiches JSON de titres en UNE migration Flyway de contenu.

    python3 tools/production-titres/generer_seed.py

Sortie : src/main/resources/db/migration/300_tcf/production/V754__tcf_production_titres.sql

CE GENERATEUR EST LA SOURCE DE VERITE DU CONTENU PUBLIE, comme
tools/competences/. Les titres sont produits, jamais ecrits a la main dans le
SQL : editer le .sql directement ferait diverger les deux, et la prochaine
regeneration ecraserait la correction.

(Le contenu vivant, lui, s'edite depuis la console d'administration une fois la
migration appliquee — PATCH /api/admin/production-tasks/{id}/titre. Ce
generateur ne sert qu'a republier depuis une base propre.)

Contrairement aux competences, les sujets EXISTENT DEJA en base avec des UUID
poses par V700-V753 : la migration est donc une suite d'UPDATE bornes par un
`WHERE id =` explicite, deterministes et idempotents. Aucune ligne n'est creee,
aucune n'est supprimee.

Le script VALIDE avant d'ecrire (2 a 5 mots, pas de chiffre, pas de jargon de
tache/niveau, unicite a l'interieur d'une tache, UUID bien formes) et refuse de
produire du SQL sur du contenu non conforme. Aucune dependance : Python 3 seul.
"""

from __future__ import annotations

import json
import re
import sys
import unicodedata
from pathlib import Path

ICI = Path(__file__).resolve().parent
CONTENU = ICI / "contenu"
# tools/production-titres/ -> backend_sejourfr/ -> src/main/resources/...
CIBLE = ICI.parent.parent / "src/main/resources/db/migration/300_tcf/production"

VERSION = 754
FICHIER = f"V{VERSION}__tcf_production_titres.sql"

# Ordre de lecture = ordre d'ecriture dans le SQL : une tache par bloc.
FICHES = ["EE1", "EE2", "EE3", "EO1", "EO2", "EO3"]

# Aligne sur production_tasks.titre varchar(80) (V028).
TITRE_MAX_CARACTERES = 80
TITRE_MIN_MOTS = 2
TITRE_MAX_MOTS = 5

UUID_RE = re.compile(r"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$")

# Ce qu'un titre ne dit JAMAIS : la carte porte deja la tache, le palier et la
# contrainte de longueur/duree. Les redire, c'est occuper la seule ligne qui
# distingue un sujet d'un autre.
INTERDITS = ("tache", "niveau", "mots", "minutes", "secondes",
             "a2", "b1", "b2", "a1", "sujet", "tcf")


def q(value: str) -> str:
    """Litteral SQL texte, apostrophes echappees a la mode Postgres."""
    return "'" + value.replace("'", "''") + "'"


def sans_accents(texte: str) -> str:
    decompose = unicodedata.normalize("NFD", texte)
    return "".join(c for c in decompose if not unicodedata.combining(c)).lower()


def valider(doc: dict, code: str) -> None:
    """Refuse un contenu non conforme plutot que de publier un titre inutile."""
    assert doc["epreuve"] in ("TCF_EE", "TCF_EO"), f"{code}: epreuve {doc['epreuve']}"
    assert code.startswith(doc["epreuve"][-2:]), f"{code} incoherent avec {doc['epreuve']}"
    assert doc["tacheNumero"] == int(code[-1]), f"{code}: tacheNumero {doc['tacheNumero']}"

    titres = doc["titres"]
    assert titres, f"{code}: aucune entree"

    vus_id: set[str] = set()
    # Comparaison de distinction : accents et casse retires, pour qu'un
    # « Ville ou campagne » ne cotoie jamais un « ville ou campagne ».
    vus_titre: dict[str, str] = {}

    for entree in titres:
        ident = entree["id"]
        titre = entree["titre"]
        repere = f"{code}/{ident}"

        assert UUID_RE.match(ident), f"{repere}: UUID mal forme"
        assert ident not in vus_id, f"{repere}: id en double"
        vus_id.add(ident)

        assert titre == titre.strip(), f"{repere}: espaces en bord de titre"
        assert titre, f"{repere}: titre vide"
        assert len(titre) <= TITRE_MAX_CARACTERES, \
            f"{repere}: {len(titre)} caracteres (max {TITRE_MAX_CARACTERES})"

        mots = titre.split()
        assert TITRE_MIN_MOTS <= len(mots) <= TITRE_MAX_MOTS, \
            f"{repere}: « {titre} » fait {len(mots)} mots (attendu {TITRE_MIN_MOTS}-{TITRE_MAX_MOTS})"

        assert titre[0].isupper(), f"{repere}: « {titre} » ne commence pas par une majuscule"
        assert titre[-1] not in ".!?:;,", f"{repere}: « {titre} » se termine par une ponctuation"
        assert not any(c.isdigit() for c in titre), f"{repere}: « {titre} » contient un chiffre"

        plat = sans_accents(titre)
        for interdit in INTERDITS:
            assert interdit not in plat.split() and not plat.startswith(interdit + " "), \
                f"{repere}: « {titre} » redit ce que la carte affiche deja ({interdit})"

        # Deux sujets d'une meme tache doivent se distinguer AU PREMIER COUP
        # D'OEIL : c'est toute la raison d'etre de ces titres.
        assert plat not in vus_titre, \
            f"{repere}: « {titre} » se confond avec « {vus_titre[plat]} »"
        vus_titre[plat] = titre

        # Le repere n'est pas publie : c'est l'aide de relecture qui rattache
        # le titre a sa consigne reelle. On exige seulement qu'il existe.
        assert entree["repere"].strip(), f"{repere}: repere de relecture manquant"


def rendre(docs: dict[str, dict]) -> str:
    total = sum(len(d["titres"]) for d in docs.values())

    out: list[str] = []
    a = out.append

    a("-- ============================================================================")
    a(f"-- V{VERSION} — Titres editoriaux des sujets EO/EE ({total} sujets)")
    a("-- ----------------------------------------------------------------------------")
    a("-- Colonne posee par V028 (NULLABLE). Ici, le CONTENU : un intitule court,")
    a("-- nominal et fidele a la consigne pour chacun des sujets publies.")
    a("--")
    a("-- Pourquoi : les cartes de sujet affichaient « Sujet 01 » + le debut de la")
    a("-- consigne. Or les consignes d'une meme tache commencent toutes de la meme")
    a("-- facon (« Ecrivez un message a… », « Racontez… », « Donnez votre avis… ») :")
    a("-- dans une liste de vingt sujets, rien ne les distinguait.")
    a("--")
    a("-- Regles de redaction, verifiees par le generateur : 2 a 5 mots, forme")
    a("-- nominale, aucun chiffre, aucun jargon (« Tache 2 », palier CECRL, nombre")
    a("-- de mots — tout cela est deja affiche ailleurs sur la carte), et deux")
    a("-- sujets d'une meme tache ne se confondent jamais.")
    a("--")
    a("-- Deterministe et idempotent : un UPDATE par sujet, borne par son id.")
    a("-- Aucune ligne creee, aucune supprimee, aucune consigne touchee.")
    a("--")
    a("-- FICHIER GENERE — NE PAS EDITER A LA MAIN.")
    a("--")
    a("--   cd backend_sejourfr && python3 tools/production-titres/generer_seed.py")
    a("--")
    a("-- On edite la fiche tools/production-titres/contenu/<TACHE>.json, puis on")
    a("-- regenere. Une correction faite ici serait ecrasee a la prochaine")
    a("-- generation, et les deux sources auraient diverge entre-temps.")
    a("--")
    a("-- (Le contenu vivant, lui, s'edite depuis la console d'administration une")
    a("-- fois la migration appliquee : c'est la base qui fait foi, pas ce JSON.)")
    a("-- ============================================================================")
    a("")

    for code in FICHES:
        doc = docs[code]
        a(f"-- {code} — {doc['libelle']} ({len(doc['titres'])} sujets)")
        for entree in doc["titres"]:
            a(f"UPDATE production_tasks SET titre = {q(entree['titre'])} "
              f"WHERE id = '{entree['id']}';")
        a("")

    return "\n".join(out)


def main() -> int:
    docs: dict[str, dict] = {}
    for code in FICHES:
        chemin = CONTENU / f"{code}.json"
        if not chemin.exists():
            print(f"fiche manquante : {chemin}", file=sys.stderr)
            return 1
        doc = json.loads(chemin.read_text(encoding="utf-8"))
        try:
            valider(doc, code)
        except AssertionError as err:
            print(f"contenu non conforme — {err}", file=sys.stderr)
            return 1
        docs[code] = doc

    # Un id ne doit apparaitre que dans UNE fiche : sinon deux UPDATE se
    # marcheraient dessus et le titre publie dependrait de l'ordre.
    tous: dict[str, str] = {}
    for code, doc in docs.items():
        for entree in doc["titres"]:
            if entree["id"] in tous:
                print(f"id {entree['id']} present dans {tous[entree['id']]} et {code}",
                      file=sys.stderr)
                return 1
            tous[entree["id"]] = code

    CIBLE.mkdir(parents=True, exist_ok=True)
    sortie = CIBLE / FICHIER
    sortie.write_text(rendre(docs) + "\n", encoding="utf-8")
    print(f"{sortie.relative_to(ICI.parent.parent)} — {len(tous)} titres")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
