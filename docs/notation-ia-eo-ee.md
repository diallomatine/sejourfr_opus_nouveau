# Comment l'IA corrige les productions (Expression Écrite & Orale)

> **À qui s'adresse ce document ?** À tout le monde — pas besoin d'être développeur.
> Il explique, en langage simple, **comment l'intelligence artificielle note** ce que le
> candidat écrit (EE) ou dit à l'oral (EO) sur SejourFR, tâche par tâche, et **selon quelles
> règles**. Une version plus technique (fichiers, code, base de données) existe dans
> [`pipeline-evaluation-eo-ee.md`](pipeline-evaluation-eo-ee.md) ; ce document-ci est le
> « pourquoi et le quoi », pas le « comment c'est branché ».

> ⚠️ **Ce document doit rester à jour et exhaustif.** Dès qu'on change **une règle de
> notation, un barème, un critère, une consigne donnée à l'IA, une tâche, le comportement de
> l'examinateur vocal, ou le déroulé d'une correction**, il faut mettre à jour ce fichier
> **dans la même passe**. Il doit toujours pouvoir être lu et compris par une personne non
> technique. Pas de jargon non expliqué, pas de raccourci.

---

## 1. De quoi on parle : EE et EO

Le TCF IRN (le test de français exigé pour le titre de séjour, la résidence ou la
naturalisation) comporte deux épreuves où le candidat **produit** du français — au lieu de
juste cocher des cases :

- **EE — Expression Écrite** : le candidat **écrit** un texte (un message, un courriel, une
  opinion).
- **EO — Expression Orale** : le candidat **parle** (il s'enregistre, ou il dialogue avec un
  examinateur).

Dans les deux cas, il n'y a pas de « bonne réponse unique ». C'est une **appréciation** :
une IA joue le rôle d'un correcteur d'examen et attribue une note et des commentaires.

Chaque épreuve a **3 tâches** (T1, T2, T3), de difficulté croissante. Six tâches en tout :
EE T1, EE T2, EE T3, EO T1, EO T2, EO T3.

---

## 2. Les 6 tâches, en clair

| Tâche | Ce que le candidat doit faire | Format attendu | Niveau visé |
|-------|-------------------------------|----------------|-------------|
| **EE T1** | Écrire un **message court** : annoncer quelque chose, décrire, inviter | 30 à 60 mots | A2 |
| **EE T2** | Écrire un **message développé** : raconter, décrire, expliquer, conseiller | 40 à 90 mots | B1 |
| **EE T3** | **Donner son opinion** et l'argumenter, ou comparer | 40 à 90 mots | B2 |
| **EO T1** | **Se présenter** et parler de soi, de son quotidien (entretien dirigé) | ~3 min (min. 2 min) | A2 |
| **EO T2** | **Interagir** dans une situation de la vie courante (obtenir / donner des informations) | ~3 min 30 (min. 2 min) | B1 |
| **EO T3** | **Donner un point de vue** en continu (petit monologue argumenté) | ~3 min 30 (min. 2 min) | B2 |

> **« Niveau visé »** = le niveau pour lequel la tâche est conçue. **Ce n'est pas un plafond** :
> l'IA peut noter au-dessus ou en dessous selon ce que le candidat produit réellement.

**Mot important — « les questions du sujet ne sont que des pistes ».** Sur certaines tâches
(surtout EO T1 et EO T2), le sujet propose des questions ou des points pour aider le candidat
à se lancer (« parlez de votre travail, de vos loisirs… »). **Ce ne sont que des suggestions
d'orientation.** L'IA ne pénalise **pas** le candidat s'il ne les traite pas toutes : ce qui
compte, c'est sa capacité à échanger et à **se faire comprendre**, pas à cocher chaque point.

---

## 3. Le voyage d'une production, du rendu à la note

Voici ce qui se passe, étape par étape, quand un candidat rend une tâche.

