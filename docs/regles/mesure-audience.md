# Mesure d'audience, funnel et analytics

> **Extrait de `CLAUDE.md` racine le 2026-08-23**, lors de la restructuration du fichier
> (343 599 chars pour une limite de 150 000, rechargé à chaque requête). **Contenu verbatim, aucune réécriture.**
> Origine : lignes 254-276, 347-554 de l'ancien `CLAUDE.md`.
> **Lu à la demande** — ce fichier n'est jamais chargé automatiquement.
> Ce fichier porte la loi de ce sous-système : on l'ouvre **quand on travaille dedans**.
> Fichier jumeau : `docs/decisions/mesure-audience.md`
> Traçabilité complète : `docs/inventaire-claude-md.md`.

---

## Identité IP des appelants (rate-limits, attempts invités)

Tout ce qui se compte « par IP » — rate-limits anti-abus (login, inscription,
mot de passe oublié, contact, démo) et `attempts.client_ip` des sessions
invitées — passe par `util/ClientIpResolver`.

- **`X-Forwarded-For` / `X-Real-IP` ne sont lus que si la connexion vient d'un
  proxy déclaré de confiance** (`sejourfr.trusted-proxies.ranges`, env
  `TRUSTED_PROXY_RANGES`, adresses ou CIDR séparés par des virgules).
  **Vide par défaut** → en dev et sans configuration, c'est l'IP de la socket
  qui fait foi. Sans ce garde-fou, n'importe qui remettait ses compteurs à zéro
  en changeant un en-tête, et un invité se fabriquait autant d'identités qu'il
  voulait.
- En production, y mettre les plages du reverse-proxy réel. La valeur spéciale
  `*` fait confiance à tout appelant : à réserver aux hébergements dont le port
  applicatif n'est joignable que par le load balancer.
- Quand le proxy est de confiance, on retient la **dernière adresse non-proxy**
  de la chaîne `X-Forwarded-For` (les valeurs forgées par le client sont à
  gauche de celle ajoutée par notre proxy, donc ignorées).
- Le rate-limit de connexion **se réinitialise sur authentification réussie**
  (`RateLimitGuard.onLoginSuccess`) : on freine l'enchaînement d'échecs, pas
  l'utilisateur qui se reconnecte.

## Funnel d'acquisition — comptage EXACT par compte (2026-08-19)

Deuxième nature de mesure, **à ne jamais mélanger** avec `page_views` : ici on
compte des **comptes**, une fois par étape, sur les vraies tables. Le funnel
suivi est *réseau social → inscription → diagnostic commencé → terminé → écran
Premium affiché → clic abonnement → paiement*.

- 🛑 **Tout ce qui peut se lire sur les vraies tables se lit sur les vraies
  tables** (`users`, `diagnostic_sessions`, `user_subscriptions`). Recompter des
  inscriptions ou des paiements par événements client aurait produit **deux
  chiffres divergents pour la même chose**. Seules les deux étapes qui n'existent
  QUE dans le navigateur sont enregistrées.
- **Cohorte d'inscription** : la population est celle des comptes créés dans la
  fenêtre (`deleted_at IS NULL`), et **chaque étape est mesurée sur ces mêmes
  comptes**, quelle que soit la date de l'étape. C'est ce qui rend « 4 payants
  sur 50 inscrits TikTok » vrai ; comparer des totaux journaliers ne veut rien
  dire. `integrity`, lui, est **global** et n'est jamais filtré par la période.
