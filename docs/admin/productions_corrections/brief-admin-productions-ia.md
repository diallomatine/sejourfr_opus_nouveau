# Brief Claude Code — Admin · Productions & corrections IA

## 0. Objectif

Ajouter dans l'Admin SejourFR un écran pour contrôler les productions (EE / EO) corrigées par IA.
Boucle visée : **repérer → ouvrir → comprendre → signaler**.

Question à laquelle l'écran doit répondre :
> « Pourquoi cette production a terminé B1 et pas A2 ou B2, et le candidat a-t-il reçu un feedback cohérent ? »

---

## 1. Règles de travail (valables pour tout le brief)

| Règle | Détail |
|---|---|
| Audit d'abord | Phase 0 en **lecture seule** : aucun fichier modifié hors du rapport d'audit. |
| Pas d'hypothèse | Tout ce qui n'est pas vérifié dans le code/la base est marqué `❓ à confirmer`. Ne jamais déduire une table, un champ ou un provider de ce brief. |
| Ne rien inventer | Afficher uniquement les critères, scores et champs **réellement** produits par le pipeline. Les exemples de ce brief sont illustratifs. |
| Réutiliser l'existant | Mêmes conventions que l'Admin actuel (routing, tableaux, pagination, filtres, design, auth). Pas d'architecture parallèle. |
| Lecture passive | Consulter une production ne doit **jamais** relancer une évaluation, appeler un LLM ni modifier une donnée. |
| Config externalisée | Toute valeur de config nouvelle (tarifs par token, seuils, taille de page…) va dans un JSON versionné, jamais en dur. |
| STOP | Respecter chaque `⛔ STOP`. Attendre un **GO** explicite. |

---

## 2. PHASE 0 — Audit (lecture seule)

### 2.1 Admin existant
Documenter : stack réelle de l'Admin, routes, layout/navigation, composant tableau, pagination (client ou serveur, format), filtres, recherche, gestion des rôles (front **et** back), client HTTP, conventions d'endpoints `/admin/**`.

### 2.2 Cartographie des données
Pour chaque ligne : **source exacte** (table.champ ou fichier), jointure nécessaire, statut `✅ / ❓ / ❌`.

| Domaine | Informations |
|---|---|
| Production | id, utilisateur (id + email), date, type EE/EO, tâche 1/2/3, sujet complet (titre, consigne, contexte), texte candidat, nb de mots |
| Oral | audio original stocké ? (où, clé R2, rétention), durée, transcription (outil réel, qui la produit, stockée ou non) |
| Évaluation IA | statut, scores par critère + barème, niveau éventuellement renvoyé par l'IA, JSON brut stocké ?, feedback (résumé, points forts, à améliorer, correction…) |
| Niveau final | champ persisté ou calculé à la lecture ? |
| Technique | provider, modèle, version du prompt, tokens in/out, coût, début/fin/durée, nb de tentatives, message d'erreur |

