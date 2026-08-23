# Contenus suspectés périmés — liste de revue

> **Créé le 2026-08-23**, à la restructuration de `CLAUDE.md` racine.
> **Rien n'a été supprimé.** Chaque contenu ci-dessous est **toujours en place, verbatim**, à
> l'emplacement indiqué, précédé du bandeau :
>
> > ⚠ **SUSPECTÉ PÉRIMÉ — non vérifié au 2026-08-23, ne pas appliquer sans confirmation.**
>
> **Ce fichier est un index de revue, pas une copie** : le texte intégral n'existe qu'à un seul
> endroit. **Lu à la demande.**

Quand une entrée est confirmée : retirer le bandeau (si toujours valable) **ou** déplacer le
verbatim ici avec la mention ❌ PÉRIMÉ + date (si obsolète). Dans les deux cas, **conserver
l'entrée** — on garde la trace.

---

## #1 — « Lot 4b (à faire, web) : refonte page /paiement »

- **Où** : `docs/decisions/paiements.md` · origine `CLAUDE.md` **l. 4260-4263**
- **Extrait** : « refonte page `/paiement` avec 3 plans × 3 périodicités (toggle
  mensuel/trimestriel/annuel), portail client Stripe pour gérer l'abonnement »
- **Pourquoi je le soupçonne** : ce lot décrit le monde **abonnement récurrent**, dormant
  depuis le lot 5 (bascule en passes achat unique). La page `/paiement` livrée vend des passes,
  pas des périodicités.
- **Comment trancher** : lire `web_sejoufr/app/paiement/` — s'il n'y a pas de toggle de
  périodicité, le lot est sans objet tant que `BILLING_MODE=ONE_TIME`.

## #2 — « Lot 4d (à faire, mobile) »

- **Où** : `docs/decisions/paiements.md` · origine `CLAUDE.md` **l. 4277-4284**
- **Pourquoi je le soupçonne** : il suit **immédiatement** un « Lot 4d (✅ fait, mobile) » au
  périmètre identique (UI paywall, `in_app_purchase`, `/verify-receipt`, `/subscription-status`
  au boot). Deux entrées « 4d » contradictoires, l'une faite, l'autre à faire.
- **Comment trancher** : la section « In-App Purchase » de `mobile_sejourfr/CLAUDE.md` décrit un
  paywall livré. Si c'est confirmé, l'entrée « à faire » est un résidu.

## #3 — « ⚠ Cassure connue après lot 4 : `/paiement` envoie `?plan=BillingPlan` → 400 »

- **Où** : `docs/decisions/paiements.md` · origine `CLAUDE.md` **l. 4329-4331**
- **Extrait** : « il sera 400 jusqu'à ce que le lot 4b mette à jour l'appel en
  `?planCode=<string>` »
- **Pourquoi je le soupçonne** : vérification partielle le 2026-08-23 — `web_sejoufr/lib/api.ts`
  documente bien un `planCode` passé à `billingApi.getPaymentLink`, et le `?plan=` restant dans
  `lib/passes.ts:150` est un paramètre de **route interne** (`PASS_RECAP_PATH`), pas l'appel
  backend. La cassure a probablement disparu avec le lot 5.
- **Comment trancher** : suivre l'appel réel de `getPaymentLink` jusqu'au controller.

## #4 — Toute la section « Mesure d'audience des landings (sans traceur) »

- **Où** : `docs/decisions/mesure-audience.md` · origine `CLAUDE.md` **l. 277-346**
- **Pourquoi je le soupçonne** : le texte se déclare lui-même mort — « 🛑 **Ce système est
  LEGACY depuis le 2026-08-21.** `page_views`, `PageViewService`, `PublicPageViewController`,
  `AdminPageViewController`, `PageViewEvent` et `PageViewStatsResponse` sont **supprimés** ».
  Il précise aussi qu'une de ses règles (« rien n'est stocké côté visiteur ») est **révoquée**.
- **Statut** : conservé **exprès** comme archive (« la table reste en base […] c'est de la
  donnée réelle »), pas comme règle applicable. Le bandeau est là pour qu'on ne l'applique pas.
- **Comment trancher** : rien à trancher — c'est de l'histoire. À déplacer plus bas dans le
  fichier si elle gêne la lecture.

## #5 — « ⏳ À gérer plus tard — garde-fou attempts guest (`user IS NULL`) »

- **Où** : `docs/regles/freemium.md` · origine `CLAUDE.md` **l. 227-253**
- **Extrait** : « **Rate-limit** sur `POST /api/public/attempts/demo` […] **Job de purge**
  `@Scheduled` (quotidien) »
- **Pourquoi je le soupçonne** : deux évolutions l'ont partiellement rattrapé — le
  `GuestAttemptPurgeJob` **existe** (livré éteint, décrit vingt lignes plus haut dans le même
  fichier), et le chantier Analytics affirme « le trou connu de `/api/public/page-views` ne se
  reproduit pas » avec un rate-limit réel. Le TODO parle donc peut-être d'un travail déjà fait
  à moitié.
- **Comment trancher** : vérifier si `POST /api/public/attempts/demo` passe par
  `RateLimitGuard`. Le point sur la purge, lui, reste valide (le job est éteint et son
  prérequis — le compteur agrégé — n'est pas décrit comme livré).

## #6 — « Deux drapeaux livrés ÉTEINTS » (`fluidite`, `seconde-passe`)

- **Où** : `docs/regles/notation-ia.md` · origine `CLAUDE.md` **l. 2953-2956**
- **Extrait** : « `fluidite.enabled` (débit/pauses, informatif) et `seconde-passe.enabled`
  (2ᵉ lecture en zone floue, même provider/modèle). À `false`, ils ne changent **rien**. »
- **Pourquoi je le soupçonne** : aucune date, aucune mention dans les passes suivantes, et
  `fluidite` (débit/pauses) semble en tension avec le garde-fou oral qui interdit d'évaluer le
  débit et la fluidité depuis une transcription.
- **Comment trancher** : vérifier que les deux clés existent encore dans `application.yaml` et
  qu'elles sont bien à `false`. Si `fluidite` est mort, le dire ; s'il est vivant, expliquer
  comment il coexiste avec le garde-fou oral.
