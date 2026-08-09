# SejourFR — Brief Claude Code
## Diagnostic TCF rapide + Plan personnalisé + intégration acquisition

> Objectif de ce document : demander à Claude Code d'analyser le projet existant et d'intégrer le diagnostic rapide et le nouveau module **Plan** de manière cohérente avec l'architecture actuelle.
>
> **Ne pas imposer une nouvelle modélisation technique si le projet possède déjà les concepts nécessaires.**
> Claude Code doit d'abord analyser le backend, le frontend web, le mobile, les entités existantes, les services IA, le stockage R2, les routes, les composants et la navigation, puis choisir la solution la plus simple et la plus cohérente.

---

# 1. Vision produit

Faire évoluer SejourFR d'une logique :

> sujet → note → rapport

vers une logique :

> **diagnostic → priorités → entraînement ciblé → nouvelles observations → plan qui s'adapte → progression**

La promesse doit devenir très simple :

> **Découvrez en quelques minutes ce qui vous empêche d'atteindre votre niveau TCF, puis travaillez exactement vos priorités.**

Le diagnostic n'est pas un examen blanc et ne doit pas être présenté comme une combinaison officielle des tâches du TCF.

Ce sont **2 exercices diagnostic SejourFR**, volontairement conçus pour faire apparaître beaucoup de capacités en peu de temps :

- 1 production écrite ;
- 1 production orale enregistrée ;
- pas de conversation IA en temps réel pour le diagnostic initial.

Objectif :
- coût IA raisonnable ;
- très peu de friction ;
- résultat immédiatement utile ;
- création automatique d'un premier plan personnalisé.

---

# 2. Contraintes importantes

## 2.1 Réutiliser le projet existant

Avant toute modification :

1. analyser les écrans et routes actuels ;
2. analyser comment les sujets EE/EO sont stockés ;
3. analyser le pipeline de correction IA actuel ;
4. analyser le référentiel existant des compétences TCF ;
5. analyser la page / progression actuelle ;
6. analyser la navigation web + mobile ;
7. analyser la génération et le stockage des fichiers audio dans Cloudflare R2 ;
8. analyser la page `/reussir`, utilisée depuis les réseaux sociaux ;
9. analyser la gestion utilisateur / invité afin de réduire au maximum la friction depuis les réseaux sociaux.

Ne pas dupliquer une logique existante.

Ne pas créer une deuxième manière de :
- stocker les productions ;
- évaluer une production ;
- charger un audio ;
- suivre les compétences ;
- calculer la progression.

Réutiliser et étendre ce qui existe.

---

# 3. Référentiel des compétences déjà présent dans le projet

Le projet possède déjà un référentiel de compétences pour :

- EE1 ;
- EE2 ;
- EE3 ;
- EO1 ;
- EO2 ;
- EO3 ;

avec **8 compétences maximum par tâche**.

Ces compétences sont une décomposition pédagogique SejourFR des critères linguistiques, pragmatiques et sociolinguistiques du TCF.

## Règle fondamentale

Le diagnostic ne doit **pas inventer un nouveau référentiel parallèle**.

Il doit sélectionner, parmi les compétences déjà présentes dans le projet, celles que les 2 sujets diagnostic permettent réellement d'observer.

Une production diagnostic ne permet pas de valider toutes les compétences des 6 tâches.

Il faut donc distinguer :

- compétence **observée** ;
- compétence **non observée** ;
- compétence **prioritaire** ;
- compétence **à renforcer** ;
- compétence **solide**.

Ne jamais afficher :

> “Vous maîtrisez X % du TCF”

simplement parce que seulement 2 productions ont été analysées.

---

# 4. Les 2 sujets fixes du diagnostic

Ces deux sujets deviennent les **sujets de référence du diagnostic initial SejourFR**.

Ils doivent être enregistrés de manière pérenne dans le projet, en utilisant le système actuel de sujets / exercices plutôt qu'une logique spéciale codée en dur si cela est possible.

Ils doivent être identifiables comme :

- diagnostic ;
- versionnés ;
- actifs ;
- non remplaçables par le moteur aléatoire des entraînements classiques.

Le candidat retrouve toujours ces 2 exercices lorsqu'il démarre son **diagnostic initial**.

---

# 5. Sujet diagnostic — Expression écrite

## Identité fonctionnelle

**Type :** Diagnostic SejourFR — Expression écrite  
**But :** faire apparaître des compétences issues des trois familles EE : message, récit, opinion.

## Sujet

### Une nouvelle activité

