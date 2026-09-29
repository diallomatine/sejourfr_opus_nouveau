# Chantier « Suivi » — passe de contrôle (2026-09-25)

Passe en **lecture seule** sur les commits `38400e1b` → `66aaddec` (branche
`feature/refonte-l1-socle`) : aucun code modifié. Trois contrôles parallèles (paiements,
`diagnostic_run`, clients). Ne sont remontés que les points qui peuvent **(1)** produire des
données fausses, **(2)** créer un risque sécurité / paiement / RGPD, **(3)** être difficiles à
corriger après la mise en production. Preuves `fichier:ligne` ; **VÉRIFIÉ** = lu dans le code,
**SUPPOSÉ** = à confirmer hors code.

Arbitrages et décisions de référence : `docs/admin/decisions-suivi.md`.

---

## 0. Synthèse

**Bloquants de déploiement (4)**

| # | Point | Pourquoi bloquant | Coût |
|---|---|---|---|
| B | SEPA possible dans le Checkout sans `async_payment_succeeded` abonné | client prélevé, accès jamais ouvert | 15 min (Dashboard) + 1 h si restriction code |
| N1 | Ingestion unitaire supprimée alors que l'app publiée l'utilise | fausse chute des visiteurs et sources dès le déploiement backend | ≈ 1 h (revert partiel de `2988a6dd`) |
| E + F | Claim d'un tiers sur appareil partagé ; vieille run d'invité réutilisée pour un diagnostic connecté | attribution et cohortes fausses, rattachement du parcours d'un tiers (RGPD) | ≈ 6 h, sans migration |
| G | Anciennes apps / anciens onglets → `OUTSIDE_DIAGNOSTIC` alors que le diagnostic a eu lieu | donnée fausse (pas inconnue) sur l'indicateur d'inscription | ≈ 2 h (+ 4–6 h pour la version minimale) |

**À faire avant publication de l'app (figé sinon jusqu'à la version suivante)** : F (CTA sur les
403), N2 (source `direct` fabriquée pour le mobile, correctif côté écriture), G-a (version minimale).

**Hautes, non bloquantes** : C (abandon civique compté « soumis »), taux de commission figé
ligne à ligne (voir N4).

**Réponses courtes aux 7 questions**

