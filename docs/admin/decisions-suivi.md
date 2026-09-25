# Chantier « Suivi » — journal des décisions

Chantier : remplacer `/dashboard` de l'admin par le dashboard « Suivi »
(`docs/admin/sejourfr-suivi-dashboard.html`), selon `docs/admin/brief-analytics-diagnostic.md`
et l'audit `docs/admin/audit-dashboard-analytics.md`.

**Principe directeur (propriétaire)** : un chiffre inconnu vaut mieux qu'un chiffre faux. Pas
d'attribution devinée, pas de backfill, `null` = inconnu (jamais 0). Pas de seconde vérité,
on étend l'existant.

**Mode d'exécution** : autonome, lots 1a → 4 puis 3b, sans STOP ; build + tests au vert et un
commit par lot. Toute décision prise en cours de route est consignée ci-dessous (§2), au fil
de l'eau, avec : contexte, options, choix et motif, fichiers impactés, difficulté de retour.

---

## 1. Arbitrages du propriétaire au STOP 0 (2026-09-25)

**Q1 — TVA.** `seller_vat_regime = FRANCHISE_293B`, en config versionnée.
- Stripe : `vat = 0` ; `net_ex_vat = net_after_fee = gross − fee`. Frais réel via
  `balance_transaction` en priorité, formule en repli (`fee_source = ESTIMATED`).
- Apple/Google : TVA retenue par le store (20 % FR, en config). Commission **MULTIPLY**, taux
  **par store** ; le propriétaire fournit les taux (0,15 ou 0,30) avant le lot 2.
- Exemples de test : Stripe 9,99 → vat 0, fee 0,40, net 9,59. Store 15 % → net 7,08.
  Store 30 % → net 5,83.

**Q2 — Tunnel TCF = `QUICK_TCF` uniquement.** Scénario 16 testé sur le civique.

**Q3 — `diagnostic_run` : OUI.** Trace du parcours uniquement, aucun contenu candidat.
- Run créée par un appel public dédié, idempotent, à l'affichage du sujet. L'étape 1 se compte
  **uniquement** sur `diagnostic_run` ; pas d'événement `DIAGNOSTIC_SUBJECT_VIEWED` en doublon.
- « Soumis » : une seule fois par run, la run doit exister, appel rate-limité.
- FK vers les sessions en `ON DELETE SET NULL`. `GuestAttemptPurgeJob` ne touche jamais
  `diagnostic_run`.

**Claim diagnostic.**
- À la création de la run, le serveur retourne `diagnosticRunId` + `claimToken` (aléatoire,
  forte entropie). Seul `claim_token_hash` est stocké.
- Le client conserve le `claimToken` avec le brouillon du diagnostic (IndexedDB /
  SharedPreferences). Il ne part **jamais** dans les événements analytics.
- Register / Login / Google / Apple transmettent `diagnosticRunId` + `claimToken`. Claim dans la
  transaction d'auth, `claim_kind = SIGNUP | LOGIN`, `signup_context` posé au même moment.
- Aucune recherche heuristique par `anonymous_id`. Le runId est un identifiant, pas un secret.
- Compte ayant déjà son diagnostic : la run est quand même claimée ; le contenu est refusé
  comme aujourd'hui.
- Ce même `claimToken` sert au lien web → app du lot 3b.

**Q4 — En-têtes** : `X-Sejourfr-Anonymous-Id`, `X-Sejourfr-Client` (`web|ios|android`),
`X-Sejourfr-App-Version`.

**Q5 — Rétention 395 j**, purge au lot 1b. Justification corrigée : 13 mois = durée de vie du
**traceur**, pas une limite CNIL générale sur les données. `/confidentialite` mise à jour dans
la même passe. Vérification RGPD du rattachement visiteur → compte : côté propriétaire, non
bloquante.

**Q6 — `users.is_internal` : OUI, seule autorité.** Initialisé depuis `excluded-emails`, puis la
liste YAML est supprimée.

