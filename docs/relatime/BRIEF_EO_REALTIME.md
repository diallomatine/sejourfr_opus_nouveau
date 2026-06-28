# Brief — Expression Orale en temps réel (Tâches 1 & 2)

> **À destination de Claude Code.**
> Ce document décrit une **intention produit** et un **cadre de contraintes**, pas un plan d'implémentation.
> Le projet a évolué : **ne présume rien de l'état du code**. Ta première tâche est un **audit**, puis une **proposition d'architecture** soumise à validation humaine **avant tout code**.
> Tu travailles sur **web** (frontend) **et mobile** (Flutter). Les deux sont concernés.

---

## 0. Mode opératoire imposé

Ne génère **aucun code** tant que les étapes 1 et 2 ne sont pas validées par moi.

1. **AUDIT** — Explore le dépôt et établis un état des lieux écrit (cf. §7).
2. **PROPOSITION** — Rédige une note d'architecture avec **options chiffrées** sur les points ouverts (cf. §6), et **une recommandation argumentée**. **HARD STOP** : j'arbitre.
3. **IMPLÉMENTATION** — Par lots, avec un hard stop à chaque jalon de §8.

Garde-fous : pas de README auto, pas d'images de rendu, pas de réécriture de pans existants « pour faire propre ». Tu signales tout ce que tu comptes modifier **avant** de le faire.

---

## 1. Objectif

Ajouter un **mode conversationnel temps réel** pour les **Tâches 1 et 2** de l'Expression Orale (EO), où un **agent vocal joue l'examinateur**. Le candidat parle, l'agent répond, et **le dialogue complet est noté après coup** par le pipeline d'évaluation existant.

Premier fournisseur : **Google Gemini Live (audio natif)**. Mais l'architecture doit permettre un **basculement rapide de fournisseur** (OpenAI Realtime, Qwen Realtime…) **sans refonte** — voir §5.

**Ce mode s'ajoute. Il ne remplace rien.** Tout le fonctionnement actuel (entraînement, examens blancs, civique, pipeline async STT, notation) reste en place.

---

## 2. Périmètre fonctionnel

### 2.1 Ce qui est temps réel vs async
- **Tâche 1** (entretien dirigé) et **Tâche 2** (interaction) → **éligibles au temps réel**.
- **Tâche 3** (point de vue) → **reste async** (pipeline STT existant). Ne pas y toucher.

### 2.2 Sessions temps réel limitées par pass
- Chaque pass donne un **quota de sessions temps réel** (1 session = 1 passage de T1 **ou** T2 en mode agent).
- Valeurs **provisoires, non confirmées, à rendre configurables** (pas en dur) :
  - Sprint ≈ **25**, Trimestre ≈ **60**, Annuel ≈ **120**.
- Le quota est **rattaché au pass / à la durée** de l'abonnement. **Audite le modèle Plan/UserSubscription réel** avant de décider où il vit.
- **Décompte en temps réel** affiché à l'utilisateur.
- **Quota épuisé → bascule automatique et silencieuse vers l'async** (le candidat n'est jamais bloqué).

### 2.3 Choix au lancement (T1/T2)
Avant de démarrer une T1 ou une T2 (en module EO seul **ou** dans un examen blanc), afficher un **petit modal** :
- nombre de **sessions temps réel restantes** ;
- choix **« Passer en temps réel avec un examinateur »** vs **« Le faire en mode classique (enregistrement) »** ;
- si quota = 0 → option temps réel désactivée, message clair, démarrage async direct.