| Q | Risque réel | Gravité | Correctif |
|---|---|---|---|
| A | Non pour le crédit (sûr par construction) ; **oui, étroit**, pour les remboursements concurrents | moyenne | `ON CONFLICT DO NOTHING` + verrou de ligne sur l'achat |
| B | **Oui si SEPA est actif dans le Dashboard** (le code n'impose aucun moyen) | **bloquant** | abonner `async_*` ; restreindre à la carte ou désactiver SEPA |
| C | **Oui** — prémisse corrigée : pas d'échéance civique, mais « Quitter » confirmé = soumis, même à 0 réponse | haute | figer le nombre de réponses à l'écriture, seuil en config (V076) |
| D | Pas de perte ; **doublons** possibles (web sans stockage) | basse | compteur « runs sans identifiant » servi |
| E | **Oui** (web et mobile, et le rejeu repousse l'expiration) | **haute** | borne serveur : TTL court ancré sur `subject_viewed_at` |
| F | **Oui**, plus large que prévu : le web fabrique des `OTHER_CTA` faux | moyenne (figée par la version de l'app) | CTA obligatoire à chaque appel, `LOCKED_PLAN` sur marqueur de route |
| G | **Oui** | haute | `signup_context = null` pour un client ancien (option b) + version minimale (a) |

---

## 1. Les 7 points demandés

### A. Un échec de calcul ou de CHECK peut-il empêcher le crédit d'un achat payé ?

**Crédit d'achat — risque réel : non** (VÉRIFIÉ). La sûreté vient de la construction, pas d'un
filet :
- l'invariant `gross = vat + fee + net_ex_vat` tient algébriquement dans les deux formules
  (`RevenueCalculator.java:58-77`) ; le `throw` de `RevenueBreakdown.java:25-27` est
  inatteignable ; frais Stripe > brut → repli formule (`:61-64`) ; devise sans taux →
  décomposition sautée (`OneTimeAccessService.java:174`) ; montant 0 jamais écrit ;
- les 6 colonnes sont toujours écrites ensemble et le brut n'est jamais réécrit après création :
  le CHECK de `user_subscriptions` (V074:289-301) ne peut pas être violé.

⚠️ Mais **aucun filet** n'existe : le crédit, la décomposition et le marquage « événement
traité » sont dans une seule transaction (`BillingService.java:436-468`), l'INSERT part au
flush du commit (`@Id` assigné). Une future régression du calcul **annulerait le crédit** et
mettrait le webhook en 5xx (relances bornées : ~3 j Stripe, ~5 Apple — SUPPOSÉ ; donc un achat
jamais crédité à l'épuisement, pas une boucle infinie).
- **Correctif défensif** : `try/catch (RuntimeException)` autour de
  `decomposer(...).appliquerA(sub)` → colonnes `null` + log. Sûr ici car c'est du Java pur, sans
  appel base. **Coût** ≈ 1 h, 1 fichier + 1 test.
- Même garde pour `rawPrice` démesuré (`MontantEncaisseResolver.java:60-63`, `intValueExact` →
  500 avant crédit ; client falsifié seulement) : borner et rendre inconnu. ≈ 0,5 h.

**Remboursements (`payment_refunds`) — risque réel : oui, étroit. Gravité : moyenne** (VÉRIFIÉ).
- La ligne comptable est écrite **avant** le retrait d'accès, dans la même transaction. Deux
  livraisons concurrentes du même remboursement : le pré-contrôle `exists`
  (`PaymentRefundService.java:68`) passe pour les deux, l'une échoue au commit sur l'unicité, et
  **son retrait d'accès est annulé avec elle**. Auto-réparant à la relance suivante (sauf
  épuisement).
- **Donnée fausse** : deux `charge.refunded` partiels de cumuls différents traités en parallèle
  lisent le même « déjà remboursé » (`StripeSubscriptionService.java:383`) → remboursement
  compté deux fois.
- ⚠️ Un simple try/catch **ne protège pas** : sous PostgreSQL une instruction en échec rend la
  transaction inutilisable, un `@Transactional` REQUIRED qui lève la marque rollback-only, et
  `NESTED` n'est pas fiable avec JPA.
- **Correctif** : INSERT natif `ON CONFLICT (provider, provider_refund_id) DO NOTHING` exécuté
  immédiatement + `SELECT … FOR UPDATE` sur la ligne `user_subscriptions` avant de calculer la
  différence ; option : ligne comptable en `REQUIRES_NEW` après le retrait d'accès.
  **Coût** 2–3 h, sans migration.

**`diagnostic_run` (auth, soumission) — risque réel : non** (VÉRIFIÉ). Toutes les transitions
sont des UPDATE natifs exécutés immédiatement, qui posent leurs paires ensemble (claim
`DiagnosticRunRepository.java:194-203`, rotation `:111-117`, soumission `:158-183`) : les CHECK
V074:93-99 ne peuvent pas être violés. Une authentification ne peut pas échouer par ce biais.
- Remarque préexistante (hors chantier) : `AnalyticsIdentityService.java:47-54` attrape une
  exception d'un `@Transactional` REQUIRED dans la transaction d'auth — best-effort illusoire,
  gravité basse.

### B. Paiements différés

**Risque réel : oui si SEPA (ou Multibanco / virement) est actif dans le Dashboard Stripe.
Gravité : bloquant de déploiement tant que ce n'est pas vérifié.**
- VÉRIFIÉ : la session Checkout (`BillingService.java:334-363`) n'a **ni
  `payment_method_types` ni `payment_method_configuration`** : les moyens proposés sont ceux
  activés dans le Dashboard. `payment_status ≠ paid` n'accorde plus rien
  (`StripeSubscriptionService.java:198-202`) ; `async_payment_succeeded` recrédite bien (`:82`,
  testé).
- Conséquence si l'événement n'est pas abonné : client prélevé, **accès jamais ouvert** —
  régression par rapport à avant (accès immédiat). La page succès annonce « activation en
  attente » après ~12 s, trompeur pour plusieurs jours.
- **Doc contradictoire** : `docs/setup-paiement-one-time.md:63-65` n'exige que
  `checkout.session.completed` et `charge.refunded` ; `docs/regles/paiements.md:388-389`
  exige aussi les deux `async_*`.
- **Donnée fausse associée** : pour un paiement différé, l'intention (TTL 24 h) est jugée sur la
  date du **succès** (`event.getCreated()`, `:234`), plusieurs jours après → origine
  systématiquement `UNKNOWN`.

**Correctif**
1. Abonner `checkout.session.async_payment_succeeded` et `…_failed` ; corriger
   `setup-paiement-one-time.md`. 15 min, sans code.
2. Au choix : restreindre en code à `CARD` (Apple Pay / Google Pay compris, `LINK` en option ;
   on perd Bancontact, iDEAL, Klarna) — ≈ 1 h ; **ou** désactiver SEPA / Multibanco dans le
   Dashboard. Recommandation : restriction en code, pour qu'un réglage Dashboard ne puisse plus
   réintroduire le cas.
3. Juger l'expiration de l'intention sur `session.getCreated()`. ≈ 1 h.

### C. Abandon civique compté « soumis »

**Risque réel : oui. Gravité : haute** (TCF et Civique non comparables, dans « Tous » et dans les
ratios).

**Prémisse corrigée** (VÉRIFIÉ) : le diagnostic civique **n'a pas d'échéance**
(`CivicDiagnosticService.java:126-170` ne pose jamais `timeLimitSeconds` ; aucun chrono client).
La mention « échéance » de D23 et de deux commentaires est inexacte. Le vrai problème :
- le diagnostic civique est un `MOCK_EXAM` : la croix « Quitter » confirmée appelle `finish`
  (web `QuestionRunner.tsx:352-355` ; mobile `runner_screen.dart:484-486`, retour système
  compris) → `doFinish` pose « soumis » **sans regarder le nombre de réponses** : un abandon à
  0/40 compte soumis ;
- `POST /api/civic-diagnostics/{id}/result` clôt aussi l'attempt s'il est ouvert
  (`CivicDiagnosticService.java:377-386`), atteignable par URL directe.

Le modèle ne distingue pas fin explicite et abandon (même appel `finish`) ; se fier à une raison
déclarée par le client serait fragile.

**Correctif proposé** : figer une mesure à l'écriture, laisser la règle à la lecture.
- V076 : `diagnostic_run.submitted_answered_count` et `submitted_question_count` (nullables),
  remplis par `markSubmittedByCivicSession` dans son UPDATE.
- Lecture : étape 2 civique = `submitted_at` **et** un seuil de réponses en config versionnée
  (recommandé : toutes les questions répondues, pour s'aligner sur le « clic Analyser » du TCF).
- Runs déjà écrites : `NULL` = inconnu (rattrapage SQL possible tant que la session civique
  existe ; non rattrapable pour les invités purgés).
- **Coût** 5–6 h, 1 migration additive, aucun changement front (parité d'office). Corriger D23.
- Ampleur mesurable gratuitement par SQL avant décision (requête dans le rapport de contrôle,
  jointure `diagnostic_run` → `civic_diagnostic_sessions` → `attempts` → `answers`).

### D. Runs sans `anonymous_id`

**Risque réel : doublons oui, pertes non. Gravité : basse.**
- **Pas de perte** (VÉRIFIÉ) : la clé personne tombe en dernier recours sur l'id de la run,
  `COALESCE(user_id, anonymous_id, id)` (`SuiviReadRepository.java:69-70`).
- **Doublons** : l'index `(anonymous_id, client_key)` n'a pas `NULLS NOT DISTINCT` (V074:119-120)
  et `findByClientKey` sort si `anonymousId == null` : aucune idempotence sans identifiant. Cas
  réel : web invité dont le navigateur refuse `localStorage` **et** IndexedDB — chaque
  rechargement crée une run, comptée comme une personne en étape 1 (étape 2 / étape 1
  sous-estimée). Mobile : identifiant toujours présent. Civique : idempotence par session, non
  touché.
- Après 395 j, `anonymous_id` est effacé (D27) : les cohortes de plus de 13 mois se re-scindent à
  la relecture.
- **Correctif** : ne pas « réparer » côté serveur (pas d'heuristique) ; rendre l'inconnu
  visible par un compteur « runs sans identifiant de mesure » servi et affiché. ≈ 1,5 h, sans
  migration (DTO + miroir admin).

### E. Appareil partagé : claim d'un tiers

**Risque réel : oui, confirmé web et mobile. Gravité : haute (attribution fausse + RGPD).**
- Web : `diagnosticRunToClaim` envoie la run invitée la plus récente au jeton valide à chaque
  login / inscription / Google (`diagnostic-run-store.ts:112-124`, `api.ts:492-500`) ; rien
  n'efface le store, `logout` compris. Mobile : idem (`diagnostic_run_tracker.dart:270-294`),
  et les **événements** du compte B portent ensuite la run de A (`runIdFor`, `:417`).
- Serveur : ne vérifie que jeton, expiration, jamais claimée, sans porteur
  (`DiagnosticRunClaimService.java:79-80`) — ni âge ni appareil.
- **Aggravant** : `reemettre` (`DiagnosticRunService.java:151-157`) repart de `now + TTL` à
  chaque rejeu : la fenêtre de 30 j se rouvre indéfiniment.
- Conséquences : `AFTER_DIAGNOSTIC`, type de diagnostic et source first-touch de A posés sur B ;
  trace de A rattachée au compte de B (aucun contenu, mais c'est un rattachement de parcours
  d'un tiers).

| Option | Verdict |
|---|---|
| Effacer le jeton côté client après la 1ʳᵉ auth réussie | ne protège pas si A ne s'authentifie jamais (cas typique) ; complément seulement |
| Même visite / session analytics | heuristique, contraire à Q3 |
| **Borne serveur sur l'âge de la run** | **recommandé** : une règle, une autorité, parité automatique |

**Correctif recommandé** : ancrer l'expiration sur la création (`expiresAt = subject_viewed_at +
TTL`, plus de prolongation au rejeu) et **raccourcir `claimTokenTtlDays`** — proposition 2 j
(ta proposition de 24 h est aussi défendable). Compromis à arbitrer : un vrai candidat qui
s'inscrit après ce délai sortira `OUTSIDE_DIAGNOSTIC`, et le lien web → app (3b) expire
pareil. **Coût** ≈ 2 h (config + 1 ligne de service + IT), sans migration. Complément optionnel
≈ 1 h / front : cesser d'envoyer une run après une auth réussie.

### F. Offres ouvertes sur un 403 sans CTA

**Risque réel : oui, et plus large que D70. Gravité : moyenne, mais figée par la version de
l'app.**
- **Mobile** (VÉRIFIÉ) : 9 emplacements confirmés sans CTA → pas d'intention → `UNKNOWN`
  (le sas CO/CE du diagnostic, 10ᵉ du rapport initial, n'ouvre aucune offre).
  `start_failure.dart:34-35` dit à tort « l'intention part en OTHER ».
- **Web — D70 est faux** : il n'y a pas de parité. `PaywallSheet.tsx:45` met
  `ctaLocation = "OTHER"` par défaut → tout 403 sans CTA devient `OTHER_CTA`. Cas **faux** déjà
  présent : un 403 depuis le **Plan civique** (`CivicPlanPanel.tsx:309`) part en `OTHER` sans
  `journeyId` alors que le parcours est en scope. Réviser TCF : web `OTHER`, mobile
  `LOCKED_PLAN` + `journeyId` → divergence.
- **Ta proposition `SERVER_LOCK` → `OTHER_CTA`** : ≈ 3–4 h (enum backend + 2 miroirs + allowlist,
  pas de migration, backend à déployer d'abord). Mais **pas vraie partout** : deux écrans
  mobiles sont atteignables depuis le Plan (`competence_prompt_screen` via `planStep: true`,
  `production_subjects_view` via un repli sans marqueur) → `OTHER_CTA` faux. Et le `journeyId`
  en cache ne prouve pas l'origine.

**Correctif recommandé** (≈ 3 h, web + mobile, sans backend ni migration) :
1. CTA **obligatoire** à l'appel (`showPaywallOrError`, `showPaywallSheet`, prop requise de
   `PaywallSheet`) : le défaut web `OTHER` disparaît, chaque appel choisit.
2. Hors Plan : réutiliser le CTA que l'écran passe déjà sur son verrou avant démarrage
   (`MOCK_EXAM` / `OTHER`). Arrivée depuis le Plan (marqueur de route `planStep`) :
   `LOCKED_PLAN` + `journeyId`. Sinon rien → `UNKNOWN`.
3. Corriger `CivicPlanPanel:309` et aligner Réviser web ⇄ mobile.
4. `SERVER_LOCK` reste possible pour distinguer « achat après refus », pas pour rendre
   l'origine plus juste.

**Arbitrage produit à trancher** : `openPlanExercise` impose `LOCKED_PLAN` depuis l'**Accueil**
(web et mobile, cohérents) — un achat parti de l'Accueil compte `DIAGNOSTIC_PLAN`. L'Accueil
compte-t-il comme « le Plan » ?

### G. Anciennes versions (mobile et web)

**Risque réel : oui. Gravité : haute** (donnée fausse, pas inconnue).
- VÉRIFIÉ : l'app publiée envoie `X-Sejourfr-Client: mobile`, sans version ni identifiant ;
  la nouvelle envoie `ios|android` + version ; l'ancien web n'envoie pas de version, le nouveau
  `0.1.0`. **Le serveur sait donc reconnaître un client ancien** (plateforme `MOBILE`, ou `WEB`
  sans version).
- `signup_context` est posé `OUTSIDE_DIAGNOSTIC` dès qu'aucune run n'est claimée, sans regarder
  le client (`SignupAttribution.java:49-59`).
- Aucun mécanisme de version minimale n'existe.

| Option | Verdict |
|---|---|
| (a) Version minimale imposée | ne règle rien pour les versions déjà publiées (elles n'ont pas le contrôle) ; **à embarquer dans cette version** pour pouvoir s'en servir ensuite. 4–6 h |
| **(b) `signup_context = null` si client ancien** (`MOBILE`/`UNKNOWN`, ou `WEB` sans version) | **recommandé** : le serveur a l'information, `null` tombe déjà dans `contextUnknown`. Couvre aussi les inscriptions entre déploiement backend et fronts, et les onglets web en cache. ≈ 2 h + tests, sans migration |
| (c) Date de mesure par plateforme | déconseillé : pas de bonne date, les vieilles apps restent des mois |

**Recommandation : (b) + (a)**, et poser `SIGNUP_CONTEXT` au **lendemain** du dernier
déploiement (la date est au jour). Reste non couvert : diagnostic fait dans l'ancienne app puis
inscription après mise à jour (marginal).

---

## 2. Autres points trouvés

| # | Point | Catégorie | Gravité | Preuve | Correctif / coût |
|---|---|---|---|---|---|
| N1 | **Ingestion unitaire supprimée trop tôt** (D88) : l'app publiée poste sur `POST /api/public/analytics/events` → 404 avalé. `VISITORS`/`ACQUISITION_SOURCES` étant mesurés depuis le 21/08, **fausse chute** dès le déploiement backend. Q17 prévoyait l'unitaire pendant la bascule ; la bascule mobile n'a pas eu lieu (app non publiée) | données fausses | **bloquant** | `2988a6dd` ; ancien `analytics_repository.dart:25` | rétablir la partie backend de `2988a6dd` ; retirer quand les événements `MOBILE` < 5 % sur 7 j (requête SQL). ≈ 1 h |
| F2 | **Vieille run d'invité réutilisée pour un diagnostic connecté** : `rejouer` rend la run `(anonymous_id, clientKey)` sans vérifier porteur ni âge (`DiagnosticRunService.java:137-149`). Web : le diagnostic connecté hérite d'un vieux `subject_viewed_at` → vieille cohorte, soumission hors fenêtre. **Mobile : pire**, l'entrée d'invité non close vaut pour toute session, aucune création, et si la run n'est plus claimable **le diagnostic connecté n'est tracé nulle part** | données fausses | **haute** | `diagnostic-run.ts:40-43`, `diagnostic_run_tracker.dart:178,193-197` | serveur : réutiliser seulement si porteur nul ou appelant **et** âge < fenêtre config (24 h), sinon run neuve ; mobile : nouveau passage dans ce cas. ≈ 3 h + 1 h |
| N2 | **Mobile sans provenance rangé en `direct`** : le serveur écrit `ft_source = DIRECT` de repli (colonne NOT NULL) ; Suivi lit `COALESCE(ft_source_raw, ft_source)`. Contraire à `docs/regles/mesure-audience.md:279`. Même défaut sur `users.signup_source` | données fausses | haute | `AnalyticsEventNormalizer.java:165-167`, `TrafficSource.java:45`, `SuiviReadRepository.java:121` | lecture : natif sans `ft_source_raw` = source inconnue (réversible) ; écriture : `unknown` au lieu de `direct`. 2–3 h + IT |
| N3 | **Une seule run claimée par auth** : un invité TCF rapide **et** civique ne rattache que la plus récente → personne comptée deux fois sous « Tous », l'autre run « jamais rattachée », étapes 5–7 et attribution d'achat perdues pour ce type (`v_journey_founding_run` exige `r.user_id = j.user_id`) | données fausses | moyenne | web `diagnostic-run-store.ts:121`, mobile `:277`, V075:38-39 | accepter 2–3 couples (run, jeton) dans les 4 DTO d'auth. 4–5 h, sans migration |
| N4 | **Commission store figée ligne à ligne** (`revenue_rules_version` par achat, pas de recalcul) | difficile à corriger | haute | `revenue-rules-v1.json:17-20` | tu gardes 0,15 : il suffit de **confirmer le taux avant de poser `measurementStart.REVENUE_BREAKDOWN`** ; sinon les achats écrits entre-temps restent à 15 %. Config seule |
| N5 | **Brut affiché comme un total** alors que `gross_unknown` est calculé et jamais servi | données fausses | moyenne | `SuiviReadRepository.java:444-445`, `SuiviMapper.java:231-247` | servir `grossUnknown` (DTO + miroir admin) ou brut `null` si > 0. 1–2 h |
| N6 | **Litiges Stripe (`charge.dispute.*`) non traités** : accès conservé, net non réduit, frais de litige ignorés (préexistant, désormais affiché) | données fausses / paiement | moyenne | `StripeSubscriptionService.java:82-89` | traiter `charge.dispute.closed` perdu comme retrait d'accès + ligne `payment_refunds`. 3–4 h |
| N7 | **First-touch web marqué envoyé même si l'envoi échoue** ; API sur un autre domaine : `sendBeacon` avec Blob `application/json` cross-origin peut être refusé (SUPPOSÉ) → UTM perdues puis `direct` (N2) | données fausses | basse–moyenne | `lib/analytics.ts` (vidage de sortie), `.env.production:2` | Blob `text/plain` accepté serveur + marquer « envoyé » seulement si parti. ≈ 1 h |
| N8 | **Rate-limit par IP contournable en prod** (préexistant) : `forward-headers-strategy: framework` réécrit l'IP depuis `X-Forwarded-For` contrôlable par le client | sécurité | moyenne (SUPPOSÉ) | `application-prod.yaml:43` | `native` + plages de proxy de confiance. ≈ 1 h, à vérifier sur le serveur |
| N9 | **RGPD, suppression de compte** : l'anonymisation coupe `analytics_identity` mais laisse `diagnostic_run(user_id, anonymous_id)` jusqu'à 395 j | RGPD | basse | `AccountDeletionService.java:139`, V074:60-64 | mettre `anonymous_id` à `null` sur les runs du compte à la suppression. ≈ 1 h + IT |
| N10 | **Ordre de déploiement** : si l'app sort avant le backend, un 4xx sur le lot fait **abandonner** les événements (D66) et aucune run ne se crée | difficile à corriger | moyenne | `analytics_queue.dart` | procédure : backend → web → publication de l'app (à écrire dans la checklist de déploiement) |

**Points vérifiés sans risque** : idempotence du crédit (`completed` puis `async` sur le même
`payment_intent`) ; consommation de l'intention en une instruction ; intention réutilisée par
un autre compte (le serveur exige le même compte → au pire `UNKNOWN`) ; `claimToken` (256 bits,
hash seul stocké, comparaison à temps constant, jamais journalisé, dans le fragment du lien,
effacé par la page de repli, jamais dans un événement) ; pas d'oracle sur `runId` ; claim
`APP_LINK` soumise aux mêmes vérifications.

**Écarté comme mineur** (bien documenté ou marginal) : frais de facture Stripe hors frais réel
(≈ 0,4 %, SUPPOSÉ) ; Adaptive Pricing (SUPPOSÉ) ; `purchase_intent` sans limite ni purge ;
appel réseau Stripe sans délai dédié dans la transaction du webhook ; delta de remboursement
`null` additionné comme 0 (devise différente, rare) ; soumission TCF rapide avec un JWT expiré
→ `submitted_authenticated` faux (rare, ≈ 1 h si voulu).

**Hors périmètre, relevé au passage** : `entrainement/{tcf,civique}/…/page.tsx:115,206` décide
d'un cadenas d'après le rang (`lot.numero > 1`), ce que `docs/regles/freemium.md` interdit ;
`TcfPaywallCard.tsx` n'est importé nulle part (code mort).

---

## 3. Ordre recommandé avant la mise en production

1. **Sans code** : vérifier les moyens de paiement du Dashboard, abonner les `async_*`, corriger
   `setup-paiement-one-time.md` (B) ; confirmer le taux de commission avant la date de mesure
   des revenus (N4).
2. **Backend, sans migration** : rétablir l'ingestion unitaire (N1) ; borne claim + réutilisation
   de run (E, F2) ; `signup_context` inconnu pour un client ancien (G-b) ; source mobile inconnue
   (N2) ; restriction des moyens de paiement + expiration d'intention sur la date de session
   (B) ; remboursements `ON CONFLICT` + verrou (A) ; garde défensive du calcul (A).
3. **Fronts, à embarquer dans la version de l'app** : CTA obligatoire (F), nouveau passage mobile
   (F2), version minimale (G-a), first-touch web (N7).
4. **Migration V076** : mesure des réponses à la soumission civique (C).
5. Ensuite : claim multi-runs (N3), brut inconnu servi (N5), litiges (N6), compteur runs sans
   identifiant (D), RGPD suppression (N9), proxy (N8).

**Arbitrages attendus du propriétaire** : TTL de claim (24 h ou 2 j) (E) ; seuil de réponses
civique pour « soumis » (C) ; l'Accueil compte-t-il comme « le Plan » (F) ; restriction des
moyens de paiement en code ou dans le Dashboard (B).