### Cas EE (écrit)
1. Le candidat écrit son texte et l'envoie.
2. Le texte part directement à l'IA correctrice.
3. L'IA renvoie une note et des commentaires (en ~10-15 secondes).

### Cas EO « classique » (le candidat s'enregistre seul)
1. Le candidat s'enregistre (audio).
2. L'audio est stocké de façon **privée et sécurisée** (personne d'autre ne peut l'écouter
   sans autorisation).
3. Un logiciel de **transcription** (appelé *Whisper*) écrit **mot à mot** ce que le candidat
   a dit. Il transcrit **fidèlement**, y compris les hésitations et les fautes — on ne veut pas
   « embellir » ce que le candidat a produit.
4. Le texte transcrit part à l'IA correctrice.
5. Note + commentaires.

### Cas EO « temps réel » (le candidat dialogue avec l'examinateur vocal)
1. Le candidat parle **avec un examinateur IA à voix haute**, en direct (voir §6).
2. Pendant l'échange, **tout le dialogue est transcrit** au fil de l'eau (les tours de
   l'examinateur ET du candidat).
3. À la fin, ce dialogue transcrit part directement à l'IA correctrice (pas besoin de
   re-transcrire).
4. Note + commentaires.

> **Statuts d'une production** (ce que le candidat peut voir s'afficher) : *Soumise* → *(EO :
> Transcription en cours)* → *Évaluation en cours* → *Évaluée*. En cas de problème technique :
> *Échec* (le candidat peut relancer).

**Un point capital sur la transcription automatique.** La machine qui transcrit la voix
**fait des erreurs**, surtout en temps réel. Un candidat qui a parlé clairement peut se
retrouver avec un texte transcrit décousu ou bizarre. **L'IA correctrice est prévenue de
ça** et a des consignes strictes pour ne pas pénaliser le candidat à cause d'un défaut de
transcription (voir §5).

---

## 4. Comment l'IA attribue la note : les critères

Pour chaque tâche, l'IA note **4 critères** sur 20, puis on en fait une **moyenne pondérée**
(certains critères comptent plus que d'autres selon la tâche).

Les 4 critères :

- **Pertinence** — est-ce que le candidat **répond au sujet** et fait ce qui est demandé ?
- **Lexique** — la **richesse et la justesse du vocabulaire**.
- **Morphosyntaxe** — la **grammaire** (conjugaisons, accords, structures de phrases).
- **Cohérence** — le **fil du propos** : est-ce organisé, enchaîné, compréhensible ? (À l'oral
  en interaction, on y ajoute la **gestion de l'échange**.)

### Poids de chaque critère, tâche par tâche

Les nombres sont des **parts** (ils font 1,00 en tout). Plus le poids est grand, plus le
critère pèse dans la note.

| Tâche | Pertinence | Lexique | Morphosyntaxe | Cohérence |
|-------|:----------:|:-------:|:-------------:|:---------:|
| **EE T1** | 0,35 | 0,25 | 0,25 | 0,15 |
| **EE T2** | 0,25 | 0,25 | 0,25 | 0,25 |
| **EE T3** | 0,25 | 0,20 | 0,25 | 0,30 |
| **EO T1** | 0,35 | 0,30 | 0,20 | 0,15 |
| **EO T2** | 0,30 | 0,25 | 0,25 | 0,20 |
| **EO T3** | 0,25 | 0,25 | 0,25 | 0,25 |

**Comment lire ça, avec un exemple.** Sur EE T1, si l'IA met : pertinence 14, lexique 10,
morphosyntaxe 12, cohérence 11, alors :
`note = 14×0,35 + 10×0,25 + 12×0,25 + 11×0,15 = 12,05` → arrondi à **12/20**.

> **Détail important** : c'est **le serveur (SejourFR)** qui recalcule cette moyenne, pas l'IA.
> L'IA note les 4 critères ; le serveur fait le calcul officiel. Ça évite les incohérences
> (une IA qui mettrait « 16/20 » alors que ses critères sont bas).

### L'échelle de note /20 (la même pour tous, indépendante de la tâche)

| Note d'un critère | Ce que ça veut dire |
|-------------------|---------------------|
| 16 – 20 | Maîtrise de niveau B2 et plus |
| 11 – 15 | Niveau B1 |
| 6 – 10 | Niveau A2 |
| 1 – 5 | Niveau A1 |
| 0 | Hors-sujet (voir §5) |

L'IA note **en absolu** (sur toute l'échelle A1→C2), **pas** « par rapport au niveau visé de la
tâche ». Un candidat brillant sur une tâche A2 peut donc obtenir une note élevée.

---

## 5. Les règles spéciales que l'IA doit respecter

Ces règles existent pour que la note soit **juste** et **bienveillante**, et pour éviter les
pièges connus.

- **À l'oral, on ne juge QUE le texte transcrit.** L'IA **n'évalue pas** la prononciation,
  l'accent, l'intonation, le débit, ni la durée. Elle juge le contenu et la langue, comme un
  écrit. Elle **tolère** l'absence de ponctuation, les hésitations et tics oraux (« euh »,
  « ben », « du coup »), les répétitions, les faux départs. Elle **n'évalue pas
  l'orthographe** sur de l'oral transcrit (ce serait juger la machine de transcription, pas le
  candidat).

