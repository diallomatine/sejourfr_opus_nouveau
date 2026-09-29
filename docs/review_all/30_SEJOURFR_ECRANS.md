# SejourFR — Inventaire et structure des écrans

> Complète `00_SEJOURFR_SPEC_MAITRE.md`, `10_SEJOURFR_TCF.md`, `20_SEJOURFR_CIVIQUE.md`.
> Ce document couvre les écrans **non spécifiés** dans les trois autres, l'inventaire complet,
> les états standards, la navigation entre Plan et Réviser, et la matrice de parité.
>
> Rappel de la frontière (`00_` §6.4) : le backend décide (niveaux, priorités, verrous, prochaine
> action), **les clients possèdent le rendu**. Les structures ci-dessous sont des specs de
> conception que Angular et Flutter implémentent, pas un contrat d'API.

---

# 1. Convention de lecture

Chaque fiche d'écran suit le même format :

```
ID · Nom                        [module] [plateformes]
Objet        à quoi sert l'écran, en une phrase
Entrée       d'où l'utilisateur arrive
Sortie       où il peut aller
Blocs        structure imposée, dans l'ordre
États        ceux qui diffèrent du standard §3
Règles       contraintes non négociables
Analytics    événements émis
```

Les écrans déjà spécifiés ailleurs ne sont pas redécrits : l'inventaire renvoie à leur section.

---

# 2. Inventaire complet

## 2.1. Tunnel TCF

| ID | Écran | Spec | Statut |
|---|---|---|---|
| T01 | Objectif et date d'examen | `10_` §3.2 + §4.1 ci-dessous | à créer |
| T02 | Rédaction du diagnostic rapide | §4.2 | à créer |
| T03 | Porte de création de compte | §4.3 | à créer |
| T04 | Analyse en cours | §4.4 | à créer |
| T05 | Résultat du diagnostic rapide | `10_` §3.6 | spécifié |
| T06 | Accueil du diagnostic complet | §5.1 | à créer |
| T07 | Passation QCM (CO / CE) | §5.2 | à créer |
| T08 | Passation EE | §5.3 | à créer |
| T09 | Passation EO | §5.4 | à créer |
| T10 | Fin de section | §5.5 | à créer |
| T11 | Diagnostic déjà réalisé | §5.6 | à créer |
| T12 | Résultat du diagnostic complet | `10_` §4.5 | spécifié |
| T13 | Paywall contextualisé | `10_` §5 | spécifié |
| T14 | Plan Premium | `10_` §6.1 | spécifié |
| T15 | Plan non abonné | `10_` §6.2 | spécifié |
| T16 | Parcours d'une priorité | `10_` §6.3 | spécifié |

## 2.2. Entraînement TCF

| ID | Écran | Spec | Statut |
|---|---|---|---|
| T20 | Réviser › Expression écrite / orale | `10_` §7.1 | spécifié |
| T21 | Tâche · onglets S'entraîner / Compétence | `10_` §7.2 | spécifié |
| T22 | Page d'une compétence | `10_` §7.3 | spécifié |
| T23 | Exécution d'une tâche complète | §6.1 | à créer |
| T24 | **Rapport IA d'une tâche complète (EE)** | §6.2 | à créer |
| T25 | **Rapport IA d'une tâche complète (EO)** | §6.3 | à créer |
| T26 | Exécution d'un micro-exercice | §6.4 | à créer |
| T27 | Rapport IA d'un micro-exercice | `10_` §8.2 | spécifié |
| T28 | Progrès TCF | §7 | à créer |

## 2.3. Civique

| ID | Écran | Spec | Statut |
|---|---|---|---|
| C01 | Choix de la mention | §8.1 | à créer |
| C02 | Passation du diagnostic | §5.2 (mutualisé avec T07) | à créer |
| C03 | Résultat du diagnostic | `20_` §4.5 | spécifié |
| C04 | Plan civique (2 variantes) | `20_` §6 | spécifié |
| C05 | Réviser › thèmes | `20_` §7.1 | spécifié |
| C06 | Thème · onglets | `20_` §7.2 | spécifié |
| C07 | Page d'une notion | `20_` §7.3 | spécifié |
| C08 | Mises en situation | `20_` §7.4 | spécifié |
| C09 | Série ciblée en cours | §8.2 | à créer |
| C10 | Correction d'une question | `20_` §7.5 | spécifié |
| C11 | Résultat d'examen blanc | `20_` §8.2 | spécifié |
| C12 | Progrès civique | `20_` §8.3 | spécifié |

