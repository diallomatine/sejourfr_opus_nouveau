#!/usr/bin/env bash
#
# seed-plan-demo.sh — DEV ONLY. Fabrique le compte de démonstration du Plan pour
# montrer la séquence « 5 micro-sujets → vérification → recalcul » (2026-09-13).
#
# 🛑 CE SCRIPT ÉCRIT DE FAUSSES DONNÉES. Il est *interdit* ailleurs que sur la
#    base locale de développement, et il refuse de s'exécuter s'il n'en est pas
#    certain (cf. « GARDE-FOUS » plus bas). Ne jamais le pointer vers une base
#    partagée, de recette ou de production.
#
# Tout ce qu'il écrit pend sous UN SEUL compte synthétique
# (plan.demo@sejourfr.fr) dont toutes les tables dépendantes sont en
# ON DELETE CASCADE : `--state rollback` supprime ce compte, et il ne reste
# rien. Aucune ligne d'aucun autre compte n'est lue en écriture, modifiée ni
# supprimée.
#
# 🛑 AUCUN APPEL LLM. Les observations et les verdicts sont écrits directement
#    en base : le correcteur n'est jamais sollicité, donc aucun fournisseur
#    payant n'est appelé.
#
# Usage :
#   scripts/seed-plan-demo.sh --state 0          # étape à 0/5
#   scripts/seed-plan-demo.sh --state 3          # 3/5 — la carte dit « Continuer »
#   scripts/seed-plan-demo.sh --state 5          # 5/5 — « Série terminée · À vérifier »
#   scripts/seed-plan-demo.sh --state verified   # vérification rendue, PAS solide
#   scripts/seed-plan-demo.sh --state solid      # vérification réussie → « Acquis »
#   scripts/seed-plan-demo.sh --state mesure     # 5/5 + une production orale INEXPLOITABLE
#                                                #   → la séance ouvre sur une mesure (A_EVALUER)
#   scripts/seed-plan-demo.sh --state rollback   # supprime tout
#
# Chaque état repart d'une table rase (il efface d'abord ce que le script avait
# posé) : il est donc **idempotent** et les états s'enchaînent dans n'importe
# quel ordre.
#
# Compte créé : plan.demo@sejourfr.fr / User123!  (même hash que le compte seed
# `user@sejourfr.fr` du profil dev).
set -euo pipefail

DB="${SEJOURFR_DB:-sejourfr_db}"
DBUSER="${SEJOURFR_DB_USER:-$(whoami)}"
STATE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --state) STATE="${2:-}"; shift 2 ;;
    -h|--help) sed -n '1,40p' "$0"; exit 0 ;;
    *) echo "Option inconnue : $1" >&2; exit 2 ;;
  esac
done

case "$STATE" in
  0|3|5|verified|solid|mesure|rollback) ;;
  *) echo "--state manquant ou invalide (0|3|5|verified|solid|mesure|rollback)" >&2; exit 2 ;;
esac

psqlq() { psql -d "$DB" -U "$DBUSER" -v ON_ERROR_STOP=1 -tAc "$1"; }

# ---------------------------------------------------------------- GARDE-FOUS
# Quatre conditions, toutes nécessaires. Aucune n'est un commentaire : le script
# s'arrête si l'une manque.
#
# 1. Le consentement explicite de l'opérateur.
if [[ "${SEJOURFR_SEED_DEV:-}" != "1" ]]; then
  cat >&2 <<'MSG'
REFUS : ce script fabrique de fausses données et n'est autorisé qu'en local/dev.
Relancez-le avec SEJOURFR_SEED_DEV=1 si et seulement si la base visée est votre
base de développement locale.
MSG
  exit 1
fi

# 2. Le nom de base du profil dev, et lui seul (cf. CLAUDE.md, application-dev.yaml).
if [[ "$DB" != "sejourfr_db" ]]; then
  echo "REFUS : base « $DB » — seul « sejourfr_db » (profil dev local) est autorisé." >&2
  exit 1
fi

