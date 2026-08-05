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

**État actuel** : rubriques de notation **v8** (profil **TCF IRN**, plafonné à B2), format de
réponse strict **v5**, examinateur vocal **v2**. Ce que ces numéros veulent dire, et où ils se
changent, est expliqué en §15.

> 🆕 **Ce que change la v8 : le rapport, pas la note.** La façon de **noter** est celle de la
> v7, à l'identique — mêmes critères, même échelle, mêmes seuils, mêmes garde-fous, mêmes
> exemples de calibration. Rien de ce qui produit une note n'a bougé, et aucune campagne de
> mesure n'était donc nécessaire. Ce qui change, c'est **ce que le candidat lit**, parce que
> le rapport rendu était répétitif, scolaire et parfois contradictoire :
>
> 1. **La confiance dit ce que le correcteur sait, jamais ce que le candidat vaut.** Une
>    production faible mais lisible est corrigée avec une confiance **haute** : un niveau bas
>    est une **observation**, pas un doute (§7).
> 2. **Une erreur, un seul endroit.** Un même fait de langue n'est plus traité trois fois de
>    suite sous trois formes différentes (§5.7).
> 3. **On ne reproche jamais un moyen que la consigne n'exigeait pas.** L'absence d'un temps
>    du passé sur une tâche qui n'en demande pas devient « ce qui te ferait gagner un
>    niveau », plus « aucun second temps maîtrisé » (§5.7). ⚠️ C'est une règle de
>    **formulation** : elle ne change **rien** au raisonnement de notation.
> 4. **Le rapport ne se contredit plus.** Un point demandé mais mal formulé est **présent** :
>    la réserve porte sur la forme, jamais sur la présence (§5.4).
> 5. **Un verdict clair en tête d'écran** : « Objectif de la tâche : atteint / partiellement
>    atteint / non atteint », avec une phrase qui dit ce que le candidat a fait (§5.4).
> 6. **Au plus deux points forts** et **au plus trois exemples corrigés** (§5.5).
> 7. **À l'écrit, une « version améliorée » de la copie entière**, réécrite au palier juste
>    au-dessus avec les seules idées du candidat (§5.8). Rien de tel à l'oral.

> 🔒 **Ce que verrouille toujours la v7, conservé tel quel en v8.** C1/C2 sont hors du contrat
> actif : SejourFR prépare uniquement le **TCF IRN**, dont le niveau rapporté ici s'arrête à
> **B2**. Exactement quatre critères, refus de toute réponse incomplète avant correction, puis
> une seule tentative automatique de réparation. Les bornes EE sont strictes : **30–60 mots en
> T1 et 60–90 mots en T2/T3**, sans aucune marge au-delà du maximum (l'ancienne tolérance de
> 20 % est supprimée).

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
| **EE T2** | Écrire un **message développé** : raconter, décrire, expliquer, conseiller | 60 à 90 mots | B1 |
| **EE T3** | **Donner son opinion** et l'argumenter, ou comparer | 60 à 90 mots | B2 |
| **EO T1** | **Se présenter** et parler de soi, de son quotidien (entretien dirigé) | ~3 min (min. 2 min) | A2 |
| **EO T2** | **Interagir** dans une situation de la vie courante (obtenir / donner des informations) | ~3 min 30 (min. 2 min) | B1 |
| **EO T3** | **Donner un point de vue** en continu (petit monologue argumenté) | ~3 min 30 (min. 2 min) | B2 |

> ⚠️ **TCF IRN ≠ TCF Canada — piège classique sur les longueurs.** Les bornes ci-dessus
> (30-60 / 60-90 / 60-90 mots) sont bien celles du **TCF IRN**, l'examen que prépare
> SejourFR. Les valeurs **60-120 et 120-180 mots** que renvoient la plupart des pages web
> appartiennent au **TCF Canada**, un autre examen. La confusion est très fréquente en ligne,
> y compris sur des sites de préparation : **ne pas « corriger » nos bornes d'après une
> recherche web** sans avoir vérifié que la source parle explicitement de l'IRN. Même
> vigilance pour toute autre donnée chiffrée (nombre de tâches, durées, barème).
>
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
5. Le serveur vérifie la réponse **brute** : quatre critères exacts sans doublon, nombres
   finis entre 0 et 20, structure complète et niveau limité à B2. Si elle est invalide, il
   demande une seule réparation ; si elle échoue encore, aucune note partielle n'est gardée.
6. Le serveur **recalcule** la note, le niveau, et applique ses propres règles (§5, §6).

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

### 3.1 Une phrase coupée en deux est recollée avant d'être lue et notée

Pendant un oral en temps réel, c'est la machine qui décide quand « le candidat a fini de
parler ». Elle se trompe souvent : elle ferme la bulle **au milieu d'une phrase**, et la fin
de la phrase repart dans une bulle suivante. Le candidat n'a rien fait de mal — il a dit une
seule phrase, et notre transcription en affichait deux morceaux :

> Candidat : … c'est vraiment tout ça qui m'ont poussé à l'air. Ah.
> Candidat : aller vers l'informatique.

Ce n'est pas un détail. Découpée ainsi, la phrase produisait **trois problèmes** :

- **le candidat relisait sa propre phrase coupée en deux bulles**, comme s'il s'était arrêté
  net ;
- **le correcteur jugeait la grammaire et le vocabulaire sur un texte haché** — et il s'en
  rendait compte : certaines corrections annonçaient au candidat une « transcription
  partiellement incertaine », alors que le hachage venait de **nous**, pas de sa parole ;
- **les citations justificatives devenaient introuvables**. L'IA doit citer un passage exact
  de la production pour justifier chaque note (voir §5.5). Une citation à cheval sur les
  deux morceaux était refusée par notre vérification — et une correction dont deux citations
  sont refusées **échoue purement et simplement** : le candidat ne voyait pas sa note.

**Ce que nous faisons maintenant.** Avant de lire et de noter, nous **recollons les bulles
qui se suivent et qui viennent de la même personne**. La phrase ci-dessus redevient une seule
prise de parole. C'est tout : on ne réécrit rien, on ne corrige aucun mot, on n'ajoute aucune
ponctuation. Le seul caractère ajouté est **l'espace** qui sépare les deux morceaux.

**En cas de doute, on ne recolle pas.** C'est le principe qui gouverne tout le reste. Sur un
texte qui sert à la fois à noter et à être relu par le candidat, **recoller à tort est pire
que ne pas recoller** : ne pas recoller nous ramène simplement à la situation d'avant, tandis
que recoller à tort **fabrique une prise de parole que personne n'a faite**. Chaque fois qu'il
y a une hésitation, on laisse donc les deux bulles séparées.

Cinq garanties qui encadrent ce recollage :

1. **Jamais à travers une intervention de l'examinateur.** Si l'examinateur parle entre les
   deux bulles, elles restent séparées. Sinon on fabriquerait une phrase que le candidat n'a
   jamais dite d'un trait — par exemple en collant sa réponse d'avant la relance à sa réponse
   d'après.
2. **Jamais quand une phrase paraît terminée et qu'une nouvelle commence.** Si la première
   bulle se termine par un point, un point d'exclamation ou un point d'interrogation **et**
   que la suivante démarre par une majuscule, ce sont deux tentatives distinctes du candidat,
   pas une phrase coupée en deux — et elles restent séparées. Exemple vécu : *« … c'est quoi
   le tarif de l'abonnement s'il vous plaît. »* puis *« Oui, c'est quoi le tarif de
   l'abonnement. »* — le candidat repose sa question, les coller serait un faux.
   Il faut bien les **deux** signes : une phrase réellement coupée par la machine repart
   presque toujours en minuscule (*« … poussé à l'air. Ah. »* + *« aller vers
   l'informatique. »*), et celle-là est bien recollée.
3. **Jamais autour d'une bulle qui ne contient ni lettre ni chiffre** (par exemple une bulle
   réduite à « . . . . »). Elle n'apporte rien au sens, et la recoller ne ferait que glisser
   du bruit **au milieu** d'une phrase propre. Elle reste donc dans son coin — mais elle
   n'est pas effacée pour autant : le recollage supprime uniquement des **séparations**,
   jamais du contenu.
4. **La parole d'origine n'est jamais modifiée en base.** Le transcript brut, tel qu'il a été
   capté, reste stocké tel quel, définitivement. Le recollage se refait **à la lecture**, à
   chaque affichage et à chaque correction. Il est réversible d'un simple réglage.
5. **Le texte affiché au candidat et le texte lu par le correcteur sont le même.** C'est la
   condition pour que les citations restent vérifiables : quand la correction cite une
   phrase, le candidat doit pouvoir la relire mot pour mot dans sa transcription.

**Ce que ça ne fait pas** : ce recollage ne concerne **pas** l'affichage en direct pendant la
session. Pendant qu'il parle, le candidat voit toujours les bulles arriver au fil de l'eau,
telles que la machine les produit. Le recollage n'intervient qu'**après**, au moment de lire
et de noter. Et il ne répare pas non plus les **mots** coupés en plein milieu (« voi ture ») :
ce défaut-là a été corrigé à la source en juillet 2026, et deviner ce que le candidat a voulu
dire sur un texte qui fait foi serait pire que de laisser la trace. Enfin, il ne rattrape pas
les transcriptions **ratées de bout en bout** (un morceau de phrase dans une autre langue, un
marqueur de bruit écrit avec des lettres) : celles-là, ce n'est pas notre découpage qui les a
abîmées, et vouloir les repérer reviendrait à juger la qualité d'une transcription — ce n'est
pas le rôle de ce mécanisme.

---

## 4. Avant l'IA : trois vérifications automatiques

Ces contrôles sont faits par le serveur, **sans aucune IA**. Ce sont de simples calculs.
Ils évitent des notes absurdes et des appels payants inutiles.

| Ce qui est vérifié | Comment | Ce qui arrive au candidat |
|---|---|---|
| **La production est-elle vide ou quasi vide ?** | Moins de 5 mots exploitables. Dans un dialogue oral, on ne compte **que** les tours du candidat : si l'examinateur a parlé seul, il n'y a rien à corriger. | **Production refusée avant l'IA.** Note 0, niveau « A1 non atteint », confiance faible, et un message clair : « Nous n'avons trouvé aucune prise de parole exploitable de votre part. » |
| **Le texte est-il en français ?** | Deux mesures : la part de lettres d'un **autre alphabet** (arabe, cyrillique…), et la part de **petits mots français très fréquents** (le, la, de, que, je, vous…). Un texte français en contient beaucoup ; un texte anglais ou espagnol, presque aucun. L'analyse ne se déclenche qu'à partir de 12 mots — en dessous, la mesure ne veut rien dire. | **Beaucoup d'autre alphabet, ou presque aucun mot français** → production refusée avant l'IA, avec l'explication. **Cas intermédiaire** (une partie du texte semble ne pas être en français) → l'IA note quand même, mais la confiance est plafonnée à « moyenne » et la raison est affichée. |
| **La consigne a-t-elle été recopiée ?** | On compare des suites de 5 mots entre la production et l'énoncé du sujet. | **Plus de 60 % recopié** → refusé : ce n'est plus une production personnelle. **Entre 30 et 60 %** → l'IA note **normalement**, et le candidat est averti que seuls ses propres mots comptent. La confiance, elle, **n'est pas touchée** (voir juste en dessous). |

Les seuils ci-dessus sont **volontairement prudents** : mieux vaut laisser passer une
production douteuse que bloquer un vrai candidat maladroit.

**Deux avertissements, deux choses différentes.** Ces contrôles peuvent signaler un doute
sans refuser la production — mais tous les doutes ne se valent pas :

- « une partie du texte ne semble pas être en français » est un **obstacle à la lecture** :
  on ne voit qu'à moitié ce que le candidat produit, donc la correction elle-même est moins
  sûre. Là, le serveur plafonne la confiance à « moyenne » ;
- « une partie de la production recopie l'énoncé » est un doute sur **l'origine des mots**,
  pas sur leur lisibilité. Les passages recopiés sont écartés, on le dit au candidat, et
  **ce qui reste se lit parfaitement**. Il n'y a donc aucune raison d'annoncer une
  correction moins sûre : la confiance reste celle du correcteur. C'est la même règle que
  celle imposée à l'IA depuis la v8 — la confiance dit ce que le correcteur **sait**, pas
  ce qu'il **soupçonne** (§7).

Quand les deux avertissements tombent ensemble, l'obstacle à la lecture reste un obstacle :
la confiance est plafonnée.

---

## 5. Comment l'IA note : les quatre critères du TCF

### 5.1 La grille est celle du vrai examen

**Depuis la version 5 des consignes, notre grille est celle du TCF**, et non plus une grille
maison. Le TCF évalue les productions sur **quatre critères, qui pèsent exactement le même
poids — 25 % chacun** :

| Critère | Ce qu'il évalue |
|---|---|
| **Communiquer** | **Accomplir la tâche** : fournir les informations demandées, décrire, raconter, expliquer, justifier une position, obtenir un renseignement — **et enchaîner ses idées** de façon suivie. |
| **Interagir** | **S'adapter à la situation de communication et au destinataire** : registre, politesse, formules d'ouverture et de clôture, prise en compte de l'interlocuteur, conduite des tours de parole à l'oral. |
| **Lexique** | Le vocabulaire est-il **approprié** : étendue, précision, justesse ? |
| **Morphosyntaxe** | La **correction grammaticale** : conjugaisons, accords, construction et variété des phrases. |