> Vous avez récemment commencé une nouvelle activité près de chez vous : sport, cours de français, bénévolat, formation, association…
>
> Écrivez à un ami pour :
>
> - lui expliquer de quelle activité il s'agit et où elle se déroule ;
> - raconter comment s'est passée votre première expérience ;
> - dire ce que vous avez aimé ou moins aimé ;
> - expliquer si vous lui conseillez cette activité et pourquoi.
>
> Écrivez environ **100 à 130 mots**.

## Important

Ce format dépasse volontairement la logique d'une seule tâche officielle.

Dans l'interface, ne pas afficher :

> Tâche 1 / Tâche 2 / Tâche 3

Afficher plutôt :

> **Diagnostic écrit**

et une phrase courte du type :

> “Cet exercice nous aide à observer plusieurs compétences en une seule production.”

---

# 6. Ce que le diagnostic écrit doit chercher à observer

Claude Code doit mapper ces capacités vers les **compétences existantes les plus pertinentes** du référentiel actuel.

Ne pas créer automatiquement de nouveaux skill IDs si les compétences existent déjà.

Les familles prioritaires à observer sont :

1. **Accomplissement de la consigne**
   - les 4 éléments demandés sont-ils réellement traités ?

2. **Adaptation au destinataire**
   - le candidat écrit-il naturellement à un ami ?
   - ton, entrée et fin du message cohérents ?

3. **Mise en place du récit**
   - activité, lieu, contexte suffisamment compréhensibles ?

4. **Chronologie et enchaînement**
   - l'expérience est-elle racontée dans un ordre compréhensible ?
   - liens temporels utiles ?

5. **Temps et cohérence grammaticale du récit**
   - stabilité minimale des temps ;
   - erreurs récurrentes qui affectent la clarté.

6. **Développement / détails utiles**
   - le candidat ne se contente pas d'une liste de faits ;
   - il précise ce qu'il s'est passé et son ressenti.

7. **Opinion claire**
   - recommande / ne recommande pas ;
   - position identifiable.

8. **Argumentation**
   - raison expliquée ;
   - idéalement exemple, conséquence ou justification concrète.

Le lexique, la morphosyntaxe et la cohérence doivent aussi être pris en compte par le moteur de niveau global, mais le plan ne doit pas créer 15 priorités simultanées.

---

# 7. Sujet diagnostic — Expression orale

## Principe

Le diagnostic oral initial est un **enregistrement**, pas une conversation IA temps réel.

Cela permet :
- de réduire le coût ;
- d'éviter une expérience trop intimidante dès la première utilisation ;
- de garder la simulation IA en direct comme fonctionnalité forte d'entraînement / Premium ;
- d'obtenir tout de même suffisamment d'informations pour un premier diagnostic.

## Sujet

### Trouver une activité dans une nouvelle ville

> Vous venez d'arriver dans une nouvelle ville et vous souhaitez participer à une activité pour rencontrer des personnes et améliorer votre français.
>
> Dans votre réponse :
>
> 1. présentez-vous brièvement et expliquez ce que vous recherchez ;
> 2. imaginez que vous parlez à une personne qui travaille dans une maison de quartier : posez plusieurs questions utiles pour obtenir des informations sur les activités proposées ;
> 3. expliquez quelle activité vous choisiriez et pourquoi ;
> 4. terminez en donnant votre opinion : selon vous, est-il préférable d'apprendre le français dans une activité en groupe ou seul sur Internet ? Expliquez pourquoi.
>
> Parlez naturellement pendant environ **2 à 3 minutes**.

## Interface

Afficher :
- la consigne ;
- un bouton de lecture audio ;
- l'enregistreur existant ;
- la durée ;
- le bouton de validation.

Le candidat peut lire la consigne et/ou écouter l'audio.

---

# 8. Limites assumées du diagnostic oral

Ce sujet permet d'observer la **formulation de questions**, mais ce n'est pas une vraie interaction.

Donc le moteur ne doit pas prétendre avoir évalué :

- la capacité à rebondir sur une réponse imprévue ;
- la capacité à reformuler après incompréhension ;
- la gestion réelle d'un échange en direct ;
- la réaction à une relance.

Ces compétences restent **non observées** tant qu'elles n'ont pas été vues dans :
- une simulation orale IA ;
- un entraînement interactif ;
- une autre production adaptée.

C'est important pour éviter un diagnostic artificiellement trop confiant.

---

# 9. Ce que le diagnostic oral doit chercher à observer

Mapper ces capacités aux compétences EO existantes les plus proches.

Familles prioritaires :

1. **Présentation et réponse pertinente**
   - comprend-on rapidement qui est le candidat et ce qu'il cherche ?

2. **Développement**
   - réponses suffisamment développées ;
   - détails utiles.

3. **Lexique fonctionnel**
   - vocabulaire du quotidien adapté à la situation.

