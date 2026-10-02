# Spec MVP — Admin / Gestion des utilisateurs (V2)

> Brief Claude Code. Audit d'abord, implémentation ensuite, avec des points STOP obligatoires.
> Les URLs, noms de tables et noms de classes cités sont **indicatifs** : suivre les conventions existantes du monorepo.

---

## 0. Déroulé et points STOP

| Phase | Contenu | Fin de phase |
|---|---|---|
| 1 | Audit de l'existant (§3), sans aucune modification | 🛑 **STOP 1** : rapport d'audit, attendre le GO |
| 2 | Backend : modèle, migrations, calcul d'accès, API admin, tests | 🛑 **STOP 2** : récapitulatif et tests verts, attendre le GO |
| 3 | Frontend admin : liste, fiche, actions | 🛑 **STOP 3** : démo des 8 cas du §11 |

**Pendant la phase 1, il est interdit de :** modifier du code, créer une migration, toucher au schéma, créer un endpoint, modifier un accès ou un achat existant, commiter.

---

## 1. Objectif

Ajouter une page admin **Utilisateurs** pour **retrouver, comprendre et dépanner** un utilisateur.
Il ne s'agit **pas** d'un CRM.

L'administrateur doit pouvoir :

- rechercher un utilisateur et ouvrir sa fiche ;
- voir ses accès effectifs (0..n produits), leurs dates et leur origine ;
- voir ses achats réels (lecture seule) ;
- voir sa progression principale (données déjà disponibles uniquement) ;
- donner, prolonger, raccourcir, terminer ou réactiver un accès ;
- corriger un produit acheté par erreur (ex. Civique → TCF) ;
- tracer chaque modification (qui, quand, avant/après, motif).

---

## 2. Modèle métier cible

### 2.1 Principe : achat ≠ accès effectif

| Notion | Définition | Modifiable par l'admin ? |
|---|---|---|
| **Achat** | Ce que l'utilisateur a réellement payé (Stripe, Apple, Google Play). | ❌ Jamais. Immuable côté admin. |
| **Override admin** | Décision manuelle `GRANT` ou `REVOKE` pour un produit, sur une fenêtre de temps. | ✅ |
| **Accès effectif** | Résultat calculé à l'instant *t* à partir des achats et des overrides. | Calculé, jamais stocké à la main. |

Le modèle tarifaire est un **achat unique sans reconduction**. Il n'y a pas de logique de renouvellement à créer. Si l'audit trouve des abonnements store auto-renouvelables, il doit le signaler.

### 2.2 Override admin (concept)

Champs conceptuels, à adapter si l'existant offre déjà un équivalent :

```text
userId
product          -> valeurs issues de l'enum produit existant (TCF, CIVIQUE, ...)
type             -> GRANT | REVOKE
startsAt         -> instant
endsAtExclusive  -> instant ; obligatoire pour GRANT, nullable pour REVOKE (null = sans fin)
reason           -> texte obligatoire
createdBy        -> admin (lu depuis le contexte de sécurité)
createdAt
supersededAt / supersededBy -> quand un override est remplacé par un autre (rien n'est jamais supprimé)
operationId      -> regroupe les overrides créés par une même action admin (ex. correction de produit)
```

**Invariant : au plus un override courant (non remplacé) par couple (user, produit).**
Toute modification remplace l'override courant (`supersededAt`) et en crée un nouveau. L'historique est ainsi conservé sans conflit entre plusieurs overrides.

### 2.3 Règle de calcul de l'accès effectif

Pour un couple (user, produit) à l'instant *t* :

```text
override = override courant du couple, s'il couvre t (startsAt <= t < endsAtExclusive, ou endsAtExclusive null)

si override est un GRANT :
    accès = OUI

sinon si override est un REVOKE :
    accès = OUI uniquement s'il existe un achat valide à t effectué APRÈS override.createdAt
    sinon accès = NON

sinon (aucun override applicable) :
    accès = OUI s'il existe un achat valide à t, sinon NON
```

La clause « achat effectué après le REVOKE » est **essentielle** : un REVOKE ne doit jamais bloquer un nouvel achat légitime. Exemple : on révoque Civique, l'utilisateur rachète Civique un mois plus tard, il doit y avoir accès.