Les mêmes quatre critères, avec les mêmes poids, servent **sur les six tâches**. Ce qui
distingue les tâches, ce ne sont plus des critères différents mais **les descripteurs et les
consignes propres à chaque tâche** : « communiquer » ne veut pas dire la même chose quand on
annonce un déménagement à un ami (EE T1) et quand on défend un point de vue (EO T3). C'est
exactement la logique du TCF, où une seule grille sert les trois tâches d'une épreuve.

**Ce qui a changé, et pourquoi.** Nos versions 3 et 4 avaient été construites maison : 4
critères universels puis 5 critères propres à chaque tâche, avec des poids variables
(15 % à 30 %). Trois écarts avec le vrai examen ont motivé la refonte :

1. **5 critères à poids variables** là où le TCF en a **4 égaux** ;
2. des **noms maison** (« réalisation de la consigne », « conduite de l'échange », « prise de
   position », « chronologie du récit »…) qui changeaient d'une tâche à l'autre, alors que
   ceux du TCF sont stables ;
3. surtout, **l'accomplissement de la tâche était exclu du calcul du niveau**. Le TCF lui
   donne 25 %. Conséquence observée sur de vraies copies : un message qui accomplit
   parfaitement sa tâche, s'adresse correctement à son destinataire et se fait comprendre
   ressortait **A2**, parce que deux des quatre critères du TCF ne pesaient **rien** chez nous.

**Où sont passés les anciens critères ?** Ils n'ont pas disparu, ils ont été **absorbés** :

| Ancien critère (v4) | Absorbé par |
|---|---|
| Réalisation de la consigne | **communiquer** |
| Chronologie et repères temporels | **communiquer** |
| Prise de position claire | **communiquer** |
| Justification et développement des arguments | **communiquer** |
| Conduite de l'échange | **communiquer** |
| Développement des réponses | **communiquer** |
| Cohérence / organisation | **communiquer** — la formulation officielle range « enchaîner les idées » du côté de *communiquer* ; elle n'est donc plus notée à part, pour ne pas la compter deux fois |
| Adéquation au destinataire et au registre | **interagir** |

Deux familles, qui ne jouent pas le même rôle mais qui pèsent désormais **autant** :

- **Les critères de langue** — **lexique** et **morphosyntaxe**, notés en absolu sur
  l'échelle du profil TCF IRN, de A1 non atteint à B2 ;
- **Les critères de réalisation** — **communiquer** et **interagir**. Ils ne comptent pas des
  cases cochées : ils disent **à quel niveau** la tâche est accomplie. Accomplir une consigne
  A2 avec des moyens A2, c'est une réussite… de niveau A2.

### 5.2 Ce que « communiquer » et « interagir » veulent dire, tâche par tâche

Les quatre critères et leurs poids ne changent pas. **Ce sont les attentes qui changent** —
c'est le champ « descripteurs » et les consignes de chaque tâche qui les portent.

| Tâche | **Communiquer** y signifie | **Interagir** y signifie |
|---|---|---|
| **EE T1** message court | Annoncer, décrire, inviter de façon compréhensible, et enchaîner ces informations d'un trait. | Formule d'appel et de clôture adaptées au destinataire (ami, famille, voisin), registre tenu. |
| **EE T2** message développé | Raconter / décrire / expliquer avec des détails concrets, dans un ordre clair, avec des repères temporels et des temps du passé employés à bon escient ; le texte forme un tout. | Le message est écrit **pour quelqu'un** : adresse, registre, prise en compte de ce que le destinataire sait déjà. |
| **EE T3** opinion argumentée | Trancher clairement, soutenir par au moins deux arguments développés, organiser (avis → arguments → conclusion). | Écrire pour un lecteur qui peut ne pas être d'accord : courtoisie du désaccord, objection prise au sérieux. |
| **EO T1** entretien dirigé | Se présenter et parler de son quotidien de façon compréhensible, **dépasser la réponse minimale** (ajouter un détail, une raison), enchaîner les thèmes. | S'adresser à son examinateur : salutation, registre, réponses qui répondent vraiment à ce qui est demandé. |
| **EO T2** interaction | **Mener** l'échange : formuler sa demande, relancer, réagir, reformuler, et **obtenir** ce qu'on est venu chercher. | Politesse et registre de la situation (guichet, commerce, employeur), gestion des tours de parole. |
| **EO T3** point de vue | Répondre à la question, affirmer un point de vue, le soutenir par des arguments développés, tenir un fil du début à la fin. | Tenir son monologue **pour** quelqu'un : nuance plutôt que péremptoire, objection envisagée, adresse à l'examinateur. |

> **C'est le serveur qui calcule la note, pas l'IA.** L'IA note chaque critère sur 20 ; le
> serveur en fait la moyenne (les quatre poids sont égaux) et **écrase** la note d'ensemble
> que l'IA avait proposée. Ça évite les incohérences (une IA qui annoncerait « 16/20 » avec
> des critères bas). Si l'écart entre les deux dépasse 3 points, c'est enregistré pour
> surveillance.

### 5.2 bis Le garde-fou qui empêche de « cocher des cases »

Remettre l'accomplissement de la tâche dans le niveau crée un risque évident : **quelqu'un
qui traite tous les points d'une consigne simple dans un français pauvre remonterait
indûment.** C'est précisément pour éviter ça que les versions précédentes l'excluaient du
calcul.

Le vrai TCF s'en protège autrement : par des **descripteurs par niveau**. « Communiquer » à
un niveau B2, ce n'est pas cocher plus de cases, c'est justifier, nuancer, enchaîner — ce qui
suppose une langue B2. Nous reproduisons ce mécanisme de deux façons :

1. **Des descripteurs de niveau pour les quatre critères**, tâche par tâche (tableau ci-dessus
   + descripteurs A1→B2 propres à chaque tâche).
2. **Un garde-fou de couplage, opposable et vérifié par le serveur** : *communiquer* et
   *interagir* ne peuvent jamais dépasser de **plus d'un point** la moyenne de *lexique* et
   *morphosyntaxe*. Exemple : lexique 1, morphosyntaxe 1 (moyenne 1) → *communiquer* et
   *interagir* sont plafonnés à 2, même si la consigne est intégralement traitée. La règle
   est écrite dans les consignes données à l'IA **et** appliquée par le serveur avant le
   calcul de la note : si l'IA la dépasse, ses notes sont ramenées sous le plafond.

> **Pourquoi « un point » alors que c'était « quatre points » jusqu'à la v5 ?** Parce que
> l'échelle a changé (§6.1) et qu'un écart de points n'a pas le même sens d'une échelle à
> l'autre. Ce qu'il faut conserver, ce n'est pas le nombre : c'est **le maximum que ces deux
> critères peuvent ajouter à la moyenne des quatre**, soit la moitié de l'écart. Avec un
> écart d'un point, ce gain plafonne à **0,5 point** — juste assez pour reconnaître qu'une
> tâche bien menée vaut mieux qu'une tâche bâclée, jamais assez pour franchir un seuil de
> niveau. Le calcul est fait pour ça : une langue au **maximum de son palier** (5 pour A2,
> 9 pour B1) donne au mieux une moyenne de 5,5 ou 9,5 — donc reste A2, reste B1. Sous la v5,
> l'écart de 4 produisait le même effet parce que les seuils de niveau y étaient décalés de
> 2 à 3 points vers le haut ; ce décalage n'existe plus, l'écart devait donc être recalculé.

Conséquence chiffrée, qui est le cœur de la protection : avec une langue A2 au maximum
(5/5) et le couplage, la moyenne des quatre plafonne à **5,5/20** — soit A2. **Un
« communiquer » élevé ne peut pas fabriquer un B2.** Il faut une vraie langue pour ça.

### 5.3 Points **obligatoires** et **pistes suggérées** — la règle centrale

Une consigne mélange deux choses très différentes, et l'IA doit les séparer **avant** de
noter :

- **Les points obligatoires** : ce que la consigne demande explicitement de faire — ses
  verbes d'action (annoncer, décrire, inviter, raconter, conseiller, donner son avis) et les
  informations qu'elle exige. **Ils comptent dans la note.** Un point obligatoire non traité
  fait baisser le critère **communiquer** — **et lui seul**, jamais le lexique ni la
  grammaire.
- **Les pistes suggérées** : les exemples, idées, thèmes ou questions que le sujet propose
  pour aider (« vous pouvez parler de votre travail, de vos loisirs… », listes de questions
  possibles). **Une piste non traitée n'enlève aucun point.** Jamais. Elle n'est jamais
  présentée comme un manque, jamais mise dans les points à améliorer. Au mieux, elle est
  signalée à titre purement informatif.

**En cas de doute sur le statut d'un point, l'IA doit le traiter comme une piste** : le doute
profite au candidat. Sur EO T1 et EO T2 en particulier, le sujet ne fournit pratiquement que
des pistes — on n'y exige **jamais** l'exhaustivité. Un échange incomplet mais réussi répond
aux attentes.

### 5.4 Le verdict, et le bloc « ce que vous avez traité / ce que vous avez oublié »

C'est la première chose que voit le candidat, **avant** tout ce qui concerne la grammaire.

Avant, un candidat qui oubliait un tiers de la consigne voyait « 14/20 » et un commentaire
vague. Il ne savait pas ce qu'il avait raté.

**Depuis la v8, l'écran s'ouvre sur un verdict explicite** — jusqu'ici, il fallait le deviner
en lisant les listes :

```
Objectif de la tâche : ATTEINT
Tu invites clairement ton amie, tu donnes le lieu et tu demandes d'apporter quelque chose.
```

Trois valeurs possibles, et trois seulement : **atteint**, **partiellement atteint**, **non
atteint**. Quatre règles les encadrent :

- le verdict ne regarde **que les points obligatoires** de la consigne. Une piste non abordée
  ne peut **jamais** le faire basculer ;
- « atteint » veut dire **exactement** : aucun point obligatoire n'a été oublié. Si l'IA
  annonce « atteint » tout en listant elle-même un manque obligatoire, **le serveur abaisse le
  verdict** à « partiellement atteint ». Il corrige toujours dans le sens prudent, jamais
  l'inverse — même principe que la confiance (§7) ;
- « non atteint » est réservé au **hors-sujet** ou à l'absence totale de traitement de la
  consigne ;
- le verdict est **indépendant de la note et du niveau**. Une consigne entièrement traitée
  avec des moyens A1 est **atteinte** — et se note quand même dans la bande A1/A2. C'est
  volontaire : accomplir la tâche et le niveau de langue employé pour y arriver sont deux
  choses différentes (§5.2 bis). L'IA a l'interdiction explicite de dégrader le verdict pour
  « justifier » une note basse.

Viennent ensuite les deux listes, en langue simple :

```
Ce que vous avez traité      ✓ Nouvelle annoncée
                             ✓ Logement décrit
Ce qui manque                ○ Invitation absente
```

Chaque ligne porte une indication invisible mais décisive : **obligatoire** ou **piste**. Un
manque marqué « piste » n'a **aucune conséquence sur la note**. Aucun calcul de note ne lit
ces marqueurs — c'est une garantie, pas une intention.

**Un point demandé mais mal formulé est un point PRÉSENT** (règle v8). Un vrai rapport
affichait « tous les points demandés ont été traités », puis, trois lignes plus bas, « la
demande d'apporter quelque chose n'est pas clairement formulée » : le candidat ne pouvait plus
savoir s'il l'avait faite ou non. Désormais, si l'invitation est maladroite, implicite ou
ambiguë, elle figure dans « ce que vous avez traité », et la réserve porte **sur la forme**
(« présent, à reformuler »), exprimée une seule fois dans le commentaire du critère
*communiquer*. Il est **interdit** de déclarer absent, manquant ou « non formulé », dans une
priorité, une suggestion ou un commentaire, un point listé comme traité.

Enfin, l'IA a l'interdiction de **fabriquer** un manque pour remplir la liste : si tout est
traité, la liste des oublis reste vide.

### 5.5 Preuves et priorités

- **Chaque critère noté doit s'appuyer sur une citation non vide** de la production (3 à 15
  mots). Le serveur cherche d'abord le passage continu correspondant, sans se laisser
  tromper par une différence de majuscule, d'accent, d'apostrophe, de tiret ou d'espace
  (`œ`/`oe` et `æ`/`ae` sont aussi reconnus). Pour éviter de rejeter une citation presque
  exacte à cause d'une petite erreur de recopie, une tolérance très limitée existe sur les
  citations d'au moins quatre mots : un petit mot-outil peut avoir été ajouté ou omis. La
  seule différence admise à l'intérieur d'un mot est la flexion explicitement reconnue
  « telles » / « tels » ; toute autre substitution est refusée. Au moins trois mots
  importants doivent rester identiques, et un
  seul passage de la production doit convenir. Cette tolérance n'accepte jamais l'ajout ou
  l'omission d'un verbe ou d'un nom porteur, un remplacement par un autre mot, un changement
  de nombre ou de négation — un mot qui contient un chiffre, comme « 10h » ou « A2 », est
  lui aussi immuable — ni des mots remis dans un autre ordre. Elle ne fait aucune recherche
  de synonymes pour rapprocher deux formulations. Une fois
  le passage retrouvé, la copie de l'IA est remplacée par **le texte original exact** avant
  l'enregistrement et l'affichage. Si aucun passage sûr ne correspond, la sortie est rejetée
  et l'IA doit la réparer. Si, après cette seconde tentative, **une seule** des quatre
  citations reste impossible à vérifier mais que tout le reste est valide, le serveur retire
  cette citation au lieu d'en afficher une inventée. La note peut alors être conservée, avec
  une confiance au maximum **moyenne** et un avertissement visible. Deux citations douteuses,
  une citation vide ou toute autre erreur font toujours échouer la correction. Avec un ancien
  format de réponse, une preuve non vérifiable est simplement retirée. Dans un dialogue, la
  recherche est limitée aux prises de parole du **candidat** : les mots de l'examinateur ne
  peuvent jamais servir de preuve.
