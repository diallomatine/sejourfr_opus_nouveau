# Comment l'IA corrige les productions (Expression Écrite & Orale)

> **À qui s'adresse ce document ?** À tout le monde — pas besoin d'être développeur.
> Il explique, en langage simple, **comment l'intelligence artificielle note** ce que le
> candidat écrit (EE) ou dit à l'oral (EO) sur SejourFR, tâche par tâche, et **selon quelles
> règles**. Il dit aussi **ce qui marche, ce qui marche mal, et comment on le sait**. Une
> version plus technique (fichiers, code, base de données) existe dans
> [`pipeline-evaluation-eo-ee.md`](pipeline-evaluation-eo-ee.md) ; ce document-ci est le
> « pourquoi et le quoi », pas le « comment c'est branché ».

> ⚠️ **Ce document doit rester à jour et exhaustif.** Dès qu'on change **une règle de
> notation, un barème, un critère, une consigne donnée à l'IA, une tâche, le comportement de
> l'examinateur vocal, ou le déroulé d'une correction**, il faut mettre à jour ce fichier
> **dans la même passe**. Il doit toujours pouvoir être lu et compris par une personne non
> technique. Pas de jargon non expliqué, pas de raccourci.

**État actuel** : rubriques de notation **v15** (profil **TCF IRN**, plafonné à B2 — **la
notation y est celle de la v9, au caractère près**), format de réponse strict **v9**,
examinateur vocal **v3**. Ce que ces numéros veulent dire, et où ils se
changent, est expliqué en §15. Pour la **seconde voie d'évaluation** — les micro-exercices par
compétence, **sans note sur 20 mais désormais avec un niveau** — les versions sont **v3 / v3**,
plus un **second appel séparé** en **v1 / v1** ; tout est décrit au §11 bis.
Le diagnostic initial et l'observateur du Plan utilisent une **troisième voie**, elle aussi
sans note sur 20, avec leurs propres consignes et format **v1 / v1** décrits juste dessous.

> 🆕 **11 août 2026 — le rapport maigrit : plus de « suggestions » ni d'« exemples corrigés ».**
> Explication complète au **§5.7 bis**.
>
> **Ce qui change à l'écran.** Le bloc replié **« Voir l'analyse complète »** disparaît du
> résultat d'une production écrite ou orale. C'était le seul endroit où s'affichaient les
> **exemples corrigés** et les **suggestions** : ces deux blocs disparaissent avec lui.
>
> **Ce qui change côté correcteur.** L'IA ne les écrit même plus : les consignes **v15** ne les
> demandent plus, et le format de réponse **v9** ne prévoit plus de case pour les loger. Deux
> raisons, qui vont dans le même sens : un pavé qu'il faut déplier n'est pas lu, et tout ce que
> l'IA écrit se paie — ce budget finance désormais la **version au niveau que vous visez**
> (§5.9), qui, elle, est en évidence.
>
> **Ce qui ne change pas.** Rien de ce qui note. La v15 est la v14 **au caractère près** pour
> l'échelle, les quatre critères, les seuils, le couplage, les plafonds, les bandes, les tests
> décisifs et les 16 exemples de calibration — un test le vérifie et casse la construction
> sinon. Restent aussi produits l'**accomplissement** (verdict, résumé, points traités et
> oubliés), qui alimente le haut de l'écran et un contrôle serveur, et les **avertissements**,
> que le serveur écrit lui-même. ⚠️ **Aucune campagne de mesure n'a été lancée**, et c'est
> assumé : aucune règle de notation ne bouge, et le prompt **perd** du texte au lieu d'en
> gagner. Retour en arrière : `EVAL_RUBRICS_VERSION=v14` + `EVAL_PROMPT_VERSION=v8`.
>
> **Les corrections déjà rendues gardent leurs deux blocs**, intacts et lisibles : on versionne,
> on ne réécrit jamais un résultat déjà rendu.

> 🆕 **9 août 2026 — un diagnostic court initialise un Plan de travail, sans se faire passer
> pour un examen TCF.** Le candidat réalise deux exercices hybrides fixes et versionnés : un
> écrit de **100 à 130 mots**, puis un oral enregistré de **2 à 3 minutes** précédé d'une
> consigne audio fixe. Ce ne sont ni les tâches officielles 1, 2 ou 3, ni un `TCF_COMPLET`.
> Le diagnostic est offert une fois par version à chaque compte et ne consomme aucun quota
> d'entraînement EE/EO.
>
> **Ce que l'IA fait, dans cet ordre.** Elle vérifie l'accomplissement de l'exercice, puis si
> la communication fonctionne, observe uniquement les compétences autorisées pour ce sujet,
> et enfin propose une estimation prudente entre « A1 non atteint » et B2. Elle ne produit
> **aucune note sur 20** et cette estimation n'est jamais présentée comme un résultat officiel
> du TCF. Une compétence absente est dite « non observée » : elle n'est pas inventée ni
> transformée en faiblesse. Chaque constat observé désigne un morceau réel de la production ;
> le serveur remplace ce numéro par le texte exact avant de l'enregistrer et de l'afficher.
>
> **À l'oral, l'IA ne reçoit que la transcription.** Elle peut donc parler du contenu, du
> lexique, de la grammaire et de la cohérence. Elle ne peut rien conclure sur la prononciation,
> l'accent, l'intonation, le débit, la qualité acoustique ou une véritable interaction avec un
> examinateur. La consigne audio est créée explicitement par un administrateur, stockée et
> vérifiée dans R2 ; elle n'est jamais régénérée au démarrage d'une session.
>
> **Le résultat commun est assemblé par le serveur, sans troisième appel.** Chaque production
> déclenche un appel d'analyse et, seulement si le format reçu est invalide, une unique demande
> de réparation. Les deux réponses structurées sont ensuite réunies de façon déterministe :
> au plus deux priorités peuvent venir d'une production et au plus trois figurent dans le Plan.
> Le contrat exige exactement l'allowlist du sujet, des codes sans doublon, une preuve réelle,
> un niveau de confiance et des textes courts. Une réponse vide, illisible ou sans appel de
> l'outil est considérée comme transitoire et peut être relancée dans la limite prévue.
>
> **Le Plan reste distinct des statistiques.** Il conserve des observations sourcées
> (`diagnostic écrit`, `diagnostic oral`, `production complète écrite/orale` ou
> `micro-exercice`), leur date, leur preuve, leur confiance et le fait qu'elles appartiennent
> ou non au diagnostic de référence. Les productions complètes futures gardent leur correction
> v15/v9 habituelle ; une observation structurée séparée actualise ensuite le Plan, et son
> échec ne peut jamais faire échouer la correction déjà obtenue. Un micro-exercice ciblé peut
> confirmer qu'un point reste prioritaire, mais **une seule réussite ne suffit jamais à déclarer
> une compétence solide**.
>
> **Séparation technique volontaire.** Les consignes
> `diagnostic-analysis-rubrics-v1.json` et le format
> `diagnostic-analysis-tool-schema-v1.json` ne passent jamais par la notation v15/v9, la table
> des évaluations notées, la version au niveau visé ou la calibration. Comme pour tout contrat
> livré, on créera une nouvelle version au lieu de réécrire v1. Les invariants et formats ont
> été testés sans appeler de fournisseur payant ; aucune campagne de mesure comparative du
> jugement pédagogique n'a donc été menée pour cette première version.

> 🆕 **14 août 2026 — à la fin du diagnostic, votre phrase et la même phrase au niveau que
> vous visez.** L'écran de résultat montre désormais un **avant / après** : une phrase que
> vous avez réellement écrite, puis cette même phrase réécrite comme l'écrirait quelqu'un au
> palier qu'exige votre démarche (A2, B1 ou B2). Deux ou trois passages de la version réécrite
> sont mis en évidence, avec une étiquette de trois mots qui dit ce qu'ils apportent
> (« lien explicite », « précision concrète »). Le but n'est pas de vous dire ce qui ne va
> pas : c'est de vous montrer à quoi ressemblerait **votre propre phrase** un cran plus haut.
>
> **La phrase affichée est bien la vôtre, au caractère près.** L'IA ne la recopie pas — elle
> désigne un numéro de phrase, et c'est le serveur qui va chercher le texte exact dans ce que
> vous avez écrit. Elle ne peut donc pas vous attribuer une phrase que vous n'avez pas écrite.
> La version réécrite garde votre situation, vos faits, vos prénoms, vos chiffres et votre
> intention : seule la langue monte d'un cran. Rien n'est inventé.
>
> **Uniquement à l'écrit, et c'est délibéré.** Votre production orale n'est jamais réécrite.
> Ce que nous lisons de l'oral est une transcription automatique : afficher un beau texte à la
> place de ce que vous avez dit serait trompeur. C'est la même règle que pour les corrections
> complètes.
>
> **C'est un appel séparé, qui ne touche pas au jugement.** L'IA qui analyse votre diagnostic
> ne sait pas qu'une réécriture aura lieu, et ne sait pas quel niveau vous visez : ses
> consignes n'ont pas changé d'une virgule. Nous avons mesuré ailleurs qu'ajouter le niveau
> visé à une grille qui juge dégrade sa fiabilité (accord exact 81,8 % → 75,6 %). La
> réécriture est donc produite **après**, à part, par une seconde demande.
>
> **Ce bloc peut être absent, et ce n'est pas une panne.** Il n'apparaît pas si vous écrivez
> déjà au niveau que vous visez (il n'y aurait rien à montrer), ni si la seconde demande
> n'aboutit pas. Votre diagnostic, vos priorités et votre Plan sont complets dans tous les
> cas : cette réécriture est un plus, jamais une pièce dont dépend le résultat. Les
> diagnostics passés avant cette date n'en ont pas — nous ne rejouons rien a posteriori.
>
> **Aucune campagne de mesure n'était requise** : rien de ce qui note ne bouge, par
> construction. Les consignes de la réécriture vivent dans leurs propres fichiers versionnés
> (`diagnostic-exemple-cible-rubrics-v1.json` et son format de sortie), et le tout se coupe
> par une seule variable si besoin.

> 🆕 **8 août 2026 — sur une tâche isolée, plus de note sur 20 : votre niveau, et où vous en
> êtes DANS ce niveau.** Explication complète aux **§6.2 bis** et **§6.3 bis**.
>
> **Le problème.** Au TCF, un correcteur humain donne un **niveau** à chaque tâche ; la note
> sur 20, elle, porte sur **l'épreuve entière** (les trois tâches). Et sur l'échelle
> officielle, où **10 sur 20 vaut déjà B2**, un « 3,5/20 » est un **A2 tout à fait normal** —
> mais tout le monde a appris à l'école qu'un 3,5/20 est un naufrage. Nous affichions donc,
> sous une production correcte pour son niveau, un chiffre qui se lisait comme un échec.
>
> **Ce qu'on a fait.** Le résultat d'une tâche montre désormais le **niveau** et la **situation
> dans ce palier**, en trois crans encourageants : *A2 atteint*, *A2 confirmé*, *A2 solide*.
> Jamais « presque B1 » — le vocabulaire du manque est exactement ce qu'on retire. Sans ce
> remplacement, un A2 « juste entré » et un A2 « très solide » auraient vu le même écran deux
> fois de suite, sans savoir s'ils avaient progressé.
>
> **Ce qui n'a pas bougé** : rien dans le calcul. La note est produite, enregistrée et affichée
> exactement comme avant — mais **au bilan de l'épreuve**, là où elle a un sens. C'est un
> changement d'affichage, pas de notation, donc aucune campagne de mesure n'est requise.

> 🆕 **8 août 2026 — à l'écrit, vous voyez votre réponse rédigée au niveau que VOUS visez.**
> Explication complète au **§5.9**.
>
> **Le problème.** Le rapport montrait déjà votre copie réécrite **au palier juste au-dessus**.
> Utile — mais quelqu'un qui prépare une **naturalisation** doit atteindre le **B2** : s'il
> écrit du A2 aujourd'hui, voir une version B1 ne lui dit pas où est l'arrivée.
>
> **Ce qu'on a fait.** Le rapport écrit contient en plus **la même réponse rédigée au niveau
> que vous visez** (celui de votre démarche), avec **deux ou trois choses précises** à
> travailler pour y arriver. Vos idées, vos faits, votre position — seule la langue monte.
>
> **Le point important, et c'est la raison même du montage** : cette version est produite par
> un **deuxième appel à l'IA, complètement séparé de la correction**. Le correcteur qui vous
> note **n'apprend jamais quel niveau vous visez** — sinon il aligne sa note dessus. Nous
> avons déjà mesuré, ici, qu'ajouter un simple bloc de texte à la grille de notation
> **dégrade** la notation (§8 quater). Si ce second appel échoue, votre correction reste
> entière : seul cet encart manque.

> 🆕 **8 août 2026 — le rapport qui vous est rendu est écrit en français correctement
> accentué.** Explication complète au **§10 bis**.
>
> **Le problème, constaté en vraie utilisation.** L'IA rendait des phrases comme « Excuse
> formulee », « le passe compose est maitrise et employe a bon escient », « J'espere que cette
> date te convient ». Les accents tombaient presque systématiquement. Sur une plateforme qui
> **enseigne le français**, corriger l'orthographe de quelqu'un dans un français mal
> orthographié est inacceptable : on lui apprend une faute au moment même où on lui en corrige
> une.
>
> **Ce qu'on a fait.** Deux choses, aucune ne touche la notation :
> 1. une **règle explicite** ajoutée aux consignes (grille **v13**) : *tout le français que tu
>    écris est accentué* — et, tout aussi important, *tout ce que tu cites du candidat se
>    recopie tel quel, accents manquants compris* ;
> 2. les **consignes du format de réponse ont elles-mêmes été réaccentuées** (format **v7**).
>    C'est la cause la plus probable du défaut : nos consignes étaient écrites sans accents, et
>    une IA imite la langue de ce qu'elle lit. Un contrôle automatique vérifie qu'entre v6 et
>    v7 **seuls des accents ont changé** — pas un mot, pas une virgule.
>
> **Ce qui n'a pas bougé** : l'échelle, les quatre critères, les seuils, les garde-fous, les
> plafonds, les exemples de calibration, les consignes de chaque tâche — **rien de ce qui
> note**, et un test le vérifie fichier contre fichier. Retour en arrière :
> `EVAL_RUBRICS_VERSION=v12` + `EVAL_PROMPT_VERSION=v6`, sans migration.
>
> ⚠️ **Ce changement n'a pas été passé au banc de mesure** (§12) : une campagne appelle une IA
> payante, et aucun appel payant n'était autorisé. Il ne touche aucune règle de notation, donc
> il n'en demande pas — mais il faut le dire : **on n'a pas mesuré combien d'accents sont
> réellement revenus.** C'est précisément pourquoi on a ajouté un **compteur** (§10 bis).

> 🆕 **8 août 2026 — l'IA ne recopie plus vos phrases pour justifier sa note : elle les
> DÉSIGNE.** C'est le changement le plus important de cette page, et il supprime une
> catégorie entière de pannes. Explication complète au **§5.5**.
>
> **Le problème.** Chaque critère noté doit s'appuyer sur un extrait de votre production.
> Jusqu'ici, l'IA **recopiait** cet extrait, et notre serveur vérifiait ensuite qu'il existait
> bien, mot pour mot. Une IA qui recopie peut se tromper — pas sur le fond, sur la **copie** :
> elle « nettoie » un bégaiement, elle normalise une graphie, elle recolle deux morceaux. Sa
> preuve était juste, sa copie ne l'était pas, et la correction était refusée. Sur des
> productions **orales**, le moteur en vigueur voyait ainsi **42,9 % de ses réponses
> refusées** par nos propres contrôles.
>
> **Cas réel du 7 août 2026** (une vraie session d'oral) : deux corrections refusées coup sur
> coup, puis une note rendue en mode dégradé. Les deux citations étaient pourtant **exactes**.
> Le candidat avait bégayé — « une sœur qui se trouve **tous tous** chez moi », « j'aime bien
> les **les films les films** comédies » — et l'IA avait simplement écrit la phrase sans le
> bégaiement, ce que nos consignes lui demandent par ailleurs de ne pas juger.
>
> **Ce qu'on a fait**, dans cet ordre :
> 1. **Les bégaiements ne font plus échouer une citation fidèle** — même traitement que les
>    « euh » depuis le mois dernier. Un mot ou un petit groupe de mots répété d'affilée dans
>    la production peut n'apparaître qu'une fois dans la citation. Cela ne dispense d'aucun
>    autre mot, et le texte finalement affiché reste **le vôtre, bégaiements compris**.
> 2. **Surtout : on a supprimé la recopie.** La production est désormais envoyée à l'IA
>    **découpée en morceaux numérotés** — un numéro par prise de parole à l'oral, un numéro
>    par phrase à l'écrit — et l'IA ne renvoie plus qu'un **numéro**. Inventer une citation
>    n'est plus « interdit » : c'est **impossible**. La seule erreur qui lui reste possible est
>    de donner un numéro qui n'existe pas, ce qui se voit immédiatement et se corrige en un
>    aller-retour. Le serveur remplace ensuite le numéro par le texte exact du morceau : **ce
>    que vous lisez à l'écran ne change pas d'un caractère**.
>
> **Ce qui n'a pas bougé** : l'échelle, les quatre critères, les seuils, les garde-fous, les
> plafonds, les tests décisifs entre niveaux, les exemples de calibration, les consignes de
> chaque tâche. **Rien de ce qui note n'a été touché**, et un test automatique le vérifie
> fichier contre fichier.
>
> ⚠️ **À dire franchement : ce changement n'a PAS été passé au banc de mesure** (§12), parce
> qu'une campagne de mesure appelle une IA payante et qu'aucun appel payant n'était autorisé.
> Ce qui le rend défendable sans mesure : il ne touche aucune règle de notation, et le peu
> qu'il change dans les consignes **retire une contrainte** au lieu d'en ajouter une. Le
> retour en arrière tient en **deux variables** (`EVAL_RUBRICS_VERSION=v9` +
> `EVAL_PROMPT_VERSION=v5`) et ne demande aucune migration.

> 🆕 **Correcteur en vigueur : `deepseek-v4-flash` — choix ARBITRÉ ET CLOS le 16 août 2026,
> pour sa RAPIDITÉ.** **Aucune règle de notation n'est en jeu** : mêmes rubriques, même
> format de réponse, mêmes seuils, mêmes garde-fous. Seul le moteur qui lit les consignes
> était en discussion.
>
> **Le motif est le temps d'attente du candidat** : pris appel par appel, `flash` répond en
> **16,3 s** en médiane et **36 s** au pire, contre **28,8 s** et **66,7 s** pour
> `deepseek-v4-pro`. Et la justesse, elle, ne s'est pas gagnée en changeant de moteur : la
> campagne du 16 août a fait monter l'accord exact de **14,5 points sans toucher au modèle**,
> uniquement par les contrats de sortie et les contrôles automatiques. Détail au **§12.6** ;
> ce que coûte réellement une correction, au **§12.6 bis**.
>
> Trois moteurs ont été comparés sur les mêmes 48 cas les 7 et 8 août 2026 (§12.6). **Une
> partie de cette comparaison s'est révélée faussée** : les trois campagnes n'ont pas accordé
> le même nombre de réessais au correcteur (jusqu'à **9** pour `flash`, **3** pour
> `deepseek-v4-pro`, **1** pour `gpt-5.4`), alors qu'en vraie utilisation il n'y a **qu'un
> seul réessai** avant l'échec. Ce qui se lisait comme « `flash` ne perd jamais de
> correction » disait en réalité « `flash` a eu neuf vies ». **Ce point est retiré du
> dossier** ; il ne faut pas s'y appuyer.
>
> Ce qui reste établi, et qui est **contre-intuitif — le fait le plus important de cette
> page** : **le modèle qui s'appelle « pro » coûte plus cher que celui qui s'appelle
> « flash »** (1,12 $ contre 0,91 $ pour la même campagne de 48 corrections), sans lui être
> supérieur : il **rate la moitié des cas-pièges** (4/8 contre 8/8) et classe **4 B2 sur 7 en
> B1**. Le nom commercial d'un modèle ne dit rien de son aptitude à corriger une production
> TCF, ni de son prix relatif. Un futur lecteur tenté de « corriger » ce choix en repassant
> au « pro » parce que le nom sonne mieux ferait une erreur : **il faut remesurer**, et cette
> fois à nombre de réessais égal.
>
> **Ce qu'on sait du coût réel du choix `flash`.** Une réponse de `flash` sur quatre est
> **refusée par nos propres contrôles** (citation qui ne se retrouve pas mot pour mot dans la
> production, conseil fondé sur un élément qu'on s'interdit de juger à l'oral) : **27,3 % de
> ses appels, et 42,9 % sur les seules productions orales**. Chaque refus est un appel
> facturé en double, et — en vraie utilisation, où le réessai est unique — **un risque réel
> de correction non rendue**. `deepseek-v4-pro` refuse moins (17,9 % ; 31,2 % à l'oral),
> `gpt-5.4` ne refuse jamais (0 %). C'est ce chiffre-là, et non la ligne « corrections
> perdues » du banc, qui a pesé dans l'arbitrage — et il se traite du côté de **nos
> contrôles**, pas en changeant de fournisseur. Comparaison colonne par colonne au
> **§12.6** ; changer de moteur reste affaire de quelques lignes de configuration.

> 🆕 **7 août 2026 — on ne vous reproche plus une langue étrangère que vous n'avez pas
> parlée.** Le transcripteur de l'oral **en temps réel** change parfois de langue tout seul :
> il rend en russe, en arabe ou en néerlandais un passage qu'il a mal capté. Le correcteur
> reprochait alors au candidat d'« être passé à une autre langue ». Notre serveur **retire
> désormais ces reproches du rapport**, automatiquement, et le dit franchement au candidat.
> **À l'écrit, rien ne change** : là, c'est bien le candidat qui a tapé chaque mot, et une
> langue étrangère reste une vraie non-réalisation. Un garde-fou chiffré empêche que cette
> protection efface le cas d'un candidat qui répond **réellement** dans une autre langue. Ni la
> note, ni le niveau, ni aucun seuil ne bougent. Détail complet, chiffres réels et versions de
> grille écartées au **§8 quater**.

> 🆕 **Ce que change la v9 : la lecture de l'oral.** La façon de **noter** est celle de la
> v8 — mêmes critères, même échelle, mêmes seuils, mêmes garde-fous, mêmes exemples de
> calibration, mêmes grilles par tâche, au caractère près. Deux sections seulement ont été
> réécrites, et elles ne concernent que l'**oral** :
>
> 1. **Un mot mal transcrit n'est plus reproché au candidat.** Ce que l'IA lit est produit par
>    une reconnaissance vocale faillible. Un mot qui n'existe pas en français, ou dont une
>    relecture proche par le son rend la phrase cohérente, est un **artefact** : l'IA évalue ce
>    que le candidat a voulu dire et ne cite ce passage **nulle part** (§8 bis). L'échappatoire
>    est fermée : une vraie erreur de langue reste une erreur.
> 2. **Le déroulé du dialogue compte.** L'examinateur a-t-il répondu à propos ? a-t-il dû faire
>    répéter ? l'échange s'est-il maintenu ? Ces indices, tous lisibles dans le texte, entrent
>    dans « communiquer » et « interagir » (§8 ter) — sans jamais toucher au garde-fou de
>    l'oral : une relance de l'examinateur **n'est pas** une hésitation du candidat.
>
> Mesurée au banc contre un témoin v8 rejoué le même jour, **avec le même moteur et le même
> budget de réessais** (ce qui rend cette comparaison-ci valide, à la différence de celle des
> moteurs au §12.6) : accord exact **74,5 % → 81,3 %**, pièges évités **4/8 → 8/8**, appels
> refusés par nos contrôles **37,3 % → 27,3 %**, corrections perdues **2,1 % → 0 %**. Un recul
> à signaler : l'accord de confiance baisse (53,2 % → 45,8 %). Détail et réserves au **§12.4**.

> 🆕 **Ce que la v8 avait changé : le rapport, pas la note.** La façon de **noter** est celle de la
> v7, à l'identique — mêmes critères, même échelle, mêmes seuils, mêmes garde-fous, mêmes
> exemples de calibration. Rien de ce qui produit une note n'a bougé, et aucune campagne de
> mesure n'était donc nécessaire. Ce qui change, c'est **ce que le candidat lit**, parce que
> le rapport rendu était répétitif, scolaire et parfois contradictoire :
>
> 1. **La confiance dit ce que le correcteur sait, jamais ce que le candidat vaut.** Une
>    production faible mais lisible est corrigée avec une confiance **haute** : un niveau bas
>    est une **observation**, pas un doute (§7).
> 2. **Une erreur, un seul endroit.** Un même fait de langue n'est plus traité trois fois de
>    suite sous trois formes différentes (§5.7).
> 3. **On ne reproche jamais un moyen que la consigne n'exigeait pas.** L'absence d'un temps
>    du passé sur une tâche qui n'en demande pas devient « ce qui te ferait gagner un
>    niveau », plus « aucun second temps maîtrisé » (§5.7). ⚠️ C'est une règle de
>    **formulation** : elle ne change **rien** au raisonnement de notation.
> 4. **Le rapport ne se contredit plus.** Un point demandé mais mal formulé est **présent** :
>    la réserve porte sur la forme, jamais sur la présence (§5.4).
> 5. **Un verdict clair en tête d'écran** : « Objectif de la tâche : atteint / partiellement
>    atteint / non atteint », avec une phrase qui dit ce que le candidat a fait (§5.4).
> 6. **Au plus deux points forts** et **au plus deux priorités** (§5.5). ⚠️ Les **exemples
>    corrigés** et les **suggestions** ne sont plus produits du tout depuis les consignes
>    **v15** : le bloc replié qui les affichait a disparu de l'écran (§5.7 bis).
> 7. **À l'écrit, un texte modèle de la copie entière**, avec les seules idées du candidat.
>    ⚠️ Le seul qui existe est la **version au niveau VISÉ** (§5.9), qui nomme son palier ; la
>    « version améliorée » du palier juste au-dessus (§5.8) a été retirée de l'écran, puis
>    **supprimée de la correction** par les consignes v14 — recopiée telle quelle, elle rendait
>    la même note. Rien de tel à l'oral.

> 🔒 **Ce que verrouille toujours la v7, conservé tel quel en v8.** C1/C2 sont hors du contrat
> actif : SejourFR prépare uniquement le **TCF IRN**, dont le niveau rapporté ici s'arrête à
> **B2**. Exactement quatre critères, refus de toute réponse incomplète avant correction, puis
> une seule tentative automatique de réparation. Les bornes EE sont strictes : **30–60 mots en
> T1 et 40–90 mots en T2/T3**, sans aucune marge (l'ancienne tolérance de 20 % est supprimée).
> ⚠️ **Le minimum de T2/T3 valait 60 par erreur** jusqu'à la migration **V724** : une copie de
> 40 à 59 mots, parfaitement recevable au TCF IRN, était **refusée à tort** avant d'atteindre
> le correcteur. C'est corrigé, et les bornes ne sont plus écrites qu'à **un seul endroit** —
> voir l'encadré du §2.

---

## 1. De quoi on parle : EE et EO

Le TCF IRN (le test de français exigé pour le titre de séjour, la résidence ou la
naturalisation) comporte deux épreuves où le candidat **produit** du français — au lieu de
juste cocher des cases :

- **EE — Expression Écrite** : le candidat **écrit** un texte (un message, un courriel, une
  opinion).
- **EO — Expression Orale** : le candidat **parle** (il s'enregistre, ou il dialogue avec un
  examinateur).

Dans les deux cas, il n'y a pas de « bonne réponse unique ». C'est une **appréciation** :
une IA joue le rôle d'un correcteur d'examen et attribue une note et des commentaires.

Chaque épreuve a **3 tâches** (T1, T2, T3), de difficulté croissante. Six tâches en tout :
EE T1, EE T2, EE T3, EO T1, EO T2, EO T3.

> **Deux façons d'être corrigé, à ne pas confondre.** Ce document décrit d'abord la correction
> d'une **tâche complète** : une production entière, une note sur 20, un niveau. C'est la voie
> principale, et c'est elle qui est mesurée (§12). Il existe aussi des **micro-exercices par
> compétence**, où le candidat travaille **une seule capacité à la fois** : l'IA y rend un
> verdict sur cette capacité **et un niveau**, mais **jamais de note sur 20**. Cette seconde voie
> est décrite au **§11 bis**, et n'a **pas** de banc de mesure : c'est dit là-bas sans détour.

---

## 2. Les 6 tâches, en clair

| Tâche | Ce que le candidat doit faire | Format attendu | Niveau visé |
|-------|-------------------------------|----------------|-------------|
| **EE T1** | Écrire un **message court** : annoncer quelque chose, décrire, inviter | 30 à 60 mots | A2 |
| **EE T2** | Écrire un **message développé** : raconter, décrire, expliquer, conseiller | 40 à 90 mots | B1 |
| **EE T3** | **Donner son opinion** et l'argumenter, ou comparer | 40 à 90 mots | B2 |
| **EO T1** | **Se présenter** et parler de soi, de son quotidien (entretien dirigé) | ~3 min (min. 2 min) | A2 |
| **EO T2** | **Interagir** dans une situation de la vie courante (obtenir / donner des informations) | ~3 min 30 (min. 2 min) | B1 |
| **EO T3** | **Donner un point de vue** en continu (petit monologue argumenté) | ~3 min 30 (min. 2 min) | B2 |

> 🧭 **Ces bornes n'ont qu'UNE source.** Elles vivent en base (`production_tasks.mots_min` /
> `mots_max`) et sont injectées telles quelles dans les consignes envoyées au correcteur, sous
> « LONGUEUR ATTENDUE ». Elles ne sont **plus** recopiées dans la grille de notation ni dans le
> contrat de sortie : celles-ci y **renvoient**. C'est la correction d'un vrai défaut — quand
> la migration **V724** a abaissé le minimum de T2/T3 de 60 à **40** (il refusait des copies
> recevables), la base et la grille se sont mises à dire deux choses contradictoires **dans le
> même message** : « longueur attendue : 40 à 90 » d'un côté, « bornes respectées exactement —
> 60 à 90 » de l'autre. Conséquence concrète pour le candidat : la version améliorée qu'on lui
> rendait alors (§5.8, depuis supprimée) visait 60-90 mots même sur une copie de 45 mots
> parfaitement valide.
> ⚠️ Les versions de grille **déjà livrées** (v8 à v11, contrat de sortie v5) gardent leurs
> bornes historiques 60-90 : c'est la trace exacte de ce avec quoi les copies déjà corrigées
> l'ont été, et on ne réécrit jamais une grille livrée. **Revenir en arrière sur la version des
> consignes réintroduit donc la contradiction** — c'est écrit dans la configuration, à
> l'endroit où le retour arrière est décrit.
>
> ⚠️ **TCF IRN ≠ TCF Canada — piège classique sur les longueurs.** Les bornes ci-dessus
> (30-60 / 40-90 / 40-90 mots) sont bien celles du **TCF IRN**, l'examen que prépare
> SejourFR. Les valeurs **60-120 et 120-180 mots** que renvoient la plupart des pages web
> appartiennent au **TCF Canada**, un autre examen. La confusion est très fréquente en ligne,
> y compris sur des sites de préparation : **ne pas « corriger » nos bornes d'après une
> recherche web** sans avoir vérifié que la source parle explicitement de l'IRN. Même
> vigilance pour toute autre donnée chiffrée (nombre de tâches, durées, barème).
>
> **« Niveau visé »** = le niveau pour lequel la tâche est conçue. **Ce n'est pas un plafond** :
> l'IA peut noter au-dessus ou en dessous selon ce que le candidat produit réellement. Un
> candidat brillant sur une tâche A2 peut donc obtenir une note élevée ; un candidat faible
> sur une tâche B2 sera noté A1 ou A2.

---

## 3. Le parcours d'une production, du rendu à la note

### Cas EE (écrit)

1. Le candidat écrit son texte et l'envoie.
2. Le serveur passe **trois vérifications automatiques**, sans IA (voir §4).
3. Si tout va bien, le texte part à l'IA correctrice.
4. L'IA renvoie une note et des commentaires (en ~10-15 secondes).
5. Le serveur vérifie la réponse **brute** : quatre critères exacts sans doublon, nombres
   finis entre 0 et 20, structure complète et niveau limité à B2. Si elle est invalide, il
   demande une seule réparation ; si elle échoue encore, aucune note partielle n'est gardée.
6. Le serveur **recalcule** la note, le niveau, et applique ses propres règles (§5, §6).

### Cas EO « classique » (le candidat s'enregistre seul)

1. Le candidat s'enregistre (audio).
2. L'audio est stocké de façon **privée et sécurisée** (personne d'autre ne peut l'écouter
   sans autorisation).
3. Un logiciel de **transcription** (appelé *Whisper*) écrit **mot à mot** ce que le candidat
   a dit. Il transcrit **fidèlement**, y compris les hésitations et les fautes — on ne veut pas
   « embellir » ce que le candidat a produit.
4. Le texte transcrit passe par les mêmes vérifications automatiques, puis part à l'IA.
5. Note + commentaires.

### Cas EO « temps réel » (le candidat dialogue avec l'examinateur vocal)

Ce mode existe pour les **tâches 1 et 2** de l'oral. La tâche 3 (monologue) se passe toujours
en enregistrement.

1. Le candidat parle **avec un examinateur IA à voix haute**, en direct (voir §10).
2. Pendant l'échange, **tout le dialogue est transcrit** au fil de l'eau (les tours de
   l'examinateur ET du candidat).
3. À la fin, ce dialogue transcrit part directement à l'IA correctrice (pas besoin de
   re-transcrire).
4. Note + commentaires. La **confiance** de l'évaluation est automatiquement plafonnée à
   « moyenne » dans ce cas (voir §7) : une transcription faite en direct est moins sûre.

> **Statuts d'une production** (ce que le candidat peut voir s'afficher) : *Soumise* → *(EO :
> Transcription en cours)* → *Évaluation en cours* → *Évaluée*. En cas de problème technique :
> *Échec* (le candidat peut relancer).

**Un point capital sur la transcription automatique.** La machine qui transcrit la voix
**fait des erreurs**, surtout en temps réel. Un candidat qui a parlé clairement peut se
retrouver avec un texte transcrit décousu ou bizarre. **L'IA correctrice est prévenue de
ça** et a des consignes strictes pour ne pas pénaliser le candidat à cause d'un défaut de
transcription (voir §8).

**Les deux machines qui transcrivent ne sont pas la même — et elles ne se trompent pas
pareil.** C'est une distinction qui compte pour comprendre le §8 quater :

| | Enregistrement (tâche 3, et tout l'oral asynchrone) | Temps réel (tâches 1 et 2) |
|---|---|---|
| Qui transcrit | *Whisper* | *Gemini Live*, la même IA qui joue l'examinateur |
| Langue | **imposée : français.** On lui dit dans quelle langue écouter, elle n'a rien à deviner | **impossible à imposer.** L'outil ne propose aucun réglage de langue pour ce qu'il entend |
| Défaut typique | des mots mal entendus (« Lille » → « l'île ») | des mots mal entendus **et** des passages restitués dans une **autre langue** |

Cette différence n'est pas une hypothèse : sur nos données réelles, **aucune** des
36 transcriptions faites par Whisper ne contient d'écriture étrangère, contre **6 sur 39**
côté temps réel. Le §8 quater explique ce qu'on en a fait.

### 3.1 Une phrase coupée en deux est recollée avant d'être lue et notée

Pendant un oral en temps réel, c'est la machine qui décide quand « le candidat a fini de
parler ». Elle se trompe souvent : elle ferme la bulle **au milieu d'une phrase**, et la fin
de la phrase repart dans une bulle suivante. Le candidat n'a rien fait de mal — il a dit une
seule phrase, et notre transcription en affichait deux morceaux :

> Candidat : … c'est vraiment tout ça qui m'ont poussé à l'air. Ah.
> Candidat : aller vers l'informatique.

Ce n'est pas un détail. Découpée ainsi, la phrase produisait **trois problèmes** :

- **le candidat relisait sa propre phrase coupée en deux bulles**, comme s'il s'était arrêté
  net ;
- **le correcteur jugeait la grammaire et le vocabulaire sur un texte haché** — et il s'en
  rendait compte : certaines corrections annonçaient au candidat une « transcription
  partiellement incertaine », alors que le hachage venait de **nous**, pas de sa parole ;
- **les citations justificatives devenaient introuvables**. L'IA doit citer un passage exact
  de la production pour justifier chaque note (voir §5.5). Une citation à cheval sur les
  deux morceaux était refusée par notre vérification — et une correction dont deux citations
  sont refusées **échoue purement et simplement** : le candidat ne voyait pas sa note.

**Ce que nous faisons maintenant.** Avant de lire et de noter, nous **recollons les bulles
qui se suivent et qui viennent de la même personne**. La phrase ci-dessus redevient une seule
prise de parole. C'est tout : on ne réécrit rien, on ne corrige aucun mot, on n'ajoute aucune
ponctuation. Le seul caractère ajouté est **l'espace** qui sépare les deux morceaux.

**En cas de doute, on ne recolle pas.** C'est le principe qui gouverne tout le reste. Sur un
texte qui sert à la fois à noter et à être relu par le candidat, **recoller à tort est pire
que ne pas recoller** : ne pas recoller nous ramène simplement à la situation d'avant, tandis
que recoller à tort **fabrique une prise de parole que personne n'a faite**. Chaque fois qu'il
y a une hésitation, on laisse donc les deux bulles séparées.

Cinq garanties qui encadrent ce recollage :

1. **Jamais à travers une intervention de l'examinateur.** Si l'examinateur parle entre les
   deux bulles, elles restent séparées. Sinon on fabriquerait une phrase que le candidat n'a
   jamais dite d'un trait — par exemple en collant sa réponse d'avant la relance à sa réponse
   d'après.
2. **Jamais quand une phrase paraît terminée et qu'une nouvelle commence.** Si la première
   bulle se termine par un point, un point d'exclamation ou un point d'interrogation **et**
   que la suivante démarre par une majuscule, ce sont deux tentatives distinctes du candidat,
   pas une phrase coupée en deux — et elles restent séparées. Exemple vécu : *« … c'est quoi
   le tarif de l'abonnement s'il vous plaît. »* puis *« Oui, c'est quoi le tarif de
   l'abonnement. »* — le candidat repose sa question, les coller serait un faux.
   Il faut bien les **deux** signes : une phrase réellement coupée par la machine repart
   presque toujours en minuscule (*« … poussé à l'air. Ah. »* + *« aller vers
   l'informatique. »*), et celle-là est bien recollée.
3. **Jamais autour d'une bulle qui ne contient ni lettre ni chiffre** (par exemple une bulle
   réduite à « . . . . »). Elle n'apporte rien au sens, et la recoller ne ferait que glisser
   du bruit **au milieu** d'une phrase propre. Elle reste donc dans son coin — mais elle
   n'est pas effacée pour autant : le recollage supprime uniquement des **séparations**,
   jamais du contenu.
4. **La parole d'origine n'est jamais modifiée en base.** Le transcript brut, tel qu'il a été
   capté, reste stocké tel quel, définitivement. Le recollage se refait **à la lecture**, à
   chaque affichage et à chaque correction. Il est réversible d'un simple réglage.
5. **Le texte affiché au candidat et le texte lu par le correcteur sont le même.** C'est la
   condition pour que les citations restent vérifiables : quand la correction cite une
   phrase, le candidat doit pouvoir la relire mot pour mot dans sa transcription.

**Ce que ça ne fait pas** : ce recollage ne concerne **pas** l'affichage en direct pendant la
session. Pendant qu'il parle, le candidat voit toujours les bulles arriver au fil de l'eau,
telles que la machine les produit. Le recollage n'intervient qu'**après**, au moment de lire
et de noter. Et il ne répare pas non plus les **mots** coupés en plein milieu (« voi ture ») :
ce défaut-là a été corrigé à la source en juillet 2026, et deviner ce que le candidat a voulu
dire sur un texte qui fait foi serait pire que de laisser la trace. Enfin, il ne rattrape pas
les transcriptions **ratées de bout en bout** (un morceau de phrase dans une autre langue, un
marqueur de bruit écrit avec des lettres) : celles-là, ce n'est pas notre découpage qui les a
abîmées, et vouloir les repérer reviendrait à juger la qualité d'une transcription — ce n'est
pas le rôle de ce mécanisme.

---

## 4. Avant l'IA : trois vérifications automatiques

Ces contrôles sont faits par le serveur, **sans aucune IA**. Ce sont de simples calculs.
Ils évitent des notes absurdes et des appels payants inutiles.

| Ce qui est vérifié | Comment | Ce qui arrive au candidat |
|---|---|---|
| **La production est-elle vide ou quasi vide ?** | Moins de 5 mots exploitables. Dans un dialogue oral, on ne compte **que** les tours du candidat : si l'examinateur a parlé seul, il n'y a rien à corriger. | **Production refusée avant l'IA.** Note 0, niveau « A1 non atteint », confiance faible, et un message clair : « Nous n'avons trouvé aucune prise de parole exploitable de votre part. » |
| **Le texte est-il en français ?** | Deux mesures : la part de lettres d'un **autre alphabet** (arabe, cyrillique…), et la part de **petits mots français très fréquents** (le, la, de, que, je, vous…). Un texte français en contient beaucoup ; un texte anglais ou espagnol, presque aucun. L'analyse ne se déclenche qu'à partir de 12 mots — en dessous, la mesure ne veut rien dire. | **Beaucoup d'autre alphabet, ou presque aucun mot français** → production refusée avant l'IA, avec l'explication. **Cas intermédiaire** (une partie du texte semble ne pas être en français) → l'IA note quand même, mais la confiance est plafonnée à « moyenne » et la raison est affichée. |
| **La consigne a-t-elle été recopiée ?** | On compare des suites de 5 mots entre la production et l'énoncé du sujet. | **Plus de 60 % recopié** → refusé : ce n'est plus une production personnelle. **Entre 30 et 60 %** → l'IA note **normalement**, et le candidat est averti que seuls ses propres mots comptent. La confiance, elle, **n'est pas touchée** (voir juste en dessous). |

Les seuils ci-dessus sont **volontairement prudents** : mieux vaut laisser passer une
production douteuse que bloquer un vrai candidat maladroit.

**Deux avertissements, deux choses différentes.** Ces contrôles peuvent signaler un doute
sans refuser la production — mais tous les doutes ne se valent pas :

- « une partie du texte ne semble pas être en français » est un **obstacle à la lecture** :
  on ne voit qu'à moitié ce que le candidat produit, donc la correction elle-même est moins
  sûre. Là, le serveur plafonne la confiance à « moyenne » ;
- « une partie de la production recopie l'énoncé » est un doute sur **l'origine des mots**,
  pas sur leur lisibilité. Les passages recopiés sont écartés, on le dit au candidat, et
  **ce qui reste se lit parfaitement**. Il n'y a donc aucune raison d'annoncer une
  correction moins sûre : la confiance reste celle du correcteur. C'est la même règle que
  celle imposée à l'IA depuis la v8 — la confiance dit ce que le correcteur **sait**, pas
  ce qu'il **soupçonne** (§7).

Quand les deux avertissements tombent ensemble, l'obstacle à la lecture reste un obstacle :
la confiance est plafonnée.

---

## 5. Comment l'IA note : les quatre critères de notre grille

### 5.1 Notre grille, alignée sur ce qu'évalue le TCF

> ⚠️ **À lire avant tout le reste de cette section — ce que nous ne prétendons pas.**
> Les quatre critères ci-dessous sont **la grille interne de SejourFR**. Ce n'est **pas** la
> grille de correction de France Éducation international, l'organisme qui fait passer le TCF.
> L'organisme officiel publie ses critères en **trois familles** — **linguistiques**,
> **pragmatiques** et **sociolinguistiques** — et fait corriger **chaque production par
> plusieurs évaluateurs humains indépendants**, selon une règle de calcul que nous ne
> reproduisons pas et que nous n'avons pas. Notre note est une **estimation pédagogique**,
> exprimée sur l'échelle du TCF IRN (§6.6) : c'est l'**échelle** qui est celle de l'examen,
> pas la correction.
>
> Concrètement, ce qui ne se dit ni ici, ni dans l'application, ni nulle part ailleurs :
> « votre note officielle serait… », « notre calcul reproduit le calcul officiel », « notre
> grille est celle du vrai examen ». Ce qui se dit : « sur cette production, notre correcteur
> situe votre niveau à B1, et au TCF le B1 correspond à 6-9/20 ».

**Depuis la version 5 des consignes, notre grille est construite pour couvrir les dimensions
que le TCF évalue** — linguistique, pragmatique, sociolinguistique — au lieu d'une grille
maison bâtie sans référence. Elle le fait avec **quatre critères, qui pèsent exactement le
même poids — 25 % chacun** :

| Critère | Ce qu'il évalue |
|---|---|
| **Communiquer** | **Accomplir la tâche** : fournir les informations demandées, décrire, raconter, expliquer, justifier une position, obtenir un renseignement — **et enchaîner ses idées** de façon suivie. |
| **Interagir** | **S'adapter à la situation de communication et au destinataire** : registre, politesse, formules d'ouverture et de clôture, prise en compte de l'interlocuteur, conduite des tours de parole à l'oral. |
| **Lexique** | Le vocabulaire est-il **approprié** : étendue, précision, justesse ? |
| **Morphosyntaxe** | La **correction grammaticale** : conjugaisons, accords, construction et variété des phrases. |

Comment ces quatre critères se rattachent aux trois familles publiées par l'organisme
officiel : *lexique* et *morphosyntaxe* relèvent du **linguistique** ; *communiquer* relève du
**pragmatique** (accomplir, organiser, enchaîner) ; *interagir* couvre le
**sociolinguistique** (registre, destinataire, politesse) et une partie du pragmatique
(conduite de l'échange). Le recouvrement est **volontaire et revendiqué comme approximatif** :
quatre critères à poids égaux ne sont pas trois familles, et un correcteur automatique n'est
pas un jury.

Les mêmes quatre critères, avec les mêmes poids, servent **sur les six tâches**. Ce qui
distingue les tâches, ce ne sont plus des critères différents mais **les descripteurs et les
consignes propres à chaque tâche** : « communiquer » ne veut pas dire la même chose quand on
annonce un déménagement à un ami (EE T1) et quand on défend un point de vue (EO T3).

**Ce qui a changé, et pourquoi.** Nos versions 3 et 4 avaient été construites sans référence :
4 critères universels puis 5 critères propres à chaque tâche, avec des poids variables
(15 % à 30 %). Trois défauts ont motivé la refonte :

1. **5 critères à poids variables**, dont la pondération n'était justifiée par rien ;
2. des **noms maison** (« réalisation de la consigne », « conduite de l'échange », « prise de
   position », « chronologie du récit »…) qui changeaient d'une tâche à l'autre, rendant deux
   tâches incomparables entre elles ;
3. surtout, **l'accomplissement de la tâche était exclu du calcul du niveau**. Conséquence
   observée sur de vraies copies : un message qui accomplit parfaitement sa tâche, s'adresse
   correctement à son destinataire et se fait comprendre ressortait **A2**, parce que la
   dimension pragmatique et la dimension sociolinguistique ne pesaient **rien** chez nous.

**Où sont passés les anciens critères ?** Ils n'ont pas disparu, ils ont été **absorbés** :

| Ancien critère (v4) | Absorbé par |
|---|---|
| Réalisation de la consigne | **communiquer** |
| Chronologie et repères temporels | **communiquer** |
| Prise de position claire | **communiquer** |
| Justification et développement des arguments | **communiquer** |
| Conduite de l'échange | **communiquer** |
| Développement des réponses | **communiquer** |
| Cohérence / organisation | **communiquer** — « enchaîner les idées » relève de la même dimension pragmatique qu'accomplir la tâche ; c'est donc noté là, et pas deux fois |
| Adéquation au destinataire et au registre | **interagir** |

Deux familles, qui ne jouent pas le même rôle mais qui pèsent désormais **autant** :

- **Les critères de langue** — **lexique** et **morphosyntaxe**, notés en absolu sur
  l'échelle du TCF IRN, de A1 non atteint à B2 ;
- **Les critères de réalisation** — **communiquer** et **interagir**. Ils ne comptent pas des
  cases cochées : ils disent **à quel niveau** la tâche est accomplie. Accomplir une consigne
  A2 avec des moyens A2, c'est une réussite… de niveau A2.

### 5.2 Ce que « communiquer » et « interagir » veulent dire, tâche par tâche

Les quatre critères et leurs poids ne changent pas. **Ce sont les attentes qui changent** —
c'est le champ « descripteurs » et les consignes de chaque tâche qui les portent.

| Tâche | **Communiquer** y signifie | **Interagir** y signifie |
|---|---|---|
| **EE T1** message court | Annoncer, décrire, inviter de façon compréhensible, et enchaîner ces informations d'un trait. | Formule d'appel et de clôture adaptées au destinataire (ami, famille, voisin), registre tenu. |
| **EE T2** message développé | Raconter / décrire / expliquer avec des détails concrets, dans un ordre clair, avec des repères temporels et des temps du passé employés à bon escient ; le texte forme un tout. | Le message est écrit **pour quelqu'un** : adresse, registre, prise en compte de ce que le destinataire sait déjà. |
| **EE T3** opinion argumentée | Trancher clairement, soutenir par au moins deux arguments développés, organiser (avis → arguments → conclusion). | Écrire pour un lecteur qui peut ne pas être d'accord : courtoisie du désaccord, objection prise au sérieux. |
| **EO T1** entretien dirigé | Se présenter et parler de son quotidien de façon compréhensible, **dépasser la réponse minimale** (ajouter un détail, une raison), enchaîner les thèmes. | S'adresser à son examinateur : salutation, registre, réponses qui répondent vraiment à ce qui est demandé. |
| **EO T2** interaction | **Mener** l'échange : formuler sa demande, relancer, réagir, reformuler, et **obtenir** ce qu'on est venu chercher. | Politesse et registre de la situation (guichet, commerce, employeur), gestion des tours de parole. |
| **EO T3** point de vue | Répondre à la question, affirmer un point de vue, le soutenir par des arguments développés, tenir un fil du début à la fin. | Tenir son monologue **pour** quelqu'un : nuance plutôt que péremptoire, objection envisagée, adresse à l'examinateur. |

> **C'est le serveur qui calcule la note, pas l'IA.** L'IA note chaque critère sur 20 ; le
> serveur en fait la moyenne (les quatre poids sont égaux) et **écrase** la note d'ensemble
> que l'IA avait proposée. Ça évite les incohérences (une IA qui annoncerait « 16/20 » avec
> des critères bas). Si l'écart entre les deux dépasse 3 points, c'est enregistré pour
> surveillance.

### 5.2 bis Le garde-fou qui empêche de « cocher des cases »

Remettre l'accomplissement de la tâche dans le niveau crée un risque évident : **quelqu'un
qui traite tous les points d'une consigne simple dans un français pauvre remonterait
indûment.** C'est précisément pour éviter ça que les versions précédentes l'excluaient du
calcul.

Un jury humain s'en protège par les **descripteurs par niveau** : « communiquer » à un niveau
B2, ce n'est pas cocher plus de cases, c'est justifier, nuancer, enchaîner — ce qui suppose
une langue B2. Un correcteur automatique, lui, se laisse plus facilement impressionner par une
consigne intégralement traitée. Nous nous en protégeons donc de deux façons :

1. **Des descripteurs de niveau pour les quatre critères**, tâche par tâche (tableau ci-dessus
   + descripteurs A1→B2 propres à chaque tâche).
2. **Un garde-fou de couplage, opposable et vérifié par le serveur** : *communiquer* et
   *interagir* ne peuvent jamais dépasser de **plus d'un point** la moyenne de *lexique* et
   *morphosyntaxe*.
   > ⚠️ **Ce garde-fou est une invention SejourFR, pas une règle du TCF.** Aucun texte de
   > France Éducation international ne le prévoit : c'est un réglage de **calibration** que
   > nous avons ajouté parce qu'un correcteur automatique surévalue l'accomplissement d'une
   > consigne simple. Il reste actif, et nous l'assumons par écrit plutôt que de le faire
   > passer pour une exigence de l'examen. Il ne peut qu'**abaisser** une note, jamais la
   > relever — c'est ce qui le rend sûr. Exemple : lexique 1, morphosyntaxe 1 (moyenne 1) → *communiquer* et
   *interagir* sont plafonnés à 2, même si la consigne est intégralement traitée. La règle
   est écrite dans les consignes données à l'IA **et** appliquée par le serveur avant le
   calcul de la note : si l'IA la dépasse, ses notes sont ramenées sous le plafond.

> **Pourquoi « un point » alors que c'était « quatre points » jusqu'à la v5 ?** Parce que
> l'échelle a changé (§6.1) et qu'un écart de points n'a pas le même sens d'une échelle à
> l'autre. Ce qu'il faut conserver, ce n'est pas le nombre : c'est **le maximum que ces deux
> critères peuvent ajouter à la moyenne des quatre**, soit la moitié de l'écart. Avec un
> écart d'un point, ce gain plafonne à **0,5 point** — juste assez pour reconnaître qu'une
> tâche bien menée vaut mieux qu'une tâche bâclée, jamais assez pour franchir un seuil de
> niveau. Le calcul est fait pour ça : une langue au **maximum de son palier** (5 pour A2,
> 9 pour B1) donne au mieux une moyenne de 5,5 ou 9,5 — donc reste A2, reste B1. Sous la v5,
> l'écart de 4 produisait le même effet parce que les seuils de niveau y étaient décalés de
> 2 à 3 points vers le haut ; ce décalage n'existe plus, l'écart devait donc être recalculé.

Conséquence chiffrée, qui est le cœur de la protection : avec une langue A2 au maximum
(5/5) et le couplage, la moyenne des quatre plafonne à **5,5/20** — soit A2. **Un
« communiquer » élevé ne peut pas fabriquer un B2.** Il faut une vraie langue pour ça.

### 5.3 Points **obligatoires** et **pistes suggérées** — la règle centrale

Une consigne mélange deux choses très différentes, et l'IA doit les séparer **avant** de
noter :

- **Les points obligatoires** : ce que la consigne demande explicitement de faire — ses
  verbes d'action (annoncer, décrire, inviter, raconter, conseiller, donner son avis) et les
  informations qu'elle exige. **Ils comptent dans la note.** Un point obligatoire non traité
  fait baisser le critère **communiquer** — **et lui seul**, jamais le lexique ni la
  grammaire.
- **Les pistes suggérées** : les exemples, idées, thèmes ou questions que le sujet propose
  pour aider (« vous pouvez parler de votre travail, de vos loisirs… », listes de questions
  possibles). **Une piste non traitée n'enlève aucun point.** Jamais. Elle n'est jamais
  présentée comme un manque, jamais mise dans les points à améliorer. Au mieux, elle est
  signalée à titre purement informatif.

**En cas de doute sur le statut d'un point, l'IA doit le traiter comme une piste** : le doute
profite au candidat. Sur EO T1 et EO T2 en particulier, le sujet ne fournit pratiquement que
des pistes — on n'y exige **jamais** l'exhaustivité. Un échange incomplet mais réussi répond
aux attentes.

### 5.4 Le verdict, et le bloc « ce que vous avez traité / ce que vous avez oublié »

C'est la première chose que voit le candidat, **avant** tout ce qui concerne la grammaire.

Avant, un candidat qui oubliait un tiers de la consigne voyait « 14/20 » et un commentaire
vague. Il ne savait pas ce qu'il avait raté.

**Depuis la v8, l'écran s'ouvre sur un verdict explicite** — jusqu'ici, il fallait le deviner
en lisant les listes :

```
Objectif de la tâche : ATTEINT
Tu invites clairement ton amie, tu donnes le lieu et tu demandes d'apporter quelque chose.
```

Trois valeurs possibles, et trois seulement : **atteint**, **partiellement atteint**, **non
atteint**. Quatre règles les encadrent :

- le verdict ne regarde **que les points obligatoires** de la consigne. Une piste non abordée
  ne peut **jamais** le faire basculer ;
- « atteint » veut dire **exactement** : aucun point obligatoire n'a été oublié. Si l'IA
  annonce « atteint » tout en listant elle-même un manque obligatoire, **le serveur abaisse le
  verdict** à « partiellement atteint ». Il corrige toujours dans le sens prudent, jamais
  l'inverse — même principe que la confiance (§7) ;
- « non atteint » est réservé au **hors-sujet** ou à l'absence totale de traitement de la
  consigne ;
- le verdict est **indépendant de la note et du niveau**. Une consigne entièrement traitée
  avec des moyens A1 est **atteinte** — et se note quand même dans la bande A1/A2. C'est
  volontaire : accomplir la tâche et le niveau de langue employé pour y arriver sont deux
  choses différentes (§5.2 bis). L'IA a l'interdiction explicite de dégrader le verdict pour
  « justifier » une note basse.

Viennent ensuite les deux listes, en langue simple :

```
Ce que vous avez traité      ✓ Nouvelle annoncée
                             ✓ Logement décrit
Ce qui manque                ○ Invitation absente
```

Chaque ligne porte une indication invisible mais décisive : **obligatoire** ou **piste**. Un
manque marqué « piste » n'a **aucune conséquence sur la note**. Aucun calcul de note ne lit
ces marqueurs — c'est une garantie, pas une intention.

**Un point demandé mais mal formulé est un point PRÉSENT** (règle v8). Un vrai rapport
affichait « tous les points demandés ont été traités », puis, trois lignes plus bas, « la
demande d'apporter quelque chose n'est pas clairement formulée » : le candidat ne pouvait plus
savoir s'il l'avait faite ou non. Désormais, si l'invitation est maladroite, implicite ou
ambiguë, elle figure dans « ce que vous avez traité », et la réserve porte **sur la forme**
(« présent, à reformuler »), exprimée une seule fois dans le commentaire du critère
*communiquer*. Il est **interdit** de déclarer absent, manquant ou « non formulé », dans une
priorité, une suggestion ou un commentaire, un point listé comme traité.

Enfin, l'IA a l'interdiction de **fabriquer** un manque pour remplir la liste : si tout est
traité, la liste des oublis reste vide.

### 5.5 Preuves et priorités

#### La preuve : un **numéro**, plus une citation recopiée (nouveau, format v6)

**Chaque critère noté doit s'appuyer sur un passage réel de votre production.** Cette exigence
n'a jamais bougé. Ce qui a changé le 8 août 2026, c'est **la façon dont l'IA la satisfait**.

- **Avant.** L'IA **recopiait** un extrait de 3 à 15 mots, et le serveur allait ensuite le
  chercher, caractère par caractère, dans votre production. Si l'extrait ne s'y retrouvait
  pas exactement, la correction était refusée, l'IA avait droit à **une** tentative de
  réparation, puis la correction échouait ou était rendue amputée d'une preuve.
- **Le défaut de fond.** On demandait à une machine de **recopier**, puis on la sanctionnait
  sur la qualité de sa copie — alors que ce qu'on voulait vérifier, c'est qu'elle ne parlait
  pas d'un passage inventé. Une preuve **juste** pouvait être refusée pour une **copie**
  imparfaite. Mesuré sur le moteur en vigueur : **27,3 % de ses réponses refusées, 42,9 % sur
  les seules productions orales**.
- **Maintenant.** La production est envoyée à l'IA **découpée en morceaux numérotés**, et l'IA
  renvoie **le numéro** du morceau qui justifie sa note. Elle ne recopie plus rien, donc elle
  ne peut plus se tromper en recopiant. **Inventer une preuve n'est plus interdit : c'est
  devenu impossible.**

**Comment on découpe**, et pourquoi ainsi :

| Type de production | Un numéro = | Pourquoi |
|---|---|---|
| **Oral en dialogue** | une **prise de parole du candidat** | C'est ce que vous avez dit d'un seul trait : vous le reconnaissez à l'écran. Et surtout, **les prises de parole de l'examinateur ne portent aucun numéro** — l'IA les voit (le déroulé de l'échange compte, §8 ter) mais ne peut structurellement pas les désigner comme votre production. |
| **Écrit, et oral sans dialogue** | une **phrase** | À l'écrit, la phrase est l'unité où se lisent la subordination, les connecteurs, les temps — exactement ce que les critères observent. |

On ne découpe pas plus fin (par groupes de mots, par tranches) : il faudrait une coupure
arbitraire, que l'IA ne saurait pas désigner de façon fiable et qui vous rendrait une preuve
illisible. Une preuve doit rester un morceau de langue, pas un fragment. Cas limite assumé :
un texte écrit **sans aucune ponctuation** forme un seul morceau — la preuve est alors peu
précise, mais elle n'est jamais fausse.

**Ce que vous voyez ne change pas.** Le serveur remplace le numéro par **le texte exact du
morceau** avant d'enregistrer et d'afficher la correction. Le champ « preuve » de votre
rapport reste ce qu'il a toujours été : un extrait littéral de ce que vous avez produit.

**La seule erreur qui reste possible** est un numéro qui n'existe pas. Elle est repérée
immédiatement (un entier comparé à une longueur de liste) et le message de réparation ne parle
plus de recopie — il rappelle simplement de choisir un numéro dans la liste. Si, après cette
unique réparation, le numéro est toujours faux, on retire cette preuve-là plutôt que de perdre
toute la correction : la confiance est alors plafonnée à **moyenne** et vous en êtes averti,
exactement comme avant.

#### Ce qui reste vrai des anciennes règles

Le contrôle « caractère par caractère » décrit ci-dessous **reste en place** et continue de
s'appliquer si l'on revient à un format de réponse antérieur (v5 et avant). Il est aussi ce
qui explique pourquoi le passage au numéro était nécessaire.

- **Chaque critère noté doit s'appuyer sur une citation non vide** de la production (3 à 15
  mots). Le serveur cherche d'abord le passage continu correspondant, sans se laisser
  tromper par une différence de majuscule, d'accent, d'apostrophe, de tiret ou d'espace
  (`œ`/`oe` et `æ`/`ae` sont aussi reconnus). Pour éviter de rejeter une citation presque
  exacte à cause d'une petite erreur de recopie, une tolérance très limitée existe sur les
  citations d'au moins quatre mots : un petit mot-outil peut avoir été ajouté ou omis. La
  seule différence admise à l'intérieur d'un mot est la flexion explicitement reconnue
  « telles » / « tels » ; toute autre substitution est refusée. Au moins trois mots
  importants doivent rester identiques, et un
  seul passage de la production doit convenir. Cette tolérance n'accepte jamais l'ajout ou
  l'omission d'un verbe ou d'un nom porteur, un remplacement par un autre mot, un changement
  de nombre ou de négation — un mot qui contient un chiffre, comme « 10h » ou « A2 », est
  lui aussi immuable — ni des mots remis dans un autre ordre. Elle ne fait aucune recherche
  de synonymes pour rapprocher deux formulations. Une fois
  le passage retrouvé, la copie de l'IA est remplacée par **le texte original exact** avant
  l'enregistrement et l'affichage. Si aucun passage sûr ne correspond, la sortie est rejetée
  et l'IA doit la réparer. Si, après cette seconde tentative, **une seule** des quatre
  citations reste impossible à vérifier mais que tout le reste est valide, le serveur retire
  cette citation au lieu d'en afficher une inventée. La note peut alors être conservée, avec
  une confiance au maximum **moyenne** et un avertissement visible. Deux citations douteuses,
  une citation vide ou toute autre erreur font toujours échouer la correction. Avec un ancien
  format de réponse, une preuve non vérifiable est simplement retirée. Dans un dialogue, la
  recherche est limitée aux prises de parole du **candidat** : les mots de l'examinateur ne
  peuvent jamais servir de preuve.
- **Les hésitations du candidat ne font plus échouer une citation fidèle.** À l'oral, la
  transcription est volontairement littérale : elle conserve les « euh », « heu », « hum » là
  où ils ont été prononcés. Une citation par ailleurs parfaitement exacte échouait donc dès
  que trois hésitations traversaient le passage — alors que les consignes **interdisent** par
  ailleurs de fonder quoi que ce soit sur les hésitations. Le correcteur ne pouvait pas
  satisfaire les deux règles à la fois. Depuis, ces trois marques d'hésitation — **et elles
  seules**, la liste est fermée — peuvent être **absentes de la citation** alors qu'elles sont
  présentes dans la production, en nombre quelconque. Ce qui n'a **pas** changé : tous les mots
  porteurs de sens restent exigés à l'identique, dans le même ordre, dans un passage continu
  et unique ; l'élision ne fonctionne que **dans ce sens-là** — une citation qui contiendrait
  un mot absent de la production, hésitation comprise, reste refusée ; et le passage
  finalement affiché reste **le texte original exact**, hésitations incluses.
- **Les bégaiements non plus** (nouveau, 8 août 2026). L'hésitation (« euh ») n'est pas la
  forme la plus fréquente du bégaiement : c'est le **mot répété d'affilée**. Deux citations
  parfaitement fidèles ont été refusées le même soir sur une vraie session — « une sœur qui se
  trouve **tous tous** chez moi », « j'aime bien les **les films les films** comédies » — parce
  que l'IA n'avait gardé qu'une occurrence, ce que les consignes lui demandent par ailleurs de
  faire (on n'évalue pas les répétitions à l'oral). La tolérance d'**une seule** petite
  différence ne suffisait pas : il y avait deux, puis trois mots en trop. Désormais, quand la
  production répète immédiatement un mot — ou un petit groupe de mots, jusqu'à trois — la
  citation peut n'en garder qu'une occurrence. Les garde-fous, eux, sont inchangés : cela ne
  vaut **que** dans ce sens (une citation ne peut pas inventer une répétition absente) ; **aucun
  mot porteur de sens n'est dispensé** ; une répétition portant sur un **nombre, un chiffre ou
  une négation** n'est jamais effaçable (« vingt vingt euros », « je ne ne veux pas ») ; et le
  passage affiché reste **votre texte, bégaiements compris**. En cas de doute — si l'ancienne
  lecture trouvait déjà quelque chose — on ne touche à rien. Limite assumée : une répétition
  **volontaire** (« c'est très très bien ») est traitée comme un bégaiement ; sans conséquence,
  puisque le texte affiché reste le vôtre et qu'aucune note ne se calcule sur une citation.
- **Quand une citation est refusée, on explique à l'IA ce qu'on attend d'elle.** La première
  version du message de réparation se contentait de lui renvoyer la liste des erreurs
  (« la preuve du critère lexique doit citer un passage réel »). Mesuré : sur 8 citations
  refusées, **zéro** était réparée — l'IA renvoyait mot pour mot la même citation, puisque de
  son point de vue elle était réelle. Le message lui rappelle désormais **la citation exacte
  qui a été refusée, critère par critère**, énonce la règle en clair (un seul passage continu,
  recopié tel qu'il apparaît, pas de « … » pour sauter un morceau, pas deux fragments
  recollés, un seul tour de parole du candidat à l'oral) et lui conseille de **re-citer plus
  court** : un passage bref et exact vaut mieux qu'un long passage reconstitué. C'est le sens
  de la correction : **on aide le correcteur à respecter la vérification, on n'abaisse pas la
  vérification.**
- **Deux points à améliorer, au maximum.** Les deux plus utiles, le plus important d'abord.
  Une liste de dix reproches décourage et n'apprend rien. Ce n'est pas qu'une
  consigne donnée à l'IA : **le serveur tronque la liste à deux** avant de vous
  l'afficher, en gardant les deux premières (les plus importantes). L'IA ne peut donc
  pas déborder, même si elle essaie. 🛑 **Le reste partait autrefois dans des
  « suggestions »** ; ce bloc n'existe plus depuis les consignes **v15** (§5.7 bis) — ce
  qui n'est pas une des deux priorités n'est plus écrit du tout.
- **Chaque priorité doit ENSEIGNER, pas constater** (version 5). Un vrai rapport observé
  disait : *« Améliorer la ponctuation pour plus de clarté »*, *« Pratiquer l'utilisation de
  connecteurs pour mieux organiser les idées »* — et la seule correction proposée était
  l'ajout d'une virgule. Le candidat apprenait **ce qui n'allait pas, jamais comment faire**.
  Depuis la version 5, une priorité est composée de trois parties obligatoires :

  | Partie | Contenu |
  |---|---|
  | **constat** | Ce qui ne va pas, en une phrase, appuyé sur SA production. |
  | **comment** | **La technique**, réutilisable et appliquée à son texte : la règle, le mot-outil, la tournure modèle, la question à se poser en se relisant. Doit contenir un verbe d'action adressé au candidat (remplacez, ajoutez, commencez par, relisez). Les formules creuses citées plus haut sont **explicitement interdites**. |
  | **exemple** | Une phrase **exacte** du candidat, avant / après, qui montre la technique en usage. |

  Exemple réellement produit sur une copie A2 : *« Reliez vos idées avec un connecteur. Par
  exemple, remplacez le point entre "Il est petit mais joli" et "Il y a une chambre" par
  "et" : "Il est petit mais joli, et il y a une chambre et une cuisine." »*
- 🛑 **Les exemples corrigés n'existent plus** depuis les consignes **v15** (§5.7 bis). Ce
  qui suit décrit ce qu'ils étaient, parce que les corrections faites avant cette bascule les
  contiennent encore et restent lisibles telles quelles. **Les exemples corrigés devaient faire
  gagner un niveau**, pas corriger des virgules. Une
  virgule ajoutée, un accent, une majuscule : interdits. Ce qu'on attend, ce sont des
  **reformulations** — une juxtaposition transformée en subordonnée, deux phrases fusionnées
  par un connecteur logique, un mot passe-partout remplacé par un terme précis, une
  affirmation transformée en argument justifié. Chaque exemple porte un champ **« gain »**
  qui dit en une phrase ce que la version corrigée démontre de plus (« cette version emploie
  une subordonnée relative, marqueur attendu au B1 »). **Trois au maximum** depuis la v8 :
  la consigne disait déjà « une à trois », mais rien ne le faisait respecter.
- **Au plus deux points forts** (v8), et ils suivent la même exigence que les priorités : de
  vrais points forts cités dans le texte, jamais un compliment de politesse. Une liste de cinq
  réussites dilue les deux qui comptent. Là encore, ce n'est pas qu'une consigne : **le serveur
  tronque** la liste avant l'affichage.

### 5.6 Ce qui empêche l'IA d'être trop gentille

Trois garde-fous écrits dans les consignes de notation, ajoutés après **mesure** (voir §12) :

**« Une tolérance lève une sanction, elle n'accorde pas de point. »** Les règles de tolérance
(§8) interdisent de retirer des points pour la longueur, l'orthographe à l'oral, les
hésitations, les pistes non traitées, les défauts de transcription. Elles restent
**entièrement valables**. Mais elles disent seulement ce qu'il ne faut **pas sanctionner** :
aucune ne dit que la production devient **bonne** pour autant.

> Une production sans faute parce qu'elle n'a rien tenté de difficile ne mérite pas une note
> haute. Une production courte est **recevable**, elle n'est pas pour autant riche. Une
> transcription bruitée, sur laquelle il est interdit de conclure à l'incompréhensibilité, ne
> devient pas une preuve de maîtrise : on ignore le bruit, puis on note ce qui reste
> observable — ni plus, ni moins.
>
> **Le doute profite au candidat sur ce qu'il a voulu dire** (le sens, l'intention, ce que la
> transcription a abîmé), **jamais sur ce qu'il n'a pas produit** (la complexité, l'étendue,
> la variété, l'organisation).

**Le couplage tâche ↔ langue.** Une tâche est toujours accomplie **avec** des moyens
linguistiques. Un critère de tâche ne peut donc pas dépasser de plus d'**un point** la
moyenne du lexique et de la morphosyntaxe (§5.2 bis). Réussir une tâche simple avec un
français très pauvre est une réussite **partielle**, pas une réussite exemplaire. Ce
garde-fou ne sert jamais à rogner une production riche : il ne fait jamais descendre
en dessous du niveau que la langue démontre déjà.

**L'ancrage du bas de l'échelle.** C'est la zone où une erreur coûte le plus cher au
candidat : lui annoncer B1 alors qu'il est A2, c'est lui faire payer un examen officiel qu'il
va rater. Les consignes contiennent donc un test explicite : pour dépasser A1, il faut
qu'apparaisse au moins un marqueur réellement construit — une subordonnée (« je pense **que**
… », « un homme **qui** … »), un temps du passé ou du futur correctement formé, ou une
tournure de politesse construite (« je voudrais », « est-ce que »). **Si l'IA classe A2 ou
au-dessus, elle doit citer le marqueur qu'elle a trouvé.** Si elle ne peut pas le citer, c'est
qu'il n'existe pas.

**L'ancrage du haut de l'échelle.** L'autre bout de l'échelle coûte tout aussi cher, pour une
raison très concrète : depuis le 1ᵉʳ janvier 2026, la naturalisation exige le **B2 dans les
quatre épreuves, sans aucune compensation**. Annoncer B2 à une personne réellement B1, c'est
l'encourager à déposer un dossier voué au refus après avoir payé l'examen. Les consignes
contiennent donc, depuis les rubriques **v4.2**, un test symétrique de celui du bas
(conservé à l'identique en v5 puis en v6).

> **Ce test est encore plus décisif depuis la v6**, où le seuil du B2 est descendu à
> **10/20** pour coller au vrai examen (§6.1). Sur cette échelle, un nombre n'est plus une
> appréciation, c'est **une déclaration de palier** : mettre 12 ou 13 à un critère, ce n'est
> pas « mettre une bonne note », c'est affirmer au candidat qu'il a le niveau exigé pour la
> naturalisation. Les consignes le disent en toutes lettres, avec la règle d'arbitrage
> correspondante : **un très bon B1 — long, fluide, richement subordonné, sans faute — se
> note 9, jamais 12 ni 13** ; et si l'IA hésite entre 9 et 12, la réponse est 9, parce que
> l'hésitation elle-même prouve que les deux marqueurs ne sont pas citables.

Ce qui sépare vraiment B1 de B2, ce n'est pas l'absence de fautes : c'est **l'efficacité de
l'argumentation et la défense d'un point de vue**, puis l'étendue du répertoire. Un B1 peut
être long, ordonné, agréable à lire et presque sans faute. **Enchaîner proprement des idées ne
fait pas un B2.** Pour classer B2, l'IA doit pouvoir **citer littéralement au moins deux
marqueurs** parmi :

- une **subordonnée d'un type absent du répertoire B1** : concessive (« bien que », « même
  si »), conséquence (« tellement… que »), but au subjonctif (« pour que »), hypothèse
  irréelle (« si j'avais… je serais… »), « à condition que » ;
- un **subjonctif ou un conditionnel employé à bon escient**, hors formule de politesse
  toute faite (« je voudrais », « pourriez-vous » ne comptent pas : c'est déjà du B1) ;
- une **objection envisagée puis traitée** : le candidat prête une objection à quelqu'un ou
  l'anticipe (« on m'objectera que… »), puis y **répond par un argument nouveau**. Une
  concession simplement admise et laissée là (« c'est vrai que…, mais moi je pense que… »)
  reste du B1: **reconnaître n'est pas réfuter** ;
- un **lexique précis, soutenu ou abstrait**, attesté par au moins deux termes qui sortent du
  vocabulaire courant du sujet (« super », « magnifique », « formidable » n'en sont pas) ;
- une **structure marquée** au service du propos (« ce qui m'a le plus surpris, ce n'est
  pas…, mais… », « il m'est impossible de… »).

Au moins un de ces deux marqueurs doit venir de **l'objection traitée** ou du **lexique
précis** — les deux endroits où le B1 et le B2 se distinguent le plus nettement. **Si l'IA ne
peut pas recopier ces marqueurs, c'est qu'ils n'y sont pas** : le niveau est B1, et **aucun
des quatre critères** ne dépasse alors **9/20** — soit, sur l'échelle du TCF, le **haut du
palier B1**, donc la meilleure note qu'un B1 puisse obtenir, pas une punition. Depuis la
version 5, le plafond couvre aussi *communiquer* et *interagir* : ils comptent pour la moitié
de la note, donc du niveau — les laisser à 12 pendant que la langue est plafonnée à 9 ferait
ressortir un B1 à 10,5/20, c'est-à-dire un faux B2.

Quatre **faux B2** sont nommés explicitement dans les consignes, parce que ce sont ceux qui
trompaient l'IA : les **connecteurs de surface** (« premièrement », « deuxièmement », « en
conclusion ») posés sur un contenu pauvre ; la **longueur** (une production longue qui ne
défend rien est un B1 long) ; la **correction confondue avec la richesse** ; et les
**formules apprises par cœur** (« il est indéniable que », « de nos jours »).

Ce plafond a une propriété importante : **il ne mord jamais en dessous de 10/20**. Il ne peut
donc, par construction, ni durcir la notation des productions A1, A2 ou B1, ni toucher à la
règle du hors-sujet. Et il n'autorise pas l'inverse non plus : dès que les deux marqueurs sont
citables, l'IA doit noter 12 à 16 **sans hésiter** — sous-noter un vrai B2 renverrait à un
entraînement inutile quelqu'un qui a déjà le niveau exigé.

Et une phrase qui résume tout : **« correction n'est pas niveau »**. Une production simple,
courte, propre et sans faute reste A2 si elle n'emploie que des structures élémentaires. Ce
n'est pas la correction qui fait monter le niveau, c'est l'**étendue** et la **complexité**.
Le piège le plus fréquent est l'énumération : réciter son nom, son âge, sa ville, son travail
et sa famille en phrases toutes construites sur le même moule, sans une faute, reste du A1.
La règle vaut aux deux bouts de l'échelle : en haut, une argumentation bien présentée mais
sans nuance ni lexique précis reste du B1.

### 5.7 Un rapport qui ne se répète pas et ne fait pas la leçon (v8)

Deux défauts revenaient dans les rapports réels. Ils ne concernaient pas la note — jugée
correcte — mais **ce que le candidat lisait**.

**« Une erreur, un seul endroit. »** Le même oubli d'accord pouvait apparaître dans le
commentaire du critère, puis dans une priorité, puis dans un exemple corrigé, puis dans une
suggestion : quatre fois. Le candidat en concluait qu'il avait quatre problèmes, alors qu'il
en avait un. Désormais chaque zone du rapport a **un rôle, et un seul** :

| Zone | Son rôle |
|---|---|
| **Commentaire d'un critère** | **Caractérise** ce critère et cite sa preuve. Il décrit ; il ne fait pas la leçon, n'explique pas comment corriger. |
| **Points à améliorer** | **Enseigne.** C'est le **seul** endroit où l'on explique comment corriger. |
| ~~**Exemples corrigés**~~ | Supprimés par les consignes v15 (§5.7 bis). Ils démontraient le palier au-dessus sur des phrases **différentes** de celles des priorités. |
| ~~**Suggestions**~~ | Supprimées par les consignes v15 (§5.7 bis). Elles ne portaient que ce qui n'avait été traité **nulle part** ailleurs. |
| ~~**Version améliorée** (écrit)~~ | Supprimée par les consignes v14 (§5.8) : le texte modèle de l'écrit est la **version au niveau visé** (§5.9). |

L'interdit qui reste — c'était la répétition la plus fréquente — est de réexpliquer dans le
« comment » ce qui est déjà dit dans le « constat ». (Le second, « ne pas réutiliser la même
phrase dans une priorité **et** dans un exemple corrigé », est devenu sans objet : les exemples
corrigés n'existent plus, §5.7 bis.)

**« On ne reproche pas ce qu'on n'a pas demandé. »** Un rapport disait *« aucun second temps
maîtrisé »* ou *« rien ne sort du répertoire A2 »* — un langage d'expert, adressé à un
professeur, à propos d'un moyen que la consigne n'exigeait pas. Depuis la v8, tout ce que le
candidat lit obéit à cette règle : l'absence d'un moyen linguistique **non exigé par la
consigne** (temps du passé, subordination complexe, connecteurs organisateurs…) est un
**levier de progression**, jamais un défaut :

> *« Tu utilises le présent partout, et c'est suffisant pour cette consigne. Ce qui te ferait
> gagner un niveau : raconter un fait passé au passé composé — "hier, j'ai visité
> l'appartement". »*

⚠️ **Attention à ne pas se tromper de portée.** C'est une règle de **formulation**, et rien
d'autre. Le raisonnement de notation est **inchangé** : c'est toujours la production qui doit
**démontrer** le niveau, et en l'absence de marqueurs, le niveau n'est pas accordé (§5.6). Le
justificatif interne du niveau — que le candidat ne voit pas — continue de dire les choses
sans détour. On dit la même chose au candidat, autrement. Et un point **obligatoire** de la
consigne réellement non traité, lui, reste un vrai manque : on le dit, simplement.

### 5.7 bis Le bloc replié « Voir l'analyse complète » a disparu — et avec lui deux blocs du rapport (v15)

> 🛑 **Deux blocs n'existent plus** : les **exemples corrigés** et les **suggestions**. Depuis
> les consignes **v15** et le format de réponse **v9**, l'IA ne les écrit même plus : le format
> ne prévoit plus de case pour les loger. Les corrections faites avant cette bascule les
> contiennent encore, et **restent lisibles telles quelles** — rien n'a été effacé ni recalculé.

#### Ce qui a été décidé

Sur l'écran de résultat d'une production écrite ou orale, tout ce qui n'était pas essentiel
était rangé dans un bloc replié intitulé **« Voir l'analyse complète »**. C'était le seul
endroit où s'affichaient les **exemples corrigés** et les **suggestions**. Ce bloc est
supprimé. Le résultat tient désormais dans ce qui se lit sans déplier quoi que ce soit : le
verdict de la tâche, ce que vous avez traité et oublié, votre niveau et votre situation dans ce
palier, les points forts, les deux priorités, les commentaires par critère et — à l'écrit — la
version au niveau que vous visez.

#### Pourquoi

Pour deux raisons, qui vont dans le même sens.

**On ne lisait pas ces blocs.** Un pavé qu'il faut déplier pour voir n'est pas lu ; deux blocs
de plus dans un rapport déjà long diluent les deux priorités, qui sont ce qui fait réellement
progresser. C'est exactement le raisonnement qui a déjà conduit à plafonner les points forts à
deux et les priorités à deux (§5.5) : mieux vaut peu et lu que beaucoup et survolé.

**Tout ce que l'IA écrit se paie.** Chaque mot produit par le correcteur coûte, à chaque
correction. Cesser de demander deux blocs entiers **libère du budget** — et ce budget finance
quelque chose de plus utile : le **second appel** qui rend, à l'écrit, votre réponse rédigée au
niveau que vous visez (§5.9). On ne supprime pas pour supprimer : on déplace la dépense là où
elle sert.

#### Ce qui reste, et pourquoi ça reste

Rien de ce qui porte la note, le niveau ou un contrôle automatique n'est touché :

| Bloc | Pourquoi il reste |
|---|---|
| **Accomplissement** (verdict, phrase de résumé, points traités / oubliés) | Il alimente le bandeau du haut de l'écran, le compteur « ce qui marche », et un **contrôle serveur** qui abaisse un verdict contradictoire (§5.4). Le retirer casserait à la fois la note et le haut de l'écran. |
| **Avertissements** | Ils ne viennent pas de l'IA : c'est le **serveur** qui les écrit (limite assumée de l'oral, plafond appliqué, phrase retirée par un filet). Ils n'ont jamais fait partie du format de réponse, et ils continuent d'être produits exactement comme avant. |
| **Points forts, priorités, commentaires par critère, preuve, confiance, justification du niveau** | Chacun est lu par un calcul, par un contrôle, ou par un bloc affiché **hors** du repli. |

#### Ce que cette bascule ne change pas, et comment nous le savons

La **v15 est la v14 au caractère près** pour tout ce qui note : l'échelle, les quatre critères,
les seuils, le garde-fou de couplage, les plafonds, les bandes affichées, les tests décisifs
A1/A2 et B1/B2, les descripteurs et le barème des six tâches, et les 16 exemples de
calibration. Ce n'est pas une promesse : un test reconstruit la v15 à partir de la v14 en lui
appliquant la **liste énumérée** des retraits, puis exige l'égalité — un seul caractère modifié
ailleurs **casse la construction**. Le format de réponse **v9** est le **v8 privé de ces deux
cases**, et rien d'autre : là aussi, un test exige l'égalité stricte de tout le reste.

⚠️ **Aucune campagne de mesure n'a été lancée**, et c'est défendable pour la même raison que
pour les v12, v13 et v14 : **aucune règle de notation ne bouge**, et le peu qui change dans les
consignes **enlève** du texte au lieu d'en ajouter. (Les seules versions qui ont dégradé les
résultats, v10 et v11, en **ajoutaient**, §8 quater.) Retour en arrière si besoin : une paire de
variables (`EVAL_RUBRICS_VERSION=v14` + `EVAL_PROMPT_VERSION=v8`), sans rien migrer — les deux
blocs sont alors de nouveau demandés et affichés.

#### Si l'IA les écrit quand même

Le format fermé le lui interdit, mais on ne fait pas dépendre une correction d'une interdiction.
Si une réponse portait malgré tout l'un de ces deux blocs, elle **n'est pas refusée** : le
serveur les retire, et la correction est rendue. Une correction perdue coûte bien plus cher au
candidat qu'un champ ignoré — c'est exactement l'arbitrage retenu lors du retrait de la version
améliorée (§5.8).

### 5.8 La version améliorée de votre texte — **supprimée** (écrit, v8 → v14)

> 🛑 **Ce bloc n'existe plus.** Il a d'abord été retiré de l'écran, puis, depuis les consignes
> **v14**, il n'est **même plus produit** par le correcteur. Ce qui suit décrit ce qu'il était,
> parce que les corrections faites avant cette bascule le contiennent encore et restent
> lisibles telles quelles. Le texte modèle de votre résultat écrit, aujourd'hui, c'est la
> **version au niveau visé** du §5.9.

À l'écrit, le rapport se terminait par **votre production réécrite en entier**, telle
que vous auriez pu l'écrire au palier juste au-dessus. C'était le pendant naturel de la règle
précédente : au lieu d'accumuler des remarques sur des phrases isolées, on montrait le résultat.

Cinq règles l'encadrent :

- **ce sont vos idées.** Mêmes informations, mêmes intentions, même contenu. L'IA n'a pas le
  droit d'inventer un détail que vous n'avez pas donné (une adresse, un horaire, un argument) ;
- **le palier juste au-dessus, pas l'excellence.** Un candidat A2 reçoit une version B1
  atteignable, jamais un modèle B2 : une version trop belle est décourageante et inutilisable ;
- **les bornes de mots de la tâche sont respectées** — celles de la tâche, telles qu'elles lui
  sont annoncées (30–60 mots en T1, 40–90 en T2/T3 depuis la migration V724). Depuis les
  consignes v12, la grille ne recopie plus ces chiffres : elle **renvoie** aux bornes
  injectées, pour ne plus pouvoir les contredire (§2) ;
- **elle applique les corrections des priorités au lieu de les répéter** : on voit la technique
  à l'œuvre, on ne la réexplique pas. Aucun commentaire ni parenthèse dans le texte ;
- **le registre et le destinataire** de la consigne sont respectés, formule d'appel et de
  clôture comprises.

**À l'oral, il n'y en a pas**, et c'est délibéré : réécrire un échange oral en dialogue modèle
n'a aucun sens pédagogique, et cela reviendrait à commenter la forme orale, ce que nous nous
interdisons (§9). Si le correcteur en produit une malgré tout, le serveur la retire avant
l'affichage.

#### ⚠️ Pourquoi elle a disparu — d'abord de l'écran, puis de la correction

Cela s'est fait en **deux temps**, et il vaut la peine de les distinguer.

**Temps 1 — retirée de l'écran.** Plus aucun écran ne la montrait, mais le correcteur
continuait de l'écrire à chaque correction écrite, et elle restait conservée avec la
correction. C'est la **version au niveau visé** du §5.9 qui avait pris sa place comme texte
modèle du résultat écrit.

**Temps 2 (consignes v14) — retirée de la correction elle-même.** Un texte que personne ne lit
n'en reste pas moins **écrit** par l'IA, et tout ce que l'IA écrit se paie : c'était en moyenne
**297 caractères, 54 mots — environ 5,7 % de tout ce que le correcteur produit** sur une copie
écrite (mesuré sur les corrections réelles qui la portent). Les consignes **v14** ne la
demandent donc plus, et le **format de réponse v8** ne prévoit même plus de case pour la loger :
elle est devenue impossible à produire, pas seulement inutile.

> **Ce que cette bascule ne change pas, et comment nous le savons.** v14 est la v13 **au
> caractère près** pour tout ce qui note : l'échelle, les quatre critères, les seuils, le
> garde-fou de couplage, les plafonds, les bandes affichées, les tests décisifs A1/A2 et B1/B2,
> les descripteurs et le barème des six tâches, et les 16 exemples de calibration. Ce n'est pas
> une promesse : un test compare les deux fichiers et **casse la construction** si un seul de
> ces éléments bouge. Comme pour v12 et v13, aucune campagne de mesure n'a été lancée — et pour
> la même raison : rien de ce qui note ne change, et le peu qui change dans les consignes
> **enlève** du texte au lieu d'en ajouter. Retour en arrière si besoin : une paire de
> variables (`EVAL_RUBRICS_VERSION=v13` + `EVAL_PROMPT_VERSION=v7`), sans rien migrer.

La raison mérite d'être dite, parce qu'elle est instructive : cette version était **au même
niveau que la production du candidat**. Elle était le texte le plus visible et le plus copiable
de la page, sans aucune étiquette de niveau à côté — rien n'indiquait « voici du B1 ». Le
propriétaire de la plateforme l'a recopiée telle quelle, l'a resoumise comme une nouvelle
copie… et a obtenu **la même note au dixième près** (vérifié dans la base). Ce n'est pas un
défaut de l'IA : le texte faisait bien ce qu'on lui demandait, c'est-à-dire le **palier juste
au-dessus** — sauf que « juste au-dessus » de A2, mesuré par notre grille, retombe souvent dans
la bande A2. Un modèle qui, recopié, ne fait pas bouger la note, est un modèle qui **ment par
son emplacement**.

La version du §5.9, elle, **nomme son niveau** (« Votre réponse au niveau B2 ») et vise le
palier de la démarche du candidat, pas le palier suivant. C'est ce qui la rend affichable en
tête d'écran.

### 5.9 La version au niveau que **vous** visez (écrit **et oral**)

> 📌 **C'est LE seul texte modèle de votre résultat écrit.** La version améliorée du §5.8 a été
> retirée de l'écran puis supprimée de la correction ; celle-ci a pris sa place, en évidence,
> avec ses leviers juste en dessous sous le titre « Ce qui vous en sépare ».
>
> 📌 **Depuis la version v2 de cet encart, l'oral y a droit aussi** — mais sous une forme
> différente, et c'est délibéré : à l'oral, votre production **n'est jamais réécrite**. Voir
> « À l'oral… » plus bas.

La version améliorée du §5.8 montrait **le palier juste au-dessus**. C'est utile, mais ce n'est
pas toujours ce dont vous avez besoin : quelqu'un qui prépare une **naturalisation** doit
atteindre le **B2**, et s'il écrit aujourd'hui du A2, voir une version B1 ne lui dit pas où est
l'arrivée.

Le rapport écrit contient donc, en plus, **la même réponse rédigée au niveau que vous visez**
— accompagnée de **deux ou trois choses précises** qui vous en séparent aujourd'hui.

#### Quel niveau « vous visez », exactement : **c'est votre démarche qui décide**

C'est le **palier exigé par la démarche que vous avez choisie dans votre profil** :

| Votre démarche | Palier de français exigé |
|---|---|
| Carte de séjour pluriannuelle | **A2** |
| Carte de résident | **B1** |
| Naturalisation | **B2** |

Ces trois valeurs ne sont pas un choix de SejourFR : ce sont les seuils en vigueur depuis le
**1ᵉʳ janvier 2026** (loi n° 2024-42, décrets 2025-647 et 2025-648, arrêté du 22 décembre 2025).

Si vous avez par ailleurs déclaré viser un niveau **plus haut** que votre démarche, c'est
celui-là qui est retenu : **on ne vous tire jamais vers le bas**. En revanche, un niveau
déclaré **plus bas** que ce que votre démarche exige ne compte pas — votre démarche fait
**plancher**.

> **Pourquoi cette règle existe.** Un compte visant la naturalisation portait, hérité d'un
> ancien réglage, un niveau enregistré à B1. Sa production a été jugée B1, la plateforme en a
> conclu « objectif atteint »… alors que sa démarche en demande **un de plus**. Ce candidat
> n'aurait jamais été tiré vers le B2 dont il a réellement besoin. Depuis, la démarche fait foi,
> et changer de démarche met automatiquement à jour le palier exigé.

Si vous n'avez pas encore choisi de démarche, c'est le niveau visé par la tâche qui sert de
repère ; et si rien n'est connu, l'encart n'est simplement pas affiché — nous ne devinons pas
un projet à votre place.

Exemple, à l'**écrit**, pour quelqu'un qui vise le B2 et dont la production a été jugée A2 :

> **Ce qui vous en sépare**
> 1. **Annonce l'objection avant d'y répondre** — « On objectera que »
> 2. **Conditionne ton accord** — « à condition que »
> 3. **Choisis un terme précis** — « la qualité de l'air »
>
> **Votre réponse au niveau B2**
> « Je suis favorable à cette interdiction, même si elle mérite d'être nuancée. Interdire les
> voitures au centre **améliorerait nettement la qualité de l'air** et réduirait le bruit…
> **On objectera que les salariés venus de loin seraient pénalisés** ; l'argument est réel, mais
> il tombe **à condition que la mairie renforce** les transports en commun. »
> *(les passages en gras sont surlignés à l'écran, avec leur étiquette : « objection traitée »,
> « position nuancée », « lexique précis »)*
>
> **À retenir**
> « On objectera que…, mais… » — pour montrer qu'on a prévu le contre-argument avant qu'on vous
> l'oppose.

**Un plan d'action court, pas un pavé.** Chaque morceau de cet encart a une longueur **plafonnée
en nombre de mots**, et ce plafond est tenu par le contrat de sortie **et** par un contrôle du
serveur — jamais par une simple consigne, qui dans ce projet n'est qu'un vœu :

| Ce que vous lisez | Longueur maximale |
|---|---|
| l'**action** d'un levier (« Annonce l'objection avant d'y répondre ») | **6 mots**, à l'impératif |
| l'**exemple** de langue d'un levier (« On objectera que ») | **5 mots**, recopiable tel quel |
| l'**étiquette** d'un passage surligné (« objection traitée ») | **3 mots** |
| la **formule** à retenir | **8 mots** |
| son **explication** | **14 mots** |

Deux ou trois leviers, jamais un inventaire ; jusqu'à trois passages surlignés, jamais tout le
texte ; **une seule** chose à retenir.

Ces plafonds sont des consignes de forme, pas des règles de calcul : le serveur **tolère
toujours au moins un mot de plus** avant de refuser (et 20 % au-delà sur les plafonds élevés).
Il faut le dire, parce que ça n'a pas toujours été vrai : la marge de 20 % appliquée seule ne
donnait **aucun mot de tolérance** sur les étiquettes de trois mots, si bien qu'une étiquette de
quatre mots — « plus poli et net » — faisait disparaître tout un encart déjà payé. Corrigé le
11 août 2026, sur cet encart comme sur celui du module Compétences.

Les autres règles sont celles du §5.8, avec un ajout : **c'est toujours votre réponse** — même
situation, mêmes faits, mêmes prénoms, mêmes chiffres, même position. Si vous êtes contre une
idée, la version l'est aussi : on ne change pas votre avis, on vous donne les moyens de le
défendre.

> **Les passages surlignés sont vérifiés, pas crus sur parole — mais ils ne coûtent qu'eux-mêmes.**
> L'IA désigne deux ou trois extraits de son propre texte modèle ; le serveur **les y
> recherche**, et n'affiche que ceux qu'il retrouve réellement : un surlignage approximatif
> présenterait comme « extrait du modèle » une phrase que le modèle n'a jamais écrite.
> **Un passage qu'il ne retrouve pas est simplement retiré, et le texte modèle reste affiché** —
> sans son surlignage. C'est la règle depuis le 11 août 2026, et elle remplace la précédente
> (« un extrait introuvable et toute la version modèle disparaît ») : **le texte réécrit est ce
> que vous venez chercher, un texte sans surlignage vaut mieux qu'un écran vide.** Vos leviers
> et votre « à retenir » restent eux aussi, comme avant : ils ne reposent sur aucune citation
> (voir « ce qui tombe, et ce qui reste » plus bas).
>
> **La recherche ignore la typographie, et rien d'autre.** Apostrophe droite ou courbe, espace
> insécable, tiret long ou court, retour à la ligne : ces différences-là ne comptent pas, parce
> qu'elles viennent du clavier et non du sens — c'est même la cause la plus fréquente d'un
> passage juste déclaré introuvable. En revanche les mots, les accents et les majuscules doivent
> correspondre, et le passage finalement surligné est **celui de votre texte, tel qu'il
> s'affiche**, jamais une version retouchée.

#### Cette version respecte la longueur de l'exercice — c'est vérifié, pas demandé

Un sujet d'expression écrite impose un **nombre de mots** (par exemple 30 à 60 pour la
tâche 1), et notre plateforme **refuse** une copie hors de ces bornes : « Votre texte est trop
long : 63 mots pour un maximum de 60. »

Pendant un temps, la version modèle, elle, n'était pas vérifiée : les deux premières rendues
faisaient **63 et 64 mots** sur une tâche plafonnée à 60. Autrement dit, on montrait au
candidat un texte à imiter que **notre propre site aurait refusé de recevoir** s'il l'avait
recopié. Une simple consigne dans le prompt ne suffisait pas — et une consigne, dans ce projet,
n'est jamais considérée comme une garantie.

Ce qui se passe maintenant :

- les bornes **de l'exercice** (celles de la base, jamais un chiffre recopié ailleurs) sont
  **envoyées à l'IA** avec l'énoncé, et **recomptées par le serveur** à la réception, avec
  exactement la même façon de compter que pour votre copie ;
- si la version est hors bornes, **une seule** tentative de correction est demandée, en disant
  précisément ce qui ne va pas : « ton texte fait 63 mots, l'exercice en attend 30 à 60, retire
  au moins 3 mots, sans couper une phrase en cours » ;
- si elle est encore hors bornes, **la version modèle n'est pas affichée** — et c'est
  volontaire : nous ne coupons **jamais** un texte modèle au mot près, parce qu'un texte tronqué
  au milieu d'une phrase enseigne une faute. Mieux vaut pas d'exemple qu'un mauvais exemple. Là
  encore, les leviers et la tournure à retenir restent affichés ;
- **trop court compte autant que trop long** : une version de 12 mots sur un sujet qui en
  demande 30 est refusée de la même façon.

Votre correction, votre note et votre niveau ne changent jamais à cause de cela.

#### À l'**oral**, on ne réécrit **jamais** votre production — on reformule deux ou trois passages

Pendant longtemps, cet encart n'existait pas du tout à l'oral. La raison n'a pas changé : **ce
que nous lisons de votre oral n'est pas un texte que vous avez écrit**, c'est une transcription
automatique. Elle est littérale, elle porte vos hésitations et vos reprises, et il lui arrive de
mal entendre un mot. Vous rendre un « beau texte » à la place de ce que vous avez dit vous
laisserait croire que vous avez produit autre chose — et ce serait faux.

Ce que vous recevez désormais à l'oral, c'est donc :

- les **mêmes leviers** qu'à l'écrit (action de 6 mots, exemple de langue de 5 mots) ;
- **deux ou trois de vos passages, redits au niveau que vous visez** — et rien d'autre. Vous
  voyez votre phrase telle que vous l'avez dite, et à côté la même phrase au niveau visé, avec
  une étiquette de trois mots qui dit ce qu'elle apporte ;
- la **même chose à retenir**.

Exemple, pour quelqu'un qui vise le B1 :

> **Ce que vous avez dit** — « Oui bonjour, je viens d'arriver dans l'immeuble et je veux mettre
> mon vélo en bas. »
> **Au niveau B1** — « Bonjour, puisque je viens d'emménager dans l'immeuble, serait-il possible
> de ranger mon vélo au sous-sol ? » *(demande plus polie)*

**Comment le passage est désigné, et pourquoi ça compte.** Votre transcription part à l'IA
**découpée et numérotée** : chaque chose que vous avez dite d'un seul trait porte un numéro.
L'IA ne recopie donc rien — elle **désigne un numéro**, et le serveur remet ensuite votre texte
exact à sa place. C'est la technique qui, côté correction, a fait disparaître la première cause
de correction perdue à l'oral (§8 ter). Conséquence directe : **les tours de l'examinateur, eux,
n'ont aucun numéro** — reformuler l'examinateur devient impossible, pas « interdit ».

##### Trois garde-fous, pour ne jamais vous reprocher ce que la machine a mal entendu

1. **Si la transcription est abîmée, il n'y a pas d'encart du tout.** Nous mesurons la qualité de
   chaque transcription (§8 septies) ; quand elle est déclarée dégradée, **aucune demande n'est
   envoyée à l'IA**. Reformuler un texte que la machine a cassé reviendrait à vous corriger pour
   nos propres erreurs — et à le faire payer. Mieux vaut rien.
2. **Une reformulation qui ne change que la forme d'un mot est retirée.** C'est exactement la
   règle du §8 sexies : à l'oral, ce qui compte est la **construction** de la phrase, jamais
   l'orthographe d'un mot. Si votre phrase est simplement recopiée avec « habite » à la place de
   « abit », ce n'est pas un conseil — c'est la correction de notre transcription, déguisée en
   correction de votre français. Elle disparaît. Une reformulation qui **subordonne**, qui
   **réordonne**, qui **construit une question** ou qui **annonce une objection**, elle, est
   conservée : les mots y bougent, c'est le signe qu'on parle de structure.
3. **Rien n'est jamais dit de votre prononciation, de votre accent, de votre intonation, de
   votre débit, de vos hésitations ou de votre ponctuation** — et la **durée** de votre
   enregistrement n'est pas davantage communiquée à ce second correcteur qu'au premier (§7).

Et comme partout ici : s'il reste **moins de deux** reformulations après ces retraits, **une
seule** nouvelle demande est faite, en disant précisément ce qui a été refusé et pourquoi ; si
elle échoue, **les reformulations ne sont pas affichées**. Jamais de demi-conseil. Votre note,
votre niveau et votre correction ne bougent jamais à cause de tout cela.

##### Ce qui tombe, et ce qui reste

Un encart abîmé ne disparaît pas en bloc. **Chaque partie est jugée séparément**, parce
qu'elles ne dépendent pas les unes des autres :

| Partie | Si elle est inexploitable après l'unique correction demandée |
|---|---|
| **Les leviers** | Rien n'est affiché du tout : un plan d'action sans levier n'apprend rien. |
| **La version modèle** (écrit) / **les reformulations** (oral) | **Elle seule** disparaît. Vos leviers et votre « à retenir » restent. |
| **Un passage surligné dans la version modèle** (écrit) | **Lui seul** disparaît : le texte reste affiché, simplement sans ce surlignage. |
| **La tournure à retenir** | **Elle seule** disparaît. |

Cette dernière ligne est récente (11 août 2026) et elle **remplace** une règle plus dure : un
seul passage introuvable emportait auparavant toute la version modèle. La raison du changement
tient en une phrase : **le texte réécrit est ce que vous venez chercher, le surlignage n'est
qu'une aide à la lecture** — et depuis que la « version améliorée » du §5.8 n'existe plus, ce
texte est le seul modèle de tout votre rapport.

> **Pourquoi cette règle a été écrite.** Sur une tâche d'oral en temps réel, la transcription
> était hachée — mots coupés, répétitions, un tour réduit à un bruit. Les reformulations ont
> donc été retirées, et c'était **le bon comportement** : elles n'auraient corrigé que ce que
> notre machine avait mal entendu. Mais le candidat perdait **aussi** ses leviers et sa tournure
> à retenir, qui ne citaient rien du tout. Une autre tâche du même candidat, mieux transcrite,
> avait reçu tout son encart. Autrement dit : la fragilité des citations à l'oral punissait des
> conseils qui n'en dépendaient pas. Ce n'est plus le cas.
>
> Et cela ne coûte **rien de plus** : la correction supplémentaire demandée à l'IA reste
> **unique**, quel que soit le nombre de parties en défaut.

#### Et si vous êtes **déjà au niveau que vous visez** ? On vous le dit.

Il n'y a alors pas de « marche au-dessus » à vous montrer : le texte modèle n'aurait aucun sens
(vous écrivez déjà à ce niveau-là). Mais **cette section ne disparaît plus en silence**.

C'était un vrai défaut : depuis que la version améliorée du §5.8 a disparu, ce
bloc est le **seul** texte modèle du rapport. Le candidat qui **réussissait** se retrouvait donc
avec un résultat plus vide que celui qui échouait, sans un mot d'explication — sa réussite avait
exactement la même tête qu'une panne.

À la place s'affiche désormais un encart vert :

> **OBJECTIF ATTEINT**
> **Objectif B2 : vous y êtes**
> Cette production tient le palier que vous visez. Il n'y a donc pas de version d'un niveau
> supérieur à vous montrer ici : l'enjeu est maintenant de tenir ce niveau sur les trois tâches
> de l'épreuve.

Deux points importants : aucune note n'y apparaît (comme partout sur le résultat d'une tâche),
et **c'est le serveur qui décide** de l'afficher. Ce n'est pas un détail : vu de l'application
seule, « objectif atteint » et « la génération du texte modèle a échoué » se ressemblent
exactement — les deux se traduisent par une absence. Seul le serveur sait laquelle des deux
c'est, et il le dit explicitement. Une panne, elle, reste silencieuse : on ne vous félicite
jamais par erreur.

#### Un levier ne peut pas être un moyen que vous employez déjà (nouveau)

Le même défaut que celui décrit au §8 quinquies s'était glissé **ici aussi**, et il y était
plus visible encore depuis que cet encart est passé en tête d'écran. Vérification faite dans la
base : sur les blocs déjà rendus, **un levier** portait la faute, dans un bloc annoncé
« niveau visé : B1 » :

> « Relier les phrases avec des connecteurs simples : « **et** », « **mais** », « donc » au lieu
> de juxtaposer des idées sans lien. »

« et » et « mais » sont classés **A2** par notre propre grille, qui exige justement, pour
dépasser le A2, des connecteurs « au-delà de et / mais / parce que / après / aussi ». On
promettait donc le B1 avec deux mots que le candidat emploie déjà.

Ici, la vérification est **plus sûre** qu'au §8 quinquies, et pour une raison simple : le
niveau visé n'a pas à être deviné dans la phrase, il est **écrit** dans l'encart. Le serveur
retire donc **le levier entier** — action **et** exemple de langue, jamais une moitié : un
demi-conseil ne s'applique pas — dès qu'il désigne un de ces petits mots alors que vous visez
**plus haut que le A2**.

> Depuis que le levier est un couple *action + exemple de langue*, le cas fautif type est encore
> plus net : l'exemple étant un bout de langue à recopier, un petit mot A2 s'y retrouve **nu**
> (« Relie tes deux idées » — « parce que »). La vérification y lit les deux moitiés, et le
> couple entier tombe.

Ce qui **passe** sans être touché :

- **si vous visez le A2**, ces mots sont exactement le bon conseil : rien n'est retiré ;
- **un petit mot cité pour dire ce qu'il faut arrêter de faire** : « Annoncer l'objection avant
  d'y répondre : *On objectera que… ; c'est vrai, mais…* **au lieu de** poser *mais* seul. » Le
  moyen recommandé y est bien au-dessus du A2 — c'est d'ailleurs l'un des exemples de référence
  de notre propre consigne ;
- **une citation qui contient un de ces mots sans s'y réduire** (« *mais ce que j'apprécie
  surtout* », « *Physiquement… mais…* ») : ce sont de vraies tournures, pas des petits mots.

Et s'il ne reste **plus assez de leviers** (le contrat en impose au moins deux) : **une seule**
nouvelle demande est faite à l'IA, en lui disant précisément quel levier a été refusé, pourquoi,
et par quoi le remplacer — subordonner, organiser le propos, nuancer, préciser le lexique. Si
elle recommence, **l'encart entier n'est pas affiché**. C'est le même arbitrage que pour la
longueur : mieux vaut pas d'exemple qu'un mauvais exemple. Votre note, votre niveau et votre
correction ne bougent jamais à cause de cela.

La consigne donnée à l'IA a été complétée dans le même mouvement — elle liste maintenant ce qui
sépare réellement du B1 et du B2 — mais c'est le **contrôle** qui tient la règle, pas la
consigne : dans ce projet, une consigne est un vœu.

#### Le point technique qui compte : c'est un **second correcteur**, appelé séparément

Cette version est produite par un **deuxième appel à l'IA, complètement séparé de la
correction**. Le correcteur qui vous note **n'apprend jamais quel niveau vous visez**.

Ce n'est pas un détail d'organisation, c'est la raison même de ce découpage : un correcteur à
qui l'on dit « ce candidat vise le B2 » a tendance à **aligner sa note sur cette attente** —
dans un sens ou dans l'autre. Nous avons d'ailleurs déjà mesuré, dans ce projet, qu'ajouter un
simple bloc de consigne à la grille de notation **dégrade la notation** (§8 quater : deux
versions écrites pour régler un tout autre problème sont passées de 81,8 % à 75,6 % de niveaux
exacts, uniquement parce que le texte ajouté diluait le reste). La note doit donc être produite
par un appel qui ne sait rien de votre projet ; l'encouragement vient après, dans un appel qui
ne note rien.

**Et si ce second appel échoue, il ne se passe rien de grave** : votre correction reste
complète et valide, seul cet encart est absent. Il n'est pas rejoué (c'est un confort, pas une
correction) et il n'a aucun effet sur votre note, votre niveau ou votre bilan.

---

## 6. La note et le niveau

### 6.1 L'échelle du profil TCF IRN

Chaque critère est noté sur 20, **en absolu**, pas « par rapport au niveau visé de la
tâche ». Depuis la v6, les seuils suivent la table utilisée pour le TCF IRN ; depuis la
**v7**, le contrat et tous les libellés sont explicitement **plafonnés à B2** : SejourFR ne
produit aucune note C1 ou C2.

| Note d'un critère | Correspondance |
|-------------------|----------------|
| 10 – 20 | Niveau **B2** (10-11 : B2 tout juste atteint · 12-16 : B2 confirmé · 17-20 : B2 très solide) |
| 6 – 9 | Niveau **B1** (6-7 : B1 émergent · 8-9 : B1 solide, **y compris un très bon B1**) |
| 2 – 5 | Niveau **A2** (2-3 : A2 fragile · 4-5 : A2 solide, sans faute, consigne bien traitée) |
| 1 | Niveau **A1** — tout A1 vaut 1, il n'y a pas de « bon A1 » à 3 ou 4 |
| 0 | Rien d'exploitable : **hors-sujet** (voir §8) **ou** production en deçà du A1 |

> ⚠️ **Oubliez le réflexe scolaire.** Sur cette échelle, **10/20 n'est pas « la moyenne »,
> c'est le seuil du B2** — le niveau exigé pour la naturalisation. Et **5/20 n'est pas un
> mauvais résultat, c'est un A2 solide**. C'est déroutant au premier abord, et c'est
> exactement ce que verra le candidat le jour de l'examen. Les consignes données à l'IA le
> disent en toutes lettres, parce que c'est l'erreur la plus facile à commettre : sur cette
> échelle, **un nombre n'est pas une appréciation, c'est une déclaration de palier**.

L'échelle est volontairement **resserrée en bas** (0, 1, puis 2-5) et **large en haut**
(10-20). Ce n'est pas une anomalie de notre part : c'est la table officielle. Elle refuse les
demi-teintes en dessous du A1 et laisse au contraire de la place pour distinguer un B2 juste
atteint d'un B2 brillant.

**La note d'ensemble est la moyenne des quatre critères** (ils pèsent 25 % chacun), arrondie
au dixième. Elle n'est plus arrondie à l'entier depuis la version 5 : avec quatre critères à
25 %, la moyenne tombe sur des quarts de point, et arrondir faisait afficher « 13/20 » à côté
d'un niveau calculé sur 12,5 — exactement la contradiction que cette refonte doit faire
disparaître.

**Et le niveau se lit sur cette note** (§6.3), avec **exactement la même table** : c'est le
même barème appliqué une fois par critère, puis à leur moyenne. Il n'y a plus, comme dans les
versions précédentes, de décalage entre l'échelle d'un critère et celle de la note
d'ensemble — c'est précisément ce que la v6 corrige.

### 6.2 Ce que le candidat voit : des bandes, pas des chiffres, par critère

**Une IA ne distingue pas honnêtement un 13 d'un 14.** Afficher « Lexique : 13/20 » suggère
une précision qui n'existe pas. Depuis la version 4, **le candidat voit une appréciation par
critère**, pas un nombre :

| Note interne | Ce qui s'affiche |
|---|---|
| 10 – 20 | Très bonne maîtrise |
| 6 – 9 | Satisfaisant |
| 2 – 5 | En cours d'acquisition |
| 1 | Fragile |
| 0 | Non évaluable |

> Ces bornes **suivent l'échelle de la grille active** : elles ont changé avec la v6, en même
> temps que l'échelle. C'est indispensable — laissées à leurs anciennes valeurs, un critère à
> 8 (un bon B1) se serait affiché « en cours d'acquisition » et un critère à 12 (un B2
> confirmé) « satisfaisant ». Les mots affichés, eux, n'ont pas bougé : les trois applications
> n'ont rien à changer.

Les notes chiffrées par critère continuent d'exister en interne : elles servent au calcul, au
banc de mesure et à la console d'administration.

### 6.2 bis Sur une tâche isolée, la note sur 20 n'est plus affichée

**Ce qui a changé.** Le résultat d'**une tâche** ne montre plus de note sur 20. Il montre votre
**niveau** sur cette tâche, et où vous vous situez à l'intérieur de ce niveau (§6.3 bis). La
note sur 20 continue d'être calculée, enregistrée et affichée — mais **au bilan de l'épreuve
entière** (§6.5), là où elle a un sens.

**Pourquoi.** Deux raisons, qui vont dans le même sens.

1. **C'est ce que fait le vrai examen.** Au TCF, un correcteur humain attribue un **niveau** à
   chaque tâche. La note sur 20 ne porte pas sur une tâche : elle porte sur **l'épreuve
   entière**, les trois tâches ensemble. Afficher « 3,5/20 » sous une tâche, c'était inventer
   une unité que l'examen n'utilise pas à cet endroit.
2. **Sur l'échelle du TCF, une note basse ne veut pas dire ce qu'on croit.** Depuis la v6, nos
   notes sont exprimées sur la table officielle, où **10 sur 20 vaut déjà B2** (§6.6). Un
   « 3,5/20 » y est un **A2 parfaitement normal** — mais tout le monde a appris à l'école qu'un
   3,5/20 est une catastrophe. Nous affichions donc, sous une production correcte pour son
   niveau, un nombre qui se lisait comme un échec.

**Ce que ça ne change pas** : rien dans le calcul. La note est produite exactement comme avant,
enregistrée comme avant, et reste disponible pour le bilan d'épreuve, la console
d'administration et le banc de mesure. C'est un changement d'**affichage**.

### 6.3 Le niveau CECRL par tâche : « performance observée »

Le **niveau CECRL** est le niveau de langue « officiel » (A1 débutant → C2 quasi natif).

Il est affiché **sur chaque tâche**, mais dans une formulation volontairement prudente :

> **Performance observée sur cette tâche : proche du niveau B1**
> Estimation pédagogique portant sur cette seule tâche. Le niveau qui fait foi est celui du
> bilan des trois tâches de l'épreuve.

Trois garde-fous, non négociables :

1. Le mot « proche de » et le rappel du bilan sont **toujours** affichés avec le niveau.
2. Ce niveau **n'est jamais affiché sans la confiance** (§7). Techniquement, si la confiance
   est inconnue, le niveau n'est pas envoyé du tout.
3. Le **bilan d'épreuve** reste le **seul** niveau qui fait foi.

**Comment ce niveau est calculé.** Pas par l'IA : par le serveur, et **directement à partir de
la note** — c'est-à-dire de la moyenne de nos quatre critères :

| Note de la tâche (moyenne des 4 critères) | Niveau |
|---|---|
| 10 et plus | B2 (plafond) |
| 6 à 9,9 | B1 |
| 2 à 5,9 | A2 |
| au-dessus de 0, sous 2 | A1 |
| exactement 0 | A1 non atteint |

**C'est la table officielle du TCF, à l'identique** (§6.6) — l'**échelle**, donc, pas la
correction : notre note est une estimation exprimée dessus (§5.1). Deux changements successifs
y ont mené :

- **version 5** : jusqu'à la 4.2, le niveau était calculé sur la moyenne de trois critères de
  langue seulement (lexique, morphosyntaxe, cohérence), et l'accomplissement de la tâche en
  était **explicitement exclu**. Le résultat était une carte qui pouvait afficher « 11/20 » et
  « proche du niveau A2 » côte à côte. La v5 a fait de la note et du niveau **deux lectures du
  même nombre** : ils ne peuvent plus se contredire *entre eux* ;
- **version 6** : il restait une contradiction, avec l'échelle officielle cette fois. Une même
  carte affichait « 12,5/20 » et « proche du niveau B1 » — or 12,5 vaut **B2** sur la table
  officielle. Un candidat qui connaît cette table lisait donc deux choses opposées. La v6
  supprime l'écart en adoptant l'échelle du TCF pour la note **et** pour chaque critère.

Ce que cela ne veut pas dire : que réussir une tâche simple suffit. Le garde-fou de couplage
(§5.2 bis) et les descripteurs par niveau tiennent cette porte fermée — une langue A2 au
maximum plafonne la note à 5,5/20, donc à A2.

Le niveau que l'IA propose de son côté est conservé en base pour la calibration, mais **n'est
jamais affiché**.

### 6.3 bis Où vous en êtes **dans** votre palier

En retirant la note d'une tâche (§6.2 bis), on retirait aussi le seul signe de progression
**à l'intérieur** d'un palier : un A2 « juste entré » et un A2 « très solide » auraient vu
exactement le même écran, deux tentatives de suite, sans savoir s'ils avaient avancé.

À la place, chaque tâche affiche donc, sous son niveau, **où votre production se situe dans la
bande de ce niveau**, en trois crans :

| Cran | Ce qui s'affiche | Ce que ça veut dire |
|---|---|---|
| bas de bande | **A2 atteint** | vous êtes dans ce palier, il commence à s'installer |
| milieu de bande | **A2 confirmé** | le palier tient sur l'ensemble de la production |
| haut de bande | **A2 solide** | le palier est tenu de bout en bout |

(le niveau change, bien sûr : « B1 confirmé », « B2 solide »…)

**Une règle de formulation, non négociable** : le haut de la bande A2 se dit « **A2 solide** »,
**jamais** « presque B1 ». On vient précisément de retirer la note pour ne plus faire lire un
A2 normal comme un échec ; réintroduire un vocabulaire de manque par cette porte-là aurait
annulé tout le bénéfice. Aucun des trois libellés ne nomme ce qui manque.

**Comment c'est calculé** : le serveur découpe la bande du niveau en trois tiers égaux et
regarde où tombe la note. Les bornes de bande viennent de **la grille active** (§6.1), pas d'une
valeur écrite dans le code : le jour où l'échelle change, les crans suivent tout seuls. Comme
tout le reste, ce calcul est fait **une seule fois, côté serveur** — les applications web et
mobile l'affichent, elles ne le refont pas.

**Cas particuliers** : rien n'est affiché s'il n'y a pas de note, ni pour « A1 non atteint »
(cette bande ne vaut qu'une seule valeur, il n'y a rien à situer). Quand un **plafond** a été
appliqué (§6.4), la position est calculée dans le palier réellement annoncé — jamais en dehors.

### 6.4 Deux plafonds ciblés

Après le calcul du niveau, le serveur applique deux règles qui ne peuvent qu'**abaisser** un
niveau, jamais le relever :

- **Tâche 3 (écrite ou orale) sans opinion identifiable** — si le critère qui porte
  l'accomplissement (**communiquer** depuis la version 5) est **à 1/20 ou moins**, la tâche
  consiste précisément à donner et défendre un avis : le niveau observé ne peut pas dépasser
  **A2**.
- **Oral, tâche 2, sans véritable échange** — même critère, même seuil : le dialogue n'a pas
  vraiment eu lieu, même plafond **A2**.

> **Le seuil valait 5 jusqu'à la v5, il vaut 1 depuis la v6** : ce n'est pas un
> assouplissement, c'est la même règle transposée. Dans les deux cas, le seuil est le **haut
> du palier A1** de l'échelle en vigueur (1-5 hier, 1 aujourd'hui) : le plafond se déclenche
> quand la tâche n'a **pas du tout** été réalisée. Laisser 5 sur la nouvelle échelle aurait
> plafonné à A2 tout candidat dont *communiquer* vaut 5 — c'est-à-dire un A2 **solide** — et
> transformé une règle ciblée en sanction de masse.

Dans les deux cas, le candidat reçoit l'explication en clair, pas seulement un chiffre plus
bas.

**Un plafond compte aussi dans le bilan de l'épreuve.** Ce n'est pas seulement le niveau
affiché sur la tâche qui est abaissé : la tâche entre dans la moyenne pondérée du bilan
(§6.5) **avec son niveau plafonné**, pas avec le niveau qu'elle aurait eu sans le plafond.
Une tâche 3 plafonnée à A2 pèse donc dans le bilan comme une tâche A2 — sinon la règle
n'aurait servi qu'à changer un libellé, alors que le bilan est le seul niveau qui fait foi.

### 6.5 Le bilan d'une épreuve complète

C'est le seul niveau qui fait foi. Il apparaît à la fin d'un examen blanc qui enchaîne les
3 tâches d'une épreuve.

- **La note de l'épreuve est la moyenne des trois notes de tâche**, et **le niveau de
  l'épreuve se lit sur cette note**, avec les mêmes bandes qu'au §6.3. Une seule histoire,
  un seul nombre.
- Les trois tâches comptent **à poids égal** depuis la version 5. Auparavant la tâche 1
  comptait 1, la 2 comptait 2 et la 3 comptait 3. Deux raisons de revenir à l'égalité : le
  TCF publie **une** note sur 20 par épreuve et aucune pondération par tâche ; et la
  difficulté croissante des trois tâches est **déjà** portée par leurs descripteurs (la
  tâche 3 vise B2), la pondérer une seconde fois la compterait deux fois. Le réglage reste
  modifiable sans redéploiement.
- Il est **plafonné à B2**, niveau maximal du profil TCF IRN couvert par SejourFR.
- Une tâche non rendue (temps écoulé, abandon) compte comme **0**.
- Une production hors-sujet compte 0 elle aussi : elle pénalise sans annuler le reste.
- Une tâche **plafonnée** (§6.4) entre avec son niveau plafonné.
- **Une tâche ne se rend qu'une fois par examen.** Un examen blanc, c'est trois tâches,
  une production chacune : une seconde production sur une tâche déjà rendue est refusée.
  Pour refaire une tâche, on relance un examen (ou on s'entraîne librement, hors examen).
- **Une production ne peut être rendue que dans l'épreuve à laquelle elle appartient** :
  une tâche orale dans une session d'expression écrite (ou l'inverse) est refusée. Sans
  cette règle, une production mal aiguillée pouvait clore la mauvaise épreuve et lui poser
  un niveau qui n'était pas le sien.
- **À l'oral, le temps se compte tâche par tâche — il n'y a pas de chrono d'épreuve.**
  Avant chaque tâche, la consigne s'affiche **sans aucun décompte** : on la lit, on la
  prépare, on souffle. Le chrono ne démarre qu'au moment où le candidat appuie sur
  « Je suis prêt · Commencer la tâche », et il porte sur le **temps de parole de cette
  tâche seule** (3 min, puis 3,5 min, puis 3,5 min — les durées du vrai TCF). À zéro,
  l'enregistrement s'arrête et on passe à la tâche suivante. C'est exactement le
  déroulé de l'examen réel, et cela veut dire qu'**une pause entre deux tâches ne coûte
  rien**. *(Il subsiste, invisible, une limite technique de plusieurs heures sur une
  session laissée ouverte : c'est un garde-fou contre les abus automatisés, jamais un
  chrono d'examen.)*
- **Un examen d'expression écrite dure 30 minutes** pour les trois tâches, à répartir
  librement — comme au TCF.
- **Une épreuve qu'on n'a pas pu passer n'a pas de niveau — elle n'est pas « ratée ».**
  Deux cas : l'épreuve était **verrouillée** (compte gratuit qui refait un examen blanc
  complet après avoir déjà utilisé son expression écrite et orale offertes), ou ses
  corrections ont **échoué** techniquement. Dans les deux cas, on n'affiche **aucun**
  niveau pour cette épreuve, et elle n'entre pas dans le niveau global de l'examen. Le
  système annonce alors combien d'épreuves comptent réellement, et le résultat est
  présenté comme **partiel**. C'est une correction d'un défaut grave : jusqu'ici une
  épreuve verrouillée était comptée « A1 non atteint », si bien qu'un candidat lisait
  « votre niveau : A1 non atteint » à côté d'un cadenas « réservé à l'abonnement ».
  Autrement dit, un **verrou commercial** lui était restitué comme un **verdict sur son
  français**. Un abonnement qui manque ne dit rien du niveau de langue de personne.

### 6.5 bis Pas de B2 au bilan sans argumentation (garde-fou de cohérence, **actif**)

Le niveau d'une épreuve est une moyenne des trois tâches. Or les trois tâches ne sont pas
interchangeables : **la tâche 3 est la seule qui demande d'argumenter**, donc la seule qui
puisse démontrer un B2. Quelqu'un qui écrit un message simple impeccable, réussit
l'échange de la tâche 2, puis s'effondre dès qu'il faut défendre un point de vue, sortait
avec un **B2 de bilan** porté par ses deux premières tâches.

La règle, désormais **appliquée** : **quand la tâche 3 est en dessous de B1, le bilan de
l'épreuve ne peut pas dépasser B1.** Une tâche 3 jamais rendue dans une épreuve terminée
compte comme un effondrement (elle vaut 0) ; une tâche 3 pas *encore* rendue dans une
épreuve en cours ne déclenche rien — on ne conclut pas d'une tâche absente.

Ce garde-fou ne peut qu'**abaisser** un niveau, jamais le relever. C'est précisément ce
qui le rend sûr : dans le pire des cas il est trop prudent, jamais trop généreux.

> ⚠️ **Ce choix repose sur un raisonnement, pas sur une mesure — et il faut le dire.** Le
> banc de mesure (§12) **ne peut pas** trancher cette question : son corpus de référence
> porte un niveau attendu **par tâche**, et ne contient **aucune** référence de niveau
> d'épreuve. Il n'existe donc, à ce jour, aucun chiffre disant si la règle rapproche ou
> éloigne nos bilans de ceux d'un jury. Elle a été activée parce qu'annoncer B2 — le
> niveau exigé pour la naturalisation — à quelqu'un qui n'a pas su argumenter revient à
> lui faire payer un examen officiel qu'il va rater. La façon honnête de la vérifier
> viendra de la console de calibration (§14), quand elle aura accumulé de vraies épreuves
> complètes annotées par des enseignants. En attendant, la règle est **réversible d'un
> seul réglage**, et l'éteindre rend exactement les bilans d'avant.

Aujourd'hui il n'existe qu'**un seul palier** de cette règle (« pas de B2 si la tâche 3
est sous B1 »). L'étendre palier par palier — par exemple « pas de B1 si la tâche 3 est
sous A2 » — est possible **sans rien changer au calcul** : il suffirait de déclarer
plusieurs couples (seuil de tâche 3 → plafond de bilan) et de retenir le plus bas. Ce
n'est **pas** fait : on ne généralise pas une règle qu'aucune mesure ne peut encore
valider.

### 6.6 Notre note sur 20 est désormais **celle du TCF** (ce qui a changé, et ce qui n'a pas changé)

C'est le point le plus important de ce chapitre, et celui qui trompait le plus de candidats.

> ⚠️ **Avertissement de mise à jour.** Jusqu'à la version 5, ce paragraphe expliquait
> l'inverse : que notre note était « pédagogique », sur une échelle « plus fine » que celle du
> TCF. **Ce n'est plus vrai.** Toute phrase de ce type encore affichée dans le site web ou
> l'application mobile est devenue fausse et doit être retirée — la liste des écrans concernés
> est à la fin de cette section.

**La note du vrai TCF.** Aux épreuves d'expression (écrite et orale), le TCF IRN donne une
note sur 20 pour **l'épreuve entière** — les trois tâches ensemble — et cette note se traduit
en niveau selon une grille officielle très resserrée :

| Note obtenue au TCF | Niveau attribué |
|---|---|
| 0 | A1 non atteint |
| 1 | A1 |
| 2 – 5 | **A2** |
| 6 – 9 | **B1** |
| 10 – 20 | **B2** |

Autrement dit : **au vrai TCF, 10/20 suffit pour être B2** — le niveau exigé pour la
naturalisation. Et 6/20 suffit pour B1, le niveau exigé pour la carte de résident.

**Notre note.** C'est **la même échelle**, depuis la version 6. Un 12/20 chez nous, c'est du
B2 ; au TCF, un 12/20 c'est du B2. Un 5/20 chez nous, c'est un A2 solide ; au TCF aussi. **Il
n'y a plus d'écart à expliquer au candidat.**

**Pourquoi on a fini par copier l'échelle du TCF.** Pendant longtemps nous ne l'avons pas
fait, et l'argument avait sa valeur : la grille officielle est très comprimée, la moitié de
l'échelle (10 à 20) vaut un seul et même niveau, et un candidat qui passe de 10 à 18 n'y voit
aucune mention changer. Une échelle plus étalée montrait mieux les progrès **à l'intérieur**
d'un niveau.

Ce raisonnement a été abandonné pour une raison plus forte : **il produisait une contradiction
visible à l'écran**. Une même carte de résultat pouvait afficher « 12,5/20 » et « proche du
niveau B1 ». Pour un candidat qui connaît la grille officielle — et tous finissent par la
connaître — 12,5 veut dire B2. Les deux informations se contredisaient, et aucune note de bas
de page n'y changeait rien : entre un chiffre et une explication, c'est le chiffre qui reste
en mémoire. Sur un examen où le B2 conditionne une naturalisation, l'ambiguïté n'est pas
acceptable.

**Ce qu'on perd, et comment on le compense.** On perd la finesse : deux productions B2 de
qualité très différente peuvent désormais se retrouver plus proches. La progression
**à l'intérieur** d'un niveau se lit maintenant ailleurs — dans les **bandes par critère**
(§6.2), dans le bloc « ce que vous avez traité / oublié » (§5.4), dans les priorités et les
exemples corrigés (§5.5), qui disent bien plus qu'un point de note. Et à l'intérieur du B2,
les consignes distinguent explicitement « B2 tout juste atteint » (10-11) de « B2 confirmé »
(12-16), ce qui laisse de la marge visible.

**Ce qu'on affiche pour lever l'ambiguïté.** À la fin d'une épreuve complète (les 3 tâches),
sous le niveau estimé, nous ajoutons la correspondance officielle :

> Au TCF, le niveau B1 correspond à une note de 6 à 9 sur 20.
> *Fourchette officielle du TCF IRN, sur l'épreuve entière.*

C'est une **table de correspondance officielle**, pas une conversion que nous aurions
inventée. Nous **ne transformons jamais** notre note en note de TCF : nous partons du
**niveau** estimé, et nous affichons la fourchette officielle de ce niveau. C'est la seule
chose qui soit honnête, parce que le niveau est la grandeur commune — pas la note.

Depuis la version 5, cette correspondance est une fonction directe de **la note d'épreuve**,
puisque le niveau d'épreuve se lit lui-même sur cette note (§6.3, §6.5) : note d'épreuve →
niveau → fourchette officielle. Depuis la version 6, la note et la fourchette tombent en plus
sur la **même échelle**, ce qui rend l'affichage cohérent au lieu de simplement compatible.

**Ce qui reste interdit malgré tout : le raccourci « notre 13/20 = 13/20 au TCF ».** Même
échelle ne veut pas dire même mesure. Notre note porte sur **une tâche** (ou sur la moyenne
des trois), elle est produite par **un seul correcteur automatique** appliquant **notre**
grille (§5.1) ; celle du TCF porte sur **l'épreuve entière**, est établie par **plusieurs
évaluateurs humains indépendants** appliquant la grille de France Éducation international, sur
un sujet passé une seule fois en conditions réelles. Ce qu'on peut dire honnêtement, c'est :
« sur cette production, notre correcteur situe votre niveau à B1, et au TCF le B1 correspond à
6-9/20 ». Ce qu'on ne peut pas dire, c'est « vous aurez 13/20 au TCF », ni « votre note
officielle serait 13/20 ».

**Où cette correspondance n'apparaît pas, et pourquoi.** Jamais sur le résultat d'une **tâche
isolée**. Au TCF, la note sur 20 récompense une épreuve entière ; une tâche seule n'a pas de
note officielle. Y afficher une fourchette TCF reviendrait à inventer une note qui n'existe
pas — et cela reste vrai depuis la v6, où l'échelle est pourtant la même : c'est le
**périmètre** qui diffère, pas l'échelle. Sur l'écran d'une tâche, on garde donc
« performance observée sur cette tâche » (§6.3) et le rappel que le niveau qui fait foi est
celui du bilan des trois tâches.

**Comment la bascule a été faite sans casser la calibration.** Le piège était connu et il est
écrit ici depuis la version 5 : **déplacer seulement les seuils aurait été une faute.** L'IA
notait avec les repères de l'ancienne échelle, où une performance B2 valait 16-20 ; poser
« B2 ≥ 10 » par-dessus cette notation aurait fait basculer en B2 une masse de productions B1
d'un seul coup, et annulé des mois de calibration mesurée (§12).

La bascule a donc consisté à faire **noter l'IA sur l'échelle du TCF**, pas à réétiqueter ses
notes : chaque repère de notation, chaque descripteur de tâche et **les seize exemples de
calibration** ont été ré-écrits avec leurs notes recalculées sur la nouvelle échelle ; le
garde-fou de couplage et les seuils de plafond ont été recalculés dans la même logique
(§5.2 bis, §6.4) ; et le tout a été **mesuré contre un témoin de la version 5 rejoué le même
jour** (§12.4). Sans ce travail de fond, le changement de seuils seul aurait été cosmétique et
dangereux.

**L'ancien discours a disparu des écrans.** Ils affichaient, sous la note, une phrase du type
« notre échelle est plus fine que celle du TCF, elle sert à suivre vos progrès ». Elle est
devenue fausse et a été retirée du web comme du mobile, remplacée par la lecture directe de
l'échelle : « 10 et plus correspond à B2, 6 à 9 à B1, 2 à 5 à A2 ». Aucun échange de données
entre le serveur et les applications n'a changé : c'était du **texte d'interface** uniquement.

**Ce que l'échelle du TCF a imposé de corriger en plus.** Elle est bien plus resserrée qu'une
note scolaire, et les écrans avaient été dessinés pour une note scolaire. Une production à
**7/20 — c'est-à-dire B1, le niveau exigé pour la carte de résident** — s'affichait
« À retravailler », en rouge, avec « 35 % » en chiffre dominant au centre du cercle. On
décourageait quelqu'un qui avait exactement le niveau qu'il visait. Le pourcentage et les
libellés scolaires ont été retirés, et la couleur suit désormais le **palier CECRL** et non un
seuil sur cent.

**Ce qui reste à arbitrer** (décisions produit, non tranchées) : le cercle de progression se
remplit toujours à `note/20`, donc un B2 à 10/20 montre un anneau à moitié vide ; et les
cartes de tâches du hub web affichent encore un pourcentage calculé en `note × 5`, où un
12/20 — un B2 solide — s'affiche « 60 % ». Ce dernier point vient d'une formule de progression
partagée avec le tableau de bord et les recommandations : le corriger seulement côté web
désynchroniserait les trois surfaces.

---

## 7. La confiance : dire quand on n'est pas sûr

Avant, « 13/20 » s'affichait sur le même ton, qu'il s'agisse d'un texte écrit propre de
90 mots ou d'un dialogue oral transcrit en direct, haché, à moitié illisible. **Ce n'était pas
honnête.**

L'IA déclare donc obligatoirement une **confiance**. Depuis la v8, une phrase la résume :
**la confiance mesure la certitude du correcteur, jamais la qualité du candidat.**

C'était le défaut le plus injuste du rapport. Les consignes disaient « production trop pauvre
pour observer la grammaire » : un candidat qui écrivait un texte **entier, lisible et
complet** — mais faible — se voyait annoncer « confiance moyenne ». On lui laissait croire
qu'on avait un doute sur lui, alors qu'on avait parfaitement observé son niveau : il était
bas. **Un niveau bas est une observation, pas un doute.**

| Confiance | Quand |
|---|---|
| **Haute** | Le correcteur a pu lire ou entendre **tout** ce que le candidat a produit, et la consigne est claire. C'est le cas **normal** — y compris quand la production est très faible ou truffée de fautes. |
| **Moyenne** | Un obstacle **matériel** limite l'observation : transcription partiellement incertaine, passages illisibles, échange interrompu en cours, consigne ambiguë, production trop **brève** pour contenir des marqueurs observables (quelques mots produits — ce qui n'a rien à voir avec quelques fautes). |
| **Faible** | L'obstacle est majeur : transcription très bruitée ou tronquée, tâche interrompue avant d'avoir produit quoi que ce soit d'observable. |

Elle donne 1 à 3 **raisons courtes et lisibles par le candidat**, et **uniquement des obstacles
à l'observation** : « transcription temps réel partiellement incertaine », « échange interrompu
avant la fin », « douze mots produits, trop peu pour observer la syntaxe ». Justifier une
confiance par la qualité (« trop de fautes pour juger ») est désormais **interdit**.

**Le serveur peut abaisser cette confiance, jamais la relever.** Elle est automatiquement
plafonnée à « moyenne » dans deux cas : quand les vérifications automatiques (§4) ont signalé
un **obstacle à l'observation** — c'est-à-dire une production qui ne semble qu'à moitié
rédigée en français —, et quand la production vient d'un **dialogue en temps réel**.

**Le serveur s'applique à lui-même l'interdit qu'il impose à l'IA.** Un énoncé partiellement
recopié (§4) est un soupçon sur l'**origine** des mots, pas un obstacle à leur lecture : le
candidat en est averti, ses passages recopiés sont écartés, et le reste s'observe
parfaitement. Cet avertissement ne plafonne donc **plus** la confiance. Convertir un soupçon
en incertitude de correction était exactement la confusion que la v8 interdit au correcteur ;
le serveur la commettait encore.

Trois interdits absolus, dont le troisième est apporté par la v8 :

- **la confiance ne baisse jamais la note.** La confiance dit ce qu'on **sait** ; la note dit
  ce qu'on a **observé** ;
- **la note ne baisse jamais la confiance.** Une production faible, fautive, élémentaire ou
  courte-mais-complète n'est **pas** une raison d'être moins sûr de soi ;
- une confiance faible n'autorise **jamais** à conclure au hors-sujet ni à
  l'incompréhensibilité.

Si l'IA oublie de déclarer une confiance, sa réponse est désormais **rejetée avant
normalisation**. Le serveur demande une seule réparation ; si le champ manque encore, la
correction passe en échec au lieu d'inventer une confiance ou de persister un résultat
partiel.

---

## 8. Les règles spéciales que l'IA doit respecter

Ces règles existent pour que la note soit **juste**, et pour éviter les pièges connus. Elles
sont toutes encadrées par la règle du §5.6 : *ne pas sanctionner n'est pas créditer*.

- **À l'oral, on ne juge QUE le texte transcrit.** L'IA **n'évalue pas** la prononciation,
  l'accent, l'intonation, le débit, ni la durée. Elle juge le contenu et la langue, comme un
  écrit. Elle **tolère** l'absence de ponctuation, les hésitations et tics oraux (« euh »,
  « ben », « du coup »), les répétitions, les faux départs. Elle **n'évalue pas
  l'orthographe** sur de l'oral transcrit (ce serait juger la machine de transcription, pas le
  candidat). Voir §9 pour ce que cette limite implique vraiment.

- **La transcription temps réel est peu fiable → bénéfice du doute.** Si un passage du
  candidat semble décousu ou incohérent, l'IA ne doit **pas** en conclure qu'il est
  « incompréhensible ». Elle reconstitue son intention à partir du dialogue et lui accorde le
  bénéfice du doute. Un texte bruité justifie une confiance **moyenne ou faible**, jamais une
  note basse. Depuis la grille **v9**, cette règle n'est plus une simple invitation : voir
  **§8 bis**, qui explique exactement ce qu'est un mot mal transcrit et ce qu'on en fait.

- **L'examinateur est le témoin de la compréhension, et le déroulé de l'échange compte.**
  Dans un dialogue (EO temps réel), si l'examinateur a **répondu de façon cohérente** à ce que
  le candidat venait de dire, c'est la **preuve** que le candidat s'est fait comprendre — même
  si son texte transcrit paraît fautif. Depuis **v9**, l'IA doit regarder le déroulé lui-même :
  voir **§8 ter**. Cette réussite de communication se porte au crédit du candidat **dans
  communiquer et interagir** — jamais dans le lexique ni la grammaire.

- **On n'exige jamais l'exhaustivité.** Voir §5.3 : les pistes du sujet ne coûtent rien.

- **La longueur n'est jamais un motif de note.** À l'écrit, la soumission est bloquée hors
  des bornes strictes du TCF IRN (T1 30–60, T2/T3 60–90) : l'IA ne reçoit donc jamais un
  texte nouveau « toléré » au-delà du maximum. À l'oral, la durée n'est plus transmise au
  correcteur et aucun avertissement de durée n'est ajouté au résultat. Une production peut
  offrir moins de matière observable, ce qui peut seulement être expliqué dans les raisons
  de confiance ; ni la longueur ni la durée ne retirent des points.

- **Le hors-sujet, la seule vraie sanction lourde.** Si une production est **totalement**
  hors-sujet (elle ne répond pas du tout à la consigne, ou parle d'autre chose), la note tombe
  à **0** sur **tous** les critères, y compris le lexique et la grammaire, et le niveau à
  « A1 non atteint » — **même si la langue employée est correcte ou riche**. Un hors-sujet
  **partiel**, lui, ne déclenche pas le 0 : il fait fortement baisser le critère de
  réalisation de la tâche, sans annuler la note. ⚠️ Attention : un texte **bruité par la
  transcription** n'est **pas** un hors-sujet.

- **À l'oral, pas de correction d'orthographe.** Les exemples corrigés ne contiennent que des
  reformulations de **phrase** qui améliorent vraiment la clarté. Jamais une correction
  d'orthographe, d'accent, de ponctuation ou d'un mot isolé — ce sont des artefacts de la
  machine de transcription, pas des erreurs du candidat. Le serveur applique ce filtre une
  seconde fois, après l'IA, par sécurité — et depuis le 7 août 2026 il l'applique aussi aux
  **commentaires, priorités et suggestions** (§8 bis).

---

## 8 bis. Quand la machine de transcription se trompe (nouveau : grille v9)

**Le problème, avec un cas réel.** Le 6 août 2026, un candidat passe une tâche d'expression
orale. Il dit « **Lille** », « **sachant qu'à Paris** », « **pour traverser** ». La machine de
transcription écrit « **l'île** », « **ça sent qu'à Paris** », « **par travers** ». L'IA
correctrice, qui ne dispose que de ce texte, a reproché **les trois** au candidat — dans cinq
endroits différents de son rapport, dont une priorité entière construite sur l'idée que « le
nom de la ville n'est jamais donné ». Coût mesuré : environ **1,5 point sur 20** perdu, et
surtout un rapport qui accuse quelqu'un de fautes qu'il n'a pas commises.

Aucun de nos garde-fous ne pouvait le voir. Celui qui existait cherche des **mots** interdits
(« prononciation », « fluidité », « débit »…) ; l'IA n'en avait employé aucun.

### Ce qu'on a changé : la règle de l'artefact

La grille **v9** dit maintenant au correcteur, noir sur blanc, que **ce qu'il lit n'a pas été
écrit par le candidat** : c'est le résultat d'une reconnaissance vocale, qui transforme des
sons en lettres sans comprendre. Il doit donc évaluer **ce que le candidat a manifestement
voulu dire**, reconstruit à partir du contexte de la phrase.

Un passage est un **artefact de transcription** dès qu'il présente l'un de ces trois signes :

1. un mot qui **n'existe pas** en français ;
2. un mot qui existe, mais dont une **relecture proche par le son** rend la phrase cohérente
   (un nom de ville devenu nom commun, deux mots collés, un mot coupé en deux, un homophone) ;
3. une suite de mots grammaticalement impossible **et** dont une relecture proche par le son
   donne une phrase normale.

Face à un artefact, deux obligations, toutes les deux absolues : retenir la lecture la plus
plausible et évaluer **celle-là** ; et **ne le citer nulle part** — ni dans un commentaire, ni
dans une priorité, ni dans une suggestion, ni dans un exemple corrigé, ni comme preuve. S'il
n'y a rien d'autre à citer pour un critère, on **change de passage**.

### Ce qui n'a PAS changé — l'échappatoire est fermée

C'est le point délicat : une règle de doute mal écrite pourrait servir à excuser n'importe
quelle faute. **Une vraie erreur de langue reste une erreur, et elle compte pleinement dans la
note.** Aucune relecture proche par le son ne répare une conjugaison fautive, un accord
manqué, un temps employé pour un autre, une préposition absente, des phrases juxtaposées, un
vocabulaire pauvre ou un mot bien réel employé de travers.

Autrement dit : **le doute porte sur la forme restituée par la machine, jamais sur la
structure ni sur l'étendue du répertoire.** Le candidat bénéficie du doute sur ce qu'il a
**voulu dire** ; jamais sur ce qu'il **n'a pas produit**. C'est la même règle qu'au §5.6 :
lever une sanction n'accorde pas de point.

**La règle de preuve, elle, ne bouge pas d'un iota.** Chaque critère porte toujours une
citation recopiée **exactement** telle qu'elle apparaît, et le serveur la vérifie caractère
par caractère. Le correcteur ne « corrige » donc jamais une citation pour la rendre
plausible : il choisit simplement un autre passage.

### Un filet automatique, en plus de la consigne

Une consigne dans un prompt n'est jamais tenue à 100 %. Le serveur retire donc lui-même, après
coup, **toute remarque qui ne tient que par un mot isolé cité de la transcription** — dans les
commentaires de critère et les priorités (et, tant qu'ils existaient, dans les suggestions et
les exemples corrigés, §5.7 bis). Trois conditions doivent être réunies : la phrase **reproche** quelque
chose, elle **cite** un passage qu'on retrouve réellement dans les paroles du candidat, et ce
passage ne nomme **qu'un seul mot**. Un conseil qui cite un mot (« relie tes idées avec
“parce que” ») n'est jamais touché.

Quand une remarque est retirée, le candidat en est informé :

> Une ou plusieurs remarques portaient sur un mot isolé de la transcription automatique :
> elles ont été retirées. À l'oral, un mot mal transcrit n'est jamais compté comme une erreur
> de votre part.

**Ce filet ne touche ni la note, ni le niveau, ni un seuil, ni un barème** : il n'agit que sur
le texte du rapport.

**Sa limite, dite franchement.** Il ne reconnaît qu'un reproche portant sur **un seul mot**.
Sur le cas réel, il aurait attrapé « l'île » et « par travers », **pas** « ça sent qu'à
Paris » — trois mots que rien ne distingue d'une vraie faute de construction sans dictionnaire
du français, et où une règle plus large supprimerait de **vraies** corrections. Ce cas-là
repose entièrement sur la consigne donnée à l'IA, et c'est pour ça qu'elle a été mesurée au
banc (§12.4).

Depuis le 2026-08-09, ce filet a été **élargi au seul terrain où la règle est claire** : la
grammaire. Voir §8 sexies.

---

## 8 ter. Le déroulé du dialogue compte (nouveau : grille v9)

À l'oral en interaction, l'épreuve mesure la capacité à **échanger** et à **se faire
comprendre**. Le meilleur témoin en est l'échange lui-même — et il est intégralement fourni au
correcteur (les tours de l'examinateur **et** ceux du candidat). Jusqu'à v8, il ne s'en servait
guère que pour donner le bénéfice du doute. Depuis **v9**, le déroulé devient un **élément
d'appréciation** de `communiquer` et `interagir`, à travers trois indices tous lisibles dans le
texte :

1. **L'examinateur a-t-il répondu à propos ?** S'il enchaîne sur le contenu, ou reformule pour
   avancer (« donc vous cherchez plutôt un studio ? »), c'est que le message **est passé** —
   même si le texte transcrit du candidat paraît fautif. Au crédit du candidat.
2. **A-t-il dû faire répéter ?** Une demande explicite (« pardon ? », « vous pouvez
   répéter ? »), ou la **même question reposée** faute de réponse : le message n'est pas passé
   du premier coup. Cela pèse, à la baisse.
3. **L'échange s'est-il maintenu ?** Un candidat qui réagit, relance, pose une question,
   conduit l'échange, se note dans `interagir`. À l'inverse, quelqu'un qui débite des blocs
   sans jamais s'adresser à son interlocuteur y reste bas, même avec une langue correcte.

### La frontière à ne pas franchir

C'est le point sensible, et il est écrit tel quel dans la grille.

- **Une relance de l'examinateur n'est pas une hésitation du candidat.** Ce qu'on observe,
  c'est le **résultat** de l'échange (l'information est-elle passée ?), **jamais la manière de
  parler**. Il reste absolument interdit de fonder la note, le niveau ou un conseil sur les
  hésitations, les répétitions, les faux départs, l'aisance, la fluidité, le débit, les pauses,
  la prononciation, l'accent, l'intonation, l'orthographe ou la ponctuation de la
  transcription, et sur la durée. Quelqu'un à qui l'on demande de répéter peut très bien
  parler : ce n'est pas sa façon de parler qu'on note.
- **Une relance prévue par le scénario n'est pas une incompréhension.** L'examinateur joue un
  rôle : poser la question suivante, ouvrir un thème, objecter pour faire parler, conclure.
  Rien de tout cela ne compte contre le candidat. Seules comptent les demandes **explicites**
  de répétition ou de clarification.
- **Dans le doute, on porte au crédit du candidat.** Un échange qui s'est **poursuivi** est en
  soi la preuve qu'une communication a eu lieu.
- **Ces indices n'entrent que dans `communiquer` et `interagir`.** Le lexique et la
  morphosyntaxe se notent sur les seules paroles du candidat, comme avant : réussir un échange
  ne vaut jamais un point de vocabulaire ni de grammaire.
- **La preuve reste prise dans une parole du candidat**, pour les quatre critères. L'IA peut
  *décrire* ce que l'examinateur a fait ; elle ne le *cite* jamais comme preuve — le serveur
  ne cherche les citations que dans les tours du candidat et la rejetterait.

**Rien n'a changé côté technique** : le dialogue complet était déjà envoyé au correcteur, et
la durée n'est toujours pas transmise. C'est uniquement la consigne qui change.

---

## 8 quater. Quand la machine de transcription change de langue

**Le constat de départ, brut.** En regardant les corrections réellement rendues, on voyait
l'IA reprocher à des candidats d'avoir parlé **russe**, **arabe**, **néerlandais** ou
**anglais**. Or nous sommes une application de préparation au français : les candidats
parlent français. Ce n'était pas eux qui changeaient de langue — **c'était notre
transcripteur**.

### Pourquoi ça n'arrive qu'à l'oral en temps réel

L'examinateur vocal et le transcripteur du temps réel sont **la même IA**, et elle est
multilingue par construction. Son éditeur l'annonce d'ailleurs comme une qualité : elle
« change de langue naturellement au cours d'une conversation ». Résultat : quand un passage
est mal articulé, couvert par un bruit, ou simplement peu audible, elle ne rend pas du
charabia français — elle rend des mots d'**une autre langue**, parfois dans une **autre
écriture**.

Nous avons compté sur nos données réelles, en séparant les deux voies :

| | Transcriptions portant une écriture non latine |
|---|---|
| Oral **enregistré** (Whisper) | **0 sur 36** |
| Oral **temps réel** (examinateur vocal) | **6 sur 39**, soit 15 % |

Côté corrections rendues : **5 corrections orales sur 72** reprochaient au candidat une langue
étrangère, et **les cinq viennent de la voie temps réel**. À l'écrit, un seul cas sur 60 — et
c'en est un **vrai**, le candidat avait bien écrit dans une autre langue.

Le défaut est donc **entièrement** dans la voie temps réel. Deux chiffres donnent l'échelle
du phénomène : les passages fautifs pèsent **de 6 à 24 caractères** dans des transcriptions
de **1 700 à 3 900 caractères**, soit **moins de 1,5 % du texte**. Ce sont des miettes — mais
des miettes que le correcteur reprochait au candidat.

### Ce qu'on a essayé d'abord : imposer le français à la machine

C'est la correction la plus propre, et c'est la première qu'on a cherchée. Elle marche pour
l'oral **enregistré** : on dit à Whisper « écoute du français », et c'est déjà le cas depuis
toujours — ce qui explique son score parfait ci-dessus.

**Pour le temps réel, ce n'est pas possible.** L'outil ne propose aucun réglage de langue
pour ce qu'il *entend*, et les modèles vocaux qu'on utilise **refusent** qu'on leur impose une
langue — la demande ferait échouer l'ouverture de la session et renverrait tout le monde vers
le mode enregistré. Nous le disons franchement plutôt que d'annoncer une correction qui
n'existe pas.

Ce qu'on a pu faire : **verrouiller la langue dans les consignes de l'examinateur vocal**
(persona v3, §10) — celle-là est **livrée et active**. On lui dit explicitement que
l'entretien est intégralement en français, que le candidat passe un examen **de** français et
que ce qu'il prononce est donc du français — et qu'un passage mal compris est du français mal
capté, jamais une phrase étrangère. C'est un **biais, pas une garantie** : nous ne pouvons pas
mesurer son effet sans faire passer des oraux réels. Le vrai filet est ailleurs.

### Ce qu'on a essayé ensuite, et qui n'a pas marché : mieux l'expliquer à l'IA

Deux versions de la grille de notation (**v10** puis **v11**) ont été écrites pour dire au
correcteur, noir sur blanc, qu'un fragment en langue étrangère à l'oral vient de la machine et
ne doit pas être reproché. Les deux ont été **mesurées** contre la grille en service (v9), le
même jour, sur le même modèle, avec les mêmes réglages qu'en production.

| | v9 (en service) | v10 | v11 |
|---|---|---|---|
| Niveau exact | **81,8 %** | 75,6 % | 76,7 % |
| Corrections perdues | **8,3 %** | 14,6 % | 10,4 % |
| Pièges déjoués | **7/8** | 4/8 | 5/8 |

**Les deux sont moins bonnes que ce qu'elles remplaçaient**, et v10 dérivait en plus sur deux
cas de référence : une production **hors-sujet** remontait de « A1 non atteint » à « A1 », et
une transcription simplement **bruitée** passait de A2 à B1. L'explication est simple et vaut
d'être retenue : le texte ajouté (plus de 4 000 caractères) **diluait la sévérité du reste de
la grille**. En demandant à l'IA d'être indulgente sur un point, on l'a rendue indulgente
partout.

Les deux versions sont **conservées** — nous ne supprimons jamais une grille livrée — mais
elles **ne sont pas activées** et la voie est refermée. La leçon est générale : *une consigne
est un vœu.* v9 interdisait **déjà** d'imputer un artefact de transcription au candidat, et le
correcteur l'a fait quand même dans 5 corrections sur 72.

### Le vrai filet : une vérification automatique, après coup

Ce qui règle le problème n'est pas une consigne mais un **contrôle de notre serveur**, appliqué
à la correction une fois qu'elle est rendue. Il est **livré et actif**.

**Ce qu'il fait.** Sur une épreuve **orale** uniquement, il relit le rapport destiné au
candidat et **retire les phrases qui lui reprochent d'avoir employé une autre langue**. Cela
concerne les commentaires de chaque critère, les priorités d'amélioration, les conseils, les
points forts, le résumé d'objectif et les exemples corrigés. Une priorité dont le constat
disparaît est retirée en entier — on ne rend pas un demi-conseil. Un commentaire vidé n'est
jamais laissé vide : il est remplacé par une phrase qui dit franchement pourquoi.

**Le candidat est prévenu.** Un avertissement dédié apparaît dans son rapport : *une ou
plusieurs remarques vous reprochaient d'être passé à une autre langue ; elles ont été retirées,
ces passages viennent de notre transcription automatique.* Nous ne corrigeons rien en douce.

**Ce qu'il ne fait pas.** Il ne touche **ni à la note, ni au niveau, ni à aucun seuil** : la
même correction donne exactement le même résultat chiffré avec ou sans lui. C'est précisément
ce qui permet de le livrer sans nouvelle campagne de mesure.

**Ce qu'il ne touche jamais.** Les **raisons de confiance**. Quand le correcteur écrit
« transcription temps réel partiellement incertaine (passages en russe et en néerlandais,
artefacts de reconnaissance vocale) », il a **raison**, et il le dit au bon endroit : la langue
étrangère y est traitée comme une gêne pour *lire* la production, pas comme une faute du
candidat. C'est exactement là qu'elle doit vivre, et rien ne l'en retire.

### À l'écrit, rien de tout cela ne s'applique

**C'est volontaire, et c'est la partie la plus importante de la règle.** À l'écrit, aucune
machine ne s'interpose entre le candidat et son texte : il a tapé chaque mot. Une phrase en
anglais dans une production écrite est **une vraie non-réalisation** de la consigne, et elle
doit remonter au candidat sans aucun bénéfice du doute. Le contrôle n'est donc **jamais**
appliqué à l'expression écrite.

L'asymétrie ne dit pas que l'oral est moins exigeant. Elle dit que **l'oral passe par une
machine et l'écrit non**.

### Le point délicat : ne pas effacer un vrai changement de langue

Un candidat qui répond **réellement** en espagnol doit continuer d'être sanctionné — sinon
cette protection deviendrait une porte de sortie. Le serveur ne juge donc pas « au feeling » :
avant de retirer quoi que ce soit, il **mesure la production elle-même**, sur les seules
paroles du candidat (jamais celles de l'examinateur).

Deux mesures, deux plafonds. Au-dessus de **l'un ou l'autre**, **plus rien n'est retiré** :

1. **La part d'écriture étrangère** (arabe, cyrillique…) doit rester **sous 15 %**. Sur nos
   données réelles, les hallucinations plafonnent à **6,8 %** ; une production vraiment écrite
   dans un autre alphabet en est proche de 100 %.
2. **La part de mots-outils d'une autre langue** (« dus », « porque », « the », « however »…)
   doit rester **sous 6 %**. Sur les 75 transcriptions réelles, le maximum observé est
   **1,4 %** ; sur les 48 productions de référence du banc, 47 sont à **0 %** — et celle où le
   candidat bascule vraiment en espagnol est à **12,5 %**.

S'y ajoute une condition de bon sens : **au moins 40 mots exploitables**. En dessous, un seul
mot pèserait plus que le seuil, et une production quasi muette est justement celle où un vrai
changement de langue est le plus plausible.

**Pourquoi deux mesures et pas une.** L'écriture ne trahit rien quand la langue s'écrit avec
notre alphabet : anglais, néerlandais, espagnol passent inaperçus. Et compter les *mots
français* ne suffit pas non plus — nous l'avons vérifié : la production de référence où le
candidat bascule en espagnol contient **36 % de mots-outils français**, soit **plus que huit
vraies transcriptions françaises** de nos données. Les langues voisines partagent trop de
petits mots avec le français. Il fallait donc compter directement la matière **étrangère**.

**En cas de doute, on ne retire rien.** Le sens de l'erreur est assumé : laisser passer un
reproche injuste est moins grave qu'effacer la détection d'une production qui n'est pas en
français.

### Ce qui n'a pas bougé

Un contrôle plus ancien vérifiait **déjà**, avant même d'appeler l'IA, qu'une production est
bien en français (§4) : une production massivement dans une autre langue est refusée sans que
l'IA ait son mot à dire. Il n'a pas changé. Le nouveau filet règle le sort des **fragments**
qui passent sous ce seuil — et qui sont précisément ceux que notre transcripteur fabrique.

N'ont pas bougé non plus : l'échelle, les quatre critères, les seuils, le garde-fou de
couplage, les plafonds, les bandes affichées, la règle de preuve littérale et le garde-fou de
l'oral.

---

## 8 quinquies. Le conseil qui ne pouvait pas vous faire progresser

### Ce qui s'est passé

Dans une correction réelle, l'IA a écrit :

> « cette version emploie une subordonnée causale avec **« parce que »**, **marqueur attendu au
> B1** »

et, quelques lignes plus bas :

> « Pour viser le palier B1, essaie d'ajouter … *j'aime discuter avec elle **parce qu'**elle est
> très agréable*. »

Le candidat a suivi ce conseil à la lettre, a refait le sujet… et a obtenu **exactement la même
note**. C'est normal : **« parce que » n'est pas un marqueur B1 dans notre grille, c'est un
marqueur A2.** Notre propre grille le dit deux fois — le descripteur A2 parle de « phrases
simples coordonnées (parce que, mais, alors) », et pour dépasser le A2 elle exige des
connecteurs qui organisent le propos « **au-delà de** et / mais / parce que / après / aussi ».

Ce n'était donc pas un conseil un peu faible : c'était un conseil **structurellement incapable**
de faire monter le niveau. Un candidat qui le suit perd du temps et, pire, perd confiance dans
la correction.

### Pourquoi on n'a pas simplement « mieux expliqué » à l'IA

Parce que la grille le dit **déjà**, et que dans la même correction l'IA se contredisait
elle-même (elle parlait ailleurs de « marqueurs A2 »). Ajouter du texte à la grille est aussi la
chose qui a été **mesurée comme dégradante** dans ce projet (§8 quater : 81,8 % → 75,6 % de
niveaux exacts après l'ajout d'un simple bloc de consigne).

La règle du projet est constante : quand on peut rendre un comportement **impossible** par un
contrôle automatique, on ne se contente pas de le déconseiller.

### Ce que fait le contrôle

Après la correction, le serveur relit les endroits du rapport où un conseil peut se glisser —
aujourd'hui les **priorités d'amélioration** — et **retire la phrase** qui présente un moyen de
niveau A2 comme la clé d'un palier **supérieur**. (Il relisait aussi les **suggestions** et la
phrase « ce que cette reformulation démontre » des **exemples corrigés** ; ces deux blocs
n'existent plus depuis la v15, §5.7 bis, et le contrôle les couvre toujours pour le cas d'un
retour en arrière.) Le candidat est prévenu par une phrase claire : une remarque a été retirée, parce
qu'elle promettait un palier qu'elle ne pouvait pas donner.

Ce contrôle **ne touche ni votre note, ni votre niveau, ni un seuil, ni un barème**. Il n'agit
que sur le texte du rapport, et seulement après que la note a été calculée.

### La frontière : en cas de doute, on ne retire rien

Un conseil n'est retiré que s'il réunit **les deux** conditions dans la **même phrase** :

1. il promet un palier **au-dessus du A2** — « B1 » ou « B2 » nommés, ou une formule du type
   « pour gagner un niveau » quand le niveau constaté est déjà A2 ou plus ;
2. il **désigne** un de ces petits mots comme le moyen d'y arriver : soit en le citant seul
   (« ajoute « parce que » »), soit en écrivant « parce que » juste après un mot de désignation
   (« avec », « comme », « connecteur », « employer »…).

Ce qui **passe** sans être touché, et c'est voulu :

- **conseiller « parce que » sans promettre de palier** (« relie tes deux idées : remplace le
  point par « parce que » ») — c'est un bon conseil, et c'est même l'exemple que donne notre
  propre grille ;
- **viser le A2 depuis le A1** : là, « parce que » est exactement le bon levier. Le contrôle
  regarde donc le niveau réellement constaté avant de trancher ;
- un conseil juste qui **contient** un « et » ou un « mais » sans en faire son sujet. Exemple
  réel, qui doit absolument être conservé : « Pour viser le palier au-dessus, envisage une
  objection et réponds-y : *On pourrait me dire que les grandes villes offrent plus d'activités,
  **mais** à l'île, la qualité de vie compense largement.* » Ici « mais » est un simple mot de
  liaison, et le conseil décrit précisément ce que la grille demande pour le B2 ;
- **ce que l'IA cite de vous** n'est jamais modifié : votre propre texte contient évidemment des
  « parce que », et il est rendu tel quel ;
- le **raisonnement interne** de l'IA sur votre niveau n'est pas concerné non plus : il ne vous
  est de toute façon jamais montré.

### Comment ces frontières ont été choisies

Sur les **138 corrections** déjà rendues en base, soit **707 morceaux de rapport**, la règle
retenue retire **5 phrases — les 5 fautives — et aucune autre**. Deux variantes plus larges ont
été essayées puis rejetées **sur ces mêmes données**, parce que chacune supprimait un conseil
juste : celle qui regardait tous les petits mots à l'intérieur des exemples cités effaçait le
conseil « objection… mais… » ci-dessus, et celle qui acceptait n'importe quel petit mot après un
mot de désignation effaçait un conseil sur le passé composé.

Le sens de l'erreur est assumé, comme pour le garde-fou de l'oral : **il vaut mieux laisser
passer une promesse douteuse qu'effacer un vrai conseil.**

### L'autre endroit où le même défaut existait : les leviers de la version au niveau visé

Le contrôle décrit ci-dessus ne regarde que le **rapport de correction**. Les leviers de la
« version au niveau visé » (§5.9) sont produits par un **autre appel**, sous un autre contrat —
ils échappaient donc entièrement à ce filet, et le même défaut s'y trouvait. C'est corrigé, avec
**la même reconnaissance des petits mots**, écrite une seule fois et partagée par les deux
contrôles. Le détail, et les frontières propres à cet encart, sont au **§5.9**.

### Ce qui est compté

Chaque retrait est **compté** par famille, comme les refus de sortie (§12.3 bis) : un contrôle
muet est un contrôle qu'on ne peut pas piloter. Si demain ce filet se déclenchait sur une
correction sur deux, ce serait le signe d'un problème de grille, pas d'un incident isolé. Les
deux surfaces — le rapport et les leviers du §5.9 — sont comptées **séparément**, pour pouvoir
dire laquelle dérive.

---

## 8 sexies. À l'oral, une faute de grammaire est une **structure**, jamais la forme d'un mot

### Ce qui s'est passé

Un candidat a dit « **j'habite à Lille** ». La transcription automatique a mangé le début du
mot et a écrit « **abit à Lille** ». Le correcteur, qui ne lit que la transcription, l'a
consciencieusement rangé dans les erreurs de grammaire :

> quelques erreurs perceptibles : « abit à Lille » (j'habite)…

**On reprochait au candidat un défaut de notre propre machine.** Ce n'est pas un détail de
présentation : c'est la phrase que le candidat lit sous son critère de grammaire, et c'est
elle qui justifie sa note à ses yeux.

### Ce que la mesure a montré

Nous avons repris les **142 évaluations** déjà rendues et cherché, dans les phrases de
reproche, les passages cités entre guillemets qui figurent bien dans la production mais
n'existent dans **aucun** dictionnaire français (475 000 formes) :

| | évaluations concernées | dont défaut machine | dont vraie faute |
|---|---|---|---|
| **Oral (75)** | 9 — 12,0 % | **9** | **0** |
| **Écrit (67)** | 4 — 6,0 % | **0** | **4** |

**Zéro à l'écrit, non nul à l'oral.** La cause est donc la machine, pas le niveau du
candidat : à l'écrit il tape chaque lettre lui-même, une forme fautive y est une vraie faute.

### La règle qu'on en a tirée

À l'oral, une faute de grammaire s'entend sur un **enchaînement** : un accord à distance, un
temps mal choisi, une construction de verbe, une subordonnée. Elle se cite donc de deux
façons, et de deux seulement :

- sur **au moins trois mots pleins** (« je suis des nationalités guinéennes ») — c'est une
  structure, elle est **conservée** ;
- sur des **mots-outils seuls** (« pour ne pas que ») — c'est aussi une structure, elle est
  **conservée**.

Entre les deux — un ou deux mots pleins isolés (« abit à Lille », « zérer ») — le reproche ne
décrit pas une structure : il nomme une **forme**. Or une forme isolée est exactement ce que
la reconnaissance vocale fabrique, et une faute de forme courte (« les enfant ») est de toute
façon **inaudible** : c'est de l'orthographe, que notre grille interdit déjà de reprocher à
l'oral. La remarque est donc retirée, et le candidat est prévenu :

> Une ou plusieurs remarques de grammaire portaient sur la forme d'un ou deux mots de la
> transcription automatique : elles ont été retirées.

**Où ça s'applique, et nulle part ailleurs** : à l'**oral** seulement, sur le **critère de
grammaire** et sur les priorités qui le reprennent. Jamais sur le vocabulaire — une remarque
de vocabulaire porte légitimement sur un mot, et la même règle y aurait supprimé deux
remarques justes que nous avons retrouvées en base (dont une citée en **point fort**). Jamais
à l'écrit.

### Ce que ça coûte, et pourquoi on l'accepte

La phrase entière est retirée, pas seulement la citation fautive : retirer une citation au
milieu d'une énumération rendrait au candidat une phrase mutilée. Conséquence mesurée sur les
75 commentaires de grammaire à l'oral déjà rendus : **11 phrases** disparaîtraient, dont
environ sept contenaient *aussi* une vraie faute. On perd donc du conseil.

C'est un choix assumé : **reprocher à quelqu'un une faute que notre machine a inventée coûte
plus cher que taire une faute réelle**. Le candidat garde par ailleurs ses priorités de
travail, ses exemples corrigés et sa note.

### Ce que ça ne répare pas — à dire franchement

Sur le cas réel ci-dessus, le correcteur citait **trois** fautes, et les trois étaient des
défauts de transcription. Notre règle en identifie **une seule** (« abit à Lille ») ; les deux
autres (« j'aimerais bien que start up », « on se rend compte ») sont du français
parfaitement valide, que rien ne distingue d'une vraie maladresse. Comme elles vivent dans la
même phrase, elles partent avec — mais par ricochet, pas parce qu'on sait les reconnaître.

Et surtout : **ce filet ne touche ni la note, ni le niveau, ni un seuil**, comme tous les
autres filets de ce document. Le candidat du cas réel reste donc à sa note. Ce qui change,
c'est qu'on cesse de lui reprocher quelque chose qu'il n'a pas dit.

---

## 8 septies. Savoir **quand** la transcription est abîmée

### Le problème : on payait un signal qu'on jetait

Notre transcripteur écrit (Whisper) nous renvoie, à chaque correction, des indicateurs de
confiance sur ce qu'il a entendu. **Nous ne les lisions pas.** Et notre transcripteur en temps
réel, lui, n'en renvoie aucun — alors que c'est la source la plus fragile.

Résultat concret : entre le **28 juin et le 4 juillet 2026**, un défaut a coupé les mots en
morceaux dans toutes les sessions orales en temps réel (« l'emplo yé de l'age nce de location
de voi ture »). Il a fallu des semaines pour le voir, parce qu'**aucun chiffre ne le disait**.

### Ce qu'on mesure maintenant, sans rien payer de plus

Deux comptages simples sur les seules paroles du candidat :

1. la part de **mots très courts inconnus** — un mot français de trois lettres appartient à
   une liste courte et fermée ; un débris de mot coupé (« nce », « voi », « lou ») n'y est
   jamais ;
2. la part de **collages** — deux débris qui se suivent (« ves te », « com me commer cial »),
   la signature du mot coupé.

Nous n'embarquons **pas** de dictionnaire français complet : il aurait pesé plusieurs
mégaoctets pour un résultat moins net. Vérification faite sur les 123 productions
exploitables de notre base, la liste courte sépare parfaitement : les 8 sessions de la
semaine du défaut sont entre **18 % et 27 %** de mots courts inconnus, les 24 sessions
suivantes toutes **sous 5 %**. Il n'existe **aucune** production entre les deux. Le seuil est
posé à **10 %**, au milieu de ce fossé.

### Ce que ça déclenche — et rien de plus

Quand une transcription est déclarée abîmée :

- **plus aucun reproche de grammaire adossé à une citation n'est retenu** : le correcteur n'a
  pas lu ce que le candidat a dit, aucun de ces reproches n'est opposable ;
- la **confiance** de l'évaluation est abaissée, avec sa raison écrite noir sur blanc. C'est
  exactement le bon endroit : la confiance dit la certitude du **correcteur**, et une
  transcription abîmée est un obstacle à l'**observation**, pas un défaut du candidat.

**La note, le niveau et les seuils ne bougent jamais.**

### Et pour la suite

Les deux comptages sont désormais **enregistrés** à côté de chaque transcription, avec les
indicateurs de Whisper qu'on jetait. La question « nos transcriptions se dégradent-elles ? »
se répond maintenant en une seule requête. C'est l'argument principal de tout ce chantier :
sans cela, on répare un cas et on reste aveugle au suivant.

---

## 8 octies. Le **diagnostic** oral protégé lui aussi (nouveau, 14 août 2026)

### Ce qui s'est passé

Le **diagnostic initial** — les deux exercices de 5 minutes qu'on passe en arrivant, un écrit
puis un oral — est corrigé par une machine **distincte** de celle qui corrige les productions
complètes. Elle a son propre contrat, ses propres garde-fous, et surtout : elle ne traversait
**aucun** des filets décrits dans les sections précédentes.

Résultat, sur une session réellement jouée. Le candidat a demandé les **horaires** d'une
activité ; notre transcription a écrit **« horreurs »**. Le rapport lui a alors répondu :

> « Demande les horaires et le tarif, mais « horreurs » pour « horaires » est une erreur
> lexicale qui peut gêner. »

On lui reprochait un mot qu'il n'avait pas dit — et sur le **tout premier écran** du produit,
celui qui doit lui donner envie de continuer.

### La correction

La même règle qu'à la section 8 sexies s'applique désormais au **volet oral du diagnostic** :

- une remarque **qui reproche quelque chose**, **qui cite un passage réel** de la
  transcription, et dont la citation ne nomme **qu'un ou deux mots pleins**, est **retirée** ;
- une remarque qui cite **trois mots ou plus**, ou **aucun mot plein** (« pour ne pas que »),
  décrit une **structure de phrase** : elle est **conservée** ;
- si la transcription a été jugée **abîmée** (section 8 septies), toute remarque appuyée sur
  une citation tombe, quelle que soit sa longueur.

### La seule différence avec les productions complètes

Sur une production complète, ce nettoyage ne touche que les remarques de **grammaire**, jamais
celles de **vocabulaire** : on y a mesuré des cas où une vraie remarque de vocabulaire aurait
été effacée à tort.

Le diagnostic, lui, **n'a pas cette séparation** : ses observations portent sur des
**compétences** (« poser des questions précises », par exemple), pas sur des critères de
langue. Il n'y a donc rien sur quoi restreindre le nettoyage.

Le choix retenu est de nettoyer **quand même**, y compris quand la remarque se dit
« lexicale », parce que les deux explications possibles mènent au même endroit : soit notre
transcripteur a mal entendu, soit le candidat a mal prononcé — et **nous nous interdisons déjà
de juger la prononciation** (section 9). Dans les deux cas, la remarque n'a pas à être rendue.

### Ce qui n'est jamais touché

- **L'écrit du diagnostic.** Rien du tout. À l'écrit, le candidat tape chaque mot : aucune
  machine ne s'interpose. Le déséquilibre vient de notre chaîne technique, pas du niveau exigé.
- **Le jugement.** Ni le niveau estimé, ni le verdict sur la tâche, ni la priorité, ni la
  confiance, ni l'ordre des priorités du Plan. On retire une **phrase**, pas un verdict. Le
  diagnostic ne produit d'ailleurs aucune note sur 20.
- **Les points forts.** On n'efface pas un compliment.
- **Le passage cité en preuve.** Il reste affiché : sans lui, le reste devient incompréhensible.
- **L'observation elle-même.** Si son explication disparaît en entier, l'observation **reste**,
  simplement sans explication. **Un nettoyage ne fait jamais échouer un diagnostic** — le
  candidat ne perd jamais ses deux productions pour cette raison.

### Ce qu'on en mesure

Chaque phrase retirée est comptée à part de celles des productions complètes. Sur les
**8 analyses orales de diagnostic** existantes, **une** portait ce défaut — la même proportion,
environ une sur huit, que celle mesurée sur les productions complètes.

---

## 9. L'oral : ce que nous ne savons pas évaluer

**C'est une limite technique, pas un choix pédagogique — et le candidat en est informé.**

À l'oral, nous n'avons que le **texte transcrit**. Nous savons donc évaluer le vocabulaire,
la grammaire, le contenu, l'organisation, et une bonne partie de l'interaction. Nous **ne
savons pas** évaluer l'aisance, la fluidité, le débit, les vraies hésitations,
l'intelligibilité et la prononciation — qui comptent pourtant à l'examen officiel.

Chaque correction orale porte donc cet avertissement, mot pour mot :

> Cette évaluation est fondée sur la transcription écrite de votre production : nous
> n'analysons pas votre voix. L'aisance, la fluidité, le débit et la prononciation ne sont
> donc pas évalués ici — c'est une limite technique de notre correction, pas un choix
> pédagogique. À l'examen officiel, ces dimensions comptent.

Il est **interdit** à l'IA de présenter cette absence comme un avantage (« votre accent n'est
pas pénalisé »), et interdit de dire quoi que ce soit de l'accent, de l'aisance ou de la
fluidité — elle ne les a pas entendus.

### Un garde-fou qui ne doit plus détruire une correction entière

Cette interdiction est vérifiée automatiquement sur chaque champ, et jusqu'au 6 août 2026 elle
était **fatale partout** : une seule phrase interdite, non réparée à la seconde tentative, et
toute l'évaluation était perdue. C'est arrivé, sur une tâche d'examen blanc : deux **exemples
corrigés** parlaient de « répétitions », la correction a échoué, la tâche a été perdue.

C'était disproportionné. Les exemples corrigés **n'entrent dans aucun calcul** — la note est
recalculée à partir des seuls critères —, ils sont plafonnés à trois, ils peuvent être une
liste vide, et le serveur y jette déjà des entrées de lui-même. Désormais, une entrée fautive
est simplement **supprimée**, et le reste de la correction est rendu au candidat.

La frontière est explicite, et elle n'a bougé nulle part ailleurs. Restent **fatals**, parce
qu'ils portent le jugement lui-même : la justification du niveau, les commentaires de chaque
critère, les points forts, les priorités et le bloc d'accomplissement. Étaient **purgés** : les
exemples corrigés. Aucune tolérance n'a été ajoutée sur les notions interdites : ce sont
exactement les mêmes. ⚠️ Depuis la **v15**, les exemples corrigés et les suggestions ne sont
plus produits (§5.7 bis) : cette frontière ne décrit donc plus qu'un cas de retour en arrière —
mais elle reste en place, et le contrôle qui l'applique aussi.

**Pourquoi on ne corrige pas ça tout de suite.** Deux obstacles sérieux :

1. **Pour deux tâches sur trois, l'audio n'existe pas de notre côté.** En oral temps réel
   (T1 et T2), le candidat parle **directement** au fournisseur de voix ; seul du texte nous
   revient. Analyser la voix supposerait de capturer et remonter l'audio : nouveau chantier,
   nouveau coût de stockage, et une vraie question de vie privée. En l'état, on ne pourrait
   analyser que les productions **enregistrées** — et deux candidats seraient alors notés sur
   des critères différents selon le mode choisi. Inacceptable.
2. **Un risque d'équité.** Notre public, ce sont des personnes en démarche de titre de séjour
   ou de naturalisation, donc massivement des accents non natifs. Demander à une IA de juger
   « prononciation et fluidité » sur de l'audio, c'est précisément le terrain où ces modèles
   sont connus pour être moins performants selon l'accent et la langue maternelle. On
   risquerait de fabriquer un correcteur qui pénalise systématiquement certaines origines.

Une mesure **neutre vis-à-vis de l'accent** est déjà écrite mais **éteinte** : le débit
(mots par minute) et le nombre de silences longs. Voir §13.

---

## 10. L'examinateur vocal (EO en temps réel)

Pour l'EO tâches 1 et 2, le candidat peut passer un **vrai oral parlé** avec un examinateur
joué par une IA vocale (technologie Google Gemini Live). Deux choses à bien distinguer :

- **L'examinateur CONDUIT l'entretien. Il ne note pas.** Il pose des questions, réagit, joue
  un rôle (T2), mais il **ne corrige jamais**, **ne donne aucune note**, **ne laisse rien
  deviner** de l'évaluation. La note vient **après**, séparément, de l'IA correctrice.

- **L'examinateur reste dans son rôle et n'oriente pas.** Il **ne souffle jamais** au candidat
  quelles questions poser ou quelles informations demander. En T2 (jeu de rôle), c'est le
  **candidat** qui mène et pose les questions ; l'examinateur **répond** et attend, sans
  prendre l'initiative.

### Le verrou de langue (nouveau : persona v3)

La même IA joue l'examinateur **et** écrit la transcription de l'échange. Elle est multilingue,
et son éditeur en fait un argument : elle « change de langue naturellement au cours d'une
conversation ». Pour un examen de français, c'est un défaut, pas une qualité — c'est lui qui
faisait apparaître des passages en arabe ou en néerlandais dans les transcriptions
(§8 quater).

Ses consignes lui disaient déjà de **parler** exclusivement français. Elles lui disent
maintenant, en plus, comment **entendre** :

- l'entretien se déroule **intégralement en français, des deux côtés**, du premier au dernier
  mot ;
- le candidat passe un examen **de** français : par définition, ce qu'il prononce **est** du
  français — même avec une prononciation approximative, un accent marqué, une phrase
  inachevée ou un micro qui grésille ;
- un passage mal compris est du français **mal capté**, jamais une phrase étrangère. Elle ne
  doit ni lui substituer des mots d'une autre langue, ni écrire la parole du candidat dans une
  autre écriture. Si elle n'a pas compris, elle demande simplement de répéter — en français ;
- elle ne bascule jamais vers une autre langue, même si on le lui demande.

**Honnêteté sur la portée.** C'est le seul levier que l'outil nous laisse : il n'existe aucun
réglage permettant d'imposer la langue de ce qu'il entend. C'est donc un **biais donné au
modèle, pas une garantie technique**, et son effet ne se mesure pas sur notre banc (qui rejoue
des textes déjà transcrits, sans jamais appeler l'examinateur vocal). Le filet qui protège
réellement le candidat est la vérification automatique décrite au §8 quater.

Tout le reste de la persona est **inchangé** — conduite de l'entretien, fiche de scénario,
interdiction de corriger la langue du candidat : v3 ajoute trois règles, elle n'en réécrit
aucune.

### La fiche de scénario de la tâche 2

**En tâche 2, l'examinateur connaît ses réponses à l'avance.** Chaque sujet de jeu de rôle est
accompagné d'une **fiche de scénario** : le rôle tenu, la manière de s'adresser au candidat
(vouvoiement ou tutoiement), la phrase d'accueil, et surtout **les faits** — les prix, les
délais, les horaires, les conditions.

Avant, l'examinateur les inventait au fil de la conversation et pouvait **se contredire**
(annoncer 12 €, puis 15 €), ce qui pénalisait injustement un candidat qui avait bien écouté.
Désormais ces informations sont **fixées d'avance** : il ne peut ni les changer en route, ni
en inventer d'autres. S'il n'a pas la réponse, il le dit simplement, sans donner de chiffre au
hasard. Si le candidat lui prête une valeur fausse, il corrige **le fait** avec naturel —
jamais la langue du candidat.

Quatre précisions qui comptent :

- **Ce n'est PAS une check-list de notation.** Les questions du sujet restent des **pistes** :
  ne pas toutes les poser n'a jamais été et n'est toujours pas une faute. La fiche sert à
  rendre l'examinateur **cohérent**, pas à cocher des cases. Une information non obtenue est
  au plus une observation informative ; elle **ne fait baisser aucune note**. La fiche n'est
  d'ailleurs jamais transmise à l'IA correctrice.
- **Il ne livre pas ses informations spontanément.** Il répond à la question posée, puis
  attend la suivante. C'est bien au candidat d'aller chercher l'information.
- **Le candidat ne voit jamais cette fiche.** Elle reste côté serveur : l'afficher
  reviendrait à donner les réponses de l'examen.
- Les **20 sujets** de tâche 2 existants ont tous leur fiche. Si un sujet futur n'en avait
  pas, l'examinateur se comporterait exactement comme avant : aucun sujet n'est dégradé.

### Réglages pensés pour le confort du candidat

- **Le candidat lit d'abord son sujet, puis démarre quand il est prêt.** Avant chaque tâche, sa
  consigne (en Tâche 2, la situation du jeu de rôle) s'affiche à l'écran ; l'examinateur ne
  commence à parler qu'au moment où le candidat appuie sur « Commencer ». Ce sujet **reste
  consultable** pendant tout l'échange (utile en Tâche 2, où c'est le candidat qui mène).
- **Le chrono de la tâche ne démarre qu'au premier mot de l'examinateur.** Le temps de
  connexion et d'accueil n'est **pas** décompté du temps de parole du candidat.
- **L'examinateur est patient mais réactif.** Il laisse le candidat finir ses phrases (il ne le
  coupe pas sur une pause de réflexion), tout en répondant assez vite pour que l'échange reste
  fluide. Le détail de ce réglage — et pourquoi il vient d'être modifié — est juste en dessous.
- **Quand le temps est écoulé, l'examinateur termine sa phrase de conclusion.** Il n'est pas
  coupé au milieu d'un mot, et il n'y a pas non plus de silence inutile avant la suite.
- **Il parle un français normal**, clair et accessible, sans s'adapter artificiellement au
  niveau du candidat (comme à un vrai examen). S'il n'a pas compris, il demande simplement de
  répéter — il ne fait jamais semblant d'avoir compris.
- **Il ne bascule jamais dans une autre langue**, ne corrige jamais, n'explique jamais qu'il
  est une IA.
- **Si le candidat ne dit rien, il n'y a rien à noter.** Quand on laisse seulement
  l'examinateur se présenter puis qu'on termine sans avoir parlé, l'application l'annonce
  clairement (« Aucune prise de parole — rien à évaluer ») et invite à reprendre l'échange, au
  lieu d'ouvrir un bilan vide.
- **La session est vérifiée avant d'être ouverte, pas après coup.** Une simulation orale ne
  démarre que si elle peut réellement être notée : l'épreuve visée doit être la bonne, encore
  ouverte, dans les temps, et la tâche pas déjà rendue dans cet examen. Autrement dit, la
  simulation orale obéit exactement aux mêmes règles que l'enregistrement classique — elle ne
  permet pas de rendre une tâche que l'autre voie aurait refusée, et on ne peut plus consommer
  une simulation pour s'entendre dire à la fin qu'il n'y avait rien à noter.

### Quand l'examinateur décide que vous avez fini de parler

Pendant un oral, personne ne dit « à toi » : c'est la machine qui doit deviner, à partir du
silence, que le candidat a terminé sa phrase. Ce réglage a **deux façons de mal tourner**, et
elles sont opposées :

- trop **impatient**, il coupe un apprenant au milieu d'une hésitation — celui qui cherche son
  mot est puni d'avoir cherché ;
- trop **prudent**, il attend longuement après le dernier mot, et l'échange devient poussif :
  « je finis ma phrase et l'examinateur met une éternité à répondre ».

Le réglage est volontairement au maximum de la prudence. En usage réel c'est un peu lent — le
propriétaire de la plateforme a constaté lui-même l'attente — et une tentative a été faite le
2026-08-12 pour passer à un « cran intermédiaire ».

**Ce cran intermédiaire n'existe pas**, et l'avoir cru a coûté cher : le service vocal
n'accepte que deux réglages, le prudent et le rapide. En lui demandant une valeur inconnue, il
a **refusé d'ouvrir chaque conversation** — du 12 au 16 août 2026, plus **aucun** oral avec
examinateur n'a pu démarrer, ni sur le site ni sur l'application. Pire : personne ne le voyait.
Le candidat choisissait « avec un examinateur », et se retrouvait sur l'enregistrement seul
**sans un mot d'explication**, comme s'il l'avait demandé.

Trois choses ont changé le 2026-08-16 :

- le réglage est **revenu au cran prudent**, le seul autre disponible — le cran rapide reste
  écarté, il couperait la parole à un apprenant A2 qui cherche son mot ;
- une valeur de réglage inconnue **empêche désormais le serveur de démarrer**, au lieu de
  désactiver l'oral en silence : mieux vaut une panne visible qu'une fonctionnalité morte que
  personne ne remarque ;
- quand l'examinateur n'est **pas** disponible, quelle qu'en soit la raison, le candidat le
  **lit** avant de s'enregistrer seul. Il n'est toujours jamais bloqué — mais on ne fait plus
  disparaître son choix sans rien dire.

Le vrai levier de réactivité, lui, n'a jamais dépendu de ce cran : c'est la durée de silence
ci-dessous, déjà ramenée à son minimum recommandé.

Deux garde-fous n'ont pas bougé et ne doivent pas bouger :

- **la durée de silence attendue reste à une demi-seconde**, qui est le plancher recommandé par
  le fournisseur. En dessous, un même énoncé se retrouve découpé en deux à chaque respiration ;
- **le petit délai gardé avant le début de parole reste identique** : c'est lui qui évite de
  perdre la première syllabe.

Enfin, **rien de tout cela ne touche la note**. Ce réglage décide du rythme de la conversation,
pas du jugement : la correction se fait après coup, sur le texte de l'échange, par une autre IA
qui ne sait rien de ces paramètres. Les cinq valeurs sont modifiables sans reconstruire
l'application, pour pouvoir en essayer d'autres.

### Si le réseau coupe, l'entretien n'est plus perdu (nouveau)

Le candidat parle **directement** au service vocal depuis son téléphone ou son navigateur ; le
serveur, lui, ne fait que délivrer l'autorisation et recueillir le texte de l'échange. Cette
liaison directe est ce qui rend la conversation fluide — mais elle est fragile : un tunnel de
métro, un ascenseur, une bascule wifi → 4G, l'application passée en arrière-plan quelques
secondes, et elle tombe.

**Ce qui se passait avant.** L'autorisation délivrée au démarrage ne valait **qu'une seule
connexion** et **deux minutes** pour l'ouvrir. Une coupure était donc définitive : l'entretien
s'arrêtait là, sans reprise possible. Et comme la simulation était **déjà décomptée** du forfait
dès les premiers mots prononcés, le candidat perdait à la fois son entretien **et** sa
simulation. Il payait pour quelque chose qu'il n'avait pas pu terminer.

**Ce qui se passe maintenant.** L'entretien peut **reprendre là où il s'est arrêté**. Le service
vocal remet régulièrement une sorte de « marque-page » de la conversation ; l'application la
conserve, et le serveur en garde aussi une copie — ce qui permet de reprendre même si
l'application a été fermée entre-temps. À la reconnexion, le serveur délivre une nouvelle
autorisation qui rouvre **le même entretien**, avec **le même historique**.

Quatre points qui comptent pour le candidat :

- **La simulation n'est jamais décomptée deux fois.** C'est la garantie centrale de ce
  changement : le forfait se débite au premier mot de l'entretien, une fois pour toutes.
  Reprendre après une coupure ne coûte rien de plus, et deux connexions qui se chevaucheraient
  ne peuvent pas non plus provoquer un double décompte.
- **Le texte de l'échange continue, il ne repart pas de zéro** et il ne se duplique pas. Avant,
  quand l'envoi d'un morceau de texte échouait, l'application préférait l'abandonner plutôt que
  de risquer de l'écrire en double ; désormais elle peut le renvoyer sans risque, parce que le
  serveur reconnaît un morceau déjà reçu. Concrètement : moins de phrases perdues dans le texte
  qui sera corrigé.
- **La reprise est bornée** : quelques reprises par entretien, et une fenêtre de reconnexion de
  dix minutes (contre deux avant). Au-delà, il faut recommencer — mais dix minutes couvrent très
  largement les coupures ordinaires.
- **Rien de ceci ne change la correction.** La note, le niveau, les critères et les contrôles
  automatiques sont exactement les mêmes. Un entretien repris est corrigé comme un entretien
  qui n'aurait jamais été interrompu.

En complément, l'échange est désormais protégé contre une limite technique du service vocal :
une conversation audio trop longue finit par saturer sa mémoire. Une « fenêtre glissante » fait
que seule la partie récente de l'échange y reste chargée. Nos entretiens durent deux à trois
minutes, donc la limite n'était pas atteinte de toute façon — mais un entretien **repris**
repart avec un historique déjà constitué, et c'est là que ce filet sert.

---

## 10 bis. Le rapport est écrit en français correctement accentué (nouveau : grille v13)

### Le problème

Sur une évaluation d'expression écrite réellement rendue à un candidat, on lisait :

> « Excuse **formulee** », « Raison de l'absence **expliquee** », « Nouvelle **seance
> proposee** »
> « Le **passe compose** est **maitrise** et **employe a** bon escient (…), ce qui donne un
> **recit** clair de l'incident. »
> « **J'espere** que cette date te convient. »

Les cédilles et les accents circonflexes passaient parfois ; les accents aigus et graves
tombaient presque systématiquement. Pour une plateforme qui **apprend le français**, c'est
inacceptable : on corrige l'orthographe de quelqu'un dans un texte mal orthographié, et on lui
enseigne une faute au moment même où on lui en corrige une.

### La cause la plus probable

Nos propres consignes étaient écrites **sans accents**. Les fichiers de règles envoyés à l'IA
contenaient environ 96 000 lettres et presque aucun accent, là où un texte français normal en
compte environ 3 %. Une IA imite la langue de ce qu'elle lit : on lui montrait un français sans
accents et on s'étonnait qu'elle en produise un.

### Ce qu'on a fait

Deux choses, **dans l'ordre de ce qui marche le mieux** :

1. **Le format de réponse a été réaccentué** (version **v7**). C'est le texte que l'IA lit
   juste avant d'écrire chaque champ, et il contient les phrases d'exemple qu'elle imite.
   Aucune règle n'y a été reformulée : un contrôle automatique compare l'ancienne et la
   nouvelle version **après avoir retiré tous les accents** et exige qu'elles soient
   identiques. Autrement dit : la machine garantit que **seuls des accents ont changé**.
2. **Une règle explicite a été ajoutée aux consignes** (grille **v13**) — une section entière,
   elle-même rédigée dans un français impeccable pour servir de modèle. Elle liste les formes
   les plus souvent fautives (« déjà » et non « deja », « après » et non « apres », « le passé
   composé » et non « le passe compose »…) et rappelle que la règle vise **la forme, jamais la
   note** : elle n'autorise à sanctionner personne sur ses accents.

### L'exception capitale : ce que l'IA **cite** n'est jamais corrigé

Deux champs du rapport reprennent **les mots du candidat** : la phrase « avant » d'un exemple
de correction, et la citation d'origine d'une reformulation. Ces champs se recopient **tels
quels — fautes, accents manquants et maladresses comprises**. Lui montrer une phrase qu'il n'a
pas écrite fausserait la démonstration, et la citation cesserait d'être la sienne. La règle est
écrite en toutes lettres à trois endroits : dans la nouvelle section de la grille, dans la
description du format de réponse, et sur chacun des deux champs concernés.

> **Un bon côté inattendu du changement d'août** : depuis que la preuve d'un critère est un
> **numéro** et non une citation recopiée (§5.5), il n'existe plus, dans le format en vigueur,
> de citation que le serveur vérifie mot à mot. Un accent ajouté par erreur ne peut donc plus
> faire échouer une correction. Ce risque existait avec l'ancien format (v5 et antérieurs) —
> raison de plus pour que l'exception soit écrite noir sur blanc, puisque ces versions restent
> chargeables en cas de retour arrière.

### Un compteur, pas un refus

Le serveur **mesure** désormais le français désaccentué qu'il s'apprête à rendre au candidat :
il cherche, dans les seuls champs que l'IA rédige elle-même, une **liste fermée** de formes qui
n'ont aucune lecture française valable sans accent (« ete », « apres », « deja », « seance »…),
et il écrit le compte dans le journal du serveur.

**Il ne refuse rien, ne modifie rien, ne rejoue rien.** Faire échouer une correction sur un
indice de ce genre coûterait au candidat infiniment plus cher que l'accent manquant qu'on veut
corriger — c'est exactement l'erreur commise avec la vérification des citations littérales,
dont le coût en corrections perdues est resté invisible pendant des mois (§12.3 bis). On
mesure d'abord ; on durcira si la mesure le justifie.

Le détecteur est volontairement **prudent** : en cas de doute, il ne signale rien.
- les mots qui restent français **sans** leur accent (« tache » une salissure, « cote »,
  « a », « ou », « regle ») en sont **exclus** ;
- les mots identiques à un mot anglais courant (« experience », « different ») aussi : un
  rapport peut légitimement en citer un ;
- les champs qui **citent** le candidat ne sont jamais examinés, ni les passages entre
  guillemets à l'intérieur d'un autre champ ;
- les textes ajoutés par le serveur lui-même (libellés de critères, avertissements) non plus :
  ils ne disent rien de ce que rend l'IA.

### Ce qui n'a pas bougé

L'échelle, les quatre critères, les seuils, le garde-fou de couplage, les plafonds, les bandes
affichées, les tests décisifs entre niveaux, les seize exemples de calibration, les consignes
de chacune des six tâches : **rien**. Un test automatique compare v13 et v12 champ par champ et
n'accepte qu'une seule différence — la section ajoutée. C'est ce qui permet de livrer ce
changement **sans campagne de mesure** : aucune règle de notation n'est en jeu.

⚠️ **À dire franchement** : on n'a donc **pas mesuré** combien d'accents sont réellement
revenus. C'est estimé, pas vérifié — d'où le compteur ci-dessus, qui donnera le chiffre sur les
prochaines corrections réelles.

**La même correction a été appliquée aux micro-exercices par compétence** (§11 bis) : consignes
**v2**, format de réponse **v2**, mêmes garanties (accentuation ajoutée, rien d'autre modifié,
citations préservées, compteur en place).

---

## 11. Ce que le candidat reçoit à la fin

Dans cet ordre :

0. **Le verdict de la tâche** (§5.4) : « Objectif : atteint / partiellement atteint / non
   atteint », suivi d'une phrase qui dit ce qu'il a fait.
1. **Ce qu'il a traité et ce qu'il a oublié** (§5.4) — avant toute considération de langue.
2. **La performance observée** sur cette tâche — le niveau (§6.3), la **situation dans ce
   palier** (« A2 solide », §6.3 bis) et la **confiance** (§7). **Pas de note sur 20 sur une
   tâche isolée** (§6.2 bis) : au TCF, une tâche reçoit un niveau, la note porte sur l'épreuve
   entière. La note reste calculée et s'affiche au bilan (§6.5), sans correspondance TCF sur
   une tâche isolée (§6.6).
3. **Les avertissements** éventuels : limite de l'évaluation orale (§9), plafond appliqué
   (§6.4), doute signalé par les vérifications automatiques (§4).
4. **1 à 2 points forts** — ce qu'il a réussi, cité dans sa production (pas des compliments de
   politesse).
5. **1 à 2 points à améliorer** — les priorités, pas une liste décourageante. Chacune avec
   son **constat**, son **« comment »** (la technique à appliquer) et un **exemple avant /
   après** pris dans sa propre production (§5.5).
6-7. 🛑 **Les « suggestions » et les « exemples corrigés » n'existent plus** (§5.7 bis). Ils
   n'étaient affichés que dans le bloc replié « Voir l'analyse complète », qui a disparu de
   l'écran ; depuis les consignes **v15**, l'IA ne les écrit même plus. Les corrections faites
   avant les conservent, et restent lisibles.
8. **Une appréciation par critère** (bande + commentaire + citation), avec le libellé propre à
   la tâche.
9. **Un plan d'action vers le niveau qu'il VISE** (§5.9), produit par un **second appel
   séparé** : deux ou trois leviers sous « Ce qui vous en sépare », puis — **à l'écrit** — sa
   réponse réécrite à ce niveau avec les passages qui font la différence surlignés, ou — **à
   l'oral** — deux ou trois de ses passages redits à ce niveau, sa production n'étant jamais
   réécrite en entier ; enfin une tournure « à retenir ». Remplacé par un encart « Objectif
   atteint » quand le niveau visé est déjà tenu, et absent sans conséquence si ce second appel
   échoue — ou, à l'oral, si la transcription est abîmée.
9 bis. La **version améliorée** du palier juste au-dessus (§5.8) n'existe plus : retirée de
   l'écran, puis **supprimée de la correction** par les consignes v14 — elle était au même
   niveau que la copie, et la recopier ne changeait pas la note. Les corrections faites avant
   la conservent, et restent lisibles.
10. *(Inactif aujourd'hui)* Sur une production orale, un encart **débit et pauses** —
    informations factuelles, hors note. Voir §13.

Les évaluations rendues **avant la v8** (une centaine, déjà en base) ne portent ni verdict ni
version améliorée : rien n'a été recalculé ni réécrit rétroactivement, ces deux blocs ne
s'affichent simplement pas. Symétriquement, celles rendues **avant la v15** portent encore leurs
suggestions et leurs exemples corrigés : ils restent en base, intacts et consultables (la
console de calibration les affiche toujours). On versionne, on ne réécrit pas — y compris les
résultats déjà rendus.

---

## 11 bis. L'autre voie : les micro-exercices par compétence

Tout ce qui précède décrit la correction d'une **tâche complète** du TCF : le candidat rend un
texte entier ou une prise de parole entière, et reçoit une note sur 20, un niveau, quatre
critères, des citations, des priorités. C'est la voie principale, et elle ne change pas.

Il en existe désormais une **seconde**, plus courte, qui ne la remplace pas : l'entraînement
**par compétence**. Les deux cohabitent dans l'application, côte à côte, et un candidat peut
n'utiliser que l'une des deux.

### Ce que le candidat fait

Une tâche du TCF, ce n'est pas une capacité unique : « écrire un message court », c'est en
réalité savoir s'adresser à la bonne personne, annoncer clairement de quoi on parle, donner des
informations précises, formuler une demande poliment… Chacune de ces capacités est appelée ici
une **compétence**.

Chaque tâche en compte **8**, et chaque compétence est travaillée sur **5 petits sujets** —
soit **240 petits sujets** en tout. Un petit sujet tient en quelques phrases : un contexte, une
consigne, et surtout **un seul critère**, affiché **avant** que le candidat commence à écrire ou
à parler. On lui dit donc à l'avance exactement ce qui sera regardé, et rien d'autre ne le sera.

C'est toute la différence avec une tâche complète : au lieu d'être jugé sur tout en même temps,
il travaille **une chose à la fois**, et il sait laquelle.

L'analyse par l'IA n'est d'ailleurs **pas automatique** : le candidat peut très bien produire sa
réponse, la comparer aux exemples, et s'en tenir là. C'est pour cette raison qu'un sujet peut
être marqué « **Fait** » plutôt que « Validé » ou « À renforcer » : sans analyse, il n'y a aucun
verdict — le dire « validé » serait faux, le dire « à renforcer » serait faux **et**
décourageant. Écrire, s'auto-évaluer et lire les exemples de référence est **gratuit et sans
limite** sur tous les sujets ; c'est **l'analyse par l'IA** qui est réservée aux abonnés, avec
**trois analyses offertes** pour essayer.

### Pas de note sur 20 — mais un niveau, désormais

**La règle a changé le 11 août 2026, et seulement à moitié.** Jusque-là, cette voie ne rendait
ni note ni niveau. Aujourd'hui elle rend un **niveau** (A1 non atteint, A1, A2, B1 ou B2), et
continue de ne rendre **aucune note sur 20**. Les deux moitiés méritent chacune leur
explication, parce qu'elles ne reposent pas sur le même raisonnement.

**Pourquoi la note reste exclue.** Une note sur 20 porte, au TCF, sur une **épreuve entière** —
et notre propre note porte au minimum sur une tâche complète (§6.6). Mettre « 8/20 » sur deux
phrases écrites pour travailler *une seule* capacité serait un **chiffre sans support** : il
aurait l'air sérieux sans rien mesurer de solide. Le format de réponse imposé à l'IA **ne
contient donc aucune case** où loger une note. Ce n'est pas une consigne qu'elle pourrait
oublier : il n'y a matériellement pas de champ pour ça.

**Pourquoi le niveau, lui, est rendu.** Parce que c'est la question que le candidat pose. Il
s'entraîne pour une démarche administrative qui exige un palier précis — A2 pour une carte de
séjour, B1 pour une carte de résident, B2 pour la naturalisation — et l'écran de résultat ne lui
disait pas où il en était. Lui répondre « votre critère est validé » sans jamais lui dire à quel
niveau, c'est le laisser sans repère sur la seule chose qui l'intéresse.

Le niveau rendu ici décrit **la langue employée dans cette production-là** : le vocabulaire, la
construction des phrases, les temps, les liens entre les idées. Deux garde-fous encadrent cette
lecture, et ils sont écrits dans les consignes de l'IA :

- **la brièveté ne fait jamais baisser le niveau.** L'exercice est court par construction ; une
  réponse courte, juste et bien tournée démontre ce qu'elle démontre. Il est explicitement
  interdit de réclamer « plus de texte » pour accorder un niveau supérieur. Ce qui borne
  réellement le jugement, c'est la matière disponible : une seule phrase simple ne peut pas
  démontrer un B2 — non parce qu'elle est courte, mais parce que rien n'y montre le B2 ;
- **le niveau est indépendant du verdict.** Un critère peut être **validé en A2** comme **en
  B2** : le verdict dit ce que le candidat a fait, le niveau dit avec quels moyens. À l'inverse,
  un candidat qui écrit bien mais répond à côté aura un critère **non atteint** avec un niveau
  B1. ⚠️ Cette phrase disait, jusqu'au 16 août 2026, que le A2 était « **le cas le plus
  fréquent** » — et cette précision se trouvait aussi, mot pour mot, dans les consignes envoyées
  à l'IA. C'était une **consigne de répartition** déguisée en repère ; elle a été retirée (voir
  juste dessous).

⚠️ **Ce niveau ne remplace pas un résultat d'examen.** Il est établi sur quelques phrases écrites
pour exercer un point précis. Un candidat qui veut savoir où il en est pour de vrai doit passer
une **tâche complète** — c'est elle qui est mesurée (§12), pas celle-ci.

Le progrès continue de se lire aussi autrement : par le **statut de chaque sujet** (« À faire »,
« Fait », « Validé », « À renforcer ») et par le compte de sujets réussis dans une compétence.

### Un niveau annoncé doit se montrer dans la copie

**Changement du 11 août 2026.** Pendant ses premiers jours, ce niveau était simplement
**annoncé** : l'IA lisait la production, lisait cinq lignes de descripteurs, et écrivait « B1 ».
Personne, ensuite, ne vérifiait quoi que ce soit. Sur la voie principale, à l'inverse, le niveau
n'est jamais annoncé à main levée : il **découle** d'une note, elle-même bridée par plusieurs
garde-fous appliqués par notre serveur (§6, §7). Deux nombres portaient donc le nom de la même
échelle sans reposer sur la même exigence.

Depuis, la règle est simple : **si l'IA annonce B1 ou B2, elle doit montrer où.**

Concrètement, la production du candidat ne part plus à l'IA d'un seul bloc : elle lui est servie
**découpée en morceaux numérotés** — une phrase par numéro à l'écrit, une prise de parole par
numéro à l'oral. Quand l'IA annonce B1 ou B2, elle ne recopie rien : elle **donne un numéro**,
celui du passage qui le démontre. Le serveur retrouve ensuite ce passage tout seul.

Ce détail — un numéro plutôt qu'une citation recopiée — n'est pas anodin. Nous avons longtemps
demandé à l'IA de **recopier** le passage qui justifiait son jugement, et de loin le premier
motif de correction perdue était là : une recopie imparfaite (un mot dédoublé, un accent ajouté)
et tout le travail du candidat partait à la poubelle. Sur les productions orales, cela touchait
**plus de quatre corrections sur dix**. Avec un numéro, il n'y a plus rien à recopier, donc plus
rien à rater : inventer un passage devient **matériellement impossible**, et non plus
« interdit ».

**Et si l'IA ne montre rien ?** Le serveur le lui redemande **une fois**, en lui disant
précisément ce qui n'allait pas — quel numéro elle avait donné, quels numéros existent vraiment
dans cette production, et ce qu'il faut chercher pour chaque palier. Si elle ne montre toujours
rien, le serveur **descend le niveau d'un cran** : un B2 non montré devient un B1, un B1 non
montré devient un A2.

Trois choses, ici, comptent autant que la règle elle-même :

- **ce garde-fou ne peut que descendre, jamais monter.** Il n'a qu'un sens, comme tous les
  autres garde-fous du même genre (§7) : au pire, il rend le résultat **prudent**. Il ne peut
  pas fabriquer un niveau que le candidat n'a pas démontré ;
- **il descend d'un cran, une seule fois.** Ce n'est pas une punition : c'est le retrait de ce
  qui n'a pas été montré ;
- **il ne fait jamais perdre l'analyse.** Le candidat garde son verdict, ses deux étiquettes et
  son niveau — simplement un niveau prudent plutôt qu'optimiste. Perdre l'analyse lui coûterait
  sa production et l'un de ses essais ; un cran de niveau ne lui coûte qu'un affichage. Ce choix
  est le même partout dans ce document : mieux vaut un résultat prudent qu'un résultat perdu.

**En dessous du B1, rien n'est exigé.** A2, A1 et « A1 non atteint » ne se lisent pas sur un
passage isolé mais sur l'ensemble de la production. Demander une preuve pour un A2 pousserait
l'IA à désigner un passage au hasard — l'inverse de ce qu'on cherche.

**La brièveté, elle, n'est toujours pas un plafond.** On ne descend pas un niveau parce que la
réponse est courte : on le descend faute de **démonstration**. Une seule phrase qui subordonne,
enchaîne et emploie un mot précis démontre un B1 — un seul passage suffit.

⚠️ **Ce point n'a fait l'objet d'aucune campagne de mesure, et c'est dit sans détour.** Le jeu de
copies qui sert à mesurer la qualité de nos corrections (§12) a été écrit pour les **tâches
complètes** ; il n'existe aucun équivalent pour les micro-exercices. Ce qui tient cette règle,
ce n'est donc pas une mesure : c'est le fait que le format de réponse n'accepte **qu'un entier**
et que le serveur **vérifie ce numéro lui-même**.

### Le niveau ne bougeait jamais — trois biais retirés le 16 août 2026

Le garde-fou décrit ci-dessus empêchait l'IA d'**exagérer** un niveau. Il n'empêchait pas le
défaut inverse, et c'est celui qu'on a constaté en regardant les analyses réellement produites
et stockées dans notre base : sur **18 micro-productions**, **pas un seul B2**, jamais. Pire, le
niveau ne réagissait presque pas à ce qui était écrit — un message truffé de fautes de frappe et
une réponse propre, avec subordonnée et conditionnel, recevaient **le même A2**. Et aucun sujet
refait plusieurs fois n'a jamais donné deux niveaux différents.

En relisant les consignes, trois causes sautaient aux yeux. Elles n'ont rien d'un réglage fin :
ce sont des **biais visibles dans le texte même qu'on envoyait à l'IA**.

1. **Deux paliers n'avaient aucun exemple.** Les consignes contiennent des exemples de
   correction — un petit sujet, une production, l'analyse attendue — qui montrent à l'IA à quoi
   ressemble une bonne réponse. Il y en avait sept : quatre en A2, deux en B1, un en A1.
   **Zéro en B2, zéro en « A1 non atteint ».** L'IA n'avait donc jamais vu à quoi ressemble
   l'un ou l'autre dans ce format d'exercice — difficile, ensuite, de lui reprocher de ne
   jamais les employer. Trois exemples ont été ajoutés : deux B2 (une objection reconnue puis
   dépassée à l'écrit, un argument développé à l'oral) et un « A1 non atteint » (une réponse
   qui n'est pas rédigée en français). Le A2 reste **majoritaire** parmi les exemples : le but
   est que les cinq paliers soient tous montrés, pas que le B2 devienne facile.
2. **Une fréquence attendue était écrite noir sur blanc.** Les consignes disaient : « un critère
   peut être validé en A2 — *c'est même le cas le plus fréquent, et c'est normal* ». L'intention
   était bienveillante, mais la phrase dit à l'IA **quelle réponse donner le plus souvent**.
   L'idée légitime qu'elle portait est conservée (un critère peut parfaitement être validé à un
   palier modeste, le verdict et le niveau sont deux questions différentes) ; la fréquence a
   disparu, remplacée par l'inverse : *aucun palier n'est plus attendu qu'un autre, tu décris
   cette production-ci, pas une moyenne*.
3. **Une étiquette de niveau était posée à côté du texte à évaluer.** Chaque compétence porte un
   palier de référence — une donnée éditoriale du catalogue, pas le niveau de la personne. Ce
   palier était envoyé à l'IA **dans le même bloc d'informations que la production**, et les
   consignes ne lui expliquaient nulle part ce que c'était. Sur les compétences de la première
   tâche, où il vaut « A2 », l'IA n'a jamais rendu autre chose que du A2. C'est exactement le
   piège que tout le reste de ce document s'emploie à éviter (§11 bis, la séparation en deux
   appels ; §12 pour la mesure qui l'a établi côté tâches complètes : annoncer un objectif au
   correcteur fait chuter sa justesse de 81,8 % à 75,6 %). Ce palier **n'est plus envoyé**.

**Rien d'autre n'a bougé.** Les trois verdicts et leur règle de décision, la table des cinq
paliers, l'obligation de montrer un B1 ou un B2, l'interdiction de la note, les limites de
l'oral, les longueurs maximales : tout est repris **mot pour mot**. Le format de réponse
demandé à l'IA est rigoureusement le même qu'avant — aucune case n'est ajoutée ni retirée.

Ce changement a été **livré sans mesure** — le jeu de copies de référence (§12) avait été écrit
pour les **tâches complètes**, et il n'existait aucun équivalent pour les micro-exercices. Ce qui
justifiait de livrer quand même : on ne réglait pas un curseur, on **retirait des biais lisibles
directement dans le texte envoyé à l'IA** — deux paliers jamais montrés, une fréquence attendue
écrite en toutes lettres, une étiquette de niveau posée à côté de la copie.

✅ **Il a été mesuré le jour même**, une fois le jeu de 90 copies de référence écrit : la justesse
du niveau passe de **71,1 % à 82,2 %**, et le nombre de copies de niveaux différents auxquelles
l'IA donnait le même niveau tombe de 74 à 43. Le détail, ainsi que la correction que cette mesure
a apportée à notre propre diagnostic, est plus bas.

### Pourquoi presque tout le monde recevait « A2 », et ce qu'on a changé

En regardant les analyses réellement produites, on a constaté que le module Compétences ne
rendait pour ainsi dire jamais un niveau élevé : sur 18 micro-productions, **pas une seule n'a
été jugée B2**, y compris des productions visiblement meilleures que d'autres qui recevaient
pourtant la même étiquette.

La dernière cause, et la plus tenace, ne tenait pas à ce qu'on demandait au correcteur, mais à ce
que ça lui **coûtait**. Pour annoncer un niveau B1 ou B2, il devait montrer sa preuve : désigner
la phrase précise de la production qui le démontre — et s'il n'y arrivait pas, notre serveur
redescendait son verdict d'un cran. Pour annoncer un A2, il n'avait **rien à montrer** et ne
risquait **rien**. Autrement dit : le niveau bas était la réponse confortable, le niveau élevé la
réponse risquée. Face à ce choix, n'importe quel correcteur — humain ou machine — finit par jouer
la sécurité.

Désormais, **le correcteur désigne toujours la phrase sur laquelle il fonde son verdict**, quel
que soit le niveau : pour dire « A2 », il montre la phrase simple qui fait passer le message,
exactement comme il devait déjà montrer la phrase construite qui démontre un B2. Répondre coûte
donc le même effort en haut et en bas de l'échelle, et il n'y a plus de réponse « gratuite ».

**Ce qui n'a pas changé, et qui compte autant.** La protection contre un niveau élevé annoncé
sans preuve reste **entière** : un B1 ou un B2 non démontré est toujours redescendu d'un cran. En
revanche, un niveau bas mal justifié n'est **jamais** sanctionné — abaisser un « A2 » à « A1 »
parce que le correcteur n'a pas désigné sa phrase reviendrait à punir la prudence, c'est-à-dire à
recréer le problème qu'on vient de corriger. Ces manquements-là sont simplement **comptés**, pour
qu'on sache si la règle est réellement suivie.

Et surtout : **aucune analyse n'est perdue à cause de ça**. Une preuve manquante n'a jamais fait,
et ne fera jamais, échouer une analyse — perdre une analyse coûte au candidat sa production et
son essai gratuit, alors qu'un niveau prudent ne lui coûte qu'une ligne d'affichage. Rien n'a été
retiré de ce que l'écran montre, et la **note sur 20 reste interdite** dans ce module : elle n'y
a toujours aucun champ où se loger.

### Ce que la mesure a donné — et ce qu'elle a corrigé dans notre propre diagnostic

Un jeu de 90 copies de référence propre aux micro-exercices a été écrit le 16 août 2026, puis les
trois versions ont été passées **sur les mêmes copies, le même jour, avec la même IA**. Résultat :

| | avant | étape 1 | **aujourd'hui** |
|---|---|---|---|
| niveau exactement juste | 71,1 % | 82,2 % | **85,6 %** |
| verdict de critère juste | 88,9 % | 87,8 % | **90,0 %** |
| copies B2 reconnues (sur 18) | 8 | 13 | **14** |
| copies A2 reconnues (sur 18) | 13 | 16 | **17** |
| copies confondues entre elles | 74 | 43 | **39** |

Soit **14,5 points de justesse gagnés**, et aucune analyse perdue sur 270 corrections. Le nombre
de copies de niveaux différents auxquelles l'IA donnait le **même** niveau a été divisé par
deux — c'était la plainte d'origine.

Le point important n'est pas que les niveaux montent : c'est qu'ils montent **des deux côtés à la
fois**. Si seules les copies fortes avaient été revalorisées, on aurait simplement rendu l'IA plus
généreuse. Or les copies A2 sont mieux reconnues **en même temps** que les copies B2, et la
moyenne des écarts reste à zéro. L'IA ne note pas plus haut, elle note plus juste.

**La mesure a aussi corrigé notre propre diagnostic, et il faut le dire.** On croyait que l'IA
« plafonnait au A2 », parce que sur 18 productions réelles aucune n'avait jamais été jugée B2.
C'était faux : sur un jeu de copies dont on connaît le niveau, l'ancienne version reconnaissait
déjà des B2. Son vrai défaut était de **tout tasser vers le milieu** — elle distribuait des B1 en
excès, en tirant vers le bas les copies B2 et vers le haut les copies A2. Ce que les 18
productions réelles disaient, ce n'est peut-être pas que l'IA en était incapable, mais simplement
qu'aucune de ces copies n'était B2.

**Ce qui reste à vérifier.** Un compteur interne devait confirmer que le correcteur fournit bien
sa preuve aussi en bas de l'échelle, et non seulement en haut ; il n'est pas encore publié dans le
rapport de mesure. Tant qu'il ne l'est pas, on sait que le résultat s'est amélioré, mais pas avec
certitude que c'est **par le mécanisme** qu'on a voulu corriger.

### Ce que l'IA renvoie : un niveau, un verdict, deux étiquettes

Le retour est volontairement **très court** — l'écran doit se comprendre en trois secondes. Il
tient en quatre éléments, et seulement quatre :

| Élément | Ce que c'est |
|---|---|
| **Le niveau** | Le palier que cette production démontre, de « A1 non atteint » à B2. |
| **Le verdict** | Une phrase qui dit si le critère annoncé est atteint. |
| **Ce qui est réussi** | **Trois mots**, pas une phrase : « Ton adapté », « Idée claire », « Adresse complète ». |
| **L'axe de progrès** | **Trois mots** également : « Plus de précision », « Relier les idées ». |

Les deux étiquettes remplacent les trois pavés de texte que cette voie rendait auparavant (un
point réussi, une priorité d'amélioration, une reformulation). Le motif est simple : sur un
exercice de trois lignes, trois paragraphes de retour, c'est plus long à lire que l'exercice
lui-même. Ce qui manque en explication est repris par le bloc « pour viser », décrit juste
dessous, qui lui donne des exemples concrets.

Leur brièveté n'est pas une consigne mais une **contrainte** : le format de réponse plafonne ces
champs en nombre de caractères, et le serveur recompte les mots derrière. Une « étiquette » de
huit mots est refusée.

Le verdict prend l'une de **trois valeurs**, et rien d'autre :

| Verdict | En clair |
|---|---|
| **Critère validé** | La compétence est là, visible et compréhensible — **même s'il reste des fautes**, tant qu'elles ne bloquent pas la compréhension. |
| **Critère partiellement atteint** | Le candidat a essayé et on voit ce qu'il vise, mais il manque quelque chose : une information, une précision, un développement, un lien logique. |
| **Critère non atteint** | La compétence est absente, la consigne n'est pas traitée, ou la production est trop difficile à comprendre pour qu'on puisse juger. |

Ces trois formulations sont **les mêmes sur le site et dans l'application** : un candidat qui
s'entraîne sur son téléphone puis relit son retour sur ordinateur doit lire le même mot. Le
troisième verdict se dit « non atteint » et non « à retravailler » : cette dernière tournure
ressemblait trop à « À renforcer », qui désigne, lui, l'état d'un **sujet** dans la liste — pas
le résultat d'**une** tentative.

Quatre règles encadrent ce retour, et elles vont toutes dans le même sens — **ne pas noyer le
candidat** :

- **un seul axe de progrès, jamais une liste.** C'est le point le plus important de cette voie.
  Dix remarques sur un exercice de trois lignes, c'est décourageant et ça n'apprend rien ;
- **on n'évalue que le critère annoncé.** Si le critère est « situer le moment et le lieu »,
  l'IA n'a pas à commenter les accords, les accents, le vocabulaire ou la conclusion. Les fautes
  sans rapport avec le critère ne sont pas sanctionnées ;
- **si c'est réussi, on le dit franchement**, sans partir en chasse d'un défaut secondaire pour
  avoir l'air rigoureux. Il est explicitement interdit d'inventer un reproche pour remplir le
  retour ;
- **la longueur n'est pas un critère en soi.** Une réponse très courte qui suffit au critère
  demandé est validée. La longueur ne devient un problème que si elle empêche d'accomplir le
  critère, ou si le sujet l'exigeait explicitement. Les longueurs conseillées affichées à
  l'écran sont des **repères, jamais des barrières** : rien n'est refusé parce que c'est trop
  court ou trop long.

Les mots interdits sont les mêmes qu'ailleurs dans ce document : pas de « très mauvais », pas de
« niveau faible », pas de « vous ne savez pas écrire ».

### « Pour passer au niveau suivant » : une seconde IA, appelée séparément

Une fois le niveau établi, l'écran répond à la question suivante : **que faut-il pour franchir
la marche suivante ?** Cette partie-là est produite par un **deuxième appel à l'IA, totalement
séparé du premier**.

**Pourquoi deux appels au lieu d'un.** C'est le point le plus important de ce montage, et il
repose sur une mesure. Sur la voie principale, on a essayé d'indiquer au correcteur le niveau
visé par le candidat : sa justesse est **tombée de 81,8 % à 75,6 %** de jugements exacts
(§12.4). Un correcteur qui connaît l'objectif aligne son jugement dessus — il devient plus
indulgent avec celui qui vise haut, plus sévère avec celui qui vise bas. La seule façon de
donner un plan d'action **sans abîmer le jugement**, c'est de poser les deux questions à deux
moments différents :

1. **le premier appel juge**, et ne sait rien de l'objectif du candidat. On ne le lui dit pas, et
   ses consignes le lui disent explicitement : « tu ne sais pas quel niveau ce candidat vise, et
   tu n'as pas à le deviner » ;
2. **le second appel conseille**, et reçoit les deux niveaux : celui qui vient d'être constaté et
   celui que la démarche du candidat exige.

C'est exactement le montage déjà en place sur les productions écrites complètes (§5.9), pour la
même raison.

**Quel est l'objectif.** Il est déduit de la **démarche administrative** choisie par le
candidat, jamais d'un réglage isolé : carte de séjour → A2, carte de résident → B1,
naturalisation → B2. Et **la démarche fait plancher** : quelqu'un qui vise la naturalisation tout
en ayant coché « B1 » quelque part se voit proposer le **B2**, parce que c'est ce dont sa
démarche a besoin. Le féliciter d'avoir atteint son objectif à B1 reviendrait à ne jamais le
tirer vers le niveau qui compte pour lui.

**Mais le texte modèle vise UNE marche, pas l'étage entier.** C'est la correction du 16 août
2026, et elle vient d'un cas réel, vérifié en base : un candidat constaté A2 et visant le B2
recevait un texte présenté comme sa « version pour viser le B2 ». Il l'a **recopié tel quel**,
l'a renvoyé comme sa propre réponse — et la correction l'a classé **A2**. Le texte modèle
n'était pas au niveau qu'il annonçait, et rien ne l'y obligeait : sur un micro-exercice de
vingt-huit mots, on ne démontre pas deux paliers d'un coup, et la consigne demandait même de
« garder une longueur proche » de la production du candidat — c'est-à-dire de reproduire son
plafond.

Depuis, le niveau du texte modèle est **le palier juste au-dessus de celui qui vient d'être
constaté, sans jamais dépasser l'objectif** : constaté A2 et objectif B2 → le texte vise le
**B1** ; constaté B1 et objectif B2 → il vise le B2, comme avant. L'objectif du candidat n'est
pas perdu pour autant : il reste ce que la petite jauge à trois crans (juste après) situe, et il
sert de **plafond** à l'ambition d'un exercice. L'intertitre nomme la marche réellement
démontrée — « Pour passer au niveau B1 » — au lieu d'annoncer un palier que le texte n'atteint
pas.

**Ce que ce second appel rend**, en trois blocs et rien d'autre :

| Bloc | Ce que c'est |
|---|---|
| **Deux ou trois leviers** | Chacun est un trio : une **action** en six mots à l'impératif (« Formule ta demande plus poliment »), un **exemple de langue** en cinq mots, recopiable tel quel (« Serait-il possible de… »), et le **procédé de langue** que cette action met en œuvre — pris dans la même liste fermée que les marqueurs du palier ci-dessous. Le procédé ne s'affiche pas : il sert à empêcher un conseil de ton de se faire passer pour un levier de niveau (voir juste après). |
| **L'exemple cible** | **Sa** réponse, réécrite au niveau de la marche suivante — même situation, mêmes faits, mêmes prénoms, et la **longueur que le sujet demande** (plus celle de sa propre réponse, qui est souvent trop courte pour démontrer quoi que ce soit). Deux ou trois passages y sont **surlignés**, chacun avec ce qu'il apporte en trois mots (« plus poli », « plus nuancé »). |
| **Les marqueurs du palier** *(nouveau, août 2026)* | Deux ou trois passages du texte modèle qui **prouvent** le niveau annoncé, chacun étiqueté par le procédé qu'il illustre — registre ajusté, articulation logique, subordination, lexique précis, nuance, objection traitée. Ils ne s'affichent pas : c'est une **contrainte**, pas un contenu. L'IA doit d'abord mettre la matière du palier dans son texte, puis la désigner ; le serveur vérifie que le passage y est vraiment. |
| **À retenir** | Une tournure réutilisable ailleurs (« Serait-il possible de + infinitif ») et, en une phrase courte, quand elle sert. |

**Trois contrôles automatiques, avant que le candidat voie quoi que ce soit :**

- **les passages surlignés sont réellement dans le texte — mais ils ne coûtent qu'eux-mêmes.**
  Le serveur cherche chaque extrait dans l'exemple cible — en ignorant la seule typographie
  (apostrophe droite ou courbe, espace insécable, tiret long), et en affichant ensuite le
  passage **tel qu'il est dans le texte**. S'il ne l'y trouve pas — passage reformulé,
  raccourci, recomposé — **ce passage-là est simplement retiré, et l'exemple cible reste
  affiché**, sans son surlignage. On ne surligne jamais une phrase que l'IA n'a pas écrite, et
  on ne fait plus payer un texte entier pour une aide à la lecture. Seul un **texte** absent ou
  vide fait tomber cette partie. *(Règle du 12 août 2026 : elle **remplace** la précédente — un
  seul extrait introuvable déclenchait une reprise payante puis emportait tout le bloc, leviers
  et tournure à retenir compris, qui ne reposent pourtant sur aucune citation. C'est exactement
  la règle des productions complètes, §5.9 : les deux surfaces, qui portent le même encart,
  partagent désormais le même contrôle.)* ;
- **un levier ne vend jamais un moyen déjà acquis.** « et », « mais », « alors », « après »,
  « aussi », « parce que » sont des moyens du niveau A2 : proposés comme la clé du B1 ou du B2,
  ils sont **retirés**. C'est le même contrôle qu'aux §8 quinquies et §5.9, pour le même défaut
  mesuré : un candidat avait suivi un conseil de ce genre, réécrit sa réponse, et obtenu
  exactement la même évaluation. S'il ne reste plus assez de leviers, une réparation est tentée,
  puis le bloc est abandonné ;
- **le texte modèle tient dans la longueur du sujet.** Le serveur recompte ses mots et refuse
  au-delà du maximum annoncé par l'exercice — au mot près, sans tolérance : un modèle plus long
  que ce que l'exercice accepte n'est plus « sa » réponse. Trop long, une reprise est demandée
  en disant combien de mots retirer ; si elle échoue, **seule cette partie disparaît** et les
  leviers comme la tournure à retenir restent affichés. Un texte plus **court** que le minimum
  conseillé, lui, reste servi : il est encore lisible et utile ;
- **les marqueurs du palier sont vérifiés, mais ne coûtent rien.** Chaque passage désigné doit
  se retrouver dans le texte modèle, et son procédé ne doit pas **sur-vendre** le niveau visé
  (on ne démontre pas l'A2 en « traitant une objection »). Un marqueur qui échoue est
  simplement **retiré** — jamais de reprise payante, jamais de texte perdu. Ce qui tient la
  règle, ce n'est pas ce nettoyage : c'est que le contrat de sortie **exige** ces marqueurs, si
  bien qu'un texte sans matière de palier ne peut plus être produit ;
- **un levier nomme un moyen de langue, jamais un effet de ton** *(nouveau, 16 août 2026)*.
  Cas réel : les trois leviers servis à un candidat pour passer au B2 étaient « Rends ton
  invitation plus chaleureuse », « Propose une alternative concrète », « Termine par une
  formule engageante ». Ce sont de bons conseils de **ton** — mais on peut être très
  chaleureux en A2, et quelqu'un qui les applique à la lettre reste exactement où il est. Le
  contrôle du point précédent ne pouvait rien y voir : il ne reconnaît que six petits mots
  cités, et aucun de ces trois leviers n'en cite un seul. Depuis, **chaque levier doit
  déclarer le procédé de langue qu'il met en œuvre**, dans la même liste fermée que les
  marqueurs du palier : registre ajusté, articulation logique, subordination, lexique précis,
  nuance, objection traitée. Le levier refusé devient alors « Subordonne ta demande à sa
  disponibilité — *si jamais tu es libre* », procédé **subordination**.

  🛑 **Et ce contrôle-là ne retire jamais rien.** Si le procédé manque, n'existe pas, ou
  promet un niveau plus haut que celui qu'on vise, le levier est **affiché quand même**, tel
  quel : c'est le seul bloc dont l'absence viderait entièrement l'écran, et un candidat n'a
  rien à gagner à perdre son plan d'action parce qu'une étiquette invisible était mal
  remplie. L'anomalie est **comptée** — pour savoir si la règle est respectée et pouvoir la
  revoir —, elle ne coûte **aucune reprise payante**, et l'étiquette douteuse n'est pas
  conservée. Ce qui tient réellement la règle, ce n'est pas ce comptage : c'est que le
  formulaire de réponse **oblige** à remplir ce champ, si bien qu'un conseil de ton ne peut
  plus être écrit sans qu'on ait à dire quel moyen de langue le porte ;
- **une seule réparation, jamais deux.** Ce bloc est un confort : payer deux appels
  supplémentaires pour reconstruire une sortie cassée n'en vaut pas le prix.

**Ce bloc peut être absent, et c'est normal.** Trois cas :

- **l'objectif est déjà atteint** — le niveau constaté vaut ou dépasse le niveau visé. Aucun
  appel n'est même émis : montrer une « version B1 » à quelqu'un qui écrit déjà du B2 serait un
  contresens. L'écran affiche alors « Tu as atteint ton objectif » ;
- **on ne sait pas quel niveau il vise** — pas de démarche choisie, pas de palier déclaré ;
- **l'IA n'a pas répondu, ou sa réponse a été refusée** par l'un des contrôles ci-dessus.

Dans les trois cas, **l'analyse reste entière** : le niveau, le verdict et les deux étiquettes
sont là. Le bloc « pour passer au niveau suivant » ne peut jamais faire échouer une analyse déjà
obtenue. Et **une partie de ce bloc peut manquer sans emporter le reste** : si le texte modèle
est inexploitable, les leviers et la tournure à retenir sont affichés quand même — ils ne
dépendent d'aucun texte.

### Où j'en suis : la petite jauge à trois crans

Sous le niveau, l'écran affiche une phrase et une barre. Les deux sont calculées **par le
serveur**, jamais par le site ou l'application — c'est ce qui garantit qu'un candidat lit la même
chose sur son téléphone et sur son ordinateur.

La phrase prend l'une de **trois formes**, et rien d'autre :

| Situation | Ce qui s'affiche |
|---|---|
| Le niveau atteint vaut ou dépasse l'objectif | **Tu as atteint ton objectif** |
| Il manque exactement un palier | **Tu es proche du niveau visé** |
| Il manque deux paliers ou plus | **Encore du chemin vers ton objectif** |

Aucune de ces phrases ne nomme un manque, et c'est délibéré : on a retiré le vocabulaire de
déficit des cartes de résultat (§6.2 bis), on ne le réintroduit pas ici.

La barre compte **trois crans** qui se terminent sur l'objectif : viser le B2 donne « A2 · B1 ·
B2 », viser le B1 donne « A1 · A2 · B1 ». Un niveau situé sous le premier cran place simplement
le curseur au début — la phrase au-dessus dit déjà qu'il reste du chemin, la barre n'a pas
besoin de l'enfoncer.

### Les trois productions de référence, et pourquoi elles arrivent après

Chaque petit sujet est accompagné de **trois réponses écrites à l'avance** par nous — jamais par
l'IA — qui montrent la même consigne traitée à trois degrés :

- une réponse **insuffisante** ;
- une réponse **attendue**, celle qui correspond à ce que le TCF demande ;
- une réponse **très réussie**.

Chacune porte une note pédagogique très courte qui explique **pourquoi** elle est à ce niveau.
Cela fait **720 réponses de référence** pour l'ensemble du module. Elles montrent une cible, pas
un modèle unique à recopier : l'IA a d'ailleurs l'interdiction de comparer mécaniquement la
production du candidat aux mots de ces références. Plusieurs formulations différentes peuvent
être également correctes.

**Elles ne s'affichent qu'une fois que le candidat a produit sa propre réponse.** Ce n'est pas
un détail d'affichage, c'est une garantie tenue par le serveur : tant qu'il n'a rien rendu sur
ce sujet, la demande est refusée, même si quelqu'un essayait de les récupérer autrement.

La raison est pédagogique. Lire une bonne réponse **avant** d'écrire, c'est la recopier sans s'en
rendre compte : on croit avoir appris alors qu'on a imité. En écrivant d'abord, puis en
comparant, le candidat voit **l'écart réel** entre ce qu'il a produit et ce qui était attendu —
et c'est cet écart qui enseigne. Il suffit d'avoir **essayé** : une tentative dont l'analyse a
échoué ouvre quand même les références, parce que c'est précisément le moment où on en a besoin.

### À l'oral, exactement la même limite qu'ailleurs

Les compétences orales se travaillent en s'enregistrant. Ce qui est analysé, c'est la
**transcription automatique** de ce que le candidat a dit — donc **ce qu'il dit, jamais la façon
dont il le prononce**.

L'IA n'a accès ni à la voix, ni à la durée de l'enregistrement, et il lui est **interdit** de
fonder son verdict ou son conseil sur la prononciation, l'accent, l'intonation, le débit,
l'aisance, la fluidité, les pauses, ou sur l'orthographe et la ponctuation d'un texte que le
candidat n'a jamais écrit. Les hésitations que la transcription conserve (« euh », « heu ») ne
sont pas comptées comme des erreurs : elles viennent de l'outil de transcription, pas d'une
faute du candidat.

C'est la même limite, pour les mêmes raisons, que celle expliquée au §9 — et elle est assumée de
la même façon : mieux vaut ne pas juger la prononciation que la juger mal, en pénalisant
systématiquement certains accents.

**Votre enregistrement n'est pas conservé.** Il sert à une seule chose : produire la
transcription, dont le correcteur a besoin pour lire ce que vous avez dit. Une fois cette
transcription faite, l'enregistrement disparaît — il n'est stocké ni sur nos serveurs, ni
ailleurs. C'est pour cette raison que la transcription est faite **à chaque fois**, même
quand vous ne demandez pas d'analyse : sans elle, il ne resterait rien de votre production.

Deux conséquences visibles pour vous. D'abord, l'envoi d'une réponse orale prend quelques
secondes de plus qu'avant : la transcription se fait pendant que vous attendez. Ensuite, les
écrans de résultat ne proposent plus de vous réécouter — ils affichent le texte de ce que
vous avez dit. En revanche, **avant de valider**, vous pouvez toujours réécouter votre prise
et la refaire : à ce moment-là le fichier est encore sur votre appareil, et il n'a été envoyé
nulle part.

Si la transcription échoue (panne du service), rien n'est enregistré et rien ne vous est
décompté : le message vous demande de **renvoyer** votre réponse, pas d'attendre une
correction qui ne viendrait jamais.

### Ce qui n'a pas été mesuré — à dire franchement

**Cette voie n'a pas de banc de mesure.** C'est sa principale faiblesse, et elle est réelle.

Tout le §12 de ce document explique comment la notation sur 20 est vérifiée : un corpus de 48
productions de référence, un niveau attendu écrit à l'avance pour chacune, des campagnes
comparées avant/après à chaque changement de consigne, des chiffres publiés y compris quand ils
sont mauvais. **Rien de tout cela n'existe pour les micro-exercices.**

Concrètement, cela veut dire que :

- **aucun corpus de référence** ne dit ce que « Validé », « Partiellement atteint » ou « Non
  atteint » devrait valoir sur des productions connues d'avance. Personne n'a écrit, pour un
  ensemble de réponses, le verdict qu'un correcteur humain aurait rendu ;
- **aucune campagne n'a mesuré** à quelle fréquence l'IA tombe sur le bon verdict, ni si elle
  penche vers l'indulgence ou vers la sévérité — alors que c'est justement le biais mesuré, et
  documenté, sur la notation des tâches complètes ;
- par conséquent, **une modification des consignes de cette voie serait aujourd'hui un pari**,
  exactement la situation que le banc de mesure a été construit pour supprimer sur l'autre voie
  (§12.1).

Ce qui **est** garanti, en revanche, relève de la forme et non de la justesse : le format de
réponse est strictement contrôlé (les cinq champs, les trois verdicts, les cinq niveaux, aucun
champ imprévu, aucune longueur excessive), une réponse mal formée est renvoyée à l'IA **une
seule fois** pour réparation puis abandonnée plutôt que rendue à moitié, et il est
structurellement impossible qu'une **note** apparaisse. Autrement dit : **on sait que le retour
aura la bonne forme ; on n'a pas encore mesuré qu'il dit juste.**

⚠️ **Cela vaut aussi, et surtout, pour le niveau désormais affiché.** Il est produit par la même
IA, sur le même corpus inexistant : personne n'a vérifié qu'un « A2 » rendu ici correspond à ce
qu'un correcteur humain aurait dit. La bascule qui l'a introduit **n'a été mesurée par aucune
campagne** — le banc du §12 ne note que des tâches complètes, et il n'existe pas de corpus de
micro-productions avec un niveau attendu écrit à l'avance. C'est la raison pour laquelle ce
niveau est présenté au candidat comme un repère d'entraînement, et pourquoi la phrase « passe une
tâche complète pour savoir où tu en es » reste valable.

⚠️ **Cela vaut également pour les deux derniers ajouts au plan d'action** (les marqueurs du
palier, puis le procédé exigé sur chaque levier) : aucune campagne ne les appuie, pour la même
raison. Ce qui les rend malgré tout défendables, c'est leur nature : ils **ajoutent une case
obligatoire au formulaire de réponse** de l'IA — la façon la plus fiable de rendre un
comportement impossible — sans déplacer aucun seuil, aucune note, aucun niveau. On ne règle pas
un curseur au jugé ; on interdit une forme de réponse.

La suite logique est la même que pour l'autre voie, et elle passe par les mêmes outils : faire
annoter de vraies productions de candidats par des enseignants, puis en tirer un corpus de
référence. Tant que ce n'est pas fait, ce module doit être lu comme un **entraînement guidé**,
pas comme un verdict fiable sur une compétence. Un candidat qui veut savoir où il en est doit
passer par une tâche complète.

---

## 12. Comment on sait si l'IA note juste : le banc de mesure

C'est le vrai apport de cette refonte, et le point le plus important de ce document.

### 12.1 Le problème qu'il résout

Avant, **changer une consigne de notation était un pari.** On modifiait le texte donné à
l'IA, on trouvait le résultat « meilleur », et on livrait. Personne ne pouvait dire si la
notation devenait plus juste ou plus fausse.

### 12.2 Ce que c'est

Un **corpus de référence** de **48 productions**, réparties sur les 6 tâches (8 par tâche) :
une « A1 non atteint », une A1, deux A2, deux B1, une B2, et un **piège**. Pour chacune, on a
écrit à l'avance ce qu'une bonne correction devrait dire :

- le **niveau attendu**, et les niveaux **tolérés** (à un palier près) ;
- une **fourchette de note** acceptable sur 20. Depuis la v6, elle n'est plus un jugement
  indépendant : elle se **déduit mécaniquement du niveau attendu** par la table officielle du
  TCF (§6.6). C'est la conséquence directe du fait que notre note s'exprime sur l'échelle du
  TCF — si le niveau est B1, la note ne peut être que dans 6-9. Lors de la bascule, ces fourchettes ont été
  régénérées à partir des niveaux existants ; **les niveaux, tolérances, confiances, pièges et
  productions n'ont pas été touchés.** On ne retouche jamais la référence pour faire passer
  une version — on peut la ré-exprimer sur une autre échelle, jamais l'ajuster ;
- la **confiance** attendue ;
- si les points **obligatoires** de la consigne sont traités, et lesquels manquent ;
- le **piège** éventuel que la production contient.

Les 7 pièges couvrent les cas où une IA se trompe le plus facilement : consigne recopiée pour
faire du volume, texte manifestement généré par une IA, hors-sujet total, candidat quasi
muet, discours appris par cœur, bascule dans une autre langue, et deux transcriptions
volontairement hachées (le piège n° 1 du système — il ne faut surtout pas conclure à
l'incompréhensibilité).

Une **commande unique** rejoue tout le corpus contre l'IA, avec la version de consignes qu'on
veut tester, et produit un rapport. Elle n'est **jamais** lancée automatiquement : elle appelle
un modèle payant. Une campagne complète coûte **91 centimes** avec le correcteur en vigueur
(`deepseek-v4-flash`, grille v9) — c'était 45 centimes avec les grilles plus courtes d'avant
la v9, et cela monte à **4,14 $** avec `gpt-5.4` (§12.6).

### 12.3 Ce qu'il mesure

| Mesure | Ce que ça veut dire |
|---|---|
| **Accord exact** | Part des productions où l'IA annonce **exactement** le bon niveau. |
| **Accord à un palier près** | Part où elle tombe au bon niveau **ou juste à côté**. |
| **Note dans la fourchette** | Part où la note sur 20 tombe dans la zone acceptable. |
| **Écart de sévérité** | De combien de points l'IA s'écarte de la référence, **en moyenne et avec le signe**. Un écart **négatif** veut dire : l'IA note **au-dessus** de la référence, donc elle est **trop indulgente**. |
| **Matrice de confusion** | Qui est confondu avec qui : les A1 pris pour des A2, les A2 pris pour des B1… |
| **Pièges** | Chaque piège est-il évité, et si non, dans quel sens l'IA dérape. |
| **Confiance** | L'IA se déclare-t-elle aussi sûre qu'elle devrait l'être ? |
| **Accomplissement** | Retrouve-t-elle les points de la consigne réellement oubliés ? |
| **Conformité de sortie** | Le modèle a-t-il renvoyé une réponse **exploitable** ? En vrai, chaque réponse inexploitable est une correction en échec pour un utilisateur. |
| **Cas perdus, et leur motif** | Combien de productions n'ont **pas pu être corrigées du tout**, et **pourquoi** : réponse coupée en cours de route, citation refusée, garde-fou de l'oral, fournisseur indisponible. Le taux est affiché **à côté** du taux de sortie invalide, jamais à la place. |
| **Stabilité** | On rejoue le même lot plusieurs fois : la même production reçoit-elle la même note ? |

### 12.3 bis Une mesure qui cachait son propre coût

Il faut le dire, parce que c'est le genre de défaut qui se répète : **le rapport du banc
annonçait « 0 % de sortie invalide » alors qu'environ un tiers des corrections orales se
perdaient.** Les deux affirmations étaient vraies en même temps, et c'est bien le problème.
« Sortie invalide » ne comptait qu'un cas précis — une réponse complète à qui il manque un
champ. Tout le reste — réponse **coupée en plein milieu** parce que la limite de longueur était
atteinte, citation refusée que la réparation n'avait pas réparée, garde-fou de l'oral déclenché
— tombait dans un fourre-tout « erreur d'appel » qui n'était pas mis en avant. **Une métrique
qui rend son propre défaut invisible ne sert à rien.**

Trois corrections en découlent, et la troisième porte sur la méthode :

1. **La limite de longueur de réponse a été relevée** (de 2 000 à 4 000 unités de texte). Elle
   avait été fixée bien avant que le format de réponse n'exige **quatre citations littérales**
   supplémentaires. Mesuré : une correction écrite tient dans ~1 500, une correction orale
   demande 1 800 à 2 000 — donc la limite était atteinte ou frôlée sur **presque toutes** les
   corrections orales. Quand elle est atteinte, la réponse est tronquée en pleine phrase, elle
   devient illisible, et **le candidat ne voit pas sa note**. C'est un plafond, pas une
   consommation : on ne paie que ce qui est réellement produit, le relever ne coûte donc rien
   sur les corrections courtes. La valeur est **identique pour les trois correcteurs possibles**
   et verrouillée par un test.
2. **Le motif de chaque perte est désormais affiché et ventilé**, et le **taux de cas perdus**
   apparaît à côté du taux de sortie invalide, dans le rapport lisible comme dans le fichier de
   résultats. On distingue en particulier ce qui est notre défaut (réponse tronquée, citation
   refusée) de ce qu'on subit (fournisseur indisponible ou qui limite le débit) : sans cette
   séparation, une campagne bridée par le fournisseur se lit à tort comme une régression de
   qualité.
3. **Ce qui a permis à ce trou de s'installer, c'est une exception à la règle de mesure.** La
   contrainte de preuve littérale — chaque critère doit citer un passage réel — a été livrée
   **sans campagne avant/après**, contrairement à toutes les versions de consignes qui l'ont
   précédée, et sans rejouer le témoin de la version précédente le même jour. La contrainte
   elle-même est bonne et n'est **pas remise en cause** : elle empêche une citation inventée
   d'être affichée à un candidat. Mais **son coût en corrections perdues n'avait jamais été
   mesuré**, donc personne ne pouvait le voir. On le laisse écrit ici, corrigé mais pas effacé :
   *une garantie livrée sans mesure de ce qu'elle coûte est une garantie dont on ignore le
   prix.*

### 12.4 Ce que la mesure a montré

**Le diagnostic : l'IA était trop gentille, surtout en bas d'échelle.** On avait empilé des
tolérances — ne pas pénaliser la longueur, ni l'orthographe à l'oral, ni le manque
d'exhaustivité, bénéfice du doute systématique. Chacune était justifiée ; **mises bout à bout,
elles poussaient les notes vers le haut.** C'était une intuition ; la mesure l'a confirmée.

**Avant correction** (consignes v4) :

- l'IA notait en moyenne **1,9 point au-dessus** de la référence ;
- **6 productions A1 sur 8** ressortaient A2 ;
- **5 productions A2 sur 13** ressortaient B1 ;
- seules **38 %** des productions A2 obtenaient une note dans la bonne fourchette ;
- accord exact : **60 %**, notes dans la bonne fourchette : **60 %**.

**Après correction** (consignes v4.1, **résultat répliqué sur deux campagnes**) :

- écart de sévérité ramené à **−1,0** ;
- accord exact : **60 % → 73 %** ;
- notes dans la bonne fourchette : **60 % → 87 %** ;
- productions A2 correctement notées : **38 % → 92-100 %** ;
- productions A2 prises pour du B1 : **5 sur 13 → 2 sur 13**.

Aucune tolérance n'a été supprimée pour obtenir ça. Elles ont été **encadrées** (la règle
« une tolérance lève une sanction, elle n'accorde pas de point », §5.6), et l'ancrage du bas
de l'échelle a été écrit noir sur blanc.

Les **exemples de référence** donnés à l'IA pour se caler ont aussi été enrichis : elle n'en
avait que **3** (tous des écrits, aucun niveau A1, aucun oral) ; elle en a **13** aujourd'hui,
dont un dialogue oral bruité, un cas « A1 non atteint », et plusieurs cas A1/A2 avec la note
attendue explicite — c'est-à-dire des repères exactement là où le risque était le plus grand.
Le haut de l'échelle n'a pas bougé (B2 était déjà bien calé).

**Un défaut technique majeur découvert au passage.** Sous l'ancien format de réponse, le
modèle renvoyait une réponse **inexploitable dans 49 % des cas** (44 appels sur 90). Chaque
cas de ce genre est, en production, **une correction en échec pour l'utilisateur**. Avec le
format actuel, ce taux est de **0 %**. Ce n'est pas un gain de notation, c'est un gain de
fiabilité — et il n'aurait jamais été vu sans le banc.

**La stabilité est bonne.** Le même corpus rejoué **3 fois** : **47 productions sur 48**
gardent exactement le même niveau, et l'écart de note maximal observé sur une même production
est de **2 points** (médiane : 0). La notation n'est donc pas un tirage au sort.

**Deuxième correction : la frontière B1/B2** (consignes **v4.2**, alors actives). Une fois
le bas de l'échelle réparé, le défaut résiduel s'était **déplacé vers le haut** : **3
productions B1 sur 12** ressortaient B2. C'était devenu l'erreur la plus coûteuse du système
(§5.6). La même technique que pour le bas a été appliquée en haut : un **test opposable avec
obligation de citation**, et non des descripteurs « plus précis » — ces derniers n'avaient
rien donné en v4.1 non plus.

Mesure : **3 campagnes v4.2** contre **1 campagne v4.1 relancée le même jour, sur le même
modèle**, pour comparer à conditions égales.

| | v4.1 | v4.2 |
|---|---|---|
| productions B1 correctement classées | **8/12** | **11/12, 10/12, 11/12** |
| productions B2 correctement classées | **6/7** | **7/7, 7/7, 7/7** |
| productions A2 correctement classées | 11/13 | 11/13 ×3 |
| productions A1 correctement classées | 7/8 | 6/8, 7/8, 6/8 |
| accord exact (48 cas) | **75,0 %** | **81,25 % ×3** |
| accord à un niveau près | 85,4 % | **91,7 % ×3** |
| notes dans la bonne fourchette | 83,3 % | 83,3 %, 81,3 %, 83,3 % |
| écart de sévérité (référence − IA) | −1,05 | −0,89, −1,03, −0,89 |
| réponses inexploitables | 0 % | 0 % ×3 |

Ce qu'il faut en retenir, et ce qu'il ne faut pas en conclure :

- le gain sur les **B1** est réel : **+2 à +3 productions** sur 12, dans les trois campagnes.
  Ce n'est pas un cas isolé qui bascule ;
- **rien n'a été écrasé en haut au passage** : les B2 ne sont pas seulement préservés, ils
  sont **meilleurs** (7/7 trois fois, contre 6/7). C'était le risque principal — corriger les
  B1 en renvoyant de vrais B2 en B1 aurait été un échec, pas une réussite ;
- le bas de l'échelle n'a **pas bougé** : A2 identique, A1 à ±1 production, hors-sujet toujours
  à 0/20, transcriptions bruitées toujours correctement traitées. C'est attendu : le plafond
  v4.2 ne s'applique qu'au-dessus de 15/20, il ne peut mécaniquement rien changer plus bas ;
- l'écart de −1,03 d'une des campagnes v4.2 et l'écart de −1,05 de la campagne v4.1 sont **le
  même chiffre à la mesure près** : moins d'un point de note entre deux campagnes, c'est du
  bruit, pas un signal.

**Troisième correction : la refonte de la grille** (consignes **v5**, alors actives). Les deux
premières corrections portaient sur la sévérité ; celle-ci porte sur **ce qu'on mesure**. La
grille sans référence (5 critères à poids variables, accomplissement exclu du niveau) a été
remplacée par notre grille actuelle, alignée sur les dimensions évaluées au TCF (4 critères
égaux, accomplissement compris) — les raisons sont au §5.1.

Mesure : **une campagne v4.2 relancée le même jour, sur le même modèle**, contre la v5. Trois
avertissements avant de lire le tableau, parce qu'ils changent la lecture :

1. **Le fournisseur d'IA local avait changé** entre-temps. Les deux premières campagnes de la
   journée ont tourné par erreur sur un autre modèle, qui classait v4.2 à **41,7 %** au lieu
   des 81,3 % connus. C'est le témoin qui l'a révélé — sans lui, on aurait attribué cet
   effondrement à la v5. **Un témoin rejoué le même jour n'est pas une formalité.**
2. Le fournisseur a **limité le débit** pendant les campagnes v5 : 5 productions sur 48 n'ont
   pas pu être évaluées. Elles comptent comme des échecs dans la colonne « sur 48 » et sont
   exclues de la colonne « sur les cas mesurés ». Les deux lectures sont données.
3. Les **seuils note → niveau ont été recalés** (16 / 13 / 9 au lieu de 15 / 12 / 8) — pas
   pour faire de beaux chiffres, mais parce que **la note ne mesure plus la même chose** :
   elle inclut désormais l'accomplissement, qui tire légitimement la moyenne d'environ un
   point et demi vers le haut. Ils ont été choisis par un rejeu **hors ligne** de la première
   campagne v5 (aucun appel d'IA supplémentaire), puis **confirmés sur une seconde campagne**.

| | v4.2 (témoin, même jour) | v5 |
|---|---|---|
| productions A1 non atteint correctement classées | 4/8 | 4/8 |
| productions **A1** correctement classées | 6/8 | **8/8** |
| productions **A2** correctement classées | 11/13 | **11/13** (11/12 des cas mesurés) |
| productions B1 correctement classées | 11/12 | 9/12 — **9/9 des cas mesurés** |
| productions B2 correctement classées | 7/7 | 6/7 — **6/6 des cas mesurés** |
| accord exact | **81,3 %** (48 cas) | 79,2 % sur 48 · **88,4 % sur les 43 cas mesurés** |
| pièges évités | 7/8 | 5/8 · **5/6 des cas mesurés**, avec exactement le même unique échec |
| réponses inexploitables | 0 % | 0 % |
| écart de sévérité (référence − IA) | −0,91 | −1,23 |

Ce qu'il faut en retenir, et ce qu'il ne faut pas en conclure :

- **le risque principal ne s'est pas matérialisé.** Remettre l'accomplissement dans le niveau
  pouvait re-gonfler le bas de l'échelle — ce que la v4.1 avait précisément corrigé. Il n'en
  est rien : les A1 passent de 6/8 à **8/8**, les A2 restent à 11/13, les productions
  hors-sujet et les transcriptions bruitées sont traitées à l'identique. C'est le garde-fou de
  couplage (§5.2 bis) qui tient cette porte ;
- **aucun palier n'est dégradé** : chaque niveau est égal ou meilleur sur les cas réellement
  mesurés, et le seul piège manqué est le **même** dans les deux versions (une production
  quasi muette classée A1 au lieu de « A1 non atteint ») ;
- l'écart de sévérité passe de −0,91 à −1,23 : **moins d'un point d'écart entre deux
  campagnes, c'est du bruit**, pas un signal ;
- la part de notes tombant dans la fourchette attendue du corpus baisse (83,3 % → 76,7 %).
  **Ce n'est pas une dégradation de qualité mais un changement d'échelle** : les fourchettes
  de notes du corpus ont été écrites pour l'ancienne définition de la note (sans
  l'accomplissement). Le corpus n'a **pas** été retouché — on ne corrige jamais la référence
  pour faire passer une version. Les candidats verront des notes plus hautes qu'avant pour une
  même production ; les **niveaux**, eux, sont plus justes ;
- **ce qui n'est pas mesuré** : la qualité pédagogique des priorités (le « comment »). Le banc
  ne compare que des notes et des niveaux. Elle a été vérifiée à la main sur des productions
  réelles, et elle est garantie par le format de réponse (§5.5), mais elle n'a pas de chiffre.

**Quatrième correction : l'échelle du TCF** (consignes **v6**, alors actives). La v5 avait
adopté les **critères** du vrai examen ; celle-ci adopte son **échelle**, pour supprimer la
dernière contradiction visible à l'écran (« 12,5/20 » et « proche du B1 » sur la même carte,
§6.6).

Mesure : **une campagne v5 rejouée le même jour, sur le même modèle et le même corpus**,
contre la v6. Trois avertissements avant de lire le tableau :

1. **Les fourchettes de notes du corpus ont été régénérées** (§12.2). Elles ne sont plus des
   jugements indépendants : ce sont l'**image mécanique du niveau attendu** par la table
   officielle. Les niveaux attendus, les tolérances, les pièges et les productions n'ont
   **pas** été touchés — la référence est la même, ré-exprimée sur la bonne échelle.
   Conséquence directe : la colonne « note dans la fourchette » **n'est pas comparable** entre
   les deux versions. Les notes de la v5 sont hors fourchette par construction, puisqu'elles
   sont sur une autre échelle. Ce sont les **niveaux** qui se comparent.
2. Le fournisseur a de nouveau **limité le débit** : 5 productions sur 48 perdues côté v5,
   2 sur 48 côté v6. Les deux lectures sont données.
3. Il a fallu **deux itérations** sur la v6 avant d'arriver à ce résultat, et elles sont
   instructives (voir sous le tableau).

| | v5 (témoin, même jour) | **v6** |
|---|---|---|
| productions mesurées | 43/48 | **46/48** |
| **accord exact** | 37/43 — **86,0 %** | 40/46 — **87,0 %** |
| **accord à un palier près** | 38/43 — 88,4 % | 46/46 — **100 %** |
| productions **A1 non atteint** correctement classées | 4/8 | **8/8** |
| productions **A1** correctement classées | **8/8** | 5/8 |
| productions **A2** correctement classées | 11/12 | 11/13 |
| productions **B1** correctement classées | 8/8 | 10/11 |
| productions **B2** correctement classées | 6/7 | **6/6** |
| **pièges évités** | 6/7 mesurés (le quasi-muet échoue) | **8/8** |
| réponses inexploitables | 0 % | 0 % |
| écart de sévérité (référence − IA) | −4,80 (non comparable, cf. avert. 1) | −0,45 |

Ce qu'il faut en retenir :

- **aucune erreur de la v6 ne sort de la zone que la référence elle-même accepte.** C'est le
  chiffre le plus parlant du tableau : 100 % d'accord à un palier près, contre 88,4 %. La v5
  produisait 5 évaluations en dehors de la tolérance annotée ; la v6, aucune ;
- **le point faible historique du banc est réparé.** « A1 non atteint » passe de 4/8 à 8/8.
  C'était la faiblesse écrite noir sur blanc au §12.5 depuis des mois : le serveur ne pose ce
  niveau que si la note vaut exactement 0, et l'IA refusait de mettre 0 à une production qui
  « disait quand même quelque chose ». Sur l'échelle du TCF il n'existe **aucun échelon entre
  0 et 1**, ce que les consignes disent désormais explicitement ;
- **les huit pièges sont évités**, y compris le quasi-muet que la v5 ratait, y compris les
  deux transcriptions bruitées et le hors-sujet à 0 ;
- **la frontière B1/B2 tient** (10/11, et 6/6 en B2) — c'était le risque principal de la
  bascule, puisque le seuil du B2 descend de 16 à 10 ;
- **le seul recul : les productions A1, 8/8 → 5/8**, les trois cas concernés ressortant A2.
  Il faut le dire précisément, parce que c'est moins grave qu'il n'y paraît : (a) la référence
  **tolère explicitement A2** sur ces trois cas ; (b) surtout, **l'IA les jugeait déjà A2 sous
  la v5** — elle notait leur langue 7/20, ce qui est la bande **A2** de l'échelle v5. Si la v5
  affichait quand même « A1 », c'est à cause du décalage entre les bandes de critère et les
  bandes globales de cette version, pas parce qu'elle jugeait mieux. La v6 n'a pas dégradé ce
  jugement : elle a cessé de le masquer.

**Les deux itérations, et ce qu'elles enseignent.** La première version de la v6 classait
correctement 8/8 des « A1 non atteint » mais laissait passer **2 faux B2** : l'IA continuait
d'écrire 13 ou 14 pour un très bon B1, par réflexe de l'ancienne échelle. Les consignes ont
donc reçu une **table de valeurs par palier** et une règle de méthode : *nommer d'abord le
palier, prendre ensuite sa valeur ; un très bon B1 se note 9, jamais 12.* Les faux B2 ont
disparu — mais la formule « tout A1 vaut 1 » a alors fait remonter à 1 des productions qui
valaient 0, **y compris le piège du hors-sujet**. Il a fallu réaffirmer le 0 avec la même
force (« le hors-sujet et le en-deçà du A1 valent 0, et ce 0 prime »). Enseignement général :
**sur une échelle resserrée, chaque borne doit être ancrée explicitement, et renforcer une
borne peut en déplacer une autre.** Seule une campagne complète le montre.

**Cinquième correction : les artefacts de transcription et le déroulé du dialogue** (consignes
**v9**, aujourd'hui **actives**). Motif : l'incident du 6 août 2026 raconté au §8 bis — trois
mots mal transcrits reprochés au candidat dans cinq endroits du rapport. Les deux sections
**orales** des consignes ont été réécrites ; **rien d'autre n'a bougé** — les six grilles par
tâche, les seuils, le garde-fou de couplage, les plafonds, les bandes et les 16 exemples de
calibration sont ceux de la v8, au caractère près, et un test automatique le vérifie. C'est ce
qui rend la mesure lisible : un seul changement à la fois.

Mesure : **une campagne v8 rejouée le même jour, sur le même modèle (DeepSeek
`deepseek-v4-flash`) et le même corpus**, contre la v9.

| | v8 (témoin, même jour) | **v9** |
|---|---|---|
| productions mesurées | 47/48 | **48/48** |
| **accord exact** | 35/47 — **74,5 %** | 39/48 — **81,3 %** |
| **accord à un palier près** | 93,6 % | **97,9 %** |
| **pièges évités** | **4/8** | **8/8** |
| productions **A1 non atteint** correctement classées | 5/8 | **8/8** |
| productions **A1** correctement classées | 3/8 | 3/8 |
| productions **A2** correctement classées | 8/12 | **10/13** |
| productions **B1** correctement classées | 12/12 | 12/12 |
| productions **B2** correctement classées | **7/7** | 6/7 |
| réponses inexploitables | 0 % | 0 % |
| **appels refusés par nos contrôles** | 37,3 % (28 sur 75) | **27,3 %** (18 sur 66) |
| **corrections perdues** | 1/48 — 2,1 % (citation refusée) | **0/48 — 0 %** |
| écart de sévérité (référence − IA) | −0,57 | **−0,38** |
| accord de **confiance** | **53,2 %** | 45,8 % |
| coût de la campagne | 62 centimes | 91 centimes |

Ce qu'il faut en retenir, et ce qu'il ne faut pas y lire :

- **les quatre pièges que la v8 ratait sont tous évités.** Ce sont précisément ceux que la
  nouvelle règle vise : les **deux transcriptions bruitées** (l'une perdue faute de citation
  vérifiable, l'autre classée un palier trop haut), le **texte mémorisé** annoncé B1 au lieu de
  A2, le hors-sujet et la production en langue étrangère. Sur l'oral en interaction (tâche 2),
  l'accord exact passe de **71,4 % à 87,5 %** ;
- **le correcteur se fait nettement moins refuser** : 37,3 % de ses appels étaient rejetés par
  nos contrôles sous la v8, 27,3 % sous la v9. Le seul cas perdu de la v8 l'était pour une
  citation refusée sur une transcription bruitée — exactement la situation où le correcteur est
  invité, désormais, à citer un autre passage plutôt qu'un mot douteux. ⚠️ Contrairement à la
  comparaison de **moteurs** du §12.6, cette comparaison-ci **est** valide : même modèle
  (`deepseek-v4-flash`), même jour, **et même budget de réessais** (jusqu'à 10 côté v8, 9 côté
  v9) — la ligne « corrections perdues » y est donc lisible ;
- **attention à ne pas sur-attribuer.** Les consignes communes sont envoyées pour **toutes** les
  tâches, y compris à l'écrit : le gain visible sur l'écrit tâche 3 (50 % → 75 %) n'a pas de
  cause identifiable dans le changement, et sur douze cas il tient dans le bruit. Ce qui est
  réellement attribuable à la v9, ce sont les résultats **oraux** et les pièges de
  transcription ;
- **deux reculs, dits franchement.** (a) Une production B2 sur sept ressort B1 : c'est le sens
  **prudent** de l'erreur, et sur sept cas ce n'est pas un signal. (b) Plus gênant : l'**accord
  de confiance baisse** (53,2 % → 45,8 %, et le correcteur se déclare « plus sûr que la
  référence » sur 19 cas contre 13). C'est probablement une conséquence directe de la nouvelle
  règle : en apprenant à lire à travers le bruit de transcription, l'IA cesse d'y voir un
  obstacle à l'observation — alors que c'en est un. À surveiller à la prochaine campagne ;
- **le point faible historique n'a pas bougé** : 3 productions A1 sur 8 seulement sont
  correctement classées, les autres ressortant A2. La v9 ne s'y attaquait pas (§12.5) ;
- **le prompt est plus long** : une campagne coûte 91 centimes au lieu de 62. C'est le prix des
  deux sections réécrites, payé sur chaque correction.

**Les seuils se règlent par rejeu hors ligne, jamais à l'intuition.** Les évaluations déjà
jouées conservent la note de chaque critère : on peut donc rejouer le passage note → niveau
avec d'autres seuils **sans un seul appel d'IA supplémentaire**. C'est ainsi qu'a été décidé,
au temps de la v4.1, le passage du seuil A2 de 7 à 8 (accord exact 71,9 % → 76,0 %,
productions A1 correctement classées 62,5 % → 87,5 %, aucune dégradation ailleurs) ; et c'est
ainsi qu'ont été choisis les seuils 16 / 13 / 9 de la v5, puis confirmés sur une campagne
indépendante.

Deux enseignements de ces rejeux, qui valent d'être écrits :

- un seuil n'est **pas** transposable d'une version de grille à l'autre. Monter le seuil B1 à
  13 était le **pire** choix possible sous la v4.2 (les A2 passaient à 100 % mais les B1
  s'effondraient à 33 %) ; c'est le **bon** choix sous la v5, parce que la note n'y mesure
  plus la même chose. C'est pour cette raison que, depuis la v5, **chaque grille déclare ses
  propres seuils dans son fichier** : revenir à la v4.2 remet automatiquement les siens ;
- **arrondir le niveau plutôt que la note dégrade la mesure** (38 → 35 classements exacts sur
  la campagne v5). C'est la note qui garde une décimale, pas le niveau qui s'arrondit.

### 12.5 Ce qui reste faible — à dire franchement

Le banc sert autant à mesurer les progrès qu'à nommer ce qui ne va pas.

- **La confiance annoncée s'est dégradée avec la v9.** Elle n'était déjà juste que dans un cas
  sur deux ; elle tombe à 45,8 %, et l'IA se déclare **plus sûre** qu'elle ne devrait sur 19
  cas. L'explication la plus probable est directe : en apprenant à lire à travers le bruit de
  transcription, elle a cessé d'y voir un obstacle à l'observation — alors que c'en est un. Ce
  n'est pas une régression de **note**, mais c'est une régression, et elle est en tête de liste
  pour la prochaine passe.

- **La frontière A1 / A2 n'a toujours pas bougé.** 3 productions A1 sur 8 seulement sont
  correctement classées ; les autres ressortent A2, dans la zone que la référence tolère. C'est
  le prix de l'échelle officielle (le palier A1 n'y vaut qu'**une** valeur, 1) et aucune des
  versions v6 à v9 ne s'y est attaquée. À trancher avec de vraies productions annotées, pas
  avec huit cas synthétiques.

- **Le filet automatique contre les mots mal transcrits ne couvre qu'un mot à la fois.** Il
  attrape un reproche adossé à **un seul** mot cité de la transcription ; un artefact étalé sur
  plusieurs mots lui échappe, faute de dictionnaire du français (§8 bis). Sur le cas réel qui a
  déclenché tout ceci, il aurait attrapé deux artefacts sur trois. Le troisième repose
  entièrement sur la consigne donnée à l'IA.

- **Les trois corrections du §12.3 bis ne sont toujours mesurées qu'indirectement.** Limite de
  longueur relevée, message de réparation enrichi, hésitations élidées : la campagne v9 montre
  bien **zéro correction perdue** contre 2,1 % pour le témoin v8, mais ce chiffre mesure la
  **nouvelle consigne orale**, pas ces trois corrections-là prises une par une. C'est exactement
  la dette que le §12.3 bis décrit — on la nomme plutôt que de la reproduire.

- **La seconde voie d'évaluation — les micro-exercices par compétence (§11 bis) — n'est pas
  mesurée du tout.** Le banc décrit ici ne couvre **que** la notation des tâches complètes. Il
  n'existe, pour les micro-exercices, **ni corpus de référence, ni campagne, ni chiffre** : rien
  ne dit aujourd'hui à quelle fréquence le verdict « critère validé / partiellement atteint /
  non validé » tombe juste, ni dans quel sens il se trompe. Ce qui y est contrôlé est **la forme**
  de la réponse, pas sa justesse. C'est la même dette que celle décrite au §12.3 bis, sur un
  périmètre neuf — et de loin la plus grosse zone non mesurée du système. Le détail, et ce que
  cela implique pour le candidat, sont écrits au §11 bis.

- **Le garde-fou de cohérence du bilan (§6.5 bis) est hors de portée de ce banc, par
  construction.** Le corpus porte un niveau attendu **par tâche** et **aucune** référence
  de niveau d'épreuve : il ne peut ni confirmer ni infirmer la règle « pas de B2 si la
  tâche 3 est sous B1 ». Elle a donc été activée sur un **raisonnement** (les trois tâches
  ne sont pas interchangeables), pas sur un chiffre — et c'est la seule règle de notation
  livrée dans ce cas. La vérifier demandera de vraies **épreuves complètes** annotées par
  des enseignants, via la console de calibration (§14) ; d'ici là, la règle reste
  réversible d'un seul réglage.

- ~~**Le niveau « A1 non atteint » n'est presque jamais atteint.**~~ **Réglé par la v6**
  (8/8 sur la campagne, contre 4/8 auparavant). La cause était bien celle décrite ici : le
  serveur ne pose « A1 non atteint » que si la note vaut **exactement 0**, et l'IA refusait de
  mettre 0 à une production qui transmettait quand même quelque chose. Sur l'échelle du TCF,
  il n'existe **aucun échelon entre 0 et 1** — le 1 est déjà le A1 — donc tout ce qui est en
  deçà du A1 vaut 0. Les consignes le disent maintenant explicitement, en précisant que ce 0
  **n'accuse pas** le candidat d'être hors-sujet : la différence se lit dans le niveau annoncé
  et dans le commentaire, pas dans le chiffre.
- **Les productions A1 ne sont plus le point faible — c'est confirmé.** Sur les campagnes
  v4.1 telles qu'elles avaient tourné (avec l'ancien seuil), environ **37 %** d'entre elles
  étaient encore mal classées, généralement annoncées A2. Une campagne complète refaite sur
  la configuration réellement livrée (rubriques v4.1 **et** seuil A2 déplacé) le confirme :
  **7 productions A1 sur 8 sont désormais correctement classées**, soit environ 12 % d'erreur.
  Le rejeu hors ligne avait vu juste.
- **La frontière A1/A2 est devenue le point faible.** 3 productions A1 sur 8 ressortent A2
  (§12.4). C'est le prix de l'échelle officielle : le palier A1 y vaut **une seule valeur, 1**,
  sans marge d'hésitation, alors que les paliers voisins en ont quatre. La moindre indulgence
  sur un critère fait changer de palier. Les trois cas concernés sont dans la zone que la
  référence tolère, et l'IA les jugeait déjà ainsi sous la v5, mais c'est là qu'il faudra
  regarder en premier à la prochaine passe — de préférence avec de vraies productions
  annotées, parce que trois cas synthétiques ne suffisent pas à trancher.
- **La frontière B1/B2 est réparée, mais pas refermée.** Elle était le point faible du
  système : 3 productions B1 sur 12 ressortaient B2, ce qui est l'erreur la plus coûteuse
  possible (la naturalisation exige B2 depuis janvier 2026). Les consignes v4.2 ramènent
  l'erreur à **1 ou 2 productions sur 12** selon les campagnes, et la v6 la maintient à ce
  niveau (10/11) malgré un seuil B2 descendu de 16 à 10 — ce qui n'allait pas de soi. Il reste **un cas qui résiste
  systématiquement** : un récit personnel très bien construit — relative, conséquence
  (« tellement… que »), comparaison hypothétique — mais au vocabulaire ordinaire et qui ne
  défend aucun point de vue. Notre référence l'a annoté B1 en le décrivant elle-même comme
  « haut de B1 touchant le B2 » : c'est un cas où deux correcteurs humains pourraient
  légitimement ne pas être d'accord. On ne le compte donc pas comme réglé, mais on ne cherche
  pas non plus à le forcer : durcir encore pour gagner ce cas-là ferait retomber de vrais B2
  en B1, ce qui découragerait à tort des candidats qui ont le niveau exigé.
- **L'IA se croit plus sûre qu'elle ne devrait.** Sur environ un tiers des cas, elle annonce
  une confiance plus élevée que celle attendue. Elle ne se trompe presque jamais dans l'autre
  sens.
- **Le repérage des oublis est perfectible.** Les points de la consigne réellement oubliés ne
  sont retrouvés que dans **un peu moins de la moitié** des cas. En revanche, la question
  « tous les points obligatoires sont-ils traités ? » reçoit la bonne réponse dans plus de
  **85 %** des cas.
- **La qualité pédagogique du feedback n'est pas mesurée.** Le banc compare des notes et des
  niveaux, rien d'autre. Que chaque priorité porte réellement un « comment » utile, que les
  exemples corrigés fassent vraiment gagner un niveau : c'est **imposé par le format de
  réponse et par les consignes**, vérifié par des tests automatiques et à la main sur de
  vraies productions — mais aucun chiffre ne le suit dans le temps. C'est le prochain
  chantier naturel du banc.
- **Le fournisseur d'IA peut changer sous nos pieds.** Deux campagnes d'une même journée ont
  tourné par erreur sur un autre modèle que celui de référence, avec un accord exact deux fois
  plus bas. La leçon est intégrée : **toute campagne comparative fixe explicitement son
  fournisseur**, et le témoin de la version précédente est rejoué le même jour.
- **Et surtout : le corpus est synthétique.** Les 48 productions ont été **écrites à la main**
  pour ce banc. Aucune ne vient d'un utilisateur réel ; aucune n'a été annotée par un
  enseignant de FLE. Les consignes, elles, sont les vraies consignes du projet. C'est une
  **base de départ honnête, pas une vérité de terrain** : un corpus écrit par ceux qui écrivent
  aussi les consignes de notation partage forcément une partie de leurs angles morts. La suite
  prévue : le remplacer et le compléter progressivement par de **vraies productions
  anonymisées, annotées par des enseignants**, avec une double annotation ciblée sur les
  frontières A2 / B1 / B2 — là où la décision compte le plus.

---

### 12.6 Changer de correcteur : trois moteurs mesurés sur le même corpus

Le correcteur est un **réglage**, pas une règle : la même grille v9 peut être lue par
plusieurs moteurs. Trois l'ont été, sur les **mêmes 48 cas**, avec la même grille et le même
format de réponse, 3 corrections en vol :

- **DeepSeek `deepseek-v4-flash`** — le correcteur historique, **en vigueur aujourd'hui** ;
- **OpenAI `gpt-5.4`** — essayé le 2026-08-07, le plus régulier mesuré, et le plus cher ;
- **DeepSeek `deepseek-v4-pro`** — essayé le 2026-08-08.

> 🛑 **Avertissement de lecture, ajouté après coup — à lire avant le tableau.** Ces trois
> campagnes **ne se comparent pas ligne à ligne**. Elles n'ont pas accordé au correcteur le
> même nombre de réessais : jusqu'à **9** pour `flash`, **3** pour `deepseek-v4-pro`, **1**
> pour `gpt-5.4`. Or, en vraie utilisation, un candidat n'a droit qu'à **un seul réessai**
> avant que la correction n'échoue. Toute ligne qui dépend du nombre d'essais — au premier
> chef **« corrections perdues »** — mesure donc le réglage du banc, pas le modèle. La ligne
> honnête, celle qui décrit ce qui arrive à un vrai candidat, est **« appels refusés par nos
> contrôles »** : elle compte les réponses rejetées **rapportées aux appels réellement
> passés**, indépendamment du nombre de vies accordées. Les lignes de justesse (accord,
> paliers, pièges) et de coût, elles, restent comparables.

> ⚠️ **Le fait à retenir, parce qu'il est contre-intuitif.** Sur ce travail précis — corriger
> une production TCF avec citations obligatoires — **le modèle nommé « pro » coûte plus cher
> que celui nommé « flash »** (1,12 $ contre 0,91 $ la campagne) **sans mieux noter** (pièges
> 4/8 contre 8/8, B2 3/7 contre 6/7). Le nom commercial d'un modèle renseigne sur sa taille,
> **pas** sur son prix relatif ni sur son aptitude à une tâche donnée. Quiconque voudrait
> « remettre le bon modèle » doit **refaire la mesure d'abord**.

| Ce qu'on mesure | **`deepseek-v4-flash`** (en vigueur) | `gpt-5.4` | `deepseek-v4-pro` |
|---|---|---|---|
| ~~Corrections rendues / perdues~~ | ⚠️ **NON COMPARABLE** — réessais accordés : 9 | ⚠️ réessais : 1 | ⚠️ réessais : 3 |
| **Appels refusés par nos contrôles** *(la ligne qui décrit ce qu'un candidat subit)* | 27,3 % (18 appels sur 66) | **0 %** (0 sur 48) | 17,9 % (10 sur 56) |
| …dont sur les seules productions **orales** | 42,9 % | **0 %** | 31,2 % |
| …sur les productions **écrites** | **0 %** | **0 %** | **0 %** |
| Accord exact (sur les corrections rendues) | 81,3 % | 81,3 % | 82,2 % |
| Accord exact (sur les 48 cas, les perdues comptées ratées) | **81,3 %** | **81,3 %** | 77,1 % |
| Accord à un palier près | **97,9 %** | **97,9 %** | 93,3 % |
| Écart moyen (référence − IA) | −0,38 | **−0,19** | +0,50 (trop sévère) |
| **A1 non atteint** (8 cas) | 8/8 | 8/8 | 8/8 |
| A1 (8 cas) | 3/8 | 2/8 | **4/8** |
| A2 (13 cas) | 10/13 | 11/13 | **12/13** |
| B1 (12 cas) | **12/12** | **12/12** | 10/12 |
| **B2** (7 cas) | **6/7** | **6/7** | 3/7 |
| **Pièges évités** (8 cas) | **8/8** | 5/8 | 4/8 |
| Cas ayant exigé un réessai | 7 | **0** | 4 |
| Attente médiane par correction | 16,6 s | **12,9 s** | 29,5 s |
| Attente **maximale** observée (cumul des réessais) | 5 min 44 s | **32 s** | 3 min 03 s |
| Accord sur la confiance annoncée | 45,8 % | **54,2 %** | 53,3 % |
| **Coût de la campagne** (48 corrections) | **0,91 $** | 4,14 $ | 1,12 $ |

**Une conclusion a dû être retirée.** Ce paragraphe disait, dans une version précédente de ce
document, que `deepseek-v4-pro` « perdait 3 corrections sur 48 là où `flash` n'en perdait
aucune ». **C'était faux, et c'est important de le dire plutôt que de l'effacer en silence.**
Une vérification ultérieure a montré que `flash` avait tourné avec **neuf** tentatives
autorisées par cas (un cas en a consommé neuf), `pro` avec trois, `gpt-5.4` avec une. Un
modèle à qui l'on accorde neuf essais finit évidemment par rendre quelque chose. La différence
mesurait donc le **réglage du banc**, pas les modèles. En vraie utilisation, il n'y a **qu'un
seul réessai**.

**La bonne façon de poser la question : combien d'appels sont refusés ?** Cette mesure-là ne
dépend pas du nombre de vies accordées, et c'est elle qui prédit ce qu'un candidat vivra.

| | `flash` | `gpt-5.4` | `pro` |
|---|---|---|---|
| appels refusés, tous cas | 27,3 % | **0 %** | 17,9 % |
| appels refusés, **productions orales** | **42,9 %** | **0 %** | 31,2 % |
| appels refusés, productions écrites | 0 % | 0 % | 0 % |

Deux enseignements. D'abord, **le problème est entièrement oral** : à l'écrit, les trois
moteurs passent nos contrôles du premier coup, systématiquement. Ensuite, **`flash` est le
moteur qui se fait le plus refuser** — près d'un appel oral sur deux. Ce que refusent nos
contrôles, ce sont deux choses précises : une citation qui ne se retrouve pas mot pour mot
dans la production du candidat, et un conseil fondé sur un élément qu'on s'interdit de juger
à l'oral (accent, débit, hésitations). Ce ne sont **pas** des réponses illisibles : le défaut
qui avait détruit une tâche d'examen réelle le 2026-08-06 — une réponse **tronquée ou
corrompue** — n'est réapparu sur **aucune** des trois campagnes.

**Ce que `deepseek-v4-pro` fait mieux, et moins bien.** Mieux : il se fait moins refuser
(17,9 % contre 27,3 %) et il est le meilleur des trois sur le **bas de l'échelle** — A1 4/8,
le meilleur score jamais obtenu sur ce palier fragile, et A2 12/13. Moins bien : il **rate la
moitié des cas-pièges** (4/8 contre 8/8) — les cas construits exprès pour tromper : hors-sujet
bien écrit, texte appris par cœur, transcription bruitée, réponse dans une autre langue — et
il **reconnaît mal les très bons candidats** (3 B2 sur 7, contre 6/7 pour les deux autres).
Ses erreurs vont dans le sens **sévère** (écart global +0,50, le seul positif des trois) : il
sous-note plutôt qu'il ne flatte, ce qui est le sens d'erreur le moins dangereux — mais
annoncer B1 à quatre candidats sur sept qui valent B2 reste une erreur. Et il **coûte 23 % de
plus** que `flash`.

**Une pointe d'attente à lire correctement.** Les 5 min 44 s de `flash` ne sont **pas** une
correction qui a mis cinq minutes à s'écrire : c'est **neuf appels enchaînés** sur la même
production, à cause des refus ci-dessus. Pris isolément, un appel de `flash` prend 16,3 s en
médiane et **36 s au pire** — mesuré sur les 41 cas réglés en un seul appel. C'est ce
chiffre-là, et pas la pointe, qui dimensionne le délai d'attente côté serveur (90 s, soit
2,5 fois le pire appel observé).

**La décision est prise — `deepseek-v4-flash` est retenu (2026-08-16).** Le réexamen ouvert
après les campagnes des 7 et 8 août est **clos**, et le motif décisif est la **rapidité de
réponse** : pris appel par appel, `flash` répond en **16,3 s** en médiane et **36 s** au pire,
contre **28,8 s** et **66,7 s** pour `deepseek-v4-pro`. Sur un écran où le candidat attend sa
correction, c'est le seul écart qu'il ressent vraiment ; une minute d'attente supplémentaire
n'est pas un détail d'exploitation.

Deux constats l'ont emporté sur les arguments contraires :

- **la justesse ne se gagne pas en changeant de moteur.** Elle s'est gagnée dans les
  **contrats de sortie et les contrôles automatiques** : la campagne du 2026-08-16 a fait
  monter l'accord exact de **14,5 points sans changer une seule ligne de modèle**. Payer 4,5
  fois plus cher pour un moteur qui note *aussi juste* (81,3 % des deux côtés, pas mieux)
  n'achèterait donc pas de la précision ;
- **le seul vrai défaut de `flash` — 42,9 % d'appels refusés à l'oral — est un défaut de nos
  contrôles autant que du moteur**, et c'est de ce côté-là qu'il se traite (désignation de la
  preuve par numéro, filtres serveur), pas en changeant de fournisseur.

Ce qui reste vrai et joue aussi dans ce sens : `flash` est **le moins cher** et **le plus
fiable sur les cas-pièges** (8/8). Les blocs OpenAI et Anthropic restent complets et testés :
la décision est réversible en trois lignes de configuration, elle n'est pas définitive.

**Revenir en arrière** ne demande ni migration ni recompilation : quelques lignes dans le
fichier d'environnement (le fournisseur, le modèle, ses tarifs), un redémarrage. Les blocs
OpenAI et Anthropic restent complets et testés.

**Changer de modèle ne demande plus de toucher au code.** Chaque fournisseur a ses petites
manies : les uns veulent que la longueur maximale de réponse s'appelle `max_tokens`, les
autres `max_completion_tokens` ; certains modèles refusent qu'on leur impose une notation
déterministe. Avant, ces différences étaient écrites dans le programme : brancher un modèle
nouveau demandait une modification et une recompilation. Désormais, **c'est le fournisseur
lui-même qui nous le dit** — il renvoie un message d'erreur explicite, qui nomme souvent le
réglage de remplacement — et le programme **corrige sa demande, réessaie une fois, et retient
la bonne forme** jusqu'au redémarrage suivant.

Le **tarif** suivait la même logique à l'envers : il vivait dans une liste écrite dans le
code, si bien que le premier modèle absent de cette liste faisait échouer la construction du
projet alors que rien n'était cassé. Il se déclare désormais **à côté du modèle, dans le même
fichier d'environnement** : si le modèle se choisit là, son prix aussi. Ce qui reste
verrouillé, c'est la **cohérence** — choisir un modèle sans poser ses tarifs fait échouer
la construction, parce que le coût d'une correction est enregistré en base et qu'un tarif faux
y resterait faux pour toujours. Ce qui n'est plus verrouillé, c'est le **choix** : aucun test
ne dit plus quel moteur doit être utilisé.

> ⚠️ **Un modèle qui impose sa propre température** (mesuré sur `gpt-5.5`) rend la notation
> **non déterministe** : la même production peut ressortir avec une note légèrement
> différente d'un jour à l'autre. Le programme s'y adapte sans planter, mais c'est un choix
> à faire en connaissance de cause, pas par accident. `deepseek-v4-flash`, `deepseek-v4-pro`,
> `gpt-5.4`, `gpt-5.4-mini`, `gpt-5.2`, `gpt-4.1` et `gpt-4o-mini` acceptent tous la notation
> déterministe.

### 12.6 bis Ce que coûte vraiment une correction (grille du 2026-08-16)

Cette section existe pour une raison simple : **les chiffres de coût affichés jusqu'ici étaient
faux**, dans les deux sens, et il vaut mieux le dire que le corriger en silence.

**Ce qui a changé chez le fournisseur.** Le 16 août 2026 à 16 h (heure de Londres), DeepSeek a
publié une nouvelle grille de prix. Elle n'est plus faite de deux nombres mais de **trois**, et
elle **double** à certaines heures de la journée. Les prix ci-dessous s'entendent en dollars
pour un million de « jetons » — l'unité de facturation des IA de texte, à peu près trois quarts
de mot en français.

| | entrée **déjà connue** de l'IA | entrée **nouvelle** | réponse produite |
|---|---|---|---|
| **heures creuses** | **0,007 $** | **0,22 $** | **0,66 $** |
| heures pleines (1 h-4 h et 6 h-10 h, heure de Londres) | 0,014 $ | 0,44 $ | 1,32 $ |

**« Entrée déjà connue », c'est quoi ?** À chaque correction, on renvoie au correcteur la même
grille d'évaluation — un document de plusieurs dizaines de pages, rigoureusement identique d'une
copie à l'autre. Le fournisseur s'en aperçoit, la garde en mémoire quelques heures, et la
facture **31 fois moins cher** la fois d'après. Ce n'est pas une astuce à mettre en place : il
le fait tout seul, et il **nous dit** dans sa réponse quelle part de l'envoi a été reconnue.
Nous ne le lisions pas ; nous le lisons désormais, et nous l'enregistrons — c'est la seule façon
de savoir quelle part de nos envois profite réellement de cette remise.

**Nos anciens chiffres, et de combien ils se trompaient.** La configuration portait encore
0,14 $ en entrée et 0,28 $ en réponse. Autrement dit :

- la **réponse** était sous-estimée de 2,4 à 4,7 fois ;
- l'**entrée nouvelle** de 1,6 à 3,1 fois ;
- l'**entrée déjà connue**, elle, était **sur**estimée d'un facteur 20.

**Et un défaut d'arrondi, plus grossier encore.** Le coût de chaque appel était arrondi **au
centime supérieur** avant d'être enregistré. Une correction coûte quelques millièmes de
centime : elle laissait donc « 1 centime » en base, soit **environ huit fois son prix**. Sur une
campagne de mesure de 90 corrections, la base indiquait 90 centimes pour 9,9 centimes réellement
dépensés. Le coût est désormais conservé au **millionième de dollar** — assez fin pour que la
plus petite correction du site en vaille encore près de deux mille, et assez précis pour que
deux appels s'additionnent sans gonfler.

**Ce que ça donne sur une correction réelle**, en moyenne sur les corrections déjà enregistrées
(EE : 16 200 jetons envoyés, 1 150 produits ; EO : 10 200 et 1 290) :

| | ancienne grille, prix réel | nouvelle grille, **sans** remise | nouvelle grille, **avec** remise |
|---|---|---|---|
| une expression **écrite** | 0,0026 $ | **0,0043 $** | ≈ 0,0014 $ |
| une expression **orale** | 0,0018 $ | **0,0031 $** | ≈ 0,0011 $ |

Aux heures pleines, il faut doubler la colonne du milieu. Autrement dit : **une correction coûte
entre un dixième et un demi-centime**, et la remise de mémoire, quand elle joue, la ramène
au-dessous de l'ancien prix — c'est même le seul levier de coût qui reste, une fois la grille
subie.

**Ce que ça ne change pas.** Ni la note, ni le niveau, ni un seuil, ni une consigne donnée au
correcteur. C'est de la comptabilité, pas de la notation. Et **rien n'a été réécrit dans le
passé** : les corrections déjà enregistrées gardent le montant calculé à leur époque, avec les
tarifs et l'arrondi de leur époque. Recalculer ces montants aujourd'hui reviendrait à inventer
un prix qu'on n'a jamais payé — le prix du jour n'a jamais été conservé à côté du décompte de
jetons.


## 13. Deux réglages **préparés mais éteints** (aucun effet aujourd'hui)

Ces deux comportements sont écrits, testés et livrés, mais **désactivés**. Tant qu'ils ne
sont pas allumés, **rien de ce qui suit ne se produit** : la notation décrite dans tout le
reste de ce document reste, mot pour mot, celle qui s'applique. Ils s'allument un par un,
après mesure au banc, en changeant une seule ligne de configuration.

| Réglage | Ce qu'il ferait une fois allumé |
|---|---|
| **Débit et pauses** | Afficher, sous une production **orale**, deux mesures **factuelles** : le **débit** (mots par minute) et — seulement si la transcription porte des repères de temps — le **nombre de silences longs**. Ce sont des **informations**, jamais une note. |
| **Seconde lecture en cas de doute** | Faire **recorriger** la production par une **seconde IA**, uniquement quand la première est peu sûre d'elle (confiance faible, note juste à la frontière d'un niveau, ou désaccord marqué entre l'IA et le calcul du serveur). En cas de désaccord entre les deux, on retient la correction **la plus basse** — le biais mesuré est vers l'indulgence — et on **baisse la confiance affichée**. |

> Un troisième réglage figurait ici jusqu'à présent : la **cohérence du bilan** (pas de B2
> quand la tâche 3 est sous B1). Il est désormais **actif** — voir le §6.5 bis, qui
> explique aussi pourquoi il a été allumé **sans mesure au banc**, celui-ci n'ayant aucune
> référence de niveau d'épreuve.

Trois précisions qui comptent :

- **Le débit ne deviendrait pas un critère de note, même allumé.** C'est une mesure affichée à
  côté de la correction, avec la mention « ces mesures n'entrent pas dans votre note ni dans
  votre niveau ». Aucun calcul de note ou de niveau ne lit ce bloc. Elle a été retenue parce
  qu'elle est **neutre vis-à-vis de l'accent** : compter des mots par minute ne favorise
  aucune langue maternelle, contrairement à une analyse de prononciation. L'allumer nuancerait
  la règle « on ne juge ni le débit ni la durée » du §8 : on **mesurerait** le débit, sans le
  **noter**.
- **La seconde lecture réutilise le correcteur configuré.** Il n'existe plus de provider ou
  de modèle séparé pour cette voie : async, fin de session temps réel, seconde passe et banc
  de mesure lisent tous `sejourfr.production-evaluation`. Cette contrainte rend une bascule
  reproductible et évite qu'une voie secondaire note sur un autre modèle à l'insu du projet.
- **La seconde lecture retient une correction entière**, jamais un mélange : on ne colle pas
  la note d'une passe sur les commentaires de l'autre.

---

## 14. Une console pour comparer l'IA à un correcteur humain

Le banc de mesure (§12) tourne sur un corpus écrit à la main. Pour le compléter par de vraies
productions, il existe un **écran d'administration** dédié.

Un correcteur humain y ouvre une production réellement rendue par un utilisateur, l'écoute ou
la lit, et pose sa propre note sur 20 et son propre niveau CECRL. L'écran affiche alors, sur
l'ensemble des productions annotées :

- le **biais** — l'IA se trompe-t-elle plutôt **vers le haut** (trop indulgente) ou vers le
  bas ? C'est la moyenne des écarts, avec leur signe ;
- la **dispersion** — de **combien** se trompe-t-elle, en moyenne et en amplitude ? Une IA qui
  se trompe de 0,5 point à chaque fois n'a pas le même problème qu'une IA juste en moyenne
  mais qui se trompe de 5 points dans les deux sens ;
- la part de productions dont l'écart dépasse **3 points**, considérés comme « hors cible » ;
- un verdict simple « calibré / non calibré » : moins de 1,5 point d'écart moyen **et** moins
  de 5 % de productions hors cible.

Une production réannotée plusieurs fois ne compte qu'**une seule fois** (sa dernière note) :
sans ce garde-fou, la mesure censée dire si l'IA note juste se biaisait elle-même.

**C'est cette console qui fera grossir le corpus réel** et permettra, à terme, de remplacer
les productions synthétiques du banc par de vraies copies annotées.

---

## 15. Où sont réglées ces règles (pour ceux qui veulent aller voir)

Toutes les instructions données à l'IA vivent dans des **fichiers de texte** (pas cachées dans
le code) — on peut donc les faire évoluer sans être développeur, en touchant le bon fichier :

| Ce qu'on veut changer | Fichier |
|-----------------------|---------|
| **Toutes les consignes de notation** (nos 4 critères et leurs poids, descripteurs et consignes par tâche, barème, ancrage du bas **et du haut** de l'échelle, garde-fou de couplage, règles obligatoires/pistes, tolérances, exemples de calibration, **et tout ce qui se lit sur une note** : seuils note → niveau, écart du garde-fou, seuils des plafonds, bornes des bandes affichées) **et toutes les consignes de restitution** (confiance, anti-répétition, levier de progression, verdict, plafonds d'affichage) | `backend_sejourfr/src/main/resources/prompts/production-rubrics-v15.json` (version **active**, profil `TCF_IRN`, maximum B2 — **c'est la v14 au caractère près pour tout ce qui note ; elle ne fait que retirer les consignes décrivant les « exemples corrigés » et les « suggestions », supprimés du rapport**, §5.7 bis). `v14` (retrait de la version améliorée, §5.8), `v13` (accentuation, §10 bis), `v12`, `v9`, `v8`, `v7` et les versions antérieures restent en place et chargeables. ⚠️ **`v10` et `v11` existent aussi, et sont écartées** : elles ajoutaient une consigne sur la langue étrangère à l'oral et ont été **mesurées moins bonnes que v9** (§8 quater) — les activer ferait revenir ces chiffres. Un rollback change la **paire compatible** `EVAL_RUBRICS_VERSION` + `EVAL_PROMPT_VERSION` (v15/v9 → v14/v8 → v13/v7 → v12/v6 → v9/v5 → v8/v5 → v7/v4), jamais un seul côté du contrat. ⚠️ **v12, v13, v14 et v15 sont les seules versions dont la notation n'a pas été mesurée au banc** — parce qu'elle ne la change pas : elle est la v9 au caractère près pour tout ce qui note (verrouillé par un test qui compare les deux fichiers), et ne modifie que **deux choses de forme** : la façon dont l'IA désigne sa preuve (§5.5), et le fait qu'elle ne **recopie plus** les bornes de mots des tâches EE — elle renvoie à celles qui lui sont injectées depuis la base (§2). Retour à la recopie littérale : `EVAL_RUBRICS_VERSION=v9` + `EVAL_PROMPT_VERSION=v5`, sans migration — ⚠️ **ce retour arrière réintroduit la contradiction sur les bornes de mots** (grille à 60-90, base à 40-90, §2). |
| **Le format de réponse de l'IA** (note, confiance, accomplissement **et son verdict**, preuves, points forts, priorités…) | `backend_sejourfr/src/main/resources/prompts/production-evaluation-tool-schema-v9.json` (version active — **v8 privée des deux cases `exemples_corriges` et `suggestions` ; un test exige l'égalité stricte de tout le reste**, §5.7 bis ; `v8` = v7 privée de `version_amelioree`, §5.8 ; `v7` = v6 réaccentuée, §10 bis) ; structure figée depuis v6 : structure complète, quatre critères exacts, niveaux limités à B2, aucun champ imprévu, au plus 2 points forts et 2 priorités). **La seule différence avec la v5** : la preuve d'un critère y est un **numéro de morceau** (un entier), plus une citation recopiée — c'est ce qui rend une preuve inventée impossible plutôt que simplement interdite (§5.5). La v5 reste en place et chargeable. |
| **Le découpage de la production en morceaux numérotés** (une prise de parole du candidat à l'oral, une phrase à l'écrit) et sa **résolution en texte** avant affichage | `backend_sejourfr/src/main/java/com/sejourfr/app/service/EvaluationProductionSegments.java`. Le découpage est **le même** pour ce qui est envoyé à l'IA, pour la vérification du numéro et pour le texte affiché — un seul point de vérité, comme pour le recollage des phrases coupées (§3.1) |
| **Le correcteur utilisé partout** (async, fin de session temps réel, réparation, seconde passe, calibration) | Le **fichier d'environnement** (`.env`), pas le code : `EVAL_LLM_PROVIDER` et `EVAL_<FOURNISSEUR>_MODEL`. `application.yaml` ne porte que les **défauts** — aujourd'hui **DeepSeek / `deepseek-v4-flash`**, et **pas** son homonyme « pro », plus cher sans mieux noter. ✅ **Choix arbitré et clos le 2026-08-16, motif rapidité** (§12.6). Les blocs OpenAI (`gpt-5.4`) et Anthropic restent complets et testés : basculer, c'est décommenter un bloc de trois lignes. Gemini reste l'examinateur vocal/transcripteur, jamais le correcteur. |
| **La façon dont on parle à un fournisseur** (nom du réglage de longueur maximale, envoi ou non d'une température) | Personne ne l'écrit : elle est **négociée avec le fournisseur** au premier appel, à partir de ses messages d'erreur, puis retenue jusqu'au redémarrage (`backend_sejourfr/src/main/java/com/sejourfr/app/util/ChatCompletionDialectNegotiator.java`). Deux clés d'environnement par fournisseur permettent de reprendre la main sans code si besoin : `EVAL_<FOURNISSEUR>_MAX_TOKENS_PARAM` et `EVAL_<FOURNISSEUR>_SEND_TEMPERATURE` |
| **Le tarif du modèle** (le coût d'une correction est enregistré en base : un tarif faux y reste faux) | Le **même fichier d'environnement que le modèle** : `EVAL_<FOURNISSEUR>_COST_INPUT` / `..._COST_OUTPUT`, plus le **facultatif** `..._COST_CACHED_INPUT` (défauts dans `application.yaml`). C'est délibéré : le prix doit voyager avec le modèle. Un test **fait échouer la construction du projet** si un modèle est choisi sans ses deux tarifs obligatoires — mais il ne dit plus « tel modèle vaut tel prix », sinon essayer un modèle nouveau redeviendrait une modification de code. Le tarif de cache et les heures pleines restent **optionnels**, avec des valeurs neutres, pour qu'un modèle inédit se branche sans eux (cf. §12.6 bis) |
| **Le comportement de l'examinateur vocal** (ton, cadre, interdiction d'orienter le candidat, ouverture T1/T2, façon de rendre la fiche de scénario T2, **verrou de langue** §10) | `backend_sejourfr/src/main/resources/prompts/realtime-personas-v3.json` (version active ; v2 — sans verrou de langue — et v1 — sans fiche de scénario — restent disponibles en repli) |
| **Les faits d'un jeu de rôle T2** (prix, délais, horaires, attitude du personnage) | colonne `agent_role_card` du sujet, en base — renseignée par les migrations `db/migration/300_tcf/production/eo/tache_2/` |
| **Les seuils de niveau, les plafonds, les vérifications automatiques, les deux réglages éteints** | `backend_sejourfr/src/main/resources/application.yaml`, section `sejourfr.production-evaluation` |
| **Le garde-fou de cohérence du bilan** (§6.5 bis — pas de B2 si la tâche 3 est sous B1) | `backend_sejourfr/src/main/resources/application.yaml`, `sejourfr.production-evaluation.coherence-bilan` — livré **actif**, contrairement aux deux réglages du §13. `EVAL_COHERENCE_BILAN_ENABLED=false` rend exactement les bilans d'avant |
| **Le recollage des phrases coupées en deux à l'oral en temps réel** (§3.1) | `backend_sejourfr/src/main/resources/application.yaml`, `sejourfr.production-evaluation.recollage-tours.enabled` — livré **actif**, contrairement aux trois réglages du §13. La règle elle-même vit à **un seul endroit**, `backend_sejourfr/src/main/java/com/sejourfr/app/util/TranscriptTurnStitcher.java`, et s'applique en un seul point de lecture, ce qui garantit que le texte cité est le texte affiché |
| **Le retrait automatique des reproches fondés sur un mot mal transcrit** (§8 bis), **le retrait des reproches de langue étrangère à l'oral** (§8 quater) et **la suppression — au lieu du rejet — d'un exemple corrigé fondé sur une notion non évaluable à l'oral** (§9) | `backend_sejourfr/src/main/java/com/sejourfr/app/service/EvaluationOralArtifactFilter.java`. Ne touche **ni la note, ni le niveau, ni un seuil** : uniquement le texte du rapport, et **uniquement à l'oral**. Les deux plafonds qui protègent le cas « le candidat a vraiment changé de langue » sont écrits dans cette même classe, avec les chiffres qui les justifient ; la liste de mots-outils étrangers qu'ils utilisent vit avec son équivalent français dans `ProductionValidityService.java`. La frontière entre ce qui reste **fatal** et ce qui est **purgé** est écrite dans `EvaluationOutputValidator.java` |
| **Le retrait d'un conseil qui vend un moyen de niveau A2 comme la clé d'un palier supérieur** (§8 quinquies) | `backend_sejourfr/src/main/java/com/sejourfr/app/service/EvaluationPalierMarqueurFilter.java`. La liste fermée de ces petits mots y est écrite, **et un test la confronte au fichier de la grille active** : si la grille change d'avis, le projet ne compile plus vert tant que les deux ne disent pas la même chose. Ne touche **ni la note, ni le niveau, ni un seuil** ; s'applique à l'écrit comme à l'oral, et jamais aux citations du candidat |
| **Les bornes de longueur d'une production écrite** (celles qui refusent votre copie **et** celles que doit respecter la version modèle du §5.9) | `backend_sejourfr/src/main/java/com/sejourfr/app/util/ProductionTextBounds.java`, alimenté par les colonnes `mots_min` / `mots_max` du sujet en base. **Un seul endroit décide**, ce qui garantit qu'un texte modèle est toujours une copie recevable |
| **Ce que les filets de rapport retirent** (compteurs par famille) | `backend_sejourfr/src/main/java/com/sejourfr/app/service/EvaluationPurgeMetrics.java`. Distinct du compteur des **refus** (§12.3 bis) : un refus peut coûter la correction, un retrait n'enlève qu'une phrase |
| **Le compteur de français désaccentué** (§10 bis — il MESURE, il ne refuse jamais) | `backend_sejourfr/src/main/java/com/sejourfr/app/service/EvaluationAccentAudit.java`. La liste fermée des formes détectées y est écrite, avec la règle qui l'a construite : en cas de doute, on ne signale rien. Aucun effet sur la note, le niveau, ni le texte rendu |
| **La patience / réactivité de l'examinateur vocal** (détection de fin de parole, §10) | `backend_sejourfr/src/main/resources/application.yaml`, section `sejourfr.realtime.gemini.vad`. Les cinq valeurs sont modifiables **sans reconstruire l'application** (variables d'environnement `REALTIME_GEMINI_VAD_*`). Aucune n'a d'effet sur la note |
| **La reprise d'un entretien après une coupure réseau** (§10) | `backend_sejourfr/src/main/resources/application.yaml`, sections `sejourfr.realtime.gemini.session-resumption` et `.context-window-compression`, plus la durée de validité de l'autorisation (`token-uses`, `new-session-expire-seconds`). Le décompte du forfait, lui, ne dépend d'aucun de ces réglages : il vit dans `RealtimeSessionService` et n'a lieu qu'**une fois par entretien**, sous verrou |
| **La longueur maximale d'une réponse du correcteur** (§12.3 bis — au-delà, la réponse est coupée et la correction est perdue) | `backend_sejourfr/src/main/resources/application.yaml`, `max-tokens` des trois correcteurs de `sejourfr.production-evaluation` : **la même valeur pour les trois**, verrouillée par un test |
| **Les consignes des micro-exercices par compétence** (§11 bis — ce que l'IA regarde, les trois verdicts, l'interdiction d'une note, la façon dont le niveau doit se montrer dans la copie, les limites de l'oral) | `backend_sejourfr/src/main/resources/prompts/competence-analysis-rubrics-v5.json` (version active — **v4 mot pour mot pour tout ce qui juge** ; elle ajoute trois exemples de correction sur les deux paliers qui n'en avaient aucun et retire une fréquence attendue. Elle garde le **format de réponse v4**, inchangé. v1 à v4 restent chargeables). Fichier **séparé** de celui des tâches complètes : les deux voies n'ont ni les mêmes règles ni le même but, et on ne veut pas qu'une modification de l'une déborde sur l'autre |
| **Le format de réponse des micro-exercices** (les quatre éléments rendus, les trois verdicts, les longueurs maximales) | `backend_sejourfr/src/main/resources/prompts/competence-analysis-tool-schema-v2.json` (consignes réaccentuées, contrat inchangé) — **aucun champ n'y existe pour une note ou un niveau**, c'est ce qui rend leur apparition impossible plutôt que simplement interdite |
| **Le plan d'action « pour passer au niveau suivant » des micro-exercices** (§11 bis — la forme des leviers, ce que la réécriture garde du candidat, les marqueurs qui prouvent le palier, le procédé exigé sur chaque levier) | `backend_sejourfr/src/main/resources/prompts/competence-niveau-vise-rubrics-v3.json` et son format de réponse `competence-niveau-vise-tool-schema-v3.json` (version **active** — **la v2 mot pour mot** pour tout ce qui concerne la réécriture et la tournure à retenir ; elle n'édite que la partie « leviers », à laquelle elle ajoute un **procédé de langue obligatoire**). v1 et v2 restent chargeables. Fichiers **séparés** de ceux de l'analyse : c'est un **second correcteur**, qui ne juge rien et à qui l'on ne montre pas la grille d'analyse. Aucun champ n'y existe pour une note ou un niveau |
| **Les réglages des micro-exercices** (longueur maximale acceptée, durée maximale d'un enregistrement, nombre d'analyses offertes) | `backend_sejourfr/src/main/resources/application.yaml`, section `sejourfr.competences.analysis`. Le **correcteur**, lui, n'a pas de réglage propre : cette voie utilise le même que tout le reste (`sejourfr.production-evaluation.provider`) |
| **Le contenu des micro-exercices** (les compétences, les petits sujets, les trois réponses de référence et leurs notes pédagogiques) | migrations `db/migration/300_tcf/competences/` — fichiers **générés**, à ne pas modifier à la main ; le volume publié est figé par un test automatique |
| **Les consignes du diagnostic initial et de l'observateur du Plan** (accomplissement avant langue, limites de l'oral transcrit, allowlist de compétences, aucune note officielle) | `backend_sejourfr/src/main/resources/prompts/diagnostic-analysis-rubrics-v1.json`, fichier **séparé** de la notation et des micro-exercices. Le même contrat sert à la baseline et aux observations de productions complètes, avec un `analysis_type` explicite ; une nouvelle règle durable crée une nouvelle version au lieu de réécrire v1 |
| **Le format structuré du diagnostic/Plan** (niveau prudent ≤ B2, accomplissement, communication, preuves segmentées, confiance et priorités) | `backend_sejourfr/src/main/resources/prompts/diagnostic-analysis-tool-schema-v1.json`, renforcé par `DiagnosticAnalysisValidator` : clés exactes, allowlist exhaustive sans doublon, numéros de segment entiers et existants, cohérence observation/statut/preuve. Le drapeau « priorité » n'est plus contrôlé mais **recalculé** à partir du statut, et le maximum de deux priorités par production est appliqué en **retirant** les priorités surnuméraires (les moins sûres d'abord) : une analyse n'est jamais perdue pour ce motif. Aucun champ de note `/20` n'existe |
| **Les réglages du diagnostic** (versions, plafond de sortie, température et relances de session) | `backend_sejourfr/src/main/resources/application.yaml`, section `sejourfr.diagnostic.analysis`. Le fournisseur/modèle reste celui de `sejourfr.production-evaluation`, mais la persistance et le pipeline sont séparés de `ai_evaluations` et de la calibration |
| **Les consignes de l'avant / après du diagnostic** (choisir une phrase par son numéro, ce que la réécriture garde du candidat, ne nommer aucun niveau, ne jamais vendre un moyen déjà acquis) | `backend_sejourfr/src/main/resources/prompts/diagnostic-exemple-cible-rubrics-v1.json` et son format `…-tool-schema-v1.json`, fichiers **séparés** de ceux de l'analyse — c'est ce qui garantit que le jugement du diagnostic ne change pas d'une virgule. Aucun champ n'existe pour une note, un verdict ou un niveau, et aucun pour recopier la phrase du candidat : elle est **désignée par un numéro** et retrouvée par le serveur |
| **Les réglages de l'avant / après** (activation, versions, plafond de sortie, température) | `backend_sejourfr/src/main/resources/application.yaml`, section `sejourfr.diagnostic.exemple-cible`. Écrit seulement, produit après l'analyse et sans rejeu : `DIAGNOSTIC_EXEMPLE_CIBLE_ENABLED=false` le coupe sans rien changer d'autre |
| **La version au niveau que le candidat vise** (§5.9 — ce que la réécriture conserve de lui, la forme des leviers, ce qu'une reformulation orale ne corrige jamais, la règle d'accentuation) | `backend_sejourfr/src/main/resources/prompts/production-version-ciblee-rubrics-v2.json` et ses **deux** contrats de sortie : `production-version-ciblee-tool-schema-v2.json` (écrit) et `production-version-ciblee-tool-schema-oral-v2.json` (oral, qui ne prévoit aucun texte réécrit). La version v1 reste chargeable — retour arrière par configuration, sans migration. Fichiers **séparés de la grille de notation**, exactement comme pour les micro-exercices : c'est un **second correcteur**, qui ne note rien et à qui l'on ne montre pas la grille. Aucun champ n'y existe pour une note ou un niveau |
| **Le coupe-circuit de cette version au niveau visé** | `backend_sejourfr/src/main/resources/application.yaml`, `sejourfr.production-evaluation.version-ciblee` — livré **actif**. `EVAL_VERSION_CIBLEE_ENABLED=false` supprime le second appel et l'encart, sans rien changer d'autre. Le **fournisseur** reste celui de tout le reste (`production-evaluation.provider`) |
| **La situation dans le palier** (§6.3 bis — « A2 solide ») et **ses libellés** | `backend_sejourfr/src/main/java/com/sejourfr/app/enums/SituationDansNiveau.java`. Les bornes viennent de la **grille active**, pas de ce fichier ; les trois libellés y sont figés par un test, avec la règle qui les gouverne : aucun ne nomme un manque |
| **Le corpus de référence du banc de mesure** | `backend_sejourfr/src/test/resources/calibration/golden-set-v1.json` |
| **La grille officielle du TCF** (niveau → fourchette de note, §6.6) | `backend_sejourfr/src/main/java/com/sejourfr/app/enums/BandeNoteTcf.java` — dans le code et **pas** dans la configuration : c'est une donnée officielle, pas un réglage. Depuis la v6, la grille active la reprend à l'identique comme échelle de notation ; cet enum reste malgré tout la source officielle et sert à **afficher** la fourchette du niveau atteint |

> **Garde-fous automatiques** : au démarrage, l'application **refuse de démarrer** si les
> consignes de notation sont incohérentes — critère inconnu, poids qui ne font pas 100 %, tâche
> sans barème, bornes EE incorrectes, contexte T2/T3 absent, ou paire rubrique/tool-schema
> incompatible. À chaque correction, la sortie brute est refusée si un critère manque, est
> dupliqué, hors bornes, si la structure est incomplète ou si un niveau dépasse B2. Une seule
> réparation sémantique est autorisée ; après deux échecs, aucune note partielle n'est
> persistée. Et si l'IA rend une note très différente du calcul officiel, l'écart est enregistré
> pour surveillance.

> **On versionne, on ne réécrit pas.** Une nouvelle grille de notation devient une nouvelle
> version (`v4`, `v4.1`…). Les anciennes restent en place : sans ça, les évaluations déjà
> rendues deviendraient illisibles et incomparables.

Pour le détail **technique** (services, base de données, providers d'IA, stockage des audios),
voir [`pipeline-evaluation-eo-ee.md`](pipeline-evaluation-eo-ee.md) et
[`SPEC_MODULE_EXPRESSION_EO_EE.md`](SPEC_MODULE_EXPRESSION_EO_EE.md). Pour les décisions
produit derrière cette refonte et leurs raisons, voir
[`ia/ANALYSE_SPEC_EVALUATION_IA.md`](ia/ANALYSE_SPEC_EVALUATION_IA.md). Pour la génération des
audios de compréhension orale (autre pipeline), voir
[`pipeline-audio-co.md`](pipeline-audio-co.md).

---

## 16. Résumé en une page

L'IA joue un correcteur d'examen **juste, pas complaisant**. Pour chaque tâche, elle note les
**quatre critères du vrai TCF — communiquer, interagir, lexique, morphosyntaxe — à poids
égal**, annonce d'abord **si l'objectif de la tâche est atteint**, dit **ce qui a été traité et
ce qui a été oublié**, appuie chaque appréciation sur un **passage précis** de la production — qu'elle **désigne par son
numéro** au lieu de le recopier, ce qui rend une preuve inventée impossible —, donne
**au plus deux points forts et deux priorités, chacune avec un « comment » concret et un
exemple avant / après pris dans la copie**, et déclare **à quel point elle est sûre d'elle** — une certitude de
correcteur, jamais un jugement déguisé sur le candidat. Un même fait de langue n'est traité
**qu'à un seul endroit** du rapport, et ce que la consigne n'exigeait pas est présenté comme un
**levier de progression**, jamais comme un manque. Le rapport a d'ailleurs **maigri** : le bloc
replié « Voir l'analyse complète » a disparu de l'écran, et avec lui les **exemples corrigés**
et les **suggestions**, que l'IA ne produit plus du tout (§5.7 bis) — ce qui n'était pas lu
coûtait des mots à chaque correction, et ce budget finance désormais la version au niveau visé. Le serveur, lui, calcule la note (la moyenne
des quatre),
**en déduit le niveau directement — la note et le niveau racontent la même histoire**,
applique le garde-fou de couplage et deux plafonds ciblés, tronque les listes trop longues,
abaisse un verdict qui se contredit, et n'affiche jamais un niveau sans sa confiance. Au
bilan d'une épreuve, il refuse en plus un **B2 sans argumentation** (tâche 3 sous B1), et
laisse **sans niveau** une épreuve qui n'a pas pu être passée plutôt que de la compter au
plus bas.

**Sur une tâche isolée, il n'affiche plus la note sur 20** (§6.2 bis) : au TCF, une tâche
reçoit un niveau, et la note porte sur l'épreuve entière — surtout, sur l'échelle officielle où
10 vaut déjà B2, un « 3,5/20 » se lisait comme un naufrage alors que c'est un A2 normal. À la
place, il dit **où la production se situe dans son propre palier** — *A2 atteint*, *A2
confirmé*, *A2 solide* — jamais « presque B1 » (§6.3 bis). Et, à l'écrit, un **second
correcteur appelé séparément** rend la même réponse **rédigée au niveau que le candidat vise**,
avec deux ou trois leviers pour l'atteindre (§5.9) : le correcteur qui note n'apprend jamais ce
niveau visé — sinon il alignerait sa note dessus. Cette version modèle **respecte la longueur
imposée par le sujet**, recomptée par le serveur comme une vraie copie : hors bornes, une seule
correction est demandée, puis l'encart est retiré plutôt que coupé au milieu d'une phrase.

Enfin, le serveur retire du rapport les conseils qui **promettent un palier qu'ils ne peuvent
pas donner** — présenter « parce que », « et » ou « mais » comme la clé du B1 alors que la
grille les classe A2 (§8 quinquies). En cas de doute, il ne retire rien : conseiller ces mots
sans promettre de palier, ou les conseiller à quelqu'un qui vise le A2, reste juste et n'est
pas touché.

Le rapport lui-même est rendu **en français correctement accentué** (§10 bis) : sur une
plateforme qui enseigne le français, corriger quelqu'un dans un texte mal orthographié lui
apprend une faute au moment où on lui en corrige une. La seule exception, absolue : **ce que
l'IA cite du candidat est recopié tel quel**, accents manquants compris — lui montrer une
phrase qu'il n'a pas écrite fausserait la démonstration. Un compteur mesure ce qui échappe
encore à la règle ; il ne refuse jamais une correction pour autant.

Elle juge avant tout la **capacité du candidat à communiquer et à se faire comprendre**, sans
le pénaliser pour une transcription imparfaite, pour une piste du sujet non traitée, ni pour
la longueur. Mais **ne pas sanctionner n'est pas créditer** : une production qui ne démontre
rien de plus que l'élémentaire reste notée comme telle, parce qu'annoncer B1 à un candidat A2
revient à lui faire payer un examen officiel qu'il va rater. La même exigence vaut en haut de
l'échelle : pour annoncer B2 — le niveau exigé pour la naturalisation, dans les quatre
épreuves et sans compensation — l'IA doit pouvoir **citer** ce qui le prouve.

**Notre note sur 20 suit l'échelle du TCF** depuis la version 6 et la v7 la limite
explicitement au profil TCF IRN : **10/20 vaut B2**, 6-9 vaut B1,
2-5 vaut A2, 1 vaut A1, 0 veut dire « rien d'exploitable ». C'est la table officielle, reprise
telle quelle — il n'y a plus deux échelles à ne pas confondre. On ne convertit toujours pas la
note pour autant : au bilan d'une épreuve, on affiche le niveau estimé **et** la fourchette
officielle de ce niveau, parce que notre note porte sur une tâche et celle du TCF sur une
épreuve entière (§6.6).

**À côté de cette correction complète, une seconde voie** (§11 bis) : des **micro-exercices**
où le candidat travaille **une seule capacité à la fois**, annoncée avant qu'il écrive. L'IA n'y
rend qu'un **verdict sur cette capacité** — critère validé, partiellement atteint ou non validé — avec
un point réussi, **une seule** priorité et une reformulation qui garde son idée. **Aucune note
sur 20, aucun niveau** : le format de réponse ne comporte même pas de case pour en loger un,
parce qu'on ne déduit pas le niveau de français d'une personne de trois lignes écrites pour
exercer un point précis. Trois réponses de référence — insuffisante, attendue, très réussie —
s'ouvrent **après** sa propre production, jamais avant : lire la bonne réponse d'abord, c'est la
recopier sans le savoir.

Quatre choses qu'on **ne cache pas** :

- le garde-fou « pas de B2 sans argumentation » (§6.5 bis) est allumé sur un
  **raisonnement**, pas sur une mesure : notre banc n'a aucune référence de niveau
  d'épreuve et **ne peut pas** trancher ce choix ;
- à l'oral, **on ne juge que la transcription** — la voix et la durée ne sont pas transmises
  au correcteur, et toute sortie qui note hésitations, répétitions, fluidité, débit,
  prononciation, accent, intonation ou orthographe de transcription est rejetée ;
- notre notation est **mesurée**, et la mesure dit encore ce qui cloche : sur l'échelle
  officielle, le palier A1 ne vaut qu'**une seule valeur**, et 3 productions A1 sur 8
  ressortent A2 ; un cas de frontière B1/B2 résiste toujours ;
- le corpus qui sert à cette mesure est **écrit à la main** : il doit être remplacé par de
  vraies productions annotées par des enseignants ;
- et cette mesure **ne couvre que la notation des tâches complètes**. Les micro-exercices par
  compétence (§11 bis) n'ont **ni corpus de référence ni campagne** : on y contrôle la **forme**
  du retour, pas sa justesse. C'est la plus grande zone non mesurée du système, et tant qu'elle
  le reste, ce module est un **entraînement guidé**, pas un verdict fiable sur une compétence.
