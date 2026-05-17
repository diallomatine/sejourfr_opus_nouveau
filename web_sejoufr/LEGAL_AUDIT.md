# Audit des pages légales SejourFR

Date d'audit : 2026-05-17
Auditeur : Claude (diagnostic uniquement, aucun fichier source modifié)

Périmètre produit retenu pour l'audit :
- Module **Examen civique** (entraînement à l'examen officiel obligatoire au 1er janvier 2026 pour CSP / CR / NAT).
- Module **TCF** (entraînement aux compétences linguistiques, à titre complémentaire).
- **Hors périmètre** (à signaler si présent) : accompagnement aux démarches administratives elles-mêmes (ANEF, NATALI, préfecture, dépôt de dossier, naturalisation à proprement parler), fonctionnalités non livrées (offline...), services / examens qui ne sont plus au catalogue.

---

## Inventaire

Pages légales identifiées :
- `/Users/diallomatine/Desktop/Nouveu_Projets/SejourFr_Opus/web_sejoufr/app/cgu/page.tsx` (447 lignes — l'estimation initiale de 484 ne correspond plus à l'état du fichier)
- `/Users/diallomatine/Desktop/Nouveu_Projets/SejourFr_Opus/web_sejoufr/app/mentions-legales/page.tsx` (247 lignes — initialement estimée à 264)
- `/Users/diallomatine/Desktop/Nouveu_Projets/SejourFr_Opus/web_sejoufr/app/confidentialite/page.tsx` (597 lignes — initialement estimée à 641 ; contient bien l'ancre `#article-8` ciblée par le footer pour les cookies)

Données partagées :
- `/Users/diallomatine/Desktop/Nouveu_Projets/SejourFr_Opus/web_sejoufr/content/legal/legal-info.ts`

Composants légaux (non modifiés par cet audit) :
- `/Users/diallomatine/Desktop/Nouveu_Projets/SejourFr_Opus/web_sejoufr/components/legal/LegalPageLayout.tsx`
- `/Users/diallomatine/Desktop/Nouveu_Projets/SejourFr_Opus/web_sejoufr/components/legal/LegalSection.tsx` (expose `LegalSection` + `LegalSubsection`)
- `/Users/diallomatine/Desktop/Nouveu_Projets/SejourFr_Opus/web_sejoufr/components/legal/LegalCallout.tsx`
- `/Users/diallomatine/Desktop/Nouveu_Projets/SejourFr_Opus/web_sejoufr/components/legal/LegalTable.tsx`
- `/Users/diallomatine/Desktop/Nouveu_Projets/SejourFr_Opus/web_sejoufr/components/legal/LegalHeader.tsx`
- `/Users/diallomatine/Desktop/Nouveu_Projets/SejourFr_Opus/web_sejoufr/components/legal/LegalSidebar.tsx`
- `/Users/diallomatine/Desktop/Nouveu_Projets/SejourFr_Opus/web_sejoufr/components/legal/LegalFooterNav.tsx`
- `/Users/diallomatine/Desktop/Nouveu_Projets/SejourFr_Opus/web_sejoufr/components/legal/BackToTopButton.tsx`
- `/Users/diallomatine/Desktop/Nouveu_Projets/SejourFr_Opus/web_sejoufr/components/legal/Placeholder.tsx`

Routes vérifiées comme **inexistantes** :
- Pas de route `/cookies` ni de dossier `app/cookies/` — la « politique cookies » est exclusivement servie via l'ancre `/confidentialite#article-8` (cf. lien dans `app/_components/Footer.tsx` ligne 62).
- Pas de page « charte de modération », « CGV séparées », « politique d'accessibilité », ni autre page légale orpheline (vérifié par `grep -rln` sur `app/` et `content/`).

Surprise positive : il existe un composant `LegalFooterNav` dans `components/legal/` mais qui n'est référencé par **aucune** des 3 pages légales actuelles — composant orphelin à signaler (potentiel à intégrer ou à supprimer lors de la phase de mise à jour).

---

## Page : CGU (`app/cgu/page.tsx`)

**Dernière mise à jour** : 2026-05-09 (via `LEGAL_INFO.lastUpdated` ; `effectiveDate` également 2026-05-09).

**Sections actuelles** (14 articles, dont plusieurs sous-articles) :
- Article 1 — Objet
- Article 2 — Définitions
- Article 3 — Inscription et compte utilisateur (3.1 Conditions d'inscription / 3.2 Création de compte / 3.3 Suppression de compte)
- Article 4 — Description des services (4.1 Accès gratuit / 4.2 Abonnement Premium / 4.3 Évolution des services)
- Article 5 — Tarifs et paiement (5.1 Prix / 5.2 Modalités de paiement / 5.3 Reconduction / 5.4 Facturation)
- Article 6 — Droit de rétractation (6.1 Modalités / 6.2 Effet / 6.3 Renonciation)
- Article 7 — Engagements de l'Utilisateur
- Article 8 — Disponibilité du service
- Article 9 — Limitation de responsabilité (9.1 Aucune garantie de réussite / 9.2 Caractère indicatif des contenus / 9.3 Limitation)
- Article 10 — Données personnelles
- Article 11 — Modifications des CGU
- Article 12 — Médiation et règlement des litiges
- Article 13 — Loi applicable et juridiction
- Article 14 — Contact

**À modifier** (références au périmètre obsolète ou trop large) :

1. **Article 2 — Définitions** (l. 100-103) : la définition d'« Examen civique » mentionne le titre de séjour ET la naturalisation, ce qui reste cohérent. **À vérifier** : la définition de « Services » (l. 91-94) parle de « QCM, examens blancs chronométrés, suivi de progression » → ne mentionne pas le **module TCF**, qui devra être ajouté pour refléter le périmètre actuel (deux modules : CIVIQUE et TCF).

2. **Article 4.1 — Accès gratuit** (l. 142-154) : la formulation « Le 1er examen blanc de chaque module (**Civique et Naturalisation**) » est **incorrecte** : les modules réels sont **Civique** et **TCF**, pas « Naturalisation ». La naturalisation est un parcours (`NAT`) au sein du module civique. À reformuler.
   La mention « 5 thématiques officielles » et `subscription.trialQuestionsPerCategory` = 5 ne correspond pas non plus à la règle métier actuelle documentée en mémoire (« 20 Q + 1 examen blanc gratuits par module »). À aligner.

3. **Article 4.2 — Abonnement Premium** (l. 156-171) : mentionne « **20 examens blancs chronométrés de 40 questions par module** ». Le nombre exact et le format à 40 questions ne sont vérifiés nulle part dans la source. À vérifier avec l'éditeur (le format de 40 Q correspond à l'examen civique officiel ; le TCF a une autre structure et durée — risque d'incohérence selon les modules).

4. **Article 9.1 — Aucune garantie de réussite** (l. 322-339) : la formulation actuelle parle de « préparation à l'examen civique et à l'entretien de naturalisation », mention de « titre de séjour ou de la nationalité française ». **Le module TCF n'est pas couvert** par cette clause de non-garantie — à compléter pour couvrir explicitement les **deux modules** (échec à l'examen civique ET résultat insuffisant au TCF / niveau A2-B1-B2 non atteint).
   La mention « centres d'examen agréés, préfectures, Ministère de l'Intérieur » est partiellement obsolète : pour le TCF, les organismes sont **France Éducation International** + centres agréés. À élargir.

5. **Article 9.2 — Caractère indicatif des contenus** (l. 341-349) : « Pour toute situation spécifique, l'Utilisateur est invité à consulter un avocat ou un conseiller spécialisé en droit des étrangers. » → laisse entendre que la plateforme touche au droit des étrangers / aux démarches. Cohérent avec une clause de non-conseil juridique, mais à vérifier que la formulation ne sous-entend pas un accompagnement.

6. **Article 14 — Contact** : OK fonctionnellement, mais l'adresse email `support@sejourfr.fr` est dure-codée alors que `LEGAL_INFO.editor.email` vaut `contact@sejourfr.fr`. Incohérence entre les deux emails utilisés dans la même page (l. 127, 237, 438 utilisent `support@…`). À harmoniser.

**Sections valides** (à conserver telles quelles, sans modification de fond) :
- Article 1 — Objet (à part la `Placeholder` éditeur qui sera remplie quand `legalName` sera renseigné).
- Article 3 — Inscription et compte utilisateur (3.1, 3.2, 3.3) : générique, valide.
- Article 5 — Tarifs et paiement (5.1, 5.2, 5.4) : valides (sauf vérifier le prix `29,90 €` qui doit refléter l'offre réelle Stripe). 5.3 « non reconductible automatiquement » : **à confirmer** car la stack mobile et le CLAUDE.md évoquent un abonnement géré via Stripe Checkout / Subscription, ce qui est généralement **renouvelable** par défaut.
- Article 6 — Droit de rétractation : conforme L221-18 et L221-28, valide.
- Article 7 — Engagements de l'Utilisateur : générique, valide.
- Article 8 — Disponibilité du service : valide.
- Article 9.3 — Limitation : valide.
- Article 10 — Données personnelles (renvoi vers `/confidentialite`) : valide.
- Article 11 — Modifications des CGU : valide.
- Article 12 — Médiation : structurellement valide (le médiateur reste à désigner).
- Article 13 — Loi applicable : valide.

**Sections à créer** :
- **Nouvelle section « Nature et limites du service »** (probablement à insérer juste après l'Article 4 — Description des services ou en tête de l'Article 9). Elle devra porter :
  - Le caractère **strictement pédagogique / d'entraînement** de la plateforme.
  - L'absence de qualité d'organisme officiel agréé pour faire passer l'examen ou le TCF.
  - La **non-substitution** aux organismes officiels (préfecture, France Éducation International, Ministère de l'Intérieur, centres agréés).
  - La **non-garantie de résultat** (échec à l'examen, niveau TCF non atteint, refus d'un titre de séjour ou de la nationalité). Cette clause est aujourd'hui partiellement dans 9.1 mais elle est noyée dans la « limitation de responsabilité » et n'aborde pas le TCF.
  - L'absence d'accompagnement aux démarches administratives (dépôt de dossier, ANEF, NATALI...). Cette mention n'existe **nulle part actuellement** dans les CGU.

**TODOs LEGAL_INFO impactés** (placeholders rendus à l'écran sur cette page) :
- `editor.legalName` (Article 1, l. 58).
- `mediator.name` / `mediator.address` / `mediator.website` (Article 12).
- `subscription.annualPriceTTC` actuellement « 29,90 € » : valeur à confirmer (Article 5.1).

**Points à confirmer avec l'éditeur (CGU)** :
- Les modules effectivement vendus dans l'offre Premium (CIVIQUE seul, TCF seul, ou les deux), et l'intitulé exact des plans Stripe (`CIVIQUE_3MOIS`, `INTEGRAL_3MOIS` selon le CLAUDE.md web).
- Reconduction de l'abonnement (oui / non) et durée réelle (3 mois ? 1 an ?).
- Nombre de questions et d'examens blancs gratuits par module — la règle métier mémorisée parle de 20 Q + 1 examen blanc par module, le code des CGU dit 5 Q + 1 examen blanc.
- Le nombre exact d'examens blancs Premium et leur format (40 questions chronométrées : valable pour civique, à confirmer pour TCF).

---

## Page : Mentions légales (`app/mentions-legales/page.tsx`)

**Dernière mise à jour** : 2026-05-09 (via `LEGAL_INFO.lastUpdated`).

**Sections actuelles** (8 articles) :
- Article 1 — Éditeur du site
- Article 2 — Directeur de la publication
- Article 3 — Hébergeur
- Article 4 — Propriété intellectuelle
- Article 5 — Liens hypertextes
- Article 6 — Responsabilité
- Article 7 — Loi applicable et juridiction compétente
- Article 8 — Contact

**À modifier** :

1. **Article 4 — Propriété intellectuelle** (l. 157-160) : « Les questions de l'examen civique sont la propriété du Ministère de l'Intérieur français et sont reproduites dans un cadre pédagogique conforme. »
   - Cette affirmation est **forte juridiquement** (revendique une reproduction conforme d'un corpus officiel). À vérifier avec un juriste : le contenu de la plateforme est-il une **reproduction** des questions officielles, ou une **adaptation pédagogique** rédigée par l'équipe SejourFR à partir des thématiques officielles ? La formulation actuelle laisse penser à une reproduction directe, ce qui exigerait une autorisation explicite.
   - **Aucune mention du corpus TCF** (qui relève de France Éducation International) → à compléter pour ne pas laisser un trou.

2. **Article 6 — Responsabilité** (l. 185-205) : globalement bien (le « plateforme de préparation indépendante » + désaffiliation officielle est exactement ce qu'on veut). **Mais** :
   - La mention « préparation indépendante… non affiliée au Ministère de l'Intérieur, à la **CCI Paris Île-de-France**, à France Éducation International » : la CCI Paris IDF gère le TEF (Test d'Évaluation de Français), pas le TCF. Si SejourFR ne couvre pas le TEF, mentionner la CCI n'a plus de sens et **doit être retiré**. À confirmer.
   - Les sources officielles listées (`service-public.fr`, `immigration.interieur.gouv.fr`, `formation-civique.interieur.gouv.fr`) : OK mais **incomplet** côté TCF (`france-education-international.fr` à ajouter).
   - L'expression « notamment celles relatives à l'examen civique et **aux procédures de naturalisation** » peut laisser entendre que la plateforme couvre les procédures de naturalisation elles-mêmes (hors périmètre). À reformuler pour rester sur l'examen et le test linguistique.

3. **Article 8 — Contact** : l'email utilisé est `editor.email` (= `contact@sejourfr.fr`), ce qui est cohérent avec la valeur seedée. À harmoniser avec les autres pages qui pointent vers `support@sejourfr.fr`.

**Sections valides** :
- Article 1 — Éditeur du site : structure valide (en attente des données EI).
- Article 2 — Directeur de la publication : valide.
- Article 3 — Hébergeur (IONOS) : valide.
- Article 5 — Liens hypertextes : valide.
- Article 7 — Loi applicable et juridiction : valide.

**Sections à créer** :
- **Phrase courte sur la nature pédagogique du service** + **non-substitution aux organismes officiels** : cette mention n'existe pas dans les mentions légales (elle est partiellement dans l'Article 6 mais centrée sur la « plateforme de préparation indépendante »). À renforcer en chapeau ou dans l'Article 6, en restant succinct (les mentions légales ne sont pas le bon véhicule pour développer — c'est dans les CGU que la clause complète vivra).

**TODOs LEGAL_INFO impactés** (placeholders sur cette page) :
- `editor.legalName` (Article 1, l. 53 ou 66 selon `company`).
- `editor.capital` (Article 1, l. 56) — `null` car EI.
- `editor.address` (Article 1, l. 58 ou 70).
- `editor.siret` (Article 1, l. 77).
- `editor.siren` (Article 1, l. 81).
- `editor.rcs` (Article 1, l. 57, conditionnel) — `null` car EI non commerçant.
- `editor.vatNumber` (Article 1, l. 86).
- `editor.phone` (Article 1, l. 101).
- `editor.publicationDirector` (Article 2, l. 111).
- `host.phone` (Article 3, l. 127).

**Points à confirmer avec l'éditeur (mentions légales)** :
- Statut juridique réel : `LEGAL_INFO.editor.legalForm = "EI"` est seedé. Si l'éditeur passe en SAS / SARL plus tard, la branche `isCompany()` s'activera automatiquement.
- Pertinence de mentionner la CCI Paris Île-de-France à l'Article 6.
- Reformulation exacte autour de la « reproduction des questions de l'examen civique » à l'Article 4 (cadre légal de l'utilisation du corpus).

---

## Page : Confidentialité (`app/confidentialite/page.tsx`)

**Dernière mise à jour** : 2026-05-09 (via `LEGAL_INFO.lastUpdated`).

**Sections actuelles** (Préambule + 14 articles) :
- Préambule
- Article 1 — Responsable du traitement
- Article 2 — Délégué à la Protection des Données (DPO)
- Article 3 — Données collectées (3.1 Données fournies / 3.2 Données automatiques / 3.3 Cookies)
- Article 4 — Finalités et bases légales du traitement
- Article 5 — Durée de conservation des données
- Article 6 — Destinataires de vos données
- Article 7 — Transferts hors Union européenne
- Article 8 — Cookies et traceurs (8.1 Définition / 8.2 Cookies utilisés / 8.3 Gestion des préférences)
- Article 9 — Vos droits (9.1 Liste / 9.2 Comment exercer / 9.3 Réclamation CNIL)
- Article 10 — Sécurité des données
- Article 11 — Violation de données
- Article 12 — Données des mineurs
- Article 13 — Modifications de la politique
- Article 14 — Contact

**À modifier** :

1. **Article 3.2 — Données collectées automatiquement** (l. 195-198) : « questions consultées, résultats aux examens blancs passés, progression par catégorie, score moyen, historique d'activité ». OK mais générique. **Vérifier** que cette description couvre bien :
   - Les sessions de **training infini** (et leur extension automatique cf. CLAUDE.md web).
   - Les **favoris** de questions (`POST|DELETE /api/me/questions/{id}/favorite`).
   - Les **erreurs** consultées en révision (`reviewQuestion`).
   - Le **target path** (CSP/CR/NAT, niveau TCF visé).
   Aucun de ces points n'est mentionné explicitement.

2. **Article 4 — Finalités et bases légales** (l. 215-237) : ne mentionne pas spécifiquement les finalités liées à la **stratégie cross-device** (compte unique web + mobile) ni le rapprochement avec l'application mobile. Mineur, mais à signaler si l'app mobile partage le même compte.

3. **Article 6 — Destinataires / sous-traitants** (l. 282-291) : le `LegalTable` est généré dynamiquement depuis `LEGAL_INFO.subProcessors` qui contient aujourd'hui **IONOS** + **Stripe** + un TODO pour le fournisseur d'email (Brevo / SendGrid / Resend / IONOS Mail). À compléter avant publication, sinon la liste sera incomplète.
   La pipeline TCF audio (Anthropic + Azure Speech + Cloudflare R2) documentée dans le CLAUDE.md racine **n'apparaît pas** dans les sous-traitants. À vérifier : ces flux concernent-ils des données personnelles utilisateur (probablement non, c'est de la génération admin de contenu), ou seulement du contenu pédagogique ? Si aucune donnée utilisateur n'y transite, aucun ajout à faire.

4. **Article 8 — Cookies et traceurs** (l. 327-389) :
   - L'Article 8.2 décrit des cookies « Préférences (choix de langue, thème clair/sombre) » alors que le CLAUDE.md web précise « Mode sombre : non prévu pour l'instant ». À aligner.
   - L'Article 8.3 mentionne un lien « Gérer mes cookies » en bas de chaque page **qui n'existe pas** dans le footer actuel (footer expose juste les liens vers les 3 pages). Le `LegalCallout` warning à la fin reconnaît d'ailleurs que la CMP est « en cours d'intégration ». À clarifier : soit développer la CMP, soit reformuler pour ne pas promettre une fonctionnalité absente.
   - Le tableau liste « Mesure d'audience » et « Analyse comportementale » comme cookies utilisés (avec consentement). À vérifier ce qui est **réellement** déposé aujourd'hui par l'application (probablement aucun analytics tiers, donc à retirer ou à signaler comme « à venir »).

5. **Article 10 — Sécurité des données** (l. 510-512) : « Authentification sécurisée par token JWT avec **rotation automatique** ». Le CLAUDE.md web précise qu'il y a un access (60 min) + refresh (30 j), mais que le **refresh automatique côté web n'est pas encore branché**. La rotation est donc partielle — à reformuler ou à valider qu'on parle bien des refresh tokens stockés en base côté backend.

6. **Article 11 — Violation de données** : valide.

7. **Article 14 — Contact** : email `support@sejourfr.fr` hardcodé alors que `editor.email = "contact@sejourfr.fr"`. Même incohérence que sur les autres pages.

**Sections valides** :
- Préambule : valide (sous réserve du remplissage de `editor.legalName`).
- Article 1 — Responsable du traitement : structure valide.
- Article 2 — DPO : valide (branche `dpo.designated = false` activée).
- Article 3.1 / 3.3 : valides.
- Article 4 — Finalités : tableau standard, valide.
- Article 5 — Durée de conservation : valide.
- Article 7 — Transferts hors UE : valide (branche `allInEu` activée car les 2 sous-traitants seedés sont UE).
- Article 9 (9.1, 9.2, 9.3) — Vos droits : valide (sous réserve du remplissage de `editor.address` pour le courrier postal).
- Article 11 — Violation de données : valide.
- Article 12 — Données des mineurs : valide.
- Article 13 — Modifications : valide.

**Sections à créer** :
- Aucune section structurelle manquante côté RGPD. Comme demandé dans le brief : pas de clause de non-garantie ici (hors sujet RGPD). Le travail sur cette page est purement d'alignement de précisions (finalités, sous-traitants, cookies réels, données collectées).

**TODOs LEGAL_INFO impactés** (placeholders sur cette page) :
- `editor.legalName` (Préambule + Article 1).
- `editor.address` (Article 1 + Article 9.2 « par courrier postal » + Article 14 « courrier »).
- `editor.siret` (Article 1).
- `subProcessors[]` : ajouter le fournisseur d'email transactionnel (TODO déjà noté ligne 129 de `legal-info.ts`).

**Points à confirmer avec l'éditeur (confidentialité)** :
- Fournisseur d'envoi d'emails réellement branché en prod.
- Présence ou non d'analytics tiers (Plausible, Matomo, Google Analytics, Posthog...). Aucun import correspondant n'a été repéré, donc probablement aucun → à confirmer.
- Existence ou non d'un mode sombre.
- Politique de durée des refresh tokens (l'Article 10 parle de « rotation automatique »).

---

## Politique cookies

**Statut actuel** : il n'y a **pas de page dédiée** `/cookies`. Le footer (`app/_components/Footer.tsx` l. 62) pointe vers l'ancre `/confidentialite#article-8`, c'est-à-dire l'Article 8 « Cookies et traceurs » de la page Confidentialité.

**Diagnostic de l'Article 8 actuel** (déjà détaillé ci-dessus) :
- Structure correcte (définition, liste des cookies, gestion du consentement).
- Trois faiblesses : (1) liste de cookies qui ne reflète pas l'état réel de l'app (mode sombre, analytics, CMP non déployés), (2) lien « Gérer mes cookies » promis dans le texte mais absent du footer et de toute autre surface, (3) `LegalCallout warning` reconnaît explicitement que la CMP n'est pas en place.

**Décision à prendre lors de la phase de mise à jour** :
- Option A : conserver l'ancre vers `/confidentialite#article-8` et corriger l'Article 8 (le plus simple, conforme à ce qui existe déjà).
- Option B : extraire en page dédiée `/cookies` (recommandé pour SEO et accessibilité si la CMP est réellement déployée, mais plus de travail).

---

## Synthèse globale

### Volumétrie estimée des modifications

| Page | Sections à reformuler / aligner | Sections à créer | Lignes touchées (estimation) |
|---|---|---|---|
| CGU (`app/cgu/page.tsx`, 447 l.) | ~5 (Articles 2, 4.1, 4.2, 9.1, 9.2) + harmonisation email contact | 1 nouvelle section « Nature et limites du service » (à insérer après Art. 4 ou en tête d'Art. 9), portant la clause de non-garantie élargie aux 2 modules | ~80 lignes touchées + ~50 lignes ajoutées |
| Mentions légales (`app/mentions-legales/page.tsx`, 247 l.) | ~2 (Articles 4 et 6) | Insertion **courte** d'une phrase « nature pédagogique + non-substitution organismes officiels » (probablement dans l'Article 6 existant, sans créer d'article supplémentaire) | ~25 lignes touchées + ~10 lignes ajoutées |
| Confidentialité (`app/confidentialite/page.tsx`, 597 l.) | ~4 (Articles 3.2, 6, 8 tout entier, 10) | Aucune section structurelle nouvelle | ~60 lignes touchées |
| `content/legal/legal-info.ts` (159 l.) | Remplir les ~10 TODOs (`legalName`, `address`, `siret`, `siren`, `vatNumber`, `publicationDirector`, `phone`, `mediator.*`, fournisseur email) + vérifier `annualPriceTTC` | — | ~20 lignes touchées |
| **Total** | **~11 sections à reformuler** | **1 nouvelle section CGU + 1 paragraphe mentions légales** | **~245 lignes** |

### Points qui nécessitent une décision éditoriale / juridique avant rédaction

1. **Périmètre exact de la clause de non-garantie de réussite** (CGU, futur « Nature et limites du service ») : doit-elle couvrir nominativement (a) l'échec à l'examen civique officiel, (b) le niveau TCF non atteint, (c) le refus d'un titre de séjour, (d) le refus de naturalisation, ou seulement (a) + (b) ?
2. **Statut juridique de l'usage du corpus de l'examen civique officiel** (mentions légales Article 4) : reproduction directe (nécessite autorisation) ou adaptation/inspiration pédagogique ? La formulation actuelle est ambiguë et juridiquement risquée.
3. **Désaffiliation explicite des organismes** : qui doit être nommé ? Ministère de l'Intérieur, France Éducation International, préfectures, centres d'examen agréés. La mention actuelle de la **CCI Paris Île-de-France** semble obsolète (CCI = TEF, pas TCF) → à confirmer / retirer.
4. **Cohérence email contact** : `contact@sejourfr.fr` (dans `LEGAL_INFO.editor.email`) vs `support@sejourfr.fr` (hardcodé partout dans les pages). Choisir une adresse unique avant publication.
5. **Cohérence règle de démo** : la mémoire produit dit « 20 questions gratuites + 1 examen blanc par module », les CGU disent « 5 questions par catégorie + 1 examen blanc ». Aligner avec la valeur réellement implémentée côté backend.
6. **Reconduction abonnement** : non reconductible (Article 5.3) contredit potentiellement l'usage Stripe Subscription. Trancher selon l'offre commerciale réelle.
7. **CMP cookies** : déploiement effectif d'une bannière + module « Gérer mes cookies », ou reformulation de l'Article 8 pour refléter qu'il n'y a aujourd'hui que des cookies strictement nécessaires (auth / sécurité).
8. **Page cookies dédiée ou ancre** : maintenir `/confidentialite#article-8` ou créer `/cookies`.
9. **Sort du composant orphelin `LegalFooterNav`** : intégrer dans les 3 pages légales ou supprimer.
10. **TODOs `LEGAL_INFO` à valeurs réelles** : raison sociale EI, adresse, SIRET, SIREN, TVA, téléphone, directeur de publication, médiateur agréé, fournisseur email transactionnel — sans ces données, les pages restent visiblement « brouillon » via le composant `Placeholder` (badge ambre).

### Surprises / points hors brief

- **Composant `LegalFooterNav` orphelin** (zéro référence dans les 3 pages), à statuer.
- **Disparité d'emails** (`contact@` vs `support@`) jamais signalée explicitement dans `LEGAL_INFO`.
- **Décompte de lignes plus faible** que prévu dans le brief (447 / 247 / 597 vs 484 / 264 / 641) — sans impact, simple écart d'estimation.
- **Article 6 mentions légales** contient déjà partiellement la phrase de « plateforme de préparation indépendante » : on peut donc s'appuyer dessus plutôt que créer un nouveau bloc.
- **Aucun trou critique** : les 3 pages couvrent l'essentiel des obligations LCEN / consommation / RGPD. Le travail à venir est de l'**alignement** au périmètre produit (modules réels, fonctionnalités effectivement livrées, sous-traitants à jour, données EI), pas une refonte structurelle.
