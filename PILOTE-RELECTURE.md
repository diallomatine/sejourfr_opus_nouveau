# Pilote v4 — les 44 questions à trancher

`PROMPT_TAG_NOTION_v4` · `claude-sonnet-5`, effort low · 2 lots de 25 : **Droits et devoirs** et **Vivre en société**. Coût réel : 0,11 $.

Sur les 50 questions du pilote, **6 sont déjà tranchées** (annexe en fin de fiche) ; **44 attendent ton verdict** et sont détaillées ci-dessous.

> 🛑 **Le modèle PROPOSE, il n'applique rien.** Aucune de ces suggestions n'a touché la base : `civic_notion_id` est nul sur les 50, et sur les 832 autres. Ta relecture est la seule chose qui pose un tag.

**L'ordre est celui de la file de revue** : « aucune notion » d'abord — c'est le signal le plus précieux d'une campagne — puis les confiances croissantes. Une suggestion à 0,97 se confirme d'un coup d'œil, une à 0,70 demande un vrai arbitrage.

⚠️ **Une description a changé APRÈS cet appel.** V060 a resserré la frontière de l'impôt dans `dd_devoirs_citoyen` — parce que ce pilote l'a révélée floue. Les suggestions ci-dessous ont donc été produites avec le texte précédent, et on ne les rejuge pas : réécrire l'histoire d'une mesure la rendrait inutilisable. La seule question concernée est la première de cette fiche.

## Le référentiel — Droits et devoirs

- **`dd_textes_fondateurs`** — La Déclaration de 1789 et les textes qui garantissent nos droits
  > D'où viennent les droits en France : la DDHC de 1789, le préambule de 1946, le bloc de constitutionnalité, et le fait que l'État lui-même y est soumis. ENTRE : la date, l'auteur et la portée de la DDHC ; ses articles cités nommément (1er, 2, 4, 6, 8, 11) ; le préambule de 1946 et les droits sociaux qu'il reconnaît ; la décision de 1971 et le bloc de constitutionnalité ; la hiérarchie des normes ; l'État de droit ; l'égalité devant la loi comme principe de texte ; la Charte des droits et devoirs du citoyen. 🛑 N'ENTRE PAS : le CONTENU d'une liberté et ses limites → « dd_libertes_limites ». Le texte dit QUE la liberté d'expression existe ; COMMENT elle s'arrête est l'autre notion. 🛑 La CEDH, la CJUE, la CPI, la Charte de l'UE → « dd_protection_europeenne » : ici on reste sur les sources FRANÇAISES. 🛑 Le nom de la Constitution actuelle → thème CIV_INSTITUTIONS.
- **`dd_protection_europeenne`** — Les droits protégés au-delà de la France : CEDH, Union européenne
  > Les textes et les juridictions européennes et internationales qui garantissent les droits des personnes vivant en France, et comment un citoyen peut les saisir. ENTRE : la Convention européenne des droits de l'homme ; la Cour de Strasbourg, sa saisine après épuisement des recours internes, la condamnation de la France ; la CJUE ; la Cour pénale internationale ; la Charte des droits fondamentaux de l'UE ; le droit international humanitaire. 🛑 N'ENTRE PAS : le contenu FRANÇAIS d'un droit également garanti par la CEDH (procès équitable devant un tribunal français, droits de la défense) → « dd_police_justice ». 🛑 L'interdiction de la torture, même quand l'énoncé cite l'article 3 CEDH → « dd_infractions_peines » : le sujet est l'interdit absolu, pas l'institution. 🛑 Le fonctionnement politique de l'UE → thème CIV_INSTITUTIONS.
- **`dd_libertes_limites`** — Les libertés individuelles et leurs limites
  > Ce que chacun a le droit de faire — s'exprimer, croire ou ne pas croire, circuler — et pourquoi la loi peut encadrer ces libertés sans les supprimer. ENTRE : la liberté d'expression et ses limites (injure, diffamation, haine en ligne) ; la liberté d'aller et venir ; LA LIBERTÉ DE CONSCIENCE et le droit de ne pas avoir de religion ; les droits individuels (liberté, sûreté, propriété) ; « les libertés ne sont pas absolues » et ses motifs ; l'état d'urgence ; le droit d'asile et la protection des apatrides. 🛑 N'ENTRE PAS : le TEXTE qui proclame la liberté et sa date → « dd_textes_fondateurs ». 🛑 La sanction pénale de l'abus → « dd_interdits_quotidien » ou « dd_infractions_peines ». 🛑 La neutralité de l'État, la loi de 1905, l'école → « pv_laicite ». LA RÈGLE : une PERSONNE a un droit → ici ; l'ÉTAT ou le service public a une obligation → « pv_laicite ». 🛑 La vie privée et l'image → « dd_vie_privee_famille ».
- **`dd_infractions_peines`** — L'infraction et la peine : du principe de légalité aux interdits absolus
  > Comment le droit français définit une infraction, la gradue et la punit, et les quelques interdits auxquels aucune circonstance ne permet de déroger. ENTRE : les trois catégories d'infractions et leur gravité ; le principe de légalité des délits et des peines ; la non-rétroactivité de la loi pénale plus sévère ; la prescription et l'imprescriptibilité des crimes contre l'humanité ; la proportionnalité ; non bis in idem ; l'abolition de la peine de mort ; la dignité humaine ; l'interdiction absolue de la torture ; l'esclavage et la traite ; le « noyau dur » des droits intangibles. 🛑 N'ENTRE PAS : les interdits CONCRETS du quotidien → « dd_interdits_quotidien ». Ici c'est le PRINCIPE, là c'est le GESTE. 🛑 La procédure (garde à vue, avocat, procès) → « dd_police_justice ». 🛑 La CEDH comme institution → « dd_protection_europeenne ».
- **`dd_interdits_quotidien`** — Ce qui est interdit au quotidien, et ce qu'on risque
  > Les comportements que la loi française interdit dans la vie de tous les jours, et la sanction encourue. C'est la notion qui répond à « est-ce que j'ai le droit de… ? ». ENTRE : fumer dans un lieu public fermé ; vendre de l'alcool à un mineur ; conduire alcoolisé ; ne pas porter la ceinture ; consommer du cannabis ; voler ; frapper ; les propos et actes racistes ; le harcèlement sexuel, le viol ; « que risque une personne qui ne respecte pas la loi ». 🛑 N'ENTRE PAS : le principe abstrait derrière la sanction → « dd_infractions_peines ». 🛑 Ce qu'on doit FAIRE positivement (payer ses impôts, trier, témoigner) → « dd_devoirs_citoyen » : un interdit n'est pas une obligation. 🛑 La procédure après l'infraction → « dd_police_justice ».
