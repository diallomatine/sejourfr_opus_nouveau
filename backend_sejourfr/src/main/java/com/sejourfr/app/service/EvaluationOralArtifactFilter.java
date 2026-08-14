package com.sejourfr.app.service;

import com.sejourfr.app.enums.EpreuveType;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Pattern;

/**
 * FILET DETERMINISTE de la restitution ORALE. Il retire du rapport rendu au
 * candidat trois choses que la grille interdit deja au correcteur, mais qu'il
 * produit quand meme :
 *
 * <ol>
 *   <li>les REPROCHES DE NIVEAU MOT appuyes sur un passage de la transcription
 *       (« vous employez « l'ile » », « la formulation « par travers » est
 *       incorrecte ») : a l'oral, un mot isole est exactement ce que la
 *       reconnaissance vocale se trompe a restituer, et les rubriques exigent
 *       depuis toujours des remarques au niveau de la PHRASE, jamais du MOT ;</li>
 *   <li>les REPROCHES DE LANGUE ETRANGERE (« un passage en neerlandais »,
 *       « eviter de passer a une autre langue ») : c'est le transcripteur temps
 *       reel qui change de langue, pas le candidat — cf. la section dediee
 *       ci-dessous ;</li>
 *   <li>les REPROCHES DE FORME en morphosyntaxe (« « abit a Lille » (j'habite) »,
 *       « « zerer » (neologisme) ») : a l'oral une faute de grammaire est une
 *       STRUCTURE, jamais la forme d'un mot — cf. le volet dedie ci-dessous ;</li>
 *   <li>les entrees de {@code exemples_corriges} dont l'explication ou le gain
 *       se fondent sur une NOTION non evaluable a l'oral (hesitations, debit,
 *       prononciation...) ou sur un reproche de langue etrangere.</li>
 * </ol>
 *
 * <h2>Ce que ce filet ne touche pas</h2>
 * <b>Ni la note, ni le niveau, ni un seuil, ni un bareme.</b> Il n'agit que sur
 * du texte de restitution, apres que la note a ete calculee : le meme jeu de
 * {@code scores_criteres} donne exactement la meme note avec ou sans lui. C'est
 * ce qui permet de le livrer sans campagne de banc.
 *
 * <h2>Pourquoi un incident l'a impose</h2>
 * Sur la submission EO T3 du 2026-08-06, le candidat avait dit « Lille »,
 * « sachant qu'a Paris » et « pour traverser » ; la transcription portait
 * « l'ile », « ca sent qu'a Paris » et « par travers ». Le correcteur a impute
 * ces trois artefacts au candidat dans CINQ champs, sans employer un seul des
 * mots interdits ({@code prononciation}, {@code fluidite}...) : le garde-fou
 * lexical existant ne pouvait rien voir.
 *
 * <h2>Frontiere assumee du filet</h2>
 * <b>Il ne reconnait qu'un reproche qui ne nomme qu'UN SEUL mot porteur de
 * sens.</b> Un artefact etale sur plusieurs mots (« ca sent qu'a Paris ») est
 * indiscernable d'une vraie faute de langue sans lexique du francais, et
 * inventer une heuristique la-dessus supprimerait de VRAIES corrections. C'est
 * la consigne de la grille (rubriques v9, section orale) qui traite ce cas, et
 * elle se mesure au banc — pas ce filet.
 *
 * <h2>Regle de purge</h2>
 * <ul>
 *   <li>on ne purge que ce qui est ANCRE sur la transcription : la citation doit
 *       etre retrouvee dans un tour {@code Candidat :} par
 *       {@link EvaluationProofMatcher}. Un conseil general, meme maladroit,
 *       n'est jamais touche ;</li>
 *   <li>on purge la PHRASE, pas le champ entier : « purger le reproche, pas la
 *       production » ;</li>
 *   <li>une phrase qui cite AUSSI un passage plus long est conservee : elle
 *       parle alors de la construction de la phrase, pas d'un mot ;</li>
 *   <li>une priorite dont le {@code constat} ou le {@code comment} ne survit pas
 *       est supprimee ENTIEREMENT : elle etait batie sur l'artefact.</li>
 * </ul>
 *
 * <h2>Volet FORME — la grammaire orale est une STRUCTURE (2026-08-09)</h2>
 * Constat, mesure sur les 142 evaluations de la base : les passages entre
 * guillemets d'un reproche, presents verbatim dans la production mais absents
 * d'un dictionnaire francais de 475 000 formes, touchent <b>9 evaluations EO sur
 * 75 (12,0 %) et 0 EE sur 67</b>. <b>Zero a l'ecrit</b> : la cause est la
 * machine, pas le niveau du candidat — a l'ecrit il tape chaque lettre.
 *
 * <p>Le volet n'agit donc qu'a l'ORAL, et seulement sur le critere
 * {@code morphosyntaxe} et les priorites qui le relisent. Il ne touche
 * <b>jamais</b> {@code lexique} : la meme mesure y produit deux faux positifs
 * reels ({@code chronoposte}, {@code ESN}), dont l'un cite en POINT FORT. Sa
 * regle est {@link EvaluationOralForme} ; son extension aux
 * transcriptions abimees vient de {@link TranscriptionQualityAudit}.
 *
 * <h2>Volet LANGUE ETRANGERE (2026-08-07)</h2>
 * <b>Cause, mesuree en base.</b> Le transcripteur du temps reel (Gemini Live,
 * modele natif-audio) est multilingue par construction et son editeur annonce
 * qu'il « change de langue naturellement en cours de conversation ».
 * <b>6 transcriptions temps reel sur 39</b> portent une ecriture non latine
 * (arabe, cyrillique), contre <b>0 sur 36</b> cote Whisper asynchrone — ou la
 * langue, elle, est imposee. L'API Live <b>ne permet pas</b> d'imposer la langue
 * de la transcription d'ENTREE. Le correcteur a impute cette langue au candidat
 * dans <b>5 evaluations EO sur 72</b>.
 *
 * <p><b>Asymetrie EE / EO, volontaire.</b> Ce filet n'est appele que sur une
 * epreuve orale. <b>A l'ecrit, rien de tout ceci ne s'applique</b> : aucune
 * machine ne s'interpose entre le candidat et son texte, il a tape chaque mot.
 * Une langue etrangere dans une production ECRITE est une vraie non-realisation
 * et doit remonter au candidat.
 *
 * <p><b>Ce qui n'est JAMAIS purge : {@code confiance_raisons}.</b> « Transcription
 * temps reel partiellement incertaine (passages en russe et en neerlandais,
 * artefacts de reconnaissance vocale) » est un verbatim REEL, et c'est le bon
 * comportement : la langue etrangere y est traitee comme un obstacle a
 * l'observation, pas comme une faute du candidat. C'est exactement la ou elle
 * doit vivre.
 *
 * <h2>Le garde-fou : ne pas neutraliser une VRAIE bascule de langue</h2>
 * Un candidat qui repond reellement dans une autre langue doit continuer d'etre
 * sanctionne — c'est un piege du corpus de calibration ({@code EO_T3_PIEGE_01}).
 * La purge est donc conditionnee a deux mesures DETERMINISTES sur la production
 * elle-meme, prises sur les seuls tours {@code Candidat :} :
 * {@link #PART_NON_LATIN_MAX} et {@link #PART_MOTS_ETRANGERS_MAX}. Au-dessus de
 * l'un ou l'autre, <b>on ne purge rien</b>.
 *
 * <p>La production mesuree est celle que LIT le correcteur : le parametre
 * {@code production} vient de {@code TranscriptionManager.findLatestTexteBySubmissionId}
 * (tours recolles compris), unique accesseur au texte. Aucun second acces.
 */