- **Les hésitations du candidat ne font plus échouer une citation fidèle.** À l'oral, la
  transcription est volontairement littérale : elle conserve les « euh », « heu », « hum » là
  où ils ont été prononcés. Une citation par ailleurs parfaitement exacte échouait donc dès
  que trois hésitations traversaient le passage — alors que les consignes **interdisent** par
  ailleurs de fonder quoi que ce soit sur les hésitations. Le correcteur ne pouvait pas
  satisfaire les deux règles à la fois. Depuis, ces trois marques d'hésitation — **et elles
  seules**, la liste est fermée — peuvent être **absentes de la citation** alors qu'elles sont
  présentes dans la production, en nombre quelconque. Ce qui n'a **pas** changé : tous les mots
  porteurs de sens restent exigés à l'identique, dans le même ordre, dans un passage continu
  et unique ; l'élision ne fonctionne que **dans ce sens-là** — une citation qui contiendrait
  un mot absent de la production, hésitation comprise, reste refusée ; et le passage
  finalement affiché reste **le texte original exact**, hésitations incluses.
- **Quand une citation est refusée, on explique à l'IA ce qu'on attend d'elle.** La première
  version du message de réparation se contentait de lui renvoyer la liste des erreurs
  (« la preuve du critère lexique doit citer un passage réel »). Mesuré : sur 8 citations
  refusées, **zéro** était réparée — l'IA renvoyait mot pour mot la même citation, puisque de
  son point de vue elle était réelle. Le message lui rappelle désormais **la citation exacte
  qui a été refusée, critère par critère**, énonce la règle en clair (un seul passage continu,
  recopié tel qu'il apparaît, pas de « … » pour sauter un morceau, pas deux fragments
  recollés, un seul tour de parole du candidat à l'oral) et lui conseille de **re-citer plus
  court** : un passage bref et exact vaut mieux qu'un long passage reconstitué. C'est le sens
  de la correction : **on aide le correcteur à respecter la vérification, on n'abaisse pas la
  vérification.**
- **Deux points à améliorer, au maximum.** Les deux plus utiles, le plus important d'abord.
  Une liste de dix reproches décourage et n'apprend rien. Le reste part dans les
  « suggestions », formulées comme des conseils d'entraînement. Ce n'est pas qu'une
  consigne donnée à l'IA : **le serveur tronque la liste à deux** avant de vous
  l'afficher, en gardant les deux premières (les plus importantes). L'IA ne peut donc
  pas déborder, même si elle essaie.
- **Chaque priorité doit ENSEIGNER, pas constater** (version 5). Un vrai rapport observé
  disait : *« Améliorer la ponctuation pour plus de clarté »*, *« Pratiquer l'utilisation de
  connecteurs pour mieux organiser les idées »* — et la seule correction proposée était
  l'ajout d'une virgule. Le candidat apprenait **ce qui n'allait pas, jamais comment faire**.
  Depuis la version 5, une priorité est composée de trois parties obligatoires :

  | Partie | Contenu |
  |---|---|
  | **constat** | Ce qui ne va pas, en une phrase, appuyé sur SA production. |
  | **comment** | **La technique**, réutilisable et appliquée à son texte : la règle, le mot-outil, la tournure modèle, la question à se poser en se relisant. Doit contenir un verbe d'action adressé au candidat (remplacez, ajoutez, commencez par, relisez). Les formules creuses citées plus haut sont **explicitement interdites**. |
  | **exemple** | Une phrase **exacte** du candidat, avant / après, qui montre la technique en usage. |

  Exemple réellement produit sur une copie A2 : *« Reliez vos idées avec un connecteur. Par
  exemple, remplacez le point entre "Il est petit mais joli" et "Il y a une chambre" par
  "et" : "Il est petit mais joli, et il y a une chambre et une cuisine." »*
- **Les exemples corrigés doivent faire gagner un niveau**, pas corriger des virgules. Une
  virgule ajoutée, un accent, une majuscule : interdits. Ce qu'on attend, ce sont des
  **reformulations** — une juxtaposition transformée en subordonnée, deux phrases fusionnées
  par un connecteur logique, un mot passe-partout remplacé par un terme précis, une
  affirmation transformée en argument justifié. Chaque exemple porte un champ **« gain »**
  qui dit en une phrase ce que la version corrigée démontre de plus (« cette version emploie
  une subordonnée relative, marqueur attendu au B1 »). **Trois au maximum** depuis la v8 :
  la consigne disait déjà « une à trois », mais rien ne le faisait respecter.
- **Au plus deux points forts** (v8), et ils suivent la même exigence que les priorités : de
  vrais points forts cités dans le texte, jamais un compliment de politesse. Une liste de cinq
  réussites dilue les deux qui comptent. Là encore, ce n'est pas qu'une consigne : **le serveur
  tronque** la liste avant l'affichage.

### 5.6 Ce qui empêche l'IA d'être trop gentille

Trois garde-fous écrits dans les consignes de notation, ajoutés après **mesure** (voir §12) :

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
linguistiques. Un critère de tâche ne peut donc pas dépasser de plus d'**un point** la
moyenne du lexique et de la morphosyntaxe (§5.2 bis). Réussir une tâche simple avec un
français très pauvre est une réussite **partielle**, pas une réussite exemplaire. Ce
garde-fou ne sert jamais à rogner une production riche : il ne fait jamais descendre
en dessous du niveau que la langue démontre déjà.

**L'ancrage du bas de l'échelle.** C'est la zone où une erreur coûte le plus cher au
candidat : lui annoncer B1 alors qu'il est A2, c'est lui faire payer un examen officiel qu'il
va rater. Les consignes contiennent donc un test explicite : pour dépasser A1, il faut
qu'apparaisse au moins un marqueur réellement construit — une subordonnée (« je pense **que**
… », « un homme **qui** … »), un temps du passé ou du futur correctement formé, ou une
tournure de politesse construite (« je voudrais », « est-ce que »). **Si l'IA classe A2 ou
au-dessus, elle doit citer le marqueur qu'elle a trouvé.** Si elle ne peut pas le citer, c'est
qu'il n'existe pas.