# 3. Le serveur doit être LOCAL. `inet_server_addr()` est vide sur une connexion
#    par socket Unix, et vaut la loopback sur une connexion TCP locale ; tout le
#    reste est une base distante.
SERVER_ADDR="$(psqlq "select coalesce(host(inet_server_addr()), 'local-socket');")"
case "$SERVER_ADDR" in
  local-socket|127.0.0.1|::1) ;;
  *) echo "REFUS : serveur PostgreSQL distant ($SERVER_ADDR). Base locale uniquement." >&2; exit 1 ;;
esac

# 4. La base doit porter les comptes seed du profil dev. Une base de production
#    n'en a aucun : c'est notre signature de « ceci est bien un poste de dev ».
SEEDS="$(psqlq "select count(*) from users where email in ('admin@sejourfr.fr','user@sejourfr.fr');")"
if [[ "$SEEDS" != "2" ]]; then
  echo "REFUS : les comptes seed du profil dev sont absents — cette base n'est pas une base de développement." >&2
  exit 1
fi

echo "✓ garde-fous : base=$DB serveur=$SERVER_ADDR comptes-seed=ok"

# ------------------------------------------------------------------ rollback
if [[ "$STATE" == "rollback" ]]; then
  psqlq "delete from users where email = 'plan.demo@sejourfr.fr';" >/dev/null
  echo "✓ rollback : le compte de démonstration et TOUTES ses lignes sont supprimés."
  exit 0
fi

# -------------------------------------------------------------------- states
psql -d "$DB" -U "$DBUSER" -v ON_ERROR_STOP=1 -v state="$STATE" -q -f - <<'SQL'
\set ON_ERROR_STOP on
begin;

-- Table rase : on repart du compte vide à chaque exécution. C'est ce qui rend
-- le script idempotent et les états interchangeables.
delete from users where email = 'plan.demo@sejourfr.fr';

-- Identifiants DÉTERMINISTES : rejouer le script rend exactement les mêmes
-- lignes, et le rollback sait quoi supprimer sans fichier d'état.
create temporary table seed_ctx on commit drop as
with base as (
  select
    md5('sejourfr:seed-plan-demo:user')::uuid          as user_id,
    md5('sejourfr:seed-plan-demo:attempt')::uuid       as attempt_id,
    md5('sejourfr:seed-plan-demo:diag')::uuid          as session_id,
    md5('sejourfr:seed-plan-demo:sub')::uuid           as sub_id,
    :'state'                                           as state,
    now()                                              as t
)
select b.*,
       s.id  as skill_id,
       s.code as skill_code,
       nxt.id as next_skill_id,
       (select id from production_tasks
         where diagnostic_code is not null and is_active and epreuve = 'TCF_EE'
         order by diagnostic_version desc, id limit 1) as diag_task_id,
       (select password_hash from users where email = 'user@sejourfr.fr') as pwd
from base b
join skills s   on s.code = 'EE3-C3'      -- « Développer un argument », tâche 3
join skills nxt on nxt.code = 'EE3-C5'    -- la priorité suivante, jamais touchée
;

-- Le compte. Synthétique de bout en bout, mot de passe = celui du seed dev.
insert into users (id, email, password_hash, first_name, last_name,
                   target_procedure, target_level, role, is_active, created_at, auth_provider)
select user_id, 'plan.demo@sejourfr.fr', pwd, 'Démo', 'Plan',
       'NAT', 'B2', 'USER', true, t - interval '10 days', 'LOCAL'
from seed_ctx;

-- Un abonnement actif : l'étape entière (5 sujets) et la vérification sont
-- PREMIUM, un compte gratuit plafonne à 2/5 et ne basculerait jamais.
insert into user_subscriptions (id, user_id, plan_id, status, starts_at, ends_at,
                                source, original_transaction_id, product_id, auto_renew)
select sub_id, user_id, '33333333-0000-0000-0000-000000000034', 'ACTIVE',
       t - interval '10 days', t + interval '300 days',
       'STRIPE', 'seed_plan_demo', 'INTEGRAL_PASS_1Y', false
from seed_ctx;