final class EvaluationOralArtifactFilter {

    /**
     * MARQUEURS DE REPROCHE DE LANGUE ETRANGERE, forme normalisee (minuscules,
     * sans accents). Liste FERMEE, calquee sur les verbatims reellement produits
     * par le correcteur (5 evaluations en base) :
     * <ul>
     *   <li>« Eviter de passer a une <b>autre langue</b> pendant l'epreuve » ;</li>
     *   <li>« Plusieurs passages sont inaudibles ou en <b>langue etrangere</b> » ;</li>
     *   <li>« Un passage <b>en neerlandais</b> (...) qui interrompt la communication » ;</li>
     *   <li>« ... avec des passages <b>en russe</b> et des bruits » ;</li>
     *   <li>« Le passage final en anglais sort du <b>cadre francophone</b> ».</li>
     * </ul>
     *
     * <p>Volontairement ANCREE sur « en &lt;langue&gt; » et non sur le simple nom de
     * la langue : « le mot anglais "meeting" » est une remarque de lexique
     * francais parfaitement legitime, et elle n'est pas touchee. De meme, aucun
     * marqueur ne porte sur {@code francais} seul — « ta phrase en francais est
     * claire » n'est pas un reproche de langue.
     */
    private static final Pattern LANGUE_ETRANGERE = Pattern.compile(
        "\\blangues? etrangeres?\\b"
            + "|\\bautres? langues?\\b"
            + "|\\bchang(e|er|ez|ement)( de| la )?langue\\b"
            + "|\\b(en|vers l|vers le|a l|a la) (anglais|americain|russe|arabe|espagnol"
            + "|neerlandais|hollandais|flamand|allemand|italien|portugais|bresilien|turc"
            + "|chinois|mandarin|japonais|coreen|polonais|roumain|ukrainien|serbe|croate"
            + "|albanais|grec|persan|farsi|pachto|ourdou|hindi|bengali|tamoul|vietnamien"
            + "|thai|swahili|somali|amharique|wolof|bambara|peul|soninke|berbere|kabyle"
            + "|creole|catalan|basque|anglaise|russes?|arabes?|espagnole|neerlandaise"
            + "|allemande|italienne|portugaise|turque|chinoise)\\b"
            + "|\\blangue (anglaise|russe|arabe|espagnole|neerlandaise|allemande|italienne"
            + "|portugaise|turque|chinoise|maternelle)\\b"
            + "|\\bcadre francophone\\b|\\bnon francophone\\b"
            + "|\\brest(er|ez|e|es) en francais\\b"
            + "|\\bhors du francais\\b");