**Q7 — Visiteurs uniques et sources : inclus.** « Utilisation du plan » reporté au brief suivant,
**sans proxy ni bloc « bientôt »**.

**Q8 — `plan_id = journey.id`.** Le serveur résout journey → `diagnostic_run` fondateur
lui-même, sans faire confiance au runId envoyé par le client.

**Q9 — Suppression de l'ancien dashboard acceptée.** Données déjà collectées conservées si elles
ne coûtent rien.

**Q10 — Supprimer le code sans appelant, garder les tables.**

**Q11 — Bugs paiement : OUI, au lot 2, avant les KPI de revenu.**
- `rawPrice` / `amountCents` ;
- anti-rejeu Stripe ;
- remboursement partiel ;
- `payment_status` ;
- prix Apple lu depuis le JWS ; prix Google borné par le catalogue.

**Q12 — Purchase intent, pas d'attribution automatique à la run la plus récente.**
- Une `purchase_intent` serveur est créée avant **chaque** démarrage d'achat, quel que soit le
  CTA : `user_id`, `cta_location`, `product_id`, `journey_id`, `diagnostic_run_id` (résolu
  serveur), `created_at`, `consumed_at`. TTL 24 h en config, usage unique.
- Transport : Stripe `metadata.intentId`. Apple/Google : **ne pas détourner**
  `appAccountToken` / `obfuscatedAccountId` / `obfuscatedProfileId` (identité du compte). Le
  mobile persiste le `purchaseIntentId` (indexé par `productId`) avant d'ouvrir le paiement,
  l'envoie avec verify-receipt, et le réutilise si l'achat est rejoué au lancement suivant.
- Vérification backend : appartient au user, même produit, non expirée, non consommée.
- Intention perdue / expirée / invalide : `origin = UNKNOWN`, `diagnostic_run_id = null`.
  Aucune reconstruction heuristique.
- `origin = DIAGNOSTIC_PLAN | OTHER_CTA | UNKNOWN`. Obligatoire au lot 2.

**Q13 — Template avec filtre Tous / TCF / Civique**, pas de tableau 3 colonnes. Les 3 sous-lignes
de « Compte rattaché », ratios en bloc secondaire, activité en dessous.

**Q14 — Lien web → app : lot 3b séparé, non bloquant.**

**Q15 — File mobile SharedPreferences bornée**, validé.

**Q16 — Aucun backfill.** La réponse indique la **date de début de mesure** de chaque indicateur ;
avant cette date, l'indicateur vaut `null`.

**Q17 — Ingestion en lot : OUI.** L'unitaire est conservé pendant la bascule, puis retiré.

**Scénarios ajoutés au brief §12.**
- **18** : achat sans intention → `UNKNOWN`, hors tunnel. Achat via un autre CTA → `OTHER_CTA`.
  Intention déjà consommée, expirée ou d'un autre user → rejetée → `UNKNOWN`.
- **19** : après la purge des invités, les runs et le compteur « jamais rattachés » sont intacts.
- **20** : claim avec un runId valide mais un `claimToken` absent ou faux → pas de claim.

**Template.** Respecter au maximum `docs/admin/sejourfr-suivi-dashboard.html` (mise en page,
ordre et contenu des blocs, densité, libellés, comportement des filtres). Seuls écarts autorisés,
chacun noté ci-dessous : les ajouts décidés (3 sous-lignes, bloc ratios, bloc activité,
remboursements) ; « Apple » → « iOS » ; couleurs et typographies de la charte admin.

---

## 2. Décisions prises en autonomie pendant l'exécution

Format : **Dn — titre** · Lot · Contexte · Options · Choix et motif · Fichiers · Difficulté de
retour (faible / moyenne / forte).

<!-- Les agents ajoutent leurs décisions ici, dans l'ordre. -->

---

## 3. Récapitulatif final

_(rempli en fin de chantier : lots livrés, état des 20 scénarios, points ouverts, actions du
propriétaire)_