-- Le diagnostic rapide CLOS : c'est lui qui rend le Plan ACTIVE
-- (PlanFoundationResolver). L'attempt est une coquille, aucune question dedans.
insert into attempts (id, user_id, mode, status, epreuve, started_at, finished_at, production_locked)
select attempt_id, user_id, 'PRODUCTION', 'COMPLETED', 'TCF_EE',
       t - interval '9 days', t - interval '9 days', false
from seed_ctx;

-- `summary_json` est NOT NULL sur une session close (contrainte
-- chk_diagnostic_session_completed) : on pose le strict minimum, sans aucune
-- phrase inventée sur le candidat.
insert into diagnostic_sessions (id, user_id, diagnostic_code, diagnostic_version,
                                 written_task_id, written_attempt_id, status,
                                 summary_json, started_at, completed_at)
select session_id, user_id, 'QUICK_TCF', 1, diag_task_id, attempt_id, 'COMPLETED',
       jsonb_build_object(
         'strengths', jsonb_build_array(),
         'priority_skill_codes', jsonb_build_array('EE3-C3'),
         'main_priority_explanation', null),
       t - interval '9 days', t - interval '9 days'
from seed_ctx;

-- ------------------------------------------------------------ observations
-- 1) La BASELINE du diagnostic sur la compétence de démonstration. C'est le
--    constat que la carte affiche, et c'est lui qui la rend actionnable.
insert into learning_plan_observations
  (id, user_id, skill_id, source_type, source_id, observed, status, evidence,
   explanation, confidence, baseline, observed_at, created_at, subject_id)
select md5('sejourfr:seed-plan-demo:obs:baseline')::uuid, user_id, skill_id,
       'DIAGNOSTIC_EE', session_id, true, 'PRIORITY',
       'Parce que cela permet de mieux vivre ensemble.',
       'le bénéfice attendu est mentionné, mais le lien de cause à effet reste peu développé.',
       'HIGH', true, t - interval '9 days', t - interval '9 days', diag_task_id
from seed_ctx;

-- 2) La priorité SUIVANTE, pour montrer que le Plan avance vraiment après la
--    vérification. Moins bien classée : TO_REINFORCE passe après PRIORITY.
insert into learning_plan_observations
  (id, user_id, skill_id, source_type, source_id, observed, status, evidence,
   explanation, confidence, baseline, observed_at, created_at, subject_id)
select md5('sejourfr:seed-plan-demo:obs:next')::uuid, user_id, next_skill_id,
       'DIAGNOSTIC_EE', session_id, true, 'TO_REINFORCE',
       'Les deux paragraphes reprennent la même idée.',
       'le propos tourne sur lui-même : la seconde partie n''ajoute rien à la première.',
       'MEDIUM', true, t - interval '9 days', t - interval '9 days', diag_task_id
from seed_ctx;

-- ------------------------------------------------- les petits sujets traités
-- N sujets de l'ÉTAPE (les 5 premiers actifs par display_order), traités comme
-- le ferait le module Compétences : une tentative EVALUATED + son observation
-- SKILL_TRAINING (critère validé → TO_REINFORCE, sinon PRIORITY).
create temporary table seed_prompts on commit drop as
select sp.id as prompt_id, sp.display_order,
       row_number() over (order by sp.display_order) as rang
from skill_prompts sp, seed_ctx c
where sp.skill_id = c.skill_id and sp.is_active
order by sp.display_order
limit 5;

insert into user_skill_attempts
  (id, user_id, skill_prompt_id, written_production, words_count, statut,
   analysis_requested, criterion_status, created_at, updated_at)
select md5('sejourfr:seed-plan-demo:usa:' || p.prompt_id)::uuid, c.user_id, p.prompt_id,
       '[SEED-PLAN-DEMO] Production de démonstration, écrite par le script de seed.',
       92, 'EVALUATED', true,
       case when p.rang % 3 = 0 then 'PARTIAL' else 'VALIDATED' end,
       c.t - (interval '1 day' * (6 - p.rang)), c.t - (interval '1 day' * (6 - p.rang))
from seed_prompts p, seed_ctx c
where p.rang <= case c.state when '3' then 3 when '0' then 0 else 5 end;

insert into learning_plan_observations
  (id, user_id, skill_id, source_type, source_id, observed, status, evidence,
   explanation, confidence, baseline, observed_at, created_at, subject_id)