4. **Formulation de questions**
   - plusieurs vraies questions ;
   - formes compréhensibles ;
   - questions réellement utiles.

5. **Couverture des informations**
   - horaires, prix, inscription, niveau, lieu, conditions, etc.
   - ne pas exiger une liste fixe si la production reste fonctionnelle.

6. **Position claire**
   - choix d'une activité ;
   - opinion groupe vs Internet.

7. **Développement et structuration de l'opinion**
   - raison ;
   - explication ;
   - exemple ou conséquence lorsque disponible.

8. **Grammaire orale / fluidité / intelligibilité**
   - utiliser uniquement ce que le pipeline technique permet réellement d'observer.

### Règle anti-hallucination

Si le LLM ne reçoit qu'une transcription :
- il peut analyser grammaire, lexique, cohérence et contenu ;
- il ne doit pas inventer une analyse fine de la prononciation ;
- il ne doit pas affirmer mesurer précisément le débit ou les hésitations si ces données ne sont pas disponibles.

Si le projet possède déjà des informations audio fiables permettant une mesure supplémentaire, les utiliser avec prudence.

---

# 10. Audio du sujet oral et Cloudflare R2

Le sujet oral diagnostic doit posséder un **audio fixe** qui lit la consigne.

Claude Code doit :

1. identifier comment les audios de questions existants sont générés ;
2. réutiliser le même fournisseur / pipeline lorsque c'est pertinent ;
3. générer une seule fois l'audio du sujet diagnostic EO ;
4. l'uploader dans le bucket Cloudflare R2 déjà utilisé par SejourFR ;
5. enregistrer l'URL / clé R2 avec le sujet en utilisant le mécanisme existant ;
6. rendre la génération **idempotente** :
   - ne pas regénérer l'audio à chaque lancement ;
   - ne pas créer plusieurs copies à chaque migration / seed ;
7. permettre la lecture de cet audio sur web et mobile.

Ne jamais générer l'audio au runtime pour chaque candidat.

### Contenu audio

Le texte lu doit correspondre exactement à la consigne visible.

La voix doit rester :
- claire ;
- neutre ;
- naturelle ;
- proche de ce qui existe déjà dans les questions audio du projet.

---

# 11. Parcours du diagnostic

## Étape 0 — Entrée

Le diagnostic peut être lancé depuis :

- l'accueil après connexion ;
- le menu **Plan** ;
- la page `/reussir` venant des réseaux sociaux ;
- éventuellement une URL dédiée partageable.

## Étape 1 — Présentation

Écran très simple :

### Découvrez vos priorités TCF

**2 exercices · environ 8 à 10 min**

- 1 écrit ;
- 1 oral enregistré ;
- analyse personnalisée.

CTA :

**Commencer mon diagnostic gratuit**

Mention discrète :

> “Estimation d'entraînement, non officielle.”

## Étape 2 — Écrit

Sujet fixe.

## Étape 3 — Oral

Sujet fixe + audio de consigne.

## Étape 4 — Analyse

Analyser les 2 productions.

## Étape 5 — Résultat

Afficher :
- niveau de production estimé écrit ;
- niveau de production estimé oral ;
- éventuellement synthèse globale prudente ;
- 3 points solides maximum ;
- 3 priorités maximum ;
- exemple(s) provenant des productions ;
- CTA principal : **Voir mon plan**.

Ne pas afficher une grille massive de critères dès le premier écran.

Lien secondaire :

**Voir le diagnostic complet**

---

# 12. Première connexion — web et mobile

Lorsqu'un candidat connecté n'a jamais terminé son diagnostic :

sur l'accueil, afficher en haut une carte très visible mais non agressive.

### Exemple

**Découvrez ce qui vous bloque au TCF**

2 exercices · ≈ 8 min

> “On analyse votre écrit et votre oral pour construire votre premier plan.”

CTA :

**Faire mon diagnostic**

Secondaire :

**Plus tard**

## États

### Aucun diagnostic commencé
`Faire mon diagnostic`

### Diagnostic commencé mais incomplet
`Reprendre mon diagnostic`

Afficher :
> 1 / 2 terminé

### Diagnostic terminé
Ne plus afficher l'invitation générique.

À la place, l'accueil peut montrer :
> **Votre priorité du jour**
> Développer un argument · 6 min

CTA :
**Continuer mon plan**

## Ne pas bloquer l'application

Le diagnostic est fortement recommandé, mais l'utilisateur doit pouvoir accéder au reste de l'application.

---

# 13. Page `/reussir` — lien venant des réseaux sociaux

La page actuelle est une landing page très orientée :
- test gratuit ;
- simulation orale IA ;
- examen complet ;
- stores.

