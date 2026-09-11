# Référentiel civique — version finale soumise à validation

> 🛑 **Rien n'est exécuté.** Aucun `civic_notion_id` posé, aucune migration
> écrite, aucun pré-tagging relancé. Ce document est la **liste à valider**.
> 🛑 **Aucun appel LLM** n'a servi à le produire.

**46 notions** sur 5 thèmes, contre 41 aujourd'hui.

⚠️ **Tous les comptages sont des projections, pas des faits de base.** Aucune
question n'est taguée à ce jour : les chiffres viennent de la lecture manuelle
des 840 questions `CONNAISSANCE`, question par question. Ils seront exacts le
jour où le tagging sera fait — pas avant.

---

## 0. Les arbitrages, et ce qu'ils changent

| # | Arbitrage | Portée |
|---|---|---|
| 1 | Les notions **mono-mention sont autorisées** | Référentiel — c'est ce qui rend ces 46 notions possibles |
| 2 | Une notion **absente** d'une mention est `NON_APPLICABLE`, pas `CONTENU_INSUFFISANT` | 🔧 **Code backend**, après validation |
| 3 | Les `MISE_SITUATION` restent dans l'axe `sit_*` | Confirme le filtre `question_type = 'CONNAISSANCE'` déjà en place |
| 4 | À terme, le seuil de 5 porte sur **5 faits distincts** | 🔧 **Code backend**, chantier séparé |
| 5 | Le **préfet** reste dans `inst_gouvernement` | Référentiel — appliqué |
| 6 | **Urgences pratiques → Société** · **droits et procédure face à la police → Droits et devoirs** | Déplace **12 questions** — appliqué |
| 7 | **Symboles nationaux → Principes** · **symboles européens → UE** | Déplace **8 questions** — appliqué |

### Arbitrage 2 — la lecture que je propose

« Absente » se lit **zéro question**. D'où trois états et non deux :

| Questions dans la mention | État | Effet sur le Plan |
|---|---|---|
| **0** | `NON_APPLICABLE` | La notion n'existe pas pour ce candidat. Ni servie, ni pénalisée, ni comptée dans le dénominateur de sa couverture. |
| **1 à 4** | `CONTENU_INSUFFISANT` | Le sujet existe pour cette mention, il manque de la matière. Écartée des priorités, et **c'est le signal qui dit quoi écrire**. |
| **≥ 5** | servable | — |

🛑 **La distinction n'est pas cosmétique.** Sans elle, « Devenir français »
(0 question CSP) et « Les devoirs du citoyen » (4 questions NAT) reçoivent le
même verdict, alors que l'une n'a rien à faire chez un candidat CSP et que
l'autre attend **une seule question** pour être complète.

Dans tout ce document : **N/A** = zéro question · **⚠️ n** = 1 à 4 questions ·
**✅** = servable.

### Arbitrage 6 — les 12 questions déplacées

**`CIV_DROITS_DEVOIRS` → `CIV_SOCIETE` (9)** — les numéros et les secours :
le 15, le 18, le 112, « Quels sont les numéros d'urgence essentiels ? », le 3919,
« Quel est le rôle de la police ? » ×2, « Quel est le rôle de la gendarmerie ? » ×2.

**`CIV_INSTITUTIONS` → `CIV_SOCIETE` (3)** — « Que fait la police nationale ? »,
le 17, le 112 européen côté police.

**Restent dans `CIV_DROITS_DEVOIRS`** — tout ce qui est un droit ou une
procédure : être arrêté sans motif, la fouille d'un sac, le droit au silence,
la garde à vue, porter plainte, l'indemnisation de la victime, le signalement
d'un enfant en danger (le 119 y est cité, mais la question porte sur le devoir
de signaler).

⚠️ **Conséquence à connaître** : `dd_police_justice` tombe de 12 à **5 questions
CSP** — pile au seuil. Les deux questions que `CIV_INSTITUTIONS` doit lui céder
(présomption d'innocence, droit à un avocat) la remonteraient à 7, mais ce
déplacement-là n'est pas encore arbitré (§7).

### Arbitrage 7 — les 8 questions déplacées

**`CIV_HISTOIRE_GEO` → `CIV_PRINCIPES`** : le drapeau, le coq, l'hymne, Marianne,
la devise ×2, la langue officielle *(article 2 de la Constitution — l'article des
symboles)*, et le slogan de la Révolution. **7 en CSP, 1 en CR.**

**Aucun mouvement côté européen** : les 5 questions de drapeau, hymne et Journée
de l'Europe restent dans `inst_ue`, ce qui préserve son CSP à 7.

🛑 **C'est l'arbitrage le plus rentable des sept.** `CIV_PRINCIPES` n'avait que
19 questions CSP ; il en gagne 7 d'un coup, sans écrire une ligne.

### Le renommage demandé

`hg_napoleon_empires` → **`hg_napoleon_xixe`**, libellé **« Napoléon et la France
au XIXᵉ siècle »**.

⚠️ **Le nouveau libellé promet un peu plus que la notion ne contient**, et il
faut que sa description le dise : deux blocs du XIXᵉ siècle vivent ailleurs **par
construction**. La naissance de la IIIᵉ République (4 septembre 1870), la Commune
et l'affaire Dreyfus sont dans `hg_republiques` ; l'abolition de l'esclavage
(1848) et les lois scolaires (1881-82) sont dans `hg_conquetes_droits`. La
frontière est écrite dans le « n'entre pas » de la notion.

---

## 1. `CIV_HISTOIRE_GEO` — 12 notions, 203 questions

#### `hg_revolution` — **Les rois de France et la Révolution**
CSP **9** ✅ · CR **7** ✅ · NAT **5** ✅ — 21 questions

**Définition.** La France d'avant la République : le royaume, ses rois, et la Révolution de 1789 qui y met fin.
**Entre.** Les rois et l'Ancien Régime (Jeanne d'Arc, Henri IV, Louis XIV) ; 1789 et ses journées (Bastille, 4 août, Jeu de paume) ; les acteurs et la fin de la monarchie (Louis XVI, Marie-Antoinette, Robespierre, la Terreur) ; les Lumières.
**N'entre pas.** 🛑 Napoléon et tout ce qui suit 1799 → `hg_napoleon_xixe` : le 18 brumaire **ferme** la Révolution, il appartient à Napoléon. 🛑 « Liberté, Égalité, Fraternité » et les symboles → `CIV_PRINCIPES`. 🛑 Le 14 juillet **comme jour férié** → `hg_fetes_jours_feries`.

#### `hg_napoleon_xixe` — **Napoléon et la France au XIXᵉ siècle** *(nouvelle)*
CSP **N/A** · CR **5** ✅ · NAT **5** ✅ — 10 questions

**Définition.** De la prise de pouvoir de Bonaparte à la chute du Second Empire : les régimes non républicains du XIXᵉ siècle et ce qu'ils laissent à la France.
**Entre.** Napoléon Iᵉʳ (18 brumaire, Code civil, Waterloo) ; la Restauration et les Trois Glorieuses ; Napoléon III et le Second Empire ; la défaite de 1870, Sedan, la perte de l'Alsace-Lorraine.
**N'entre pas.** 🛑 La proclamation de la IIIᵉ République **le lendemain** de Sedan, la Commune de Paris, l'affaire Dreyfus → `hg_republiques` : Sedan est la **chute d'un empire**, le 4 septembre est la **naissance d'une république**. 🛑 L'abolition de l'esclavage (1848) et les lois scolaires (1881-82) → `hg_conquetes_droits` : ce sont des **droits acquis**, même s'ils sont du XIXᵉ siècle.
🛑 **CSP = 0.** Aucune question CSP sur Napoléon dans les 73 du thème — un trou de corpus, pas de taxonomie. Cinq questions à écrire (§8).

#### `hg_republiques` — **Les cinq républiques** *(remplace `hg_dates_republique`)*
CSP **⚠️ 2** · CR **7** ✅ · NAT **8** ✅ — 17 questions

**Définition.** Les régimes républicains successifs : quand ils naissent, comment ils fonctionnent, et les crises qui les traversent.
**Entre.** Le décompte des républiques ; la naissance de la IIIᵉ (4 septembre 1870) ; la Commune de Paris ; l'affaire Dreyfus ; la fondation de la Ve en 1958 et ses présidents ; le référendum de 1962.
**N'entre pas.** 🛑 Si l'événement fait **gagner un droit**, il relève de `hg_conquetes_droits`, **même posé sous forme de date**. Couple de référence : « Quel président a **aboli la peine de mort** ? » → conquêtes · « Qui a été le **premier président socialiste** ? » → ici. Même réponse, notions différentes : c'est la substance qui tranche, jamais la forme de la question. 🛑 Les empires et les monarchies → `hg_napoleon_xixe`.
⚠️ Le libellé abandonne « les grandes dates », qui nommait une **forme de question** au lieu d'un objet d'apprentissage — c'est ce qui alimentait le litige avec les conquêtes.