    /**
     * Part maximale de lettres NON LATINES (arabe, cyrillique...) dans les tours
     * du candidat au-dela de laquelle on ne purge plus rien.
     *
     * <p><b>Origine, mesuree.</b> Sur les 75 transcriptions reelles en base, les
     * 5 qui portent une hallucination non latine plafonnent a <b>6,8 %</b>
     * (24 caracteres non latins dans une production courte) ; les 36
     * transcriptions Whisper sont a <b>0 %</b>. A l'inverse, une production
     * reellement redigee dans un autre alphabet en est proche de 100 %, et le
     * controle amont ({@code ProductionValidityService}) la declare deja INVALIDE
     * a partir de 30 %. Ce seuil laisse donc 2,2x de marge au-dessus du pire
     * artefact observe tout en restant a la moitie du seuil d'invalidite.
     */
    static final double PART_NON_LATIN_MAX = 0.15;

    /**
     * Part maximale de MOTS-OUTILS D'UNE AUTRE LANGUE dans les tours du candidat
     * au-dela de laquelle on ne purge plus rien. C'est ce seuil qui protege le
     * cas « le candidat repond vraiment dans une autre langue », que l'alphabet
     * ne trahit pas (anglais, neerlandais, espagnol).
     *
     * <p><b>Origine, mesuree.</b> Trois populations, meme mesure
     * ({@code ProductionValidityService.ratioMotsEtrangers} sur les tours
     * candidat, hesitations retirees) :
     * <ul>
     *   <li>75 transcriptions reelles (dont les 5 evaluations fautives) :
     *       <b>1,4 % au pire</b> ;</li>
     *   <li>47 des 48 cas du corpus de calibration : <b>0 %</b> ;</li>
     *   <li>{@code EO_T3_PIEGE_01}, le cas ou le candidat bascule VRAIMENT en
     *       espagnol : <b>12,5 %</b>.</li>
     * </ul>
     * 6 % se place a 4,3x au-dessus du pire artefact reel et a 2,1x en dessous
     * du piege. C'est la mesure qui separe, et la seule : le ratio de mots-outils
     * FRANCAIS ne separe pas (le piege affiche 36 %, soit plus que 8 vraies
     * transcriptions francaises) — cf. {@code MOTS_OUTILS_ETRANGERS}.
     */
    static final double PART_MOTS_ETRANGERS_MAX = 0.06;

    /**
     * En dessous de ce nombre de mots exploitables, on ne mesure rien et on ne
     * purge rien : un seul token pese alors plus de 2,5 % et deux tokens
     * suffiraient a franchir {@link #PART_MOTS_ETRANGERS_MAX}. Une production
     * quasi muette est justement celle ou une vraie bascule de langue est la plus
     * plausible. Les 5 evaluations fautives reelles portent 77 a 255 mots.
     */
    static final int MOTS_MIN_MESURE_LANGUE = 40;

    /** Au-dela d'un mot porteur de sens, le reproche n'est plus « de niveau mot ». */
    private static final int MAX_MOTS_PORTEURS = 1;

    /**
     * VOLET FORME — code du critere de grammaire, le seul concerne. Les codes
     * sont identiques sur les six taches depuis les rubriques v5.
     */
    private static final String CODE_MORPHOSYNTAXE = "morphosyntaxe";

