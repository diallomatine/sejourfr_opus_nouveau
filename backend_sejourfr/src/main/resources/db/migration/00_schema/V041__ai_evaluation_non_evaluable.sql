-- ---------------------------------------------------------------------------
-- V041 — Le TROU JUMEAU de V040, sur la voie STANDARD cette fois.
--
-- LE DEFAUT. `AiEvaluationService.persistProductionInvalide` ecrit une ligne
-- `ai_evaluations` portant note 0 + `A1_NON_ATTEINT` quand les controles
-- deterministes ont juge la production inexploitable (vide, quasi vide, langue
-- non francaise, recopiage de la consigne) -- AUCUN appel LLM n'a eu lieu,
-- personne n'a rien observe, et pourtant la ligne affirme un niveau. C'est la
-- meme confusion que V040 vient de corriger cote diagnostic : une ABSENCE DE
-- PREUVE enregistree comme la PREUVE DU NIVEAU LE PLUS FAIBLE.
--
-- Le rayon d'impact est plus large ici. `ai_evaluations` est la table que
-- `TcfProfileService` lit EN PRIORITE (le diagnostic n'en est que le repli) pour
-- etablir le niveau EE/EO d'un candidat, et le niveau global est le PLANCHER des
-- quatre domaines : une seule production ratee tirait tout le profil au fond.
--
-- CE QUI N'EST PAS TOUCHE, ET C'EST DELIBERE. Une epreuve d'examen OUVERTE PUIS
-- ABANDONNEE (chrono ecoule, rien rendu) continue de compter `A1_NON_ATTEINT` :
-- elle a ete PASSEE et ratee. Ce cas-la ne passe pas par cette table -- il n'y a
-- justement aucune ligne -- et se decide dans
-- `ProductionBilanService.bilanEpreuveTerminee` (« le reste note 0 »), qui ne
-- bouge pas d'une ligne. Les deux situations sont separables parce qu'elles ne
-- partagent aucun code : celle-ci est une LIGNE QUI EXISTE ET NE DIT RIEN,
-- celle-la une LIGNE QUI N'EXISTE PAS.
--
-- CE QUE FAIT CETTE MIGRATION. Une seule colonne, meme patron que V040 :
-- `evaluabilite` dit POURQUOI il n'y a ni note ni niveau, comme un FAIT.
-- L'absence de ligne signifie « pas encore evaluee » ; une ligne NON_EVALUABLE
-- signifie « rendue, mais rien a observer ». Ces deux etats ne se disent pas
-- pareil au candidat, et un front ne doit pas avoir a les distinguer en testant
-- la nullite de deux colonnes.
--
-- POURQUOI LA CONTRAINTE NE VA QUE DANS UN SENS. « NON_EVALUABLE => aucun
-- verdict » est un invariant que nous ecrivons : il est opposable. La reciproque
-- (« EVALUABLE => note et niveau non nuls ») ne l'est pas : `note_sur_20` et
-- `niveau_cecrl` sont nullables depuis V011 et une evaluation peut legitimement
-- sortir sans niveau situable. V040 pouvait exiger les deux sens parce que ses
-- trois colonnes etaient NOT NULL a l'origine ; ici, l'exiger inventerait un
-- invariant que le code n'a jamais tenu.
--
-- AUCUNE DONNEE N'EST MIGREE. Les 4 lignes deja en base (`modele_utilise =
-- 'validation-serveur'`) gardent leur note 0 et leur `A1_NON_ATTEINT` : les
-- recalculer serait reecrire l'historique. Le DEFAULT 'EVALUABLE' ne fait que
-- donner aux lignes existantes le sens qu'elles avaient deja -- elles portent
-- toutes un niveau. Leur rattrapage est un arbitrage du proprietaire, pas une
-- consequence technique de ce correctif.
-- ---------------------------------------------------------------------------

ALTER TABLE ai_evaluations
    ADD COLUMN evaluabilite varchar(16) NOT NULL DEFAULT 'EVALUABLE';

ALTER TABLE ai_evaluations
    ADD CONSTRAINT chk_ai_eval_evaluabilite
        CHECK (evaluabilite IN ('EVALUABLE', 'NON_EVALUABLE'));

ALTER TABLE ai_evaluations
    ADD CONSTRAINT chk_ai_eval_aucun_verdict_si_non_evaluable
        CHECK (
            evaluabilite <> 'NON_EVALUABLE'
                OR (note_sur_20 IS NULL
                    AND niveau_cecrl IS NULL
                    AND niveau_cecrl_ia IS NULL)
        );

COMMENT ON COLUMN ai_evaluations.evaluabilite IS
    'EVALUABLE | NON_EVALUABLE. NON_EVALUABLE = production rendue mais sans matiere observable (vide/quasi vide, langue non francaise, recopiage de la consigne) : AUCUN appel au correcteur n''a ete emis, note_sur_20 et niveau_cecrl sont NULL. A ne pas confondre avec l''absence de ligne, qui signifie « pas encore evaluee », ni avec l''absence de LIGNES sur une epreuve d''examen abandonnee, qui reste comptee A1_NON_ATTEINT par le bilan.';
COMMENT ON COLUMN ai_evaluations.niveau_cecrl IS
    'Niveau CECRL calcule serveur (lexique + morphosyntaxe, seuils config). Valeur affichee a l''utilisateur. NULL quand evaluabilite = NON_EVALUABLE : null = inconnu, jamais mauvais -- TcfProfileService ecarte deja ces lignes.';