#### `hg_guerres_resistance` — **Les guerres du XXᵉ siècle et la décolonisation** *(élargie)*
CSP **8** ✅ · CR **9** ✅ · NAT **9** ✅ — 26 questions

**Définition.** La France dans les conflits du XXᵉ siècle : les deux guerres mondiales, l'Occupation et la Résistance, puis les guerres qui mettent fin à l'empire colonial.
**Entre.** 14-18 et ses batailles ; 39-45, Vichy, la Shoah, la France libre, la Résistance, la Libération ; l'empire colonial, l'Indochine, l'Algérie, les indépendances de 1960.
**N'entre pas.** 🛑 Le 11 novembre et le 8 mai **comme jours fériés** → `hg_fetes_jours_feries`. 🛑 La Sécurité sociale de 1945 → `hg_conquetes_droits` : un droit acquis. 🛑 La Nouvelle-Calédonie et ses référendums → `hg_geographie` : statut d'outre-mer actuel.
⚠️ **Pourquoi la décolonisation n'est pas une notion à part** : seule, elle ferait **0 / 3 / 3**. La fusion est chronologiquement continue (1914 → 1962) et ne coûte rien. Elle redevient séparable avec ~5 questions CSP de plus sur la colonisation.

#### `hg_conquetes_droits` — **Les conquêtes sociales et les transformations de la société** *(renommée)*
CSP **⚠️ 1** · CR **⚠️ 3** · NAT **12** ✅ — 16 questions

**Définition.** Les événements, lois et mouvements qui ont fait **acquérir, étendre ou reconnaître** un droit, ou transformé en profondeur la société française.
**Entre.** École gratuite, laïque et obligatoire ; abolition de l'esclavage ; droit de vote des femmes ; Front populaire et congés payés ; Sécurité sociale ; IVG ; abolition de la peine de mort ; majorité à 18 ans ; **Mai 68**.
**N'entre pas.** 🛑 Un fait purement institutionnel ou présidentiel → `hg_republiques`. 🛑 Le 1ᵉʳ mai comme **fête du Travail** → `hg_fetes_jours_feries`.
⚠️ **Mai 68 n'a pas sa notion** : le corpus n'en porte que **2 questions, dont 0 en CSP**. Le renommage l'accueille sous un libellé honnête plutôt que de fabriquer une notion à 2 questions.

#### `hg_europe` — **La construction européenne**
CSP **N/A** · CR **N/A** · NAT **6** ✅ — 6 questions

**Définition.** La naissance et les étapes de l'Europe communautaire, du point de vue français.
**Entre.** CECA, CEE et traité de Rome, Maastricht, référendum de 2005, pères fondateurs français.
**N'entre pas.** 🛑 Les institutions européennes **d'aujourd'hui** → `inst_ue`, thème `CIV_INSTITUTIONS`. 🛑 Strasbourg comme capitale du Grand Est → `hg_geographie`.
🛑 **Zéro question européenne hors NAT dans tout le thème** — vérifié sur les 145 lignes CSP et CR. Notion mono-mention assumée.

#### `hg_geographie` — **Géographie de la France et outre-mer**
CSP **17** ✅ · CR **11** ✅ · NAT **5** ✅ — 33 questions

**Définition.** Situer la France et ses territoires : mers, fleuves, montagnes, régions, grandes villes, outre-mer.
**Entre.** Façades maritimes ; fleuves ; chaînes de montagnes ; les 13 régions et leurs capitales ; les grandes villes et leurs surnoms ; DOM et collectivités ; le continent.
**N'entre pas.** 🛑 Un lieu qu'on visite pour **ce qu'il est** → `hg_patrimoine`. **La règle : situer sur une carte → ici ; nommer un site célèbre → patrimoine.** 🛑 Un produit régional → `hg_art_de_vivre`.
⚠️ Les 5 questions NAT ne portent que **3 faits** (régions ×2, Alpes ×2, Nouvelle-Calédonie) : servable au sens du seuil actuel, pauvre au sens de l'arbitrage 4.

#### `hg_patrimoine` — **Monuments et sites emblématiques**
CSP **9** ✅ · CR **5** ✅ · NAT **⚠️ 1** — 15 questions

