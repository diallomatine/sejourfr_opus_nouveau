# GUIDE EE — Expression écrite (Tâches 1/2/3, niveaux A2/B1/B2)

> À utiliser avec `GUIDE_00_COMMUN_conventions.md`. L'EE génère deux choses :
> 1. des **sujets** (lignes de `production_tasks`) que le candidat traite ;
> 2. des **exemples-modèles** (`production_examples`) que le candidat consulte.

---

## Rappel des 3 tâches EE (officiel TCF IRN)

| Tâche | Nature | Mots min/max | Déclencheur |
|---|---|---|---|
| Tâche 1 | Message court (répondre à un proche) | **30-60** | SMS / message d'un ami |
| Tâche 2 | Récit (raconter une expérience) | **60-90** | message demandant un récit |
| Tâche 3 | Avis argumenté (forum) | **60-90** | question d'opinion sur un forum |

Le candidat **doit** respecter les bornes de mots : la soumission est refusée hors plage,
elle n'est pas envoyée au correcteur et ne reçoit pas artificiellement « A1 non atteint ».

---

## A) Génération des SUJETS (`production_tasks`)

Chaque sujet = une ligne. Champs :
```
epreuve='TCF_EE', tache_numero (1|2|3), niveau_cible (indicatif, nullable),
consigne,            -- la tâche à accomplir
contexte,            -- mise en situation
declencheur (jsonb), -- le message reçu : {expediteur, avatar, texte}
mots_min, mots_max,  -- 30/60 (T1) ; 60/90 (T2 et T3)
duree_max_sec=NULL, is_active=true
```

### Déclencheur (`declencheur`) selon la tâche
- **T1** : un proche écrit un message court appelant une réponse (invitation,
  demande de description, nouvelle à donner). Ex. `{"expediteur":"Karim","avatar":"K","texte":"…"}`.
- **T2** : un proche demande le récit d'un événement (« Comment s'est passé… ? »).
- **T3** : une question d'opinion façon forum (« Vous préférez X ou Y ? Expliquez. »).

### Calibration des sujets par niveau (difficulté indicative)
- **A2** : situations très concrètes et familières (anniversaire, déménagement,
  sortie, description d'un ami). Vocabulaire quotidien.
- **B1** : situations un peu plus riches (organiser à plusieurs, raconter un
  voyage, donner un avis sur un choix de vie). Demande connecteurs et nuances.
- **B2** : sujets ouvrant sur l'abstraction et l'argumentation (questions de
  société, choix de mode de vie, débats du quotidien).

> Produire ~10 sujets par tâche, variés (thèmes, profils, contextes). Le
> `niveau_cible` répartit indicativement la difficulté, sans jamais filtrer le candidat.

---

## B) Génération des EXEMPLES-MODÈLES (`production_examples`)

Réponses modèles rattachées à la tâche (`task_id`), avec **explications
pédagogiques**. Champs :
```
task_id, titre, resume, contenu, explications, plan_points (jsonb),
niveau_indicatif ('A2'|'B1'|'B2'), display_order
(audio_url, ssml_text : NULL pour l'EE — pas d'audio en écrit)
```

### Calibration des modèles par niveau
Les exemples illustrent la **progression** du simple au riche. Sur ~10 exemples
par tâche, viser 3 A2 / 3-4 B1 / 3 B2.

**Tâche 1 (30-60 mots)** — message court :
- A2 : salutation + réponse directe + clôture simple. Phrases courtes, présent.
- B1 : + une nuance, une émotion, une question de relance. Passé composé/futur.
- B2 : registre maîtrisé (formel ou affectif selon le destinataire), formules
  idiomatiques, tact (refus poli, reproche nuancé au subjonctif).

**Tâche 2 (60-90 mots)** — récit :
- A2 : succession d'actions au passé composé, repères temporels simples, opinion finale.
- B1 : passé composé + imparfait (décor/émotions), structure (situation → déroulé →
  ressenti), connecteurs (d'abord, ensuite, finalement).
- B2 : récit nuancé (plus-que-parfait, conditionnel passé), analyse personnelle,
  leçon tirée, lexique précis.

**Tâche 3 (60-90 mots)** — avis argumenté :
- A2 : position claire + deux raisons simples + conclusion.
- B1 : position + deux arguments illustrés d'exemples + concession (« c'est vrai
  que… mais »).
- B2 : thèse nuancée, objection anticipée et réfutée, connecteurs concessifs,
  subjonctif, conclusion ouverte.

### `plan_points` (jsonb)
Liste courte de la structure de la réponse modèle, ex :
```json
["Salutation + remerciement", "Réponse à l'invitation", "Proposition de moment", "Question pratique", "Clôture"]
```

### `explications` (pédagogique)
Expliquer **ce qui rend la réponse réussie** : temps employés, connecteurs,
respect des bornes de mots, tournures à imiter. Ex. « Remarquez l'emploi du passé
composé pour les actions et de l'imparfait pour le décor ; la réponse fait 78 mots,
dans les bornes 60-90. »

---

## Règle de comptage des mots (rappel)

1 mot = ensemble de signes entre deux espaces. **Toujours vérifier** que chaque
exemple respecte les bornes de sa tâche (T1 : 30-60 ; T2/T3 : 60-90) et l'indiquer
dans le `resume` (ex. « ≈78 mots »).

---

## Exemples de déclencheurs originaux (à varier)

- T1 : « Salut ! Alors, ce nouveau travail ? Raconte ! » / « Coucou, tu viens à mon
  anniversaire samedi ? »
- T2 : « Comment s'est passé ton week-end à la montagne ? » / « Raconte-moi ta
  première journée de cours ! »
- T3 : « Faut-il limiter les écrans des enfants ? Donnez votre avis. » / « Vaut-il
  mieux vivre en ville ou à la campagne ? »

---

## Checklist spécifique EE

- [ ] Sujets : `epreuve='TCF_EE'`, bonnes bornes de mots (30-60 / 60-90), contexte/destinataire explicite en T2/T3, déclencheur jsonb.
- [ ] ~10 sujets variés par tâche ; `niveau_cible` indicatif réparti.
- [ ] Exemples : `contenu` **dans les bornes** de la tâche (compté), `explications` utiles.
- [ ] Gradation A2/B1/B2 visible dans les exemples (temps, connecteurs, registre).
- [ ] `audio_url`/`ssml_text` NULL (écrit).
- [ ] + checklist universelle du commun.