- **La provenance et la plateforme voyagent en EN-TÊTES**, résolues serveur par
  `util/ClientContextResolver` (patron `ClientIpResolver`) : `X-Sejourfr-Source`
  (normalisée par **`util/TrafficSource`**, autorité unique dont
  `PageViewService` est désormais un client — l'allowlist n'existe plus en deux
  copies) et `X-Sejourfr-Client` (`web` / `mobile`, enum `ClientPlatform`).
  Un en-tête plutôt qu'un champ de DTO : ça couvre d'un coup l'inscription
  locale, les sign-in Google/Apple et la création de diagnostic **sans toucher
  quatre DTO**, et chaque front n'a qu'**un seul point de câblage** (client HTTP
  web, `BaseOptions` du Dio mobile — y compris sur les requêtes non
  authentifiées, l'inscription en fait partie).
- **Capté à la création seulement** : `users.signup_source` / `signup_platform`
  sont posés à `register` et à la **première** connexion sociale, **jamais
  réécrits** — la provenance, c'est celle du premier jour (test dédié).
  `diagnostic_sessions.platform` répond à « qui fait son diagnostic depuis
  l'app ». **Legacy = NULL, aucun rattrapage** : rendu `"inconnu"` /
  `"UNKNOWN"` et **affiché en clair**, sinon les totaux ne tombent plus juste.
- **`user_funnel_events`** (V036) : `UNIQUE (user_id, event)` — **première
  occurrence seulement**, donc **3 lignes maximum par compte**, la table ne peut
  pas gonfler et n'a pas besoin de rate-limit. `POST /api/me/funnel-events`
  (authentifié) rend **204** et est idempotent par `ON CONFLICT DO NOTHING` :
  aucun rejeu ne lève, y compris en concurrence.
  🛑 **`CHECKOUT_STARTED` est REFUSÉ au client (422)** et posé **serveur** par
  `BillingService` après création réelle de la Checkout Stripe : venant d'un
  client ce serait une **intention**, pas un fait, et la dernière marche du
  funnel ne voudrait plus rien dire. Best-effort — un échec d'enregistrement ne
  bloque jamais un paiement.
- **`PAYWALL_VIEWED` ≠ `SUBSCRIBE_CLICKED`** : le premier se pose à l'affichage
  d'un écran Premium (page `/paiement` **et** `PaywallSheet`), le second
  **uniquement sur un CTA qui engage l'achat**. Un lien de navigation vers
  `/paiement` n'est pas un clic d'abonnement — sinon les deux étapes affichent le
  même nombre.
- **`GET /api/admin/audience/funnel`** : `stages` (ordre figé `SIGNUP` →
  `PURCHASE`, jamais réordonné par un front), `bySource`, `byPlatform`, `daily`,
  `integrity`. `PURCHASE` = au moins une `user_subscriptions` de statut
  ≠ `PENDING` (un remboursement a bien été un paiement). **6 requêtes agrégées
  bornées** (`GROUP BY` en SQL), jamais une par compte ; chaque compte
  appartient à exactement une cellule (source × plateforme), donc les
  sous-totaux sont additionnables.
- **Un seul diagnostic par compte** : l'unicité réelle est
  `(user_id, diagnostic_code, diagnostic_version)`, **pas `user_id` seul** — une
  version 2 du diagnostic autoriserait légitimement une seconde session. C'est
  exactement ce que surveille `integrity.accountsWithMultipleDiagnosticSessions`
  (doit valoir 0, mesuré sur **toute la base**).
- **Suppression de compte** : les événements de funnel sont purgés
  **explicitement** par `AccountDeletionService` — la suppression est une
  *anonymisation*, la ligne `users` survit, donc la cascade DB ne se déclenche
  pas (test IT dédié).
- ⚠️ **Conséquence légale, traitée dans la même passe** : la provenance est
  désormais **rattachée à un compte**, ce que `/confidentialite` niait
  implicitement. La page a une sous-section **8.3 « Mesure d'audience sans
  traceur »** + les lignes correspondantes aux articles 3.2, 4 et 5. L'acquis
  est intact et doit le rester : **aucun cookie, rien écrit sur le terminal,
  aucun outil tiers, aucun bandeau de consentement**. Ne rien ajouter qui écrive
  côté visiteur sans repasser sur cette page.
- **Admin** : `features/audience/` est scindé en **deux sections étiquetées** —
  « comptage exact · par compte » (le funnel) puis « agrégat anonyme · par
  page » (l'existant). Les lire comme comparables produit des conclusions
  fausses ; l'étiquette est là pour ça. Un **filtre de période unique** en tête
  pilote les deux (aujourd'hui / hier / cette semaine — lundi / ce mois — le 1er
  / 7-30-90 j / une date précise), calculé côté client depuis un seul
  `parisToday()`.

## Analytics — acquisition → diagnostic → inscription → premium → paiement (2026-08-21)

Chantier d'après `docs/plan/BRIEF_CLAUDE_CODE_ANALYTICS_SEJOURFR.md` (112 sections)
et sa maquette `docs/plan/SejourFR - Analytics Autonome.html`, **source de vérité
visuelle**. L'écran vit dans l'admin sur **`/dashboard`** (`features/analytics/`) et
**remplace** l'ancien dashboard et `features/audience/`, supprimés. Il répond à une
seule question : *pourquoi mes visiteurs ne deviennent-ils pas abonnés, et quel
levier améliorer en priorité ?*

### Les 5 arbitrages du propriétaire

1. **`anonymous_id` autorisé, sous exemption CNIL de mesure d'audience** :
   first-party, jamais partagé, jamais cross-site, **rétention 13 mois**, aucun
   recoupement externe ⇒ **toujours aucun bandeau de consentement**. Révoque la
   règle « rien n'est stocké côté visiteur » ; `/confidentialite` (art. 3.2, 4, 5
   et tout l'article 8, désormais 8.1→8.5) a été réécrite **dans la même passe**.
2. **Analytics remplace `/dashboard`** — pas de cohabitation.
3. **Charte SejourFR, maquette pour tout le reste** : la maquette est hors charte
   (Bricolage Grotesque / Hanken Grotesk, bleu `oklch` ≈ #2D5BB8) ; on reprend sa
   mise en page, sa densité et ses libellés, **jamais ses couleurs ni ses polices**.
4. **Pays par géo-IP embarquée** (MaxMind GeoLite2). L'IP est lue en mémoire et
   **jamais persistée**.
5. **Revenu = montant réellement encaissé**, figé à l'écriture.

### 🛑 Aucune seconde vérité — la règle qui structure tout le modèle

`USER_REGISTERED`, `PAYMENT_SUCCEEDED` et `DIAGNOSTIC_COMPLETED` **ne sont PAS des
événements**, alors que le brief §100 les liste. Ils se lisent sur `users`,
`user_subscriptions` et `diagnostic_sessions` — V036 l'écrivait déjà : deux
chiffres pour la même chose sont condamnés à diverger. **Un événement n'existe que
pour ce qui n'existe QUE dans le navigateur.** Corollaire : `CHECKOUT_STARTED` est
déclaré au registre mais **jamais écrit** dans `analytics_event` (il est posé
serveur par `BillingService`, qui n'a pas d'`anonymousId`) — c'est
`user_funnel_events` (V036) qui fait foi, table **conservée et continuée**.

### Schéma — `V043__analytics.sql`

- **`analytics_visitor`** : une ligne par `anonymous_id`. **L'attribution vit ici,
  pas sur l'événement** — sinon le first touch cesserait d'être premier, et
  compter les visiteurs demanderait un `COUNT(DISTINCT)`. Le **first touch
  n'apparaît dans aucun `SET`** de l'upsert : il ne *peut pas* être réécrit. Le
  last touch ne l'est que sur une source explicite. Pays / device / plateforme ne
  s'écrasent jamais avec une absence d'info.
- **`analytics_event`** : journal comportemental, `properties jsonb` à clés
  **allowlistées** (le §6 du brief propose du jsonb libre — écarté, l'endpoint est
  public), `dedup_key` unique.
- **`analytics_identity`** (`anonymous_id` ⇄ `user_id`) : une **table** et non une
  colonne, parce qu'un appareil partagé porte deux comptes. Écrite à la connexion
  locale et aux deux sign-in sociaux, idempotente, best-effort. Un `anonymousId`
  inconnu **n'écrit rien au lieu de lever** — sinon la FK empoisonnerait la
  transaction de login.
- **`analytics_annotation`** : les repères produit / marketing de la courbe.
- **`user_subscriptions`** gagne `amount_cents`, `currency`, `amount_eur_cents`,
  `fx_rate_to_eur`. 🛑 **Figés à l'écriture, jamais recalculés** :
  `plans.price` est **mutable en console** (`AdminPlanService`), donc le lire à la
  lecture falsifierait rétroactivement le chiffre d'affaires de tout l'historique.
  Autorité unique `MontantEncaisse` + `MontantEncaisseResolver` (taux sous
  `sejourfr.analytics.fx-rates`, POJO ≡ YAML). Devise sans taux ⇒ `amount_eur_cents`
  **null**, jamais une conversion inventée. Les lignes existantes restent `NULL` :
  **aucune migration de données**.
- ⚠️ `country_code` / `currency` sont en `varchar(2)`/`varchar(3)` et non `char` :
  Postgres rend `bpchar`, que Hibernate refuse sous `ddl-auto: validate`.

### Ingestion — `POST /api/public/analytics/events`

Public, **rate-limité** (`analytics:burst` 120 / 10 min, `analytics:daily` 2000 / j)
— le trou connu de `/api/public/page-views` ne se reproduit pas. Allowlists fermées :
événement, propriétés **par événement**, chemins (`util/AnalyticsPaths`). Hors
allowlist ⇒ **400 nommé**. Pays et device sont résolus **serveur** (le client les
falsifierait) ; les UTM trop longues sont **tronquées, pas rejetées** (borne de
stockage, pas règle métier) ; un referrer est ramené à son **hôte seul**.
⚠️ **Ajouter un écran suivi = une ligne dans `AnalyticsPaths.KNOWN`, dans la même
passe que le front** — un chemin non déclaré est refusé, jamais rangé en « autre ».

### Lecture — `GET /api/admin/analytics`

**Un seul endpoint** et pas les cinq du brief : la maquette recalcule toutes ses
sections depuis un même objet, cinq appels imposeraient cinq fenêtres de temps à
tenir cohérentes. `FenetreMesure` **réutilisée telle quelle**, bornes appliquées
rendues, 4 filtres facultatifs, cache 60 s (vidé à l'écriture d'une annotation).
**Coût figé : 10 requêtes SQL, constantes**, vérifié par une **égalité** dans
`AdminAnalyticsCoutIT` avec 2 puis 20 provenances — seule façon d'attraper un N+1.
Zéro agrégation en Java.

Règles de calcul : `v` compte des **visiteurs distincts**, jamais des vues ; `prem`
des **cliqueurs uniques** (le volume brut de clics ne vit que dans la table CTA) ;
`revEurCents` est la **somme réelle** des montants — **jamais** le `pay × 14,99` de
la maquette ; `previous = 0` ⇒ delta **`null`** ; bucketing 1 j / 45 j → heure /
jour / semaine ; séries **continues des deux côtés** ; **arrondi à somme conservée**
(`util/RepartitionArrondie`) pour que la somme des lignes égale toujours le pied ;
comptes de test exclus **en SQL** (`sejourfr.analytics.excluded-emails`) ;
`direct ≠ inconnu`, et `inconnu` ne se cache jamais.

⚠️ **`pay` suit la COHORTE d'inscription**, pas « premier paiement dans la
période » : la population est celle des comptes créés dans la fenêtre, et chaque
étape est mesurée sur ces mêmes comptes. C'est ce qui rend « 4 payants sur 50
inscrits TikTok » vrai et les sous-totaux additionnables. **Conséquence assumée** :
un compte inscrit avant la fenêtre qui paie pendant n'est pas compté, et le chiffre
d'une période passée continue de monter à mesure que ses inscrits convertissent.
« Un renouvellement n'est jamais un nouvel abonné » reste garanti.

**Insights déterministes, sans LLM** (≤ 4), avec les trois seuils d'honnêteté
hérités de l'ancien `insights.ts` : 10 inscrits pour désigner une fuite, 20 pour
comparer les réseaux, 5 par réseau. Sous le seuil **on énonce les chiffres et on
dit pourquoi on s'arrête là** — on masque une conclusion, jamais une donnée. Le
classement des sources trie **payants d'abord, taux ensuite** (le taux seul
hisserait en tête un réseau à 1 inscrit / 1 payant), `inconnu` toujours en dernier.

### Limites connues — à afficher comme telles, jamais à combler par une estimation

- **Le pays reste `UNKNOWN`** tant que `GeoLite2-Country.mmdb` n'est pas installée
  (compte MaxMind requis, licence interdisant de la versionner) : poser
  `ANALYTICS_GEOIP_DB`. Le résolveur est **inerte proprement** sans elle.
- **Aucune provenance mobile** : ni deep link, ni install referrer, ni paramètre
  d'URL. La plomberie est prête (un seul point de câblage) mais l'attribution
  mobile restera « inconnu » tant qu'aucune campagne n'ouvrira l'app par un lien.
  🛑 **Ne pas « réparer » en renvoyant `direct`** — c'était le bug d'avant.
- **`DIAGNOSTIC_CO_COMPLETED` / `_CE_COMPLETED` ne sont pas émis** : la
  compréhension se joue dans le runner QCM ordinaire, qui ignore pourquoi il
  s'ouvre. Les maillons `co2`/`ce2` valent **`null`, jamais 0** — un zéro se lirait
  « tout le monde abandonne ». Réparable en marquant l'attempt à son lancement.
- **La série n'est pas additive** pour `v` et les cliqueurs (un visiteur actif deux
  jours compte dans deux barres) : aucune courbe d'uniques ne l'est. Les tableaux,
  eux, somment exactement au pied.
- **Un job de purge à 13 mois reste à écrire** — ce n'est pas optionnel, c'est une
  **condition de l'exemption CNIL** sur laquelle repose l'absence de bandeau.
  L'index `idx_analytics_visitor_last_seen` est posé pour lui (il balaie par
  dernière activité, pas par première vue).
