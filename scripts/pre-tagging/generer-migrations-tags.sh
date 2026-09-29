#!/usr/bin/env bash
# =============================================================================
# Genere les DEUX migrations qui rendent le tagging civique REPRODUCTIBLE.
# -----------------------------------------------------------------------------
# POURQUOI CE SCRIPT EXISTE. La campagne du 2026-09-11 a pose 783 tags sur
# `questions.civic_notion_id` et 981 lignes dans `question_notion_suggestions`
# -- par script, directement en base. RIEN NE LES A CAPTURES EN MIGRATION.
# Mesure du 2026-09-19, base de test Zonky, toutes migrations appliquees :
#
#     base locale : 1 016 questions, 783 taguees, 981 suggestions
#     base neuve  : 1 005 questions,   1 taguee,    0 suggestion
#
# V293 est la seule migration qui pose des tags -- 366 -- et elle les LIT dans
# `question_notion_suggestions`, vide sur une base neuve. Son garde le dit :
# « sur une base neuve la campagne n'a jamais tourne et il n'y a rien a poser ».
# Elle reussit donc en ne faisant rien. Ce n'est pas un bug : c'est une migration
# qui SUPPOSE un etat qu'elle ne cree pas.
#
# 🛑 CE TRAVAIL EST DU REFERENTIEL, PAS DE LA DONNEE D'EXPLOITATION. 355 verdicts
# du proprietaire, 172 d'un agent, 17 corrections a la main : il n'existe
# aujourd'hui que dans un fichier de base de donnees sur une seule machine.
#
# -----------------------------------------------------------------------------
# LES TROIS PIEGES DE PORTABILITE, MESURES AVANT D'ECRIRE
# -----------------------------------------------------------------------------
# 1. `civic_notions.id` est en `gen_random_uuid()` (V051) : il DIFFERE d'une base
#    a l'autre. On joint donc sur `civic_notions.code`, jamais sur l'UUID.
#    `questions.id`, lui, est EXPLICITE en migration -- il est stable.
#
# 2. 8 questions civiques locales viennent de `db/migration-dev/V900__seed_dev.sql`
#    (ids `c000000X-...`), dont 5 sont taguees et 10 portent des suggestions.
#    Ce sont des donnees de DEVELOPPEMENT : elles n'existent pas en production,
#    et une migration qui les cite serait silencieusement partielle. EXCLUES.
#
# 3. `question_notion_suggestions.reviewed_by` pointe `aaaaaaaa-...-0001`
#    (admin@sejourfr.fr) sur 548 lignes -- un compte du SEED DEV. Sur une base
#    neuve il n'existe pas, et la FK echouerait. On emet donc NULL, et on garde
#    `review_verdict` + `review_source` : QUI a relu est une donnee de la machine,
#    QUE ce soit relu et par quelle autorite est une donnee du referentiel.
#
# -----------------------------------------------------------------------------
# Usage : ./generer-migrations-tags.sh [BASE] [DOSSIER_SORTIE]
#   BASE            defaut sejourfr_db
#   DOSSIER_SORTIE  defaut ./out (le script n'ecrit JAMAIS dans db/migration)
#
# 🛑 Le script ne pose rien et ne migre rien : il EMET du SQL. Deposer les
#    fichiers dans `db/migration/` est un geste humain, apres relecture.
# =============================================================================
set -euo pipefail

BASE="${1:-sejourfr_db}"
OUT="${2:-$(cd "$(dirname "$0")" && pwd)/out}"
mkdir -p "$OUT"
Q() { psql -U "${PGUSER:-diallomatine}" -d "$BASE" -X -A -t -q -c "$1"; }

# Le predicat d'exclusion du seed dev, en un seul endroit.
HORS_DEV="q.id::text NOT LIKE 'c000000%'"

TAGS=$(Q "SELECT count(*) FROM questions q WHERE q.module='CIVIQUE' AND q.civic_notion_id IS NOT NULL AND $HORS_DEV")
SUGG=$(Q "SELECT count(*) FROM question_notion_suggestions s WHERE s.question_id::text NOT LIKE 'c000000%'")
echo "→ $TAGS tags et $SUGG suggestions a emettre (seed dev exclu)." >&2

