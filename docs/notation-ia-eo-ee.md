# Comment l'IA corrige les productions (Expression Écrite & Orale)

> **À qui s'adresse ce document ?** À tout le monde — pas besoin d'être développeur.
> Il explique, en langage simple, **comment l'intelligence artificielle note** ce que le
> candidat écrit (EE) ou dit à l'oral (EO) sur SejourFR, tâche par tâche, et **selon quelles
> règles**. Il dit aussi **ce qui marche, ce qui marche mal, et comment on le sait**. Une
> version plus technique (fichiers, code, base de données) existe dans
> [`pipeline-evaluation-eo-ee.md`](pipeline-evaluation-eo-ee.md) ; ce document-ci est le
> « pourquoi et le quoi », pas le « comment c'est branché ».

> ⚠️ **Ce document doit rester à jour et exhaustif.** Dès qu'on change **une règle de
> notation, un barème, un critère, une consigne donnée à l'IA, une tâche, le comportement de
> l'examinateur vocal, ou le déroulé d'une correction**, il faut mettre à jour ce fichier
> **dans la même passe**. Il doit toujours pouvoir être lu et compris par une personne non
> technique. Pas de jargon non expliqué, pas de raccourci.

**État actuel** : rubriques de notation **v4.1**, format de réponse **v2**, examinateur vocal
**v2**. Ce que ces numéros veulent dire, et où ils se changent, est expliqué en §15.

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
> l'IA peut noter au-dessus ou en dessous selon ce que le candidat produit réellement. Un
> candidat brillant sur une tâche A2 peut donc obtenir une note élevée ; un candidat faible
> sur une tâche B2 sera noté A1 ou A2.

---

## 3. Le parcours d'une production, du rendu à la note

### Cas EE (écrit)

1. Le candidat écrit son texte et l'envoie.
2. Le serveur passe **trois vérifications automatiques**, sans IA (voir §4).
3. Si tout va bien, le texte part à l'IA correctrice.
4. L'IA renvoie une note et des commentaires (en ~10-15 secondes).
5. Le serveur **recalcule** la note, le niveau, et applique ses propres règles (§5, §6).

### Cas EO « classique » (le candidat s'enregistre seul)

1. Le candidat s'enregistre (audio).
2. L'audio est stocké de façon **privée et sécurisée** (personne d'autre ne peut l'écouter
   sans autorisation).
3. Un logiciel de **transcription** (appelé *Whisper*) écrit **mot à mot** ce que le candidat
   a dit. Il transcrit **fidèlement**, y compris les hésitations et les fautes — on ne veut pas
   « embellir » ce que le candidat a produit.
4. Le texte transcrit passe par les mêmes vérifications automatiques, puis part à l'IA.
5. Note + commentaires.

### Cas EO « temps réel » (le candidat dialogue avec l'examinateur vocal)

Ce mode existe pour les **tâches 1 et 2** de l'oral. La tâche 3 (monologue) se passe toujours
en enregistrement.

1. Le candidat parle **avec un examinateur IA à voix haute**, en direct (voir §10).
2. Pendant l'échange, **tout le dialogue est transcrit** au fil de l'eau (les tours de
   l'examinateur ET du candidat).
3. À la fin, ce dialogue transcrit part directement à l'IA correctrice (pas besoin de
   re-transcrire).
4. Note + commentaires. La **confiance** de l'évaluation est automatiquement plafonnée à
   « moyenne » dans ce cas (voir §7) : une transcription faite en direct est moins sûre.

> **Statuts d'une production** (ce que le candidat peut voir s'afficher) : *Soumise* → *(EO :
> Transcription en cours)* → *Évaluation en cours* → *Évaluée*. En cas de problème technique :
> *Échec* (le candidat peut relancer).

**Un point capital sur la transcription automatique.** La machine qui transcrit la voix
**fait des erreurs**, surtout en temps réel. Un candidat qui a parlé clairement peut se
retrouver avec un texte transcrit décousu ou bizarre. **L'IA correctrice est prévenue de
ça** et a des consignes strictes pour ne pas pénaliser le candidat à cause d'un défaut de
transcription (voir §8).

---

## 4. Avant l'IA : trois vérifications automatiques

Ces contrôles sont faits par le serveur, **sans aucune IA**. Ce sont de simples calculs.
Ils évitent des notes absurdes et des appels payants inutiles.

| Ce qui est vérifié | Comment | Ce qui arrive au candidat |
|---|---|---|
| **La production est-elle vide ou quasi vide ?** | Moins de 5 mots exploitables. Dans un dialogue oral, on ne compte **que** les tours du candidat : si l'examinateur a parlé seul, il n'y a rien à corriger. | **Production refusée avant l'IA.** Note 0, niveau « A1 non atteint », confiance faible, et un message clair : « Nous n'avons trouvé aucune prise de parole exploitable de votre part. » |
| **Le texte est-il en français ?** | Deux mesures : la part de lettres d'un **autre alphabet** (arabe, cyrillique…), et la part de **petits mots français très fréquents** (le, la, de, que, je, vous…). Un texte français en contient beaucoup ; un texte anglais ou espagnol, presque aucun. L'analyse ne se déclenche qu'à partir de 12 mots — en dessous, la mesure ne veut rien dire. | **Beaucoup d'autre alphabet, ou presque aucun mot français** → production refusée avant l'IA, avec l'explication. **Cas intermédiaire** (une partie du texte semble ne pas être en français) → l'IA note quand même, mais la confiance est plafonnée à « moyenne » et la raison est affichée. |
| **La consigne a-t-elle été recopiée ?** | On compare des suites de 5 mots entre la production et l'énoncé du sujet. | **Plus de 60 % recopié** → refusé : ce n'est plus une production personnelle. **Entre 30 et 60 %** → l'IA note, confiance plafonnée à « moyenne », et le candidat est averti que seuls ses propres mots comptent. |

Les seuils ci-dessus sont **volontairement prudents** : mieux vaut laisser passer une
production douteuse que bloquer un vrai candidat maladroit.

---

## 5. Comment l'IA note : des critères propres à chaque tâche

### 5.1 Il n'y a plus de critères universels

Jusqu'à la version 3 des consignes de notation, l'IA notait **les mêmes 4 critères** sur les
6 tâches : pertinence, lexique, morphosyntaxe, cohérence. Seuls les poids changeaient.

Le défaut était structurel : **des questions génériques donnent des commentaires génériques.**
Sur EO T2 (obtenir des informations dans un dialogue), « cohérence » ne veut pas dire
grand-chose ; ce qui compte vraiment, c'est *« est-ce que le candidat a mené l'échange et
obtenu ce qu'il cherchait ? »* — et ce critère n'existait nulle part.