### 2.4 Examens blancs
Deux niveaux d'intégration. Le modal de §2.3 s'applique **dans les deux cas** pour T1/T2.
- **Module EO seul** : enchaînement T1 → T2 → T3, chacune avec son mode.
- **Examen blanc complet (IRN)** : aujourd'hui l'examen blanc ne tire que **CO + CE** (cf. référentiel : EO/EE non-QCM). Il faut **intégrer une section EO** (les 3 tâches) dans le parcours complet, T1/T2 avec choix temps réel/async, T3 async, puis **agréger** le résultat productif (EO, et EE si déjà géré) avec les scores QCM dans le bilan IRN.
- Cette intégration complète peut être **lourde** : tu as le droit de **proposer un phasage** (EO autonome d'abord, intégration examen complet ensuite). Justifie.

---

## 3. Référence TCF IRN — Expression Orale (faits vérifiés, source France Éducation international)

À respecter pour que la simulation soit **fidèle au réel**. ⚠️ Ne pas confondre avec le TCF Canada/Québec (durées et préparation différentes).

- **Format IRN** : épreuve individuelle en face à face, **~10 min, 3 tâches, SANS préparation**, entièrement enregistrée.
- **Tâche 1 — Entretien dirigé (3 min)** : le candidat se présente et parle de lui (parcours, situation, projets). L'examinateur **relance seulement si nécessaire**, sinon il écoute.
- **Tâche 2 — Interaction (3 min 30)** : le candidat doit **obtenir des informations** dans une situation courante. Les **statuts** (rôle de l'examinateur, rôle du candidat) sont **précisés dans la consigne**. **C'est le candidat qui mène** et pose les questions ; l'examinateur **joue le rôle** indiqué et répond. (Ex. de consignes réelles : « Je suis un conseiller en voyages, vous planifiez vos vacances… » / « Je suis un organisateur d'événements, vous préparez une fête… ».)
- **Tâche 3 — Point de vue (3 min 30)** : production quasi-monologue sur une question choisie. → **async**.
- L'épreuve est **évaluée en double aveugle** sur des critères **linguistiques** (étendue/maîtrise du lexique, correction grammaticale, aisance, prononciation), **pragmatiques** (interaction, structuration, cohérence/cohésion) et **sociolinguistiques** (adéquation à la situation).
- Le candidat **peut demander de répéter/reformuler** à tout moment.
- **L'examinateur ne cherche pas à piéger** : il vise à révéler le **meilleur niveau** du candidat.

---

## 4. Persona de l'examinateur (couche « conduite »)

> Cette couche **conduit la conversation uniquement**. Elle **ne note pas**, **ne corrige pas**, **ne donne aucun indice**. La séparation conduite ≠ notation est **stricte** (anti-inflation de note).

### 4.1 Identité & ton
Examinateur TCF professionnel : **courtois, calme, neutre-bienveillant**. Présence encourageante (acquiescements naturels, « très bien », « je comprends »), **jamais évaluative ni corrective**. Français **authentique et accessible** (registre B2 atteignable). **Français exclusivement** — ne jamais basculer vers une autre langue, même si le candidat peine (reformuler/simplifier en français).

### 4.2 Ouverture (début de session)
Le persona **se présente**, **annonce la tâche**, puis **rend la parole**. Exemple à adapter (T1) :
> « Bonjour, je suis votre examinateur pour l'épreuve d'expression orale du TCF. Elle dure une dizaine de minutes et se déroule sans préparation. À tout moment, vous pouvez me demander de répéter ou de reformuler. Nous commençons par la première partie : pouvez-vous vous présenter et me parler de votre parcours et de vos projets ? **Je vous écoute.** »

Tâche 2 — présenter la situation puis rendre la parole :
> « Voici la deuxième partie. Je suis [rôle de la consigne]. Vous [situation]. Posez-moi vos questions. Je vous écoute. »

### 4.3 Conduite par tâche
- **T1** : écouter, laisser le candidat dominer le temps de parole. **Relancer seulement** s'il s'arrête ou reste trop bref, par des questions **ouvertes et neutres** (« Pouvez-vous m'en dire plus sur… ? », « Qu'est-ce qui vous a amené à… ? »). Viser ~3 min.
- **T2** : **jouer le rôle** de la consigne de façon plausible, **répondre** aux questions du candidat, fournir l'information demandée, **aider le candidat à exprimer ses choix/préférences** sans jamais lui souffler quoi demander. Relances neutres uniquement (« Avez-vous d'autres questions ? »). Viser ~3 min 30.
- **Clôture** (temps écoulé) : « Merci, nous allons nous arrêter ici. » **Aucun retour, aucune note, aucun commentaire de performance.**