select md5('sejourfr:seed-plan-demo:obs:micro:' || p.prompt_id)::uuid,
       c.user_id, c.skill_id, 'SKILL_TRAINING',
       md5('sejourfr:seed-plan-demo:usa:' || p.prompt_id)::uuid, true,
       case when p.rang % 3 = 0 then 'PRIORITY' else 'TO_REINFORCE' end,
       'Petit sujet ciblé n°' || p.rang || '.',
       'le bénéfice attendu est mentionné, mais le lien de cause à effet reste peu développé.',
       'MEDIUM', false,
       c.t - (interval '1 day' * (6 - p.rang)), c.t - (interval '1 day' * (6 - p.rang)),
       p.prompt_id
from seed_prompts p, seed_ctx c
where p.rang <= case c.state when '3' then 3 when '0' then 0 else 5 end;

-- ------------------------------------------------ la production de vérification
-- 🛑 ÉCRITE DIRECTEMENT EN BASE, jamais par le correcteur : aucun appel LLM,
--    aucun coût. C'est le FAIT « une production contextualisée est venue après
--    les petits sujets » qui compte, et c'est ce fait que le moteur lit.
insert into learning_plan_observations
  (id, user_id, skill_id, source_type, source_id, observed, status, evidence,
   explanation, confidence, baseline, observed_at, created_at, subject_id)
select md5('sejourfr:seed-plan-demo:obs:verif:' || g.n)::uuid,
       c.user_id, c.skill_id, 'PRODUCTION_EE',
       md5('sejourfr:seed-plan-demo:verif-src:' || g.n)::uuid, true,
       case c.state when 'solid' then 'SOLID' else 'TO_REINFORCE' end,
       'Vérification en situation n°' || g.n || '.',
       case c.state when 'solid'
            then 'en tâche complète, l''argument est développé et le lien de cause à effet est explicite.'
            else 'en tâche complète, l''argument reste plus court qu''en exercice ciblé.' end,
       'HIGH', false, c.t - interval '1 hour' * g.n, c.t - interval '1 hour' * g.n,
       md5('sejourfr:seed-plan-demo:verif-sujet:' || g.n)::uuid
from seed_ctx c,
     generate_series(1, case c.state when 'solid' then 2 else 1 end) as g(n)
where c.state in ('verified', 'solid');

-- ------------------------------------------------- la MESURE indispensable
-- Une production ORALE rendue dont le correcteur n'a RIEN pu observer : c'est
-- le second sens de NOT_OBSERVED (« la production était inutilisable »), et il
-- ouvre la séance sur une mesure `A_EVALUER` — la seule action du Plan qui ne
-- soit pas un exercice. Elle sert à vérifier que les DEUX fronts savent la
-- lancer depuis la carte « À faire maintenant ».
--
-- 🛑 `observed = false` impose `status = 'NOT_OBSERVED'` ET `evidence IS NULL`
--    (chk_learning_plan_observation_coherence) : on n'invente aucun verdict.
insert into learning_plan_observations
  (id, user_id, skill_id, source_type, source_id, observed, status, evidence,
   explanation, confidence, baseline, observed_at, created_at, subject_id)
select md5('sejourfr:seed-plan-demo:obs:mesure')::uuid, c.user_id, eo.id,
       'PRODUCTION_EO', md5('sejourfr:seed-plan-demo:mesure-src')::uuid,
       false, 'NOT_OBSERVED', null,
       'production orale rendue, mais rien n''a pu y être observé.',
       null, false, c.t - interval '2 hours', c.t - interval '2 hours', null
from seed_ctx c, skills eo
where c.state = 'mesure' and eo.code = 'EO1-C1' and eo.is_active;

commit;
SQL

DONE="$(psqlq "select count(*) from user_skill_attempts a
                 join users u on u.id = a.user_id
                where u.email = 'plan.demo@sejourfr.fr';")"
echo "✓ état « $STATE » posé — compte plan.demo@sejourfr.fr / User123! — ${DONE}/5 petits sujets traités."
echo "  annuler : scripts/seed-plan-demo.sh --state rollback"