Depuis la version 4, **chaque tâche a ses propres critères** : 5 par tâche. Trois sont
communs à toutes (lexique, morphosyntaxe, cohérence) ; les deux autres changent selon ce que
la tâche demande vraiment.

Deux familles, qui ne jouent pas le même rôle :

- **Les critères porteurs du niveau** — le **lexique** (richesse et justesse du vocabulaire),
  la **morphosyntaxe** (grammaire : conjugaisons, accords, construction des phrases) et la
  **cohérence** (organisation et enchaînement du propos). Ce sont eux qui décident du niveau
  de langue.
- **Les critères de tâche** — réalisation de la consigne, conduite de l'échange,
  argumentation, adéquation au destinataire, chronologie… Ils mesurent la **réussite de la
  tâche**, pas le niveau de langue.

### 5.2 Les critères et leurs poids, tâche par tâche

Les pourcentages font 100 % pour chaque tâche. Plus le pourcentage est grand, plus le critère
pèse dans la note.

**EE T1 — message court (annoncer, décrire, inviter)**

| Critère | Poids | Ce que l'IA regarde |
|---|:--:|---|
| Réalisation de la consigne | 30 % | Les points **obligatoires** de la consigne sont-ils traités de façon compréhensible ? |
| Adéquation au destinataire et au registre | 15 % | Formule d'appel et de clôture présentes et adaptées (ami, famille, collègue), ton tenu du début à la fin. |
| Étendue et maîtrise du lexique | 20 % | Variété et précision du vocabulaire. |
| Correction morphosyntaxique | 20 % | Conjugaisons, accords, déterminants, prépositions, construction des phrases. |
| Clarté et enchaînement du message | 15 % | Le message se lit-il d'un trait ? (Faiblement pondéré : le texte est court.) |

**EE T2 — message développé (raconter, décrire, expliquer, conseiller)**

| Critère | Poids | Ce que l'IA regarde |
|---|:--:|---|
| Réalisation du récit ou du compte rendu | 25 % | Le contenu demandé est-il là, avec des détails ? |
| Chronologie et repères temporels | 20 % | Les faits s'enchaînent-ils dans un ordre clair, avec des repères de temps ? |
| Cohérence et organisation | 15 % | Organisation d'ensemble du texte. |
| Étendue et maîtrise du lexique | 20 % | |
| Correction morphosyntaxique | 20 % | |

**EE T3 — prise de position / opinion argumentée / comparaison**

| Critère | Poids | Ce que l'IA regarde |
|---|:--:|---|
| Prise de position claire | 20 % | Le candidat tranche-t-il vraiment ? |
| Justification et développement des arguments | 25 % | Arguments distincts, exemples, plan apparent. |
| Organisation et connecteurs logiques | 15 % | |
| Étendue et maîtrise du lexique | 20 % | |
| Correction morphosyntaxique | 20 % | |

**EO T1 — entretien dirigé (se présenter, parler de soi)**

| Critère | Poids | Ce que l'IA regarde |
|---|:--:|---|
| Réponse à la consigne et présentation de soi | 25 % | Se présente-t-il et parle-t-il de son quotidien de façon compréhensible ? |
| Développement des réponses | 20 % | Développe-t-il spontanément, ou répond-il par trois mots ? |
| Étendue et maîtrise du lexique | 25 % | |
| Correction grammaticale perceptible | 15 % | |
| Cohérence du propos | 15 % | |

**EO T2 — interaction (obtenir / donner des informations)**

| Critère | Poids | Ce que l'IA regarde |
|---|:--:|---|
| Conduite de l'échange et obtention des informations | 30 % | Mène-t-il le dialogue, relance-t-il, obtient-il ce qu'il cherche ? **C'est le critère central de cette tâche.** |
| Adéquation à l'interlocuteur et au registre | 15 % | |
| Étendue et maîtrise du lexique | 20 % | |
| Correction grammaticale perceptible | 20 % | |
| Cohérence des interventions | 15 % | |

**EO T3 — point de vue / monologue suivi**

| Critère | Poids | Ce que l'IA regarde |
|---|:--:|---|
| Point de vue clair et réponse à la question | 20 % | |
| Développement des arguments et exemples | 25 % | |
| Organisation du monologue | 20 % | |
| Étendue et maîtrise du lexique | 20 % | |
| Correction grammaticale perceptible | 15 % | |

> **C'est le serveur qui calcule la note, pas l'IA.** L'IA note chaque critère sur 20 ; le
> serveur applique les pourcentages ci-dessus et **écrase** la note d'ensemble que l'IA avait
> proposée. Ça évite les incohérences (une IA qui annoncerait « 16/20 » avec des critères
> bas). Si l'écart entre les deux dépasse 3 points, c'est enregistré pour surveillance.

### 5.3 Points **obligatoires** et **pistes suggérées** — la règle centrale

Une consigne mélange deux choses très différentes, et l'IA doit les séparer **avant** de
noter :

- **Les points obligatoires** : ce que la consigne demande explicitement de faire — ses
  verbes d'action (annoncer, décrire, inviter, raconter, conseiller, donner son avis) et les
  informations qu'elle exige. **Ils comptent dans la note.** Un point obligatoire non traité
  fait baisser le critère de réalisation de la tâche — **et lui seul**, jamais le lexique ni
  la grammaire.
- **Les pistes suggérées** : les exemples, idées, thèmes ou questions que le sujet propose
  pour aider (« vous pouvez parler de votre travail, de vos loisirs… », listes de questions
  possibles). **Une piste non traitée n'enlève aucun point.** Jamais. Elle n'est jamais
  présentée comme un manque, jamais mise dans les points à améliorer. Au mieux, elle est
  signalée à titre purement informatif.

**En cas de doute sur le statut d'un point, l'IA doit le traiter comme une piste** : le doute
profite au candidat. Sur EO T1 et EO T2 en particulier, le sujet ne fournit pratiquement que
des pistes — on n'y exige **jamais** l'exhaustivité. Un échange incomplet mais réussi répond
aux attentes.

### 5.4 Le bloc « ce que vous avez traité / ce que vous avez oublié »

C'est la première chose que voit le candidat, **avant** tout ce qui concerne la grammaire.

Avant, un candidat qui oubliait un tiers de la consigne voyait « 14/20 » et un commentaire
vague. Il ne savait pas ce qu'il avait raté.

Désormais l'IA remplit obligatoirement deux listes, en langue simple :

```
Ce que vous avez traité      ✓ Nouvelle annoncée
                             ✓ Logement décrit
Ce qui manque                ○ Invitation absente
```