Elle doit maintenant devenir un point d'entrée majeur vers le **diagnostic gratuit**.

Ne pas supprimer les autres arguments commerciaux, mais changer la hiérarchie.

---

# 14. Nouveau message principal de `/reussir`

## Hero

Remplacer la promesse générique de test par quelque chose de plus personnel.

### Titre recommandé

> **Tu prépares le TCF ? Découvre d'abord ce qui te bloque.**

### Sous-titre

> Fais 1 exercice écrit et 1 oral. SejourFR analyse tes réponses, estime ton niveau de production et te montre les compétences à travailler en priorité.

### CTA principal

**Faire mon diagnostic gratuit**

### Réassurance

- 2 exercices ;
- ≈ 8 à 10 min ;
- sans carte bancaire.

Concernant “sans inscription”, Claude Code doit regarder le fonctionnement réel du mode invité.

- Si le diagnostic peut réellement commencer sans compte : conserver cet avantage.
- Sinon : ne pas promettre “sans inscription”.
- Si l'authentification est nécessaire, conserver l'URL de retour afin que le candidat arrive directement au diagnostic après connexion.

---

# 15. Visuel principal de `/reussir`

Le visuel actuel met fortement en avant une **simulation orale IA en direct**.

Le remplacer dans le premier écran par une visualisation du diagnostic :

Exemple :

**Votre diagnostic**
- Expression écrite : B1
- Expression orale : B1
- Objectif : B2

**Vos priorités**
1. Développer un argument
2. Structurer votre prise de parole
3. Stabiliser les temps du récit

CTA :
**Voir mon plan**

La simulation IA en direct reste dans une section suivante comme bénéfice Premium / entraînement avancé.

Ainsi :

1. acquisition = diagnostic gratuit ;
2. valeur immédiate = découverte des faiblesses ;
3. rétention = plan personnalisé ;
4. différenciation Premium = simulations IA et corrections illimitées.

---

# 16. Corriger les incohérences de `/reussir`

La landing actuelle contient une promesse type :

> “Tester gratuitement”

et une réassurance très courte du type :

> “2 minutes”

Le diagnostic ne dure pas 2 minutes.

Lorsqu'un CTA dirige vers le diagnostic, afficher une durée réaliste :

> **≈ 8 à 10 min**

Ne pas laisser une promesse “2 minutes” à côté d'un CTA diagnostic.

Mettre également à jour :
- title / metadata si utile ;
- description Open Graph ;
- description Twitter ;
- sticky CTA mobile ;
- CTA final de page.

CTA principal cohérent partout :

> **Faire mon diagnostic gratuit**

Les autres liens :
- examens blancs ;
- entraînement ;
- application mobile ;
- blog ;
- TikTok ;
- FAQ ;

restent accessibles.

---

# 17. Navigation principale — remplacer “Progression” par “Plan”

Dans la navigation principale web et mobile :

**Progression** devient :

> **Plan**

Ne pas perdre l'écran de progression actuel.

## Dans le nouvel écran Plan

Ajouter un accès secondaire visible :

**Voir ma progression**

Ce bouton doit ouvrir / afficher l'expérience actuelle de progression en réutilisant au maximum le composant et la logique déjà en place.

Éviter de créer un doublon du dashboard de progression.

---

# 18. Rôle du menu Plan

Le menu **Plan** devient la page à ouvrir lorsqu'un candidat se demande :

> “Qu'est-ce que je dois travailler maintenant ?”

Il ne doit pas être un dashboard rempli de chiffres.

Ordre recommandé :

1. objectif ;
2. priorité immédiate ;
3. séance recommandée ;
4. autres priorités ;
5. compétences observées ;
6. prochaine réévaluation ;
7. accès à la progression détaillée.

---

# 19. Plan — état avant diagnostic

Si aucun diagnostic n'existe :

### Mon plan

> **Construisons votre plan personnalisé**

“Faites 1 exercice écrit et 1 oral pour identifier vos premières priorités.”

CTA principal :

**Faire mon diagnostic**

Sous le CTA, on peut afficher les entraînements classiques, mais le diagnostic doit rester l'action recommandée.

---

# 20. Plan — état après diagnostic

## En-tête

Exemple :

**Objectif : B2**

> 3 priorités détectées · environ 20 min cette semaine

Ne pas utiliser de faux score de progression vers le niveau cible.

## Bloc 1 — À travailler maintenant

Une seule priorité principale.

Exemple :

### Développer un argument

> “Vous donnez une raison correcte, mais vous l'expliquez encore trop peu.”

**2 exercices · 6 min**

CTA :

**Commencer**