### 4.4 Interdits stricts du persona
Ne **jamais** : corriger la langue ; suggérer quoi dire/demander ; commenter le niveau ou la performance ; révéler ou laisser deviner une note ; changer de langue ; sortir du cadre de la tâche ; monopoliser la parole (surtout en T1).

### 4.5 Implémentation du persona
- Le persona vit dans la **system instruction** (prompt) côté **serveur**, **jamais exposée au client en clair**.
- Le **sujet/consigne** de T2 (rôle + situation) est injecté dynamiquement depuis la banque de contenu.
- Gérer le **timing** de chaque tâche (l'agent et le client connaissent la durée cible ; le minuteur fait foi).

---

## 5. Notation (couche « scoring » — inchangée)

- **On garde la notation actuelle.** Le temps réel **n'introduit aucune logique de note**.
- À la fin du dialogue, le **transcript complet** (interventions candidat **et** examinateur) part dans le **pipeline d'évaluation existant** (rubriques de production, niveau CECRL **calculé côté serveur**, jamais par le LLM, jamais affiché brut).
- Le **transcript est l'artefact de notation** : il doit être **capturé de façon fiable côté serveur**, quel que soit le schéma de connexion retenu (cf. §6). C'est un point critique : si le transcript n'est pas garanti, le scoring est compromis.
- **Calibrage IRN — ne pas trop pénaliser** : l'IRN vérifie la **capacité à communiquer dans la société** (plafond B2). La notation EO doit **valoriser la réussite communicative et l'adéquation sociolinguistique** et rester **indulgente sur les erreurs mineures** qui n'entravent pas la compréhension. Tu **ne réécris pas** le pipeline ; tu **vérifies** que les consignes de notation EO reflètent bien cet esprit, et tu me signales tout écart. Une réponse réellement hors-sujet ou non réalisée reste notée au plus bas, comme aujourd'hui.

---

## 6. Ce que TU dois analyser et proposer (rien n'est figé ici)

Présente des **options** avec avantages/inconvénients **et une reco**. Points clés :

### 6.1 Schéma de connexion — décision centrale
Deux familles, à arbitrer selon : facilité de **bascule fournisseur**, **latence**, **duplication** de code web/mobile, lieu d'**application des quotas**, **secrets/persona** côté serveur, fiabilité de **capture du transcript**.
- **(A) Client → fournisseur en direct** (le backend émet un **token éphémère**, le client ouvre le WebSocket vers le fournisseur). Latence minimale ; mais le protocole fournisseur vit dans **les deux clients** ; transcript à rapatrier ; quotas à verrouiller via le token/contrôle serveur.
- **(B) Relais serveur** (le client parle **un protocole SejourFR stable**, le backend relaie vers le fournisseur). Un **seul point** d'abstraction et de bascule ; persona/secrets/quotas/transcript **nativement côté serveur** ; clients identiques quel que soit le fournisseur ; mais **hop supplémentaire** (latence) et charge audio serveur.
- Un précédent design interne penchait vers **(A) token éphémère + connexion directe Flutter↔WebSocket pour T1/T2**. **Audite ce qui existe réellement** et reconfirme ou propose mieux.

### 6.2 Forme de l'abstraction fournisseur
Interface normalisée (ex. « obtenir une session realtime » → descripteur : provider, modèle, endpoint, auth/token, formats audio, config voix, réf. persona) avec **adaptateurs** par fournisseur. **Modèle et fournisseur = configuration**, pas du code en dur. Conçois l'interface pour qu'OpenAI Realtime / Qwen s'y branchent (eux aussi WebSocket + secrets éphémères côté client, formats/voix spécifiques).

### 6.3 Modèle Gemini — à vérifier au moment du build
- Modèle souhaité par défaut : **`gemini-2.5-flash-native-audio-latest`** (à mettre **en config**).
- ⚠️ **La gamme Live de Gemini évolue** : certaines variantes *2.5 native-audio* sont en cours de dépréciation et un modèle plus récent est désormais recommandé côté Google. **Vérifie l'alias exact en vigueur** dans la doc/registre Gemini Live au moment d'implémenter, et rends ce choix trivial à changer (c'est tout l'intérêt de l'abstraction).
- Éléments confirmés à exploiter : connexion **WebSocket** ; **tokens éphémères** (endpoint v1alpha, `access_token`, durée courte côté session) ; possibilité de **verrouiller la system instruction dans le token** (persona reste serveur) ; **une seule modalité de sortie par session** → utiliser `AUDIO` + **activer la transcription** (entrée **et** sortie) pour récupérer le dialogue ; **français à restreindre via la system instruction** ; sessions audio largement assez longues pour 3–3 min 30. **Confirme les formats audio exacts** (PCM/échantillonnage entrée/sortie) dans la doc avant de coder côté client.
- Côté **Spring Boot (Java)** : il n'existe pas forcément de SDK haut niveau Live officiel — **vérifie** comment émettre le token (REST de provisioning vs Vertex AI) et tranche.

### 6.4 Autres points ouverts
- **Où vivent le quota et son décompte** dans le modèle de données réel (Plan/UserSubscription/entité dédiée), et **quand il est débité** (au démarrage de session ? à la connexion réussie ? gérer les sessions interrompues/échouées sans pénaliser injustement).
- **Phasage** EO autonome vs intégration examen blanc complet (cf. §2.4).
- **Placement UI** du modal et du compteur (web + mobile), états (quota=0, hors-ligne, échec de connexion → fallback async).
- **Maîtrise des coûts/abus** : le quota est le garde-fou principal ; signale tout risque résiduel.

---

## 7. Étape 1 — Audit attendu (livrable écrit, avant proposition)

Établis un état des lieux factuel :
- Stack réelle (backend, frontend web, mobile) et **versions**.
- **Module EO actuel** : qu'existe-t-il déjà (T1/T2/T3, pipeline async STT, tokens éphémères, WebSocket, ébauches realtime) ?
- **Modèle Plan / UserSubscription** : tiers, durées, droits → où brancher le quota.
- **Examens blancs** : comment l'`Attempt`/parcours gère (ou non) l'EO/EE non-QCM, et comment les résultats QCM et productifs sont agrégés.
- **Pipeline de notation EO** : rubriques, calcul CECRL serveur, consignes de notation, point d'entrée « transcript → score ».
- **Banque de consignes EO** (sujets T1/T2/T3) et leur structure.
- Conventions du dépôt (packaging backend, DTO, migrations Flyway, état réel « offline-first » mobile).

Termine par : la **liste des fichiers/zones que tu comptes créer ou modifier**, et les **questions ouvertes** restantes.

---

## 8. Points de validation humaine (hard stops)

Je valide explicitement à chacun :
1. **Fin d'audit** (§7) avant toute proposition.
2. **Choix du schéma de connexion** (§6.1) et **forme de l'abstraction** (§6.2).
3. **Emplacement du quota** dans le modèle de données + **règle de débit** (§6.4).
4. **Texte/comportement du persona** (§4) avant intégration.
5. **Phasage examen blanc** (§2.4) si tu proposes de découper.
6. Toute **migration de schéma** ou modification du **pipeline de notation**.

---

## 9. Hors périmètre / à ne pas casser

- Module **civique**, **CO/CE/Structure**, **examens blancs CO+CE** existants : inchangés.
- **Tâche 3** et **pipeline async STT** : inchangés.
- **Pipeline et règles de notation** : conservés (tu vérifies le calibrage EO, tu ne réécris pas).
- **Aucun secret** (clé API fournisseur) ni la **system instruction en clair** côté client.
- **Aucune valeur de quota en dur** : tout configurable.