Chaque ligne porte une indication invisible mais décisive : **obligatoire** ou **piste**. Un
manque marqué « piste » n'a **aucune conséquence sur la note**. Aucun calcul de note ne lit
ces marqueurs — c'est une garantie, pas une intention.

Un point partiellement traité est compté comme traité, avec la réserve exprimée dans le
commentaire du critère. Et l'IA a l'interdiction de **fabriquer** un manque pour remplir la
liste : si tout est traité, la liste des oublis reste vide.

### 5.5 Preuves et priorités

- **Chaque critère noté doit s'appuyer sur une citation littérale** de la production (3 à 15
  mots, recopiée exactement). Si l'IA cite une phrase qui **ne figure pas** dans la
  production, le serveur la supprime avant affichage : une fausse citation détruit la
  confiance dans toute la correction. Dans un dialogue, seules les prises de parole du
  **candidat** peuvent être citées.
- **Deux points à améliorer, au maximum.** Les deux plus utiles, le plus important d'abord.
  Une liste de dix reproches décourage et n'apprend rien. Le reste part dans les
  « suggestions », formulées comme des conseils d'entraînement.
- Les points forts suivent la même exigence : de vrais points forts cités dans le texte,
  jamais un compliment de politesse.

### 5.6 Ce qui empêche l'IA d'être trop gentille

Deux garde-fous écrits dans les consignes de notation, ajoutés après **mesure** (voir §12) :

**« Une tolérance lève une sanction, elle n'accorde pas de point. »** Les règles de tolérance
(§8) interdisent de retirer des points pour la longueur, l'orthographe à l'oral, les
hésitations, les pistes non traitées, les défauts de transcription. Elles restent
**entièrement valables**. Mais elles disent seulement ce qu'il ne faut **pas sanctionner** :
aucune ne dit que la production devient **bonne** pour autant.

> Une production sans faute parce qu'elle n'a rien tenté de difficile ne mérite pas une note
> haute. Une production courte est **recevable**, elle n'est pas pour autant riche. Une
> transcription bruitée, sur laquelle il est interdit de conclure à l'incompréhensibilité, ne
> devient pas une preuve de maîtrise : on ignore le bruit, puis on note ce qui reste
> observable — ni plus, ni moins.
>
> **Le doute profite au candidat sur ce qu'il a voulu dire** (le sens, l'intention, ce que la
> transcription a abîmé), **jamais sur ce qu'il n'a pas produit** (la complexité, l'étendue,
> la variété, l'organisation).

**Le couplage tâche ↔ langue.** Une tâche est toujours accomplie **avec** des moyens
linguistiques. Un critère de tâche ne peut donc pas dépasser de plus de **4 points** la
moyenne du lexique et de la morphosyntaxe. Réussir une tâche simple avec un français très
pauvre est une réussite **partielle**, pas une réussite exemplaire. Ce garde-fou ne mord
qu'en bas d'échelle : à partir de B1, il n'est jamais contraignant, et il ne sert jamais à
rogner une production riche.

**L'ancrage du bas de l'échelle.** C'est la zone où une erreur coûte le plus cher au
candidat : lui annoncer B1 alors qu'il est A2, c'est lui faire payer un examen officiel qu'il
va rater. Les consignes contiennent donc un test explicite : pour dépasser A1, il faut
qu'apparaisse au moins un marqueur réellement construit — une subordonnée (« je pense **que**
… », « un homme **qui** … »), un temps du passé ou du futur correctement formé, ou une
tournure de politesse construite (« je voudrais », « est-ce que »). **Si l'IA classe A2 ou
au-dessus, elle doit citer le marqueur qu'elle a trouvé.** Si elle ne peut pas le citer, c'est
qu'il n'existe pas.

Et une phrase qui résume tout : **« correction n'est pas niveau »**. Une production simple,
courte, propre et sans faute reste A2 si elle n'emploie que des structures élémentaires. Ce
n'est pas la correction qui fait monter le niveau, c'est l'**étendue** et la **complexité**.
Le piège le plus fréquent est l'énumération : réciter son nom, son âge, sa ville, son travail
et sa famille en phrases toutes construites sur le même moule, sans une faute, reste du A1.

---

## 6. La note et le niveau

### 6.1 L'échelle interne, sur 20