- **La transcription temps réel est peu fiable → bénéfice du doute.** Si un passage du
  candidat semble décousu ou incohérent, l'IA ne doit **pas** en conclure qu'il est
  « incompréhensible ». Elle reconstitue son intention à partir du dialogue et lui accorde le
  bénéfice du doute.

- **L'examinateur est le témoin de la compréhension.** Dans un dialogue (EO temps réel), si
  l'examinateur a **répondu de façon cohérente** à ce que le candidat venait de dire, c'est la
  **preuve** que le candidat s'est fait comprendre — même si son texte transcrit paraît fautif.
  L'IA doit porter cette réussite de communication au crédit du candidat. **L'objectif de
  l'épreuve, c'est la capacité à échanger et à se faire comprendre**, pas la propreté de la
  transcription.

- **On n'exige pas que toutes les questions du sujet soient posées.** (Voir §2.) Les questions
  du sujet orientent le candidat ; ne pas toutes les traiter n'est **pas** une faute. On juge
  la capacité à dialoguer et à se faire comprendre, pas l'exhaustivité ni la perfection.

- **La longueur n'est jamais pénalisée.** Si une production est acceptée, c'est que sa longueur
  a déjà été validée en amont. L'IA ne dira jamais « trop court » ou « trop long ».

- **Le hors-sujet, la seule vraie sanction lourde.** Si une production est **totalement**
  hors-sujet (elle ne répond pas du tout à la consigne, ou parle d'autre chose), la note tombe
  à **0** et le niveau à « A1 non atteint ». ⚠️ Attention : un texte **bruité par la
  transcription** n'est **pas** un hors-sujet. Le hors-sujet ne s'applique que si le candidat
  n'a manifestement rien produit d'exploitable (silence, sujet totalement étranger).

### Trois réglages **préparés mais éteints** (aucun effet aujourd'hui)

Ces trois comportements sont écrits, testés et livrés, mais **désactivés par défaut**. Tant
qu'ils ne sont pas allumés, **rien de ce qui suit ne se produit** : la notation décrite dans
tout le reste de ce document reste, mot pour mot, celle qui s'applique. Ils s'allument un par
un, après mesure sur le banc de calibration, en changeant une seule ligne de configuration
(section `sejourfr.production-evaluation` du fichier `application.yaml`, ou la variable
d'environnement indiquée).

| Réglage | Ce qu'il ferait une fois allumé | Clé de configuration (défaut : éteint) |
|---|---|---|
| **Débit et pauses** | Afficher, sous une production **orale**, deux mesures **factuelles** : le **débit** (mots par minute) et — seulement si la transcription porte des repères de temps — le **nombre de silences longs**. Ce sont des **informations**, jamais une note. | `fluidite.enabled` (`EVAL_FLUIDITE_ENABLED`) |
| **Seconde lecture en cas de doute** | Faire **recorriger** la production par une **seconde IA** quand la première est peu sûre d'elle (confiance faible, note juste à la frontière d'un niveau, ou désaccord marqué entre l'IA et le calcul du serveur). En cas de désaccord entre les deux, on retient la **note la plus basse** et on **baisse la confiance affichée**. | `seconde-passe.enabled` (`EVAL_SECONDE_PASSE_ENABLED`) |
| **Cohérence du bilan** | Interdire un **B2 au bilan** d'une épreuve quand la **tâche 3** (celle où l'on argumente et défend son avis) est **en dessous de B1**. Le bilan est alors ramené à B1. | `coherence-bilan.enabled` (`EVAL_COHERENCE_BILAN_ENABLED`) |

Deux précisions qui comptent :

- **Le débit ne devient pas un critère de note, même allumé.** C'est une mesure affichée à côté
  de la correction, avec la mention « ces mesures n'entrent pas dans votre note ni dans votre
  niveau ». Elle a été retenue parce qu'elle est **neutre vis-à-vis de l'accent** : compter des
  mots par minute ne favorise aucune langue maternelle, contrairement à une analyse de
  prononciation. Allumer ce réglage nuancerait la règle « on ne juge ni le débit ni la durée »
  énoncée plus haut : on **mesurerait** le débit, sans le **noter**.
- **La seconde lecture n'a d'intérêt qu'avec une IA différente.** Reposer exactement la même
  question au même modèle donne quasiment toujours la même réponse. Le modèle de la seconde
  lecture est donc configurable séparément (`seconde-passe.provider`), et l'application
  avertit au démarrage si on l'active sans en choisir un autre.

---

## 6. L'examinateur vocal (EO en temps réel)

Pour l'EO, le candidat peut passer un **vrai oral parlé** avec un examinateur joué par une IA
vocale (technologie Google Gemini Live). Deux choses à bien distinguer :

- **L'examinateur CONDUIT l'entretien. Il ne note pas.** Il pose des questions, réagit, joue
  un rôle (T2), mais il **ne corrige jamais**, **ne donne aucune note**, **ne laisse rien
  deviner** de l'évaluation. La note vient **après**, séparément, de l'IA correctrice (§3-§5).

- **L'examinateur reste dans son rôle et n'oriente pas.** Il **ne souffle jamais** au candidat
  quelles questions poser ou quelles informations demander. En T2 (jeu de rôle), c'est le
  **candidat** qui mène et pose les questions ; l'examinateur **répond** et attend, sans
  prendre l'initiative.

- **En Tâche 2, l'examinateur connaît ses réponses à l'avance.** Chaque sujet de jeu de rôle
  est accompagné d'une **fiche de scénario** : le rôle tenu, la manière de s'adresser au
  candidat (vouvoiement ou tutoiement), la phrase d'accueil, et surtout **les faits** —
  les prix, les délais, les horaires, les conditions. Avant, l'examinateur les inventait au
  fil de la conversation et pouvait **se contredire** (annoncer 12 €, puis 15 €), ce qui
  pénalisait injustement un candidat qui avait bien écouté. Désormais ces informations sont
  **fixées d'avance** : il ne peut ni les changer en route, ni en inventer d'autres. S'il
  n'a pas la réponse, il le dit simplement, sans donner de chiffre au hasard.

  Trois précisions importantes :
  - **Il ne les donne pas spontanément.** Il répond à la question posée, puis attend la
    suivante. C'est bien au candidat d'aller chercher l'information.
  - **Ce n'est pas une liste de questions obligatoires.** Les questions du sujet restent des
    **pistes** : ne pas toutes les poser n'a jamais été et n'est toujours pas une faute. La
    fiche sert à rendre l'examinateur cohérent, **pas** à cocher des cases. Une information
    non obtenue est une simple observation, elle **ne fait pas baisser la note**.
  - **Le candidat ne voit jamais cette fiche.** Elle reste côté serveur : l'afficher
    reviendrait à donner les réponses de l'examen.

  Si un sujet n'a pas encore de fiche, l'examinateur se comporte exactement comme avant :
  aucun sujet existant n'est dégradé.

Quelques réglages pensés pour le confort du candidat :

- **Le candidat lit d'abord son sujet, puis démarre quand il est prêt.** Avant chaque tâche, sa
  consigne (en Tâche 2, la situation du jeu de rôle) s'affiche à l'écran ; l'examinateur ne
  commence à parler qu'au moment où le candidat appuie sur « Commencer ». On ne bascule jamais
  dans l'oral sans lui laisser le temps de lire son sujet. Ce sujet **reste consultable** à
  l'écran pendant tout l'échange (utile en Tâche 2, où c'est le candidat qui mène).
- **Le chrono de la tâche ne démarre qu'au premier mot de l'examinateur.** Le temps de
  connexion et d'accueil n'est **pas** décompté du temps de parole du candidat.
- **L'examinateur est patient mais réactif.** Il laisse le candidat finir ses phrases (il ne le
  coupe pas sur une pause de réflexion), tout en répondant assez vite pour que l'échange reste
  fluide.
- **Quand le temps est écoulé, l'examinateur termine sa phrase de conclusion.** À la fin d'une
  tâche, on le laisse prononcer sa formule de clôture jusqu'au bout avant de fermer l'échange —
  il n'est pas coupé au milieu d'un mot, et il n'y a pas non plus de silence inutile avant de
  passer à la suite.
- **Il parle un français normal**, clair et accessible, sans s'adapter artificiellement au
  niveau du candidat (comme à un vrai examen). S'il n'a pas compris, il demande simplement de
  répéter.
- **Si le candidat ne dit rien, il n'y a rien à noter.** Quand on laisse seulement
  l'examinateur se présenter puis qu'on termine sans avoir parlé, aucune réponse n'a été
  produite : l'application l'annonce clairement (« Aucune prise de parole — rien à évaluer »)
  et invite à reprendre l'échange, au lieu d'ouvrir un bilan vide. Aucune note n'est calculée
  dans ce cas.

---

## 7. Ce que le candidat reçoit à la fin

Après l'évaluation, l'IA renvoie, en plus de la note /20 :

- **Points forts** — ce que le candidat a réussi (de vrais points, pas des compliments de
  politesse).
- **Points à améliorer** — les faiblesses concrètes à travailler.
- **Suggestions** — des conseils pédagogiques (règles à revoir, exercices).
- **Exemples corrigés** — des phrases exactes du candidat, réécrites en mieux, avec
  l'explication. (À l'oral, seulement des reformulations qui améliorent vraiment la clarté —
  jamais des corrections d'orthographe ou de mots isolés, qui seraient des artefacts de
  transcription.)