    /**
     * VOLET FORME — marqueurs qui rattachent une priorite
     * ({@code points_a_ameliorer}) au critere de grammaire. Le contrat de sortie
     * ne porte AUCUN code de critere sur ces entrees : sans cette liste, on ne
     * saurait pas laquelle relit un reproche de morphosyntaxe, et appliquer le
     * volet a toutes les priorites reviendrait a purger des conseils de contenu.
     * Liste fermee et etroite, comme {@link #REPROCHE} : elle ne peut que
     * REDUIRE le nombre de purges.
     */
    private static final Pattern MARQUEUR_GRAMMAIRE = Pattern.compile(
        "\\bgrammatical|\\bgrammaire\\b|\\baccord\\b|\\bconjug|\\bconjugaison\\b"
            + "|\\btemps (du |de |verbal)|\\bverbe\\b|\\bverbal|\\barticle\\b|\\bgenre\\b"
            + "|\\bpluriel\\b|\\bsingulier\\b|\\bpreposition|\\bpronom\\b|\\bauxiliaire\\b"
            + "|\\bparticipe\\b|\\binfinitif\\b|\\bsubjonctif\\b|\\bconditionnel\\b"
            + "|\\bsyntax|\\bmorphosyntax|\\bconstruction (de la |du |verbale)");

    /**
     * Remplace un commentaire de critere entierement purge. Le champ est
     * obligatoire cote fronts : on ne le supprime pas, on dit franchement
     * pourquoi il est vide — meme pratique que les avertissements serveur.
     */
    static final String COMMENTAIRE_CRITERE_PURGE =
        "La seule remarque proposée pour ce critère portait sur un mot isolé de la "
            + "transcription : elle a été retirée. Nous ne vous reprochons jamais un mot que "
            + "la reconnaissance vocale a pu déformer.";

    /** Idem, quand c'est le volet FORME qui a tout emporte. */
    static final String COMMENTAIRE_CRITERE_PURGE_FORME =
        "Les erreurs de grammaire relevées pour ce critère ne portaient que sur la forme d'un "
            + "ou deux mots de la transcription : elles ont été retirées. À l'oral, nous ne "
            + "vous reprochons que ce qui s'entend — une structure de phrase, jamais "
            + "l'orthographe d'un mot que la machine a pu déformer.";

    /** Idem, quand c'est le volet LANGUE qui a tout emporte. */
    static final String COMMENTAIRE_CRITERE_PURGE_LANGUE =
        "La seule remarque proposée pour ce critère vous reprochait d'avoir parlé une autre "
            + "langue : elle a été retirée. Ces passages viennent de notre transcription "
            + "automatique, pas de vous.";

    /** Idem pour le résumé d'objectif, qui ne peut pas rester vide. */
    static final String OBJECTIF_RESUME_PURGE_LANGUE =
        "Ton objectif a été évalué sur ce que tu as dit en français : les passages transcrits "
            + "dans une autre langue n'ont pas été retenus contre toi.";

    /** Avertissement candidat, pose des qu'au moins une remarque a ete retiree. */
    static final String AVERTISSEMENT_ARTEFACT =
        "Une ou plusieurs remarques portaient sur un mot isolé de la transcription "
            + "automatique : elles ont été retirées. À l'oral, un mot mal transcrit n'est "
            + "jamais compté comme une erreur de votre part.";

    /** Avertissement candidat propre au volet FORME. */
    static final String AVERTISSEMENT_FORME =
        "Une ou plusieurs remarques de grammaire portaient sur la forme d'un ou deux mots de "
            + "la transcription automatique : elles ont été retirées. À l'oral, une faute de "
            + "grammaire se voit sur une structure de phrase — la forme d'un mot isolé, elle, "
            + "ne s'entend pas et peut venir de notre machine.";

    /** Avertissement candidat propre au volet LANGUE. */
    static final String AVERTISSEMENT_LANGUE =
        "Une ou plusieurs remarques vous reprochaient d'être passé à une autre langue : elles "
            + "ont été retirées. Ces passages sont produits par notre transcription "
            + "automatique, qui bascule parfois de langue toute seule — ils ne vous sont "
            + "jamais comptés comme une faute.";

    /** Resultat d'une purge : le feedback est modifie en place. */
    record Resultat(int remarquesRetirees, int remarquesLangueRetirees,
                    int remarquesFormeRetirees, int exemplesRetires) {
        boolean aPurge() {
            return remarquesRetirees > 0 || remarquesLangueRetirees > 0
                || remarquesFormeRetirees > 0 || exemplesRetires > 0;
        }
    }

