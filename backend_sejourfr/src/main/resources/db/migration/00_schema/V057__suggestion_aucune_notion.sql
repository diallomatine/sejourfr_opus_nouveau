-- ============================================================================
-- V057 — « AUCUNE NOTION NE CONVIENT » DEVIENT UNE LIGNE, PARCE QUE C'EST LE
--        SIGNAL QUI RÉVÈLE LES TROUS DU RÉFÉRENTIEL.
-- ----------------------------------------------------------------------------
-- Le pré-tagging peut conclure qu'AUCUNE notion du référentiel ne convient :
-- `PROMPT_TAG_NOTION_v3` porte la valeur « AUCUNE » en première classe dans son
-- enum de sortie, et sa règle 4 la rend explicite (« ne force jamais un
-- rattachement pour éviter de dire non »). Jusqu'ici cette réponse était PERDUE :
-- `notion_id` était NOT NULL, donc l'import n'écrivait aucune ligne et la
-- question disparaissait des métriques.
--
-- 🛑 CE VERDICT EST L'INFORMATION LA PLUS UTILE DU CHANTIER.
-- Cas réel du pilote du 2026-09-11 : « Quel roi a établi l'édit de Nantes
-- (1598) pour la liberté de culte protestant ? » — réponse « AUCUNE »,
-- confiance 0,60, justification « avant la Révolution et hors thème laïcité
-- 1905, ne colle à aucune notion du référentiel ». Le lot a produit 49 lignes
-- pour 50 entrées, et personne n'aurait vu la 50ᵉ. C'est pourtant exactement
-- ce que la porte de revue de `50_` §6.1.3 attend : le tagging dit quelles
-- notions MANQUENT, et il ne peut le dire que si on l'écoute quand il dit non.
--
-- 🛑 AUCUNE NOTION TECHNIQUE « AUCUNE » N'EST CRÉÉE DANS `civic_notions`.
-- Décision explicite du propriétaire. Le référentiel ne contient que de vraies
-- notions pédagogiques : une notion fantôme se retrouverait dans le <select> de
-- l'écran d'administration, dans la couverture par mention, dans les séries
-- ciblées, et finirait taguée sur une question. L'absence de rattachement
-- s'écrit avec l'absence de valeur — `notion_id IS NULL` — pas avec une
-- sentinelle.
--
-- 🛑 POURQUOI `UNIQUE NULLS NOT DISTINCT`, ET PAS LA CONTRAINTE D'ORIGINE.
-- Par défaut, Postgres considère deux NULL comme DISTINCTS : `uq_question_
-- notion_suggestion (question_id, notion_id)` n'aurait donc plus rien empêché,
-- et dix lignes « aucune notion » auraient pu s'empiler sur la même question à
-- chaque rejeu de lot. Le compteur de trous du référentiel — le seul chiffre
-- pour lequel ce lot existe — serait devenu faux, et faux DANS LE SENS QUI
-- ALARME (un trou compté dix fois). La base tourne en Postgres 16 ; `NULLS NOT
-- DISTINCT` (15+) rend l'unicité vraie pour les deux formes de ligne.
--
-- ⚠️ AUCUNE CONTRAINTE D'EXCLUSION « aucune notion » ⇄ « notion X » N'EST POSÉE,
-- et c'est délibéré. Elle paraît évidente — le modèle ne peut pas dire « c'est X »
-- et « ce n'est rien » à la fois — mais elle est FAUSSE sur le contrat réel du
-- job : le tool-schema de `tagger-lot.sh` accepte « AUCUNE » aussi bien en
-- `notion` qu'en `alternative`, et sa règle 8 demande explicitement une
-- alternative quand deux réponses se défendent. « Probablement `hg_patrimoine`
-- (0,62), sinon rien » est une hésitation HONNÊTE, et c'est précisément le
-- matériau de la porte de revue : l'interdire pousserait le modèle — ou
-- l'import — à taire l'une des deux moitiés. La cohérence se juge donc sur la
-- MEILLEURE suggestion, côté serveur, à la lecture ; pas par un verrou qui
-- amputerait la mesure. (Techniquement, l'interdire demanderait en plus un
-- trigger ou une contrainte d'exclusion sur cette table, ce que V054 s'est
-- explicitement interdit.)
-- ============================================================================

ALTER TABLE question_notion_suggestions
    ALTER COLUMN notion_id DROP NOT NULL;

-- L'unicité doit tenir SUR LES DEUX FORMES de ligne : une notion au plus par
-- question, et « aucune notion » au plus UNE FOIS par question.
ALTER TABLE question_notion_suggestions
    DROP CONSTRAINT uq_question_notion_suggestion;

ALTER TABLE question_notion_suggestions
    ADD CONSTRAINT uq_question_notion_suggestion
        UNIQUE NULLS NOT DISTINCT (question_id, notion_id);

COMMENT ON COLUMN question_notion_suggestions.notion_id IS
    'La notion PROPOSEE. NULL = LE MODELE A CONCLU QU''AUCUNE NOTION DU '
    'REFERENTIEL NE CONVIENT. Ce n''est ni une erreur ni une absence de '
    'suggestion : c''est un VERDICT, et c''est le signal qui fait decouvrir '
    'les notions manquantes a la porte de revue (50_ §6.1.3). A ne pas '
    'confondre avec l''ABSENCE DE LIGNE, qui dit « cette question n''a pas ete '
    'pre-taguee ». 🛑 Aucune notion technique « AUCUNE » n''existe dans '
    'civic_notions : le referentiel ne contient que de vraies notions '
    'pedagogiques. Unicite en NULLS NOT DISTINCT : une seule ligne « aucune '
    'notion » par question, sinon un trou du referentiel se compterait dix '
    'fois.';

COMMENT ON CONSTRAINT uq_question_notion_suggestion ON question_notion_suggestions IS
    'NULLS NOT DISTINCT (PG 15+) : sans cela deux lignes « aucune notion » sur '
    'la meme question seraient considerees distinctes, et un rejeu de lot '
    'gonflerait le compteur de trous du referentiel.';