**Définition.** Les monuments et les sites que la France montre au monde, et ce qu'ils sont.
**Entre.** Monuments bâtis (tour Eiffel, Louvre, Versailles, Notre-Dame, Arc de Triomphe, Chambord, arènes de Nîmes) **et** sites naturels devenus emblèmes (Mont-Saint-Michel, falaises d'Étretat).
**N'entre pas.** 🛑 Une œuvre ou son auteur → `hg_arts_sciences` : « Qu'est-ce que le Louvre ? » est ici, « Qui a peint la Joconde ? » est là-bas. 🛑 Une ville qu'on situe → `hg_geographie`.
🛑 Le CR ne tient à 5 **que si** Étretat et le Mont-Saint-Michel sont ici : c'est pourquoi la frontière ci-dessus doit être écrite en base, pas seulement comprise.

#### `hg_litterature` — **Les grands écrivains français** *(nouvelle)*
CSP **N/A** · CR **12** ✅ · NAT **8** ✅ — 20 questions

**Définition.** Les écrivains français qu'un candidat doit savoir reconnaître, et leur œuvre la plus connue.
**Entre.** Romanciers, poètes, dramaturges, philosophes-écrivains, et les prix Nobel français de littérature.
**N'entre pas.** 🛑 Un peintre, un musicien, un savant → `hg_arts_sciences`. 🛑 Zola pris comme **acteur de l'affaire Dreyfus** → `hg_republiques` : la question demande qui a écrit « J'accuse…! » *lors de l'affaire*, pas qui a écrit *Germinal*.

#### `hg_arts_sciences` — **Artistes et savants français** *(nouvelle)*
CSP **⚠️ 3** · CR **6** ✅ · NAT **6** ✅ — 15 questions

**Définition.** Les Français qui ont marqué la peinture, la musique, la chanson, le cinéma, la mode — et les grandes découvertes et inventions françaises.
**Entre.** Peintres, compositeurs, chanteuses, couturiers, cinéastes, inventeurs et scientifiques célèbres.
**N'entre pas.** 🛑 Un écrivain → `hg_litterature`. 🛑 Le monument où l'œuvre est exposée → `hg_patrimoine`. 🛑 Joséphine Baker **résistante** → `hg_guerres_resistance`, mais « Qui était Joséphine Baker ? » est une question d'artiste et reste ici.
⚠️ Les 6 questions NAT sont **trois paires strictement jumelles** (Baker ×2, Chagall ×2, Cézanne ×2) : **3 faits**. Sous l'arbitrage 4, cette cellule redeviendra insuffisante.

#### `hg_art_de_vivre` — **Gastronomie, sport et art de vivre** *(nouvelle)*
CSP **9** ✅ · CR **⚠️ 3** · NAT **⚠️ 2** — 14 questions

**Définition.** Ce que la France mange, boit, porte et regarde : les produits, les traditions et les grands rendez-vous sportifs et culturels.
**Entre.** Baguette, croissant, fromages, vins et champagne ; football, Tour de France, Roland-Garros, Jeux olympiques ; festival de Cannes ; la mode.
**N'entre pas.** 🛑 La région où le produit est fait, quand la question porte sur **la région** → `hg_geographie`. 🛑 Le créateur ou l'artiste lui-même → `hg_arts_sciences`. 🛑 Un jour de fête du calendrier → `hg_fetes_jours_feries`.
✅ **9 questions CSP pour 9 sujets distincts, aucun doublon** — la meilleure cellule CSP du thème après la géographie.

#### `hg_fetes_jours_feries` — **Fêtes et jours fériés en France**
CSP **8** ✅ · CR **⚠️ 2** · NAT **N/A** — 10 questions

**Définition.** Les fêtes du calendrier français et les jours fériés : quand ils tombent et ce qu'ils commémorent.
**Entre.** 1ᵉʳ janvier, 1ᵉʳ mai, 8 mai, 14 juillet, Toussaint, 11 novembre, Noël.
**N'entre pas.** 🛑 L'événement commémoré pris pour lui-même → sa notion d'histoire : « Quand a eu lieu la prise de la Bastille ? » → `hg_revolution`, « Que célèbre-t-on le 14 juillet ? » → ici. 🛑 Le 14 juillet comme **fête nationale et symbole** → `CIV_PRINCIPES`.

**Sorties du thème** — `hg_loi_1905` 🛑 supprimée (1 question, elle-même mal
rangée) · `hg_langue_culture` 🛑 **dissoute** : son noyau « langue » ne pesait
que **2 questions sur 36**, le reste était de la culture. Les 8 symboles partent
vers `CIV_PRINCIPES` (arbitrage 7).

**Orphelines assumées (3)** — l'OIF, le 13 novembre 2015, la COP21. Les deux
dernières esquissent « La France d'aujourd'hui dans le monde » : 4 en NAT,
**0 ailleurs**. Laissées orphelines plutôt qu'enfouies dans le prochain
fourre-tout.

---

## 2. `CIV_INSTITUTIONS` — 8 notions, 211 questions

*(214 − 3 parties vers `CIV_SOCIETE` par l'arbitrage 6)*

#### `inst_constitution` — **La Constitution et la séparation des pouvoirs**
CSP **⚠️ 4** · CR **13** ✅ · NAT **12** ✅ — 29 questions

**Définition.** Le texte qui fonde la Ve République, la façon dont il se révise et qui le fait respecter ; et le principe qu'il organise : trois pouvoirs séparés, chacun tenu par quelqu'un de différent.
**Entre.** Le régime politique de la France ; Montesquieu et l'identification de chaque pouvoir à son titulaire ; le Conseil constitutionnel (composition, saisine, QPC, contrôle a priori / a posteriori) ; la révision constitutionnelle et ses limites ; le rang des normes (loi organique).
**N'entre pas.** 🛑 Ce que **fait** un pouvoir donné → `inst_president` / `inst_parlement` : ici on reste au niveau « il y a trois pouvoirs, voici lequel est lequel ». 🛑 Le partage loi / règlement et le décret → `inst_gouvernement`. 🛑 « Qui doit respecter la loi ? » n'est pas de la Constitution mais du devoir civique → `CIV_DROITS_DEVOIRS`.
🛑 **CSP réel = 2** si les deux questions de devoir civique partent (§7). Il manque 3 questions CSP élémentaires.

#### `inst_president` — **Le président de la République**
CSP **10** ✅ · CR **7** ✅ · NAT **8** ✅ — 25 questions

**Définition.** Qui il est, comment on le devient, combien de temps il reste, et ce qu'il peut faire — y compris ce qu'il ne peut pas faire.
**Entre.** Élection au suffrage universel direct depuis 1962, durée et limite de mandats, parrainages, l'Élysée ; ses pouvoirs propres (nommer le Premier ministre, dissoudre, promulguer, référendum, article 16, chef des armées) ; ses limites (immunité, Haute Cour, obligation de promulguer).
**N'entre pas.** 🛑 Le Premier ministre et les ministres **une fois nommés** → `inst_gouvernement` : la frontière est « le président **nomme** » ici, « le gouvernement **gouverne** » là-bas. 🛑 Le scrutin vu de l'électeur → `inst_elections`.
✅ **La notion la plus saine du thème.**

#### `inst_gouvernement` — **Le gouvernement et l'administration de l'État** *(élargie)*
CSP **10** ✅ · CR **6** ✅ · NAT **5** ✅ — 21 questions

**Définition.** Qui dirige l'action de l'État au quotidien — Premier ministre, ministres, et leurs relais sur le territoire — et par quels moyens : décrets, ordonnances, budget.
**Entre.** Le gouvernement (composition, nomination, Matignon, Conseil des ministres, cohabitation) ; **les actes de l'exécutif** (décret, ordonnance, domaine réglementaire, 49.3) ; **l'État sur le territoire : le préfet** ; **l'argent de l'État** (impôts collectés, budget, Cour des comptes).
**N'entre pas.** 🛑 Le président, qui **nomme** le Premier ministre mais n'est pas le gouvernement → `inst_president`. 🛑 Le **vote** du budget est au Parlement ; sa **préparation et son contrôle** sont ici. 🛑 Le rôle de la police → `CIV_SOCIETE` (arbitrage 6).
🛑 **L'élargissement n'est pas un confort, c'est une nécessité.** Réduite au gouvernement stricto sensu, la notion serait à **CR 0 · NAT 3** : la mention la plus fournie du thème (90 questions) ne contient **aucune** question sur le Premier ministre, les ministres ou Matignon. Son CR tient au préfet, aux ordonnances et au budget.
✅ **Arbitrage 5 appliqué** : le préfet est ici. Déconcentration ≠ décentralisation — et le corpus fait lui-même la distinction (« le préfet représente l'État dans le département » face à « qui dirige un conseil départemental ? »).

#### `inst_parlement` — **Le Parlement : Assemblée nationale et Sénat**
CSP **14** ✅ · CR **13** ✅ · NAT **6** ✅ — 33 questions

**Définition.** Les deux chambres : qui y siège, comment on y entre, et ce qu'on y fait — voter les lois, voter le budget, contrôler le gouvernement.
**Entre.** Bicamérisme, effectifs (577 / 348), durée et mode d'élection, Palais Bourbon et Luxembourg, immunité, commissions ; le travail parlementaire (voter la loi, la navette et le dernier mot de l'Assemblée, le budget, les questions au gouvernement, la motion de censure, l'entrée en vigueur d'une loi votée).
**N'entre pas.** 🛑 Le Parlement **européen** → `inst_ue` : deux institutions homonymes, **le piège n°1 du thème**. 🛑 Le scrutin législatif vu de l'électeur → `inst_elections`. 🛑 La promulgation → `inst_president`. 🛑 Le 49.3 et l'ordonnance → `inst_gouvernement` : c'est l'exécutif qui agit.
⚠️ **Scission testée et rejetée** : « qui y siège » (7/6/**4**) et « ce qu'il fait » (7/7/**2**). Le NAT ne porte que 6 questions parlementaires, dont deux jumelles. Redeviendra faisable avec ~4 questions NAT sur le travail législatif.

#### `inst_elections` — **Les élections et le droit de vote**
CSP **10** ✅ · CR **11** ✅ · NAT **9** ✅ — 30 questions

**Définition.** Qui a le droit de voter en France et à quelles conditions ; quelles élections existent au niveau national ; comment la vie politique qui les entoure est encadrée.
**Entre.** Le droit de vote (âge, nationalité, droits civiques, inscription, vote non obligatoire, suffrage universel, droit de vote des ressortissants UE) ; les scrutins nationaux (présidentielle, législatives) ; le référendum, y compris d'initiative partagée ; l'encadrement (partis et pluralisme, financement des campagnes, parité, transparence).
**N'entre pas.** 🛑 Les **municipales, départementales et régionales** → `inst_collectivites` : le candidat qui révise « les collectivités » a besoin de savoir comment on désigne un maire, et sans elles cette notion s'effondre. 🛑 Les **européennes** → `inst_ue`. 🛑 Ce que **fait** l'élu une fois élu → `inst_president` / `inst_parlement`. **Règle : la question porte-t-elle sur l'électeur et le scrutin (ici) ou sur l'institution élue (là-bas) ?**
⚠️ **Scission testée et rejetée** : « le droit de vote » ferait **CSP 2** — et ces 2 questions sont **le même item posé deux fois** (« À partir de quel âge a-t-on le droit de voter ? » / « À partir de quel âge peut-on voter en France ? »).

#### `inst_collectivites` — **Les collectivités territoriales : commune, département, région** *(fusion)*
CSP **7** ✅ · CR **10** ✅ · NAT **⚠️ 3** — 20 questions

**Définition.** Les trois échelons élus qui gèrent le territoire au-dessous de l'État : qui les dirige, comment on les désigne, et qui fait quoi entre la mairie, le département et la région.
**Entre.** L'emboîtement commune → département → région → État ; la commune (le maire, son élection par le conseil municipal, l'état civil, les intercommunalités) ; le département et la région (nombre, présidence, mandats, compétences — collèges, lycées, transports, formation —, autonomie financière) ; les élections **locales**.
**N'entre pas.** 🛑 Le **préfet** : il ne dirige pas une collectivité, il représente l'État → `inst_gouvernement` (arbitrage 5). **C'est la confusion centrale du thème**, et le corpus la met lui-même en scène. 🛑 Le Parlement et le gouvernement, qui sont l'État et non le territoire.
🛑 **La fusion n'était pas un choix de style.** Séparées, les deux moitiés étaient chacune morte dans une mention différente : `inst_commune` **0 en NAT**, `inst_departement_region` **0 en CSP**. Le CSP ne pose *que* des questions communales, le NAT *que* des questions départementales. Trois questions portent d'ailleurs **déjà** sur les collectivités comme un tout et ne rentraient dans ni l'une ni l'autre.
⚠️ Les 3 questions NAT ne portent que **2 faits** (le nombre de départements, posé deux fois, et l'autonomie financière).

#### `inst_justice` — **La justice, les tribunaux et les magistrats**
CSP **⚠️ 2** · CR **13** ✅ · NAT **7** ✅ — 22 questions

**Définition.** Qui juge en France, dans quel tribunal selon la gravité, et pourquoi la justice décide sans recevoir d'ordre du pouvoir politique.
**Entre.** L'autorité judiciaire et son indépendance ; les juridictions (police, correctionnel, assises, Cour de cassation, Conseil d'État, ordre judiciaire / ordre administratif, Cour de justice de la République) ; les magistrats (siège et parquet, procureur, CSM) ; les recours du citoyen contre l'administration.
**N'entre pas.** 🛑 Le **Conseil constitutionnel**, qui n'est pas un tribunal → `inst_constitution`. 🛑 Les **droits de la personne jugée** (présomption d'innocence, avocat, aide juridictionnelle) → `CIV_DROITS_DEVOIRS` : ce sont des droits, pas des institutions. 🛑 La **police** → `CIV_SOCIETE` (arbitrage 6).
🛑 **Le plus gros trou du thème.** Les 2 questions CSP sont précisément celles qui doivent partir vers `CIV_DROITS_DEVOIRS` (§7) : **CSP réel = 0**. Il n'existe pas une seule question CSP sur le tribunal ou le juge, alors que le CR en compte treize.

#### `inst_ue` — **L'Union européenne**
CSP **7** ✅ · CR **17** ✅ · NAT **7** ✅ — 31 questions

**Définition.** Ce qu'est l'UE, d'où elle vient, qui décide à Bruxelles et à Strasbourg, et ce qu'elle change concrètement pour quelqu'un qui vit en France.
**Entre.** Les institutions (Commission, Parlement européen, Conseil de l'UE, Conseil européen, sièges, élections européennes, règlement vs directive) ; la vie du citoyen européen (citoyenneté, Schengen, libre circulation, euro et zone euro) ; **les symboles européens : drapeau, hymne, Journée de l'Europe** (arbitrage 7) ; les traités et le nombre d'États membres.
**N'entre pas.** 🛑 Le Parlement **français** → `inst_parlement`. 🛑 Le **112 vu comme numéro d'urgence à composer** → `CIV_SOCIETE` (arbitrage 6) ; le 112 comme *acquis européen* resterait ici, mais le corpus ne pose que la première forme. 🛑 Les **étapes historiques** de la construction européenne (CECA, traité de Rome, référendum de 2005) → `hg_europe`.
⚠️ **Scission testée et rejetée** : « construction et institutions » ferait **CSP 0** — le CSP ne pose que des questions de vie quotidienne et de symboles.

**Aucune orpheline** : le corpus institutionnel est dense et bien centré. Son
problème n'est pas la dispersion, c'est **la répartition entre mentions**.

---

## 3. `CIV_DROITS_DEVOIRS` — 9 notions, 149 questions

*(158 − 9 parties vers `CIV_SOCIETE` par l'arbitrage 6)*

🛑 **Aucune notion de ce thème n'atteint 5 dans les trois mentions.** Ce n'est
pas un défaut de découpage : le CSP n'a **aucune** question sur la DDHC ni sur
le droit européen, et le NAT **aucune** sur les interdits du quotidien.

#### `dd_textes_fondateurs` — **La Déclaration de 1789 et les textes qui garantissent nos droits**
CSP **N/A** · CR **11** ✅ · NAT **8** ✅ — 19 questions

**Définition.** D'où viennent les droits en France : la DDHC de 1789, le préambule de 1946, le bloc de constitutionnalité, et le fait que l'État lui-même y est soumis.
**Entre.** La date, l'auteur et la portée de la DDHC ; ses articles cités nommément (1ᵉʳ, 2, 4, 6, 8, 11) ; le préambule de 1946 et les droits sociaux qu'il reconnaît ; la décision de 1971 et le bloc de constitutionnalité ; la hiérarchie des normes ; l'État de droit ; l'égalité devant la loi comme principe de texte ; la Charte des droits et devoirs du citoyen.
**N'entre pas.** 🛑 Le **contenu** d'une liberté et ses limites → `dd_libertes_limites` : le texte dit *que* la liberté d'expression existe ; *comment elle s'arrête* est l'autre notion. 🛑 La CEDH, la CJUE, la CPI, la Charte de l'UE → `dd_protection_europeenne` : ici on reste sur les sources **françaises**. 🛑 Le nom de la Constitution actuelle → `CIV_INSTITUTIONS`.

#### `dd_protection_europeenne` — **Les droits protégés au-delà de la France : CEDH, Union européenne**
CSP **N/A** · CR **N/A** · NAT **8** ✅ — 8 questions

**Définition.** Les textes et les juridictions européennes et internationales qui garantissent les droits des personnes vivant en France, et comment un citoyen peut les saisir.
**Entre.** La Convention européenne des droits de l'homme ; la Cour de Strasbourg, sa saisine après épuisement des recours internes, la condamnation de la France ; la CJUE ; la Cour pénale internationale ; la Charte des droits fondamentaux de l'UE ; le droit international humanitaire.
**N'entre pas.** 🛑 Le **contenu français** d'un droit également garanti par la CEDH (procès équitable devant un tribunal français, droits de la défense) → `dd_police_justice`. 🛑 L'interdiction de la torture, même quand l'énoncé cite l'article 3 CEDH → `dd_infractions_peines` : le sujet est l'interdit absolu, pas l'institution. 🛑 Le fonctionnement politique de l'UE → `CIV_INSTITUTIONS`.

#### `dd_libertes_limites` — **Les libertés individuelles et leurs limites**
CSP **⚠️ 1** · CR **15** ✅ · NAT **7** ✅ — 23 questions

**Définition.** Ce que chacun a le droit de faire — s'exprimer, croire ou ne pas croire, circuler — et pourquoi la loi peut encadrer ces libertés sans les supprimer.
**Entre.** La liberté d'expression (définition, fondement, limites : injure, diffamation, haine en ligne) ; la liberté d'aller et venir ; la liberté de conscience et le droit de ne pas avoir de religion ; les droits individuels (liberté, sûreté, propriété) ; le raisonnement « les libertés ne sont pas absolues » et ses motifs ; l'état d'urgence ; le droit d'asile et la protection des apatrides.
**N'entre pas.** 🛑 Le **texte** qui proclame la liberté et sa date → `dd_textes_fondateurs`. 🛑 La **sanction pénale** de l'abus → `dd_interdits_quotidien` / `dd_infractions_peines`. 🛑 La **neutralité de l'État**, la loi de 1905, l'école → `pv_laicite` : **une personne a un droit → ici ; l'État a une obligation → `CIV_PRINCIPES`.** 🛑 La vie privée et l'image → `dd_vie_privee_famille`.
⚠️ Les 7 questions NAT ne portent que **4 faits** : quatre d'entre elles sont des reformulations de « pourquoi les libertés peuvent-elles être limitées ».

#### `dd_infractions_peines` — **L'infraction et la peine : du principe de légalité aux interdits absolus**
CSP **⚠️ 1** · CR **13** ✅ · NAT **7** ✅ — 21 questions

**Définition.** Comment le droit français définit une infraction, la gradue et la punit — et les quelques interdits auxquels aucune circonstance ne permet de déroger.
**Entre.** Les trois catégories d'infractions et leur gravité ; le principe de légalité ; la non-rétroactivité de la loi pénale plus sévère ; la prescription et l'imprescriptibilité des crimes contre l'humanité ; la proportionnalité ; `non bis in idem` ; l'abolition de la peine de mort ; la dignité humaine ; l'interdiction absolue de la torture ; l'esclavage et la traite ; le « noyau dur » des droits intangibles.
**N'entre pas.** 🛑 Les **interdits concrets du quotidien** → `dd_interdits_quotidien` : ici c'est le **principe**, là c'est le **geste**. 🛑 La **procédure** (garde à vue, avocat, procès) → `dd_police_justice`. 🛑 La CEDH comme institution → `dd_protection_europeenne`.

#### `dd_interdits_quotidien` — **Ce qui est interdit au quotidien, et ce qu'on risque** *(nouvelle)*
CSP **10** ✅ · CR **⚠️ 3** · NAT **N/A** — 13 questions

**Définition.** Les comportements que la loi française interdit dans la vie de tous les jours, et la sanction encourue. C'est la notion qui répond à « est-ce que j'ai le droit de… ? ».
**Entre.** Fumer dans un lieu public fermé ; vendre de l'alcool à un mineur ; conduire alcoolisé ; ne pas porter la ceinture ; consommer du cannabis ; voler ; frapper ; les propos et actes racistes ; le harcèlement sexuel, le viol ; « que risque une personne qui ne respecte pas la loi ».
**N'entre pas.** 🛑 Le **principe abstrait** derrière la sanction → `dd_infractions_peines`. 🛑 Ce qu'on doit **faire** positivement (payer ses impôts, trier, témoigner) → `dd_devoirs_citoyen` : **un interdit n'est pas une obligation.** 🛑 La **procédure** après l'infraction → `dd_police_justice`.
⚠️ **La scission d'avec `dd_infractions_peines` est le choix le plus discutable du thème.** Fusionnées, elles feraient **11 / 16 / 7 — la seule notion ≥ 5 partout**. Séparées, elles sont pédagogiquement justes mais chacune mono-mention. J'ai retenu la séparation : réviser « la prescription des délits est de 6 ans » et « le port de la ceinture est obligatoire » dans la même séance, ce sont deux apprentissages sans rapport. **Si tu veux maximiser les notions servables partout, c'est la fusion à faire en premier**, et le thème tombe à 8 notions.

#### `dd_police_justice` — **Police, justice : mes droits quand la loi s'applique à moi**
CSP **5** ✅ · CR **7** ✅ · NAT **⚠️ 3** — 15 questions

**Définition.** Ce que la police peut faire et ne pas faire, ce qu'une personne contrôlée ou poursuivie peut exiger, et comment une victime obtient réparation.
**Entre.** Contrôle et fouille, garde à vue et sa durée, droit au silence, interdiction de l'arrestation sans motif ; droit à un avocat et droits de la défense ; procès équitable ; présomption d'innocence ; aide juridictionnelle ; recours effectif ; porter plainte, se constituer partie civile, être indemnisé.
**N'entre pas.** 🛑 **Les numéros d'urgence et le rôle de la police et de la gendarmerie** → `vs_urgences_secours`, thème `CIV_SOCIETE` (arbitrage 6) : **ce que fait la police relève du service ; ce que je peux lui opposer relève du droit.** 🛑 La définition de l'infraction et de la peine → `dd_infractions_peines`. 🛑 Le devoir de respecter une décision de justice → `dd_devoirs_citoyen`.
⚠️ **CSP à 5, pile au seuil**, après le départ des 7 questions d'urgence et de rôle. Les deux questions que `CIV_INSTITUTIONS` doit lui céder (présomption d'innocence, droit à un avocat) la porteraient à **7** — décision en attente (§7).

#### `dd_devoirs_citoyen` — **Les devoirs du citoyen : la loi, l'impôt, la défense, l'environnement** *(renommée)*
CSP **5** ✅ · CR **6** ✅ · NAT **⚠️ 4** — 15 questions

**Définition.** Ce que la République attend de chacun en retour des droits qu'elle garantit : obéir à la loi, contribuer, servir, protéger.
**Entre.** Respecter la loi et les décisions de justice ; payer ses impôts ; dire la vérité comme témoin ; la Journée défense et citoyenneté, l'objection de conscience ; la probité de l'agent public ; le devoir de protéger l'environnement et le tri ; les « devoirs constitutionnels » ; le devoir de fraternité.
**N'entre pas.** 🛑 Les **interdits** → `dd_interdits_quotidien`. 🛑 Le droit à un environnement sain **reste ici** avec son pendant l'obligation, parce que le corpus les énonce toujours ensemble et qu'une notion « environnement » autonome ferait **1 / 2 / 1**.
🛑 **Renommage obligatoire.** Le libellé actuel est « Les devoirs : lois, impôts, **jury** » — et le corpus ne contient **aucune question sur le jury d'assises** : il n'apparaît que dans l'explication d'une autre question. Le libellé promet un contenu inexistant.
✅ **Il manque UNE question NAT** pour que cette notion soit servable dans les trois mentions. **Meilleur rapport effort / gain de tout l'audit.**

#### `dd_vie_privee_famille` — **Vie privée, image, données personnelles et vie de famille** *(nouvelle)*
CSP **5** ✅ · CR **10** ✅ · NAT **⚠️ 3** — 18 questions

**Définition.** Ce qui appartient à la sphère intime d'une personne — son image, sa correspondance, ses données, ses choix de couple et de corps — et la protection que le droit y attache.
**Entre.** Le droit au respect de la vie privée ; le droit à l'image ; le secret des correspondances ; le secret professionnel et médical ; le RGPD et le droit à l'oubli ; la majorité civile ; le mariage, le mariage pour tous, le PACS ; l'IVG ; la fin de vie.
**N'entre pas.** 🛑 La liberté d'expression et ses limites, même quand elles protègent autrui → `dd_libertes_limites`. 🛑 La protection de l'enfance (maltraitance, signalement) → `dd_droits_sociaux` : c'est un droit de l'enfant. 🛑 L'égalité femmes-hommes comme principe politique → `dd_textes_fondateurs`.
⚠️ **La notion la moins homogène des neuf.** « Le droit à l'image » et « qu'est-ce que le PACS » ne sont pas le même apprentissage. Séparées : **3/5/1** et **2/5/2** — inviables toutes les deux. Fusionner est le moindre mal, pas un bon découpage.

#### `dd_droits_sociaux` — **Travailler, se soigner, être logé, aller à l'école : les droits sociaux** *(fusion de 4)*
CSP **10** ✅ · CR **⚠️ 3** · NAT **⚠️ 4** — 17 questions

**Définition.** Les droits que le préambule de 1946 et la loi reconnaissent à toute personne vivant en France dans sa vie matérielle : le travail, la santé, le logement, l'instruction, la protection de l'enfance.
**Entre.** Durée légale du travail, congés payés, SMIC, travail dissimulé, harcèlement moral, droit de grève, liberté syndicale ; protection maladie universelle et droit constitutionnel à la santé ; droit au logement opposable ; instruction obligatoire de 3 à 16 ans et gratuité de l'école ; protection de l'enfance (signalement, interdiction des violences éducatives).
**N'entre pas.** 🛑 Les **démarches** pour obtenir ces droits → `CIV_SOCIETE`. **Le test : un droit qu'on peut faire valoir devant un juge reste ici ; un formulaire à déposer à un guichet part là-bas.** 🛑 Le devoir de payer ses cotisations → `dd_devoirs_citoyen`.
🛑 **La fusion de 4 notions faméliques en une.** `dd_logement` portait **1** question, `dd_protection_sociale` **2**, `dd_ecole_enfance` 6, `dd_travail` 7. Le corpus lui-même les traite comme un bloc : la question « Quels sont les droits sociaux fondamentaux en France ? » énumère santé, éducation, travail, sécurité matérielle et logement dans une seule réponse.
🛑 **Le grand trou du corpus** : le CR pèse 72 questions et n'en a que **3** sur travail, santé, école et logement réunis.

**Supprimées (3)** — 🛑 `dd_egalite_loi` (5 questions, sous le seuil partout ;
redistribuée entre textes fondateurs et interdits) · 🛑 `dd_logement` (**1**
question) · 🛑 `dd_liberte_culte` (**2** questions, toutes deux sur la liberté
de *conscience*, absorbées par `dd_libertes_limites`).

**Aucune orpheline**, mais **quatre poches sous le seuil partout** désignent des
notions manquantes **faute de contenu** : le droit des étrangers (0/2/1),
l'égalité femmes-hommes et les violences (1/3/2), l'environnement (1/2/1),
l'État de droit (0/0/2).

---

## 4. `CIV_SOCIETE` — 12 notions, 169 questions

*(157 + 12 reçues par l'arbitrage 6)*

#### `vs_ecole_scolarite` — **L'école et les études** *(nouvelle)*
CSP **12** ✅ · CR **11** ✅ · NAT **N/A** — 23 questions

**Définition.** Le système scolaire français : qui doit être instruit, jusqu'à quand, quels cycles, quels diplômes, et comment on s'y inscrit.
**Entre.** Obligation d'instruction de 3 à 16 ans ; maternelle, élémentaire, collège, lycée ; brevet, bac, CAP, bac pro ; alternance, apprentissage, Parcoursup ; inscription, assiduité, cantine.
**N'entre pas.** 🛑 La **laïcité à l'école** (loi de 2004, Charte de 2013) → `pv_laicite`, qui en porte déjà 12. 🛑 Le **droit à l'éducation** comme droit fondamental → `dd_droits_sociaux`. 🛑 La formation professionnelle de l'adulte → `vs_emploi_formation`.

#### `vs_sante_soins` — **Se soigner : médecin, Sécu, remboursements**
CSP **⚠️ 2** · CR **13** ✅ · NAT **N/A** — 15 questions

**Définition.** Le parcours de soins ordinaire et son remboursement : à qui on s'adresse, avec quelle carte, qui paie quoi.
**Entre.** Carte Vitale, CPAM, médecin traitant, pharmacien, mutuelle, PUMA, arrêt maladie, vaccinations obligatoires.
**N'entre pas.** 🛑 L'**AME et la C2S** → `vs_protection_sociale_aides` : prestations sous condition de ressources. 🛑 La médecine du travail → `vs_travail_entreprise`. 🛑 L'IVG, la PMA, la GPA → `vs_famille_etat_civil`. 🛑 Le **droit** à la santé → `dd_droits_sociaux`.

#### `vs_travail_contrat_salaire` — **Le contrat de travail et le salaire** *(issue de `vs_emploi`)*
CSP **⚠️ 2** · CR **16** ✅ · NAT **⚠️ 1** — 19 questions

**Définition.** La relation individuelle employeur ↔ salarié : quel contrat, quel salaire, quelle durée, comment ça se rompt.
**Entre.** CDI, CDD, SMIC, brut/net, 35 heures, préavis, démission, rupture conventionnelle, congés maternité et paternité, âge minimum pour travailler, travail non déclaré, CESU.
**N'entre pas.** 🛑 Tout ce qui est **collectif** (CSE, syndicats, convention collective, inspection du travail) → `vs_travail_entreprise`. 🛑 **Chercher** un emploi ou se former → `vs_emploi_formation`. 🛑 Cotisations et retraite → `vs_protection_sociale_aides`. 🛑 Le droit au travail et la non-discrimination à l'embauche → `dd_droits_sociaux`.

#### `vs_travail_entreprise` — **Les salariés dans l'entreprise** *(issue de `vs_emploi`)*
CSP **N/A** · CR **⚠️ 4** · NAT **5** ✅ — 9 questions

**Définition.** Ce qui se joue collectivement dans l'entreprise : qui représente les salariés, qui négocie, qui contrôle, et ce que l'entreprise redistribue.
**Entre.** CSE, syndicats représentatifs, convention collective, inspection du travail, médecine du travail, participation aux bénéfices, PEE, AGS.
**N'entre pas.** 🛑 Le contrat individuel et le salaire → `vs_travail_contrat_salaire`. 🛑 Le droit de grève et la liberté syndicale **comme libertés publiques** → `dd_droits_sociaux`. 🛑 Les conquêtes sociales historiques (1936, 1945) → `hg_conquetes_droits`.
⚠️ Notion volontairement mince mais irréductible : **c'est la seule notion « travail » qui tienne en NAT.** La fusionner avec la précédente recréerait `vs_emploi` (28 questions, trop large).

#### `vs_emploi_formation` — **Chercher un emploi, se former, créer son activité** *(issue de `vs_emploi`)*
CSP **N/A** · CR **5** ✅ · NAT **N/A** — 5 questions

**Définition.** Ce qu'on fait quand on n'a pas (encore) d'emploi, ou qu'on veut en changer : les organismes, les droits à la formation, la création d'activité.
**Entre.** France Travail, CPF, micro-entrepreneur, service civique, reconnaissance de diplômes.
**N'entre pas.** 🛑 Le contrat une fois signé → `vs_travail_contrat_salaire`. 🛑 L'allocation chômage et le RSA → `vs_protection_sociale_aides`. 🛑 L'alternance sous statut scolaire → `vs_ecole_scolarite`.
🛑 **La notion la plus fragile du référentiel : 5 questions, pile au seuil, et dans une seule mention.** L'arbitrage 3 lui retire les mises en situation qui l'auraient consolidée. **Repli si tu la juges trop mince : la fusionner dans `vs_travail_contrat_salaire`**, qui passerait à 24 — je ne le recommande pas, mais c'est le seul repli propre.

#### `vs_protection_sociale_aides` — **La protection sociale et les aides** *(élargie)*
CSP **5** ✅ · CR **6** ✅ · NAT **7** ✅ — 18 questions

**Définition.** Le filet social français : qui le finance, et quelles prestations on peut toucher selon sa situation.
**Entre.** Sécurité sociale, cotisations, URSSAF, retraite, État-providence ; CAF, RSA, prime d'activité, APL, AAH, MDPH, C2S, AME ; **logement social et HLM**.
**N'entre pas.** 🛑 Le remboursement ordinaire des soins → `vs_sante_soins`. 🛑 Les droits sociaux du préambule de 1946 → `dd_droits_sociaux`. 🛑 La création de la Sécu en 1945 **comme événement** → `hg_conquetes_droits`.
✅ **L'une des deux seules notions du thème servables dans les trois mentions** — et elle ne l'est que grâce à l'élargissement au logement social et aux cotisations.

#### `vs_famille_etat_civil` — **La famille, le couple et l'état civil** *(nouvelle)*
CSP **6** ✅ · CR **6** ✅ · NAT **10** ✅ — 22 questions

**Définition.** Comment le droit français organise le couple, les enfants, la majorité et la transmission — et ce qu'il autorise ou interdit sur le corps.
**Entre.** Mariage civil (conditions, âge, égalité des époux, régimes matrimoniaux), PACS, autorité parentale, émancipation, majorité, crèche, acte de naissance, tutelle, mandat de protection future, réserve héréditaire, PMA, IVG, GPA.
**N'entre pas.** 🛑 L'égalité femmes-hommes **comme principe républicain** → `CIV_PRINCIPES`. 🛑 Les violences conjugales et leur répression → `dd_interdits_quotidien`. 🛑 Le droit de vote à 18 ans, qui est la majorité **civique** → `inst_elections`. 🛑 La carte d'identité → `vs_papiers_identite`.
⚠️ **Notion large** (couple / enfants / patrimoine / bioéthique), maintenue entière parce que toute scission fait retomber les morceaux sous 5 en CSP et en CR. Si le corpus s'étoffe, la coupe naturelle est couple-famille / corps-bioéthique.

#### `vs_sejour_asile` — **Le séjour des étrangers et l'asile** *(issue de `vs_demarches`)*
CSP **⚠️ 1** · CR **9** ✅ · NAT **⚠️ 4** — 14 questions

**Définition.** Les titres qui autorisent un étranger à vivre en France, l'accompagnement à l'intégration, et la protection internationale.
**Entre.** Titre de séjour, carte pluriannuelle, carte de résident, niveaux de français exigés, OFII, CIR, TCF/DELF ; asile : GUDA, OFPRA, statut de réfugié vs protection subsidiaire, règlement Dublin.
**N'entre pas.** 🛑 **Devenir français** → `vs_nationalite_francaise` : **la frontière est *avoir le droit de rester* vs *devenir français*.** 🛑 Les droits de l'étranger, la double peine, l'éloignement → `CIV_DROITS_DEVOIRS`. 🛑 Frontex et l'agence européenne d'asile → `CIV_INSTITUTIONS`.

#### `vs_nationalite_francaise` — **Devenir français** *(issue de `vs_demarches`)*
CSP **N/A** · CR **N/A** · NAT **10** ✅ — 10 questions

**Définition.** Les voies d'accès à la nationalité française, leurs conditions, et ce qui accompagne son obtention.
**Entre.** Droit du sol, droit du sang, naturalisation (critères, examen civique 2026, B2), déclaration après mariage, double nationalité, cérémonie d'accueil, Charte des droits et devoirs, adhésion aux valeurs, perte de la nationalité.
**N'entre pas.** 🛑 Le séjour régulier qui précède → `vs_sejour_asile`. 🛑 Les **valeurs républicaines en elles-mêmes** → `CIV_PRINCIPES` : ici on ne garde que « ce à quoi le candidat doit adhérer ». 🛑 Les droits du citoyen une fois français → `CIV_DROITS_DEVOIRS`.
✅ **Notion mono-mention assumée, et la plus dense du thème pour un candidat NAT.** Elle n'a aucun sens pour CSP et CR — c'est exactement ce que l'arbitrage 2 permet enfin d'exprimer.

#### `vs_papiers_identite` — **Ses papiers et les guichets de l'administration** *(issue de `vs_demarches`)*
CSP **8** ✅ · CR **N/A** · NAT **N/A** — 8 questions

**Définition.** Les documents qui prouvent qui on est, comment on les obtient, les renouvelle, les remplace — et où l'on s'adresse pour une démarche.
**Entre.** Carte nationale d'identité et sa validité, passeport, perte ou vol, document attestant la nationalité, documents pour voyager, service-public.fr et le 39 39, centre des impôts.
**N'entre pas.** 🛑 Le titre de séjour → `vs_sejour_asile`. 🛑 L'acte de naissance et l'état civil → `vs_famille_etat_civil`. 🛑 La carte Vitale → `vs_sante_soins`.
🛑 **C'est ce qui reste de `vs_demarches` une fois vidé : ne jamais y remettre du séjour, de la nationalité ou des aides.**

#### `vs_urgences_secours` — **Urgences, secours et forces de l'ordre** *(élargie par l'arbitrage 6)*
CSP **18** ✅ · CR **⚠️ 2** · NAT **N/A** — 20 questions

**Définition.** Qui intervient en cas d'urgence ou de danger, quel numéro composer, et ce que font la police et la gendarmerie au quotidien.
**Entre.** Le 15, le 17, le 18, le 112, le 119, le 116 000, le 3919 ; la gratuité et l'accessibilité 24 h/24 ; **le rôle de la police nationale et de la gendarmerie**, et leur répartition urbain / rural.
**N'entre pas.** 🛑 **Ce que je peux opposer à un policier** — contrôle, fouille, garde à vue, droit au silence, arrestation sans motif, porter plainte → `dd_police_justice`, thème `CIV_DROITS_DEVOIRS` (arbitrage 6). **La règle : ce que font les forces de l'ordre est un service ; ce que je peux leur opposer est un droit.** 🛑 Le parcours de soins non urgent → `vs_sante_soins`. 🛑 Le signalement d'un enfant en danger, qui est un **devoir** → `dd_droits_sociaux`.
⚠️ **18 questions CSP pour ~10 faits distincts** : la fusion des trois thèmes a rassemblé le 15 ×3, le 18 ×3, le 112 ×2 et la définition ×2. La notion reste largement servable sous l'arbitrage 4, mais c'est **le premier endroit où dédupliquer**.

#### `vs_deplacements_route` — **Se déplacer : permis, sécurité routière, transports** *(issue de `vs_transports_securite`)*
CSP **5** ✅ · CR **N/A** · NAT **⚠️ 1** — 6 questions

**Définition.** Conduire légalement en France et se déplacer au quotidien : les permis, leurs âges, les obligations de sécurité.
**Entre.** Permis B, permis moto A1/A2/A, conduite accompagnée, permis à points, casque à vélo, équipement obligatoire du véhicule, transports en commun urbains.
**N'entre pas.** 🛑 Les infractions routières et leurs sanctions, l'alcool au volant → `dd_interdits_quotidien`. 🛑 Les numéros de secours après un accident → `vs_urgences_secours`. 🛑 Le réseau ferré et l'aménagement du territoire → `hg_geographie`.
⚠️ **La scission d'avec les urgences était nécessaire** : rien ne relie « Le 18 est le numéro des pompiers » et « Le permis A1 se passe à 16 ans ». Les garder groupées n'achetait **aucune couverture** — la notion fusionnée restait à 0 en CR — seulement de l'incohérence.

**Supprimées (4)** — 🛑 `vs_laicite_quotidien` (**1** question, doublon de
`CIV_PRINCIPES` ; zéro question sur la laïcité au travail, à l'hôpital ou à la
cantine) · 🛑 `vs_logement_pratique` (4, dont 0 en NAT) · 🛑 `vs_budget_impots`
(**2**) · 🛑 `vs_vie_collective` (5 sans rapport, et « Vivre ensemble et respect
des règles » est indéfendable après « À travailler : »).

**Orphelines assumées (7)** — le surendettement, la caution locative, le tabac
aux mineurs, l'âge d'entrée en boîte de nuit, l'INSEE, la bibliothèque
municipale, l'école laïque *(celle-ci part vers `pv_laicite`)*.

⚠️ **Une 13ᵉ notion existe en creux : « La majorité et les âges de la vie »** —
travail à 14/16, permis à 16/17/18, tabac et boîte de nuit à 18, mariage et vote
à 18, émancipation à 16, retraite à 64. Une dizaine de questions. **Non retenue
parce qu'elle volerait ses questions à quatre autres notions** et que le moteur
ne sait pas rattacher une question à deux notions. C'est la meilleure candidate
suivante, et elle réglerait deux orphelines.

---

## 5. `CIV_PRINCIPES` — 5 notions, 81 questions

*(73 + 8 reçues par l'arbitrage 7)*

#### `pv_symboles_devise` — **Les symboles et la devise de la République** *(fusion)*
CSP **24** ✅ · CR **12** ✅ · NAT **⚠️ 4** — 40 questions

**Définition.** Ce à quoi la France se reconnaît : son drapeau, son hymne, sa figure, sa fête, sa langue — et les trois mots de sa devise, un par un.
**Entre.** Drapeau tricolore, Marianne, coq, hymne et *La Marseillaise*, 14 juillet comme fête nationale, langue officielle *(article 2 de la Constitution)*, sceau ; « Liberté, Égalité, Fraternité » et le sens de chacun des trois mots.
**N'entre pas.** 🛑 Les **symboles européens** (drapeau aux 12 étoiles, hymne, Journée de l'Europe) → `inst_ue` (arbitrage 7). 🛑 Le 14 juillet comme **jour férié du calendrier** → `hg_fetes_jours_feries` ; comme **prise de la Bastille** → `hg_revolution`. 🛑 L'égalité **comme droit opposable** → `pv_egalite_non_discrimination` : la devise proclame, la notion d'égalité applique.
🛑 **Fusion de `pv_symboles` et `pv_devise_valeurs`** : le corpus ne les distingue pas. « Que représente Marianne ? » et « Que signifie la liberté dans la devise ? » sont la même révision.
⚠️ **NAT à 4 — une seule question manque.**

#### `pv_republique_democratie` — **La République : régime, démocratie, souveraineté** *(nouvelle)*
CSP **⚠️ 1** · CR **8** ✅ · NAT **⚠️ 4** — 13 questions

**Définition.** Ce que veut dire « République » en France : un régime où le pouvoir vient du peuple, s'exerce par des représentants élus, et n'appartient à personne en propre.
**Entre.** République indivisible, laïque, démocratique et sociale ; démocratie représentative et directe ; souveraineté nationale et populaire ; « le gouvernement du peuple, par le peuple, pour le peuple » ; le caractère républicain que la révision ne peut pas toucher ; l'intérêt général.
**N'entre pas.** 🛑 Les **institutions** qui l'incarnent — président, Parlement, élections → `CIV_INSTITUTIONS` : ici on est sur le principe, pas sur l'organe. 🛑 Les **cinq républiques successives** et leur chronologie → `hg_republiques`. 🛑 La laïcité, qui est l'un des quatre adjectifs mais a sa propre notion → `pv_laicite`.
🛑 **Grappe de 13 questions qui n'avait aucune notion d'accueil** dans le référentiel actuel.

#### `pv_laicite` — **La laïcité**
CSP **N/A** · CR **5** ✅ · NAT **5** ✅ — 10 questions

**Définition.** La règle qui sépare l'État des religions : l'État ne se mêle pas des croyances, et garantit à chacun de croire, de ne pas croire ou de changer d'avis.
**Entre.** Loi de 1905 et séparation des Églises et de l'État ; neutralité de l'État et de l'agent public ; loi du 15 mars 2004 sur les signes religieux à l'école publique ; Charte de la laïcité de 2013 ; liberté de conscience ; financement des cultes ; exception concordataire d'Alsace-Moselle.
**N'entre pas.** 🛑 Le droit **individuel** de croire, de pratiquer, de ne pas être discriminé pour sa religion → `dd_libertes_limites`. **La règle : l'État ou le service public a une obligation → ici ; une personne a un droit → `CIV_DROITS_DEVOIRS`.** 🛑 La date du vote de la loi de 1905 prise comme **repère historique** → `hg_conquetes_droits`.
⚠️ Deux questions de `CIV_DROITS_DEVOIRS` (liberté de conscience) et une de `CIV_SOCIETE` (« L'école publique est-elle laïque ? ») sont des candidates naturelles à rejoindre cette notion — décision en attente (§7). Elles porteraient le CR à 7.

#### `pv_egalite_non_discrimination` — **Égalité et refus des discriminations**
CSP **N/A** · CR **9** ✅ · NAT **⚠️ 1** — 10 questions

**Définition.** Le principe selon lequel la loi est la même pour tous et personne ne peut être traité moins bien à cause de ce qu'il est.
**Entre.** Égalité devant la loi et devant le service public ; les critères de discrimination prohibés ; l'égalité femmes-hommes et la parité ; l'égalité réelle et les politiques qui la visent ; le refus des distinctions d'origine, de race ou de religion.
**N'entre pas.** 🛑 L'égalité **comme mot de la devise** → `pv_symboles_devise`. 🛑 La **sanction pénale** du racisme et de l'incitation à la haine → `dd_interdits_quotidien`. 🛑 L'article 6 de la DDHC pris comme **texte** → `dd_textes_fondateurs`.

#### `pv_libertes_ddhc` — **Les libertés fondamentales et la Déclaration de 1789** *(fusion)*
CSP **N/A** · CR **7** ✅ · NAT **⚠️ 1** — 8 questions

**Définition.** Les libertés que la République reconnaît à toute personne, et le texte de 1789 qui les a énoncées le premier.
**Entre.** Liberté, sûreté, propriété, résistance à l'oppression ; liberté d'expression, de réunion, d'association, de la presse comme **principes** ; la DDHC comme socle de ces libertés et son intégration au bloc de constitutionnalité.
**N'entre pas.** 🛑 Le **régime juridique** d'une liberté et ses limites concrètes → `dd_libertes_limites`, thème `CIV_DROITS_DEVOIRS`. 🛑 La DDHC prise comme **source du droit** (articles, bloc de constitutionnalité, hiérarchie des normes) → `dd_textes_fondateurs`.
⚠️ **Fusion de `pv_libertes_fondamentales` et `pv_ddhc`** : 8 questions à elles deux, séparées elles étaient inviables.
🛑 **Recouvrement assumé avec `CIV_DROITS_DEVOIRS`.** Les deux thèmes parlent des mêmes libertés ; la frontière est *principe proclamé* (ici) vs *droit exercé et limité* (là-bas). **C'est la frontière la plus fragile du référentiel** — à surveiller au tagging.

### 🛑 Le verdict sur ce thème

**Aucune de ces 5 notions n'est servable dans les trois mentions, et aucun
découpage ne le permettrait.** La cause n'est pas la taxonomie : le CSP n'a que
19 questions natives dont 17 sur les symboles, et le NAT n'en a que 16
éparpillées sur cinq sujets. Même en fusionnant tout en une notion unique, NAT
resterait à 16.

✅ **Mais le moteur le gère déjà.** La bascule thème → notion se fait **par
thème** : `CIV_PRINCIPES` peut rester au grain thème pendant que les quatre
autres passent au grain notion. **Aucune ligne de code à écrire.**

Le remède est **éditorial** : ~15 questions CSP et NAT à écrire (§8). Et
l'arbitrage 7 en a déjà apporté 7 gratuitement.

---

## 6. Récapitulatif — 46 notions

| Thème | Notions | Servables CSP | Servables CR | Servables NAT | Servables partout |
|---|---:|---:|---:|---:|---:|
| `CIV_HISTOIRE_GEO` | 12 | 7 | 8 | 7 | 3 |
| `CIV_INSTITUTIONS` | 8 | 6 | 8 | 7 | 5 |
| `CIV_DROITS_DEVOIRS` | 9 | 5 | 7 | 5 | 2 |
| `CIV_SOCIETE` | 12 | 6 | 6 | 4 | 2 |
| `CIV_PRINCIPES` | 5 | 1 | 5 | 1 | 0 |
| **Total** | **46** | **25** | **34** | **24** | **12** |

**Couverture : 813 questions sur 840 (97 %)** rattachées à une notion. Restent
10 orphelines assumées (3 en Histoire-Géo, 7 en Société) et ~17 questions encore
rangées dans un thème qui n'est pas le leur (§7).

⚠️ **Le CR est deux fois mieux servi que le CSP et le NAT** — 34 notions contre
25 et 24. Ce n'est pas un biais de découpage : le CR pèse 350 questions sur 840,
soit **42 % du corpus pour un tiers des candidats**.

---

## 7. Ce qui reste à décider — les déplacements de thème non arbitrés

Les arbitrages 6 et 7 ont réglé 20 questions. Il en reste **~17** rangées dans un
thème qui n'est pas le leur. Je ne les ai pas déplacées.

| Flux | Nb | Questions | Effet si tu valides |
|---|---:|---|---|
| `CIV_INSTITUTIONS` → `CIV_DROITS_DEVOIRS` | 8 | présomption d'innocence, droit à l'avocat, « qui doit respecter la loi » ×2, impôts ×2, recours de l'usager ×2 | `dd_police_justice` CSP **5 → 7** · `inst_constitution` CSP **4 → 2** 🛑 · `inst_gouvernement` CSP 10 → 8 |
| `CIV_DROITS_DEVOIRS` → `CIV_INSTITUTIONS` | 7 | « nom de la Constitution » ×2, service public ×2, subsidiarité, souveraineté, impôts locaux | `dd_textes_fondateurs` CR 11 → 9 · `dd_protection_europeenne` NAT 8 → 7 |
| `CIV_SOCIETE` → `CIV_INSTITUTIONS` | 3 | âge d'électeur, Frontex, INSEE | résout 1 orpheline de Société |
| `CIV_DROITS_DEVOIRS` → `pv_laicite` | 2 | liberté de conscience ×2 | `pv_laicite` CR **5 → 7** |
| `CIV_SOCIETE` → `pv_laicite` | 1 | « L'école publique est-elle laïque ? » | résout 1 orpheline · doublon à arbitrer |
| `CIV_INSTITUTIONS` → `hg_republiques` | 1 | « Pourquoi la IVe République a-t-elle pris fin en 1958 ? » | — |
| `CIV_DROITS_DEVOIRS` → `vs_deplacements_route` | 1 | âge minimum pour conduire | `vs_deplacements_route` CSP 5 → 6 |

🛑 **Le flux Institutions → Droits et devoirs est à double tranchant.** Il sauve
`dd_police_justice` (5 → 7 en CSP) mais fait tomber `inst_constitution` à
**CSP 2** et `inst_justice` à **CSP 0**. Si tu le valides, il faut écrire les
questions CSP de remplacement **dans la même passe** — sinon deux notions
institutionnelles deviennent inservables aux candidats CSP.

---

## 8. Ce qu'il faudra écrire — par ordre de rentabilité

| # | À écrire | Volume | Ce que ça débloque |
|---|---|---:|---|
| 1 | 1 question **NAT** sur les devoirs (jury d'assises, article 13 DDHC) | **1** | `dd_devoirs_citoyen` devient la **1ʳᵉ** notion de son thème servable partout |
| 2 | 1 question **NAT** sur les symboles | **1** | `pv_symboles_devise` servable partout |
| 3 | Questions **CSP** sur la justice (« Qui juge en France ? », « Un juge reçoit-il des ordres ? ») | 5 | `inst_justice` passe de **CSP 2** (0 réel) à servable |
| 4 | Questions **CSP** sur la Constitution | 3 | `inst_constitution` passe de **CSP 4** (2 réel) à servable |
| 5 | Questions **CSP** et **NAT** sur `CIV_PRINCIPES` | ~15 | débloque le grain notion sur le thème le plus affamé |
| 6 | Questions **CR** sur les droits sociaux | ~10 | le CR pèse 72 questions et n'en a que **3** sur le sujet |
| 7 | Questions **CSP** sur Napoléon | 5 | `hg_napoleon_xixe` passe de **CSP 0** à servable |
| 8 | Questions **NAT** sur les collectivités | 2 | `inst_collectivites` passe de 3 (2 faits) à servable |
| 9 | Questions **NAT** sur le travail parlementaire | 4 | rend possible la scission de `inst_parlement` |

**Deux questions — les nos 1 et 2 — font passer le nombre de notions servables
dans les trois mentions de 12 à 14.**

---

## 9. Ce qui se passe après ta validation

Dans cet ordre, et pas avant :

1. **Migration Flyway** qui pose les 46 notions avec leurs libellés et leurs
   descriptions — 🛑 **sans toucher un seul `civic_notion_id`**. Les notions
   supprimées sont marquées `merged_into` vers leur remplaçante quand il y en a
   une, jamais effacées.
2. 🔧 **Arbitrage 2 en code** : l'état `NON_APPLICABLE` à côté de
   `CONTENU_INSUFFISANT`, avec le test « zéro question dans la mention ». Tests
   backend dans la même passe, et les 3 fronts alignés sur le nouvel état.
3. **Réécriture du prompt de pré-tagging** sur le nouveau référentiel — les
   notions changent, les descriptions changent, `PROMPT_TAG_NOTION_v3` est
   caduc. Nouveau `prompt_version`.
4. **Nouveau pilote** de 50 questions avant le batch complet, comme la dernière
   fois : c'est ce qui a coûté 0,05 $ au lieu de 0,48 $ pour trouver le trou des
   jours fériés.
5. 🔧 **Arbitrage 4** (seuil sur les faits distincts) : chantier séparé, qui
   suppose une déduplication du corpus. **À ne pas mélanger avec le tagging.**

🛑 **État actuel : rien n'est lancé.** Le pré-tagging reste en pause, les 50
questions du pilote v3 restent en attente de ta relecture, les 790 restantes
n'ont pas été lancées, et aucun `civic_notion_id` n'a bougé.
