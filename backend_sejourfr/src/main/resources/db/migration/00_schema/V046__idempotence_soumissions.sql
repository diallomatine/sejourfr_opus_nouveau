-- ============================================================================
-- V046 — IDEMPOTENCE DES SOUMISSIONS PAYANTES : la cle rendue par le client.
-- ----------------------------------------------------------------------------
-- Lot L1 de la refonte. Spec : docs/review_all/50_SEJOURFR_CORRECTIFS.md §8
-- (« Premiere action recommandee, avant tout le reste ») et 00_ §6.5 ;
-- constat mesure : docs/review_all/40_SEJOURFR_AUDIT.md, blocage B5.
--
-- CE QUE CA REPARE, ET COMBIEN CA COUTE AUJOURD'HUI.
-- Les deux surfaces qui declenchent un appel LLM paye — une production EE/EO
-- complete et un petit sujet de competence — n'ont AUCUN moyen de reconnaitre
-- deux fois la meme soumission. Un reseau qui lache apres l'envoi mais avant la
-- reponse, un double-tap sur un bouton, un retry automatique du client HTTP :
-- le serveur voit deux requetes legitimes, insere deux lignes, et paie DEUX
-- corrections. Le candidat, lui, voit deux rapports pour une seule production
-- et son quota gratuit se vide deux fois plus vite.
--
-- Le seul endroit du depot qui etait deja protege, c'est le diagnostic, et il
-- l'est par un index partiel (uq_prod_submission_diagnostic_attempt, V029) :
-- « une seule soumission diagnostique par attempt ». La preuve que le probleme
-- est reel, et que la reponse est un index unique, pas une garde applicative.
--
-- 🛑 NULLABLE, ET CA LE RESTE.
-- Les lignes existantes n'ont pas de cle et ne peuvent pas en recevoir une :
-- personne ne sait quelle UUID le client aurait tiree. Et un client ancien qui
-- n'envoie rien doit continuer de fonctionner — sinon la migration casse
-- l'application deja installee sur les telephones. L'absence de cle signifie
-- donc « ce client ne sait pas encore se repeter sans dommage », jamais
-- « soumission invalide ».
--
-- 🛑 L'UNICITE EST PAR UTILISATEUR, PAS GLOBALE.
-- La spec (10_ §11) ecrit « unicite tcf_production(client_submission_id) ».
-- On ne le fait PAS. Une UUID est tiree par le client : rien n'empeche un
-- appelant de rejouer celle d'un autre. Avec une unicite globale, cette
-- collision ferait echouer la soumission d'un tiers — ou, pire, la ferait
-- resoudre vers la production de quelqu'un d'autre. Bornee a (user_id, cle),
-- une collision entre deux comptes est sans effet, et le rejeu ne peut
-- retrouver que ses propres lignes.
--
-- INDEX PARTIEL : `WHERE ... IS NOT NULL`. Sans lui, Postgres accepterait
-- autant de NULL qu'on veut (deux NULL ne sont pas egaux) mais l'index
-- porterait quand meme toutes les lignes historiques pour rien.
-- ============================================================================

ALTER TABLE production_submissions
    ADD COLUMN client_submission_id uuid;

COMMENT ON COLUMN production_submissions.client_submission_id IS
    'UUID tiree par le client pour rendre la soumission rejouable sans second '
    'appel LLM. NULL = client qui ne la fournit pas encore (jamais une erreur).';

CREATE UNIQUE INDEX uq_prod_submission_client_key
    ON production_submissions (user_id, client_submission_id)
    WHERE client_submission_id IS NOT NULL;

ALTER TABLE user_skill_attempts
    ADD COLUMN client_submission_id uuid;

COMMENT ON COLUMN user_skill_attempts.client_submission_id IS
    'UUID tiree par le client pour rendre la production rejouable sans second '
    'appel LLM. NULL = client qui ne la fournit pas encore (jamais une erreur).';

CREATE UNIQUE INDEX uq_skill_attempt_client_key
    ON user_skill_attempts (user_id, client_submission_id)
    WHERE client_submission_id IS NOT NULL;