- **Une note par critère** (pertinence / lexique / morphosyntaxe / cohérence) avec un
  commentaire.
- *(Inactif aujourd'hui)* Sur une production orale, un encart **débit et pauses** —
  informations factuelles, hors note. Voir « Trois réglages préparés mais éteints » en §5.

### Et le niveau CECRL (A1, A2, B1, B2…) ?

Le **niveau CECRL** est le niveau de langue « officiel » (A1 débutant → C2 quasi natif).

Règle importante : **on n'affiche pas de niveau CECRL tâche par tâche.** Pourquoi ? Parce que
sur une seule production courte (par ex. un message de 40 mots), estimer un niveau global
serait peu fiable. Le niveau n'apparaît donc qu'au **bilan d'une épreuve complète** (un examen
blanc qui enchaîne les 3 tâches) :

- Le niveau du bilan = une **moyenne pondérée** des 3 tâches (les tâches plus difficiles
  comptent un peu plus, comme au vrai TCF).
- Il est **plafonné à B2** (le niveau utile pour la naturalisation ; C1/C2 ne sont pas
  fiables sur ces formats courts).
- Une tâche non rendue (temps écoulé, abandon) compte comme **0** dans la moyenne.
- *(Inactif aujourd'hui)* Une règle de cohérence peut interdire un **B2** au bilan quand la
  **tâche 3** est sous B1. Voir « Trois réglages préparés mais éteints » en §5.

En interne, le serveur calcule ce niveau à partir des critères qui **portent le niveau de
langue** : le **lexique**, la **morphosyntaxe** et la **cohérence**. La **pertinence** est
volontairement **exclue** de ce calcul : réussir une tâche simple ne prouve pas un haut niveau
de langue.

---

## 8. Où sont réglées ces règles (pour ceux qui veulent aller voir)

Toutes les instructions données à l'IA vivent dans des **fichiers de texte** (pas cachées dans
le code) — on peut donc les faire évoluer sans être développeur, en touchant le bon fichier :