- **`dd_police_justice`** — Police, justice : mes droits quand la loi s'applique à moi
  > Ce que la police peut faire et ne pas faire, ce qu'une personne contrôlée ou poursuivie peut exiger, et comment une victime obtient réparation. ENTRE : contrôle et fouille, garde à vue et sa durée, droit au silence, interdiction de l'arrestation sans motif ; droit à un avocat et droits de la défense ; procès équitable ; présomption d'innocence ; aide juridictionnelle ; recours effectif ; porter plainte, se constituer partie civile, être indemnisé. 🛑 N'ENTRE PAS : les numéros d'urgence et LE RÔLE de la police et de la gendarmerie → « vs_urgences_secours », thème CIV_SOCIETE. LA RÈGLE : ce que FONT les forces de l'ordre est un service ; ce que je peux LEUR OPPOSER est un droit. 🛑 La définition de l'infraction et de la peine → « dd_infractions_peines ». 🛑 Le devoir de respecter une décision de justice → « dd_devoirs_citoyen ».
- **`dd_devoirs_citoyen`** — Les devoirs du citoyen : la loi, l'impôt, la défense, l'environnement
  > Ce que la République attend de chacun en retour des droits qu'elle garantit : obéir à la loi, contribuer, servir, protéger. ENTRE : respecter la loi et les décisions de justice ; L'OBLIGATION INDIVIDUELLE DE PAYER SES IMPÔTS — y compris « doit-on payer ses impôts ? » et « tout le monde paie-t-il des impôts ? », qui portent sur l'ÉTENDUE de cette obligation et donc sur le devoir lui-même ; dire la vérité comme témoin ; la Journée défense et citoyenneté, l'objection de conscience ; la probité de l'agent public ; le devoir de protéger l'environnement et le tri ; les devoirs constitutionnels ; le devoir de fraternité. 🛑 N'ENTRE PAS : les INTERDITS → « dd_interdits_quotidien » : un devoir est une obligation d'AGIR, pas une abstention. 🛑 L'ORGANISATION, LA COLLECTE, LE BUDGET et le fonctionnement fiscal de l'État — quel impôt finance quoi, qui perçoit, comment le budget se prépare et se contrôle → thème CIV_INSTITUTIONS. LA RÈGLE, ET ELLE TRANCHE SEULE : si la question porte sur CE QUE DOIT LE CITOYEN, c'est ici ; si elle porte sur CE QUE L'ÉTAT FAIT de l'impôt, c'est là-bas. Une question qui demande QUI est redevable, ou S'IL faut payer, est un devoir et reste ici. 🛑 Le droit à un environnement sain RESTE ICI avec son pendant l'obligation, parce que le corpus les énonce toujours ensemble.
- **`dd_vie_privee_famille`** — Vie privée, image, données personnelles et vie de famille
  > Ce qui appartient à la sphère intime d'une personne — son image, sa correspondance, ses données, ses choix de couple et de corps — et la protection que le droit y attache. ENTRE : le droit au respect de la vie privée ; le droit à l'image ; le secret des correspondances ; le secret professionnel et médical ; le RGPD et le droit à l'oubli ; la majorité civile ; le mariage, le mariage pour tous, le PACS ; l'IVG ; la fin de vie. 🛑 N'ENTRE PAS : la liberté d'expression et ses limites, même quand elles protègent autrui → « dd_libertes_limites ». 🛑 La protection de l'enfance (maltraitance, signalement) → « dd_droits_sociaux » : c'est un droit de l'enfant. 🛑 L'égalité femmes-hommes comme principe politique → « dd_textes_fondateurs ».
- **`dd_droits_sociaux`** — Travailler, se soigner, être logé, aller à l'école : les droits sociaux
  > Les droits que le préambule de 1946 et la loi reconnaissent à toute personne vivant en France dans sa vie matérielle : le travail, la santé, le logement, l'instruction, la protection de l'enfance. ENTRE : durée légale du travail, congés payés, SMIC, travail dissimulé, harcèlement moral, droit de grève, liberté syndicale ; protection maladie universelle et droit constitutionnel à la santé ; droit au logement opposable ; instruction obligatoire de 3 à 16 ans et gratuité de l'école ; protection de l'enfance (signalement, interdiction des violences éducatives). 🛑 N'ENTRE PAS : les DÉMARCHES pour obtenir ces droits → thème CIV_SOCIETE. LE TEST : un droit qu'on peut faire valoir DEVANT UN JUGE reste ici ; un formulaire à déposer à un GUICHET part là-bas. 🛑 Le devoir de payer ses cotisations → « dd_devoirs_citoyen ».

## Le référentiel — Vivre en société

- **`vs_ecole_scolarite`** — L'école et les études
  > Le système scolaire français : qui doit être instruit, jusqu'à quand, quels cycles, quels diplômes, et comment on s'y inscrit. ENTRE : obligation d'instruction de 3 à 16 ans ; maternelle, élémentaire, collège, lycée ; brevet, bac, CAP, bac pro ; alternance, apprentissage, Parcoursup ; inscription, assiduité, cantine. 🛑 N'ENTRE PAS : la LAÏCITÉ à l'école (loi de 2004, Charte de 2013) → « pv_laicite ». 🛑 Le DROIT à l'éducation comme droit fondamental → « dd_droits_sociaux ». 🛑 La formation professionnelle de l'adulte → « vs_emploi_formation ».
- **`vs_sante_soins`** — Se soigner : médecin, Sécu, remboursements
  > Le parcours de soins ordinaire et son remboursement : à qui on s'adresse, avec quelle carte, qui paie quoi. ENTRE : carte Vitale, CPAM, médecin traitant, pharmacien, mutuelle, protection universelle maladie, arrêt maladie, vaccinations obligatoires. 🛑 N'ENTRE PAS : l'AME et la C2S → « vs_protection_sociale_aides » : prestations sous condition de ressources. 🛑 La médecine du travail → « vs_travail_entreprise ». 🛑 L'IVG, la PMA, la GPA → « vs_famille_etat_civil ». 🛑 Le DROIT à la santé → « dd_droits_sociaux ».
