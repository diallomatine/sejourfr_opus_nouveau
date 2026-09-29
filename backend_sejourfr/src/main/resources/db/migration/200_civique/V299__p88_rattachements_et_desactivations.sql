-- ============================================================================
-- V299 — Civique : ce que la relecture editoriale de P8.8 a tranche
-- ----------------------------------------------------------------------------
-- Six rattachements a une notion interne, quatre desactivations.
--
-- 🛑 DESACTIVER, JAMAIS SUPPRIMER. Ces lignes sont referencees par des
--    `attempt_questions` et des `answers` : un DELETE casserait l'historique
--    d'un candidat qui y a deja repondu.
--
-- 🛑 LES DEUX DRAPEAUX, pas un seul. `is_active` et `status` existent tous les
--    deux et ne sont PAS lus par les memes requetes :
--      * `QuestionRepository.findOrdered` (les series par theme) ne filtre que
--        `active` ;
--      * le tirage conforme d'examen et les series sur unite filtrent LES DEUX.
--    N'en poser qu'un laisserait une question desactivee visible dans la
--    moitie des chemins. Asymetrie qui ne se voit qu'en lisant les deux
--    requetes cote a cote.
--
-- ⚠️ `V299` EST LE DERNIER SLOT DE LA PLAGE `200_civique` (V200-V299). La
--    prochaine migration civique TRANSVERSE n'aura plus de numero : voir
--    DETTE-F1 (`docs/decisions/plan-parcours-tcf.md`), qui pose les trois
--    options AVANT qu'on ait a choisir sous contrainte.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Les six rattachements qui redescendent PROPREMENT jusqu'a une notion
-- ----------------------------------------------------------------------------
-- 🛑 Huit autres questions ne sont PAS rattachees, et c'est un arbitrage, pas
--    un oubli (option 3, 2026-09-20) : leur unite officielle est evidente mais
--    AUCUNE des notions qu'elle contient ne couvre leur sujet. Forcer la notion
--    la moins fausse a ete ecarte -- le plan derive travaille au grain de la
--    NOTION, donc une question de logement rangee dans « Se deplacer » ferait
--    dire au plan de travailler les transports. Un mauvais tag ment davantage
--    qu'une absence de tag. Liste et motif : SIGNAL-T1.
--
-- 🛑 `theme_id` N'EST PAS MODIFIE. Le premier rattachement est cross-theme : la
--    question est rangee en CIV_PRINCIPES et rejoint une unite de
--    CIV_DROITS_DEVOIRS. C'est D-47 -- le PROGRAMME prime sur `theme_id` la ou
--    l'on compose, `theme_id` reste l'axe du CORPUS, et les deux faits
--    coexistent sans se contredire.
--
-- 🛑 Par CODE de notion, jamais par uuid : un `WHERE code = …` qui ne trouve
--    rien ecrit zero ligne, et le garde de fin de fichier le voit.

UPDATE questions SET
    civic_notion_id = (SELECT id FROM civic_notions WHERE code = 'pv_egalite_non_discrimination'),
    updated_at = now()
 WHERE id = 'f0000001-0000-0000-0000-000000000124';   -- autorite saisie en cas de discrimination

UPDATE questions SET
    civic_notion_id = (SELECT id FROM civic_notions WHERE code = 'inst_gouvernement'),
    updated_at = now()
 WHERE id IN (
    'f3000002-0000-0000-0000-0000000000b5',            -- definition du service public
    'f3000002-0000-0000-0000-0000000000b6',            -- principes du service public
    'f2000002-0000-0000-0000-000000000090',            -- transparence de la vie publique (HATVP)
    'f5000002-0000-0000-0000-00000000001e'             -- ce que designe l'INSEE
 );

UPDATE questions SET
    civic_notion_id = (SELECT id FROM civic_notions WHERE code = 'pv_republique_democratie'),
    updated_at = now()
 WHERE id = 'f3000001-0000-0000-0000-000000000015';   -- droits qu'ouvre la citoyennete