# =============================================================================
# 1. LES TAGS
# =============================================================================
{
cat <<'ENTETE'
-- ============================================================================
-- V297 — LES 815 TAGS DE LA CAMPAGNE DU 2026-09-11, ENFIN REPRODUCTIBLES
-- ============================================================================
-- CE FICHIER PORTE **LA DECISION** : quelle notion chaque question porte.
-- Sa jumelle V296 porte **CE QUI L'A PRODUITE** (les suggestions du modele et
-- les verdicts humains). Deposees dans `200_civique/` et non `00_schema/` :
-- ce sont des donnees de REFERENTIEL, au meme titre que V286 -> V295.
-- ----------------------------------------------------------------------------
-- D'OU VIENNENT CES LIGNES, ET POURQUOI ELLES ARRIVENT MAINTENANT
-- ----------------------------------------------------------------------------
-- 🛑 CE N'EST PAS UN SEED ARBITRAIRE. Ces lignes sont le produit de la CAMPAGNE
-- DE TAGGING DU 2026-09-11 : 840 questions de connaissance soumises a
-- `claude-sonnet-5` (prompt `PROMPT_TAG_NOTION_v4`) en 4 lots, puis relues --
-- 355 verdicts du proprietaire, 172 d'un agent, 17 corrections a la main,
-- 4 rejets. Materiel conserve : `scripts/pre-tagging/campagne-v4/`.
--
-- 🛑 POURQUOI SIX MOIS APRES. La campagne a ecrit DIRECTEMENT EN BASE, par
-- script, et rien ne l'a capturee. Mesure du 2026-09-19, base neuve (Zonky,
-- toutes migrations Flyway appliquees) contre la base de travail :
--
--       questions civiques : 1 005  contre  1 016
--       TAGUEES            :     1  contre     783
--       suggestions        :     0  contre     981
--
-- V293 est la seule migration qui posait des tags -- 366 -- et elle les LIT dans
-- `question_notion_suggestions`, vide sur une base neuve. Son garde le dit :
-- « sur une base neuve la campagne n'a jamais tourne et il n'y a rien a poser ».
-- Elle reussissait donc EN NE FAISANT RIEN. Ce n'etait pas un bug : c'etait une
-- migration qui SUPPOSE un etat qu'elle ne cree pas.
--
-- 🛑 CE TRAVAIL EST DU REFERENTIEL, PAS DE LA DONNEE D'EXPLOITATION -- au meme
-- titre que les 16 unites officielles de V115, qui sont bien en migration, elles.
-- Une relecture humaine ne se refait pas.
--
-- GENEREE par `scripts/pre-tagging/generer-migrations-tags.sh`, versionne comme
-- seule trace de la methode. Ne pas editer ce fichier a la main : regenerer.
-- Arbitrage complet, pieges de portabilite et verifications : DETTE-T1 dans
-- `docs/decisions/plan-parcours-tcf.md`.
--
-- ⚠️ TROIS EXCLUSIONS / SUBSTITUTIONS, mesurees avant d'ecrire (DETTE-T1) :
--   1. jointure sur `civic_notions.code`, JAMAIS sur son UUID : il est en
--      `gen_random_uuid()` (V051) et differe d'une base a l'autre. Les
--      `questions.id`, eux, sont explicites en migration donc stables ;
--   2. les 8 questions de `db/migration-dev/V900__seed_dev.sql` (ids
--      `c000000X-...`) sont EXCLUES : donnees de developpement, absentes de la
--      production, une migration qui les cite serait silencieusement partielle ;
--   3. `reviewed_by` est emis a NULL : il pointait un compte du seed dev.
--      QUI a relu est une donnee de la MACHINE ; QUE ce soit relu, et par quelle
--      AUTORITE (`review_source`), est une donnee du REFERENTIEL.
--
-- 🛑 IDEMPOTENTE : `WHERE q.civic_notion_id IS NULL`. Une decision deja prise ne
-- se reecrit pas -- meme regle que V293. Verifie a blanc sur la base de travail :
-- 0 posees, 815 deja en place, garde final au vert.
--
-- 🛑 VERIFIEE SUR BASE NEUVE avant depot : 1 taguee -> 815, dont 778
-- connaissances actives -- exactement le compte de la base de travail hors seed
-- dev. Le garde final n'a pas tire, ce qui est la vraie preuve de la manoeuvre.
-- ============================================================================

DO $$
DECLARE
    attendus  integer;
    posees    integer;
    manquants integer;
BEGIN
    CREATE TEMP TABLE tags_campagne (question_id uuid, notion_code varchar(64)) ON COMMIT DROP;

    INSERT INTO tags_campagne (question_id, notion_code) VALUES
ENTETE

Q "SELECT string_agg(format('    (%L, %L)', q.id, n.code), E',\n' ORDER BY n.theme_code, n.code, q.id)
   FROM questions q JOIN civic_notions n ON n.id = q.civic_notion_id
   WHERE q.module='CIVIQUE' AND q.civic_notion_id IS NOT NULL AND $HORS_DEV"
echo "    ;"