Chaque critère est noté sur 20, **en absolu** (sur toute l'échelle A1→C2), pas « par rapport
au niveau visé de la tâche ».

| Note d'un critère | Correspondance |
|-------------------|----------------|
| 16 – 20 | Maîtrise de niveau B2 et plus |
| 11 – 15 | Niveau B1 |
| 6 – 10 | Niveau A2 |
| 1 – 5 | Niveau A1 |
| 0 | Hors-sujet (voir §8) |

L'IA doit aussi vérifier que sa **note d'ensemble** est cohérente avec le niveau qu'elle
annonce. Repères : A1 non atteint 0-3 · A1 2-7 · A2 6-12 · B1 11-16 · B2 15-20. Ces bandes se
chevauchent volontairement — elles **bornent**, elles ne dictent pas la note. Mais une
production classée A1 ne doit pas ressortir à 12/20.

### 6.2 Ce que le candidat voit : des bandes, pas des chiffres, par critère

**Une IA ne distingue pas honnêtement un 13 d'un 14.** Afficher « Lexique : 13/20 » suggère
une précision qui n'existe pas. Depuis la version 4, **le candidat voit une appréciation par
critère**, pas un nombre :

| Note interne | Ce qui s'affiche |
|---|---|
| 16 – 20 | Très bonne maîtrise |
| 11 – 15 | Satisfaisant |
| 6 – 10 | En cours d'acquisition |
| 1 – 5 | Fragile |
| 0 | Non évaluable |

**La note globale sur 20 reste affichée**, elle. C'est le repère qu'un candidat attend d'un
examen, et la fausse précision est un problème au niveau du critère (5 nombres qui bougent),
pas au niveau du résultat d'ensemble. Les notes chiffrées par critère continuent d'exister en
interne : elles servent au calcul, au banc de mesure et à la console d'administration.

### 6.3 Le niveau CECRL par tâche : « performance observée »

Le **niveau CECRL** est le niveau de langue « officiel » (A1 débutant → C2 quasi natif).

Il est désormais affiché **sur chaque tâche**, mais dans une formulation volontairement
prudente :

> **Performance observée sur cette tâche : proche du niveau B1**
> Estimation pédagogique portant sur cette seule tâche. Le niveau qui fait foi est celui du
> bilan des trois tâches de l'épreuve.

Trois garde-fous, non négociables :

1. Le mot « proche de » et le rappel du bilan sont **toujours** affichés avec le niveau.
2. Ce niveau **n'est jamais affiché sans la confiance** (§7). Techniquement, si la confiance
   est inconnue, le niveau n'est pas envoyé du tout.
3. Le **bilan d'épreuve** reste le **seul** niveau qui fait foi.

**Comment ce niveau est calculé.** Pas par l'IA : par le serveur. Il fait la moyenne des trois
critères porteurs du niveau — **lexique, morphosyntaxe, cohérence** — et la compare à des
seuils :

| Moyenne des trois critères | Niveau |
|---|---|
| 15 et plus | B2 (plafond) |
| 12 à 14,9 | B1 |
| 8 à 11,9 | A2 |
| au-dessus de 0, sous 8 | A1 |
| exactement 0 | A1 non atteint |

Les critères de **tâche** sont volontairement **exclus** de ce calcul : réussir une tâche
simple ne prouve pas un haut niveau de langue. Le niveau que l'IA propose de son côté est
conservé en base pour la calibration, mais **n'est jamais affiché**.

Le seuil A2 est passé de 7 à **8** — c'est le seul déplacement de seuil que la mesure a
montré comme entièrement bénéfique (voir §12).

### 6.4 Deux plafonds ciblés

Après le calcul du niveau, le serveur applique deux règles qui ne peuvent qu'**abaisser** un
niveau, jamais le relever :

- **Tâche 3 (écrite ou orale) sans opinion identifiable** — si le critère « prise de
  position » est à 5/20 ou moins, la tâche consiste précisément à donner et défendre un avis :
  le niveau observé ne peut pas dépasser **A2**.
- **Oral, tâche 2, sans véritable échange** — si le critère « conduite de l'échange » est à
  5/20 ou moins, le dialogue n'a pas vraiment eu lieu : même plafond, **A2**.

Dans les deux cas, le candidat reçoit l'explication en clair, pas seulement un chiffre plus
bas.

### 6.5 Le bilan d'une épreuve complète

C'est le seul niveau qui fait foi. Il apparaît à la fin d'un examen blanc qui enchaîne les
3 tâches d'une épreuve.

- Le niveau du bilan est une **moyenne pondérée** des trois tâches : la tâche 1 compte pour
  1, la tâche 2 pour 2, la tâche 3 pour 3 — les tâches plus difficiles pèsent plus, comme au
  vrai TCF.
- Il est **plafonné à B2** (le niveau utile pour la naturalisation ; C1/C2 ne sont pas
  fiables sur ces formats courts).
- Une tâche non rendue (temps écoulé, abandon) compte comme **0**.
- Une production hors-sujet compte 0 elle aussi : elle pénalise sans annuler le reste.

---

## 7. La confiance : dire quand on n'est pas sûr

Avant, « 13/20 » s'affichait sur le même ton, qu'il s'agisse d'un texte écrit propre de
90 mots ou d'un dialogue oral transcrit en direct, haché, à moitié illisible. **Ce n'était pas
honnête.**

L'IA déclare désormais obligatoirement une **confiance** :

| Confiance | Quand |
|---|---|
| **Haute** | Production complète et lisible, consigne claire, marqueurs de langue nombreux et nets. |
| **Moyenne** | Production courte mais exploitable, transcription partiellement incertaine, quelques passages ambigus, hésitation entre deux niveaux voisins. |
| **Faible** | Transcription très bruitée, tâche manifestement incomplète ou interrompue, production trop pauvre pour observer la grammaire ou le lexique. |

Elle donne 1 à 3 **raisons courtes et lisibles par le candidat** : « transcription temps réel
partiellement incertaine », « production très courte, peu de marqueurs grammaticaux
observables », « échange interrompu avant la fin ».

**Le serveur peut abaisser cette confiance, jamais la relever.** Elle est automatiquement
plafonnée à « moyenne » dans deux cas : quand les vérifications automatiques (§4) ont signalé
un doute, et quand la production vient d'un **dialogue en temps réel**.

Deux interdits absolus :

- **la confiance ne baisse jamais la note.** La confiance dit ce qu'on **sait** ; la note dit
  ce qu'on a **observé** ;
- une confiance faible n'autorise **jamais** à conclure au hors-sujet ni à
  l'incompréhensibilité.

Si l'IA oublie de déclarer une confiance, le serveur met « moyenne » : l'absence
d'information n'est pas une certitude.

---

## 8. Les règles spéciales que l'IA doit respecter

Ces règles existent pour que la note soit **juste**, et pour éviter les pièges connus. Elles
sont toutes encadrées par la règle du §5.6 : *ne pas sanctionner n'est pas créditer*.

- **À l'oral, on ne juge QUE le texte transcrit.** L'IA **n'évalue pas** la prononciation,
  l'accent, l'intonation, le débit, ni la durée. Elle juge le contenu et la langue, comme un
  écrit. Elle **tolère** l'absence de ponctuation, les hésitations et tics oraux (« euh »,
  « ben », « du coup »), les répétitions, les faux départs. Elle **n'évalue pas
  l'orthographe** sur de l'oral transcrit (ce serait juger la machine de transcription, pas le
  candidat). Voir §9 pour ce que cette limite implique vraiment.

- **La transcription temps réel est peu fiable → bénéfice du doute.** Si un passage du
  candidat semble décousu ou incohérent, l'IA ne doit **pas** en conclure qu'il est
  « incompréhensible ». Elle reconstitue son intention à partir du dialogue et lui accorde le
  bénéfice du doute. Un texte bruité justifie une confiance **moyenne ou faible**, jamais une
  note basse.

- **L'examinateur est le témoin de la compréhension.** Dans un dialogue (EO temps réel), si
  l'examinateur a **répondu de façon cohérente** à ce que le candidat venait de dire, c'est la
  **preuve** que le candidat s'est fait comprendre — même si son texte transcrit paraît fautif.
  L'IA doit porter cette réussite de communication au crédit du candidat, **dans le critère de
  conduite de l'échange** — jamais dans le lexique ni la grammaire.

- **On n'exige jamais l'exhaustivité.** Voir §5.3 : les pistes du sujet ne coûtent rien.

- **La longueur n'est jamais pénalisée.** Si une production est acceptée, c'est que sa
  longueur a déjà été validée en amont. L'IA ne dira jamais « trop court » ou « trop long ».
  Deux nuances honnêtes : une production courte donne légitimement une confiance moyenne
  (moins de matière observable) ; et moins on écrit ou on parle, moins on a d'occasions de
  **démontrer** un niveau élevé — ce n'est pas une pénalité, c'est une conséquence. Sur une
  production orale nettement plus courte que la cible, l'application ajoute d'ailleurs un
  rappel en ce sens.