**L'ancrage du haut de l'échelle.** L'autre bout de l'échelle coûte tout aussi cher, pour une
raison très concrète : depuis le 1ᵉʳ janvier 2026, la naturalisation exige le **B2 dans les
quatre épreuves, sans aucune compensation**. Annoncer B2 à une personne réellement B1, c'est
l'encourager à déposer un dossier voué au refus après avoir payé l'examen. Les consignes
contiennent donc, depuis les rubriques **v4.2**, un test symétrique de celui du bas
(conservé à l'identique en v5 puis en v6).

> **Ce test est encore plus décisif depuis la v6**, où le seuil du B2 est descendu à
> **10/20** pour coller au vrai examen (§6.1). Sur cette échelle, un nombre n'est plus une
> appréciation, c'est **une déclaration de palier** : mettre 12 ou 13 à un critère, ce n'est
> pas « mettre une bonne note », c'est affirmer au candidat qu'il a le niveau exigé pour la
> naturalisation. Les consignes le disent en toutes lettres, avec la règle d'arbitrage
> correspondante : **un très bon B1 — long, fluide, richement subordonné, sans faute — se
> note 9, jamais 12 ni 13** ; et si l'IA hésite entre 9 et 12, la réponse est 9, parce que
> l'hésitation elle-même prouve que les deux marqueurs ne sont pas citables.

Ce qui sépare vraiment B1 de B2, ce n'est pas l'absence de fautes : c'est **l'efficacité de
l'argumentation et la défense d'un point de vue**, puis l'étendue du répertoire. Un B1 peut
être long, ordonné, agréable à lire et presque sans faute. **Enchaîner proprement des idées ne
fait pas un B2.** Pour classer B2, l'IA doit pouvoir **citer littéralement au moins deux
marqueurs** parmi :

- une **subordonnée d'un type absent du répertoire B1** : concessive (« bien que », « même
  si »), conséquence (« tellement… que »), but au subjonctif (« pour que »), hypothèse
  irréelle (« si j'avais… je serais… »), « à condition que » ;
- un **subjonctif ou un conditionnel employé à bon escient**, hors formule de politesse
  toute faite (« je voudrais », « pourriez-vous » ne comptent pas : c'est déjà du B1) ;
- une **objection envisagée puis traitée** : le candidat prête une objection à quelqu'un ou
  l'anticipe (« on m'objectera que… »), puis y **répond par un argument nouveau**. Une
  concession simplement admise et laissée là (« c'est vrai que…, mais moi je pense que… »)
  reste du B1: **reconnaître n'est pas réfuter** ;
- un **lexique précis, soutenu ou abstrait**, attesté par au moins deux termes qui sortent du
  vocabulaire courant du sujet (« super », « magnifique », « formidable » n'en sont pas) ;
- une **structure marquée** au service du propos (« ce qui m'a le plus surpris, ce n'est
  pas…, mais… », « il m'est impossible de… »).

Au moins un de ces deux marqueurs doit venir de **l'objection traitée** ou du **lexique
précis** — les deux endroits où le B1 et le B2 se distinguent le plus nettement. **Si l'IA ne
peut pas recopier ces marqueurs, c'est qu'ils n'y sont pas** : le niveau est B1, et **aucun
des quatre critères** ne dépasse alors **9/20** — soit, sur l'échelle du TCF, le **haut du
palier B1**, donc la meilleure note qu'un B1 puisse obtenir, pas une punition. Depuis la
version 5, le plafond couvre aussi *communiquer* et *interagir* : ils comptent pour la moitié
de la note, donc du niveau — les laisser à 12 pendant que la langue est plafonnée à 9 ferait
ressortir un B1 à 10,5/20, c'est-à-dire un faux B2.

Quatre **faux B2** sont nommés explicitement dans les consignes, parce que ce sont ceux qui
trompaient l'IA : les **connecteurs de surface** (« premièrement », « deuxièmement », « en
conclusion ») posés sur un contenu pauvre ; la **longueur** (une production longue qui ne
défend rien est un B1 long) ; la **correction confondue avec la richesse** ; et les
**formules apprises par cœur** (« il est indéniable que », « de nos jours »).

Ce plafond a une propriété importante : **il ne mord jamais en dessous de 10/20**. Il ne peut
donc, par construction, ni durcir la notation des productions A1, A2 ou B1, ni toucher à la
règle du hors-sujet. Et il n'autorise pas l'inverse non plus : dès que les deux marqueurs sont
citables, l'IA doit noter 12 à 16 **sans hésiter** — sous-noter un vrai B2 renverrait à un
entraînement inutile quelqu'un qui a déjà le niveau exigé.

Et une phrase qui résume tout : **« correction n'est pas niveau »**. Une production simple,
courte, propre et sans faute reste A2 si elle n'emploie que des structures élémentaires. Ce
n'est pas la correction qui fait monter le niveau, c'est l'**étendue** et la **complexité**.
Le piège le plus fréquent est l'énumération : réciter son nom, son âge, sa ville, son travail
et sa famille en phrases toutes construites sur le même moule, sans une faute, reste du A1.
La règle vaut aux deux bouts de l'échelle : en haut, une argumentation bien présentée mais
sans nuance ni lexique précis reste du B1.

### 5.7 Un rapport qui ne se répète pas et ne fait pas la leçon (v8)

Deux défauts revenaient dans les rapports réels. Ils ne concernaient pas la note — jugée
correcte — mais **ce que le candidat lisait**.

**« Une erreur, un seul endroit. »** Le même oubli d'accord pouvait apparaître dans le
commentaire du critère, puis dans une priorité, puis dans un exemple corrigé, puis dans une
suggestion : quatre fois. Le candidat en concluait qu'il avait quatre problèmes, alors qu'il
en avait un. Désormais chaque zone du rapport a **un rôle, et un seul** :

| Zone | Son rôle |
|---|---|
| **Commentaire d'un critère** | **Caractérise** ce critère et cite sa preuve. Il décrit ; il ne fait pas la leçon, n'explique pas comment corriger. |
| **Points à améliorer** | **Enseigne.** C'est le **seul** endroit où l'on explique comment corriger. |
| **Exemples corrigés** | **Démontrent** le palier au-dessus, sur des phrases **différentes** de celles déjà utilisées dans les priorités. |
| **Suggestions** | Uniquement ce qui n'a été traité **nulle part** ailleurs. |
| **Version améliorée** (écrit) | **Montre** le résultat en contexte, sans rien réexpliquer (§5.8). |

Deux interdits précis, ce sont les répétitions les plus fréquentes : réexpliquer dans le
« comment » ce qui est déjà dit dans le « constat », et réutiliser la même phrase du candidat
dans une priorité **et** dans un exemple corrigé.

**« On ne reproche pas ce qu'on n'a pas demandé. »** Un rapport disait *« aucun second temps
maîtrisé »* ou *« rien ne sort du répertoire A2 »* — un langage d'expert, adressé à un
professeur, à propos d'un moyen que la consigne n'exigeait pas. Depuis la v8, tout ce que le
candidat lit obéit à cette règle : l'absence d'un moyen linguistique **non exigé par la
consigne** (temps du passé, subordination complexe, connecteurs organisateurs…) est un
**levier de progression**, jamais un défaut :

> *« Tu utilises le présent partout, et c'est suffisant pour cette consigne. Ce qui te ferait
> gagner un niveau : raconter un fait passé au passé composé — "hier, j'ai visité
> l'appartement". »*

⚠️ **Attention à ne pas se tromper de portée.** C'est une règle de **formulation**, et rien
d'autre. Le raisonnement de notation est **inchangé** : c'est toujours la production qui doit
**démontrer** le niveau, et en l'absence de marqueurs, le niveau n'est pas accordé (§5.6). Le
justificatif interne du niveau — que le candidat ne voit pas — continue de dire les choses
sans détour. On dit la même chose au candidat, autrement. Et un point **obligatoire** de la
consigne réellement non traité, lui, reste un vrai manque : on le dit, simplement.

### 5.8 La version améliorée de votre texte (écrit uniquement, v8)

À l'écrit, le rapport se termine désormais par **votre production réécrite en entier**, telle
que vous auriez pu l'écrire au palier juste au-dessus. C'est le pendant naturel de la règle
précédente : au lieu d'accumuler des remarques sur des phrases isolées, on montre le résultat.

Cinq règles l'encadrent :

- **ce sont vos idées.** Mêmes informations, mêmes intentions, même contenu. L'IA n'a pas le
  droit d'inventer un détail que vous n'avez pas donné (une adresse, un horaire, un argument) ;
- **le palier juste au-dessus, pas l'excellence.** Un candidat A2 reçoit une version B1
  atteignable, jamais un modèle B2 : une version trop belle est décourageante et inutilisable ;
- **les bornes de mots de la tâche sont respectées** (30–60 mots en T1, 60–90 en T2/T3) ;
- **elle applique les corrections des priorités au lieu de les répéter** : on voit la technique
  à l'œuvre, on ne la réexplique pas. Aucun commentaire ni parenthèse dans le texte ;
- **le registre et le destinataire** de la consigne sont respectés, formule d'appel et de
  clôture comprises.

**À l'oral, il n'y en a pas**, et c'est délibéré : réécrire un échange oral en dialogue modèle
n'a aucun sens pédagogique, et cela reviendrait à commenter la forme orale, ce que nous nous
interdisons (§9). Si le correcteur en produit une malgré tout, le serveur la retire avant
l'affichage.

---

## 6. La note et le niveau

### 6.1 L'échelle du profil TCF IRN

Chaque critère est noté sur 20, **en absolu**, pas « par rapport au niveau visé de la
tâche ». Depuis la v6, les seuils suivent la table utilisée pour le TCF IRN ; depuis la
**v7**, le contrat et tous les libellés sont explicitement **plafonnés à B2** : SejourFR ne
produit aucune note C1 ou C2.

| Note d'un critère | Correspondance |
|-------------------|----------------|
| 10 – 20 | Niveau **B2** (10-11 : B2 tout juste atteint · 12-16 : B2 confirmé · 17-20 : B2 très solide) |
| 6 – 9 | Niveau **B1** (6-7 : B1 émergent · 8-9 : B1 solide, **y compris un très bon B1**) |
| 2 – 5 | Niveau **A2** (2-3 : A2 fragile · 4-5 : A2 solide, sans faute, consigne bien traitée) |
| 1 | Niveau **A1** — tout A1 vaut 1, il n'y a pas de « bon A1 » à 3 ou 4 |
| 0 | Rien d'exploitable : **hors-sujet** (voir §8) **ou** production en deçà du A1 |

> ⚠️ **Oubliez le réflexe scolaire.** Sur cette échelle, **10/20 n'est pas « la moyenne »,
> c'est le seuil du B2** — le niveau exigé pour la naturalisation. Et **5/20 n'est pas un
> mauvais résultat, c'est un A2 solide**. C'est déroutant au premier abord, et c'est
> exactement ce que verra le candidat le jour de l'examen. Les consignes données à l'IA le
> disent en toutes lettres, parce que c'est l'erreur la plus facile à commettre : sur cette
> échelle, **un nombre n'est pas une appréciation, c'est une déclaration de palier**.

L'échelle est volontairement **resserrée en bas** (0, 1, puis 2-5) et **large en haut**
(10-20). Ce n'est pas une anomalie de notre part : c'est la table officielle. Elle refuse les
demi-teintes en dessous du A1 et laisse au contraire de la place pour distinguer un B2 juste
atteint d'un B2 brillant.

**La note d'ensemble est la moyenne des quatre critères** (ils pèsent 25 % chacun), arrondie
au dixième. Elle n'est plus arrondie à l'entier depuis la version 5 : avec quatre critères à
25 %, la moyenne tombe sur des quarts de point, et arrondir faisait afficher « 13/20 » à côté
d'un niveau calculé sur 12,5 — exactement la contradiction que cette refonte doit faire
disparaître.

**Et le niveau se lit sur cette note** (§6.3), avec **exactement la même table** : c'est le
même barème appliqué une fois par critère, puis à leur moyenne. Il n'y a plus, comme dans les
versions précédentes, de décalage entre l'échelle d'un critère et celle de la note
d'ensemble — c'est précisément ce que la v6 corrige.

### 6.2 Ce que le candidat voit : des bandes, pas des chiffres, par critère

**Une IA ne distingue pas honnêtement un 13 d'un 14.** Afficher « Lexique : 13/20 » suggère
une précision qui n'existe pas. Depuis la version 4, **le candidat voit une appréciation par
critère**, pas un nombre :

| Note interne | Ce qui s'affiche |
|---|---|
| 10 – 20 | Très bonne maîtrise |
| 6 – 9 | Satisfaisant |
| 2 – 5 | En cours d'acquisition |
| 1 | Fragile |
| 0 | Non évaluable |

> Ces bornes **suivent l'échelle de la grille active** : elles ont changé avec la v6, en même
> temps que l'échelle. C'est indispensable — laissées à leurs anciennes valeurs, un critère à
> 8 (un bon B1) se serait affiché « en cours d'acquisition » et un critère à 12 (un B2
> confirmé) « satisfaisant ». Les mots affichés, eux, n'ont pas bougé : les trois applications
> n'ont rien à changer.

**La note globale sur 20 reste affichée**, elle. C'est le repère qu'un candidat attend d'un
examen, et la fausse précision est un problème au niveau du critère (5 nombres qui bougent),
pas au niveau du résultat d'ensemble. Les notes chiffrées par critère continuent d'exister en
interne : elles servent au calcul, au banc de mesure et à la console d'administration.

### 6.3 Le niveau CECRL par tâche : « performance observée »

Le **niveau CECRL** est le niveau de langue « officiel » (A1 débutant → C2 quasi natif).

Il est affiché **sur chaque tâche**, mais dans une formulation volontairement prudente :

> **Performance observée sur cette tâche : proche du niveau B1**
> Estimation pédagogique portant sur cette seule tâche. Le niveau qui fait foi est celui du
> bilan des trois tâches de l'épreuve.

Trois garde-fous, non négociables :

1. Le mot « proche de » et le rappel du bilan sont **toujours** affichés avec le niveau.
2. Ce niveau **n'est jamais affiché sans la confiance** (§7). Techniquement, si la confiance
   est inconnue, le niveau n'est pas envoyé du tout.
3. Le **bilan d'épreuve** reste le **seul** niveau qui fait foi.

**Comment ce niveau est calculé.** Pas par l'IA : par le serveur, et **directement à partir de
la note** — c'est-à-dire de la moyenne des quatre critères du TCF :

| Note de la tâche (moyenne des 4 critères) | Niveau |
|---|---|
| 10 et plus | B2 (plafond) |
| 6 à 9,9 | B1 |
| 2 à 5,9 | A2 |
| au-dessus de 0, sous 2 | A1 |
| exactement 0 | A1 non atteint |

**C'est la table officielle du TCF, à l'identique** (§6.6). Deux changements successifs y ont
mené :

- **version 5** : jusqu'à la 4.2, le niveau était calculé sur la moyenne de trois critères de
  langue seulement (lexique, morphosyntaxe, cohérence), et l'accomplissement de la tâche en
  était **explicitement exclu**. Le résultat était une carte qui pouvait afficher « 11/20 » et
  « proche du niveau A2 » côte à côte. La v5 a fait de la note et du niveau **deux lectures du
  même nombre** : ils ne peuvent plus se contredire *entre eux* ;
- **version 6** : il restait une contradiction, avec le vrai examen cette fois. Une même carte
  affichait « 12,5/20 » et « proche du niveau B1 » — or 12,5 vaut **B2** sur la grille
  officielle. Un candidat qui connaît cette grille lisait donc deux choses opposées. La v6
  supprime l'écart en adoptant l'échelle du TCF pour la note **et** pour chaque critère.

Ce que cela ne veut pas dire : que réussir une tâche simple suffit. Le garde-fou de couplage
(§5.2 bis) et les descripteurs par niveau tiennent cette porte fermée — une langue A2 au
maximum plafonne la note à 5,5/20, donc à A2.

Le niveau que l'IA propose de son côté est conservé en base pour la calibration, mais **n'est
jamais affiché**.

### 6.4 Deux plafonds ciblés

Après le calcul du niveau, le serveur applique deux règles qui ne peuvent qu'**abaisser** un
niveau, jamais le relever :

- **Tâche 3 (écrite ou orale) sans opinion identifiable** — si le critère qui porte
  l'accomplissement (**communiquer** depuis la version 5) est **à 1/20 ou moins**, la tâche
  consiste précisément à donner et défendre un avis : le niveau observé ne peut pas dépasser
  **A2**.
- **Oral, tâche 2, sans véritable échange** — même critère, même seuil : le dialogue n'a pas
  vraiment eu lieu, même plafond **A2**.

> **Le seuil valait 5 jusqu'à la v5, il vaut 1 depuis la v6** : ce n'est pas un
> assouplissement, c'est la même règle transposée. Dans les deux cas, le seuil est le **haut
> du palier A1** de l'échelle en vigueur (1-5 hier, 1 aujourd'hui) : le plafond se déclenche
> quand la tâche n'a **pas du tout** été réalisée. Laisser 5 sur la nouvelle échelle aurait
> plafonné à A2 tout candidat dont *communiquer* vaut 5 — c'est-à-dire un A2 **solide** — et
> transformé une règle ciblée en sanction de masse.

Dans les deux cas, le candidat reçoit l'explication en clair, pas seulement un chiffre plus
bas.

**Un plafond compte aussi dans le bilan de l'épreuve.** Ce n'est pas seulement le niveau
affiché sur la tâche qui est abaissé : la tâche entre dans la moyenne pondérée du bilan
(§6.5) **avec son niveau plafonné**, pas avec le niveau qu'elle aurait eu sans le plafond.
Une tâche 3 plafonnée à A2 pèse donc dans le bilan comme une tâche A2 — sinon la règle
n'aurait servi qu'à changer un libellé, alors que le bilan est le seul niveau qui fait foi.

### 6.5 Le bilan d'une épreuve complète

C'est le seul niveau qui fait foi. Il apparaît à la fin d'un examen blanc qui enchaîne les
3 tâches d'une épreuve.

- **La note de l'épreuve est la moyenne des trois notes de tâche**, et **le niveau de
  l'épreuve se lit sur cette note**, avec les mêmes bandes qu'au §6.3. Une seule histoire,
  un seul nombre.
- Les trois tâches comptent **à poids égal** depuis la version 5. Auparavant la tâche 1
  comptait 1, la 2 comptait 2 et la 3 comptait 3. Deux raisons de revenir à l'égalité : le
  TCF publie **une** note sur 20 par épreuve et aucune pondération par tâche ; et la
  difficulté croissante des trois tâches est **déjà** portée par leurs descripteurs (la
  tâche 3 vise B2), la pondérer une seconde fois la compterait deux fois. Le réglage reste
  modifiable sans redéploiement.
- Il est **plafonné à B2**, niveau maximal du profil TCF IRN couvert par SejourFR.
- Une tâche non rendue (temps écoulé, abandon) compte comme **0**.
- Une production hors-sujet compte 0 elle aussi : elle pénalise sans annuler le reste.
- Une tâche **plafonnée** (§6.4) entre avec son niveau plafonné.
- **Une tâche ne se rend qu'une fois par examen.** Un examen blanc, c'est trois tâches,
  une production chacune : une seconde production sur une tâche déjà rendue est refusée.
  Pour refaire une tâche, on relance un examen (ou on s'entraîne librement, hors examen).
- **Une production ne peut être rendue que dans l'épreuve à laquelle elle appartient** :
  une tâche orale dans une session d'expression écrite (ou l'inverse) est refusée. Sans
  cette règle, une production mal aiguillée pouvait clore la mauvaise épreuve et lui poser
  un niveau qui n'était pas le sien.
- **Un examen d'expression orale dure 15 minutes**, comme l'examen d'expression écrite en
  dure 30. Les trois tâches orales plafonnent le temps de parole à 3 + 3,5 + 3,5 minutes ;
  les 5 minutes restantes couvrent la lecture des consignes et les transitions.
- **Une épreuve qu'on n'a pas pu passer n'a pas de niveau — elle n'est pas « ratée ».**
  Deux cas : l'épreuve était **verrouillée** (compte gratuit qui refait un examen blanc
  complet après avoir déjà utilisé son expression écrite et orale offertes), ou ses
  corrections ont **échoué** techniquement. Dans les deux cas, on n'affiche **aucun**
  niveau pour cette épreuve, et elle n'entre pas dans le niveau global de l'examen. Le
  système annonce alors combien d'épreuves comptent réellement, et le résultat est
  présenté comme **partiel**. C'est une correction d'un défaut grave : jusqu'ici une
  épreuve verrouillée était comptée « A1 non atteint », si bien qu'un candidat lisait
  « votre niveau : A1 non atteint » à côté d'un cadenas « réservé à l'abonnement ».
  Autrement dit, un **verrou commercial** lui était restitué comme un **verdict sur son
  français**. Un abonnement qui manque ne dit rien du niveau de langue de personne.