## Bloc 2 — Ensuite

2 ou 3 priorités maximum.

Exemple :
- Structurer une réponse orale ;
- Raconter les actions dans l'ordre ;
- Stabiliser les temps du passé.

## Bloc 3 — Mes compétences

Afficher uniquement :
- prioritaires ;
- à renforcer ;
- solides récemment observées.

Lien :

**Voir toutes mes compétences observées**

Ne pas afficher les 48 compétences d'un coup.

## Bloc 4 — Réévaluation

Exemple :

> **Prochaine vérification**
> Après quelques entraînements, une nouvelle production permettra de vérifier si cette faiblesse est réellement corrigée.

## Bloc 5 — Progression

Bouton / carte :

> **Voir ma progression**

Ouvre l'écran actuellement utilisé par le menu Progression.

---

# 21. Comment le plan se construit

Le plan ne doit pas être une liste statique créée une seule fois après le diagnostic.

Il doit être **vivant**.

Chaque nouvelle activité pertinente peut apporter une observation :

- diagnostic EE ;
- diagnostic EO ;
- sujet complet EE ;
- sujet complet EO ;
- micro-entraînement par compétence ;
- simulation orale ;
- examen blanc ;
- plus tard : CO ;
- plus tard : CE.

Ces observations servent à mettre à jour les priorités.

---

# 22. Priorisation des compétences

Le moteur doit éviter de recommander 8 choses à la fois.

Après le diagnostic :

- maximum **3 priorités actives** ;
- 1 priorité principale ;
- 2 secondaires.

Pour choisir les priorités, tenir compte notamment de :

1. écart avec le niveau cible ;
2. impact de la faiblesse sur la réalisation de la tâche ;
3. récurrence de la faiblesse ;
4. présence dans plusieurs productions ;
5. capacité à entraîner concrètement cette compétence dans l'application ;
6. confiance dans l'observation.

Une petite faute isolée ne doit jamais passer devant un problème comme :
- réponse trop courte ;
- consigne incomplète ;
- récit incompréhensible ;
- absence d'argument ;
- questions non pertinentes.

---

# 23. Comment suivre l'avancement du candidat

Ne pas résumer la progression par un seul pourcentage “vers B2”.

Afficher plusieurs signaux simples.

## A. Activité du plan

Exemple :

> **3 / 5 exercices recommandés réalisés cette semaine**

Cela mesure ce que le candidat a réellement fait.

## B. État des priorités

Chaque compétence observée peut être :

- **À évaluer**
- **Priorité**
- **À renforcer**
- **Solide**

## C. Évolution par rapport au diagnostic initial

Le diagnostic crée une **baseline**.

Pour une compétence prioritaire, conserver la logique :

> diagnostic initial → entraînements → nouvelle production → nouvelle observation

Exemple :

**Développer un argument**
- Diagnostic : Priorité
- Exercice ciblé 1 : À renforcer
- Exercice ciblé 2 : réussi
- Nouvelle production EE3 : Solide

C'est cette dernière étape qui prouve réellement le progrès.

---

# 24. Ne pas valider une compétence sur une seule bonne réponse

Règle recommandée :

Une réussite dans un micro-exercice peut montrer :

> “Réussi sur cet exercice”

mais ne transforme pas automatiquement la compétence globale en **Solide**.

Pour passer en **Solide**, demander une confirmation dans une autre production suffisamment indépendante.

Exemple :

1. exercice ciblé réussi ;
2. puis nouveau sujet EE/EO où la compétence réapparaît correctement.

Cela évite de donner une impression de maîtrise artificielle.

Claude Code doit réutiliser autant que possible la logique actuelle de progression et d'historique.

---

# 25. Réévaluation

Le candidat ne doit pas refaire les 2 mêmes sujets diagnostic chaque semaine.

Les 2 sujets fixes servent surtout de **diagnostic initial commun**.

Ensuite, le plan peut confirmer les progrès à partir :
- de nouveaux sujets complets ;
- de micro-exercices ;
- de simulations ;
- d'examens blancs.

Le bouton :

**Refaire mon diagnostic**

peut rester disponible plus tard dans un écran secondaire si souhaité, mais ne doit pas être la boucle principale.

Cela limite l'effet de mémorisation.

---

# 26. Intégration future de CO et CE dans le Plan

La Compréhension orale et la Compréhension écrite **ne font pas partie du diagnostic rapide initial**.

Cependant, le Plan doit être conçu pour pouvoir recevoir leurs observations plus tard.

Ne pas coder le Plan comme :

> `plan = uniquement compétences EE + EO`

Il doit pouvoir intégrer d'autres familles de compétences.

---

# 27. Exemples futurs — Compréhension orale