    private EvaluationOralArtifactFilter() {
    }

    /**
     * Purge en place les champs de restitution d'une sortie ORALE. Le drapeau de
     * transcription degradee est deduit de la production elle-meme.
     *
     * @param feedback   sortie du correcteur, deja normalisee
     * @param production transcription servie au correcteur (tours recolles)
     */
    static Resultat purge(Map<String, Object> feedback, String production) {
        return purge(feedback, production, TranscriptionQualityAudit.mesurer(production).degradee());
    }

    /**
     * @param transcriptionDegradee mesure de {@link TranscriptionQualityAudit} :
     *                              au-dessus du seuil, TOUT reproche de
     *                              morphosyntaxe adosse a un passage cite est
     *                              suspect, quelle que soit sa longueur — le
     *                              texte que lit le correcteur n'est pas celui
     *                              que le candidat a dit.
     */
    static Resultat purge(Map<String, Object> feedback, String production,
                          boolean transcriptionDegradee) {
        Contexte ctx = new Contexte(production, mesurableEtFrancaise(production), transcriptionDegradee);
        Purge total = Purge.vide();
        total = total.plus(purgeScores(feedback, ctx));
        total = total.plus(purgePriorites(feedback, ctx));
        total = total.plus(purgeListeDeTextes(feedback, "suggestions", ctx));
        total = total.plus(purgeListeDeTextes(feedback, "points_forts", ctx));
        total = total.plus(purgeObjectifResume(feedback, ctx));
        return new Resultat(total.mot(), total.langue(), total.forme(),
            purgeExemplesCorriges(feedback, ctx));
    }

    /**
     * Ce que chaque champ doit connaitre : le texte de la production, si le
     * volet LANGUE a le droit de s'appliquer, et si la transcription est
     * degradee. Les deux garde-fous sont evalues UNE fois par purge, pas par
     * phrase.
     */
    private record Contexte(String production, boolean langueAutorisee, boolean degradee) {
    }

    // ------------------------------------------------------------- par champ

    @SuppressWarnings("unchecked")
    private static Purge purgeScores(Map<String, Object> feedback, Contexte ctx) {
        if (!(feedback.get("scores_criteres") instanceof List<?> scores)) return Purge.vide();
        Purge total = Purge.vide();
        for (Object raw : scores) {
            if (!(raw instanceof Map<?, ?> rawMap)) continue;
            Map<String, Object> score = (Map<String, Object>) rawMap;
            if (!(score.get("commentaire") instanceof String commentaire)) continue;
            // Le volet FORME ne concerne QUE la grammaire : sur `lexique`, un
            // reproche court est le plus souvent une vraie remarque de
            // vocabulaire (mesure : « chronoposte » et « ESN », dont l'un cite
            // en POINT FORT, seraient des faux positifs).
            boolean grammaire = CODE_MORPHOSYNTAXE.equals(codeDe(score));
            Purge purge = purgerPhrases(commentaire, ctx, true, true, grammaire);
            if (purge.rien()) continue;
            total = total.plus(purge);
            score.put("commentaire", purge.reste().isBlank()
                ? commentairePurge(purge)
                : purge.reste());
        }
        return total;
    }

    private static String codeDe(Map<String, Object> score) {
        return score.get("code") == null ? "" : score.get("code").toString();
    }

    /** Le texte de remplacement nomme le motif REEL de la purge, jamais un autre. */
    private static String commentairePurge(Purge purge) {
        if (purge.langue() > 0) return COMMENTAIRE_CRITERE_PURGE_LANGUE;
        if (purge.mot() > 0) return COMMENTAIRE_CRITERE_PURGE;
        return COMMENTAIRE_CRITERE_PURGE_FORME;
    }