- **Le hors-sujet, la seule vraie sanction lourde.** Si une production est **totalement**
  hors-sujet (elle ne répond pas du tout à la consigne, ou parle d'autre chose), la note tombe
  à **0** sur **tous** les critères, y compris le lexique et la grammaire, et le niveau à
  « A1 non atteint » — **même si la langue employée est correcte ou riche**. Un hors-sujet
  **partiel**, lui, ne déclenche pas le 0 : il fait fortement baisser le critère de
  réalisation de la tâche, sans annuler la note. ⚠️ Attention : un texte **bruité par la
  transcription** n'est **pas** un hors-sujet.

- **À l'oral, pas de correction d'orthographe.** Les exemples corrigés ne contiennent que des
  reformulations de **phrase** qui améliorent vraiment la clarté. Jamais une correction
  d'orthographe, d'accent, de ponctuation ou d'un mot isolé — ce sont des artefacts de la
  machine de transcription, pas des erreurs du candidat. Le serveur applique ce filtre une
  seconde fois, après l'IA, par sécurité.

---

## 9. L'oral : ce que nous ne savons pas évaluer

**C'est une limite technique, pas un choix pédagogique — et le candidat en est informé.**

À l'oral, nous n'avons que le **texte transcrit**. Nous savons donc évaluer le vocabulaire,
la grammaire, le contenu, l'organisation, et une bonne partie de l'interaction. Nous **ne
savons pas** évaluer l'aisance, la fluidité, le débit, les vraies hésitations,
l'intelligibilité et la prononciation — qui comptent pourtant à l'examen officiel.

Chaque correction orale porte donc cet avertissement, mot pour mot :

> Cette évaluation est fondée sur la transcription écrite de votre production : nous
> n'analysons pas votre voix. L'aisance, la fluidité, le débit et la prononciation ne sont
> donc pas évalués ici — c'est une limite technique de notre correction, pas un choix
> pédagogique. À l'examen officiel, ces dimensions comptent.

Il est **interdit** à l'IA de présenter cette absence comme un avantage (« votre accent n'est
pas pénalisé »), et interdit de dire quoi que ce soit de l'accent, de l'aisance ou de la
fluidité — elle ne les a pas entendus.

**Pourquoi on ne corrige pas ça tout de suite.** Deux obstacles sérieux :

1. **Pour deux tâches sur trois, l'audio n'existe pas de notre côté.** En oral temps réel
   (T1 et T2), le candidat parle **directement** au fournisseur de voix ; seul du texte nous
   revient. Analyser la voix supposerait de capturer et remonter l'audio : nouveau chantier,
   nouveau coût de stockage, et une vraie question de vie privée. En l'état, on ne pourrait
   analyser que les productions **enregistrées** — et deux candidats seraient alors notés sur
   des critères différents selon le mode choisi. Inacceptable.
2. **Un risque d'équité.** Notre public, ce sont des personnes en démarche de titre de séjour
   ou de naturalisation, donc massivement des accents non natifs. Demander à une IA de juger
   « prononciation et fluidité » sur de l'audio, c'est précisément le terrain où ces modèles
   sont connus pour être moins performants selon l'accent et la langue maternelle. On
   risquerait de fabriquer un correcteur qui pénalise systématiquement certaines origines.

Une mesure **neutre vis-à-vis de l'accent** est déjà écrite mais **éteinte** : le débit
(mots par minute) et le nombre de silences longs. Voir §13.

---

## 10. L'examinateur vocal (EO en temps réel)

Pour l'EO tâches 1 et 2, le candidat peut passer un **vrai oral parlé** avec un examinateur
joué par une IA vocale (technologie Google Gemini Live). Deux choses à bien distinguer :

- **L'examinateur CONDUIT l'entretien. Il ne note pas.** Il pose des questions, réagit, joue
  un rôle (T2), mais il **ne corrige jamais**, **ne donne aucune note**, **ne laisse rien
  deviner** de l'évaluation. La note vient **après**, séparément, de l'IA correctrice.

- **L'examinateur reste dans son rôle et n'oriente pas.** Il **ne souffle jamais** au candidat
  quelles questions poser ou quelles informations demander. En T2 (jeu de rôle), c'est le
  **candidat** qui mène et pose les questions ; l'examinateur **répond** et attend, sans
  prendre l'initiative.

### La fiche de scénario de la tâche 2

**En tâche 2, l'examinateur connaît ses réponses à l'avance.** Chaque sujet de jeu de rôle est
accompagné d'une **fiche de scénario** : le rôle tenu, la manière de s'adresser au candidat
(vouvoiement ou tutoiement), la phrase d'accueil, et surtout **les faits** — les prix, les
délais, les horaires, les conditions.

Avant, l'examinateur les inventait au fil de la conversation et pouvait **se contredire**
(annoncer 12 €, puis 15 €), ce qui pénalisait injustement un candidat qui avait bien écouté.
Désormais ces informations sont **fixées d'avance** : il ne peut ni les changer en route, ni
en inventer d'autres. S'il n'a pas la réponse, il le dit simplement, sans donner de chiffre au
hasard. Si le candidat lui prête une valeur fausse, il corrige **le fait** avec naturel —
jamais la langue du candidat.

Quatre précisions qui comptent :

- **Ce n'est PAS une check-list de notation.** Les questions du sujet restent des **pistes** :
  ne pas toutes les poser n'a jamais été et n'est toujours pas une faute. La fiche sert à
  rendre l'examinateur **cohérent**, pas à cocher des cases. Une information non obtenue est
  au plus une observation informative ; elle **ne fait baisser aucune note**. La fiche n'est
  d'ailleurs jamais transmise à l'IA correctrice.
- **Il ne livre pas ses informations spontanément.** Il répond à la question posée, puis
  attend la suivante. C'est bien au candidat d'aller chercher l'information.
- **Le candidat ne voit jamais cette fiche.** Elle reste côté serveur : l'afficher
  reviendrait à donner les réponses de l'examen.
- Les **20 sujets** de tâche 2 existants ont tous leur fiche. Si un sujet futur n'en avait
  pas, l'examinateur se comporterait exactement comme avant : aucun sujet n'est dégradé.

### Réglages pensés pour le confort du candidat

- **Le candidat lit d'abord son sujet, puis démarre quand il est prêt.** Avant chaque tâche, sa
  consigne (en Tâche 2, la situation du jeu de rôle) s'affiche à l'écran ; l'examinateur ne
  commence à parler qu'au moment où le candidat appuie sur « Commencer ». Ce sujet **reste
  consultable** pendant tout l'échange (utile en Tâche 2, où c'est le candidat qui mène).