Si les questions actuelles possèdent ou peuvent recevoir des métadonnées pédagogiques, les erreurs répétées peuvent faire apparaître des priorités comme :

- repérer une information explicite ;
- comprendre l'intention du locuteur ;
- identifier l'idée principale ;
- comprendre une information implicite ;
- distinguer des informations proches / distracteurs ;
- suivre des détails utiles dans un message plus long.

Exemple :

Un candidat échoue régulièrement sur des questions B1/B2 dont la réponse demande une inférence.

Le Plan peut afficher :

### Comprendre l'implicite à l'oral

> “Vous trouvez les informations directes, mais les questions où la réponse n'est pas dite mot pour mot vous posent plus de difficultés.”

CTA :
**Faire 5 questions ciblées**

---

# 28. Exemples futurs — Compréhension écrite

Même logique possible :

- idée principale ;
- information précise ;
- intention de l'auteur ;
- implicite / inférence ;
- vocabulaire en contexte ;
- liens entre les phrases ;
- distinction entre informations proches.

Ne pas implémenter un scoring artificiel maintenant si les questions n'ont pas encore les métadonnées nécessaires.

Préparer simplement le Plan pour pouvoir consommer ces signaux plus tard.

---

# 29. Analyse LLM du diagnostic

Le LLM ne doit pas produire un commentaire libre puis laisser le backend essayer de comprendre le texte.

Utiliser le contrat structuré déjà existant dans le projet.

Si nécessaire, l'étendre **le moins possible**.

Le moteur doit recevoir :
- le sujet ;
- la production ;
- le type diagnostic ;
- l'objectif CECRL du candidat si disponible ;
- la liste des compétences existantes autorisées à observer avec ce sujet ;
- les règles d'évaluation ;
- éventuellement la transcription et les données audio réellement disponibles.

---

# 30. Ordre d'analyse obligatoire pour le LLM

## Étape 1 — Accomplissement

Avant la grammaire :

> Le candidat a-t-il réellement fait ce qui était demandé ?

## Étape 2 — Communication

> La production est-elle compréhensible et exploitable dans la situation ?

## Étape 3 — Compétences observables

Pour chaque compétence autorisée :
- observée ou non observée ;
- réussite ;
- fragilité ;
- preuve issue de la production.

## Étape 4 — Niveau

Estimer prudemment un niveau de production.

Ne pas faire dépendre le niveau d'une simple moyenne mathématique des compétences.

## Étape 5 — Priorités

Sélectionner maximum :
- 3 priorités globales après les 2 productions ;
- 2 ou 3 faiblesses importantes par production.

## Étape 6 — Action

Chaque priorité doit être reliée à :
- une compétence existante ;
- un entraînement réellement disponible ou générable dans SejourFR.

---

# 31. Ce que le LLM doit retourner conceptuellement

Claude Code doit adapter ce besoin au JSON / DTO actuel du projet.

Ne pas créer ce schéma mot pour mot si une structure équivalente existe déjà.

Il faut néanmoins pouvoir retrouver :

## Production
- niveau estimé ;
- tâche accomplie ou partiellement accomplie ;
- résumé très court ;
- points forts ;
- faiblesses principales.

## Par compétence réellement observée
- référence vers la compétence du catalogue ;
- statut / verdict ;
- preuve ou extrait réel ;
- explication courte ;
- niveau de confiance raisonnable ;
- caractère prioritaire ou non.

## Synthèse diagnostic
- niveau écrit ;
- niveau oral ;
- 3 forces maximum ;
- 3 priorités maximum ;
- explication de la priorité principale ;
- prochaine action recommandée.

---

# 32. Règles de qualité du feedback IA

1. La réalisation de la tâche passe avant la perfection grammaticale.
2. Ne pas noter comme une dissertation scolaire.
3. Une erreur isolée ne doit pas devenir une priorité.
4. Prioriser les erreurs récurrentes ou communicativement importantes.
5. Ne pas répéter la même faiblesse sous 3 noms différents.
6. Utiliser des extraits exacts de la production.
7. Montrer une reformulation courte lorsque cela apporte quelque chose.
8. Le feedback doit être atteignable au niveau cible.
9. Ne pas exiger du vocabulaire artificiellement complexe.
10. Ne pas exiger du subjonctif pour “faire B2”.
11. Ne jamais prétendre à une précision phonétique que le système ne mesure pas.
12. Une compétence non observable doit être marquée non observée plutôt que devinée.

---

# 33. Diagnostic complet — UX

L'écran principal du résultat doit rester très léger.

## Premier écran

### Votre diagnostic TCF

**Expression écrite : B1**  
**Expression orale : B1**  
**Objectif : B2**