cat <<ENTETE

    SELECT count(*) INTO attendus FROM tags_campagne;
    IF attendus <> $TAGS THEN
        RAISE EXCEPTION 'Tags civiques : % lignes generees, $TAGS attendues.', attendus;
    END IF;

    -- 🛑 Toute notion citee doit exister. Un code inconnu voudrait dire que le
    -- referentiel a bouge depuis la generation : on refuse de taguer a cote.
    SELECT count(*) INTO manquants FROM (
        SELECT DISTINCT t.notion_code FROM tags_campagne t
        WHERE NOT EXISTS (SELECT 1 FROM civic_notions n WHERE n.code = t.notion_code)) x;
    IF manquants > 0 THEN
        RAISE EXCEPTION 'Tags civiques : % code(s) de notion inconnu(s) du referentiel.', manquants;
    END IF;

    UPDATE questions q
       SET civic_notion_id = n.id
      FROM tags_campagne t JOIN civic_notions n ON n.code = t.notion_code
     WHERE q.id = t.question_id
       AND q.civic_notion_id IS NULL;

    GET DIAGNOSTICS posees = ROW_COUNT;

    -- 🛑 LE GARDE FINAL, meme patron que celui des 16 unites : il echoue
    -- BRUYAMMENT et il dit quoi faire. Une migration de referentiel qui pose
    -- « presque » tous ses tags est pire qu'une qui echoue.
    SELECT count(*) INTO manquants
      FROM tags_campagne t JOIN questions q ON q.id = t.question_id
      JOIN civic_notions n ON n.code = t.notion_code
     WHERE q.civic_notion_id IS DISTINCT FROM n.id;
    IF manquants > 0 THEN
        RAISE EXCEPTION
            'Tags civiques : % question(s) ne portent pas le tag attendu (% posees sur % lignes). '
            'Soit une question a deja un AUTRE tag -- une decision plus recente, a arbitrer --, '
            'soit son id a change. Verifier avant de forcer.',
            manquants, posees, attendus;
    END IF;

    RAISE NOTICE 'Tags civiques : % posees, % deja en place.', posees, attendus - posees;
END \$\$;
ENTETE
} > "$OUT/V297__tags_campagne_civique.sql"

# =============================================================================
# 2. LES SUGGESTIONS — la tracabilite de la campagne
# =============================================================================
{
cat <<'ENTETE'
-- ============================================================================
-- V296 — `question_notion_suggestions` : LA TRACABILITE DE LA CAMPAGNE (971 l.)
-- ============================================================================
-- CE FICHIER PORTE **CE QUI A PRODUIT LA DECISION** : quel modele a propose
-- quoi, avec quelle confiance, quel prompt, et ce qu'un humain en a fait.
-- Sa jumelle V297 porte **LA DECISION** elle-meme (les tags).
--
-- 🛑 POURQUOI ELLE EXISTE ALORS QUE V293 N'EN A PLUS BESOIN. V297 pose ses
-- 815 tags sans lire cette table. Mais ces 971 lignes sont ce qui permettra de
-- REJOUER ou d'AUDITER le tagging -- et de mesurer le modele sans que la mesure
-- se nourrisse de ses propres decisions (cf. l'argumentaire de V293 sur le seuil
-- 0,95). Les perdre au motif qu'une migration n'en a plus besoin serait jeter la
-- seule trace de la methode.
-- ----------------------------------------------------------------------------
-- D'OU VIENNENT CES LIGNES, ET POURQUOI ELLES ARRIVENT MAINTENANT
-- ----------------------------------------------------------------------------
-- 🛑 CE N'EST PAS UN SEED ARBITRAIRE. Ces lignes sont le produit de la CAMPAGNE
-- DE TAGGING DU 2026-09-11 : 840 questions de connaissance soumises a
-- `claude-sonnet-5` (prompt `PROMPT_TAG_NOTION_v4`) en 4 lots, puis relues --
-- 355 verdicts du proprietaire, 172 d'un agent, 17 corrections a la main,
-- 4 rejets. Materiel conserve : `scripts/pre-tagging/campagne-v4/`.
--
-- 🛑 POURQUOI SIX MOIS APRES. La campagne a ecrit DIRECTEMENT EN BASE, par
-- script, et rien ne l'a capturee. Mesure du 2026-09-19, base neuve (Zonky,
-- toutes migrations Flyway appliquees) contre la base de travail :
--
--       questions civiques : 1 005  contre  1 016
--       TAGUEES            :     1  contre     783
--       suggestions        :     0  contre     981
--
-- V293 est la seule migration qui posait des tags -- 366 -- et elle les LIT dans
-- `question_notion_suggestions`, vide sur une base neuve. Son garde le dit :
-- « sur une base neuve la campagne n'a jamais tourne et il n'y a rien a poser ».
-- Elle reussissait donc EN NE FAISANT RIEN. Ce n'etait pas un bug : c'etait une
-- migration qui SUPPOSE un etat qu'elle ne cree pas.
--
-- 🛑 CE TRAVAIL EST DU REFERENTIEL, PAS DE LA DONNEE D'EXPLOITATION -- au meme
-- titre que les 16 unites officielles de V115, qui sont bien en migration, elles.
-- Une relecture humaine ne se refait pas.
--
-- GENEREE par `scripts/pre-tagging/generer-migrations-tags.sh`, versionne comme
-- seule trace de la methode. Ne pas editer ce fichier a la main : regenerer.
-- Arbitrage complet, pieges de portabilite et verifications : DETTE-T1 dans
-- `docs/decisions/plan-parcours-tcf.md`.
--
-- ⚠️ TROIS EXCLUSIONS / SUBSTITUTIONS, mesurees avant d'ecrire (DETTE-T1) :
--   1. jointure sur `civic_notions.code`, JAMAIS sur son UUID : il est en
--      `gen_random_uuid()` (V051) et differe d'une base a l'autre. Les
--      `questions.id`, eux, sont explicites en migration donc stables ;
--   2. les 8 questions de `db/migration-dev/V900__seed_dev.sql` (ids
--      `c000000X-...`) sont EXCLUES : donnees de developpement, absentes de la
--      production, une migration qui les cite serait silencieusement partielle ;
--   3. `reviewed_by` est emis a NULL : il pointait un compte du seed dev.
--      QUI a relu est une donnee de la MACHINE ; QUE ce soit relu, et par quelle
--      AUTORITE (`review_source`), est une donnee du REFERENTIEL.
--
-- ⚠️ `reviewed_at` est CONSERVE alors que `reviewed_by` part a NULL :
-- `chk_question_notion_review_date` n'exige que la coherence avec le verdict,
-- et QUAND une relecture a eu lieu est une donnee du referentiel.
--
-- 🛑 `ON CONFLICT DO NOTHING` sur `uq_question_notion_suggestion`
-- (question_id, batch_id, notion_id) : rejouable, et une campagne ulterieure
-- n'est jamais ecrasee.
--
-- 🛑 VERIFIEE SUR BASE NEUVE avant depot : 0 -> 971 lignes.
-- ============================================================================