- **`vs_travail_contrat_salaire`** — Le contrat de travail et le salaire
  > La relation individuelle employeur-salarié : quel contrat, quel salaire, quelle durée, comment ça se rompt. ENTRE : CDI, CDD, SMIC, brut et net, 35 heures, préavis, démission, rupture conventionnelle, congés maternité et paternité, âge minimum pour travailler, travail non déclaré, CESU. 🛑 N'ENTRE PAS : tout ce qui est COLLECTIF (CSE, syndicats, convention collective, inspection du travail) → « vs_travail_entreprise ». 🛑 CHERCHER un emploi ou se former → « vs_emploi_formation ». 🛑 Cotisations et retraite → « vs_protection_sociale_aides ». 🛑 Le droit au travail et la non-discrimination à l'embauche → « dd_droits_sociaux ».
- **`vs_travail_entreprise`** — Les salariés dans l'entreprise
  > Ce qui se joue collectivement dans l'entreprise : qui représente les salariés, qui négocie, qui contrôle, et ce que l'entreprise redistribue. ENTRE : CSE, syndicats représentatifs, convention collective, inspection du travail, médecine du travail, participation aux bénéfices, PEE, AGS. 🛑 N'ENTRE PAS : le contrat individuel et le salaire → « vs_travail_contrat_salaire ». 🛑 Le droit de grève et la liberté syndicale COMME LIBERTÉS PUBLIQUES → « dd_droits_sociaux ». 🛑 Les conquêtes sociales historiques (1936, 1945) → « hg_conquetes_droits ».
- **`vs_emploi_formation`** — Chercher un emploi, se former, créer son activité
  > Ce qu'on fait quand on n'a pas (encore) d'emploi, ou qu'on veut en changer : les organismes, les droits à la formation, la création d'activité. ENTRE : France Travail, CPF, micro-entrepreneur, service civique, reconnaissance de diplômes. 🛑 N'ENTRE PAS : le contrat une fois signé → « vs_travail_contrat_salaire ». 🛑 L'allocation chômage et le RSA → « vs_protection_sociale_aides ». 🛑 L'alternance sous statut scolaire → « vs_ecole_scolarite ».
- **`vs_protection_sociale_aides`** — La protection sociale et les aides
  > Le filet social français : qui le finance, et quelles prestations on peut toucher selon sa situation. ENTRE : Sécurité sociale, cotisations, URSSAF, retraite, État-providence ; CAF, RSA, prime d'activité, APL, AAH, MDPH, C2S, AME ; LOGEMENT SOCIAL et HLM. 🛑 N'ENTRE PAS : le remboursement ORDINAIRE des soins (carte Vitale, médecin traitant, mutuelle) → « vs_sante_soins ». 🛑 Les droits sociaux du préambule de 1946 → « dd_droits_sociaux ». 🛑 La création de la Sécurité sociale en 1945 COMME ÉVÉNEMENT → « hg_conquetes_droits ».
- **`vs_famille_etat_civil`** — La famille, le couple et l'état civil
  > Comment le droit français organise le couple, les enfants, la majorité et la transmission, et ce qu'il autorise ou interdit sur le corps. ENTRE : mariage civil (conditions, âge, égalité des époux, régimes matrimoniaux), PACS, autorité parentale, émancipation, majorité, crèche, acte de naissance, tutelle, mandat de protection future, réserve héréditaire, PMA, IVG, GPA. 🛑 N'ENTRE PAS : l'égalité femmes-hommes COMME PRINCIPE RÉPUBLICAIN → thème CIV_PRINCIPES. 🛑 Les violences conjugales et leur répression → « dd_interdits_quotidien ». 🛑 Le droit de vote à 18 ans, qui est la majorité CIVIQUE → « inst_elections ». 🛑 La carte d'identité → « vs_papiers_identite ».
- **`vs_sejour_asile`** — Le séjour des étrangers et l'asile
  > Les titres qui autorisent un étranger à vivre en France, l'accompagnement à l'intégration, et la protection internationale. ENTRE : titre de séjour, carte pluriannuelle, carte de résident, niveaux de français exigés, OFII, contrat d'intégration républicaine, TCF/DELF ; asile : GUDA, OFPRA, statut de réfugié contre protection subsidiaire, règlement Dublin. 🛑 N'ENTRE PAS : DEVENIR FRANÇAIS → « vs_nationalite_francaise ». LA FRONTIÈRE : avoir le droit de rester (ici) contre devenir français (là-bas). 🛑 Les droits de l'étranger, la double peine, l'éloignement → thème CIV_DROITS_DEVOIRS. 🛑 Frontex et l'agence européenne d'asile → thème CIV_INSTITUTIONS.
- **`vs_nationalite_francaise`** — Devenir français
  > Les voies d'accès à la nationalité française, leurs conditions, et ce qui accompagne son obtention. ENTRE : droit du sol, droit du sang, naturalisation (critères, examen civique 2026, B2), déclaration après mariage, double nationalité, cérémonie d'accueil, Charte des droits et devoirs, adhésion aux valeurs, perte de la nationalité. 🛑 N'ENTRE PAS : le séjour régulier qui précède → « vs_sejour_asile ». 🛑 Les VALEURS RÉPUBLICAINES EN ELLES-MÊMES → thème CIV_PRINCIPES : ici on ne garde que « ce à quoi le candidat doit adhérer ». 🛑 Les droits du citoyen une fois français → thème CIV_DROITS_DEVOIRS.
- **`vs_papiers_identite`** — Ses papiers et les guichets de l'administration
  > Les documents qui prouvent qui on est, comment on les obtient, les renouvelle, les remplace, et où l'on s'adresse pour une démarche. ENTRE : carte nationale d'identité et sa validité, passeport, perte ou vol, document attestant la nationalité, documents pour voyager, service-public.fr et le 39 39, centre des impôts. 🛑 N'ENTRE PAS : le titre de séjour → « vs_sejour_asile ». 🛑 L'acte de naissance et l'état civil → « vs_famille_etat_civil ». 🛑 La carte Vitale → « vs_sante_soins ». 🛑 C'est ce qui reste de l'ancienne notion « démarches administratives » UNE FOIS VIDÉE : ne jamais y remettre du séjour, de la nationalité ou des aides.