- **Le chrono de la tâche ne démarre qu'au premier mot de l'examinateur.** Le temps de
  connexion et d'accueil n'est **pas** décompté du temps de parole du candidat.
- **L'examinateur est patient mais réactif.** Il laisse le candidat finir ses phrases (il ne le
  coupe pas sur une pause de réflexion), tout en répondant assez vite pour que l'échange reste
  fluide.
- **Quand le temps est écoulé, l'examinateur termine sa phrase de conclusion.** Il n'est pas
  coupé au milieu d'un mot, et il n'y a pas non plus de silence inutile avant la suite.
- **Il parle un français normal**, clair et accessible, sans s'adapter artificiellement au
  niveau du candidat (comme à un vrai examen). S'il n'a pas compris, il demande simplement de
  répéter — il ne fait jamais semblant d'avoir compris.
- **Il ne bascule jamais dans une autre langue**, ne corrige jamais, n'explique jamais qu'il
  est une IA.
- **Si le candidat ne dit rien, il n'y a rien à noter.** Quand on laisse seulement
  l'examinateur se présenter puis qu'on termine sans avoir parlé, l'application l'annonce
  clairement (« Aucune prise de parole — rien à évaluer ») et invite à reprendre l'échange, au
  lieu d'ouvrir un bilan vide.

---

## 11. Ce que le candidat reçoit à la fin

Dans cet ordre :

1. **Ce qu'il a traité et ce qu'il a oublié** (§5.4) — avant toute considération de langue.
2. **La note sur 20** et, avec elle, la **performance observée** sur cette tâche et la
   **confiance** (§6.3, §7).
3. **Les avertissements** éventuels : limite de l'évaluation orale (§9), plafond appliqué
   (§6.4), doute signalé par les vérifications automatiques (§4).
4. **Points forts** — ce qu'il a réussi, cité dans sa production (pas des compliments de
   politesse).
5. **1 à 2 points à améliorer** — les priorités, pas une liste décourageante.
6. **Suggestions** — conseils pédagogiques (règles à revoir, exercices).
7. **Exemples corrigés** — des phrases exactes du candidat, réécrites en mieux, avec
   l'explication. (À l'oral, uniquement des reformulations qui améliorent vraiment la clarté.)
8. **Une appréciation par critère** (bande + commentaire + citation), avec le libellé propre à
   la tâche.
