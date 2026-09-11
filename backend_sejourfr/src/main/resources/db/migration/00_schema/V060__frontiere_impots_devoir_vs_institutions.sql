-- ============================================================================
-- V060 — LA FRONTIÈRE DE L'IMPÔT, ÉCRITE POUR NE PLUS SE DISCUTER.
-- ----------------------------------------------------------------------------
-- Le pilote v4 (2026-09-11, 50 questions) a produit UNE SEULE réponse « aucune
-- notion ne convient », et elle portait sur « Tout le monde paie-t-il des
-- impôts en France ? ». Motif rendu par le modèle : « l'organisation de
-- l'impôt relève de CIV_INSTITUTIONS ».
--
-- 🛑 CE N'EST PAS LE MODÈLE QUI A MAL LU, C'EST LA DESCRIPTION QUI ÉTAIT MAL
-- ÉQUILIBRÉE. Elle mentionnait l'obligation de payer dans le « ce qui entre »
-- en trois mots, et consacrait une phrase entière à ce qui n'entre pas. Un
-- lecteur qui cherche une frontière lit d'abord la frontière. Le propriétaire
-- a tranché le 2026-09-11 :
--   * obligation INDIVIDUELLE de payer ses impôts        -> dd_devoirs_citoyen
--   * organisation, collecte, budget, fonctionnement      -> CIV_INSTITUTIONS
--
-- La correction est TEXTUELLE et va dans les deux sens : la règle est écrite
-- ici ET dans « inst_gouvernement », parce qu'une frontière qui n'existe que
-- d'un côté se perd à la première relecture.
--
-- ⚠️ Elle ne rejuge rien. Les 55 suggestions de la campagne v4 gardent leur
-- confiance et leur rationale : elles ont été produites avec le texte
-- précédent, et réécrire l'histoire d'une mesure la rendrait inutilisable.
-- La question concernée est simplement relue par un humain, ce qui était déjà
-- le cas — elle arrivait en tête de file avec une confiance de 0,70.
-- ============================================================================

UPDATE civic_notions SET description =
 $tx$Ce que la République attend de chacun en retour des droits qu'elle garantit : obéir à la loi, contribuer, servir, protéger. ENTRE : respecter la loi et les décisions de justice ; L'OBLIGATION INDIVIDUELLE DE PAYER SES IMPÔTS — y compris « doit-on payer ses impôts ? » et « tout le monde paie-t-il des impôts ? », qui portent sur l'ÉTENDUE de cette obligation et donc sur le devoir lui-même ; dire la vérité comme témoin ; la Journée défense et citoyenneté, l'objection de conscience ; la probité de l'agent public ; le devoir de protéger l'environnement et le tri ; les devoirs constitutionnels ; le devoir de fraternité. 🛑 N'ENTRE PAS : les INTERDITS → « dd_interdits_quotidien » : un devoir est une obligation d'AGIR, pas une abstention. 🛑 L'ORGANISATION, LA COLLECTE, LE BUDGET et le fonctionnement fiscal de l'État — quel impôt finance quoi, qui perçoit, comment le budget se prépare et se contrôle → thème CIV_INSTITUTIONS. LA RÈGLE, ET ELLE TRANCHE SEULE : si la question porte sur CE QUE DOIT LE CITOYEN, c'est ici ; si elle porte sur CE QUE L'ÉTAT FAIT de l'impôt, c'est là-bas. Une question qui demande QUI est redevable, ou S'IL faut payer, est un devoir et reste ici. 🛑 Le droit à un environnement sain RESTE ICI avec son pendant l'obligation, parce que le corpus les énonce toujours ensemble.$tx$
WHERE code = 'dd_devoirs_citoyen';

UPDATE civic_notions SET description = replace(description,
 'L''OBLIGATION DE PAYER ses impôts est un devoir → thème CIV_DROITS_DEVOIRS.',
 'L''OBLIGATION INDIVIDUELLE DE PAYER ses impôts, et toute question sur QUI est redevable, est un devoir → « dd_devoirs_citoyen », thème CIV_DROITS_DEVOIRS. Ici on ne garde que ce que l''État FAIT de l''impôt : le percevoir, le budgéter, le contrôler.')
WHERE code = 'inst_gouvernement';

-- Le remplacement ci-dessus est silencieux s'il ne trouve pas sa chaîne. On
-- vérifie donc que la frontière est bien écrite des DEUX côtés — c'est tout
-- l'objet de cette migration.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM civic_notions
                    WHERE code = 'inst_gouvernement'
                      AND description LIKE '%QUI est redevable%') THEN
        RAISE EXCEPTION
            'V060 : la frontiere de l''impot n''a pas ete ecrite dans inst_gouvernement.';
    END IF;
END $$;