- **`vs_urgences_secours`** — Urgences, secours et forces de l'ordre
  > Qui intervient en cas d'urgence ou de danger, quel numéro composer, et ce que font la police et la gendarmerie au quotidien. ENTRE : le 15, le 17, le 18, le 112, le 119, le 116 000, le 3919 ; la gratuité et l'accessibilité 24 h/24 ; LE RÔLE de la police nationale et de la gendarmerie, et leur répartition urbain-rural. 🛑 N'ENTRE PAS : ce que je peux OPPOSER à un policier — contrôle, fouille, garde à vue, droit au silence, arrestation sans motif, porter plainte → thème CIV_DROITS_DEVOIRS. LA RÈGLE : ce que FONT les forces de l'ordre est un service ; ce que je peux LEUR OPPOSER est un droit. 🛑 Le parcours de soins non urgent → « vs_sante_soins ». 🛑 Le signalement d'un enfant en danger, qui est un DEVOIR → « dd_droits_sociaux ».
- **`vs_deplacements_route`** — Se déplacer : permis, sécurité routière, transports
  > Conduire légalement en France et se déplacer au quotidien : les permis, leurs âges, les obligations de sécurité. ENTRE : permis B, permis moto A1/A2/A, conduite accompagnée, permis à points, casque à vélo, équipement obligatoire du véhicule, transports en commun urbains. 🛑 N'ENTRE PAS : les infractions routières et leurs sanctions, l'alcool au volant → « dd_interdits_quotidien ». 🛑 Les numéros de secours après un accident → « vs_urgences_secours ». 🛑 Le réseau ferré et l'aménagement du territoire → « hg_geographie ».

---

## Les quatre gestes

| Geste | Quand | Ce que ça enregistre |
|---|---|---|
| **Valider** | la notion proposée est la bonne | `VALIDATED` + le tag posé |
| **Corriger** | une autre notion convient mieux | `CORRECTED` + le tag posé |
| **Rejeter** | aucune ne convient, et le modèle en proposait une | `REJECTED`, aucun tag |
| **Passer** | tu ne tranches pas maintenant | `SKIPPED`, la question reste dans la file |

Sur une question **sans notion proposée**, « Valider » devient **« Confirmer le trou »** : tu confirmes que le modèle a raison, aucun tag n'est posé, et la question remonte dans la métrique des trous du référentiel.

🛑 **Tu n'écris jamais `VALIDATED` ni `CORRECTED` toi-même** : le serveur les déduit en comparant ta notion à la mieux notée. C'est ce qui rend la mesure de qualité du modèle incontestable.

---

## 1 — Les hésitantes (0,70 – 0,89) — 4 questions

C'est ici que ta relecture apporte le plus. Le modèle le dit lui-même : il n'est pas sûr. Quand une alternative est donnée, c'est souvent elle le vrai débat.

### 1. Lequel de ces droits est un droit fondamental ?

*Droits et devoirs · Carte de résident*

- La liberté ← **bonne réponse**
- Le droit à la voiture
- Le droit aux vacances
- Le droit à un smartphone

**Explication de la question** — Le droit à la liberté, le droit à la sûreté, le droit à la propriété sont des droits fondamentaux inscrits dans la Déclaration de 1789.

**Proposition du modèle — `dd_libertes_limites`** (Les libertés individuelles et leurs limites) · confiance **0.70**
> Liberté comme droit fondamental relève du contenu des libertés.

**Alternative du modèle — `dd_textes_fondateurs`** (La Déclaration de 1789 et les textes qui garantissent nos droits) · confiance **0.60**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 2. En France, qui est tenu de respecter la loi ?

*Droits et devoirs · Carte de séjour pluriannuelle*

- Toute personne présente sur le territoire ← **bonne réponse**
- Uniquement les Français
- Uniquement les adultes
- Uniquement les personnes condamnées

**Explication de la question** — Tout le monde, sans exception : citoyens, résidents, dirigeants politiques, agents publics. La loi s'applique de la même manière à tous.

**Proposition du modèle — `dd_devoirs_citoyen`** (Les devoirs du citoyen : la loi, l'impôt, la défense, l'environnement) · confiance **0.85**
> Obligation de respecter la loi pour tous.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 3. En quoi consiste la traite des êtres humains ?

*Droits et devoirs · Naturalisation*

- Exploiter une personne par la force (travail forcé, prostitution...) ← **bonne réponse**
- Un type de commerce légal
- L'immigration légale
- L'accueil des réfugiés

**Explication de la question** — La traite des êtres humains consiste à exploiter une personne (travail forcé, prostitution, esclavage...) par la contrainte. C'est un crime grave puni par la loi.