**Exigences :**

- Ce calcul doit vivre dans **un seul service backend**, utilisé par **tous** les contrôles d'accès (API utilisateur, app web, app mobile). Il ne doit exister aucune logique parallèle côté front.
- Les webhooks Stripe, les RTDN Google Play et la validation des reçus Apple **ne lisent ni n'écrivent jamais** les overrides. Ils ne gèrent que les achats.
- Un remboursement invalide l'achat concerné mais **ne touche pas** un GRANT existant, qui reste une décision admin explicite. La fiche doit alors afficher l'alerte « Achat remboursé ».

### 2.4 Statuts affichés (par produit)

| Statut | Condition |
|---|---|
| **Actif** | accès = OUI à maintenant |
| **Programmé** | accès = NON maintenant, mais un GRANT démarre dans le futur |
| **Expiré** | accès = NON, avec au moins un achat ou GRANT passé |
| **Révoqué** | accès = NON à cause d'un REVOKE courant |
| **Aucun** | jamais eu d'achat ni de GRANT |

Le statut est calculé par le backend et renvoyé dans le DTO. Le front ne le recalcule jamais.

### 2.5 Dates

| Aspect | Règle |
|---|---|
| Saisie et affichage UI | Date métier **inclusive** : « Fin : 31/10/2026 inclus » |
| Stockage | Borne de fin **exclusive** : `01/11/2026 00:00 Europe/Paris`, convertie en instant (`timestamptz`) |
| Début | « Aujourd'hui » = maintenant ; une date future = 00:00 Europe/Paris ce jour-là |
| Conversion | Côté backend uniquement |
| Éviter | les valeurs `23:59:59` et tout calcul de date côté front |

Si l'audit montre une autre convention déjà généralisée dans le backend, la signaler et proposer l'alignement le plus sûr.

### 2.6 Traduction des actions admin en overrides (proposition)

