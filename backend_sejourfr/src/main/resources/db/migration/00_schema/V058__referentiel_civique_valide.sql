-- ============================================================================
-- V058 — LE RÉFÉRENTIEL CIVIQUE VALIDÉ : 41 notions → 46.
-- ----------------------------------------------------------------------------
-- V051 posait un « référentiel de TRAVAIL », explicitement « destiné à être
-- ajusté APRÈS le tagging » (50_ §6.1). L'ajustement a eu lieu : les 840
-- questions CONNAISSANCE ont été relues une à une, thème par thème, et le
-- référentiel a été reconstruit à partir du corpus réel plutôt que déduit.
-- Le propriétaire a validé la liste le 2026-09-11.
--
-- 🛑 AUCUN `civic_notion_id` N'EST TOUCHÉ ICI. Cette migration décrit le
-- programme, elle ne tague aucune question. Le tagging reste un geste humain.
--
-- 🛑 AUCUNE NOTION N'EST SUPPRIMÉE. Quatorze sont désactivées ; celles qui ont
-- une destination pointent dessus par `merged_into_id`. Les trois qui se
-- dissolvent sans destination dominante gardent `merged_into_id` NULL et
-- disent pourquoi dans leur description — inventer une destination unique
-- serait une trace fausse.
--
-- 🛑 CE QUE LA `description` DOIT CONTENIR, ET POURQUOI.
-- Trois lecteurs s'en servent : le prompt de pré-tagging, l'écran
-- d'administration et le relecteur humain. Elle porte donc la DÉFINITION, ce
-- qui ENTRE, et surtout ce qui N'ENTRE PAS — en nommant la notion voisine avec
-- laquelle on confond. Le pilote v1 l'a mesuré : une frontière décrite par la
-- FORME de la question (« quand un événement a eu lieu ») fait ranger « l'école
-- gratuite » dans les dates. C'est la SUBSTANCE qui doit trancher.
--
-- 🛑 CE QUE LE CORPUS IMPOSE, ET QUI N'EST PAS NÉGOCIABLE PAR LA TAXONOMIE.
-- CSP, CR et NAT ne sont pas trois niveaux du même programme : ce sont trois
-- programmes différents. Le CR ne contient AUCUNE question sur le gouvernement,
-- le NAT AUCUNE sur l'école ni sur la santé, le CSP AUCUNE sur Napoléon,
-- l'Europe, les écrivains ou la DDHC. Sur ces 46 notions, 12 seulement portent
-- 5 questions dans les trois mentions. Ce n'est pas un défaut de découpage.
-- D'où l'état NON_APPLICABLE, servi par le plan (aucune migration : c'est un
-- dérivé, il se calcule à la lecture) : « zéro question dans cette mention »
-- n'est pas « notion mal faite », c'est « pas pour ce candidat ».
--
-- Chaînes en dollar-quoting : les descriptions sont du français, pleines
-- d'apostrophes. Les doubler à la main est une source d'erreur sans contrepartie.
-- ============================================================================

-- ============================================================================
-- 1. LES NOUVELLES NOTIONS (19)
-- ============================================================================