### 6.5 bis Pas de B2 au bilan sans argumentation (garde-fou de cohérence, **actif**)

Le niveau d'une épreuve est une moyenne des trois tâches. Or les trois tâches ne sont pas
interchangeables : **la tâche 3 est la seule qui demande d'argumenter**, donc la seule qui
puisse démontrer un B2. Quelqu'un qui écrit un message simple impeccable, réussit
l'échange de la tâche 2, puis s'effondre dès qu'il faut défendre un point de vue, sortait
avec un **B2 de bilan** porté par ses deux premières tâches.

La règle, désormais **appliquée** : **quand la tâche 3 est en dessous de B1, le bilan de
l'épreuve ne peut pas dépasser B1.** Une tâche 3 jamais rendue dans une épreuve terminée
compte comme un effondrement (elle vaut 0) ; une tâche 3 pas *encore* rendue dans une
épreuve en cours ne déclenche rien — on ne conclut pas d'une tâche absente.

Ce garde-fou ne peut qu'**abaisser** un niveau, jamais le relever. C'est précisément ce
qui le rend sûr : dans le pire des cas il est trop prudent, jamais trop généreux.

> ⚠️ **Ce choix repose sur un raisonnement, pas sur une mesure — et il faut le dire.** Le
> banc de mesure (§12) **ne peut pas** trancher cette question : son corpus de référence
> porte un niveau attendu **par tâche**, et ne contient **aucune** référence de niveau
> d'épreuve. Il n'existe donc, à ce jour, aucun chiffre disant si la règle rapproche ou
> éloigne nos bilans de ceux d'un jury. Elle a été activée parce qu'annoncer B2 — le
> niveau exigé pour la naturalisation — à quelqu'un qui n'a pas su argumenter revient à
> lui faire payer un examen officiel qu'il va rater. La façon honnête de la vérifier
> viendra de la console de calibration (§14), quand elle aura accumulé de vraies épreuves
> complètes annotées par des enseignants. En attendant, la règle est **réversible d'un
> seul réglage**, et l'éteindre rend exactement les bilans d'avant.

Aujourd'hui il n'existe qu'**un seul palier** de cette règle (« pas de B2 si la tâche 3
est sous B1 »). L'étendre palier par palier — par exemple « pas de B1 si la tâche 3 est
sous A2 » — est possible **sans rien changer au calcul** : il suffirait de déclarer
plusieurs couples (seuil de tâche 3 → plafond de bilan) et de retenir le plus bas. Ce
n'est **pas** fait : on ne généralise pas une règle qu'aucune mesure ne peut encore
valider.

### 6.6 Notre note sur 20 est désormais **celle du TCF** (ce qui a changé, et ce qui n'a pas changé)

C'est le point le plus important de ce chapitre, et celui qui trompait le plus de candidats.

> ⚠️ **Avertissement de mise à jour.** Jusqu'à la version 5, ce paragraphe expliquait
> l'inverse : que notre note était « pédagogique », sur une échelle « plus fine » que celle du
> TCF. **Ce n'est plus vrai.** Toute phrase de ce type encore affichée dans le site web ou
> l'application mobile est devenue fausse et doit être retirée — la liste des écrans concernés
> est à la fin de cette section.

**La note du vrai TCF.** Aux épreuves d'expression (écrite et orale), le TCF IRN donne une
note sur 20 pour **l'épreuve entière** — les trois tâches ensemble — et cette note se traduit
en niveau selon une grille officielle très resserrée :

| Note obtenue au TCF | Niveau attribué |
|---|---|
| 0 | A1 non atteint |
| 1 | A1 |
| 2 – 5 | **A2** |
| 6 – 9 | **B1** |
| 10 – 20 | **B2** |

Autrement dit : **au vrai TCF, 10/20 suffit pour être B2** — le niveau exigé pour la
naturalisation. Et 6/20 suffit pour B1, le niveau exigé pour la carte de résident.

**Notre note.** C'est **la même échelle**, depuis la version 6. Un 12/20 chez nous, c'est du
B2 ; au TCF, un 12/20 c'est du B2. Un 5/20 chez nous, c'est un A2 solide ; au TCF aussi. **Il
n'y a plus d'écart à expliquer au candidat.**

**Pourquoi on a fini par copier l'échelle du TCF.** Pendant longtemps nous ne l'avons pas
fait, et l'argument avait sa valeur : la grille officielle est très comprimée, la moitié de
l'échelle (10 à 20) vaut un seul et même niveau, et un candidat qui passe de 10 à 18 n'y voit
aucune mention changer. Une échelle plus étalée montrait mieux les progrès **à l'intérieur**
d'un niveau.

Ce raisonnement a été abandonné pour une raison plus forte : **il produisait une contradiction
visible à l'écran**. Une même carte de résultat pouvait afficher « 12,5/20 » et « proche du
niveau B1 ». Pour un candidat qui connaît la grille officielle — et tous finissent par la
connaître — 12,5 veut dire B2. Les deux informations se contredisaient, et aucune note de bas
de page n'y changeait rien : entre un chiffre et une explication, c'est le chiffre qui reste
en mémoire. Sur un examen où le B2 conditionne une naturalisation, l'ambiguïté n'est pas
acceptable.

**Ce qu'on perd, et comment on le compense.** On perd la finesse : deux productions B2 de
qualité très différente peuvent désormais se retrouver plus proches. La progression
**à l'intérieur** d'un niveau se lit maintenant ailleurs — dans les **bandes par critère**
(§6.2), dans le bloc « ce que vous avez traité / oublié » (§5.4), dans les priorités et les
exemples corrigés (§5.5), qui disent bien plus qu'un point de note. Et à l'intérieur du B2,
les consignes distinguent explicitement « B2 tout juste atteint » (10-11) de « B2 confirmé »
(12-16), ce qui laisse de la marge visible.

**Ce qu'on affiche pour lever l'ambiguïté.** À la fin d'une épreuve complète (les 3 tâches),
sous le niveau estimé, nous ajoutons la correspondance officielle :

> Au TCF, le niveau B1 correspond à une note de 6 à 9 sur 20.
> *Grille officielle du TCF IRN, sur l'épreuve entière.*

C'est une **table de correspondance officielle**, pas une conversion que nous aurions
inventée. Nous **ne transformons jamais** notre note en note de TCF : nous partons du
**niveau** estimé, et nous affichons la fourchette officielle de ce niveau. C'est la seule
chose qui soit honnête, parce que le niveau est la grandeur commune — pas la note.

Depuis la version 5, cette correspondance est une fonction directe de **la note d'épreuve**,
puisque le niveau d'épreuve se lit lui-même sur cette note (§6.3, §6.5) : note d'épreuve →
niveau → fourchette officielle. Depuis la version 6, la note et la fourchette tombent en plus
sur la **même échelle**, ce qui rend l'affichage cohérent au lieu de simplement compatible.

**Ce qui reste interdit malgré tout : le raccourci « notre 13/20 = 13/20 au TCF ».** Même
échelle ne veut pas dire même mesure. Notre note porte sur **une tâche** (ou sur la moyenne
des trois), celle du TCF sur **l'épreuve entière**, corrigée par des examinateurs humains, sur
un sujet passé une seule fois en conditions réelles. Ce qu'on peut dire honnêtement, c'est :
« sur cette production, l'IA situe votre niveau à B1, et au TCF le B1 correspond à 6-9/20 ».
Ce qu'on ne peut pas dire, c'est « vous aurez 13/20 au TCF ».

**Où cette correspondance n'apparaît pas, et pourquoi.** Jamais sur le résultat d'une **tâche
isolée**. Au TCF, la note sur 20 récompense une épreuve entière ; une tâche seule n'a pas de
note officielle. Y afficher une fourchette TCF reviendrait à inventer une note qui n'existe
pas — et cela reste vrai depuis la v6, où l'échelle est pourtant la même : c'est le
**périmètre** qui diffère, pas l'échelle. Sur l'écran d'une tâche, on garde donc
« performance observée sur cette tâche » (§6.3) et le rappel que le niveau qui fait foi est
celui du bilan des trois tâches.

**Comment la bascule a été faite sans casser la calibration.** Le piège était connu et il est
écrit ici depuis la version 5 : **déplacer seulement les seuils aurait été une faute.** L'IA
notait avec les repères de l'ancienne échelle, où une performance B2 valait 16-20 ; poser
« B2 ≥ 10 » par-dessus cette notation aurait fait basculer en B2 une masse de productions B1
d'un seul coup, et annulé des mois de calibration mesurée (§12).

La bascule a donc consisté à faire **noter l'IA sur l'échelle du TCF**, pas à réétiqueter ses
notes : chaque repère de notation, chaque descripteur de tâche et **les seize exemples de
calibration** ont été ré-écrits avec leurs notes recalculées sur la nouvelle échelle ; le
garde-fou de couplage et les seuils de plafond ont été recalculés dans la même logique
(§5.2 bis, §6.4) ; et le tout a été **mesuré contre un témoin de la version 5 rejoué le même
jour** (§12.4). Sans ce travail de fond, le changement de seuils seul aurait été cosmétique et
dangereux.

**L'ancien discours a disparu des écrans.** Ils affichaient, sous la note, une phrase du type
« notre échelle est plus fine que celle du TCF, elle sert à suivre vos progrès ». Elle est
devenue fausse et a été retirée du web comme du mobile, remplacée par la lecture directe de
l'échelle : « 10 et plus correspond à B2, 6 à 9 à B1, 2 à 5 à A2 ». Aucun échange de données
entre le serveur et les applications n'a changé : c'était du **texte d'interface** uniquement.

**Ce que l'échelle du TCF a imposé de corriger en plus.** Elle est bien plus resserrée qu'une
note scolaire, et les écrans avaient été dessinés pour une note scolaire. Une production à
**7/20 — c'est-à-dire B1, le niveau exigé pour la carte de résident** — s'affichait
« À retravailler », en rouge, avec « 35 % » en chiffre dominant au centre du cercle. On
décourageait quelqu'un qui avait exactement le niveau qu'il visait. Le pourcentage et les
libellés scolaires ont été retirés, et la couleur suit désormais le **palier CECRL** et non un
seuil sur cent.

**Ce qui reste à arbitrer** (décisions produit, non tranchées) : le cercle de progression se
remplit toujours à `note/20`, donc un B2 à 10/20 montre un anneau à moitié vide ; et les
cartes de tâches du hub web affichent encore un pourcentage calculé en `note × 5`, où un
12/20 — un B2 solide — s'affiche « 60 % ». Ce dernier point vient d'une formule de progression
partagée avec le tableau de bord et les recommandations : le corriger seulement côté web
désynchroniserait les trois surfaces.

---

## 7. La confiance : dire quand on n'est pas sûr

Avant, « 13/20 » s'affichait sur le même ton, qu'il s'agisse d'un texte écrit propre de
90 mots ou d'un dialogue oral transcrit en direct, haché, à moitié illisible. **Ce n'était pas
honnête.**

L'IA déclare donc obligatoirement une **confiance**. Depuis la v8, une phrase la résume :
**la confiance mesure la certitude du correcteur, jamais la qualité du candidat.**

C'était le défaut le plus injuste du rapport. Les consignes disaient « production trop pauvre
pour observer la grammaire » : un candidat qui écrivait un texte **entier, lisible et
complet** — mais faible — se voyait annoncer « confiance moyenne ». On lui laissait croire
qu'on avait un doute sur lui, alors qu'on avait parfaitement observé son niveau : il était
bas. **Un niveau bas est une observation, pas un doute.**

| Confiance | Quand |
|---|---|
| **Haute** | Le correcteur a pu lire ou entendre **tout** ce que le candidat a produit, et la consigne est claire. C'est le cas **normal** — y compris quand la production est très faible ou truffée de fautes. |
| **Moyenne** | Un obstacle **matériel** limite l'observation : transcription partiellement incertaine, passages illisibles, échange interrompu en cours, consigne ambiguë, production trop **brève** pour contenir des marqueurs observables (quelques mots produits — ce qui n'a rien à voir avec quelques fautes). |
| **Faible** | L'obstacle est majeur : transcription très bruitée ou tronquée, tâche interrompue avant d'avoir produit quoi que ce soit d'observable. |

Elle donne 1 à 3 **raisons courtes et lisibles par le candidat**, et **uniquement des obstacles
à l'observation** : « transcription temps réel partiellement incertaine », « échange interrompu
avant la fin », « douze mots produits, trop peu pour observer la syntaxe ». Justifier une
confiance par la qualité (« trop de fautes pour juger ») est désormais **interdit**.