**Proposition du modèle — `dd_infractions_peines`** (L'infraction et la peine : du principe de légalité aux interdits absolus) · confiance **0.85**
> Traite des êtres humains, interdit absolu, principe pénal.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 4. Qui doit respecter la loi ?

*Droits et devoirs · Carte de séjour pluriannuelle*

- Toute personne présente sur le territoire français ← **bonne réponse**
- Uniquement les citoyens français
- Uniquement les majeurs
- Uniquement les personnes salariées

**Explication de la question** — Toute personne présente sur le territoire français doit respecter la loi : citoyens français, étrangers, résidents, touristes, dirigeants politiques.

**Proposition du modèle — `dd_devoirs_citoyen`** (Les devoirs du citoyen : la loi, l'impôt, la défense, l'environnement) · confiance **0.85**
> Qui doit respecter la loi relève du devoir de respecter la loi.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

## 2 — Les sûres (≥ 0,90) — 40 questions

Elles devraient s'enchaîner vite — c'est précisément ce qu'on cherche à mesurer : est-ce que « sûr » veut dire « juste » ?

### 5. À partir de quel âge un mineur peut-il travailler ?

*Vivre en société · Carte de résident*

- À partir de 16 ans (avec accord parental) ← **bonne réponse**
- À partir de 18 ans seulement
- À partir de 12 ans
- À tout âge, sans restriction

**Explication de la question** — Un mineur peut travailler à partir de 16 ans (avec autorisation parentale). Dès 14 ans, il peut faire des petits travaux pendant les vacances scolaires sous conditions strictes.

**Proposition du modèle — `vs_travail_contrat_salaire`** (Le contrat de travail et le salaire) · confiance **0.90**
> Âge minimum pour travailler

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 6. Comment s'appelle le texte qui énonce les droits et devoirs des personnes résidant en France ?

*Droits et devoirs · Carte de résident*

- La Charte des droits et devoirs du citoyen français ← **bonne réponse**
- Le Code civil
- La Bible
- Le Code du travail

**Explication de la question** — La Charte des droits et devoirs du citoyen français, établie en 2012, rappelle les principes fondamentaux et les valeurs essentielles de la République.

**Proposition du modèle — `dd_textes_fondateurs`** (La Déclaration de 1789 et les textes qui garantissent nos droits) · confiance **0.90**
> La Charte des droits et devoirs du citoyen est explicitement dans dd_textes_fondateurs.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 7. En France, peut-on être arrêté sans motif précis ?

*Droits et devoirs · Carte de séjour pluriannuelle*

- Non, il faut un motif légal ← **bonne réponse**
- Oui, sans aucune raison
- Oui, sur ordre du maire
- Oui, le week-end uniquement

**Explication de la question** — Non. Toute privation de liberté doit avoir un fondement légal. La police judiciaire ne peut placer en garde à vue qu'une personne soupçonnée d'avoir commis ou tenté une infraction.

**Proposition du modèle — `dd_police_justice`** (Police, justice : mes droits quand la loi s'applique à moi) · confiance **0.90**
> Interdiction de l'arrestation sans motif, droit face à la police.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 8. Le travail non déclaré est :

*Vivre en société · Carte de résident*

- Interdit et puni par la loi ← **bonne réponse**
- Autorisé pour les petits emplois
- Sans conséquence
- Encouragé par l'État

**Explication de la question** — Le travail non déclaré (travail au noir) est illégal. Il prive le travailleur de droits sociaux (chômage, retraite, sécurité sociale) et expose employeur et salarié à des sanctions.

**Proposition du modèle — `vs_travail_contrat_salaire`** (Le contrat de travail et le salaire) · confiance **0.90**
> Travail non déclaré, relation individuelle salarié-employeur

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 9. Quel droit permet à une personne de se défendre devant la justice ?

*Droits et devoirs · Carte de résident*

- Le droit à la défense (et à un avocat) ← **bonne réponse**
- Le droit de vote
- Le droit de propriété
- Le droit à la santé

**Explication de la question** — Le droit à la défense (et le droit à un avocat) est un principe fondamental. Toute personne accusée a le droit d'être défendue, présumée innocente jusqu'à preuve du contraire.

**Proposition du modèle — `dd_police_justice`** (Police, justice : mes droits quand la loi s'applique à moi) · confiance **0.90**
> Droit à la défense et à un avocat en procédure judiciaire.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 10. Quel texte a été adopté pendant la Révolution française ?

*Droits et devoirs · Carte de résident*

- La Déclaration des droits de l'homme et du citoyen ← **bonne réponse**
- Le Traité de Rome
- La Constitution de la Ve République
- La loi de 1905

**Explication de la question** — La Déclaration des droits de l'homme et du citoyen a été adoptée le 26 août 1789 par l'Assemblée nationale constituante, pendant la Révolution.

**Proposition du modèle — `dd_textes_fondateurs`** (La Déclaration de 1789 et les textes qui garantissent nos droits) · confiance **0.90**
> DDHC adoptée pendant la Révolution, texte fondateur.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 11. Quelle liberté permet à une personne de ne pas avoir de religion ?

*Droits et devoirs · Carte de résident*

- La liberté de conscience ← **bonne réponse**
- La liberté du commerce
- La liberté de la presse
- La liberté de circulation

**Explication de la question** — La liberté de conscience, garantie par la laïcité, permet de croire, de ne pas croire ou de changer de religion.

**Proposition du modèle — `dd_libertes_limites`** (Les libertés individuelles et leurs limites) · confiance **0.90**
> Liberté de conscience explicitement citée dans dd_libertes_limites.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 12. Auprès de quel organisme faut-il demander le remboursement des frais de santé ?

*Vivre en société · Carte de résident*

- L'Assurance Maladie (CPAM) ← **bonne réponse**
- La mairie
- La préfecture
- France Travail

**Explication de la question** — Les remboursements de frais de santé sont assurés par l'Assurance Maladie (CPAM - Caisse Primaire d'Assurance Maladie), qui fait partie de la Sécurité sociale.

**Proposition du modèle — `vs_sante_soins`** (Se soigner : médecin, Sécu, remboursements) · confiance **0.95**
> Remboursement des soins via CPAM

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 13. Comment un mineur étranger né en France acquiert-il la nationalité française ?

*Vivre en société · Naturalisation*

- Automatiquement à 18 ans sous condition de résidence ← **bonne réponse**
- À la naissance automatiquement
- Jamais
- À 25 ans uniquement

**Explication de la question** — L'enfant né en France de parents étrangers acquiert automatiquement la nationalité française à sa majorité, s'il réside en France depuis l'âge de 11 ans (au moins 5 ans). Peut être anticipée dès 13 ans.

**Proposition du modèle — `vs_nationalite_francaise`** (Devenir français) · confiance **0.95**
> Acquisition automatique par droit du sol à majorité

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 14. Concernant les limites aux libertés individuelles, quelle proposition est correcte ?

*Droits et devoirs · Naturalisation*

- Les libertés ont des limites fixées par la loi ← **bonne réponse**
- Les libertés sont absolues, sans limite
- Les libertés ne s'appliquent qu'au domicile privé
- Il n'existe pas de libertés individuelles en France

**Explication de la question** — Les libertés individuelles ne sont jamais absolues : elles s'arrêtent là où commencent celles des autres, et sont encadrées par la loi pour protéger l'ordre public et autrui.

**Proposition du modèle — `dd_libertes_limites`** (Les libertés individuelles et leurs limites) · confiance **0.95**
> Limites des libertés fixées par la loi, coeur de la notion.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 15. De quelle année date la Déclaration des droits de l'homme et du citoyen ?

*Droits et devoirs · Carte de résident*

- 1789 ← **bonne réponse**
- 1848
- 1905
- 1958

**Explication de la question** — La Déclaration des droits de l'homme et du citoyen a été adoptée le 26 août 1789, pendant la Révolution française. Elle a valeur constitutionnelle.

**Proposition du modèle — `dd_textes_fondateurs`** (La Déclaration de 1789 et les textes qui garantissent nos droits) · confiance **0.95**
> Date de la DDHC, texte fondateur.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 16. Parmi ces textes, lequel garantit les droits et libertés en France ?

*Droits et devoirs · Carte de résident*

- La Déclaration des droits de l'homme et du citoyen ← **bonne réponse**
- Le Code de la route
- Le manuel scolaire
- Le journal officiel

**Explication de la question** — La Déclaration des droits de l'homme et du citoyen de 1789, intégrée au "bloc de constitutionnalité", garantit les droits et libertés fondamentales.

**Proposition du modèle — `dd_textes_fondateurs`** (La Déclaration de 1789 et les textes qui garantissent nos droits) · confiance **0.95**
> DDHC comme texte garantissant les droits.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 17. Pour quelles raisons les libertés individuelles peuvent-elles être encadrées par la loi ?

*Droits et devoirs · Naturalisation*

- Pour protéger l'ordre public, la santé, les droits des autres ← **bonne réponse**
- Pour faire plaisir au gouvernement
- Pour des raisons religieuses
- Pour réduire les dépenses publiques

**Explication de la question** — Les libertés individuelles peuvent être limitées pour protéger l'ordre public, la sécurité, la santé publique, les droits d'autrui ou prévenir les atteintes à la dignité.

**Proposition du modèle — `dd_libertes_limites`** (Les libertés individuelles et leurs limites) · confiance **0.95**
> Motifs d'encadrement légal des libertés individuelles.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 18. Pourquoi les libertés individuelles peuvent-elles être limitées ?

*Droits et devoirs · Naturalisation*

- Pour protéger les droits des autres et l'ordre public ← **bonne réponse**
- Selon le bon vouloir du président
- Pour favoriser une religion
- Pour limiter le travail des étrangers

**Explication de la question** — Les libertés peuvent être limitées pour protéger l'ordre public, la sécurité, la santé ou les libertés d'autrui. Ces limites doivent être proportionnées et fixées par la loi.

**Proposition du modèle — `dd_libertes_limites`** (Les libertés individuelles et leurs limites) · confiance **0.95**
> Motifs de limitation des libertés individuelles.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 19. Qu'est-ce qu'un numéro d'urgence ?

*Vivre en société · Carte de séjour pluriannuelle*

- Un numéro gratuit pour contacter les secours ← **bonne réponse**
- Le numéro personnel du président
- Le numéro de la mairie
- Le numéro pour réserver un taxi

**Explication de la question** — Un numéro d'urgence est un numéro gratuit que l'on peut appeler en cas de situation grave : 15 (SAMU), 17 (Police), 18 (Pompiers), 112 (numéro européen).

**Proposition du modèle — `vs_urgences_secours`** (Urgences, secours et forces de l'ordre) · confiance **0.95**
> Définition générale des numéros d'urgence

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 20. Qu'est-ce que la liberté d'expression ?

*Droits et devoirs · Carte de résident*

- Le droit d'exprimer ses opinions dans le respect de la loi ← **bonne réponse**
- Le droit de dire tout sans limite
- L'interdiction de parler en public
- Une liberté réservée aux journalistes

**Explication de la question** — La liberté d'expression est le droit de dire, écrire ou publier ses opinions, dans le respect des lois (pas d'injures, de diffamation, d'incitation à la haine).

**Proposition du modèle — `dd_libertes_limites`** (Les libertés individuelles et leurs limites) · confiance **0.95**
> Liberté d'expression et ses limites.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 21. Qu'est-ce que le SMIC ?

*Vivre en société · Carte de résident*

- Le salaire minimum légal en France ← **bonne réponse**
- Un impôt payé par les salariés
- Le nom d'une assurance
- Une aide sociale pour les chômeurs

**Explication de la question** — Le SMIC (Salaire Minimum Interprofessionnel de Croissance) est le salaire horaire minimum légal en dessous duquel un employeur ne peut pas payer un salarié.

**Proposition du modèle — `vs_travail_contrat_salaire`** (Le contrat de travail et le salaire) · confiance **0.95**
> Définition du SMIC

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 22. Que désigne la 'double nationalité' en droit français ?

*Vivre en société · Naturalisation*

- Posséder la nationalité française et une autre nationalité ← **bonne réponse**
- Être marié deux fois
- Avoir deux passeports d'un même pays
- Être apatride

**Explication de la question** — La France autorise la double (ou multiple) nationalité : un Français peut conserver ou acquérir une autre nationalité. Tous les pays ne l'autorisent pas (certains exigent de renoncer à la nationalité d'origine).

**Proposition du modèle — `vs_nationalite_francaise`** (Devenir français) · confiance **0.95**
> Double nationalité

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 23. Que dit le droit français sur les limites possibles aux libertés individuelles ?

*Droits et devoirs · Naturalisation*

- Elles peuvent être limitées par la loi pour l'ordre public et les droits d'autrui ← **bonne réponse**
- Elles sont absolues sans limite
- Elles n'existent pas
- Elles dépendent du maire

**Explication de la question** — Les libertés individuelles ne sont pas absolues. Elles peuvent être limitées par la loi pour protéger l'ordre public, les droits d'autrui ou la sécurité nationale.

**Proposition du modèle — `dd_libertes_limites`** (Les libertés individuelles et leurs limites) · confiance **0.95**
> Limites légales aux libertés individuelles.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 24. Que doit faire un employeur pour fixer un salaire ?

*Vivre en société · Carte de résident*

- Respecter au minimum le SMIC ← **bonne réponse**
- Décider seul du montant
- Payer ce que le salarié demande
- Adapter le salaire au sexe du salarié

**Explication de la question** — L'employeur doit respecter le SMIC (salaire minimum légal) et la convention collective applicable. Le salaire ne peut être inférieur au SMIC.

**Proposition du modèle — `vs_travail_contrat_salaire`** (Le contrat de travail et le salaire) · confiance **0.95**
> SMIC, fixation du salaire

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 25. Quel est le rôle de la gendarmerie ?

*Vivre en société · Carte de résident*

- Assurer la sécurité, principalement en zone rurale ← **bonne réponse**
- Voter les lois
- Éduquer les enfants
- Faire la guerre à l'étranger

**Explication de la question** — La gendarmerie assure la sécurité publique, principalement en zone rurale et périurbaine. Elle exerce des missions de police judiciaire et administrative, sous tutelle du ministère de l'Intérieur.

**Proposition du modèle — `vs_urgences_secours`** (Urgences, secours et forces de l'ordre) · confiance **0.95**
> Rôle de la gendarmerie, service des forces de l'ordre

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 26. Quel est le rôle de la police ?

*Vivre en société · Carte de séjour pluriannuelle*

- Assurer la sécurité et faire respecter la loi ← **bonne réponse**
- Juger les criminels
- Voter les lois
- Éduquer les enfants

**Explication de la question** — La police nationale assure la sécurité des personnes et des biens, principalement en zone urbaine. Elle prévient et constate les infractions, fait respecter l'ordre public.

**Proposition du modèle — `vs_urgences_secours`** (Urgences, secours et forces de l'ordre) · confiance **0.95**
> Rôle de la police nationale

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 27. Quel est le texte fondateur établissant en France les droits et les devoirs de chaque citoyen ?

*Droits et devoirs · Naturalisation*

- La Déclaration des droits de l'homme et du citoyen (1789) ← **bonne réponse**
- Le Code de la santé publique
- Le Traité de Rome
- La Charte des Nations unies

**Explication de la question** — La Déclaration des droits de l'homme et du citoyen de 1789 est le texte fondateur des droits et libertés en France. Elle reste intégrée à la Constitution actuelle.

**Proposition du modèle — `dd_textes_fondateurs`** (La Déclaration de 1789 et les textes qui garantissent nos droits) · confiance **0.95**
> DDHC 1789 comme texte fondateur des droits/devoirs.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 28. Quel texte historique établit les droits et devoirs fondamentaux des citoyens en France ?

*Droits et devoirs · Naturalisation*

- La Déclaration des droits de l'homme et du citoyen de 1789 ← **bonne réponse**
- Le Code Napoléon
- La Magna Carta
- La Charte de l'environnement

**Explication de la question** — La Déclaration des droits de l'homme et du citoyen de 1789 est le texte fondateur. Elle est intégrée au bloc de constitutionnalité et a aujourd'hui valeur constitutionnelle.

**Proposition du modèle — `dd_textes_fondateurs`** (La Déclaration de 1789 et les textes qui garantissent nos droits) · confiance **0.95**
> DDHC 1789 comme texte fondateur des droits et devoirs.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 29. Quelle cérémonie marque l'obtention de la nationalité française par naturalisation ?

*Vivre en société · Naturalisation*

- Une cérémonie d'accueil en préfecture ← **bonne réponse**
- Une visite à l'Élysée
- Une fête au village d'origine
- Aucune cérémonie

**Explication de la question** — Une cérémonie d'accueil dans la citoyenneté française est organisée en préfecture. Les nouveaux Français y reçoivent leur décret de naturalisation et la Charte des droits et devoirs du citoyen français.

**Proposition du modèle — `vs_nationalite_francaise`** (Devenir français) · confiance **0.95**
> Cérémonie d'accueil dans la nationalité

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 30. Quelle est la durée légale du temps de travail par semaine ?

*Vivre en société · Carte de séjour pluriannuelle*

- 35 heures ← **bonne réponse**
- 40 heures
- 48 heures
- 30 heures

**Explication de la question** — La durée légale du temps de travail en France est de 35 heures par semaine pour un temps plein, depuis les lois Aubry de 2000.

**Proposition du modèle — `vs_travail_contrat_salaire`** (Le contrat de travail et le salaire) · confiance **0.95**
> Durée légale du temps de travail, 35h

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 31. Qui est aidé par France Travail ?

*Vivre en société · Carte de résident*

- Les demandeurs d'emploi ← **bonne réponse**
- Les retraités
- Les élèves d'école primaire
- Les touristes étrangers

**Explication de la question** — France Travail (ex-Pôle Emploi) accompagne les demandeurs d'emploi : inscription, recherche d'emploi, indemnités, formation. Les entreprises peuvent également être aidées dans leurs recrutements.

**Proposition du modèle — `vs_emploi_formation`** (Chercher un emploi, se former, créer son activité) · confiance **0.95**
> France Travail, recherche d'emploi

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 32. Toute personne accusée est-elle considérée comme coupable avant son jugement ?

*Droits et devoirs · Carte de séjour pluriannuelle*

- Non, elle bénéficie de la présomption d'innocence ← **bonne réponse**
- Oui, automatiquement
- Cela dépend du juge
- Cela dépend de la commune

**Explication de la question** — Non. La présomption d'innocence est un principe fondamental : toute personne est considérée comme innocente tant qu'elle n'a pas été jugée coupable.

**Proposition du modèle — `dd_police_justice`** (Police, justice : mes droits quand la loi s'applique à moi) · confiance **0.95**
> Présomption d'innocence, procédure judiciaire.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 33. Une personne accusée d'un délit a-t-elle le droit à un avocat ?

*Droits et devoirs · Carte de séjour pluriannuelle*

- Oui, et l'aide juridictionnelle existe pour les plus modestes ← **bonne réponse**
- Non, jamais
- Uniquement les hommes y ont droit
- Uniquement si le délit est léger

**Explication de la question** — Oui. Toute personne mise en cause a le droit d'être défendue par un avocat. Si elle n'a pas les moyens, elle peut bénéficier de l'aide juridictionnelle (avocat aux frais de l'État).

**Proposition du modèle — `dd_police_justice`** (Police, justice : mes droits quand la loi s'applique à moi) · confiance **0.95**
> Droit à l'avocat et aide juridictionnelle, procédure judiciaire.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 34. À quelles conditions un mariage est-il reconnu juridiquement en France ?

*Vivre en société · Carte de résident*

- S'il est célébré à la mairie par un officier d'état civil ← **bonne réponse**
- S'il est célébré dans un lieu religieux
- Si les parents donnent leur accord
- S'il est annoncé dans le journal

**Explication de la question** — Un mariage est juridiquement reconnu en France uniquement s'il est célébré par un officier d'état civil (le maire ou son adjoint) à la mairie. Les mariages religieux n'ont pas de valeur civile.

**Proposition du modèle — `vs_famille_etat_civil`** (La famille, le couple et l'état civil) · confiance **0.96**
> Conditions de reconnaissance juridique du mariage

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 35. Que désigne l'OFPRA ?

*Vivre en société · Naturalisation*

- L'organisme qui examine les demandes d'asile ← **bonne réponse**
- Un syndicat
- Un parti politique
- Une banque

**Explication de la question** — L'Office français de protection des réfugiés et apatrides examine les demandes d'asile et accorde le statut de réfugié ou la protection subsidiaire en France.

**Proposition du modèle — `vs_sejour_asile`** (Le séjour des étrangers et l'asile) · confiance **0.96**
> OFPRA, demandes d'asile

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 36. Que désigne la 'déclaration de nationalité française' après un mariage ?

*Vivre en société · Naturalisation*

- Acquisition de la nationalité après mariage avec un Français (4 ans en général) ← **bonne réponse**
- Une déclaration au consulat
- Un divorce
- Aucune procédure

**Explication de la question** — Un étranger marié à un Français peut acquérir la nationalité française par déclaration après 4 ans de mariage (5 si la communauté de vie n'a pas commencé en France ou si l'époux ne réside pas en France).

**Proposition du modèle — `vs_nationalite_francaise`** (Devenir français) · confiance **0.96**
> Déclaration de nationalité après mariage

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 37. Quel diplôme obtient-on à la fin du lycée ?

*Vivre en société · Carte de séjour pluriannuelle*

- Le baccalauréat (bac) ← **bonne réponse**
- Le brevet
- La licence
- Le master

**Explication de la question** — À la fin du lycée, les élèves passent le baccalauréat (le "bac"), diplôme qui sanctionne la fin des études secondaires et permet de poursuivre dans l'enseignement supérieur.

**Proposition du modèle — `vs_ecole_scolarite`** (L'école et les études) · confiance **0.96**
> Diplôme du lycée : bac

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 38. Jusqu'à quel âge l'école est-elle obligatoire ?

*Vivre en société · Carte de séjour pluriannuelle*

- Jusqu'à 16 ans ← **bonne réponse**
- Jusqu'à 12 ans
- Jusqu'à 18 ans
- Jusqu'à 21 ans

**Explication de la question** — L'instruction est obligatoire de 3 à 16 ans en France (depuis 2019, l'âge d'entrée a été abaissé à 3 ans, contre 6 ans auparavant).

**Proposition du modèle — `vs_ecole_scolarite`** (L'école et les études) · confiance **0.97**
> Âge de l'obligation d'instruction

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 39. Pour qui l'école est-elle obligatoire ?

*Vivre en société · Carte de séjour pluriannuelle*

- Pour tous les enfants de 3 à 16 ans en France ← **bonne réponse**
- Uniquement pour les enfants français
- Uniquement pour les garçons
- Uniquement pour les enfants pauvres

**Explication de la question** — L'instruction est obligatoire pour tous les enfants de 3 à 16 ans résidant en France, qu'ils soient français ou étrangers, en situation régulière ou non.

**Proposition du modèle — `vs_ecole_scolarite`** (L'école et les études) · confiance **0.97**
> Obligation scolaire pour tous les enfants

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 40. Que désigne le 'droit du sang' en droit français ?

*Vivre en société · Naturalisation*

- Acquisition par filiation (parent français) ← **bonne réponse**
- Une transfusion sanguine
- Le droit à la chasse
- Le droit du commerce

**Explication de la question** — Le droit du sang attribue la nationalité française à un enfant si l'un de ses parents (au moins) est français, quel que soit le lieu de naissance.

**Proposition du modèle — `vs_nationalite_francaise`** (Devenir français) · confiance **0.97**
> Droit du sang

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 41. Que désigne le 'droit du sol' en droit français ?

*Vivre en société · Naturalisation*

- L'acquisition de la nationalité par naissance en France (sous conditions) ← **bonne réponse**
- Le droit de propriété immobilière
- Le droit à l'agriculture
- Le droit au logement

**Explication de la question** — Le droit du sol attribue automatiquement la nationalité française à un enfant né en France de parents étrangers, sous certaines conditions de résidence en France à sa majorité.

**Proposition du modèle — `vs_nationalite_francaise`** (Devenir français) · confiance **0.97**
> Droit du sol, voie d'accès à la nationalité

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 42. Quel numéro d'urgence permet d'appeler le SAMU ?

*Vivre en société · Carte de séjour pluriannuelle*

- Le 15 ← **bonne réponse**
- Le 17
- Le 18
- Le 112

**Explication de la question** — Le 15 est le numéro du SAMU (Service d'Aide Médicale Urgente). Il s'appelle en cas d'urgence médicale grave (malaise, accident, blessure...).

**Proposition du modèle — `vs_urgences_secours`** (Urgences, secours et forces de l'ordre) · confiance **0.97**
> Numéro d'urgence SAMU

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 43. Quel numéro d'urgence permet d'appeler les pompiers ?

*Vivre en société · Carte de séjour pluriannuelle*

- Le 18 ← **bonne réponse**
- Le 15
- Le 17
- Le 119

**Explication de la question** — Le 18 est le numéro des pompiers. Ils interviennent pour les incendies, les accidents, les secours d'urgence et les catastrophes.

**Proposition du modèle — `vs_urgences_secours`** (Urgences, secours et forces de l'ordre) · confiance **0.97**
> Numéro pompiers

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 44. Quels sont les critères pour obtenir la nationalité française par naturalisation ?

*Vivre en société · Naturalisation*

- Séjour, langue B2, connaissance société, ressources, intégrité ← **bonne réponse**
- Être né en France
- Avoir un parent français uniquement
- Aucun critère requis

**Explication de la question** — Pour la naturalisation : être majeur, justifier d'un séjour régulier en France (5 ans en général), maîtriser le français (niveau B2), connaître l'histoire/culture/société française, avoir des ressources, ne pas avoir de condamnation grave, adhérer aux valeurs républicaines.

**Proposition du modèle — `vs_nationalite_francaise`** (Devenir français) · confiance **0.97**
> Critères de naturalisation

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

## Annexe — les questions déjà tranchées

Elles ne sont pas à relire. Rappelées ici pour que la fiche dise l'état complet du pilote, et parce qu'une correction est plus instructive qu'une validation : elle montre où le modèle se trompe.

| Question | Le modèle proposait | Verdict | Tag posé |
|---|---|---|---|
| Le médiateur entre l'administration et les citoyens existe-t-il sous une forme officielle en France ? | `dd_police_justice · 0.70` | **REJECTED** | aucun |
| Tout le monde paie-t-il des impôts en France ? | `_aucune notion_ · 0.70` | **CORRECTED** | `dd_devoirs_citoyen` |
| Concernant les droits individuels, quelle proposition est correcte ? | `dd_textes_fondateurs · 0.70` | **CORRECTED** | `dd_libertes_limites` |
| Que risque une personne qui ne respecte pas la loi ? | `dd_interdits_quotidien · 0.75` | **CORRECTED** | `dd_infractions_peines` |
| Que risque une personne qui ne respecte pas la loi en France ? | `dd_interdits_quotidien · 0.75` | **CORRECTED** | `dd_infractions_peines` |
| Concernant l'accès aux soins, quelle proposition est correcte ? | `vs_sante_soins · 0.90` | **REJECTED** | aucun |

## Après la relecture

```bash
./scripts/pre-tagging/mesurer.sh PROMPT_TAG_NOTION_v4 \
  $(cat scripts/pre-tagging/batches_v4.txt)
```

Cette commande ne mesure QUE ces 50 questions : quand le job des 782 tournera, ses suggestions ne contamineront pas ces chiffres.