## 2.4. Transverse

| ID | Écran | Spec | Statut |
|---|---|---|---|
| G01 | **Accueil agrégé TCF + civique** | §9 | à créer |
| G02 | Confirmation d'abonnement — première minute Premium | §10.1 | à créer |
| G03 | Gestion et fin d'abonnement | §10.2 | à créer |
| G04 | Profil et données personnelles | §10.3 | à créer |

## 2.5. Admin

| ID | Écran | Spec | Statut |
|---|---|---|---|
| A01 | File de tagging des notions | `20_` §3.2 | spécifié |
| A02 | Couverture du catalogue | §11.1 | à créer |
| A03 | Gestion des sujets EE/EO et micro-exercices | §11.2 | à créer |
| A04 | Supervision IA : coûts et qualité | §11.3 | à créer |

---

# 3. États standards

Définis une fois, applicables à **tous** les écrans. Un écran qui ne les implémente pas n'est pas terminé.

| État | Comportement imposé |
|---|---|
| **Chargement** | Squelette de la structure réelle de l'écran, jamais un spinner plein écran. Au-delà de 3 s, ajouter une ligne de texte expliquant l'attente. |
| **Vide** | Toujours un message + une action. Jamais un écran blanc, jamais « Aucune donnée ». Formulation orientée prochaine étape. |
| **Erreur réseau** | Message court, bouton *Réessayer*, et conservation de toute saisie en cours. Une production écrite ne doit jamais être perdue. |
| **Erreur IA** | « Votre correction n'a pas pu être générée. Nous réessayons automatiquement. » La production est enregistrée, le quota **n'est pas** décrémenté, un job de reprise est planifié, et l'utilisateur est notifié quand le rapport est prêt. |
| **Verrouillé** | Le contenu reste **visible en structure** (titre, nombre d'éléments), seul le détail est masqué. Cadenas + libellé de raison venant de `lock_reason`. Jamais un écran entièrement grisé. |
| **Quota épuisé** | Message spécifique à la source du quota, jamais générique. Exemple EE : « Vous avez utilisé votre correction gratuite en expression écrite. » |
| **Contenu insuffisant** | Mode dégradé silencieux (`00_` §7.4). L'utilisateur ne doit jamais voir qu'il manque du contenu. |

---

# 4. Tunnel du diagnostic rapide

## 4.1. T01 · Objectif et date d'examen `[TCF]` `[web+mobile]`

**Objet** — Recueillir les 3 informations qui personnalisent tout le tunnel.
**Entrée** — Accueil, page d'atterrissage, ou CTA « Faire mon diagnostic ».
**Sortie** — T02.

```
[Header]        logo SejourFR · pas de retour destructif
[Titre]         « Avant de commencer »
                « 3 questions rapides pour personnaliser votre diagnostic. »

[Q1]            Quel examen préparez-vous ?
                [TCF IRN]  [Examen civique]  [Les deux]        cartes sélectionnables

[Q2]            ⚠ dépend de la réponse à Q1, affichée dynamiquement sur la même page

  si TCF      → « Quel niveau visez-vous ? »
                [A2 — Carte de séjour pluriannuelle]
                [B1 — Carte de résident]
                [B2 — Naturalisation]

  si Civique  → « Quelle démarche préparez-vous ? »
                [Carte de séjour pluriannuelle (CSP)]
                [Carte de résident (CR)]
                [Naturalisation (NAT)]

  si Les deux → les DEUX questions, dans cet ordre, la seconde présélectionnée
                sur la mention correspondant au niveau choisi (A2→CSP, B1→CR, B2→NAT),
                modifiable

                sous-texte commun : « Vous pourrez le modifier plus tard. »

[Q3]            Avez-vous une date d'examen ?
                [Oui]  → sélecteur de date
                [Pas encore]

[CTA]           Commencer
```

**Règles** — Une seule page, pas de wizard en 3 étapes ; Q2 se substitue en place sans changement d'écran. Ne jamais demander un niveau CECRL à quelqu'un qui ne prépare que le civique. Q3 est facultative et ne bloque jamais.
**Sortie selon Q1** — `TCF` → T02 · `Civique` → C02 (la mention est déjà connue, C01 est sauté) · `Les deux` → T02, la mention civique étant déjà enregistrée.
**Analytics** — `onboarding_started`, `onboarding_completed` (target_level, has_exam_date).

## 4.2. T02 · Rédaction du diagnostic rapide `[TCF]` `[web+mobile]`

**Objet** — Recueillir la production unique de 150–220 mots.

```
[Header]        « Diagnostic écrit »  ·  compteur discret « environ 10 minutes »

[Consigne]      carte fixe, toujours visible (ne défile pas sur mobile)
                le sujet transversal tiré (10_ §3.3)
                « Objectif recommandé : 150 à 220 mots »

[Saisie]        zone de texte plein écran, hauteur maximale disponible
                compteur de mots vivant, sans dénominateur trompeur :
                    87 mots
                    Objectif recommandé : 150–220 mots
                le compteur passe au vert à partir de 150 mots
                sauvegarde automatique toutes les 10 s + à chaque pause de frappe

[Aide]          une seule ligne, pas un pavé de conseils :
                « Écrivez naturellement. Ce n'est pas noté comme un examen. »

[CTA]           Valider mon diagnostic
                désactivé sous 100 mots, avec libellé explicite :
                « Encore 13 mots minimum pour lancer l'analyse »
```

**Deux seuils distincts, à ne jamais confondre à l'écran** :

| Seuil | Valeur | Rôle |
|---|---|---|
| Recevabilité | **100 mots** | en dessous, l'analyse ne peut pas être lancée |
| Objectif recommandé | **150–220 mots** | qualité de l'analyse, jamais présenté comme un minimum |

Afficher `87 / 150` laisserait croire que 150 est obligatoire : interdit.

**Règles** — Pas de chronomètre visible, pas de compte à rebours, pas de blocage du copier-coller (inutile et hostile). La sauvegarde survit à une fermeture d'onglet ou d'app. Sur mobile, le clavier ne doit jamais masquer le compteur ni le CTA.
**États** — Reprise : si un brouillon existe, l'écran s'ouvre dessus avec « Vous aviez commencé, reprenez où vous en étiez. »
**Analytics** — `quick_diag_started`, `quick_diag_submitted` (word_count, duration_seconds).

## 4.3. T03 · Porte de création de compte `[TCF]` `[web+mobile]`

**Objet** — Obtenir le compte au moment où la motivation est maximale. **Écran le plus sensible du tunnel.**

```
[Visuel]        icône ou illustration sobre, pas de célébration excessive

[Titre]         « Votre texte est enregistré »
[Sous-titre]    « Créez votre compte pour lancer l'analyse et découvrir
                  votre niveau estimé et vos axes de progression. »

[Rappel]        carte discrète
                ✓ 187 mots enregistrés
                ✓ Analyse gratuite
                ✓ Résultat complet, sans abonnement

[CTA principal] Créer mon compte
[Secondaire]    J'ai déjà un compte
[Tertiaire]     Continuer avec Google / Apple   (si déjà en place)

[Pied]          « Votre texte est conservé, vous ne le perdrez pas. »
```

**Règles** — Interdiction absolue d'écrire « Votre analyse est prête » : rien n'est analysé, ce serait un mensonge et l'attente qui suit le révélerait. Ne jamais afficher un aperçu partiel du résultat ici — soit on donne tout après le compte, soit rien. Aucune mention de prix, aucun paywall.
**États** — Échec d'inscription : la production reste intacte, l'utilisateur revient sur cet écran, jamais sur T02.
**Analytics** — `quick_diag_signup_gate_viewed`, `signup_started`, `signup_completed(source=quick_diag)`, `quick_diag_gate_abandoned`.

## 4.4. T04 · Analyse en cours `[TCF]` `[web+mobile]`

**Objet** — Tenir l'attente de 5 à 15 s sans donner l'impression d'un bug.

```
[Animation]     sobre, en cohérence avec la marque
[Titre]         « Analyse de votre texte »
[Étapes]        se cochent progressivement, rythmées sur la durée réelle
                ✓ Lecture de votre production
                ✓ Analyse de votre expression
                ○ Préparation de vos axes de progression
[Pied]          « Quelques secondes seulement. »
```

**Règles** — Les étapes sont indicatives et ne doivent pas prétendre décrire des sous-appels qui n'existent pas. Au-delà de 25 s : « L'analyse prend plus de temps que prévu, nous vous prévenons dès qu'elle est prête » + libération de l'écran, notification à la fin. Si l'appel échoue : état *Erreur IA* du §3, et **relance automatique**, l'utilisateur ne relance jamais lui-même un appel payant.
**Analytics** — `quick_diag_analysis_started`, `quick_diag_analyzed(duration_ms)`, `quick_diag_analysis_failed`.

---

# 5. Diagnostic TCF complet

## 5.1. T06 · Accueil du diagnostic complet `[TCF]` `[web+mobile]`

**Objet** — Rendre les 75 minutes acceptables en montrant qu'elles se découpent.

```
[Header]        « Diagnostic TCF »
[Intro]         « 4 épreuves, environ 75 minutes au total.
                  Vous pouvez les faire séparément, quand vous voulez. »

[Progression]   1 section sur 4 terminée          barre discrète

[Sections]      4 cartes, ordre libre
                🎧 Compréhension orale     15 questions · ~13 min    [Terminée ✓]
                📖 Compréhension écrite    15 questions · ~20 min    [Commencer]
                ✍️ Expression écrite       3 tâches · 30 min         [Commencer]
                🎤 Expression orale        3 tâches · 10 min         [Commencer]
                chaque carte indique clairement : une fois commencée,
                la section se termine d'une traite

[Encart]        « Votre résultat complet s'affichera une fois les 4 sections terminées. »

[Pied]          « Vous avez 7 jours pour terminer. »   si une section est déjà faite
```

**Règles** — **Aucun résultat partiel n'est affiché entre les sections** : le résultat est le moment de conversion, le diluer le détruit. Une section commencée puis interrompue est reprise à zéro (chronométrée), et l'écran le dit avant de lancer. Sur mobile, prévenir avant EO : « Cette section utilise votre micro. »
**États** — Au-delà de 7 jours : bandeau « Votre diagnostic a expiré. Nous calculerons votre résultat sur les sections terminées. » + CTA *Voir mon résultat*.
**Analytics** — `full_diag_started`, `full_diag_section_started(epreuve)`.

## 5.2. T07 · Passation QCM `[TCF + civique]` `[web+mobile]`

**Objet** — Écran de passation mutualisé : CO, CE, diagnostic civique, séries ciblées, examens blancs.

```
[Barre]         ← quitter    Question 7 / 15    ⏱ 12:34
                barre de progression fine
[Support]       audio (CO) : lecteur, nombre d'écoutes autorisées affiché
                texte (CE) : passage scrollable, énoncé fixe en bas
                image : média inline
[Énoncé]        question
[Choix]         4 options, cible tactile ≥ 48 px
[CTA]           Valider   →   Question suivante
```

**Règles** — En mode diagnostic et examen blanc : **aucune correction affichée pendant la passation**. En mode entraînement libre : correction immédiate (`20_` §7.5). Quitter en cours affiche une confirmation explicite indiquant si la progression est perdue. Le chronomètre est par section, jamais global.
**États** — Perte de réseau : les réponses sont mises en file et renvoyées avec le même `client_submission_id`.

## 5.3. T08 · Passation EE `[TCF]` `[web+mobile]`

```
[Barre]         Tâche 2 / 3    ⏱ 30:00 pour l'ensemble de l'épreuve
[Consigne]      carte fixe : situation, destinataire, longueur attendue
[Saisie]        compteur de mots, sauvegarde continue
[CTA]           Tâche suivante   (dernière tâche : Terminer l'épreuve)
```

**Règles** — Le chronomètre de 30 min couvre les 3 tâches, comme au TCF ; l'utilisateur répartit son temps librement et peut revenir sur une tâche précédente. À l'expiration : soumission automatique de ce qui est écrit, sans perte.

## 5.4. T09 · Passation EO `[TCF]` `[web+mobile]`

```
[Barre]         Tâche 1 / 3
[Consigne]      énoncé + durée de la tâche (3:00 / 3:30 / 3:30)
[Préparation]   affichée uniquement si tcf_task.prep_seconds > 0
                prep_seconds = 0 → le bloc n'existe pas, aucune mention
                aucune tâche n'est traitée en dur : la donnée décide
[Enregistrement]
                bouton unique, large
                minuteur décomptant la durée de la tâche
                indicateur de niveau sonore
                arrêt automatique à max_duration_seconds
[Après]         [Réécouter]  [Recommencer]  [Valider]
                Recommencer : autorisé une fois par tâche en entraînement,
                jamais en diagnostic ni en examen blanc
[CTA]           Tâche suivante
```

**Règles** — Demande de permission micro avant la première tâche, avec explication. Test micro proposé une fois. En cas d'échec d'upload : conservation locale du fichier et reprise automatique, jamais de perte silencieuse. Interdiction de lancer l'enregistrement sans que l'utilisateur voie la consigne.
**États** — Permission refusée : écran dédié expliquant comment l'activer, et proposition de sauter la section EO (le diagnostic reste valide, EO devient « non évaluée »).

## 5.5. T10 · Fin de section `[TCF]` `[web+mobile]`

```
[Icône]         validation sobre
[Titre]         « Section terminée »
[Texte]         « Compréhension écrite terminée. Plus que 2 épreuves. »
[Progression]   2 sections sur 4
[CTA]           Continuer avec l'expression écrite
[Secondaire]    Reprendre plus tard
[Pied]          « Votre résultat s'affichera à la fin des 4 sections. »
```

**Règles** — Aucun score, aucun niveau, aucun indice de performance. C'est volontaire.

## 5.6. T11 · Diagnostic déjà réalisé `[TCF]` `[web+mobile]`

```
[Titre]         « Votre diagnostic initial a déjà été réalisé »
[Texte]         « Vous l'avez passé le 12 mars. Votre niveau estimé était B1. »
[CTA principal] Voir mon diagnostic
[Bloc Premium]  « Mesurer votre progression »
                « Avec Premium, réévaluez votre niveau et vérifiez que vous êtes
                  réellement passé de B1 à B2. »
                [Débloquer ma réévaluation]
```

**Règles** — Ne jamais bloquer l'accès au résultat existant. La réévaluation Premium est limitée à une tous les 14 jours (`10_` §4.6) et le dire ici.

---

# 6. Entraînement et rapports IA

## 6.1. T23 · Exécution d'une tâche complète `[TCF]` `[web+mobile]`

Identique à T08 / T09, avec ces différences : une seule tâche, chronomètre indicatif et non bloquant, possibilité d'enregistrer un brouillon et de revenir. En bas, un rappel discret du quota : « Correction IA : 1 gratuite restante » — jamais un compte à rebours anxiogène.

## 6.2. T24 · Rapport IA d'une tâche complète — EE `[TCF]` `[web+mobile]`

**Objet** — L'écran que verront le plus souvent les abonnés. Il doit être **plus riche** que le rapport de micro-exercice, mais rester lisible.
**Rendu** — `TaskReportRenderer`, routé sur `schema_version` (`10_` §8.3).

```
[1. Verdict]
      Expression écrite — Tâche 3
      Niveau de cette production :  B1
      « Votre réponse est claire et répond à la consigne, mais elle reste
        encore trop peu développée pour montrer un niveau B2. »
      si off_task : bandeau « Votre réponse s'écarte de la consigne »
                    + niveau plafonné, expliqué

[2. Vos compétences sur cette tâche]
      une ligne par compétence évaluée, statut + libellé candidat
      ✅ Respecter la consigne
      ✅ Utiliser un vocabulaire adapté
      🟠 Relier ses idées
      🔴 Développer ses arguments
      🔴 Nuancer son opinion
      chaque ligne dépliable → commentaire + extrait exact cité de sa production
      ⚠ l'extrait est obligatoire : c'est ce qui rend la correction crédible

[3. Le point prioritaire]
      un seul, celui de top_improvement
      « Développer vos arguments »
      ce qui manque (1 phrase) + ce qu'il faut faire la prochaine fois (1 phrase)

[4. Avant → Après]
      extrait original de sa production
      version améliorée, avec étiquettes des ajouts : exemple · conséquence · nuance

[5. Votre texte annoté]                  repliable, fermé par défaut
      la production intégrale, avec les extraits cités mis en évidence
      ⚠ pas de correction orthographique ligne à ligne : ce n'est pas un correcteur

[6. Effet sur votre plan]
      « Cette production met à jour votre plan. »
      → Développer ses arguments : toujours à travailler
      → Relier ses idées : en progression
      [CTA] Continuer mon plan

[Pied]  [Refaire cette tâche]  ·  [Voir un autre sujet]
```

**Règles** — Jamais plus de 5 compétences affichées. Le bloc 6 est construit par le moteur, pas par le LLM. Pour un non abonné ayant consommé son essai : blocs 1 et 3 visibles, blocs 2, 4, 5 verrouillés avec leur structure apparente (« 5 compétences analysées 🔒 »).
**Analytics** — `task_report_viewed(task, level, locked)`.

## 6.3. T25 · Rapport IA d'une tâche complète — EO `[TCF]` `[web+mobile]`

Même structure que T24, avec en plus :

```
[0. Votre enregistrement]        placé avant le verdict
      lecteur audio + durée réelle
      « Ce que nous avons entendu »   → transcription, repliable
      mention obligatoire : « Transcription automatique, elle peut contenir
      des approximations. Votre prononciation n'est pas évaluée dessus. »
```

et, uniquement si `speech_rate_comment` est non nul, une ligne sur le débit. Aucun commentaire d'orthographe nulle part.

## 6.4. T26 · Exécution d'un micro-exercice `[TCF]` `[web+mobile]`

```
[Header]        Compétence : Développer ses arguments        Exercice 2 / 3
[Objectif]      « Objectif : ajouter un exemple à votre raison. »
[Consigne]      énoncé court
[Saisie]        zone compacte — c'est un exercice de 2 à 3 minutes,
                pas une tâche : l'interface doit le montrer
                pas de compteur de mots contraignant
[CTA]           Valider
```

**Règles** — L'interface doit visuellement se distinguer de T23. Un micro-exercice qui ressemble à une tâche complète décourage. En EO : enregistrement limité à 60 s.

---

# 7. T28 · Progrès TCF `[TCF]` `[web+mobile]`

**Objet** — Montrer le mouvement, pas un tableau de bord.

```
[Segmented]     TCF IRN | Examen civique

[1. Niveau]     B1 → objectif B2
                historique des estimations : diagnostic initial B1 · réévaluation B1
                courbe uniquement s'il y a au moins 2 points

[2. Par épreuve]  4 lignes, niveau actuel + évolution depuis le diagnostic
                🎧 CO  B2   =
                📖 CE  B2   =
                ✍️ EE  B1   ↑ depuis A2
                🎤 EO  B1   =

[3. Compétences] « 4 compétences maîtrisées sur 11 travaillées »
                liste des dernières acquises, avec date

[4. Activité]   entraînements réalisés sur 30 jours, régularité
                pas de série de flammes, pas de gamification agressive

[5. Historique] productions et rapports, consultables à vie
```

**Règles** — Aucun pourcentage de progression vers un niveau. Non abonné : blocs 1 et 2 visibles, 3 et 5 verrouillés.
**État vide** — « Votre progression s'affichera après votre premier diagnostic. » + CTA.

---

# 8. Civique

## 8.1. C01 · Choix de la mention `[civique]` `[web+mobile]`

```
[Titre]         « Quelle démarche préparez-vous ? »
[Options]       3 cartes
                Carte de séjour pluriannuelle (CSP)
                Carte de résident (CR)
                Naturalisation (NAT)
                chaque carte : une ligne expliquant à qui elle s'adresse
[Pied]          « Le contenu de l'examen dépend de votre démarche.
                  Vous pourrez la modifier dans votre profil. »
[CTA]           Continuer
```

**Règles** — Écran obligatoire avant tout contenu civique. En cas de changement ultérieur : écran de confirmation expliquant que le plan sera recalculé et que **les notions déjà maîtrisées sont conservées**.

## 8.2. C09 · Série ciblée en cours `[civique]` `[web+mobile]`

Reprend T07, avec :

```
[Bandeau]       Notion travaillée : Le Parlement          Question 4 / 10
[Après réponse] correction immédiate (20_ §7.5)
[Fin de série]  « Série terminée — 8 / 10 »
                « Le Parlement passe de À travailler à En progression. »
                « Prochaine révision proposée dans 3 jours. »
                [CTA] Continuer mon plan   ·   [Refaire cette notion]
```

**Règles** — L'effet Leitner doit être **visible** : c'est ce qui rend la valeur Premium tangible. Ne jamais afficher le numéro de boîte, seulement l'état et la prochaine échéance.

---

# 9. G01 · Accueil agrégé `[transverse]` `[web+mobile]`

**Objet** — Écran d'entrée de l'app. Répond à une seule question : **qu'est-ce que je fais maintenant ?**

```
[Salutation]    « Bonjour Amadou »
                si date d'examen : « TCF le 18 octobre — dans 39 jours »

[1. À faire aujourd'hui]        LE bloc dominant
                au maximum 2 cartes, une par module actif
                🎤 TCF · Expression orale, tâche 3
                   « Nuancer votre opinion »   ~8 min      [Commencer]
                📘 Civique · Le Parlement
                   « 10 questions ciblées »    ~6 min      [Commencer]
                les deux prochaines actions viennent des deux plans,
                elles ne sont jamais fusionnées en un plan unique

[2. Vos objectifs]              compact, une ligne par module
                TCF        B1 → B2
                Civique    30 / 40 → 32 requis

[3. Reprendre]                  n'apparaît que s'il y a quelque chose en cours
                « Diagnostic TCF — 2 sections sur 4 »       [Reprendre]

[4. Réviser librement]          accès à la bibliothèque
                Expression écrite · Expression orale · Compréhension
                Thèmes civiques · Mises en situation

[5. Encart contextuel]          un seul, jamais deux
                sans diagnostic  → « Commencez par un diagnostic »
                non abonné       → rappel du plan verrouillé
                abonné           → progression récente
```

**Règles** — Un seul module actif ? Les blocs civiques disparaissent, ils ne sont pas grisés. Jamais plus de 2 actions proposées dans le bloc 1 : au-delà, ce n'est plus un GPS.
**État vide** — Nouvel utilisateur : le bloc 1 est remplacé par le CTA diagnostic.

---

# 10. Abonnement

## 10.1. G02 · Confirmation d'abonnement `[transverse]` `[web+mobile]`

**Objet** — La première minute d'un abonné décide de sa rétention. Ne jamais renvoyer vers un écran générique.

```
[Confirmation]  « Votre plan B2 est actif »
                pas « Merci pour votre achat »
[Récapitulatif] Premium · 14,99 €/mois · renouvellement le 9 octobre
[Ce qui change] 3 lignes maximum, concrètes
                ✓ Vos 3 priorités sont débloquées
                ✓ Vos entraînements sont corrigés et expliqués
                ✓ Votre plan s'adapte après chaque séance
[CTA principal] Commencer ma première étape
                → mène DIRECTEMENT à l'exercice, pas à la page Plan
```

**Règles** — Le CTA doit lancer l'action, pas afficher un menu. C'est le point où l'abonné doit ressentir immédiatement ce qu'il a acheté.

## 10.2. G03 · Gestion et fin d'abonnement `[transverse]` `[web+mobile]`

État de l'abonnement, date de renouvellement, résiliation sans friction (aucun parcours de rétention à obstacles), historique de facturation.

**Après expiration** : le plan reste visible en version aperçu, les diagnostics, productions et rapports restent **consultables à vie**. Bandeau : « Votre plan est en pause. Vos résultats et votre historique sont conservés. » Aucune suppression de donnée.

## 10.3. G04 · Profil et données `[transverse]` `[web+mobile]`

Objectif et date d'examen modifiables, mention civique, langue, notifications, et — obligatoire au titre du RGPD (`00_` §13) — **export de mes données** et **suppression de mon compte**, incluant les enregistrements audio.

---

# 11. Admin

## 11.1. A02 · Couverture du catalogue

Tableau par module. Civique : notions × mentions, nombre de questions actives, notions sous le seuil de 4 en rouge, taux de tagging par thème avec l'indicateur `notion_mode_enabled`. TCF : questions par `question_type` × `difficulty` × `competence_code`, sujets par tâche, micro-exercices par compétence, compétences sans aucun micro-exercice signalées.

## 11.2. A03 · Gestion des contenus EE/EO

CRUD des sujets de tâche et des micro-exercices, avec statut `DRAFT` / `PUBLISHED`, prévisualisation dans le rendu réel, et génération assistée (`10_` §10.7) qui écrit **toujours en brouillon**.

## 11.3. A04 · Supervision IA

Coût par source et par jour, coût moyen d'un diagnostic complet, **coût d'acquisition par abonné**, taux d'échec de validation de schéma par prompt et version, latence, et échantillon de rapports récents pour relecture qualité. C'est cet écran qui permettra de décider si le diagnostic complet gratuit reste soutenable.

---

# 12. Navigation Plan → Réviser

Le Plan est le GPS, Réviser la bibliothèque : ils doivent partager les mêmes destinations, jamais dupliquer les écrans.

```
Plan · [Commencer] sur « EO tâche 3 — Nuancer son opinion »
   → route : /reviser/eo/taches/EO3/competences/eo_nuancer/exercices/{id}?from=plan
```

Règles :

- une étape de plan **ne crée jamais un écran dédié** : elle ouvre l'écran de Réviser correspondant ;
- le paramètre `from=plan` change deux choses seulement : le bouton retour revient au Plan, et le rapport affiche le bloc « Effet sur votre plan » ;
- à l'inverse, un exercice lancé depuis Réviser met **quand même** à jour les états de compétence et le plan. Il n'y a qu'un seul système pédagogique ;
- deep links à supporter à l'identique en web (routes Angular) et mobile (routes Flutter), avec les mêmes chemins.

---

# 13. Matrice de parité

À maintenir dans le dépôt et à cocher à chaque lot. Un écran non coché des deux côtés bloque la clôture du lot (`00_` §15).

| ID | Écran | Angular | Flutter | États | Analytics |
|---|---|:--:|:--:|:--:|:--:|
| T01 | Objectif et date | ☐ | ☐ | ☐ | ☐ |
| T02 | Rédaction diagnostic | ☐ | ☐ | ☐ | ☐ |
| T03 | Porte de compte | ☐ | ☐ | ☐ | ☐ |
| T04 | Analyse en cours | ☐ | ☐ | ☐ | ☐ |
| T05 | Résultat rapide | ☐ | ☐ | ☐ | ☐ |
| T06 | Accueil diagnostic complet | ☐ | ☐ | ☐ | ☐ |
| T07 | Passation QCM | ☐ | ☐ | ☐ | ☐ |
| T08 | Passation EE | ☐ | ☐ | ☐ | ☐ |
| T09 | Passation EO | ☐ | ☐ | ☐ | ☐ |
| T10 | Fin de section | ☐ | ☐ | ☐ | ☐ |
| T11 | Diagnostic déjà réalisé | ☐ | ☐ | ☐ | ☐ |
| T12 | Résultat complet | ☐ | ☐ | ☐ | ☐ |
| T13 | Paywall | ☐ | ☐ | ☐ | ☐ |
| T14 | Plan Premium | ☐ | ☐ | ☐ | ☐ |
| T15 | Plan non abonné | ☐ | ☐ | ☐ | ☐ |
| T16 | Parcours priorité | ☐ | ☐ | ☐ | ☐ |
| T20 | Réviser EE/EO | ☐ | ☐ | ☐ | ☐ |
| T21 | Tâche · onglets | ☐ | ☐ | ☐ | ☐ |
| T22 | Page compétence | ☐ | ☐ | ☐ | ☐ |
| T23 | Tâche complète | ☐ | ☐ | ☐ | ☐ |
| T24 | Rapport tâche EE | ☐ | ☐ | ☐ | ☐ |
| T25 | Rapport tâche EO | ☐ | ☐ | ☐ | ☐ |
| T26 | Micro-exercice | ☐ | ☐ | ☐ | ☐ |
| T27 | Rapport micro | ☐ | ☐ | ☐ | ☐ |
| T28 | Progrès TCF | ☐ | ☐ | ☐ | ☐ |
| C01 | Mention | ☐ | ☐ | ☐ | ☐ |
| C03 | Résultat diagnostic civique | ☐ | ☐ | ☐ | ☐ |
| C04 | Plan civique | ☐ | ☐ | ☐ | ☐ |
| C05–C08 | Réviser civique | ☐ | ☐ | ☐ | ☐ |
| C09 | Série ciblée | ☐ | ☐ | ☐ | ☐ |
| C10 | Correction question | ☐ | ☐ | ☐ | ☐ |
| C11 | Résultat examen blanc | ☐ | ☐ | ☐ | ☐ |
| C12 | Progrès civique | ☐ | ☐ | ☐ | ☐ |
| G01 | Accueil agrégé | ☐ | ☐ | ☐ | ☐ |
| G02 | Confirmation abonnement | ☐ | ☐ | ☐ | ☐ |
| G03 | Gestion abonnement | ☐ | ☐ | ☐ | ☐ |
| G04 | Profil et données | ☐ | ☐ | ☐ | ☐ |

Écrans admin : web uniquement, hors matrice.

---

# 14. Definition of Done — écran

- [ ] les blocs sont présents dans l'ordre spécifié, sur les deux plateformes ;
- [ ] les 7 états du §3 sont implémentés ;
- [ ] aucun texte en dur : tout passe par `i18n/fr.json` (`00_` §6.3) ;
- [ ] aucun seuil, niveau ou verrou calculé côté client ;
- [ ] les événements analytics sont émis avec les mêmes noms des deux côtés ;
- [ ] cible tactile ≥ 48 px, contraste AA, navigation clavier sur web, libellés lisibles par lecteur d'écran ;
- [ ] toute saisie survit à une perte de réseau ou à une fermeture de l'application ;
- [ ] rendu vérifié à 390 px de large, et en colonne centrée ≤ 480 px sur web.