**Le serveur peut abaisser cette confiance, jamais la relever.** Elle est automatiquement
plafonnée à « moyenne » dans deux cas : quand les vérifications automatiques (§4) ont signalé
un **obstacle à l'observation** — c'est-à-dire une production qui ne semble qu'à moitié
rédigée en français —, et quand la production vient d'un **dialogue en temps réel**.

**Le serveur s'applique à lui-même l'interdit qu'il impose à l'IA.** Un énoncé partiellement
recopié (§4) est un soupçon sur l'**origine** des mots, pas un obstacle à leur lecture : le
candidat en est averti, ses passages recopiés sont écartés, et le reste s'observe
parfaitement. Cet avertissement ne plafonne donc **plus** la confiance. Convertir un soupçon
en incertitude de correction était exactement la confusion que la v8 interdit au correcteur ;
le serveur la commettait encore.

Trois interdits absolus, dont le troisième est apporté par la v8 :

- **la confiance ne baisse jamais la note.** La confiance dit ce qu'on **sait** ; la note dit
  ce qu'on a **observé** ;
- **la note ne baisse jamais la confiance.** Une production faible, fautive, élémentaire ou
  courte-mais-complète n'est **pas** une raison d'être moins sûr de soi ;
- une confiance faible n'autorise **jamais** à conclure au hors-sujet ni à
  l'incompréhensibilité.

Si l'IA oublie de déclarer une confiance, sa réponse est désormais **rejetée avant
normalisation**. Le serveur demande une seule réparation ; si le champ manque encore, la
correction passe en échec au lieu d'inventer une confiance ou de persister un résultat
partiel.

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
  L'IA doit porter cette réussite de communication au crédit du candidat, **dans le critère
  communiquer** — jamais dans le lexique ni la grammaire.

- **On n'exige jamais l'exhaustivité.** Voir §5.3 : les pistes du sujet ne coûtent rien.

- **La longueur n'est jamais un motif de note.** À l'écrit, la soumission est bloquée hors
  des bornes strictes du TCF IRN (T1 30–60, T2/T3 60–90) : l'IA ne reçoit donc jamais un
  texte nouveau « toléré » au-delà du maximum. À l'oral, la durée n'est plus transmise au
  correcteur et aucun avertissement de durée n'est ajouté au résultat. Une production peut
  offrir moins de matière observable, ce qui peut seulement être expliqué dans les raisons
  de confiance ; ni la longueur ni la durée ne retirent des points.

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
- **La session est vérifiée avant d'être ouverte, pas après coup.** Une simulation orale ne
  démarre que si elle peut réellement être notée : l'épreuve visée doit être la bonne, encore
  ouverte, dans les temps, et la tâche pas déjà rendue dans cet examen. Autrement dit, la
  simulation orale obéit exactement aux mêmes règles que l'enregistrement classique — elle ne
  permet pas de rendre une tâche que l'autre voie aurait refusée, et on ne peut plus consommer
  une simulation pour s'entendre dire à la fin qu'il n'y avait rien à noter.

---

## 11. Ce que le candidat reçoit à la fin

Dans cet ordre :

0. **Le verdict de la tâche** (§5.4) : « Objectif : atteint / partiellement atteint / non
   atteint », suivi d'une phrase qui dit ce qu'il a fait.
1. **Ce qu'il a traité et ce qu'il a oublié** (§5.4) — avant toute considération de langue.
2. **La note sur 20** — sur l'échelle du TCF depuis la v6, mais **sans correspondance TCF
   affichée sur une tâche isolée** (§6.6 : au TCF, la note /20 est celle d'une épreuve
   entière) — et, avec elle, la **performance observée** sur cette tâche et la **confiance**
   (§6.3, §7).
3. **Les avertissements** éventuels : limite de l'évaluation orale (§9), plafond appliqué
   (§6.4), doute signalé par les vérifications automatiques (§4).
4. **1 à 2 points forts** — ce qu'il a réussi, cité dans sa production (pas des compliments de
   politesse).
5. **1 à 2 points à améliorer** — les priorités, pas une liste décourageante. Chacune avec
   son **constat**, son **« comment »** (la technique à appliquer) et un **exemple avant /
   après** pris dans sa propre production (§5.5).
6. **Suggestions** — conseils pédagogiques (règles à revoir, exercices), et uniquement ce qui
   n'a été dit nulle part ailleurs (§5.7).