| Ce qu'on veut changer | Fichier |
|-----------------------|---------|
| **Toutes les consignes de notation** (critères, poids, barème, règles spéciales, exemples de calibration, tolérance transcription, règle « pas d'exhaustivité »…) | `backend_sejourfr/src/main/resources/prompts/production-rubrics-v3.json` |
| **Le format de réponse de l'IA** (note, niveau, points forts, exemples corrigés…) | `backend_sejourfr/src/main/resources/prompts/production-evaluation-tool-schema-v1.5.json` |
| **Le comportement de l'examinateur vocal** (ton, cadre, interdiction d'orienter le candidat, ouverture T1/T2, façon de rendre la fiche de scénario T2…) | `backend_sejourfr/src/main/resources/prompts/realtime-personas-v2.json` (version active ; la v1, sans fiche de scénario, reste disponible en repli) |
| **Les faits d'un jeu de rôle T2** (prix, délais, horaires, attitude du personnage) | colonne `agent_role_card` du sujet, en base — renseignée par les migrations `db/migration/300_tcf/production/eo/tache_2/` |
| **La patience / réactivité de l'examinateur vocal** (détection de fin de parole) | `backend_sejourfr/src/main/resources/application.yaml` (section `sejourfr.realtime.gemini.vad`) |
| **Les trois réglages éteints** (débit et pauses, seconde lecture, cohérence du bilan — cf. §5) | `backend_sejourfr/src/main/resources/application.yaml` (section `sejourfr.production-evaluation`, blocs `fluidite`, `seconde-passe`, `coherence-bilan`) |

> **Deux garde-fous automatiques** : au démarrage, l'application **refuse de démarrer** si les
> consignes de notation sont incohérentes (un critère inconnu, des poids qui ne font pas 1,00,
> une tâche sans barème…). Et si l'IA rend une note très différente du calcul officiel, l'écart
> est enregistré pour surveillance.

Pour le détail **technique** (services, base de données, providers d'IA, stockage des audios,
versions de prompts, calibration admin), voir
[`pipeline-evaluation-eo-ee.md`](pipeline-evaluation-eo-ee.md) et
[`SPEC_MODULE_EXPRESSION_EO_EE.md`](SPEC_MODULE_EXPRESSION_EO_EE.md). Pour la génération des
audios de compréhension orale (autre pipeline), voir
[`pipeline-audio-co.md`](pipeline-audio-co.md).

---

## 9. Résumé en une phrase

L'IA joue un correcteur d'examen **bienveillant et juste** : elle note 4 critères sur 20 pour
chaque tâche, le serveur en fait la note officielle, elle explique ses commentaires — et elle
juge avant tout la **capacité du candidat à communiquer et à se faire comprendre**, sans le
pénaliser pour une transcription imparfaite ni pour ne pas avoir tout dit.