INSERT INTO civic_notions (code, label, theme_code, display_order, description)
VALUES
-- ---------------------------------------------------------------- HISTOIRE-GÉO
('hg_napoleon_xixe', 'Napoléon et la France au XIXᵉ siècle', 'CIV_HISTOIRE_GEO', 2,
 $tx$De la prise de pouvoir de Bonaparte à la chute du Second Empire : les régimes non républicains du XIXᵉ siècle. ENTRE : Napoléon Ier (18 brumaire, Code civil, Waterloo) ; la Restauration et les Trois Glorieuses ; Napoléon III et le Second Empire ; la défaite de 1870, Sedan, la perte de l'Alsace-Lorraine. 🛑 N'ENTRE PAS : la proclamation de la IIIe République LE LENDEMAIN de Sedan, la Commune, l'affaire Dreyfus — Sedan est la chute d'un empire, le 4 septembre est la naissance d'une république : « hg_republiques ». 🛑 N'ENTRE PAS non plus l'abolition de l'esclavage (1848) et les lois scolaires (1881-82) : ce sont des DROITS ACQUIS, donc « hg_conquetes_droits », même s'ils sont du XIXᵉ siècle.$tx$),

('hg_litterature', 'Les grands écrivains français', 'CIV_HISTOIRE_GEO', 9,
 $tx$Les écrivains français qu'un candidat doit savoir reconnaître, et leur œuvre la plus connue. ENTRE : romanciers, poètes, dramaturges, philosophes-écrivains, prix Nobel français de littérature. 🛑 N'ENTRE PAS : un peintre, un musicien, un savant → « hg_arts_sciences ». 🛑 Zola pris comme ACTEUR DE L'AFFAIRE DREYFUS → « hg_republiques » : la question demande qui a écrit « J'accuse…! » lors de l'affaire, pas qui a écrit Germinal.$tx$),

('hg_arts_sciences', 'Artistes et savants français', 'CIV_HISTOIRE_GEO', 10,
 $tx$Les Français qui ont marqué la peinture, la musique, la chanson, le cinéma, la mode, et les grandes découvertes et inventions françaises. ENTRE : peintres, compositeurs, chanteuses, couturiers, cinéastes, inventeurs, scientifiques célèbres. 🛑 N'ENTRE PAS : un écrivain → « hg_litterature ». 🛑 Le monument où l'œuvre est exposée → « hg_patrimoine » : « Qu'est-ce que le Louvre ? » est un monument, « Qui a peint la Joconde ? » est un peintre.$tx$),

('hg_art_de_vivre', 'Gastronomie, sport et art de vivre', 'CIV_HISTOIRE_GEO', 11,
 $tx$Ce que la France mange, boit, porte et regarde : les produits, les traditions et les grands rendez-vous sportifs et culturels. ENTRE : baguette, croissant, fromages, vins et champagne ; football, Tour de France, Roland-Garros, Jeux olympiques ; festival de Cannes ; la mode. 🛑 N'ENTRE PAS : la région où le produit est fait, quand la question porte sur LA RÉGION → « hg_geographie ». 🛑 Le créateur ou l'artiste lui-même → « hg_arts_sciences ». 🛑 Un jour de fête du calendrier → « hg_fetes_jours_feries ».$tx$),

-- ------------------------------------------------------------ DROITS & DEVOIRS
('dd_protection_europeenne', 'Les droits protégés au-delà de la France : CEDH, Union européenne', 'CIV_DROITS_DEVOIRS', 2,
 $tx$Les textes et les juridictions européennes et internationales qui garantissent les droits des personnes vivant en France, et comment un citoyen peut les saisir. ENTRE : la Convention européenne des droits de l'homme ; la Cour de Strasbourg, sa saisine après épuisement des recours internes, la condamnation de la France ; la CJUE ; la Cour pénale internationale ; la Charte des droits fondamentaux de l'UE ; le droit international humanitaire. 🛑 N'ENTRE PAS : le contenu FRANÇAIS d'un droit également garanti par la CEDH (procès équitable devant un tribunal français, droits de la défense) → « dd_police_justice ». 🛑 L'interdiction de la torture, même quand l'énoncé cite l'article 3 CEDH → « dd_infractions_peines » : le sujet est l'interdit absolu, pas l'institution. 🛑 Le fonctionnement politique de l'UE → thème CIV_INSTITUTIONS.$tx$),

('dd_libertes_limites', 'Les libertés individuelles et leurs limites', 'CIV_DROITS_DEVOIRS', 3,
 $tx$Ce que chacun a le droit de faire — s'exprimer, croire ou ne pas croire, circuler — et pourquoi la loi peut encadrer ces libertés sans les supprimer. ENTRE : la liberté d'expression et ses limites (injure, diffamation, haine en ligne) ; la liberté d'aller et venir ; LA LIBERTÉ DE CONSCIENCE et le droit de ne pas avoir de religion ; les droits individuels (liberté, sûreté, propriété) ; « les libertés ne sont pas absolues » et ses motifs ; l'état d'urgence ; le droit d'asile et la protection des apatrides. 🛑 N'ENTRE PAS : le TEXTE qui proclame la liberté et sa date → « dd_textes_fondateurs ». 🛑 La sanction pénale de l'abus → « dd_interdits_quotidien » ou « dd_infractions_peines ». 🛑 La neutralité de l'État, la loi de 1905, l'école → « pv_laicite ». LA RÈGLE : une PERSONNE a un droit → ici ; l'ÉTAT ou le service public a une obligation → « pv_laicite ». 🛑 La vie privée et l'image → « dd_vie_privee_famille ».$tx$),

('dd_infractions_peines', 'L''infraction et la peine : du principe de légalité aux interdits absolus', 'CIV_DROITS_DEVOIRS', 4,
 $tx$Comment le droit français définit une infraction, la gradue et la punit, et les quelques interdits auxquels aucune circonstance ne permet de déroger. ENTRE : les trois catégories d'infractions et leur gravité ; le principe de légalité des délits et des peines ; la non-rétroactivité de la loi pénale plus sévère ; la prescription et l'imprescriptibilité des crimes contre l'humanité ; la proportionnalité ; non bis in idem ; l'abolition de la peine de mort ; la dignité humaine ; l'interdiction absolue de la torture ; l'esclavage et la traite ; le « noyau dur » des droits intangibles. 🛑 N'ENTRE PAS : les interdits CONCRETS du quotidien → « dd_interdits_quotidien ». Ici c'est le PRINCIPE, là c'est le GESTE. 🛑 La procédure (garde à vue, avocat, procès) → « dd_police_justice ». 🛑 La CEDH comme institution → « dd_protection_europeenne ».$tx$),

('dd_interdits_quotidien', 'Ce qui est interdit au quotidien, et ce qu''on risque', 'CIV_DROITS_DEVOIRS', 5,
 $tx$Les comportements que la loi française interdit dans la vie de tous les jours, et la sanction encourue. C'est la notion qui répond à « est-ce que j'ai le droit de… ? ». ENTRE : fumer dans un lieu public fermé ; vendre de l'alcool à un mineur ; conduire alcoolisé ; ne pas porter la ceinture ; consommer du cannabis ; voler ; frapper ; les propos et actes racistes ; le harcèlement sexuel, le viol ; « que risque une personne qui ne respecte pas la loi ». 🛑 N'ENTRE PAS : le principe abstrait derrière la sanction → « dd_infractions_peines ». 🛑 Ce qu'on doit FAIRE positivement (payer ses impôts, trier, témoigner) → « dd_devoirs_citoyen » : un interdit n'est pas une obligation. 🛑 La procédure après l'infraction → « dd_police_justice ».$tx$),

('dd_police_justice', 'Police, justice : mes droits quand la loi s''applique à moi', 'CIV_DROITS_DEVOIRS', 6,
 $tx$Ce que la police peut faire et ne pas faire, ce qu'une personne contrôlée ou poursuivie peut exiger, et comment une victime obtient réparation. ENTRE : contrôle et fouille, garde à vue et sa durée, droit au silence, interdiction de l'arrestation sans motif ; droit à un avocat et droits de la défense ; procès équitable ; présomption d'innocence ; aide juridictionnelle ; recours effectif ; porter plainte, se constituer partie civile, être indemnisé. 🛑 N'ENTRE PAS : les numéros d'urgence et LE RÔLE de la police et de la gendarmerie → « vs_urgences_secours », thème CIV_SOCIETE. LA RÈGLE : ce que FONT les forces de l'ordre est un service ; ce que je peux LEUR OPPOSER est un droit. 🛑 La définition de l'infraction et de la peine → « dd_infractions_peines ». 🛑 Le devoir de respecter une décision de justice → « dd_devoirs_citoyen ».$tx$),

('dd_vie_privee_famille', 'Vie privée, image, données personnelles et vie de famille', 'CIV_DROITS_DEVOIRS', 8,
 $tx$Ce qui appartient à la sphère intime d'une personne — son image, sa correspondance, ses données, ses choix de couple et de corps — et la protection que le droit y attache. ENTRE : le droit au respect de la vie privée ; le droit à l'image ; le secret des correspondances ; le secret professionnel et médical ; le RGPD et le droit à l'oubli ; la majorité civile ; le mariage, le mariage pour tous, le PACS ; l'IVG ; la fin de vie. 🛑 N'ENTRE PAS : la liberté d'expression et ses limites, même quand elles protègent autrui → « dd_libertes_limites ». 🛑 La protection de l'enfance (maltraitance, signalement) → « dd_droits_sociaux » : c'est un droit de l'enfant. 🛑 L'égalité femmes-hommes comme principe politique → « dd_textes_fondateurs ».$tx$),

-- ------------------------------------------------------------------- SOCIÉTÉ
('vs_ecole_scolarite', 'L''école et les études', 'CIV_SOCIETE', 1,
 $tx$Le système scolaire français : qui doit être instruit, jusqu'à quand, quels cycles, quels diplômes, et comment on s'y inscrit. ENTRE : obligation d'instruction de 3 à 16 ans ; maternelle, élémentaire, collège, lycée ; brevet, bac, CAP, bac pro ; alternance, apprentissage, Parcoursup ; inscription, assiduité, cantine. 🛑 N'ENTRE PAS : la LAÏCITÉ à l'école (loi de 2004, Charte de 2013) → « pv_laicite ». 🛑 Le DROIT à l'éducation comme droit fondamental → « dd_droits_sociaux ». 🛑 La formation professionnelle de l'adulte → « vs_emploi_formation ».$tx$),

('vs_travail_entreprise', 'Les salariés dans l''entreprise', 'CIV_SOCIETE', 4,
 $tx$Ce qui se joue collectivement dans l'entreprise : qui représente les salariés, qui négocie, qui contrôle, et ce que l'entreprise redistribue. ENTRE : CSE, syndicats représentatifs, convention collective, inspection du travail, médecine du travail, participation aux bénéfices, PEE, AGS. 🛑 N'ENTRE PAS : le contrat individuel et le salaire → « vs_travail_contrat_salaire ». 🛑 Le droit de grève et la liberté syndicale COMME LIBERTÉS PUBLIQUES → « dd_droits_sociaux ». 🛑 Les conquêtes sociales historiques (1936, 1945) → « hg_conquetes_droits ».$tx$),

('vs_emploi_formation', 'Chercher un emploi, se former, créer son activité', 'CIV_SOCIETE', 5,
 $tx$Ce qu'on fait quand on n'a pas (encore) d'emploi, ou qu'on veut en changer : les organismes, les droits à la formation, la création d'activité. ENTRE : France Travail, CPF, micro-entrepreneur, service civique, reconnaissance de diplômes. 🛑 N'ENTRE PAS : le contrat une fois signé → « vs_travail_contrat_salaire ». 🛑 L'allocation chômage et le RSA → « vs_protection_sociale_aides ». 🛑 L'alternance sous statut scolaire → « vs_ecole_scolarite ».$tx$),

('vs_protection_sociale_aides', 'La protection sociale et les aides', 'CIV_SOCIETE', 6,
 $tx$Le filet social français : qui le finance, et quelles prestations on peut toucher selon sa situation. ENTRE : Sécurité sociale, cotisations, URSSAF, retraite, État-providence ; CAF, RSA, prime d'activité, APL, AAH, MDPH, C2S, AME ; LOGEMENT SOCIAL et HLM. 🛑 N'ENTRE PAS : le remboursement ORDINAIRE des soins (carte Vitale, médecin traitant, mutuelle) → « vs_sante_soins ». 🛑 Les droits sociaux du préambule de 1946 → « dd_droits_sociaux ». 🛑 La création de la Sécurité sociale en 1945 COMME ÉVÉNEMENT → « hg_conquetes_droits ».$tx$),

('vs_famille_etat_civil', 'La famille, le couple et l''état civil', 'CIV_SOCIETE', 7,
 $tx$Comment le droit français organise le couple, les enfants, la majorité et la transmission, et ce qu'il autorise ou interdit sur le corps. ENTRE : mariage civil (conditions, âge, égalité des époux, régimes matrimoniaux), PACS, autorité parentale, émancipation, majorité, crèche, acte de naissance, tutelle, mandat de protection future, réserve héréditaire, PMA, IVG, GPA. 🛑 N'ENTRE PAS : l'égalité femmes-hommes COMME PRINCIPE RÉPUBLICAIN → thème CIV_PRINCIPES. 🛑 Les violences conjugales et leur répression → « dd_interdits_quotidien ». 🛑 Le droit de vote à 18 ans, qui est la majorité CIVIQUE → « inst_elections ». 🛑 La carte d'identité → « vs_papiers_identite ».$tx$),

('vs_sejour_asile', 'Le séjour des étrangers et l''asile', 'CIV_SOCIETE', 8,
 $tx$Les titres qui autorisent un étranger à vivre en France, l'accompagnement à l'intégration, et la protection internationale. ENTRE : titre de séjour, carte pluriannuelle, carte de résident, niveaux de français exigés, OFII, contrat d'intégration républicaine, TCF/DELF ; asile : GUDA, OFPRA, statut de réfugié contre protection subsidiaire, règlement Dublin. 🛑 N'ENTRE PAS : DEVENIR FRANÇAIS → « vs_nationalite_francaise ». LA FRONTIÈRE : avoir le droit de rester (ici) contre devenir français (là-bas). 🛑 Les droits de l'étranger, la double peine, l'éloignement → thème CIV_DROITS_DEVOIRS. 🛑 Frontex et l'agence européenne d'asile → thème CIV_INSTITUTIONS.$tx$),

('vs_nationalite_francaise', 'Devenir français', 'CIV_SOCIETE', 9,
 $tx$Les voies d'accès à la nationalité française, leurs conditions, et ce qui accompagne son obtention. ENTRE : droit du sol, droit du sang, naturalisation (critères, examen civique 2026, B2), déclaration après mariage, double nationalité, cérémonie d'accueil, Charte des droits et devoirs, adhésion aux valeurs, perte de la nationalité. 🛑 N'ENTRE PAS : le séjour régulier qui précède → « vs_sejour_asile ». 🛑 Les VALEURS RÉPUBLICAINES EN ELLES-MÊMES → thème CIV_PRINCIPES : ici on ne garde que « ce à quoi le candidat doit adhérer ». 🛑 Les droits du citoyen une fois français → thème CIV_DROITS_DEVOIRS.$tx$),

('vs_deplacements_route', 'Se déplacer : permis, sécurité routière, transports', 'CIV_SOCIETE', 12,
 $tx$Conduire légalement en France et se déplacer au quotidien : les permis, leurs âges, les obligations de sécurité. ENTRE : permis B, permis moto A1/A2/A, conduite accompagnée, permis à points, casque à vélo, équipement obligatoire du véhicule, transports en commun urbains. 🛑 N'ENTRE PAS : les infractions routières et leurs sanctions, l'alcool au volant → « dd_interdits_quotidien ». 🛑 Les numéros de secours après un accident → « vs_urgences_secours ». 🛑 Le réseau ferré et l'aménagement du territoire → « hg_geographie ».$tx$),

-- ---------------------------------------------------------------- PRINCIPES
('pv_republique_democratie', 'La République : régime, démocratie, souveraineté', 'CIV_PRINCIPES', 2,
 $tx$Ce que veut dire « République » en France : un régime où le pouvoir vient du peuple, s'exerce par des représentants élus, et n'appartient à personne en propre. ENTRE : République indivisible, laïque, démocratique et sociale ; démocratie représentative et directe ; souveraineté nationale et populaire ; « le gouvernement du peuple, par le peuple, pour le peuple » ; le caractère républicain que la révision ne peut pas toucher ; l'intérêt général. 🛑 N'ENTRE PAS : les INSTITUTIONS qui l'incarnent — président, Parlement, élections → thème CIV_INSTITUTIONS. Ici on est sur le principe, pas sur l'organe. 🛑 Les cinq républiques successives et leur chronologie → « hg_republiques ». 🛑 La laïcité, qui est l'un des quatre adjectifs mais a sa propre notion → « pv_laicite ».$tx$);

-- ============================================================================
-- 2. LES NOTIONS CONSERVÉES : code, libellé, rang, frontière
-- ----------------------------------------------------------------------------
-- Les renommages de CODE viennent avant les fusions du §3, qui résolvent leur
-- destination par code.
--
-- Deux renommages corrigent un libellé qui MENTAIT sur son contenu :
--   * « Les grandes dates de la République » nommait une FORME de question,
--     pas un objet d'apprentissage — c'est ce qui alimentait le litige avec
--     les conquêtes de droits, et deux pilotes l'ont buté dessus.
--   * « Les devoirs : lois, impôts, jury » promettait le jury d'assises, sur
--     lequel le corpus ne porte AUCUNE question : il n'apparaît que dans
--     l'explication d'une autre. Un candidat n'en verrait jamais une seule.
-- ============================================================================

UPDATE civic_notions SET label = 'Les rois de France et la Révolution', display_order = 1, description =
 $tx$La France d'avant la République : le royaume, ses rois, et la Révolution de 1789 qui y met fin. ENTRE : les rois et l'Ancien Régime (Jeanne d'Arc, Henri IV, Louis XIV) ; 1789 et ses journées (Bastille, 4 août, Jeu de paume) ; les acteurs et la fin de la monarchie (Louis XVI, Marie-Antoinette, Robespierre, la Terreur) ; les Lumières. 🛑 N'ENTRE PAS : Napoléon et tout ce qui suit 1799 → « hg_napoleon_xixe » : le 18 brumaire FERME la Révolution, il appartient à Napoléon. 🛑 « Liberté, Égalité, Fraternité » et les symboles → thème CIV_PRINCIPES. 🛑 Le 14 juillet COMME JOUR FÉRIÉ → « hg_fetes_jours_feries ».$tx$
WHERE code = 'hg_revolution';

UPDATE civic_notions SET code = 'hg_republiques', label = 'Les cinq républiques', display_order = 3, description =
 $tx$Les régimes républicains successifs : quand ils naissent, comment ils fonctionnent, et les crises qui les traversent. ENTRE : le décompte des républiques ; la naissance de la IIIe (4 septembre 1870) ; la Commune de Paris ; l'affaire Dreyfus ; la fondation de la Ve en 1958 et ses présidents ; le référendum de 1962. 🛑 N'ENTRE PAS : si l'événement fait GAGNER UN DROIT, il relève de « hg_conquetes_droits », MÊME POSÉ SOUS FORME DE DATE. Couple de référence : « Quel président a aboli la peine de mort ? » → conquêtes ; « Qui a été le premier président socialiste ? » → ici. Même réponse (Mitterrand), notions différentes : c'est la SUBSTANCE qui tranche, jamais la forme de la question. 🛑 Les empires et les monarchies → « hg_napoleon_xixe ».$tx$
WHERE code = 'hg_dates_republique';

UPDATE civic_notions SET label = 'Les guerres du XXᵉ siècle et la décolonisation', display_order = 4, description =
 $tx$La France dans les conflits du XXᵉ siècle : les deux guerres mondiales, l'Occupation et la Résistance, puis les guerres qui mettent fin à l'empire colonial. ENTRE : 14-18 et ses batailles ; 39-45, Vichy, la Shoah, la France libre, la Résistance, la Libération ; l'empire colonial, l'Indochine, l'Algérie, les indépendances de 1960. 🛑 N'ENTRE PAS : le 11 novembre et le 8 mai COMME JOURS FÉRIÉS → « hg_fetes_jours_feries ». 🛑 La Sécurité sociale de 1945 → « hg_conquetes_droits » : un droit acquis. 🛑 La Nouvelle-Calédonie et ses référendums → « hg_geographie » : statut d'outre-mer actuel.$tx$
WHERE code = 'hg_guerres_resistance';

UPDATE civic_notions SET label = 'Les conquêtes sociales et les transformations de la société', display_order = 5, description =
 $tx$Les événements, lois et mouvements qui ont fait ACQUÉRIR, ÉTENDRE ou RECONNAÎTRE un droit, ou transformé en profondeur la société française — même quand la question demande une date, une année ou une personnalité. ENTRE : école gratuite, laïque et obligatoire ; abolition de l'esclavage ; droit de vote des femmes ; Front populaire et congés payés ; Sécurité sociale ; IVG ; abolition de la peine de mort ; majorité à 18 ans ; Mai 68. 🛑 N'ENTRE PAS : un fait purement institutionnel ou présidentiel, qui n'est pas principalement l'acquisition d'un droit → « hg_republiques ». 🛑 Le 1er mai comme FÊTE DU TRAVAIL → « hg_fetes_jours_feries ».$tx$
WHERE code = 'hg_conquetes_droits';

UPDATE civic_notions SET label = 'La construction européenne', display_order = 6, description =
 $tx$La naissance et les étapes de l'Europe communautaire, du point de vue français. ENTRE : CECA, CEE et traité de Rome, Maastricht, référendum de 2005, pères fondateurs français. 🛑 N'ENTRE PAS : les institutions européennes D'AUJOURD'HUI (Commission, Parlement européen, élections européennes) → « inst_ue ». 🛑 Strasbourg comme capitale du Grand Est → « hg_geographie ».$tx$
WHERE code = 'hg_europe';

UPDATE civic_notions SET label = 'Géographie de la France et outre-mer', display_order = 7, description =
 $tx$Situer la France et ses territoires : mers, fleuves, montagnes, régions, grandes villes, outre-mer. ENTRE : façades maritimes ; fleuves ; chaînes de montagnes ; les 13 régions et leurs capitales ; les grandes villes et leurs surnoms ; DOM et collectivités ; le continent. 🛑 N'ENTRE PAS : un lieu qu'on visite pour CE QU'IL EST → « hg_patrimoine ». LA RÈGLE : situer sur une carte → ici ; nommer un site célèbre → patrimoine. Le Mont-Saint-Michel et les falaises d'Étretat sont donc du patrimoine, les Alpes et la Corse de la géographie. 🛑 Un produit régional → « hg_art_de_vivre ».$tx$
WHERE code = 'hg_geographie';

UPDATE civic_notions SET label = 'Monuments et sites emblématiques', display_order = 8, description =
 $tx$Les monuments et les sites que la France montre au monde, et ce qu'ils sont. ENTRE : monuments bâtis (tour Eiffel, Louvre, Versailles, Notre-Dame, Arc de Triomphe, Chambord, arènes de Nîmes) ET sites naturels devenus emblèmes (Mont-Saint-Michel, falaises d'Étretat). 🛑 N'ENTRE PAS : une œuvre ou son auteur → « hg_arts_sciences » : « Qu'est-ce que le Louvre ? » est ici, « Qui a peint la Joconde ? » est là-bas. 🛑 Une ville qu'on situe → « hg_geographie ».$tx$
WHERE code = 'hg_patrimoine';

UPDATE civic_notions SET display_order = 12, description =
 $tx$Les fêtes du calendrier français et les jours fériés : quand ils tombent et ce qu'ils commémorent. ENTRE : 1er janvier, 1er mai, 8 mai, 14 juillet, Toussaint, 11 novembre, Noël. 🛑 N'ENTRE PAS : l'événement commémoré pris POUR LUI-MÊME → sa notion d'histoire. « Quand a eu lieu la prise de la Bastille ? » → « hg_revolution » ; « Que célèbre-t-on le 14 juillet ? » → ici. 🛑 Le 14 juillet comme FÊTE NATIONALE ET SYMBOLE → thème CIV_PRINCIPES.$tx$
WHERE code = 'hg_fetes_jours_feries';

UPDATE civic_notions SET label = 'La Constitution et la séparation des pouvoirs', display_order = 1, description =
 $tx$Le texte qui fonde la Ve République, la façon dont il se révise et qui le fait respecter ; et le principe qu'il organise : trois pouvoirs séparés, chacun tenu par quelqu'un de différent. ENTRE : le régime politique de la France ; Montesquieu et l'identification de chaque pouvoir à son titulaire ; le Conseil constitutionnel (composition, saisine, QPC, contrôle a priori et a posteriori) ; la révision constitutionnelle et ses limites ; le rang des normes (loi organique). 🛑 N'ENTRE PAS : ce que FAIT un pouvoir donné → « inst_president » ou « inst_parlement ». Ici on reste au niveau « il y a trois pouvoirs, voici lequel est lequel ». 🛑 Le partage loi/règlement et le décret → « inst_gouvernement ». 🛑 « Qui doit respecter la loi ? » est un devoir civique → thème CIV_DROITS_DEVOIRS.$tx$
WHERE code = 'inst_constitution';

UPDATE civic_notions SET label = 'Le président de la République', display_order = 2, description =
 $tx$Qui il est, comment on le devient, combien de temps il reste, et ce qu'il peut faire — y compris ce qu'il ne peut pas faire. ENTRE : élection au suffrage universel direct depuis 1962, durée et limite de mandats, parrainages, l'Élysée ; ses pouvoirs propres (nommer le Premier ministre, dissoudre, promulguer, référendum, article 16, chef des armées) ; ses limites (immunité, Haute Cour, obligation de promulguer). 🛑 N'ENTRE PAS : le Premier ministre et les ministres UNE FOIS NOMMÉS → « inst_gouvernement ». LA FRONTIÈRE : le président NOMME (ici), le gouvernement GOUVERNE (là-bas). 🛑 Le scrutin vu de l'électeur → « inst_elections ».$tx$
WHERE code = 'inst_president';

UPDATE civic_notions SET label = 'Le gouvernement et l''administration de l''État', display_order = 3, description =
 $tx$Qui dirige l'action de l'État au quotidien — Premier ministre, ministres, et leurs relais sur le territoire — et par quels moyens : décrets, ordonnances, budget. ENTRE : le gouvernement (composition, nomination, Matignon, Conseil des ministres, cohabitation) ; les actes de l'exécutif (décret, ordonnance, domaine réglementaire, 49.3) ; L'ÉTAT SUR LE TERRITOIRE : LE PRÉFET ; l'argent public quand la question porte sur son ORGANISATION ou sa COLLECTE (budget, impôts perçus par l'État, impôts locaux, Cour des comptes). 🛑 N'ENTRE PAS : le président, qui NOMME le Premier ministre mais n'est pas le gouvernement → « inst_president ». 🛑 Le VOTE du budget est au Parlement ; sa préparation et son contrôle sont ici. 🛑 L'OBLIGATION DE PAYER ses impôts est un devoir → thème CIV_DROITS_DEVOIRS. 🛑 Le rôle de la police → « vs_urgences_secours ». 🛑 Le préfet n'est PAS une collectivité : il représente l'État. Déconcentration ici, décentralisation dans « inst_collectivites ».$tx$
WHERE code = 'inst_gouvernement';

UPDATE civic_notions SET display_order = 4, description =
 $tx$Les deux chambres : qui y siège, comment on y entre, et ce qu'on y fait — voter les lois, voter le budget, contrôler le gouvernement. ENTRE : bicamérisme, effectifs (577 et 348), durée et mode d'élection, Palais Bourbon et Luxembourg, immunité, commissions ; le travail parlementaire (voter la loi, la navette et le dernier mot de l'Assemblée, le budget, les questions au gouvernement, la motion de censure, l'entrée en vigueur d'une loi votée). 🛑 N'ENTRE PAS : le Parlement EUROPÉEN → « inst_ue ». Deux institutions homonymes : c'est le piège numéro un du thème. 🛑 Le scrutin législatif vu de l'électeur → « inst_elections ». 🛑 La promulgation → « inst_president ». 🛑 Le 49.3 et l'ordonnance → « inst_gouvernement » : c'est l'exécutif qui agit.$tx$
WHERE code = 'inst_parlement';

UPDATE civic_notions SET display_order = 5, description =
 $tx$Qui a le droit de voter en France et à quelles conditions ; quelles élections existent au niveau national ; comment la vie politique qui les entoure est encadrée. ENTRE : le droit de vote (âge, nationalité, droits civiques, inscription, vote non obligatoire, suffrage universel, droit de vote des ressortissants UE) ; les scrutins nationaux (présidentielle, législatives) ; le référendum, y compris d'initiative partagée ; l'encadrement (partis et pluralisme, financement des campagnes, parité, transparence). 🛑 N'ENTRE PAS : les municipales, départementales et régionales → « inst_collectivites » : sans elles cette notion-là s'effondre. 🛑 Les européennes → « inst_ue ». 🛑 Ce que FAIT l'élu une fois élu → « inst_president » ou « inst_parlement ». LA RÈGLE : la question porte-t-elle sur l'électeur et le scrutin (ici) ou sur l'institution élue (là-bas) ?$tx$
WHERE code = 'inst_elections';

UPDATE civic_notions SET code = 'inst_collectivites', label = 'Les collectivités territoriales : commune, département, région', display_order = 6, description =
 $tx$Les trois échelons élus qui gèrent le territoire au-dessous de l'État : qui les dirige, comment on les désigne, et qui fait quoi entre la mairie, le département et la région. ENTRE : l'emboîtement commune, département, région, État ; la commune (le maire, son élection par le conseil municipal, l'état civil, les intercommunalités) ; le département et la région (nombre, présidence, mandats, compétences — collèges, lycées, transports, formation —, autonomie financière) ; les élections LOCALES. 🛑 N'ENTRE PAS : LE PRÉFET. Il ne dirige pas une collectivité, il représente l'État → « inst_gouvernement ». C'est la confusion centrale du thème, et le corpus la met lui-même en scène. 🛑 Le Parlement et le gouvernement, qui sont l'État et non le territoire.$tx$
WHERE code = 'inst_commune';

UPDATE civic_notions SET label = 'La justice, les tribunaux et les magistrats', display_order = 7, description =
 $tx$Qui juge en France, dans quel tribunal selon la gravité, et pourquoi la justice décide sans recevoir d'ordre du pouvoir politique. ENTRE : l'autorité judiciaire et son indépendance ; les juridictions (police, correctionnel, assises, Cour de cassation, Conseil d'État, ordre judiciaire et ordre administratif, Cour de justice de la République) ; les magistrats (siège et parquet, procureur, Conseil supérieur de la magistrature) ; les recours du citoyen contre l'administration. 🛑 N'ENTRE PAS : le Conseil constitutionnel, qui n'est pas un tribunal → « inst_constitution ». 🛑 Les DROITS de la personne jugée (présomption d'innocence, avocat, aide juridictionnelle) → thème CIV_DROITS_DEVOIRS : ce sont des droits, pas des institutions. 🛑 La police → « vs_urgences_secours ».$tx$
WHERE code = 'inst_justice';

UPDATE civic_notions SET display_order = 8, description =
 $tx$Ce qu'est l'Union européenne, d'où elle vient, qui décide à Bruxelles et à Strasbourg, et ce qu'elle change concrètement pour quelqu'un qui vit en France. ENTRE : les institutions (Commission, Parlement européen, Conseil de l'UE, Conseil européen, sièges, élections européennes, règlement contre directive) ; la vie du citoyen européen (citoyenneté, Schengen, libre circulation, euro et zone euro) ; LES SYMBOLES EUROPÉENS (drapeau, hymne, Journée de l'Europe) ; les traités et le nombre d'États membres. 🛑 N'ENTRE PAS : le Parlement FRANÇAIS → « inst_parlement ». 🛑 Le 112 vu comme NUMÉRO D'URGENCE À COMPOSER → « vs_urgences_secours ». 🛑 Les étapes HISTORIQUES de la construction européenne (CECA, traité de Rome, référendum de 2005) → « hg_europe ».$tx$
WHERE code = 'inst_ue';

UPDATE civic_notions SET code = 'dd_textes_fondateurs', label = 'La Déclaration de 1789 et les textes qui garantissent nos droits', display_order = 1, description =
 $tx$D'où viennent les droits en France : la DDHC de 1789, le préambule de 1946, le bloc de constitutionnalité, et le fait que l'État lui-même y est soumis. ENTRE : la date, l'auteur et la portée de la DDHC ; ses articles cités nommément (1er, 2, 4, 6, 8, 11) ; le préambule de 1946 et les droits sociaux qu'il reconnaît ; la décision de 1971 et le bloc de constitutionnalité ; la hiérarchie des normes ; l'État de droit ; l'égalité devant la loi comme principe de texte ; la Charte des droits et devoirs du citoyen. 🛑 N'ENTRE PAS : le CONTENU d'une liberté et ses limites → « dd_libertes_limites ». Le texte dit QUE la liberté d'expression existe ; COMMENT elle s'arrête est l'autre notion. 🛑 La CEDH, la CJUE, la CPI, la Charte de l'UE → « dd_protection_europeenne » : ici on reste sur les sources FRANÇAISES. 🛑 Le nom de la Constitution actuelle → thème CIV_INSTITUTIONS.$tx$
WHERE code = 'dd_droits_fondamentaux';

UPDATE civic_notions SET label = 'Les devoirs du citoyen : la loi, l''impôt, la défense, l''environnement', display_order = 7, description =
 $tx$Ce que la République attend de chacun en retour des droits qu'elle garantit : obéir à la loi, contribuer, servir, protéger. ENTRE : respecter la loi et les décisions de justice ; L'OBLIGATION DE PAYER SES IMPÔTS ; dire la vérité comme témoin ; la Journée défense et citoyenneté, l'objection de conscience ; la probité de l'agent public ; le devoir de protéger l'environnement et le tri ; les devoirs constitutionnels ; le devoir de fraternité. 🛑 N'ENTRE PAS : les INTERDITS → « dd_interdits_quotidien » : un devoir est une obligation d'AGIR, pas une abstention. 🛑 L'ORGANISATION de l'impôt, sa collecte, le budget public → thème CIV_INSTITUTIONS. LA RÈGLE : « dois-je payer ? » est ici, « qui collecte et comment » est là-bas. 🛑 Le droit à un environnement sain RESTE ICI avec son pendant l'obligation, parce que le corpus les énonce toujours ensemble.$tx$
WHERE code = 'dd_devoirs_citoyen';

UPDATE civic_notions SET code = 'dd_droits_sociaux', label = 'Travailler, se soigner, être logé, aller à l''école : les droits sociaux', display_order = 9, description =
 $tx$Les droits que le préambule de 1946 et la loi reconnaissent à toute personne vivant en France dans sa vie matérielle : le travail, la santé, le logement, l'instruction, la protection de l'enfance. ENTRE : durée légale du travail, congés payés, SMIC, travail dissimulé, harcèlement moral, droit de grève, liberté syndicale ; protection maladie universelle et droit constitutionnel à la santé ; droit au logement opposable ; instruction obligatoire de 3 à 16 ans et gratuité de l'école ; protection de l'enfance (signalement, interdiction des violences éducatives). 🛑 N'ENTRE PAS : les DÉMARCHES pour obtenir ces droits → thème CIV_SOCIETE. LE TEST : un droit qu'on peut faire valoir DEVANT UN JUGE reste ici ; un formulaire à déposer à un GUICHET part là-bas. 🛑 Le devoir de payer ses cotisations → « dd_devoirs_citoyen ».$tx$
WHERE code = 'dd_travail';

UPDATE civic_notions SET code = 'vs_sante_soins', label = 'Se soigner : médecin, Sécu, remboursements', display_order = 2, description =
 $tx$Le parcours de soins ordinaire et son remboursement : à qui on s'adresse, avec quelle carte, qui paie quoi. ENTRE : carte Vitale, CPAM, médecin traitant, pharmacien, mutuelle, protection universelle maladie, arrêt maladie, vaccinations obligatoires. 🛑 N'ENTRE PAS : l'AME et la C2S → « vs_protection_sociale_aides » : prestations sous condition de ressources. 🛑 La médecine du travail → « vs_travail_entreprise ». 🛑 L'IVG, la PMA, la GPA → « vs_famille_etat_civil ». 🛑 Le DROIT à la santé → « dd_droits_sociaux ».$tx$
WHERE code = 'vs_sante';

UPDATE civic_notions SET code = 'vs_travail_contrat_salaire', label = 'Le contrat de travail et le salaire', display_order = 3, description =
 $tx$La relation individuelle employeur-salarié : quel contrat, quel salaire, quelle durée, comment ça se rompt. ENTRE : CDI, CDD, SMIC, brut et net, 35 heures, préavis, démission, rupture conventionnelle, congés maternité et paternité, âge minimum pour travailler, travail non déclaré, CESU. 🛑 N'ENTRE PAS : tout ce qui est COLLECTIF (CSE, syndicats, convention collective, inspection du travail) → « vs_travail_entreprise ». 🛑 CHERCHER un emploi ou se former → « vs_emploi_formation ». 🛑 Cotisations et retraite → « vs_protection_sociale_aides ». 🛑 Le droit au travail et la non-discrimination à l'embauche → « dd_droits_sociaux ».$tx$
WHERE code = 'vs_emploi';

UPDATE civic_notions SET code = 'vs_papiers_identite', label = 'Ses papiers et les guichets de l''administration', display_order = 10, description =
 $tx$Les documents qui prouvent qui on est, comment on les obtient, les renouvelle, les remplace, et où l'on s'adresse pour une démarche. ENTRE : carte nationale d'identité et sa validité, passeport, perte ou vol, document attestant la nationalité, documents pour voyager, service-public.fr et le 39 39, centre des impôts. 🛑 N'ENTRE PAS : le titre de séjour → « vs_sejour_asile ». 🛑 L'acte de naissance et l'état civil → « vs_famille_etat_civil ». 🛑 La carte Vitale → « vs_sante_soins ». 🛑 C'est ce qui reste de l'ancienne notion « démarches administratives » UNE FOIS VIDÉE : ne jamais y remettre du séjour, de la nationalité ou des aides.$tx$
WHERE code = 'vs_demarches';

UPDATE civic_notions SET code = 'vs_urgences_secours', label = 'Urgences, secours et forces de l''ordre', display_order = 11, description =
 $tx$Qui intervient en cas d'urgence ou de danger, quel numéro composer, et ce que font la police et la gendarmerie au quotidien. ENTRE : le 15, le 17, le 18, le 112, le 119, le 116 000, le 3919 ; la gratuité et l'accessibilité 24 h/24 ; LE RÔLE de la police nationale et de la gendarmerie, et leur répartition urbain-rural. 🛑 N'ENTRE PAS : ce que je peux OPPOSER à un policier — contrôle, fouille, garde à vue, droit au silence, arrestation sans motif, porter plainte → thème CIV_DROITS_DEVOIRS. LA RÈGLE : ce que FONT les forces de l'ordre est un service ; ce que je peux LEUR OPPOSER est un droit. 🛑 Le parcours de soins non urgent → « vs_sante_soins ». 🛑 Le signalement d'un enfant en danger, qui est un DEVOIR → « dd_droits_sociaux ».$tx$
WHERE code = 'vs_transports_securite';

UPDATE civic_notions SET code = 'pv_symboles_devise', label = 'Les symboles et la devise de la République', display_order = 1, description =
 $tx$Ce à quoi la France se reconnaît : son drapeau, son hymne, sa figure, sa fête, sa langue, et les trois mots de sa devise, un par un. ENTRE : drapeau tricolore, Marianne, coq, hymne et La Marseillaise, 14 juillet comme fête nationale, langue officielle (article 2 de la Constitution, l'article des symboles), sceau ; « Liberté, Égalité, Fraternité » et le sens de chacun des trois mots. 🛑 N'ENTRE PAS : les SYMBOLES EUROPÉENS (drapeau aux douze étoiles, hymne, Journée de l'Europe) → « inst_ue ». 🛑 Le 14 juillet comme JOUR FÉRIÉ DU CALENDRIER → « hg_fetes_jours_feries » ; comme PRISE DE LA BASTILLE → « hg_revolution ». 🛑 L'égalité comme DROIT OPPOSABLE → « pv_egalite_non_discrimination » : la devise proclame, l'autre notion applique.$tx$
WHERE code = 'pv_symboles';

UPDATE civic_notions SET display_order = 3, description =
 $tx$La règle qui sépare l'État des religions : l'État ne se mêle pas des croyances, et garantit à chacun de croire, de ne pas croire ou de changer d'avis. ENTRE : loi de 1905 et séparation des Églises et de l'État ; NEUTRALITÉ DE L'ÉTAT ET DE L'AGENT PUBLIC ; loi du 15 mars 2004 sur les signes religieux à l'école publique ; Charte de la laïcité de 2013 ; laïcité de l'école publique ; financement des cultes ; exception concordataire d'Alsace-Moselle. 🛑 N'ENTRE PAS : le droit INDIVIDUEL de croire, de ne pas croire, de changer de religion, de ne pas être discriminé pour sa religion → « dd_libertes_limites ». LA RÈGLE, ET ELLE EST STRICTE : l'ÉTAT ou le SERVICE PUBLIC a une obligation → ici ; une PERSONNE a un droit → « dd_libertes_limites ». 🛑 La date du vote de la loi de 1905 prise comme repère historique → « hg_conquetes_droits ».$tx$
WHERE code = 'pv_laicite';

UPDATE civic_notions SET display_order = 4, description =
 $tx$Le principe selon lequel la loi est la même pour tous et personne ne peut être traité moins bien à cause de ce qu'il est. ENTRE : égalité devant la loi et devant le service public ; les critères de discrimination prohibés ; l'égalité femmes-hommes et la parité ; l'égalité réelle et les politiques qui la visent ; le refus des distinctions d'origine, de race ou de religion. 🛑 N'ENTRE PAS : l'égalité comme MOT DE LA DEVISE → « pv_symboles_devise ». 🛑 La SANCTION PÉNALE du racisme et de l'incitation à la haine → « dd_interdits_quotidien ». 🛑 L'article 6 de la DDHC pris comme TEXTE → « dd_textes_fondateurs ».$tx$
WHERE code = 'pv_egalite_non_discrimination';

UPDATE civic_notions SET code = 'pv_libertes_ddhc', label = 'Les libertés fondamentales et la Déclaration de 1789', display_order = 5, description =
 $tx$Les libertés que la République reconnaît à toute personne, et le texte de 1789 qui les a énoncées le premier. ENTRE : liberté, sûreté, propriété, résistance à l'oppression ; liberté d'expression, de réunion, d'association, de la presse COMME PRINCIPES ; la DDHC comme socle de ces libertés. 🛑 N'ENTRE PAS : le RÉGIME JURIDIQUE d'une liberté et ses limites concrètes → « dd_libertes_limites », thème CIV_DROITS_DEVOIRS. 🛑 La DDHC prise comme SOURCE DU DROIT (articles, bloc de constitutionnalité, hiérarchie des normes) → « dd_textes_fondateurs ». ⚠️ Recouvrement assumé avec CIV_DROITS_DEVOIRS : la frontière est PRINCIPE PROCLAMÉ (ici) contre DROIT EXERCÉ ET LIMITÉ (là-bas). C'est la frontière la plus fragile du référentiel.$tx$
WHERE code = 'pv_libertes_fondamentales';

-- ============================================================================
-- 3. LES QUATORZE FUSIONS
-- ----------------------------------------------------------------------------
-- Aucune ligne n'est supprimée : la contrainte `chk_civic_notion_merge_desactive`
-- impose seulement qu'une notion fusionnée soit désactivée. Les trois qui se
-- dissolvent sans destination dominante gardent `merged_into_id` NULL — une
-- destination unique serait une trace fausse.
-- ============================================================================

UPDATE civic_notions n SET
    is_active = false,
    merged_into_id = (SELECT m.id FROM civic_notions m WHERE m.code = f.vers),
    description = f.motif
FROM (VALUES
    ('hg_loi_1905', 'pv_laicite',
     $tx$Désactivée (V058) : UNE SEULE question dans les 215 du thème, et elle est elle-même mal rangée — « en quelle année la loi de séparation des Églises et de l'État a-t-elle été votée ? » relève de la laïcité. Zéro question en CSP, zéro en NAT.$tx$),
    ('hg_langue_culture', 'hg_litterature',
     $tx$Dissoute (V058) en « hg_litterature », « hg_arts_sciences » et « hg_art_de_vivre ». Son nom mentait sur son contenu : sur 36 questions, DEUX seulement portaient sur la langue ou la francophonie ; tout le reste était de la culture. Elle avalait aussi les fêtes du calendrier faute de notion dédiée.$tx$),
    ('inst_departement_region', 'inst_collectivites',
     $tx$Fusionnée (V058) avec « la commune et le maire ». Ce n'étaient pas deux notions qui se recouvraient : c'étaient deux moitiés d'une seule, chacune morte dans une mention différente — celle-ci n'avait AUCUNE question CSP, l'autre AUCUNE question NAT.$tx$),
    ('dd_egalite_loi', 'dd_textes_fondateurs',
     $tx$Désactivée (V058) : 5 questions au total, sous le seuil dans les trois mentions. L'article 6 de la DDHC, l'égalité réelle et la parité rejoignent les textes fondateurs ; le racisme puni et l'incitation à la haine rejoignent « dd_interdits_quotidien ».$tx$),
    ('dd_liberte_culte', 'dd_libertes_limites',
     $tx$Désactivée (V058) : DEUX questions, toutes deux sur la liberté de CONSCIENCE et non de culte. Elles restent un droit individuel, donc dans les libertés et leurs limites — et non dans « pv_laicite », qui porte l'obligation de l'ÉTAT.$tx$),
    ('dd_protection_sociale', 'dd_droits_sociaux',
     $tx$Fusionnée (V058) : DEUX questions. Le corpus traite santé, éducation, travail, sécurité matérielle et logement comme un bloc — une de ses questions les énumère d'ailleurs dans une seule réponse.$tx$),
    ('dd_ecole_enfance', 'dd_droits_sociaux',
     $tx$Fusionnée (V058) : 6 questions, dont zéro en CR. Le DROIT à l'instruction rejoint les droits sociaux ; le fonctionnement de l'école rejoint « vs_ecole_scolarite ».$tx$),
    ('dd_logement', 'dd_droits_sociaux',
     $tx$Fusionnée (V058) : UNE SEULE question dans tout le thème, le droit au logement opposable. Le logement pratique (bail, caution, APL) relève du thème CIV_SOCIETE.$tx$),
    ('vs_logement_pratique', 'vs_protection_sociale_aides',
     $tx$Désactivée (V058) : 4 questions, dont zéro en NAT. Logement social, HLM et APL rejoignent les aides sous condition de ressources, où ils sont chez eux. La caution locative reste orpheline : le corpus ne porte presque rien sur la location.$tx$),
    ('vs_budget_impots', 'vs_papiers_identite',
     $tx$Désactivée (V058) : DEUX questions — le surendettement et le centre des impôts. Le budget du particulier (compte bancaire, déclaration de revenus, taxe foncière) est une lacune de contenu, pas une notion.$tx$),
    ('vs_laicite_quotidien', 'pv_laicite',
     $tx$Désactivée (V058) : UNE SEULE question, « l'école publique est-elle laïque ? », qui doublonnait déjà avec le thème CIV_PRINCIPES. Aucune question sur la laïcité au travail, à l'hôpital ou à la cantine : le quotidien laïque n'existe pas dans le corpus.$tx$)
) AS f(code, vers, motif)
WHERE n.code = f.code;

UPDATE civic_notions n SET
    is_active = false,
    description = f.motif
FROM (VALUES
    ('pv_devise_valeurs',
     $tx$Fusionnée (V058) dans « pv_symboles_devise ». Le corpus ne distingue pas la devise des symboles : « Que représente Marianne ? » et « Que signifie la liberté dans la devise ? » sont la même révision.$tx$),
    ('pv_ddhc',
     $tx$Fusionnée (V058) dans « pv_libertes_ddhc ». À elles deux, les libertés fondamentales et la Déclaration ne portaient que 8 questions : séparées, elles étaient inviables.$tx$),
    ('vs_vie_collective',
     $tx$Dissoute (V058) SANS destination dominante, et c'est pourquoi `merged_into_id` reste NULL. Ses 5 questions n'avaient rien en commun : le service civique part vers « vs_emploi_formation », les valeurs républicaines vers « vs_nationalite_francaise », le tabac aux mineurs, l'âge d'entrée en boîte de nuit et la bibliothèque municipale restent orphelins. Son libellé, « Vivre ensemble et respect des règles », était indéfendable après « À travailler : ».$tx$)
) AS f(code, motif)
WHERE n.code = f.code;

UPDATE civic_notions SET merged_into_id = (SELECT id FROM civic_notions WHERE code = 'pv_symboles_devise')
WHERE code = 'pv_devise_valeurs';

UPDATE civic_notions SET merged_into_id = (SELECT id FROM civic_notions WHERE code = 'pv_libertes_ddhc')
WHERE code = 'pv_ddhc';