    @SuppressWarnings("unchecked")
    private static Purge purgePriorites(Map<String, Object> feedback, Contexte ctx) {
        if (!(feedback.get("points_a_ameliorer") instanceof List<?> points)) return Purge.vide();
        List<Object> gardees = new ArrayList<>();
        Purge total = Purge.vide();
        for (Object raw : points) {
            if (!(raw instanceof Map<?, ?> rawMap)) {
                gardees.add(raw);
                continue;
            }
            Map<String, Object> point = new LinkedHashMap<>((Map<String, Object>) rawMap);
            String constatBrut = EvaluationTexte.texte(point.get("constat"));
            String commentBrut = EvaluationTexte.texte(point.get("comment"));
            // Le contrat ne rattache aucune priorite a un critere : c'est le
            // vocabulaire de la priorite elle-meme qui dit si elle relit le
            // reproche de grammaire. Cf. MARQUEUR_GRAMMAIRE.
            boolean grammaire = parleDeGrammaire(constatBrut) || parleDeGrammaire(commentBrut);
            Purge constat = purgerPhrases(constatBrut, ctx, true, true, grammaire);
            Purge comment = purgerPhrases(commentBrut, ctx, true, true, grammaire);
            if (constat.rien() && comment.rien()) {
                gardees.add(rawMap);
                continue;
            }
            total = total.plus(constat).plus(comment);
            // Une priorite dont le constat OU la technique est tombee ne tenait
            // que par l'artefact : on la retire en entier plutot que de rendre
            // au candidat un demi-conseil.
            boolean vide = constat.reste().isBlank()
                || (point.get("comment") != null && comment.reste().isBlank());
            if (vide) continue;
            point.put("constat", constat.reste());
            if (point.get("comment") != null) point.put("comment", comment.reste());
            gardees.add(point);
        }
        feedback.put("points_a_ameliorer", gardees);
        return total;
    }

    /**
     * Listes de chaines simples ({@code suggestions}, {@code points_forts}) :
     * l'entree entierement purgee disparait — un conseil ou un point fort reduit
     * a rien n'a rien a dire au candidat. Le plafond serveur
     * ({@code AiEvaluationService.capListe}) s'applique apres, sur ce qui reste.
     */
    private static Purge purgeListeDeTextes(Map<String, Object> feedback, String champ, Contexte ctx) {
        if (!(feedback.get(champ) instanceof List<?> valeurs)) return Purge.vide();
        List<Object> gardees = new ArrayList<>();
        Purge total = Purge.vide();
        for (Object raw : valeurs) {
            if (!(raw instanceof String valeur)) {
                gardees.add(raw);
                continue;
            }
            Purge purge = purgerPhrases(valeur, ctx);
            if (purge.rien()) {
                gardees.add(raw);
                continue;
            }
            total = total.plus(purge);
            if (!purge.reste().isBlank()) gardees.add(purge.reste());
        }
        feedback.put(champ, gardees);
        return total;
    }

    /**
     * {@code accomplissement.objectif_resume} : phrase candidat, elle ne peut pas
     * rester vide (les fronts l'affichent sous le verdict). Le VERDICT lui-meme
     * ({@code accomplissement.objectif}) n'est pas touche : il est garanti par
     * ailleurs, et le remonter ici contredirait la regle « le serveur n'abaisse,
     * jamais ne releve ».
     */
    @SuppressWarnings("unchecked")
    private static Purge purgeObjectifResume(Map<String, Object> feedback, Contexte ctx) {
        if (!(feedback.get("accomplissement") instanceof Map<?, ?> rawMap)) return Purge.vide();
        Map<String, Object> accomplissement = (Map<String, Object>) rawMap;
        if (!(accomplissement.get("objectif_resume") instanceof String resume)) return Purge.vide();
        // Volet LANGUE seul : le volet MOT exige une citation ancree ET un
        // marqueur de reproche, or ce champ resume l'ATTEINTE de l'objectif.
        // L'y appliquer viderait un resume pour un mot cite, en contradiction
        // avec la coherence « accomplissement <-> rapport » de la v8.
        Purge purge = purgerPhrases(resume, ctx, false, true, false);
        if (purge.rien()) return Purge.vide();
        accomplissement.put("objectif_resume",
            purge.reste().isBlank() ? OBJECTIF_RESUME_PURGE_LANGUE : purge.reste());
        return purge;
    }

    /**
     * {@code exemples_corriges} : on SUPPRIME l'entree dont l'explication ou le
     * gain se fonde sur une notion non evaluable a l'oral — ou sur un reproche de
     * langue etrangere — au lieu de faire echouer l'evaluation entiere (cf.
     * {@link EvaluationOutputValidator}).
     */
    private static int purgeExemplesCorriges(Map<String, Object> feedback, Contexte ctx) {
        if (!(feedback.get("exemples_corriges") instanceof List<?> exemples)) return 0;
        List<Object> gardes = new ArrayList<>();
        int retires = 0;
        for (Object raw : exemples) {
            if (raw instanceof Map<?, ?> exemple
                && (EvaluationOutputValidator.mentionneMotifOralInterdit(exemple.get("explication"))
                    || EvaluationOutputValidator.mentionneMotifOralInterdit(exemple.get("gain"))
                    || (ctx.langueAutorisee()
                        && (reprocheDeLangue(EvaluationTexte.texte(exemple.get("explication")))
                            || reprocheDeLangue(EvaluationTexte.texte(exemple.get("gain"))))))) {
                retires++;
                continue;
            }
            gardes.add(raw);
        }
        feedback.put("exemples_corriges", gardes);
        return retires;
    }