> Estimation d'entraînement, non officielle.

### Vos points solides
3 maximum.

### Vos priorités
3 maximum.

### À travailler maintenant
1 compétence + durée.

CTA :

**Commencer mon plan**

Lien :

**Voir le diagnostic complet**

## Détail

Le diagnostic complet peut afficher :
- compétences observées ;
- preuve ;
- statut ;
- production source.

Ne pas afficher les compétences non observées comme si elles étaient mauvaises.

---

# 34. Plan — expérience Premium sans bloquer la valeur gratuite

Le diagnostic gratuit doit déjà donner une vraie valeur.

L'utilisateur doit comprendre :
- où il en est ;
- ce qui le bloque ;
- quoi faire ensuite.

Ensuite Premium peut débloquer davantage de :
- micro-entraînements ;
- correction IA ;
- simulations orales en direct ;
- historique ;
- plan complet ;
- réévaluations ;
- examens blancs.

Éviter :

> diagnostic gratuit = écran vide + paywall immédiat.

Le diagnostic doit convaincre par sa pertinence.

---

# 35. Funnel recommandé

Depuis TikTok / Instagram / réseaux :

`/reussir`
→ **Faire mon diagnostic gratuit**
→ écrit
→ oral enregistré
→ résultat personnalisé
→ **Voir mon plan**
→ premier exercice recommandé
→ découverte des fonctions avancées
→ Premium.

C'est ce flux qui doit guider la hiérarchie des CTA.

---

# 36. Reprise d'un diagnostic interrompu

Le diagnostic doit supporter :
- écrit terminé / oral non terminé ;
- fermeture de l'application ;
- changement web ↔ mobile si l'utilisateur est connecté ;
- reprise à l'étape correcte.

Ne pas demander de refaire une production déjà enregistrée simplement parce que le candidat a quitté l'écran.

Utiliser les mécanismes de persistance existants.

---

# 37. Diagnostic déjà effectué

Si un diagnostic existe :

dans Plan :

> **Diagnostic réalisé le …**
> Voir le diagnostic

Ne pas relancer systématiquement le candidat.

Sur l'accueil :
- montrer sa priorité ;
- non le banner “faites votre diagnostic”.

Sur `/reussir`, si l'utilisateur est déjà authentifié et diagnostiqué, Claude Code peut adapter le CTA vers :

> **Voir mon plan**

si l'architecture actuelle permet facilement cette personnalisation.

---

# 38. Instrumentation utile

Si le projet possède déjà analytics / événements, suivre au minimum :

- diagnostic_viewed ;
- diagnostic_started ;
- diagnostic_written_completed ;
- diagnostic_oral_completed ;
- diagnostic_completed ;
- diagnostic_result_viewed ;
- plan_opened ;
- plan_recommended_exercise_started ;
- social_landing_diagnostic_clicked ;
- diagnostic_to_premium_clicked.

Ne pas ajouter un nouveau fournisseur analytics uniquement pour cela.

Réutiliser l'existant.

---

# 39. Migration du menu Progression

Objectif :

### Avant
Accueil | Entraînement | … | Progression

### Après
Accueil | Entraînement | … | **Plan**

Dans Plan :

**Voir ma progression**

L'écran actuel de progression doit rester fonctionnel.

Réutiliser :
- historique ;
- statistiques ;
- streaks ;
- évolution de scores ;
- tout ce qui est pertinent actuellement.

Plan = **quoi faire maintenant**.  
Progression = **ce que j'ai déjà fait et comment j'évolue**.

Les deux notions doivent être séparées sans créer deux entrées principales de navigation.

---

# 40. Direction UI

L'application doit rester :
- très propre ;
- premium ;
- peu verbeuse ;
- actionnable ;
- mobile-first ;
- cohérente avec le design actuel.

Éviter :
- 12 jauges sur un écran ;
- listes de 48 compétences ;
- pourcentages pseudo-scientifiques ;
- gamification enfantine ;
- longues explications ;
- notation anxiogène.

L'utilisateur doit comprendre en quelques secondes :

1. **où j'en suis** ;
2. **ce qui me bloque** ;
3. **ce que je fais maintenant**.

---

# 41. Ce que Claude Code ne doit pas faire

- ne pas réécrire toute l'architecture ;
- ne pas imposer les tables / classes décrites dans un prototype externe ;
- ne pas créer un référentiel de compétences parallèle ;
- ne pas dupliquer Progression ;
- ne pas coder en dur les résultats du diagnostic ;
- ne pas regénérer l'audio EO à chaque candidat ;
- ne pas lancer une conversation temps réel pendant le diagnostic ;
- ne pas faire de CO / CE dans le diagnostic initial ;
- ne pas prétendre avoir évalué une compétence absente de la production ;
- ne pas transformer Plan en page de statistiques ;
- ne pas afficher un “niveau officiel TCF”.