9. *(Inactif aujourd'hui)* Sur une production orale, un encart **débit et pauses** —
   informations factuelles, hors note. Voir §13.

---

## 12. Comment on sait si l'IA note juste : le banc de mesure

C'est le vrai apport de cette refonte, et le point le plus important de ce document.

### 12.1 Le problème qu'il résout

Avant, **changer une consigne de notation était un pari.** On modifiait le texte donné à
l'IA, on trouvait le résultat « meilleur », et on livrait. Personne ne pouvait dire si la
notation devenait plus juste ou plus fausse.

### 12.2 Ce que c'est

Un **corpus de référence** de **48 productions**, réparties sur les 6 tâches (8 par tâche) :
une « A1 non atteint », une A1, deux A2, deux B1, une B2, et un **piège**. Pour chacune, on a
écrit à l'avance ce qu'une bonne correction devrait dire :

- le **niveau attendu**, et les niveaux **tolérés** (à un palier près) ;
- une **fourchette de note** acceptable sur 20 ;
- la **confiance** attendue ;
- si les points **obligatoires** de la consigne sont traités, et lesquels manquent ;
- le **piège** éventuel que la production contient.

Les 7 pièges couvrent les cas où une IA se trompe le plus facilement : consigne recopiée pour
faire du volume, texte manifestement généré par une IA, hors-sujet total, candidat quasi
muet, discours appris par cœur, bascule dans une autre langue, et deux transcriptions
volontairement hachées (le piège n° 1 du système — il ne faut surtout pas conclure à
l'incompréhensibilité).

Une **commande unique** rejoue tout le corpus contre l'IA, avec la version de consignes qu'on
veut tester, et produit un rapport. Elle n'est **jamais** lancée automatiquement : elle appelle
un modèle payant. Une campagne complète coûte environ **45 centimes**.

### 12.3 Ce qu'il mesure

| Mesure | Ce que ça veut dire |
|---|---|
| **Accord exact** | Part des productions où l'IA annonce **exactement** le bon niveau. |
| **Accord à un palier près** | Part où elle tombe au bon niveau **ou juste à côté**. |
| **Note dans la fourchette** | Part où la note sur 20 tombe dans la zone acceptable. |
| **Écart de sévérité** | De combien de points l'IA s'écarte de la référence, **en moyenne et avec le signe**. Un écart **négatif** veut dire : l'IA note **au-dessus** de la référence, donc elle est **trop indulgente**. |
| **Matrice de confusion** | Qui est confondu avec qui : les A1 pris pour des A2, les A2 pris pour des B1… |
| **Pièges** | Chaque piège est-il évité, et si non, dans quel sens l'IA dérape. |
| **Confiance** | L'IA se déclare-t-elle aussi sûre qu'elle devrait l'être ? |
| **Accomplissement** | Retrouve-t-elle les points de la consigne réellement oubliés ? |
| **Conformité de sortie** | Le modèle a-t-il renvoyé une réponse **exploitable** ? En vrai, chaque réponse inexploitable est une correction en échec pour un utilisateur. |
| **Stabilité** | On rejoue le même lot plusieurs fois : la même production reçoit-elle la même note ? |

### 12.4 Ce que la mesure a montré

**Le diagnostic : l'IA était trop gentille, surtout en bas d'échelle.** On avait empilé des
tolérances — ne pas pénaliser la longueur, ni l'orthographe à l'oral, ni le manque
d'exhaustivité, bénéfice du doute systématique. Chacune était justifiée ; **mises bout à bout,
elles poussaient les notes vers le haut.** C'était une intuition ; la mesure l'a confirmée.

**Avant correction** (consignes v4) :

- l'IA notait en moyenne **1,9 point au-dessus** de la référence ;
- **6 productions A1 sur 8** ressortaient A2 ;
- **5 productions A2 sur 13** ressortaient B1 ;
- seules **38 %** des productions A2 obtenaient une note dans la bonne fourchette ;
- accord exact : **60 %**, notes dans la bonne fourchette : **60 %**.

**Après correction** (consignes v4.1, **résultat répliqué sur deux campagnes**) :

- écart de sévérité ramené à **−1,0** ;
- accord exact : **60 % → 73 %** ;
- notes dans la bonne fourchette : **60 % → 87 %** ;
- productions A2 correctement notées : **38 % → 92-100 %** ;
- productions A2 prises pour du B1 : **5 sur 13 → 2 sur 13**.

Aucune tolérance n'a été supprimée pour obtenir ça. Elles ont été **encadrées** (la règle
« une tolérance lève une sanction, elle n'accorde pas de point », §5.6), et l'ancrage du bas
de l'échelle a été écrit noir sur blanc.

Les **exemples de référence** donnés à l'IA pour se caler ont aussi été enrichis : elle n'en
avait que **3** (tous des écrits, aucun niveau A1, aucun oral) ; elle en a **13** aujourd'hui,
dont un dialogue oral bruité, un cas « A1 non atteint », et plusieurs cas A1/A2 avec la note
attendue explicite — c'est-à-dire des repères exactement là où le risque était le plus grand.
Le haut de l'échelle n'a pas bougé (B2 était déjà bien calé).

**Un défaut technique majeur découvert au passage.** Sous l'ancien format de réponse, le
modèle renvoyait une réponse **inexploitable dans 49 % des cas** (44 appels sur 90). Chaque
cas de ce genre est, en production, **une correction en échec pour l'utilisateur**. Avec le
format actuel, ce taux est de **0 %**. Ce n'est pas un gain de notation, c'est un gain de
fiabilité — et il n'aurait jamais été vu sans le banc.

**La stabilité est bonne.** Le même corpus rejoué **3 fois** : **47 productions sur 48**
gardent exactement le même niveau, et l'écart de note maximal observé sur une même production
est de **2 points** (médiane : 0). La notation n'est donc pas un tirage au sort.

**Le seuil A2 est passé de 7 à 8.** En rejouant hors ligne les 96 évaluations des deux
campagnes v4.1 avec différents seuils, un seul déplacement s'est révélé **entièrement
bénéfique** : monter le seuil A2 de 7 à 8. Accord exact **71,9 % → 76,0 %**, productions A1
correctement classées **62,5 % → 87,5 %**, et **aucune dégradation** sur A2, B1 et B2. À
l'inverse, monter le seuil B1 à 13 était le pire choix testé : les A2 passaient à 100 %, mais
les B1 s'effondraient à 33 % — on aurait annoncé « A2 » à de vrais B1. On ne l'a pas fait.

### 12.5 Ce qui reste faible — à dire franchement

Le banc sert autant à mesurer les progrès qu'à nommer ce qui ne va pas.

- **Le niveau « A1 non atteint » n'est presque jamais atteint.** Seule la moitié des cas
  attendus à ce niveau y arrivent ; les autres ressortent A1. C'est une **limite de
  construction** : le serveur ne pose « A1 non atteint » que si la note vaut **exactement 0**,
  c'est-à-dire en pratique uniquement sur un hors-sujet total ou une production refusée par
  les vérifications automatiques. Une production réellement en deçà du A1, mais qui obtient
  1 ou 2 points, sera annoncée A1.
- **Les productions A1 restent le point faible.** Sur les deux campagnes v4.1 telles qu'elles
  ont tourné, **environ 37 %** d'entre elles étaient encore mal classées (généralement
  annoncées A2). Le déplacement du seuil A2 décrit ci-dessus ramène ce chiffre à environ
  **12 %** sur le même corpus — mais ce résultat vient d'un **rejeu hors ligne**, pas encore
  d'une campagne complète refaite. À reconfirmer.
- **Quelques B1 sont annoncés B2.** L'accord exact sur les B1 plafonne autour de **71-75 %**.
- **L'IA se croit plus sûre qu'elle ne devrait.** Sur environ un tiers des cas, elle annonce
  une confiance plus élevée que celle attendue. Elle ne se trompe presque jamais dans l'autre
  sens.
- **Le repérage des oublis est perfectible.** Les points de la consigne réellement oubliés ne
  sont retrouvés que dans **un peu moins de la moitié** des cas. En revanche, la question
  « tous les points obligatoires sont-ils traités ? » reçoit la bonne réponse dans plus de
  **85 %** des cas.
- **Et surtout : le corpus est synthétique.** Les 48 productions ont été **écrites à la main**
  pour ce banc. Aucune ne vient d'un utilisateur réel ; aucune n'a été annotée par un
  enseignant de FLE. Les consignes, elles, sont les vraies consignes du projet. C'est une
  **base de départ honnête, pas une vérité de terrain** : un corpus écrit par ceux qui écrivent
  aussi les consignes de notation partage forcément une partie de leurs angles morts. La suite
  prévue : le remplacer et le compléter progressivement par de **vraies productions
  anonymisées, annotées par des enseignants**, avec une double annotation ciblée sur les
  frontières A2 / B1 / B2 — là où la décision compte le plus.

---

## 13. Trois réglages **préparés mais éteints** (aucun effet aujourd'hui)

Ces trois comportements sont écrits, testés et livrés, mais **désactivés**. Tant qu'ils ne
sont pas allumés, **rien de ce qui suit ne se produit** : la notation décrite dans tout le
reste de ce document reste, mot pour mot, celle qui s'applique. Ils s'allument un par un,
après mesure au banc, en changeant une seule ligne de configuration.

| Réglage | Ce qu'il ferait une fois allumé |
|---|---|
| **Débit et pauses** | Afficher, sous une production **orale**, deux mesures **factuelles** : le **débit** (mots par minute) et — seulement si la transcription porte des repères de temps — le **nombre de silences longs**. Ce sont des **informations**, jamais une note. |
| **Seconde lecture en cas de doute** | Faire **recorriger** la production par une **seconde IA**, uniquement quand la première est peu sûre d'elle (confiance faible, note juste à la frontière d'un niveau, ou désaccord marqué entre l'IA et le calcul du serveur). En cas de désaccord entre les deux, on retient la correction **la plus basse** — le biais mesuré est vers l'indulgence — et on **baisse la confiance affichée**. |
| **Cohérence du bilan** | Interdire un **B2 au bilan** d'une épreuve quand la **tâche 3** (celle où l'on argumente) est **en dessous de B1**. Le bilan est alors ramené à B1. Ne peut qu'abaisser. |

Trois précisions qui comptent :

- **Le débit ne deviendrait pas un critère de note, même allumé.** C'est une mesure affichée à
  côté de la correction, avec la mention « ces mesures n'entrent pas dans votre note ni dans
  votre niveau ». Aucun calcul de note ou de niveau ne lit ce bloc. Elle a été retenue parce
  qu'elle est **neutre vis-à-vis de l'accent** : compter des mots par minute ne favorise
  aucune langue maternelle, contrairement à une analyse de prononciation. L'allumer nuancerait
  la règle « on ne juge ni le débit ni la durée » du §8 : on **mesurerait** le débit, sans le
  **noter**.