INSERT INTO question_notion_suggestions
  (id, question_id, notion_id, confidence, model, created_at, prompt_version,
   rationale, review_verdict, reviewed_by, reviewed_at, batch_id, source_theme_code, review_source)
VALUES
ENTETE

Q "SELECT string_agg(
       format('  (%L, %L, %s, %s, %L, %L, %L, %s, %s, NULL, %s, %L, %L, %s)',
              s.id, s.question_id,
              CASE WHEN n.code IS NULL THEN 'NULL'
                   ELSE format('(SELECT id FROM civic_notions WHERE code = %L)', n.code) END,
              s.confidence, s.model, s.created_at, s.prompt_version,
              CASE WHEN s.rationale IS NULL THEN 'NULL' ELSE quote_literal(s.rationale) END,
              CASE WHEN s.review_verdict IS NULL THEN 'NULL' ELSE quote_literal(s.review_verdict) END,
              CASE WHEN s.reviewed_at IS NULL THEN 'NULL' ELSE quote_literal(s.reviewed_at::text) END,
              s.batch_id, s.source_theme_code,
              CASE WHEN s.review_source IS NULL THEN 'NULL' ELSE quote_literal(s.review_source) END),
       E',\n' ORDER BY s.batch_id, s.question_id, s.id)
   FROM question_notion_suggestions s LEFT JOIN civic_notions n ON n.id = s.notion_id
   WHERE s.question_id::text NOT LIKE 'c000000%'"
echo "ON CONFLICT ON CONSTRAINT uq_question_notion_suggestion DO NOTHING;"

cat <<ENTETE

-- 🛑 LE GARDE FINAL. Une tracabilite partielle est une tracabilite fausse.
DO \$\$
DECLARE presentes integer;
BEGIN
    SELECT count(*) INTO presentes FROM question_notion_suggestions;
    IF presentes < $SUGG THEN
        RAISE EXCEPTION
            'Suggestions civiques : % lignes en base, $SUGG attendues au minimum. '
            'Une notion citee par code est peut-etre absente du referentiel.', presentes;
    END IF;
    RAISE NOTICE 'Suggestions civiques : % lignes en base.', presentes;
END \$\$;
ENTETE
} > "$OUT/V296__suggestions_campagne_civique.sql"

echo "→ $OUT/tags_campagne.sql          ($(wc -l < "$OUT/V297__tags_campagne_civique.sql") lignes)" >&2
echo "→ $OUT/suggestions_campagne.sql   ($(wc -l < "$OUT/V296__suggestions_campagne_civique.sql") lignes)" >&2