---

# 42. Ordre d'implémentation recommandé

Claude Code doit commencer par auditer le projet puis adapter cet ordre si nécessaire.

## Phase 1 — Audit
- routes ;
- navigation ;
- sujets ;
- compétences ;
- IA ;
- R2 ;
- progression ;
- auth ;
- page `/reussir`.

## Phase 2 — Sujets diagnostic
- enregistrer les 2 sujets ;
- identifier leurs compétences observables ;
- générer + uploader l'audio EO ;
- rendre le seed idempotent.

## Phase 3 — Parcours diagnostic
- lancement ;
- reprise ;
- écrit ;
- oral ;
- analyse ;
- résultat.

## Phase 4 — Plan
- remplacement du menu Progression ;
- état sans diagnostic ;
- état après diagnostic ;
- priorités ;
- séances recommandées ;
- accès à l'ancienne progression.

## Phase 5 — Accueil
- invitation première connexion ;
- reprise ;
- priorité du jour après diagnostic.

## Phase 6 — `/reussir`
- nouveau hero ;
- nouveau CTA diagnostic ;
- visuel diagnostic ;
- métadonnées ;
- sticky CTA ;
- conservation des arguments Premium existants.

## Phase 7 — Vérification
- web desktop ;
- web mobile ;
- application mobile ;
- utilisateur anonyme si supporté ;
- utilisateur connecté ;
- diagnostic interrompu ;
- diagnostic terminé ;
- audio R2 ;
- réponse IA valide ;
- plan sans données ;
- plan avec données.

---

# 43. Critères d'acceptation

L'intégration est considérée comme terminée lorsque :

- [ ] les 2 sujets diagnostic fixes existent dans le système de contenu ;
- [ ] le sujet écrit correspond au brief ;
- [ ] le sujet oral correspond au brief ;
- [ ] l'audio du sujet oral est généré une seule fois et disponible dans R2 ;
- [ ] web et mobile peuvent lire cet audio ;
- [ ] le diagnostic utilise un enregistrement oral et non une conversation temps réel ;
- [ ] le diagnostic peut être repris s'il est interrompu ;
- [ ] seules les compétences réellement observables sont évaluées ;
- [ ] l'analyse réutilise les compétences TCF déjà présentes ;
- [ ] le LLM retourne une réponse structurée exploitable ;
- [ ] maximum 3 priorités sont proposées ;
- [ ] le résultat donne une action immédiate ;
- [ ] le menu Progression est remplacé par Plan ;
- [ ] Plan contient un accès à l'actuelle Progression ;
- [ ] Plan fonctionne avant et après diagnostic ;
- [ ] Plan est alimenté par les nouvelles productions ;
- [ ] une compétence n'est pas déclarée solide sur une seule réussite ciblée ;
- [ ] l'accueil web propose le diagnostic au premier usage ;
- [ ] l'accueil mobile propose le même parcours ;
- [ ] `/reussir` pousse clairement vers le diagnostic gratuit ;
- [ ] les CTA et durées de `/reussir` sont cohérents ;
- [ ] les simulations IA en direct restent mises en valeur plus bas comme fonction avancée ;
- [ ] la structure du Plan pourra recevoir plus tard des signaux CO / CE ;
- [ ] aucune fausse précision CECRL ou phonétique n'est affichée ;
- [ ] le design reste cohérent avec SejourFR.

---

# 44. Résultat produit recherché

À la fin, un nouvel utilisateur doit vivre ce parcours :

> “Je viens d'arriver sur SejourFR.”

→ **On me propose de découvrir mes faiblesses.**

> “Je fais un écrit et j'enregistre un oral.”

→ **SejourFR m'explique que mon niveau de production semble B1 et que 3 compétences me freinent.**

> “Je ne reçois pas 40 remarques.”

→ **On me montre UNE chose à faire maintenant.**

> “Je fais les exercices recommandés.”

→ **Le Plan évolue selon mes nouvelles productions.**

> “Je veux voir tout ce que j'ai déjà fait.”

→ **Je clique sur Voir ma progression.**

À terme :

> “Je fais aussi des questions CO et CE.”

→ **Le Plan comprend que je bloque par exemple sur l'implicite et ajoute ce besoin à mes priorités.**

Le produit ne doit plus seulement dire :

> **“Voici votre score.”**

Il doit surtout répondre à :

> **“Voici ce qui vous bloque, et voici exactement ce que vous devez faire maintenant.”**
