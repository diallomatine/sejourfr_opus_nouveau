# GUIDE EO — Expression orale (Tâches 1/2/3, niveaux A2/B1/B2)

> À utiliser avec `GUIDE_00_COMMUN_conventions.md`. L'EO génère :
> 1. des **sujets** (`production_tasks`) que le candidat traite à l'oral ;
> 2. des **exemples-modèles** (`production_examples`) sous forme de **simulations
>    réalistes** (dialogue/monologue) avec **SSML** ; l'audio est généré ensuite
>    par le batch admin (Azure).

---

## Rappel des 3 tâches EO (officiel TCF IRN)

| Tâche | Nature | Durée cible | Min. accepté |
|---|---|---|---|
| Tâche 1 | Entretien dirigé (se présenter, l'examinateur relance) | **3 min** | 2 min (120 s) |
| Tâche 2 | Exercice en interaction (jeu de rôle) | **3 min 30** | 2 min (120 s) |
| Tâche 3 | Exprimer ses goûts / opinions (monologue) | **3 min 30** | 2 min (120 s) |

En dessous de 2 min : production bloquée. Entre 2 min et la cible : acceptée mais
message d'amélioration remonté.

---

## A) Génération des SUJETS (`production_tasks`)

Champs :
```
epreuve='TCF_EO', tache_numero (1|2|3), niveau_cible (indicatif, nullable),
consigne, contexte,
duree_max_sec (180 pour T1 ; 210 pour T2/T3), duree_min_sec=120,
mots_min=NULL, mots_max=NULL, is_active=true
```

### Nature des sujets par tâche
- **T1 (se présenter)** : la tâche n'a pas de variantes au sens strict → imposer
  **des profils** comme sujets (« Vous êtes mécanicien et souhaitez la nationalité.
  Présentez-vous. », « Vous êtes étudiant étranger… », « Vous êtes infirmière en
  France depuis 5 ans… »). ~10 profils variés.
- **T2 (jeu de rôle)** : situations d'interaction du quotidien (louer un logement,
  acheter/réparer un objet, prendre un RDV, réclamation, ouvrir un compte,
  organiser un déménagement…). L'app/examinateur joue l'autre rôle.
- **T3 (opinion)** : questions d'opinion (« Quelle est la ville que vous préférez ?
  Pourquoi ? », transports gratuits, écrans des enfants, télétravail, tourisme…).

> ~10 sujets par tâche. `niveau_cible` indicatif (jamais un filtre).

---

## B) Génération des EXEMPLES-MODÈLES (`production_examples`)

Simulations **proches du réel**, à la **bonne durée**. Champs :
```
task_id, titre, resume, contenu, explications, ssml_text, plan_points (jsonb),
niveau_indicatif, display_order, audio_url=NULL (généré par le batch)
```

- `contenu` = transcription **lisible** : `[Examinateur] … [Candidat] …` (T1/T2) ou
  monologue (T3).
