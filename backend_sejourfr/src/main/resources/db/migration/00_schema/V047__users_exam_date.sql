-- ============================================================================
-- V047 — LA DATE D'EXAMEN DU CANDIDAT.
-- ----------------------------------------------------------------------------
-- Lot L1 de la refonte. Spec : docs/review_all/50_SEJOURFR_CORRECTIFS.md §7
-- (correctif T01) ; constat mesure : 40_SEJOURFR_AUDIT.md, blocage B11.
--
-- POURQUOI UNE COLONNE POUR UNE SEULE DATE.
-- Trois surfaces la reclament et n'ont aujourd'hui rien a lire :
--   * T01 (« Avez-vous une date d'examen ? »), la troisieme question du tunnel ;
--   * le paywall, dont 50_ §3.4 fait le principal levier des pass a duree
--     bornee — « votre examen est le 18 octobre, le pass 2 mois couvre toute
--     votre preparation » ne peut pas s'ecrire sans elle ;
--   * l'accueil agrege (30_ §9), « TCF le 18 octobre — dans 39 jours ».
--
-- 🛑 `date`, PAS `timestamptz`.
-- Une convocation d'examen porte un jour, pas un instant. Stocker un
-- timestamptz obligerait a inventer une heure et un fuseau, puis a les
-- reafficher : un candidat a Mayotte verrait sa date reculer d'un jour. Le
-- decompte « dans 39 jours » se calcule cote serveur, a la lecture, contre la
-- date du jour — jamais persiste (invariant : derive serveur, jamais stocke).
--
-- 🛑 NULLABLE, ET SANS DEFAUT.
-- « Pas encore de date » est la reponse la plus frequente et une reponse
-- PLEINE : la question est facultative et ne bloque jamais le tunnel (30_
-- §4.1). NULL = le candidat n'a pas de date, jamais « on ne lui a pas demande »
-- et jamais une date plausible inventee pour remplir l'ecran.
--
-- Aucune contrainte de coherence avec le passe : une date depassee est une
-- information vraie (l'examen a eu lieu), et le serveur decide a la lecture de
-- ce qu'il en affiche. Une contrainte CHECK ici empecherait un candidat de
-- corriger une saisie, et vieillirait toute seule.
-- ============================================================================

ALTER TABLE users
    ADD COLUMN exam_date date;

COMMENT ON COLUMN users.exam_date IS
    'Jour de l''examen vise, declare par le candidat. NULL = pas de date '
    '(reponse pleine et frequente), jamais une date inventee.';