- **La seconde lecture n'a d'intérêt qu'avec une IA différente.** Reposer exactement la même
  question au même modèle donne presque toujours la même réponse — le banc l'a montré (§12.4).
  Le modèle de la seconde lecture est donc configurable séparément, et l'application avertit
  au démarrage si on l'active sans en choisir un autre.
- **La seconde lecture retient une correction entière**, jamais un mélange : on ne colle pas
  la note d'une passe sur les commentaires de l'autre.

---

## 14. Une console pour comparer l'IA à un correcteur humain

Le banc de mesure (§12) tourne sur un corpus écrit à la main. Pour le compléter par de vraies
productions, il existe un **écran d'administration** dédié.

Un correcteur humain y ouvre une production réellement rendue par un utilisateur, l'écoute ou
la lit, et pose sa propre note sur 20 et son propre niveau CECRL. L'écran affiche alors, sur
l'ensemble des productions annotées :

- le **biais** — l'IA se trompe-t-elle plutôt **vers le haut** (trop indulgente) ou vers le
  bas ? C'est la moyenne des écarts, avec leur signe ;
- la **dispersion** — de **combien** se trompe-t-elle, en moyenne et en amplitude ? Une IA qui
  se trompe de 0,5 point à chaque fois n'a pas le même problème qu'une IA juste en moyenne
  mais qui se trompe de 5 points dans les deux sens ;
- la part de productions dont l'écart dépasse **3 points**, considérés comme « hors cible » ;
- un verdict simple « calibré / non calibré » : moins de 1,5 point d'écart moyen **et** moins
  de 5 % de productions hors cible.

Une production réannotée plusieurs fois ne compte qu'**une seule fois** (sa dernière note) :
sans ce garde-fou, la mesure censée dire si l'IA note juste se biaisait elle-même.

**C'est cette console qui fera grossir le corpus réel** et permettra, à terme, de remplacer
les productions synthétiques du banc par de vraies copies annotées.

---

## 15. Où sont réglées ces règles (pour ceux qui veulent aller voir)

Toutes les instructions données à l'IA vivent dans des **fichiers de texte** (pas cachées dans
le code) — on peut donc les faire évoluer sans être développeur, en touchant le bon fichier :

| Ce qu'on veut changer | Fichier |
|-----------------------|---------|
| **Toutes les consignes de notation** (critères propres à chaque tâche, poids, barème, ancrage du bas de l'échelle, règles obligatoires/pistes, tolérances, exemples de calibration…) | `backend_sejourfr/src/main/resources/prompts/production-rubrics-v4.1.json` (version **active**). Les versions `v4` et `v3` restent en place et valides : on revient en arrière en changeant une seule variable. |
| **Le format de réponse de l'IA** (note, confiance, accomplissement, preuves, exemples corrigés…) | `backend_sejourfr/src/main/resources/prompts/production-evaluation-tool-schema-v2.json` |
| **Le comportement de l'examinateur vocal** (ton, cadre, interdiction d'orienter le candidat, ouverture T1/T2, façon de rendre la fiche de scénario T2…) | `backend_sejourfr/src/main/resources/prompts/realtime-personas-v2.json` (version active ; la v1, sans fiche de scénario, reste disponible en repli) |
| **Les faits d'un jeu de rôle T2** (prix, délais, horaires, attitude du personnage) | colonne `agent_role_card` du sujet, en base — renseignée par les migrations `db/migration/300_tcf/production/eo/tache_2/` |
| **Les seuils de niveau, les plafonds, les vérifications automatiques, les trois réglages éteints** | `backend_sejourfr/src/main/resources/application.yaml`, section `sejourfr.production-evaluation` |
| **La patience / réactivité de l'examinateur vocal** (détection de fin de parole) | `backend_sejourfr/src/main/resources/application.yaml`, section `sejourfr.realtime.gemini.vad` |
| **Le corpus de référence du banc de mesure** | `backend_sejourfr/src/test/resources/calibration/golden-set-v1.json` |

> **Deux garde-fous automatiques** : au démarrage, l'application **refuse de démarrer** si les
> consignes de notation sont incohérentes — critère inconnu, poids qui ne font pas 100 %, tâche
> sans barème, ou disparition d'un des trois critères porteurs du niveau. Et si l'IA rend une
> note très différente du calcul officiel, l'écart est enregistré pour surveillance.

> **On versionne, on ne réécrit pas.** Une nouvelle grille de notation devient une nouvelle
> version (`v4`, `v4.1`…). Les anciennes restent en place : sans ça, les évaluations déjà
> rendues deviendraient illisibles et incomparables.

Pour le détail **technique** (services, base de données, providers d'IA, stockage des audios),
voir [`pipeline-evaluation-eo-ee.md`](pipeline-evaluation-eo-ee.md) et
[`SPEC_MODULE_EXPRESSION_EO_EE.md`](SPEC_MODULE_EXPRESSION_EO_EE.md). Pour les décisions
produit derrière cette refonte et leurs raisons, voir
[`ia/ANALYSE_SPEC_EVALUATION_IA.md`](ia/ANALYSE_SPEC_EVALUATION_IA.md). Pour la génération des
audios de compréhension orale (autre pipeline), voir
[`pipeline-audio-co.md`](pipeline-audio-co.md).

---

## 16. Résumé en une page

L'IA joue un correcteur d'examen **juste, pas complaisant**. Pour chaque tâche, elle note
**5 critères qui lui sont propres**, dit d'abord **ce qui a été traité et ce qui a été
oublié**, appuie chaque appréciation sur une **citation** de la production, donne **au plus
deux priorités**, et déclare **à quel point elle est sûre d'elle**. Le serveur, lui, calcule
la note officielle, en déduit le niveau à partir du lexique, de la grammaire et de la
cohérence, applique deux plafonds ciblés, et n'affiche jamais un niveau sans sa confiance.

Elle juge avant tout la **capacité du candidat à communiquer et à se faire comprendre**, sans
le pénaliser pour une transcription imparfaite, pour une piste du sujet non traitée, ni pour
la longueur. Mais **ne pas sanctionner n'est pas créditer** : une production qui ne démontre
rien de plus que l'élémentaire reste notée comme telle, parce qu'annoncer B1 à un candidat A2
revient à lui faire payer un examen officiel qu'il va rater.

Trois choses qu'on **ne cache pas** :

- à l'oral, **on ne juge que la transcription** — la voix n'est pas analysée, et c'est une
  limite technique, pas un choix pédagogique ;
- notre notation est **mesurée**, et la mesure dit encore que le bas de l'échelle est notre
  point faible ;
- le corpus qui sert à cette mesure est **écrit à la main** : il doit être remplacé par de
  vraies productions annotées par des enseignants.