- `ssml_text` = SSML **multi-voix** prêt pour Azure (cf. règles SSML du commun).
- `explications` = ce qui rend la prestation réussie (structure, temps, connecteurs,
  stratégie d'interaction).

### Voix
- **T1** : Denise = examinateur ; Henri (ou Vivienne) = candidat.
- **T2** : Denise = l'autre rôle (agent, conseiller…) ; Henri/Vivienne = candidat.
- **T3** : une seule voix (le candidat), Henri ou Vivienne.

### Durée cible et volume de texte
Azure ≈ 145-160 mots/min. Pour atteindre les cibles :
- **T1 (~3 min)** : viser **~330-410 mots prononcés** (dialogue), ≥ 2 min impératif.
- **T2 (~3 min 30)** : **~310-480 mots prononcés** (échange complet).
- **T3 (~3 min 30)** : **~330-500 mots prononcés** (monologue structuré).
Toujours **dépasser 2 min**. Mieux vaut dense et naturel que long et creux.

---

## Calibration par niveau (richesse de la prestation modèle)

### T1 — Entretien dirigé
- A2 : réponses courtes mais complètes à chaque relance (identité, travail, famille,
  loisirs). Présent + passé composé simple.
- B1 : réponses développées, parcours (avant/maintenant), motivations, projets ;
  connecteurs, passé composé/imparfait.
- B2 : discours fluide, nuancé, lexique précis, capacité à rebondir, recul réflexif
  sur son parcours et ses projets.

### T2 — Jeu de rôle
- A2 : poser des questions simples et claires (prix, lieu, horaire), réagir
  (« d'accord », « très bien »), conclure.
- B1 : enchaîner plusieurs questions variées (prix, charges, documents, délai),
  réagir au contenu (« c'est important pour moi car… »), négocier, fixer une suite.
- B2 : interaction riche (conditionnel de politesse, reformulation, négociation
  fine), registre adapté, initiative dans la conversation.

### T3 — Opinion (monologue)
- A2 : position claire + deux raisons + un exemple + conclusion. Phrases simples.
- B1 : introduction + 2 arguments illustrés + concession + conclusion ; connecteurs
  (d'abord, ensuite, par exemple, cependant).
- B2 : thèse nuancée, objection anticipée et réfutée, connecteurs concessifs,
  subjonctif (« à condition que »), conclusion ouverte et adaptée.

---

## Structure attendue des modèles

**T1 (dialogue)** : ouverture examinateur → présentation → relances thématiques
(travail, venue en France, loisirs, projets) → clôture. Le **candidat parle le plus**.

**T2 (dialogue)** : l'autre rôle ouvre → candidat expose son besoin → série de
questions/réponses (le candidat mène) → conclusion concrète (RDV, décision).

**T3 (monologue)** : introduction (sujet + position) → argument 1 + exemple →
argument 2 → objection → réponse à l'objection → conclusion nuancée.

`plan_points` reflète cette structure, ex :
```json
["Introduction : sujet + position", "Argument 1 + exemple", "Argument 2", "Objection", "Réponse à l'objection", "Conclusion nuancée"]
```

---

## SSML (gabarits)

**T1 / T2 (dialogue, alternance Denise ↔ candidat) :**
```xml
<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">{réplique examinateur}</prosody></voice><break time="700ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">{réplique candidat}</prosody></voice><break time="700ms"/>…</speak>
```

**T3 (monologue, une voix, pauses entre paragraphes) :**
```xml
<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-HenriNeural"><prosody rate="1.0">{intro}<break time="600ms"/>{argument 1}<break time="600ms"/>{argument 2}<break time="600ms"/>{objection}<break time="600ms"/>{réponse}<break time="600ms"/>{conclusion}</prosody></voice></speak>
```

Vérifier l'équilibre des balises et **estimer la durée** (mots ÷ 150 × 60 + pauses)
pour confirmer ≥ 2 min, idéalement proche de la cible.

---

## `explications` (pédagogique)

Pointer les leviers de réussite : « Le candidat ne récite pas, il développe chaque
réponse avec un exemple », « connecteurs concessifs et subjonctif marquent le B2 »,
« l'objection anticipée renforce l'argumentation », « le candidat mène l'échange et
pose des questions variées ».

---

## Checklist spécifique EO

- [ ] Sujets : `epreuve='TCF_EO'`, `duree_max_sec` (180/210), `duree_min_sec=120`.
- [ ] T1 = profils variés ; T2 = situations d'interaction ; T3 = questions d'opinion.
- [ ] Exemples : `contenu` lisible ([Rôle] …) + `ssml_text` multi-voix équilibré.
- [ ] Durée estimée ≥ 2 min (idéalement proche cible) ; voix correctes par tâche.
- [ ] Gradation A2/B1/B2 visible (richesse, connecteurs, registre, stratégie).
- [ ] `audio_url=NULL` (généré par le batch admin).
- [ ] + checklist universelle du commun.
