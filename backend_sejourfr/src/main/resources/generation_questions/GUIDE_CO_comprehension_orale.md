# GUIDE CO — Compréhension orale (A2 / B1 / B2)

> À utiliser avec `GUIDE_00_COMMUN_conventions.md`. Table cible :
> `audio_question_draft`. L'audio est généré ensuite par le batch admin (Azure).

---

## Table cible `audio_question_draft` (colonnes)

```
id, difficulty ('A2'|'B1'|'B2'), competence_code, theme_id,
inline_svg, image_url, image_alt_text,          -- (CO_IMAGE uniquement)
transcript_text,                                 -- version lisible affichée
ssml_text,                                       -- audio multi-voix Azure
statement,                                       -- consigne candidat
explanation,                                     -- correction pédagogique
choices (jsonb), voice_recommended, status,      -- status = 'TEXT_VALIDATED'
audio_url, audio_duration_sec, audio_voice_used,
audio_generated_at, batch_id, created_at,
audio_validated_at, audio_validated_by, rejection_reason
```
À la génération de texte : `status = 'TEXT_VALIDATED'`, `audio_url = NULL` et toutes
les colonnes audio à `NULL` (remplies par le batch). `voice_recommended` = la voix
principale du document.

---

## Les 3 sous-formats CO (d'après le TCF officiel)

### Format A — CO_IMAGE (image + 4 propositions)
Une **image** est affichée, l'audio lit **seulement l'intro + les 4 propositions**.
Le candidat choisit la proposition qui correspond à l'image. **Pas de document parlé.**
- Renseigner `inline_svg` + `image_alt_text` (cf. règles SVG du commun).
- `competence_code = 'co_image_proposition'`.
- SSML = 1 seule voix (Denise) : intro + propositions.
- Surtout A2 (peut exister en B1 avec scènes plus subtiles).

### Format B — Question + 4 réponses (sans document, sans image)
L'audio lit **une question courte** puis **4 réponses**. Le candidat choisit la
réponse cohérente avec la question. Les distracteurs répondent à d'autres questions
(lieu, moment, fréquence, cause, but…).
- `competence_code = 'co_question_reponse'`.
- SSML : intro (Denise) → question (Henri ou Vivienne) → propositions (Denise).
- A2 (questions concrètes) → B1 (questions plus variées).

### Format C — Document sonore + question
L'audio diffuse un **dialogue ou monologue**, puis **une question**. Le candidat
choisit la bonne réponse. C'est le format qui **s'allonge le plus avec le niveau**.
- `competence_code = 'co_document_question'`.
- SSML : intro (Denise) → document multi-voix (Henri/Vivienne) → question (Denise)
  → propositions (Denise).
- B1 (dialogue court de service) → B2 (monologue expositif long, inférence).

---

## Calibration par niveau

### A2
- Formats : **A (CO_IMAGE)** et **B (question/réponse)**.
- Document : scène de vie quotidienne (image) ou question simple isolée.
- Lexique : famille, repas, achats, transports, école, météo, santé.
- Compréhension **explicite** : la bonne réponse décrit littéralement l'image ou
  répond directement à la question.
- Distracteurs : nettement distincts (autres lieux/actions/moments).
- Exemple de paire (format B, original) :
  - Q : « Quel temps fait-il aujourd'hui ? »
  - A. Il a trente ans. (âge) · B. Il pleut depuis ce matin. ✅ (météo)
  - C. Il habite à Lille. (lieu) · D. Il part demain. (futur)

### B1
- Formats : **B** et **C** (dialogue court).
- Document : dialogue de service (2-4 répliques) — guichet, magasin, bureau, RDV.
  ~30-70 mots prononcés.
- Compréhension explicite + **inférence simple** : relier deux informations du
  dialogue (ex. déduire le moyen de paiement final, la décision prise).
- Distracteurs : thématiquement proches (tous liés au contexte).
- Exemple (format C, original, inspiré du format officiel « paiement ») :
  - Dialogue : un client veut payer par un moyen refusé, on lui propose des
    alternatives, il finit par en choisir une.
  - Q : « Comment le client va-t-il finalement payer ? »
  - 4 moyens de paiement plausibles, 1 seul cohérent avec la fin du dialogue.

### B2
- Format : **C** (monologue expositif/argumentatif long, ou dialogue dense).
- Document : ~120-200 mots prononcés. Présentation d'un service, d'une organisation,
  d'un point de vue, d'une situation professionnelle.
- Compréhension **implicite** : identifier le rôle/la fonction, l'intention du
  locuteur, l'idée principale, une conséquence non dite explicitement.
- Distracteurs : tous plausibles, formulés en reformulation (paraphrase) ; piège =
  confondre thème et propos, ou détail secondaire et idée principale.
- Exemple (format C, original) :
  - Monologue : présentation d'un organisme qui réalise des études pour aider des
    entreprises à s'implanter à l'étranger.
  - Q : « Quel est le rôle de cet organisme ? »
  - 4 reformulations abstraites ; la bonne synthétise la fonction réelle.

---

## SSML par format (gabarits)

**Format A (CO_IMAGE) :**
```xml
<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez les quatre propositions. Choisissez celle qui correspond à l'image.</prosody></voice><break time="1500ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>…<break time="700ms"/>B.<break time="300ms"/>…<break time="700ms"/>C.<break time="300ms"/>…<break time="700ms"/>D.<break time="300ms"/>…</prosody></voice></speak>
```

**Format B (question + réponses) :**
```xml
<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez la question et les quatre réponses. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">{question}</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>…<break time="700ms"/>B.<break time="300ms"/>…<break time="700ms"/>C.<break time="300ms"/>…<break time="700ms"/>D.<break time="300ms"/>…</prosody></voice></speak>
```

**Format C (document + question) :**
```xml
<speak version="1.0" xml:lang="fr-FR"><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">Écoutez le document puis la question. Choisissez la bonne réponse.</prosody></voice><break time="1500ms"/><voice name="fr-FR-VivienneNeural"><prosody rate="1.0">{réplique 1}</prosody></voice><break time="400ms"/><voice name="fr-FR-HenriNeural"><prosody rate="1.0">{réplique 2}</prosody></voice>…<break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">{question}</prosody></voice><break time="1000ms"/><voice name="fr-FR-DeniseNeural"><prosody rate="0.95">A.<break time="300ms"/>…<break time="700ms"/>B.<break time="300ms"/>…<break time="700ms"/>C.<break time="300ms"/>…<break time="700ms"/>D.<break time="300ms"/>…</prosody></voice></speak>
```

---

## `transcript_text` (version lisible affichée)

Reproduire le contenu de façon lisible, format :
```
Écoutez … Choisissez la bonne réponse.

[Femme] {réplique}     (ou [Homme] / la question)
[Homme] ...

A. {texte}
B. {texte}
C. {texte}
D. {texte}
```
(Pour CO_IMAGE : pas de réplique, juste l'intro + les propositions ; l'image est dans `inline_svg`.)

---

## Checklist spécifique CO

- [ ] Format choisi cohérent avec le niveau (A→A2 ; B→A2/B1 ; C→B1/B2).
- [ ] CO_IMAGE : `inline_svg` propre + `image_alt_text` ; SSML mono-voix (intro + propositions).
- [ ] B/C : SSML multi-voix équilibré ; document de longueur conforme au niveau.
- [ ] Distracteurs calibrés (distincts en A2, proches en B1, tous plausibles en B2).
- [ ] `status='TEXT_VALIDATED'`, `audio_url=NULL`, colonnes audio NULL.
- [ ] + checklist universelle du commun.