    // ------------------------------------------------------------- mecanique

    /** Compteurs par MOTIF : les trois volets n'ont pas le meme avertissement. */
    private record Purge(String reste, int mot, int langue, int forme) {

        static Purge vide() {
            return new Purge("", 0, 0, 0);
        }

        boolean rien() {
            return mot == 0 && langue == 0 && forme == 0;
        }

        /** Cumul des COMPTEURS seuls ; le reste textuel appartient a chaque champ. */
        Purge plus(Purge autre) {
            return new Purge(reste, mot + autre.mot(), langue + autre.langue(),
                forme + autre.forme());
        }
    }

    private static Purge purgerPhrases(String texte, Contexte ctx) {
        return purgerPhrases(texte, ctx, true, true, false);
    }

    /**
     * Retire les phrases qui ne tiennent que par une citation d'UN SEUL mot de la
     * transcription, par un reproche de langue etrangere, ou — sur le seul
     * critere de grammaire — par un reproche de FORME. Les autres sont recopiees
     * telles quelles.
     */
    private static Purge purgerPhrases(String texte, Contexte ctx, boolean voletMot,
                                       boolean voletLangue, boolean voletForme) {
        String production = ctx.production();
        if (texte == null || texte.isBlank() || production == null || production.isBlank()) {
            return new Purge(texte == null ? "" : texte, 0, 0, 0);
        }
        List<String> gardees = new ArrayList<>();
        int mot = 0;
        int langue = 0;
        int forme = 0;
        for (String phrase : EvaluationTexte.phrases(texte)) {
            // Ordre volontaire : LANGUE, puis MOT, puis FORME. Le volet MOT est
            // strictement plus etroit que le volet FORME ; le tester en premier
            // garde intact le compteur et l'avertissement des cas deja couverts.
            if (voletLangue && ctx.langueAutorisee() && reprocheDeLangue(phrase)) {
                langue++;
            } else if (voletMot && reprocheDeNiveauMot(phrase, production)) {
                mot++;
            } else if (voletForme && reprocheDeForme(phrase, production, ctx.degradee())) {
                forme++;
            } else {
                gardees.add(phrase.strip());
            }
        }
        if (mot == 0 && langue == 0 && forme == 0) return new Purge(texte, 0, 0, 0);
        return new Purge(String.join(" ", gardees).strip(), mot, langue, forme);
    }

    /** Vrai quand la priorite relit explicitement le reproche de grammaire. */
    private static boolean parleDeGrammaire(String texte) {
        return texte != null && !texte.isBlank()
            && MARQUEUR_GRAMMAIRE.matcher(EvaluationTexte.normaliserPourMarqueur(texte)).find();
    }

    /**
     * VOLET FORME — vrai quand la phrase reunit les trois conditions :
     * <ol>
     *   <li>elle REPROCHE quelque chose ({@link #REPROCHE}) ;</li>
     *   <li>elle cite au moins un passage REEL de la transcription, retrouve dans
     *       un tour {@code Candidat :} ;</li>
     *   <li>au moins un des passages cites nomme <b>une ou deux</b> formes
     *       pleines — donc ne decrit pas une structure. La regle et son seuil
     *       vivent dans {@link EvaluationOralForme}, partages avec le second
     *       appel « version au niveau visee ». Sur une transcription DEGRADEE,
     *       cette troisieme condition tombe : le texte lu n'est pas celui qui a
     *       ete dit, aucun reproche de grammaire ancre n'y est opposable.</li>
     * </ol>
     *
     * <p><b>Cas reels attrapes</b> : « abit a Lille » (le candidat avait dit
     * « j'habite a Lille », le « j'h » a ete mange) le 2026-08-08, et
     * « Habite a Lille » sans sujet le 2026-08-07 — le meme artefact, deux jours
     * de suite. A l'inverse, un passage fait UNIQUEMENT de mots-outils (« pour ne
     * pas que ») est une structure pure, et il est conserve.
     *
     * <p><b>Le sens de l'erreur, et son cout, sont assumes.</b> La phrase entiere
     * part, pas la seule citation fautive : retirer une citation au milieu d'une
     * enumeration rendrait au candidat une phrase mutilee. Mesure sur les 75
     * commentaires de morphosyntaxe EO en base : <b>11 phrases</b> tombent, dont
     * environ sept portaient AUSSI une vraie faute. On perd donc du conseil, mais
     * on ne perd jamais un point : ce filet ne touche ni la note, ni le niveau,
     * ni un seuil, et le candidat garde ses priorites et ses exemples corriges.
     * Reprocher a un candidat une faute que notre machine a fabriquee coute plus
     * cher que taire une faute reelle.
     */
    private static boolean reprocheDeForme(String phrase, String production, boolean degradee) {
        // La regle entiere — reproche, ancrage, une ou deux formes pleines — vit
        // dans EvaluationOralForme depuis qu'une TROISIEME surface la relit (le
        // volet oral du diagnostic). Ici on ne fait que l'appeler.
        return EvaluationOralForme.reprocheAncreSurUneForme(phrase, production, degradee);
    }