-- ----------------------------------------------------------------------------
-- 2. Les trois hors programme, et le doublon
-- ----------------------------------------------------------------------------
-- Les trois premieres n'ont aucun rattachement honnete : l'annexe I couvre
-- l'histoire DE FRANCE et ne cite ni les traites de Westphalie ni la COP21.
--
-- 🛑 La troisieme est une ERREUR DE CONTENU, pas seulement un hors-programme :
--    sa « bonne reponse » affirme un age legal d'entree en discotheque qui
--    n'existe pas en droit francais (seule la vente d'alcool aux mineurs est
--    interdite). Elle serait a desactiver meme si elle etait au programme.
--
-- La quatrieme est un quasi-doublon : « Que signifie la laicite ? » et
-- « Qu'est-ce que la laicite ? » portent les MEMES quatre options, reformulees,
-- et la meme bonne reponse. Une serie de 10 questions pouvait servir les deux.
--
-- 🛑 ET CE DOUBLON N'EXISTE QUE SUR UNE BASE DE DEV. Trouve en ecrivant le
--    garde, pas en relisant : `c0000001-…0002` est inseree par
--    `migration-dev/V900__seed_dev.sql`, jamais par une migration de
--    production. Les huit AUTRES questions de Laicite viennent bien de V062,
--    V296 et V297.
--    Consequences, toutes verifiees :
--      * en PRODUCTION, Laicite compte 8 questions, pas 9 -- 8 + 12 = 20,
--        le seuil est atteint SANS cette desactivation ;
--      * sur une base de DEV deja seedee, la ligne existe et cet UPDATE
--        l'eteint : 9 + 12 - 1 = 20 ;
--      * sur une base de DEV NEUVE, V900 (900 > 299) s'execute APRES et la
--        reinsere active : le dev verra 21 questions et le doublon. C'est
--        assume -- ⛔ on ne touche pas a V900, dont le checksum est deja pose
--        sur toutes les bases existantes.
--    L'UPDATE est donc un no-op en production, et c'est voulu : il ne coute
--    rien et refermera le cas le jour ou la ligne serait promue.

UPDATE questions SET
    is_active = false,
    status = 'ARCHIVED',
    updated_at = now()
 WHERE id IN (
    'f4000002-0000-0000-0000-00000000005d',            -- traites de Westphalie (1648)
    'f4000002-0000-0000-0000-0000000000d7',            -- COP21, accord de Paris
    'f5000002-0000-0000-0000-00000000001c',            -- age en boite de nuit : REGLE INEXISTANTE
    'c0000001-0000-0000-0000-000000000002'             -- doublon de f0000001-…001e (laicite)
 );

-- ============================================================================
-- LE GARDE — la migration ECHOUE plutot que de laisser un etat a moitie ecrit.
-- ============================================================================
DO $$
DECLARE
    rattachees int;
    desactivees int;
    doublon_vivant int;
    laicite int;
    sans_notion int;
BEGIN
    SELECT count(*) INTO rattachees FROM questions
     WHERE id IN ('f0000001-0000-0000-0000-000000000124',
                  'f3000002-0000-0000-0000-0000000000b5',
                  'f3000002-0000-0000-0000-0000000000b6',
                  'f2000002-0000-0000-0000-000000000090',
                  'f5000002-0000-0000-0000-00000000001e',
                  'f3000001-0000-0000-0000-000000000015')
       AND civic_notion_id IS NOT NULL;
    IF rattachees <> 6 THEN
        RAISE EXCEPTION 'V299 : % question(s) rattachee(s) au lieu de 6', rattachees;
    END IF;

    -- 🛑 TROIS, et non quatre : le doublon de Laicite n'existe que sur une base
    --    de dev (cf. le bloc 2). Exiger 4 ferait echouer la migration en
    --    production sur une ligne qui n'y a jamais existe.
    SELECT count(*) INTO desactivees FROM questions
     WHERE id IN ('f4000002-0000-0000-0000-00000000005d',
                  'f4000002-0000-0000-0000-0000000000d7',
                  'f5000002-0000-0000-0000-00000000001c')
       AND is_active = false AND status = 'ARCHIVED';
    IF desactivees <> 3 THEN
        RAISE EXCEPTION 'V299 : % desactivation(s) hors programme au lieu de 3',
            desactivees;
    END IF;

    -- Le doublon, LA OU IL EXISTE : s'il est present, il doit etre eteint.
    SELECT count(*) INTO doublon_vivant FROM questions
     WHERE id = 'c0000001-0000-0000-0000-000000000002'
       AND (is_active OR status <> 'ARCHIVED');
    IF doublon_vivant > 0 THEN
        RAISE EXCEPTION 'V299 : le doublon de Laicite est encore actif';
    END IF;

    -- 🛑 LE SEUIL DE R2 : l'unite « Laicite » doit sortir de cette passe a 20
    --    questions actives. C'est la RAISON d'etre de P8.8 -- la verifier ici
    --    vaut mieux que la constater a l'ecran.
    SELECT count(*) INTO laicite
      FROM questions q
      JOIN civic_notions n ON n.id = q.civic_notion_id
      JOIN civic_official_units u ON u.id = n.official_unit_id
     WHERE u.code = 'P2_LAICITE' AND q.is_active AND q.status = 'ACTIVE';
    IF laicite <> 20 THEN
        RAISE EXCEPTION 'V299 : unite Laicite a % question(s) active(s) au lieu de 20', laicite;
    END IF;

    -- Les huit qui attendent une notion qui n'existe pas encore (SIGNAL-T1).
    SELECT count(*) INTO sans_notion FROM questions
     WHERE module = 'CIVIQUE' AND question_type = 'CONNAISSANCE'
       AND is_active AND status = 'ACTIVE' AND civic_notion_id IS NULL;
    IF sans_notion <> 8 THEN
        RAISE EXCEPTION
            'V299 : % connaissance(s) sans notion au lieu de 8 -- le corpus a bouge depuis la relecture',
            sans_notion;
    END IF;
END $$;