7. **Jusqu'à 3 exemples corrigés** — des phrases exactes du candidat, réécrites au **palier
   au-dessus**, avec l'explication et le **gain** obtenu. Jamais une correction de
   ponctuation. (À l'oral, uniquement des reformulations qui améliorent vraiment la clarté.)
8. **Une appréciation par critère** (bande + commentaire + citation), avec le libellé propre à
   la tâche.
9. **À l'écrit : la version améliorée de sa copie entière** (§5.8), au palier juste au-dessus,
   avec ses seules idées. Rien de tel à l'oral.
10. *(Inactif aujourd'hui)* Sur une production orale, un encart **débit et pauses** —
    informations factuelles, hors note. Voir §13.

Les évaluations rendues **avant la v8** (une centaine, déjà en base) ne portent ni verdict ni
version améliorée : rien n'a été recalculé ni réécrit rétroactivement, ces deux blocs ne
s'affichent simplement pas. On versionne, on ne réécrit pas — y compris les résultats déjà
rendus.

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
- une **fourchette de note** acceptable sur 20. Depuis la v6, elle n'est plus un jugement
  indépendant : elle se **déduit mécaniquement du niveau attendu** par la table officielle du
  TCF (§6.6). C'est la conséquence directe de « notre note est celle du TCF » — si le niveau
  est B1, la note ne peut être que dans 6-9. Lors de la bascule, ces fourchettes ont été
  régénérées à partir des niveaux existants ; **les niveaux, tolérances, confiances, pièges et
  productions n'ont pas été touchés.** On ne retouche jamais la référence pour faire passer
  une version — on peut la ré-exprimer sur une autre échelle, jamais l'ajuster ;
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
| **Cas perdus, et leur motif** | Combien de productions n'ont **pas pu être corrigées du tout**, et **pourquoi** : réponse coupée en cours de route, citation refusée, garde-fou de l'oral, fournisseur indisponible. Le taux est affiché **à côté** du taux de sortie invalide, jamais à la place. |
| **Stabilité** | On rejoue le même lot plusieurs fois : la même production reçoit-elle la même note ? |

### 12.3 bis Une mesure qui cachait son propre coût

Il faut le dire, parce que c'est le genre de défaut qui se répète : **le rapport du banc
annonçait « 0 % de sortie invalide » alors qu'environ un tiers des corrections orales se
perdaient.** Les deux affirmations étaient vraies en même temps, et c'est bien le problème.
« Sortie invalide » ne comptait qu'un cas précis — une réponse complète à qui il manque un
champ. Tout le reste — réponse **coupée en plein milieu** parce que la limite de longueur était
atteinte, citation refusée que la réparation n'avait pas réparée, garde-fou de l'oral déclenché
— tombait dans un fourre-tout « erreur d'appel » qui n'était pas mis en avant. **Une métrique
qui rend son propre défaut invisible ne sert à rien.**

Trois corrections en découlent, et la troisième porte sur la méthode :

1. **La limite de longueur de réponse a été relevée** (de 2 000 à 4 000 unités de texte). Elle
   avait été fixée bien avant que le format de réponse n'exige **quatre citations littérales**
   supplémentaires. Mesuré : une correction écrite tient dans ~1 500, une correction orale
   demande 1 800 à 2 000 — donc la limite était atteinte ou frôlée sur **presque toutes** les
   corrections orales. Quand elle est atteinte, la réponse est tronquée en pleine phrase, elle
   devient illisible, et **le candidat ne voit pas sa note**. C'est un plafond, pas une
   consommation : on ne paie que ce qui est réellement produit, le relever ne coûte donc rien
   sur les corrections courtes. La valeur est **identique pour les trois correcteurs possibles**
   et verrouillée par un test.
2. **Le motif de chaque perte est désormais affiché et ventilé**, et le **taux de cas perdus**
   apparaît à côté du taux de sortie invalide, dans le rapport lisible comme dans le fichier de
   résultats. On distingue en particulier ce qui est notre défaut (réponse tronquée, citation
   refusée) de ce qu'on subit (fournisseur indisponible ou qui limite le débit) : sans cette
   séparation, une campagne bridée par le fournisseur se lit à tort comme une régression de
   qualité.
3. **Ce qui a permis à ce trou de s'installer, c'est une exception à la règle de mesure.** La
   contrainte de preuve littérale — chaque critère doit citer un passage réel — a été livrée
   **sans campagne avant/après**, contrairement à toutes les versions de consignes qui l'ont
   précédée, et sans rejouer le témoin de la version précédente le même jour. La contrainte
   elle-même est bonne et n'est **pas remise en cause** : elle empêche une citation inventée
   d'être affichée à un candidat. Mais **son coût en corrections perdues n'avait jamais été
   mesuré**, donc personne ne pouvait le voir. On le laisse écrit ici, corrigé mais pas effacé :
   *une garantie livrée sans mesure de ce qu'elle coûte est une garantie dont on ignore le
   prix.*

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

**Deuxième correction : la frontière B1/B2** (consignes **v4.2**, alors actives). Une fois
le bas de l'échelle réparé, le défaut résiduel s'était **déplacé vers le haut** : **3
productions B1 sur 12** ressortaient B2. C'était devenu l'erreur la plus coûteuse du système
(§5.6). La même technique que pour le bas a été appliquée en haut : un **test opposable avec
obligation de citation**, et non des descripteurs « plus précis » — ces derniers n'avaient
rien donné en v4.1 non plus.

Mesure : **3 campagnes v4.2** contre **1 campagne v4.1 relancée le même jour, sur le même
modèle**, pour comparer à conditions égales.

| | v4.1 | v4.2 |
|---|---|---|
| productions B1 correctement classées | **8/12** | **11/12, 10/12, 11/12** |
| productions B2 correctement classées | **6/7** | **7/7, 7/7, 7/7** |
| productions A2 correctement classées | 11/13 | 11/13 ×3 |
| productions A1 correctement classées | 7/8 | 6/8, 7/8, 6/8 |
| accord exact (48 cas) | **75,0 %** | **81,25 % ×3** |
| accord à un niveau près | 85,4 % | **91,7 % ×3** |
| notes dans la bonne fourchette | 83,3 % | 83,3 %, 81,3 %, 83,3 % |
| écart de sévérité (référence − IA) | −1,05 | −0,89, −1,03, −0,89 |
| réponses inexploitables | 0 % | 0 % ×3 |

Ce qu'il faut en retenir, et ce qu'il ne faut pas en conclure :

- le gain sur les **B1** est réel : **+2 à +3 productions** sur 12, dans les trois campagnes.
  Ce n'est pas un cas isolé qui bascule ;
- **rien n'a été écrasé en haut au passage** : les B2 ne sont pas seulement préservés, ils
  sont **meilleurs** (7/7 trois fois, contre 6/7). C'était le risque principal — corriger les
  B1 en renvoyant de vrais B2 en B1 aurait été un échec, pas une réussite ;
- le bas de l'échelle n'a **pas bougé** : A2 identique, A1 à ±1 production, hors-sujet toujours
  à 0/20, transcriptions bruitées toujours correctement traitées. C'est attendu : le plafond
  v4.2 ne s'applique qu'au-dessus de 15/20, il ne peut mécaniquement rien changer plus bas ;
- l'écart de −1,03 d'une des campagnes v4.2 et l'écart de −1,05 de la campagne v4.1 sont **le
  même chiffre à la mesure près** : moins d'un point de note entre deux campagnes, c'est du
  bruit, pas un signal.

**Troisième correction : la grille du TCF** (consignes **v5**, alors actives). Les deux
premières corrections portaient sur la sévérité ; celle-ci porte sur **ce qu'on mesure**. La
grille maison (5 critères à poids variables, accomplissement exclu du niveau) a été remplacée
par celle du TCF (4 critères égaux, accomplissement compris) — les raisons sont au §5.1.

Mesure : **une campagne v4.2 relancée le même jour, sur le même modèle**, contre la v5. Trois
avertissements avant de lire le tableau, parce qu'ils changent la lecture :

1. **Le fournisseur d'IA local avait changé** entre-temps. Les deux premières campagnes de la
   journée ont tourné par erreur sur un autre modèle, qui classait v4.2 à **41,7 %** au lieu
   des 81,3 % connus. C'est le témoin qui l'a révélé — sans lui, on aurait attribué cet
   effondrement à la v5. **Un témoin rejoué le même jour n'est pas une formalité.**
2. Le fournisseur a **limité le débit** pendant les campagnes v5 : 5 productions sur 48 n'ont
   pas pu être évaluées. Elles comptent comme des échecs dans la colonne « sur 48 » et sont
   exclues de la colonne « sur les cas mesurés ». Les deux lectures sont données.
3. Les **seuils note → niveau ont été recalés** (16 / 13 / 9 au lieu de 15 / 12 / 8) — pas
   pour faire de beaux chiffres, mais parce que **la note ne mesure plus la même chose** :
   elle inclut désormais l'accomplissement, qui tire légitimement la moyenne d'environ un
   point et demi vers le haut. Ils ont été choisis par un rejeu **hors ligne** de la première
   campagne v5 (aucun appel d'IA supplémentaire), puis **confirmés sur une seconde campagne**.

| | v4.2 (témoin, même jour) | v5 |
|---|---|---|
| productions A1 non atteint correctement classées | 4/8 | 4/8 |
| productions **A1** correctement classées | 6/8 | **8/8** |
| productions **A2** correctement classées | 11/13 | **11/13** (11/12 des cas mesurés) |
| productions B1 correctement classées | 11/12 | 9/12 — **9/9 des cas mesurés** |
| productions B2 correctement classées | 7/7 | 6/7 — **6/6 des cas mesurés** |
| accord exact | **81,3 %** (48 cas) | 79,2 % sur 48 · **88,4 % sur les 43 cas mesurés** |
| pièges évités | 7/8 | 5/8 · **5/6 des cas mesurés**, avec exactement le même unique échec |
| réponses inexploitables | 0 % | 0 % |
| écart de sévérité (référence − IA) | −0,91 | −1,23 |

Ce qu'il faut en retenir, et ce qu'il ne faut pas en conclure :

- **le risque principal ne s'est pas matérialisé.** Remettre l'accomplissement dans le niveau
  pouvait re-gonfler le bas de l'échelle — ce que la v4.1 avait précisément corrigé. Il n'en
  est rien : les A1 passent de 6/8 à **8/8**, les A2 restent à 11/13, les productions
  hors-sujet et les transcriptions bruitées sont traitées à l'identique. C'est le garde-fou de
  couplage (§5.2 bis) qui tient cette porte ;
- **aucun palier n'est dégradé** : chaque niveau est égal ou meilleur sur les cas réellement
  mesurés, et le seul piège manqué est le **même** dans les deux versions (une production
  quasi muette classée A1 au lieu de « A1 non atteint ») ;
- l'écart de sévérité passe de −0,91 à −1,23 : **moins d'un point d'écart entre deux
  campagnes, c'est du bruit**, pas un signal ;
- la part de notes tombant dans la fourchette attendue du corpus baisse (83,3 % → 76,7 %).
  **Ce n'est pas une dégradation de qualité mais un changement d'échelle** : les fourchettes
  de notes du corpus ont été écrites pour l'ancienne définition de la note (sans
  l'accomplissement). Le corpus n'a **pas** été retouché — on ne corrige jamais la référence
  pour faire passer une version. Les candidats verront des notes plus hautes qu'avant pour une
  même production ; les **niveaux**, eux, sont plus justes ;
- **ce qui n'est pas mesuré** : la qualité pédagogique des priorités (le « comment »). Le banc
  ne compare que des notes et des niveaux. Elle a été vérifiée à la main sur des productions
  réelles, et elle est garantie par le format de réponse (§5.5), mais elle n'a pas de chiffre.

**Quatrième correction : l'échelle du TCF** (consignes **v6**, alors actives). La v5 avait
adopté les **critères** du vrai examen ; celle-ci adopte son **échelle**, pour supprimer la
dernière contradiction visible à l'écran (« 12,5/20 » et « proche du B1 » sur la même carte,
§6.6).

Mesure : **une campagne v5 rejouée le même jour, sur le même modèle et le même corpus**,
contre la v6. Trois avertissements avant de lire le tableau :

1. **Les fourchettes de notes du corpus ont été régénérées** (§12.2). Elles ne sont plus des
   jugements indépendants : ce sont l'**image mécanique du niveau attendu** par la table
   officielle. Les niveaux attendus, les tolérances, les pièges et les productions n'ont
   **pas** été touchés — la référence est la même, ré-exprimée sur la bonne échelle.
   Conséquence directe : la colonne « note dans la fourchette » **n'est pas comparable** entre
   les deux versions. Les notes de la v5 sont hors fourchette par construction, puisqu'elles
   sont sur une autre échelle. Ce sont les **niveaux** qui se comparent.
2. Le fournisseur a de nouveau **limité le débit** : 5 productions sur 48 perdues côté v5,
   2 sur 48 côté v6. Les deux lectures sont données.
3. Il a fallu **deux itérations** sur la v6 avant d'arriver à ce résultat, et elles sont
   instructives (voir sous le tableau).

| | v5 (témoin, même jour) | **v6** |
|---|---|---|
| productions mesurées | 43/48 | **46/48** |
| **accord exact** | 37/43 — **86,0 %** | 40/46 — **87,0 %** |
| **accord à un palier près** | 38/43 — 88,4 % | 46/46 — **100 %** |
| productions **A1 non atteint** correctement classées | 4/8 | **8/8** |
| productions **A1** correctement classées | **8/8** | 5/8 |
| productions **A2** correctement classées | 11/12 | 11/13 |
| productions **B1** correctement classées | 8/8 | 10/11 |
| productions **B2** correctement classées | 6/7 | **6/6** |
| **pièges évités** | 6/7 mesurés (le quasi-muet échoue) | **8/8** |
| réponses inexploitables | 0 % | 0 % |
| écart de sévérité (référence − IA) | −4,80 (non comparable, cf. avert. 1) | −0,45 |

Ce qu'il faut en retenir :

- **aucune erreur de la v6 ne sort de la zone que la référence elle-même accepte.** C'est le
  chiffre le plus parlant du tableau : 100 % d'accord à un palier près, contre 88,4 %. La v5
  produisait 5 évaluations en dehors de la tolérance annotée ; la v6, aucune ;
- **le point faible historique du banc est réparé.** « A1 non atteint » passe de 4/8 à 8/8.
  C'était la faiblesse écrite noir sur blanc au §12.5 depuis des mois : le serveur ne pose ce
  niveau que si la note vaut exactement 0, et l'IA refusait de mettre 0 à une production qui
  « disait quand même quelque chose ». Sur l'échelle du TCF il n'existe **aucun échelon entre
  0 et 1**, ce que les consignes disent désormais explicitement ;
- **les huit pièges sont évités**, y compris le quasi-muet que la v5 ratait, y compris les
  deux transcriptions bruitées et le hors-sujet à 0 ;
- **la frontière B1/B2 tient** (10/11, et 6/6 en B2) — c'était le risque principal de la
  bascule, puisque le seuil du B2 descend de 16 à 10 ;
- **le seul recul : les productions A1, 8/8 → 5/8**, les trois cas concernés ressortant A2.
  Il faut le dire précisément, parce que c'est moins grave qu'il n'y paraît : (a) la référence
  **tolère explicitement A2** sur ces trois cas ; (b) surtout, **l'IA les jugeait déjà A2 sous
  la v5** — elle notait leur langue 7/20, ce qui est la bande **A2** de l'échelle v5. Si la v5
  affichait quand même « A1 », c'est à cause du décalage entre les bandes de critère et les
  bandes globales de cette version, pas parce qu'elle jugeait mieux. La v6 n'a pas dégradé ce
  jugement : elle a cessé de le masquer.

**Les deux itérations, et ce qu'elles enseignent.** La première version de la v6 classait
correctement 8/8 des « A1 non atteint » mais laissait passer **2 faux B2** : l'IA continuait
d'écrire 13 ou 14 pour un très bon B1, par réflexe de l'ancienne échelle. Les consignes ont
donc reçu une **table de valeurs par palier** et une règle de méthode : *nommer d'abord le
palier, prendre ensuite sa valeur ; un très bon B1 se note 9, jamais 12.* Les faux B2 ont
disparu — mais la formule « tout A1 vaut 1 » a alors fait remonter à 1 des productions qui
valaient 0, **y compris le piège du hors-sujet**. Il a fallu réaffirmer le 0 avec la même
force (« le hors-sujet et le en-deçà du A1 valent 0, et ce 0 prime »). Enseignement général :
**sur une échelle resserrée, chaque borne doit être ancrée explicitement, et renforcer une
borne peut en déplacer une autre.** Seule une campagne complète le montre.

**Les seuils se règlent par rejeu hors ligne, jamais à l'intuition.** Les évaluations déjà
jouées conservent la note de chaque critère : on peut donc rejouer le passage note → niveau
avec d'autres seuils **sans un seul appel d'IA supplémentaire**. C'est ainsi qu'a été décidé,
au temps de la v4.1, le passage du seuil A2 de 7 à 8 (accord exact 71,9 % → 76,0 %,
productions A1 correctement classées 62,5 % → 87,5 %, aucune dégradation ailleurs) ; et c'est
ainsi qu'ont été choisis les seuils 16 / 13 / 9 de la v5, puis confirmés sur une campagne
indépendante.

Deux enseignements de ces rejeux, qui valent d'être écrits :

- un seuil n'est **pas** transposable d'une version de grille à l'autre. Monter le seuil B1 à
  13 était le **pire** choix possible sous la v4.2 (les A2 passaient à 100 % mais les B1
  s'effondraient à 33 %) ; c'est le **bon** choix sous la v5, parce que la note n'y mesure
  plus la même chose. C'est pour cette raison que, depuis la v5, **chaque grille déclare ses
  propres seuils dans son fichier** : revenir à la v4.2 remet automatiquement les siens ;
- **arrondir le niveau plutôt que la note dégrade la mesure** (38 → 35 classements exacts sur
  la campagne v5). C'est la note qui garde une décimale, pas le niveau qui s'arrondit.

### 12.5 Ce qui reste faible — à dire franchement

Le banc sert autant à mesurer les progrès qu'à nommer ce qui ne va pas.

- **Les trois corrections du §12.3 bis ne sont pas encore mesurées.** Limite de longueur
  relevée, message de réparation enrichi, hésitations élidées : les trois sont raisonnées et
  couvertes par des tests automatiques, mais **aucune campagne n'a encore comparé l'avant et
  l'après**. Tant que ce n'est pas fait, le taux de corrections perdues annoncé plus haut reste
  celui du diagnostic, pas celui du système corrigé. C'est exactement la dette que le §12.3 bis
  décrit — on la nomme plutôt que de la reproduire.

- **Le garde-fou de cohérence du bilan (§6.5 bis) est hors de portée de ce banc, par
  construction.** Le corpus porte un niveau attendu **par tâche** et **aucune** référence
  de niveau d'épreuve : il ne peut ni confirmer ni infirmer la règle « pas de B2 si la
  tâche 3 est sous B1 ». Elle a donc été activée sur un **raisonnement** (les trois tâches
  ne sont pas interchangeables), pas sur un chiffre — et c'est la seule règle de notation
  livrée dans ce cas. La vérifier demandera de vraies **épreuves complètes** annotées par
  des enseignants, via la console de calibration (§14) ; d'ici là, la règle reste
  réversible d'un seul réglage.

- ~~**Le niveau « A1 non atteint » n'est presque jamais atteint.**~~ **Réglé par la v6**
  (8/8 sur la campagne, contre 4/8 auparavant). La cause était bien celle décrite ici : le
  serveur ne pose « A1 non atteint » que si la note vaut **exactement 0**, et l'IA refusait de
  mettre 0 à une production qui transmettait quand même quelque chose. Sur l'échelle du TCF,
  il n'existe **aucun échelon entre 0 et 1** — le 1 est déjà le A1 — donc tout ce qui est en
  deçà du A1 vaut 0. Les consignes le disent maintenant explicitement, en précisant que ce 0
  **n'accuse pas** le candidat d'être hors-sujet : la différence se lit dans le niveau annoncé
  et dans le commentaire, pas dans le chiffre.
- **Les productions A1 ne sont plus le point faible — c'est confirmé.** Sur les campagnes
  v4.1 telles qu'elles avaient tourné (avec l'ancien seuil), environ **37 %** d'entre elles
  étaient encore mal classées, généralement annoncées A2. Une campagne complète refaite sur
  la configuration réellement livrée (rubriques v4.1 **et** seuil A2 déplacé) le confirme :
  **7 productions A1 sur 8 sont désormais correctement classées**, soit environ 12 % d'erreur.
  Le rejeu hors ligne avait vu juste.
- **La frontière A1/A2 est devenue le point faible.** 3 productions A1 sur 8 ressortent A2
  (§12.4). C'est le prix de l'échelle officielle : le palier A1 y vaut **une seule valeur, 1**,
  sans marge d'hésitation, alors que les paliers voisins en ont quatre. La moindre indulgence
  sur un critère fait changer de palier. Les trois cas concernés sont dans la zone que la
  référence tolère, et l'IA les jugeait déjà ainsi sous la v5, mais c'est là qu'il faudra
  regarder en premier à la prochaine passe — de préférence avec de vraies productions
  annotées, parce que trois cas synthétiques ne suffisent pas à trancher.
- **La frontière B1/B2 est réparée, mais pas refermée.** Elle était le point faible du
  système : 3 productions B1 sur 12 ressortaient B2, ce qui est l'erreur la plus coûteuse
  possible (la naturalisation exige B2 depuis janvier 2026). Les consignes v4.2 ramènent
  l'erreur à **1 ou 2 productions sur 12** selon les campagnes, et la v6 la maintient à ce
  niveau (10/11) malgré un seuil B2 descendu de 16 à 10 — ce qui n'allait pas de soi. Il reste **un cas qui résiste
  systématiquement** : un récit personnel très bien construit — relative, conséquence
  (« tellement… que »), comparaison hypothétique — mais au vocabulaire ordinaire et qui ne
  défend aucun point de vue. Notre référence l'a annoté B1 en le décrivant elle-même comme
  « haut de B1 touchant le B2 » : c'est un cas où deux correcteurs humains pourraient
  légitimement ne pas être d'accord. On ne le compte donc pas comme réglé, mais on ne cherche
  pas non plus à le forcer : durcir encore pour gagner ce cas-là ferait retomber de vrais B2
  en B1, ce qui découragerait à tort des candidats qui ont le niveau exigé.
- **L'IA se croit plus sûre qu'elle ne devrait.** Sur environ un tiers des cas, elle annonce
  une confiance plus élevée que celle attendue. Elle ne se trompe presque jamais dans l'autre
  sens.
- **Le repérage des oublis est perfectible.** Les points de la consigne réellement oubliés ne
  sont retrouvés que dans **un peu moins de la moitié** des cas. En revanche, la question
  « tous les points obligatoires sont-ils traités ? » reçoit la bonne réponse dans plus de
  **85 %** des cas.
- **La qualité pédagogique du feedback n'est pas mesurée.** Le banc compare des notes et des
  niveaux, rien d'autre. Que chaque priorité porte réellement un « comment » utile, que les
  exemples corrigés fassent vraiment gagner un niveau : c'est **imposé par le format de
  réponse et par les consignes**, vérifié par des tests automatiques et à la main sur de
  vraies productions — mais aucun chiffre ne le suit dans le temps. C'est le prochain
  chantier naturel du banc.
- **Le fournisseur d'IA peut changer sous nos pieds.** Deux campagnes d'une même journée ont
  tourné par erreur sur un autre modèle que celui de référence, avec un accord exact deux fois
  plus bas. La leçon est intégrée : **toute campagne comparative fixe explicitement son
  fournisseur**, et le témoin de la version précédente est rejoué le même jour.
- **Et surtout : le corpus est synthétique.** Les 48 productions ont été **écrites à la main**
  pour ce banc. Aucune ne vient d'un utilisateur réel ; aucune n'a été annotée par un
  enseignant de FLE. Les consignes, elles, sont les vraies consignes du projet. C'est une
  **base de départ honnête, pas une vérité de terrain** : un corpus écrit par ceux qui écrivent
  aussi les consignes de notation partage forcément une partie de leurs angles morts. La suite
  prévue : le remplacer et le compléter progressivement par de **vraies productions
  anonymisées, annotées par des enseignants**, avec une double annotation ciblée sur les
  frontières A2 / B1 / B2 — là où la décision compte le plus.

---

## 13. Deux réglages **préparés mais éteints** (aucun effet aujourd'hui)

Ces deux comportements sont écrits, testés et livrés, mais **désactivés**. Tant qu'ils ne
sont pas allumés, **rien de ce qui suit ne se produit** : la notation décrite dans tout le
reste de ce document reste, mot pour mot, celle qui s'applique. Ils s'allument un par un,
après mesure au banc, en changeant une seule ligne de configuration.

| Réglage | Ce qu'il ferait une fois allumé |
|---|---|
| **Débit et pauses** | Afficher, sous une production **orale**, deux mesures **factuelles** : le **débit** (mots par minute) et — seulement si la transcription porte des repères de temps — le **nombre de silences longs**. Ce sont des **informations**, jamais une note. |
| **Seconde lecture en cas de doute** | Faire **recorriger** la production par une **seconde IA**, uniquement quand la première est peu sûre d'elle (confiance faible, note juste à la frontière d'un niveau, ou désaccord marqué entre l'IA et le calcul du serveur). En cas de désaccord entre les deux, on retient la correction **la plus basse** — le biais mesuré est vers l'indulgence — et on **baisse la confiance affichée**. |

> Un troisième réglage figurait ici jusqu'à présent : la **cohérence du bilan** (pas de B2
> quand la tâche 3 est sous B1). Il est désormais **actif** — voir le §6.5 bis, qui
> explique aussi pourquoi il a été allumé **sans mesure au banc**, celui-ci n'ayant aucune
> référence de niveau d'épreuve.

Trois précisions qui comptent :

- **Le débit ne deviendrait pas un critère de note, même allumé.** C'est une mesure affichée à
  côté de la correction, avec la mention « ces mesures n'entrent pas dans votre note ni dans
  votre niveau ». Aucun calcul de note ou de niveau ne lit ce bloc. Elle a été retenue parce
  qu'elle est **neutre vis-à-vis de l'accent** : compter des mots par minute ne favorise
  aucune langue maternelle, contrairement à une analyse de prononciation. L'allumer nuancerait
  la règle « on ne juge ni le débit ni la durée » du §8 : on **mesurerait** le débit, sans le
  **noter**.
- **La seconde lecture réutilise le correcteur configuré.** Il n'existe plus de provider ou
  de modèle séparé pour cette voie : async, fin de session temps réel, seconde passe et banc
  de mesure lisent tous `sejourfr.production-evaluation`. Cette contrainte rend une bascule
  reproductible et évite qu'une voie secondaire note sur un autre modèle à l'insu du projet.
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
| **Toutes les consignes de notation** (les 4 critères du TCF et leurs poids, descripteurs et consignes par tâche, barème, ancrage du bas **et du haut** de l'échelle, garde-fou de couplage, règles obligatoires/pistes, tolérances, exemples de calibration, **et tout ce qui se lit sur une note** : seuils note → niveau, écart du garde-fou, seuils des plafonds, bornes des bandes affichées) **et toutes les consignes de restitution** (confiance, anti-répétition, levier de progression, verdict, version améliorée, plafonds d'affichage) | `backend_sejourfr/src/main/resources/prompts/production-rubrics-v8.json` (version **active**, profil `TCF_IRN`, maximum B2). `v7` et les versions antérieures restent en place et chargeables. Un rollback change la **paire compatible** `EVAL_RUBRICS_VERSION` + `EVAL_PROMPT_VERSION` (v8/v5 → v7/v4, par exemple), jamais un seul côté du contrat. |
| **Le format de réponse de l'IA** (note, confiance, accomplissement **et son verdict**, preuves, exemples corrigés, version améliorée…) | `backend_sejourfr/src/main/resources/prompts/production-evaluation-tool-schema-v5.json` (version active : structure complète, quatre critères exacts, niveaux limités à B2, aucun champ imprévu, au plus 2 points forts / 2 priorités / 3 exemples corrigés) |
| **Le correcteur utilisé partout** (async, fin de session temps réel, réparation, seconde passe, calibration) | `backend_sejourfr/src/main/resources/application.yaml`, `sejourfr.production-evaluation.provider` et le modèle du provider choisi. Défaut : DeepSeek / `deepseek-v4-flash`. Gemini reste l'examinateur vocal/transcripteur, jamais le correcteur. |
| **Le comportement de l'examinateur vocal** (ton, cadre, interdiction d'orienter le candidat, ouverture T1/T2, façon de rendre la fiche de scénario T2…) | `backend_sejourfr/src/main/resources/prompts/realtime-personas-v2.json` (version active ; la v1, sans fiche de scénario, reste disponible en repli) |
| **Les faits d'un jeu de rôle T2** (prix, délais, horaires, attitude du personnage) | colonne `agent_role_card` du sujet, en base — renseignée par les migrations `db/migration/300_tcf/production/eo/tache_2/` |
| **Les seuils de niveau, les plafonds, les vérifications automatiques, les deux réglages éteints** | `backend_sejourfr/src/main/resources/application.yaml`, section `sejourfr.production-evaluation` |
| **Le garde-fou de cohérence du bilan** (§6.5 bis — pas de B2 si la tâche 3 est sous B1) | `backend_sejourfr/src/main/resources/application.yaml`, `sejourfr.production-evaluation.coherence-bilan` — livré **actif**, contrairement aux deux réglages du §13. `EVAL_COHERENCE_BILAN_ENABLED=false` rend exactement les bilans d'avant |
| **Le recollage des phrases coupées en deux à l'oral en temps réel** (§3.1) | `backend_sejourfr/src/main/resources/application.yaml`, `sejourfr.production-evaluation.recollage-tours.enabled` — livré **actif**, contrairement aux trois réglages du §13. La règle elle-même vit à **un seul endroit**, `backend_sejourfr/src/main/java/com/sejourfr/app/util/TranscriptTurnStitcher.java`, et s'applique en un seul point de lecture, ce qui garantit que le texte cité est le texte affiché |
| **La patience / réactivité de l'examinateur vocal** (détection de fin de parole) | `backend_sejourfr/src/main/resources/application.yaml`, section `sejourfr.realtime.gemini.vad` |
| **La longueur maximale d'une réponse du correcteur** (§12.3 bis — au-delà, la réponse est coupée et la correction est perdue) | `backend_sejourfr/src/main/resources/application.yaml`, `max-tokens` des trois correcteurs de `sejourfr.production-evaluation` : **la même valeur pour les trois**, verrouillée par un test |
| **Le corpus de référence du banc de mesure** | `backend_sejourfr/src/test/resources/calibration/golden-set-v1.json` |
| **La grille officielle du TCF** (niveau → fourchette de note, §6.6) | `backend_sejourfr/src/main/java/com/sejourfr/app/enums/BandeNoteTcf.java` — dans le code et **pas** dans la configuration : c'est une donnée officielle, pas un réglage. Depuis la v6, la grille active la reprend à l'identique comme échelle de notation ; cet enum reste malgré tout la source officielle et sert à **afficher** la fourchette du niveau atteint |