Points à trancher explicitement :
- Une production peut-elle avoir **plusieurs évaluations** (retry, ré-évaluation) ? Laquelle est montrée au candidat ?
- Le pipeline EO : enregistrement uploadé puis évalué, ou session temps réel ? L'audio et la transcription existent-ils réellement en base/stockage ?
- Le feedback affiché au candidat est-il le JSON IA brut, ou une version retravaillée côté backend ? (l'Admin doit voir **exactement** ce que le candidat a vu)

### 2.3 Chaîne de notation (point critique)
Pour **EE** puis **EO**, documenter :

```
prompt (fichier + version) → JSON attendu (schéma) → parsing/validation
→ calcul backend (formule, pondérations, seuils, arrondis) → niveau final → affichage candidat
```

- Où vivent les seuils (code, JSON, base) ? Existe-t-il plusieurs versions du calcul ? Les anciennes productions sont-elles recalculées avec la nouvelle version ?
- **Trace concrète obligatoire** : prendre 1 production EE et 1 EO réelles (base de dev, anonymisées) et dérouler le calcul pas à pas jusqu'au niveau affiché.

### 2.4 Sécurité & données personnelles
Contrôle des rôles côté backend sur les endpoints admin existants, mode d'accès à l'audio (URL signée ? durée ?), données sensibles exposées.

### 2.5 Livrable
Créer **uniquement** `docs/diagnostic/audit-admin-productions-ia.md` :

- **A. Disponible** — tableau `Information | Statut | Source | Remarque`
- **B. Manquant** — pour chaque élément : utilité, type de changement (`front` / `endpoint` / `backend` / `migration`)
- **C. Chaîne de notation** — EE et EO + les 2 traces concrètes
- **D. Architecture proposée** — endpoints (signature + DTO), composants/routes, solution minimale
- **E. Migrations proposées** — SQL en texte dans le rapport, **non créées**
- **F. Décisions à valider** — uniquement les vrais choix, chacun avec 2–3 options et une recommandation
- **G. Inconnues** — tout ce qui reste `❓`

### ⛔ STOP 1 — Attendre GO sur le rapport d'audit

---

## 3. PHASE 1 — Fonctionnalité cible

*À adapter selon l'audit : si une donnée n'existe pas, la masquer proprement (« non disponible »), ne pas la simuler.*

### 3.1 Navigation
Nouvelle entrée Admin : **Productions IA**.

### 3.2 Liste
- Pagination **serveur** (convention existante, défaut 50).
- Tri par défaut : **plus récentes d'abord**. Tris : date ↑↓, niveau, épreuve (coût/durée si trivial).
- Colonnes : `Date | Candidat | Épreuve | Tâche | Niveau | Statut IA | Signalement`
- Filtres : type (EE/EO), tâche (1/2/3), niveau (valeurs réellement supportées), statut IA (succès / erreur / en cours), signalement (toutes / signalées / non signalées), période (aujourd'hui / 7 j / 30 j / personnalisée).
- Recherche : email, ID utilisateur, ID production.
- Filtres + tri + page reflétés dans l'URL (partage d'un lien de diagnostic).
- Clic sur une ligne → détail.

### 3.3 Détail — blocs dans cet ordre
1. **Contexte** : candidat, email, ID production, date, épreuve, tâche, niveau final.
2. **Sujet** : exactement ce que le candidat a reçu.
3. **Réponse** : EE → texte exact + nb de mots. EO → lecteur audio, durée, transcription (libellée « transcription automatique », pas une retranscription fidèle).
4. **Évaluation IA** : scores bruts par critère avec barème (ex. `Grammaire : 2 / 4`).
5. **Calcul SejourFR** : niveau final + éléments du calcul (ex. `Score : 71/100 · Seuil B1 : 60–79`), séparé visuellement du bloc IA. Si l'IA renvoie aussi un niveau, afficher les deux et signaler un écart.
6. **Feedback candidat** : rendu tel qu'il a été vu par le candidat.
7. **Informations techniques** (repliable) : provider, modèle, version prompt, tokens, coût, durée, date, tentatives, erreur.
8. **JSON brut** (repliable) : réponse IA stockée, formatée, en lecture seule.

Valeurs techniques et calculs fournis par le backend, jamais recalculés côté front.

### 3.4 Signalement
- Bouton **⚠️ Signaler cette évaluation** → modale :
  - motif (obligatoire) : niveau incohérent · score incohérent · feedback incorrect · réponse mal comprise par l'IA · problème de transcription · autre
  - commentaire (facultatif)
- Après signalement : bandeau avec date, admin, motif, commentaire.
- Actions : **Marquer vérifié** / **Retirer**. Pas d'autre statut.
- Un signalement ne modifie **jamais** niveau, scores ni feedback.
- Modèle de données : à proposer dans l'audit (ex. option table dédiée vs colonnes sur l'évaluation).

### 3.5 Hors périmètre (MVP)
Workflow de tickets, assignation, fil de commentaires, correction/recalcul manuel du niveau, notification au candidat, export des productions signalées (envisageable plus tard).

### 3.6 Sécurité
- Endpoints sous le préfixe admin existant, rôle admin vérifié **côté backend** sur chaque endpoint.
- Audio servi uniquement par URL signée courte durée.
- Aucune de ces données exposée via les endpoints candidats.

---

## 4. PHASE 2 — Implémentation par lots (après GO)

| Lot | Contenu | Fin de lot |
|---|---|---|
| 1 | Migration(s) validée(s) + endpoints liste/détail en lecture + tests (droits, filtres, tri, pagination) | ⛔ STOP 2 |
| 2 | Écrans liste + détail | ⛔ STOP 3 |
| 3 | Signalement (back + front + tests) | Récap final |

À chaque STOP : fichiers modifiés, comment tester, écarts éventuels par rapport au rapport validé.

---

## 5. Critères d'acceptation

1. Accès refusé (403) à un non-admin sur **tous** les endpoints, testé.
2. Liste paginée côté serveur, plus récentes d'abord.
3. Filtres, tris et recherche fonctionnels et combinables.
4. Détail : sujet, réponse, audio + transcription (EO), scores, calcul du niveau, feedback candidat, infos techniques, JSON brut.
5. Toute donnée absente affichée « non disponible », jamais simulée.
6. Pour les 2 productions tracées pendant l'audit, l'écran permet de retrouver le niveau final à partir des scores affichés.
7. Signalement créé, conservé, visible dans la liste, marquable vérifié / retirable, sans effet sur le résultat candidat.
8. Ouvrir une production ne déclenche aucun appel IA ni écriture en base.