| Action admin | Situation | Override créé (remplace l'override courant) |
|---|---|---|
| **Donner un accès** | aucun accès | `GRANT [début, fin+1j)` |
| **Prolonger** | accès issu d'un achat | `GRANT [maintenant, nouvelle fin+1j)` |
| **Prolonger / raccourcir** | accès issu d'un GRANT | nouveau `GRANT` avec la nouvelle fin |
| **Raccourcir** | nouvelle fin < fin de l'achat | `REVOKE [nouvelle fin+1j, ∅)` |
| **Terminer** | accès actif | `REVOKE [maintenant, ∅)` |
| **Réactiver** | accès expiré ou révoqué | `GRANT [début, fin+1j)` |
| **Corriger le produit A → B** | A actif | **Atomique**, même `operationId` et même motif : `REVOKE A [maintenant, ∅)` + `GRANT B [maintenant, fin actuelle de A +1j)` |

L'audit peut proposer une traduction équivalente plus simple si l'existant le permet. Les règles du §2.3 et l'invariant du §2.2 restent non négociables.

**Correction de produit :**

- La date de fin proposée par défaut est celle de A ; elle reste modifiable.
- L'opération est tracée comme **une seule** entrée dans l'historique admin.
- Si l'utilisateur possède un pack ou un autre achat couvrant B, l'audit doit en vérifier les conséquences.

---

## 3. Phase 1 — Audit (aucune modification)

### 3.1 Points à identifier

1. Le modèle `User` : champs disponibles (nom, statut du compte, dernière connexion).
2. L'authentification, le rôle ADMIN et le mécanisme d'autorisation admin existant.
3. Les tables d'achats, de pass et d'abonnements (ex. `Plan`, `UserSubscription`) pour **Stripe, Apple IAP et Google Play**.
4. **L'endroit exact où l'accès TCF, Civique ou autre est calculé aujourd'hui.** Ce calcul est-il centralisé ou dupliqué ?
5. Les enums de produits et la granularité réelle : produit seul (TCF), ou niveau/mention (TCF B1, Civique NAT) ? Existe-t-il des packs ?
6. Les dates utilisées (début, fin, expiration), leur type SQL et la convention timezone.
7. **Le comportement des webhooks Stripe, des RTDN Google Play et de la validation/restauration des reçus Apple** : recalculent-ils, écrasent-ils ou suppriment-ils des droits ? C'est le point critique pour la survie des overrides.
8. Le traitement actuel des remboursements.
9. La présence d'un mécanisme proche d'un override, d'un entitlement ou d'un accès manuel.
10. Les caches d'accès : claims JWT, cache Drift côté mobile offline-first, cache du front web. Délai réel avant qu'un changement soit vu par l'utilisateur.
11. Les risques de concurrence : admin contre webhook, admin contre admin. Les transactions et contraintes actuelles suffisent-elles ?
12. L'existence d'un audit log générique réutilisable.
13. Les APIs admin, la pagination, les composants et les pages admin réutilisables.
14. Les données de progression **déjà** facilement accessibles : diagnostics, niveau, plan actif, cycle, dernière activité.
15. L'existence d'une notion de « dernière activité » stockée ; sinon, le coût d'un calcul par ligne.

### 3.2 Format du rapport

**A. État actuel** — ce qui existe.

**B. Matrice des écarts** — une ligne par fonctionnalité de cette spec :
✅ disponible · 🟠 partiel · 🔴 à développer · 🗄 migration probable

**C. Modèle recommandé** — comment appliquer le §2 sur l'existant : réutilisation, nouvelle table ou extension.

**D. Migrations** — pour chacune : pourquoi, table, colonnes, index, contraintes (dont l'invariant du §2.2), impact sur les données existantes. **Ne rien écrire avant le GO.**

**E. Plan d'implémentation** — fichiers et couches concernés : backend, base, API, admin front, tests.

**F. Verdict** — ✅ faisable tel quel · 🟠 petites évolutions · 🔴 changement structurel.

**G. Points ouverts** — décisions à trancher par moi, sous forme d'options.

🛑 **STOP 1 — attendre le GO.**

---

## 4. Écran — Liste des utilisateurs

Route indicative : `/admin/users`.

### Colonnes

| Colonne | Exemple | Remarque |
|---|---|---|
| Utilisateur | Jean Dupont | ou l'email si pas de nom |
| Email | jean@email.com | |
| Inscription | 21/09/2026 | |
| Accès | `TCF · Actif` `Civique · Expiré` | un badge par produit, couleur selon statut |
| Prochaine fin | 21/10/2026 | fin la plus proche parmi les accès actifs |
| Dernière activité | 29/09/2026 | **seulement si la donnée est stockée**, sinon absente de la liste |
| Statut compte | Actif | seulement si la notion existe |

### Recherche

Par email, par nom si disponible, et par ID utilisateur.

### Filtres

| Filtre | Signification |
|---|---|
| Tous | |
| Accès TCF actif | accès effectif TCF = OUI maintenant |
| Accès Civique actif | accès effectif Civique = OUI maintenant |
| Sans accès actif | aucun produit actif (inclut les expirés et les jamais-payants) |
| Expiré | au moins un accès passé et aucun actif |
| Accès manuel | un override courant existe |
| Compte bloqué | seulement si la notion existe |

### Pagination

Utiliser la pagination serveur existante. Ne jamais charger tous les utilisateurs d'un coup. Les filtres sur l'accès effectif doivent rester performants : l'audit doit proposer la stratégie de requête.

---

## 5. Écran — Fiche utilisateur

Route indicative : `/admin/users/{id}`. Blocs dans cet ordre :

### 5.1 Résumé (lisible en 5 secondes)

```text
Jean Dupont — jean@email.com
Inscrit le 21/09/2026 · Dernière activité : aujourd'hui
TCF : actif jusqu'au 21/10/2026 inclus (Admin)
Civique : révoqué le 30/09/2026
```

### 5.2 Accès

Un bloc par produit connu de l'enum, y compris le statut « Aucun » :

| Champ | Exemple |
|---|---|
| Produit | TCF |
| Statut | Actif |
| Début / Fin incluse | 21/09/2026 → 21/10/2026 |
| Origine | Achat Stripe / Achat Apple / Achat Google Play / Admin (GRANT) / Admin (REVOKE) |
| Alerte éventuelle | « Achat remboursé », « Révocation programmée le 05/11 » |

Actions visibles sur chaque bloc : **Modifier l'accès** (action principale), **Terminer**, **Corriger le produit**. Un bouton global **Donner un accès** est aussi affiché.

### 5.3 Historique des achats (lecture seule)

Produit, montant, date, plateforme (Stripe / Apple / Google Play), statut (payé, remboursé…), référence externe tronquée.

### 5.4 Progression (données existantes uniquement)

- **TCF** : diagnostic fait ou non, niveau, plan actif, progression du cycle, dernière activité TCF.
- **Civique** : diagnostic fait ou non, progression principale, dernière activité.

Toute donnée qui demande une requête complexe est **sortie du MVP** et signalée dans l'audit.

### 5.5 Compte

ID, email, nom, date de création, dernière connexion, statut. Lecture seule.

### 5.6 Historique admin

```text
30/09/2026 14:12 — admin@sejourfr.fr
Correction de produit : CIVIQUE → TCF
CIVIQUE : actif jusqu'au 30/10 → révoqué
TCF : aucun → actif jusqu'au 30/10/2026 inclus
Motif : erreur de produit lors de l'achat
```

---

## 6. Modale d'action

Il y a une seule modale, avec un mode selon l'action.

| Champ | Règle |
|---|---|
| Produit | liste issue du backend (enum existant), jamais codée en dur dans le front |
| Début | par défaut aujourd'hui ; modifiable uniquement pour un GRANT |
| Fin (incluse) | obligatoire pour donner, réactiver, prolonger ou corriger |
| Motif | **obligatoire**, 3 à 500 caractères |
| Aperçu | phrase calculée **par le backend** (endpoint de prévisualisation ou réponse de dry-run) |

### Validations backend

- fin ≥ début ;
- fin ≥ aujourd'hui pour un GRANT ;
- produit valide ;
- utilisateur existant ;
- motif non vide.

### Confirmation obligatoire (seconde étape) avant :

- une correction de produit : « Vous allez retirer l'accès Civique et donner l'accès TCF jusqu'au 30/10/2026 inclus. »
- une réduction de date ;
- une fin immédiate : « Cet utilisateur perdra immédiatement son accès TCF. Continuer ? »

Boutons : **Annuler** / **Confirmer**.

---

## 7. Historique administratif

- **Obligatoire** pour chaque action du §2.6.
- Champs : admin, date, opération, valeur avant, valeur après, motif, `operationId`.
- Si un audit log générique existe, le réutiliser. Sinon, la table des overrides (jamais supprimés, toujours remplacés) peut servir d'historique : l'audit doit trancher.
- L'admin est **toujours** lu depuis le contexte de sécurité, jamais depuis la requête.

---

## 8. API (fonctionnelle, conventions à suivre)

| Besoin | Indicatif |
|---|---|
| Liste | `GET /admin/users?q=&filter=&page=&size=` |
| Détail | `GET /admin/users/{userId}` : compte, accès par produit, achats, progression, historique admin |
| Produits disponibles | `GET /admin/products` (ou équivalent existant) |
| Action d'accès | `POST /admin/users/{userId}/access-operations` |

Exemple de corps pour une action d'accès :

```json
{
  "operation": "GRANT | EXTEND | SHORTEN | END | REACTIVATE | CORRECT_PRODUCT",
  "product": "TCF",
  "fromProduct": "CIVIQUE",
  "startDate": "2026-09-30",
  "endDateInclusive": "2026-10-30",
  "reason": "Erreur de produit lors de l'achat",
  "dryRun": false
}
```

- `dryRun: true` renvoie l'aperçu et l'état résultant, sans rien écrire.
- La réponse contient le nouvel état des accès de l'utilisateur, calculé par le service unique.
- Chaque opération s'exécute dans **une transaction**. Une correction de produit est tout ou rien.

### Concurrence

Si l'audit montre un risque réel (webhook et admin sur la même ressource, deux admins), ajouter un verrou optimiste (`version` ou équivalent). Sinon, une transaction et la contrainte d'unicité de l'override courant suffisent.

---

## 9. Sécurité

- Toutes les routes `/admin/**` sont réservées au rôle ADMIN, avec le mécanisme existant.
- Requête non authentifiée : **401**. Utilisateur non admin : **403**. Utilisateur introuvable : **404**.
- Les DTO admin n'exposent jamais : hash de mot de passe, tokens, secrets de paiement, identifiants de paiement complets.
- Aucune action admin ne déclenche de paiement, ne crée de transaction, ne modifie de montant ni ne réécrit un achat.

---

## 10. Effet sur l'application utilisateur

- Un accès accordé par l'admin fonctionne **exactement** comme un accès acheté, via le service unique du §2.3.
- Le changement est visible **au prochain appel API**. S'il existe un cache (claims JWT, cache front), l'invalider ou le limiter. L'audit précise le mécanisme.
- **Mobile offline-first** : un appareil hors ligne peut conserver l'ancien état jusqu'à sa prochaine synchronisation. Ce comportement est accepté pour le MVP, mais doit être documenté dans le rapport.

---

## 11. Cas de test

| # | Situation | Action | Résultat attendu |
|---|---|---|---|
| 1 | Utilisateur gratuit | Donner TCF jusqu'au 31/10 | TCF actif immédiatement, origine Admin |
| 2 | Civique acheté (Stripe) jusqu'au 30/10 | Corriger Civique → TCF | Civique révoqué, TCF actif jusqu'au 30/10 ; achat Civique intact ; une seule entrée d'historique |
| 3 | TCF actif jusqu'au 10/10 | Prolonger au 31/10 | Actif jusqu'au 31/10 inclus |
| 4 | TCF expiré | Réactiver jusqu'au 30/11 | Actif |
| 5 | Achat Stripe, Apple ou Play | Toute action admin | Aucune transaction ni aucun achat modifié |
| 6 | Override admin en place | **Webhook Stripe, RTDN Play ou restauration Apple rejoué** | L'override reste en place, l'accès effectif ne change pas |
| 7 | Civique révoqué | L'utilisateur **rachète** Civique | Civique actif (le REVOKE ne bloque pas un nouvel achat) |
| 8 | TCF et Civique actifs | Terminer TCF uniquement | TCF révoqué, Civique inchangé |
| 9 | Achat jusqu'au 15/11 | Raccourcir au 05/11 | Actif jusqu'au 05/11 inclus, puis Révoqué |
| 10 | Aucun accès | GRANT qui démarre le 15/10 | Statut Programmé, pas d'accès avant le 15/10 |
| 11 | GRANT en cours | Achat associé remboursé | GRANT conservé, alerte « Achat remboursé » |
| 12 | Fin le 31/10 inclus | Vérifier le 31/10 à 23:30 puis le 01/11 à 00:01 (Paris) | Accès OUI, puis NON |
| 13 | Fin < début, motif vide, produit inconnu | Appel API | 400 avec message clair |
| 14 | Non authentifié / non admin / user inexistant | Appel API admin | 401 / 403 / 404 |
| 15 | Correction de produit qui échoue à mi-parcours | Erreur simulée sur le GRANT | Rollback : le REVOKE n'est pas persisté |

---

## 12. Critères de validation

1. Je retrouve un utilisateur par email, nom ou ID.
2. Je vois tous ses accès, leur statut, leur fin incluse et leur origine.
3. Je vois ses achats réels, distincts de ses accès.
4. Je peux donner, prolonger, raccourcir, terminer et réactiver un accès.
5. Je peux corriger un produit de façon atomique.
6. Un override survit aux webhooks et aux restaurations d'achat.
7. Un REVOKE ne bloque jamais un nouvel achat.
8. L'app utilisateur reconnaît le nouvel état au prochain appel API.
9. Toutes les actions sont réservées aux admins et tracées avec un motif.
10. Aucun achat ni aucune transaction n'est modifié.
11. Aucun système parallèle n'est créé lorsqu'une brique existante convient.
12. Les cas 1 à 15 du §11 passent.

---

## 13. Hors MVP

CRM, notes internes, emails en masse, segmentation, statistiques avancées, graphiques, impersonation, remboursement ou modification de paiement depuis l'admin, édition du profil, suppression d'utilisateurs, blocage de compte (sauf s'il existe déjà), export CSV (sauf s'il est trivial).