> **Garde-fous automatiques** : au démarrage, l'application **refuse de démarrer** si les
> consignes de notation sont incohérentes — critère inconnu, poids qui ne font pas 100 %, tâche
> sans barème, bornes EE incorrectes, contexte T2/T3 absent, ou paire rubrique/tool-schema
> incompatible. À chaque correction, la sortie brute est refusée si un critère manque, est
> dupliqué, hors bornes, si la structure est incomplète ou si un niveau dépasse B2. Une seule
> réparation sémantique est autorisée ; après deux échecs, aucune note partielle n'est
> persistée. Et si l'IA rend une note très différente du calcul officiel, l'écart est enregistré
> pour surveillance.

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

L'IA joue un correcteur d'examen **juste, pas complaisant**. Pour chaque tâche, elle note les
**quatre critères du vrai TCF — communiquer, interagir, lexique, morphosyntaxe — à poids
égal**, annonce d'abord **si l'objectif de la tâche est atteint**, dit **ce qui a été traité et
ce qui a été oublié**, appuie chaque appréciation sur une **citation** de la production, donne
**au plus deux points forts et deux priorités, chacune avec un « comment » concret et un
exemple avant / après pris dans la copie**, rend à l'écrit **la copie entière réécrite au
palier au-dessus**, et déclare **à quel point elle est sûre d'elle** — une certitude de
correcteur, jamais un jugement déguisé sur le candidat. Un même fait de langue n'est traité
**qu'à un seul endroit** du rapport, et ce que la consigne n'exigeait pas est présenté comme un
**levier de progression**, jamais comme un manque. Le serveur, lui, calcule la note (la moyenne
des quatre),
**en déduit le niveau directement — la note et le niveau racontent la même histoire**,
applique le garde-fou de couplage et deux plafonds ciblés, tronque les listes trop longues,
abaisse un verdict qui se contredit, et n'affiche jamais un niveau sans sa confiance. Au
bilan d'une épreuve, il refuse en plus un **B2 sans argumentation** (tâche 3 sous B1), et
laisse **sans niveau** une épreuve qui n'a pas pu être passée plutôt que de la compter au
plus bas.

Elle juge avant tout la **capacité du candidat à communiquer et à se faire comprendre**, sans
le pénaliser pour une transcription imparfaite, pour une piste du sujet non traitée, ni pour
la longueur. Mais **ne pas sanctionner n'est pas créditer** : une production qui ne démontre
rien de plus que l'élémentaire reste notée comme telle, parce qu'annoncer B1 à un candidat A2
revient à lui faire payer un examen officiel qu'il va rater. La même exigence vaut en haut de
l'échelle : pour annoncer B2 — le niveau exigé pour la naturalisation, dans les quatre
épreuves et sans compensation — l'IA doit pouvoir **citer** ce qui le prouve.

**Notre note sur 20 suit l'échelle du TCF** depuis la version 6 et la v7 la limite
explicitement au profil TCF IRN : **10/20 vaut B2**, 6-9 vaut B1,
2-5 vaut A2, 1 vaut A1, 0 veut dire « rien d'exploitable ». C'est la table officielle, reprise
telle quelle — il n'y a plus deux échelles à ne pas confondre. On ne convertit toujours pas la
note pour autant : au bilan d'une épreuve, on affiche le niveau estimé **et** la fourchette
officielle de ce niveau, parce que notre note porte sur une tâche et celle du TCF sur une
épreuve entière (§6.6).

Quatre choses qu'on **ne cache pas** :

- le garde-fou « pas de B2 sans argumentation » (§6.5 bis) est allumé sur un
  **raisonnement**, pas sur une mesure : notre banc n'a aucune référence de niveau
  d'épreuve et **ne peut pas** trancher ce choix ;
- à l'oral, **on ne juge que la transcription** — la voix et la durée ne sont pas transmises
  au correcteur, et toute sortie qui note hésitations, répétitions, fluidité, débit,
  prononciation, accent, intonation ou orthographe de transcription est rejetée ;
- notre notation est **mesurée**, et la mesure dit encore ce qui cloche : sur l'échelle
  officielle, le palier A1 ne vaut qu'**une seule valeur**, et 3 productions A1 sur 8
  ressortent A2 ; un cas de frontière B1/B2 résiste toujours ;
- le corpus qui sert à cette mesure est **écrit à la main** : il doit être remplacé par de
  vraies productions annotées par des enseignants.