    /** Vrai quand la phrase reproche au candidat d'avoir employe une autre langue. */
    private static boolean reprocheDeLangue(String phrase) {
        return phrase != null && !phrase.isBlank()
            && LANGUE_ETRANGERE.matcher(EvaluationTexte.normaliserPourMarqueur(phrase)).find();
    }

    /**
     * GARDE-FOU DU VOLET LANGUE — vrai quand la production est assez longue pour
     * etre mesuree ET reste massivement francaise. Faux <b>en cas de doute</b> :
     * un reproche injuste laisse passer coute moins cher que l'effacement d'une
     * vraie bascule de langue, qui est une non-realisation.
     *
     * <p>Mesure prise sur les seuls tours {@code Candidat :} : les mots de
     * l'examinateur ne sont pas la production du candidat. Hesitations retirees,
     * comme partout ailleurs.
     */
    private static boolean mesurableEtFrancaise(String production) {
        if (production == null || production.isBlank()) return false;
        String texte = production.strip();
        String duCandidat = ProductionValidityService.estDialogue(texte)
            ? ProductionValidityService.toursDuCandidat(texte)
            : texte;
        if (duCandidat.isBlank()) return false;
        List<String> mots = new ArrayList<>();
        for (String mot : ProductionValidityService.motsNormalises(duCandidat)) {
            if (!EvaluationProofMatcher.DISFLUENCES.contains(mot)) mots.add(mot);
        }
        if (mots.size() < MOTS_MIN_MESURE_LANGUE) return false;
        return ProductionValidityService.ratioLettresNonLatines(duCandidat) <= PART_NON_LATIN_MAX
            && ProductionValidityService.ratioMotsEtrangers(mots) <= PART_MOTS_ETRANGERS_MAX;
    }

    /**
     * Vrai quand la phrase reunit les TROIS conditions :
     * <ol>
     *   <li>elle REPROCHE quelque chose ({@link #REPROCHE}) — un conseil qui cite
     *       un mot n'est jamais touche ;</li>
     *   <li>elle cite au moins un passage REEL de la transcription, retrouve
     *       dans un tour {@code Candidat :} ;</li>
     *   <li>TOUS les passages qu'elle cite ne nomment qu'un seul mot porteur de
     *       sens. Citer aussi un passage plus long suffit a la conserver : la
     *       remarque porte alors sur la construction de la phrase, pas sur un mot
     *       que la reconnaissance vocale a pu deformer.</li>
     * </ol>
     *
     * <p><b>Exception ajoutee le 2026-08-09</b> : une citation faite UNIQUEMENT de
     * mots-outils — zero mot porteur, comme « pour ne pas que » ou « est-ce
     * que » — ne nomme aucun mot, elle nomme une STRUCTURE. Elle etait purgee par
     * inadvertance (« aucun mot porteur » satisfaisait « au plus un »), alors que
     * le cas reel du 2026-06-11 (« "pour ne pas que" (incorrect pour "pour eviter
     * que)" ») est un vrai reproche de grammaire. Un resserrement, donc : ce
     * volet purge strictement moins qu'avant.
     */
    private static boolean reprocheDeNiveauMot(String phrase, String production) {
        if (!EvaluationOralForme.estUnReproche(phrase)) return false;
        boolean motIsole = false;
        for (String citation : EvaluationOralForme.citations(phrase)) {
            if (EvaluationProofMatcher
                .canonicalPassage(production, citation, EpreuveType.TCF_EO).isEmpty()) {
                continue; // pas un passage de la transcription : on n'y touche pas
            }
            int porteurs = EvaluationProofMatcher.significantTokenCount(citation);
            if (porteurs > MAX_MOTS_PORTEURS) return false;
            if (porteurs >= 1) motIsole = true;
        }
        return motIsole;
    }

}
