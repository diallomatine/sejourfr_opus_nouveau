package com.sejourfr.app.service;

import com.sejourfr.app.enums.EpreuveType;

import java.text.Normalizer;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Optional;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/** Rapproche une preuve LLM d'un passage unique et litteral de la production. */
final class EvaluationProofMatcher {

    private static final int MIN_FUZZY_TOKENS = 4;
    private static final int MIN_IDENTICAL_SIGNIFICANT_TOKENS = 3;

    // Inclure les marques combinantes avant la normalisation : dans une chaine
    // deja decomposee en NFD, "e\u0301cole" doit rester un seul token. Les
    // offsets restent ceux du texte brut pour restituer sa sous-chaine exacte.
    private static final Pattern TOKEN = Pattern.compile("[\\p{L}\\p{N}\\p{M}]+");
    /**
     * Marqueur de tour d'un dialogue oral. Partage avec
     * {@link EvaluationProductionSegments} : le decoupage NUMEROTE servi au
     * correcteur (contrat v6) et le rapprochement litteral (contrats v4/v5)
     * doivent lire un dialogue exactement de la meme facon.
     */
    static final Pattern TURN_MARKER = Pattern.compile(
        "(?im)^[\\h]*(examinateur|candidat)[\\h]*:[\\h]*");
    private static final Pattern CITATION_SPEAKER = Pattern.compile(
        "(?is)^\\s*(examinateur|candidat)\\s*:\\s*");

    private static final Set<String> NEGATIONS = Set.of(
        "ne", "n", "pas", "plus", "jamais", "rien", "personne", "aucun",
        "aucune", "aucuns", "aucunes", "ni", "non", "sans", "guere",
        "point", "nullement", "aucunement");

    private static final Set<String> NUMBER_WORDS = Set.of(
        "zero", "un", "une", "deux", "trois", "quatre", "cinq", "six", "sept",
        "huit", "neuf", "dix", "onze", "douze", "treize", "quatorze", "quinze",
        "seize", "vingt", "trente", "quarante", "cinquante", "soixante", "cent",
        "cents", "mille", "million", "millions", "milliard", "milliards", "premier",
        "premiere", "deuxieme", "second", "seconde", "troisieme", "quatrieme",
        "cinquieme", "sixieme", "septieme", "huitieme", "neuvieme", "dixieme");

    // Seuls ces mots-outils peuvent manquer dans la copie d'une citation ou y
    // avoir ete ajoutes. La liste reste volontairement courte : pronoms,
    // possessifs, conjonctions, verbes et noms portent potentiellement le sens.
    private static final Set<String> OPTIONAL_FUNCTION_WORDS = Set.of(
        "d", "de", "des", "du", "l", "la", "le", "les");

    // Certaines flexions de "tel" ne tiennent pas dans une distance d'edition
    // de caractere <= 1, mais restent sures entre formes de 4 caracteres ou plus.
    private static final Set<String> TEL_INFLECTIONS = Set.of(
        "tels", "telle", "telles");

    /**
     * Marques d'HESITATION, elidables du cote PRODUCTION avant appariement, en
     * nombre non borne. Liste fermee, tiree de {@link #NON_SIGNIFICANT} : ce
     * sont les seuls tokens que le pipeline produit et qui ne portent aucun
     * sens (Whisper transcrit en mode litteral, donc il les conserve).
     *
     * <p><b>Pourquoi cette elision ne fragilise pas la garantie « une preuve
     * inventee ou ambigue ne passe pas »</b> : elle ne dispense d'AUCUN token
     * porteur de sens. Tous les autres mots de la citation restent exiges a
     * l'identique, dans le meme ordre, dans un passage contigu et unique. Une
     * citation qui contiendrait un mot absent de la production reste refusee.
     *
     * <p><b>Pourquoi elle etait necessaire</b> : le prompt interdit au
     * correcteur de fonder quoi que ce soit sur les hesitations, et lui demande
     * en meme temps de recopier la production « exactement ». Sans cette
     * elision, trois « euh » intercales suffisaient a faire echouer une
     * citation parfaitement fidele — le correcteur ne pouvait pas satisfaire
     * les deux consignes a la fois.
     *
     * <p><b>Sens unique</b> : production -> citation. On ne retire jamais rien
     * de la citation.
     */
    static final Set<String> DISFLUENCES = Set.of("euh", "heu", "hum");

    /**
     * BEGAIEMENT : longueur maximale, EN TOKENS, d'un bloc que la production peut
     * repeter d'affilee sans que la citation ait a le recopier deux fois.
     *
     * <p>La forme la plus frequente du begaiement a l'oral n'est pas
     * l'hesitation ({@code euh}), c'est le MOT REPETE ({@code tous tous chez
     * moi}), parfois le groupe court repete ({@code les les films les films}).
     * La grille interdit par ailleurs d'evaluer les repetitions ; sans cette
     * elision, le correcteur ne pouvait pas a la fois ignorer le begaiement et
     * recopier « exactement » — deux ou trois suppressions depassent la
     * tolerance d'UNE seule edition de token, et la preuve etait refusee. Cas
     * reel : submission {@code e6f28822}, deux citations justes refusees
     * d'affilee, puis mode degrade.
     *
     * <p>Au-dela de trois tokens, ce n'est plus un begaiement : c'est une reprise
     * de phrase, et on ne l'elide pas.
     */
    private static final int MAX_TOKENS_REPETITION_ELIDABLE = 3;

    /**
     * Nombre maximum de tokens CONSECUTIFS de la production qu'un seul token de
     * la citation peut recoller. La transcription temps reel coupe un mot en
     * deux, parfois en trois (« quatre vingt dou ze ») ; au-dela, ce n'est plus
     * un mot coupe, c'est une recomposition.
     */
    private static final int MAX_FRAGMENTS_RECOLLES = 3;

    /**
     * Blancs HORIZONTAUX admis entre deux fragments d'un meme mot. Un mot coupe
     * par la transcription l'est par une espace inseree au milieu — jamais par
     * une apostrophe, un trait d'union, une ponctuation ou un saut de ligne.
     * Exiger cela interdit de fabriquer un mot en enjambant une frontiere reelle
     * ({@code je pars. Toi} ne peut pas donner {@code parstoi}).
     */
    private static final Pattern BLANCS_HORIZONTAUX = Pattern.compile("[ \\t\\u00A0\\u202F]+");

    private static final Set<String> NON_SIGNIFICANT = Set.of(
        "a", "ai", "au", "aux", "avec", "c", "ce", "ces", "cet", "cette", "d",
        "dans", "de", "des", "du", "elle", "elles", "en", "est", "et", "eux",
        "il", "ils", "j", "je", "l", "la", "le", "les", "leur", "leurs", "lui",
        "m", "ma", "mais", "me", "mes", "moi", "mon", "n", "ne", "ni", "nos",
        "notre", "nous", "on", "ou", "par", "pas", "plus", "pour", "qu", "que",
        "qui", "s", "sa", "sans", "se", "ses", "son", "sont", "sur", "t", "ta",
        "te", "tes", "toi", "ton", "tu", "un", "une", "vos", "votre", "vous", "y",
        "euh", "heu", "hum");

    private EvaluationProofMatcher() {
    }

    /**
     * Retourne le passage original exact si la citation designe un seul endroit.
     * La comparaison exacte normalisee est toujours tentee avant la tolerance
     * d'un unique token.
     *
     * <p><b>Deux lectures, jamais melangees.</b> La premiere lit la production
     * TELLE QUELLE : c'est le comportement historique, au comportement pres
     * inchange. La seconde n'est tentee que si la premiere n'a rien trouve du
     * tout, et elle elide les REPETITIONS IMMEDIATES de la production
     * (begaiements). Cet ordre est ce qui garantit qu'aucune citation acceptee
     * hier ne devient ambigue aujourd'hui : une lecture qui trouve, meme
     * plusieurs fois, arrete la recherche — « en cas de doute, on ne rapproche
     * pas ».
     */
    static Optional<String> canonicalPassage(String production, String citation,
                                             EpreuveType epreuve) {
        if (production == null || production.isBlank() || citation == null || citation.isBlank()) {
            return Optional.empty();
        }

        String citationCandidate = candidateCitation(citation, epreuve);
        if (citationCandidate == null || citationCandidate.isBlank()) return Optional.empty();
        List<Token> needle = tokens(citationCandidate, 0);
        if (needle.isEmpty()) return Optional.empty();

        List<Segment> segments = searchableSegments(production, epreuve);

        Lecture stricte = rechercher(production, segments, needle, false);
        if (stricte.concluante()) return stricte.passage();
        return rechercher(production, segments, needle, true).passage();
    }

    /**
     * Resultat d'UNE lecture. {@code concluante} distingue « je n'ai rien
     * trouve » (on peut tenter la lecture suivante) de « j'ai trouve, mais a
     * plusieurs endroits » (refus definitif : la preuve est ambigue).
     */
    private record Lecture(boolean concluante, Optional<String> passage) {
        private static final Lecture ABSENTE = new Lecture(false, Optional.empty());

        static Lecture trouvee(Set<String> passages) {
            return new Lecture(true, passages.size() == 1
                ? Optional.of(passages.iterator().next())
                : Optional.empty());
        }
    }

    private static Lecture rechercher(String production, List<Segment> segments,
                                      List<Token> needle, boolean elideRepetitions) {
        Set<SourceMatch> exactMatches = new LinkedHashSet<>();
        for (Segment segment : segments) {
            collectExact(production, lecture(segment.tokens(), elideRepetitions), needle, exactMatches);
        }
        if (!exactMatches.isEmpty()) {
            Set<String> exactPassages = new LinkedHashSet<>();
            for (SourceMatch match : exactMatches) exactPassages.add(match.extract(production));
            // Une phrase strictement identique repetee a la meme valeur
            // canonique. Deux graphies originales distinctes seraient en
            // revanche impossibles a canonicaliser sans choisir arbitrairement.
            return Lecture.trouvee(exactPassages);
        }
        if (needle.size() < MIN_FUZZY_TOKENS) return Lecture.ABSENTE;

        Set<SourceMatch> fuzzyMatches = new LinkedHashSet<>();
        for (Segment segment : segments) {
            List<Token> base = lecture(segment.tokens(), elideRepetitions);
            collectFuzzy(base, needle, fuzzyMatches);
            // Seconde lecture du meme segment, hesitations retirees : la
            // tolerance d'UNE edition reste entiere, elle n'est simplement plus
            // consommee par un « euh ». Les offsets restant ceux du texte brut,
            // le passage restitue contient toujours la production originale.
            List<Token> sansHesitations = withoutDisfluences(base);
            if (sansHesitations.size() != base.size()) {
                collectFuzzy(sansHesitations, needle, fuzzyMatches);
            }
        }
        if (fuzzyMatches.isEmpty()) return Lecture.ABSENTE;
        if (fuzzyMatches.size() != 1) return new Lecture(true, Optional.empty());
        return new Lecture(true, Optional.of(fuzzyMatches.iterator().next().extract(production)));
    }

    private static List<Token> lecture(List<Token> tokens, boolean elideRepetitions) {
        return elideRepetitions ? withoutImmediateRepetitions(tokens) : tokens;
    }

    /**
     * BEGAIEMENTS ELIDES : retire les tokens qui REPETENT A L'IDENTIQUE, et
     * immediatement, le bloc qui vient d'etre retenu ({@code tous tous} ->
     * {@code tous}, {@code les les films les films} -> {@code les films}).
     *
     * <p><b>Sens unique</b>, comme l'elision des hesitations et le recollage des
     * mots coupes : la PRODUCTION peut begayer, la citation jamais. Une citation
     * qui inventerait une repetition absente de la production reste refusee, et
     * aucun token porteur de sens n'est dispense — tous les mots de la citation
     * restent exiges, dans le meme ordre, dans un passage contigu et unique.
     *
     * <p><b>L'elision ne consomme pas le budget d'une edition de token</b> : elle
     * se fait avant l'appariement, en nombre non borne. C'est tout l'objet — la
     * tolerance d'UNE edition ne reglait deja pas un mot repete deux fois.
     *
     * <p><b>Ce qui reste immuable</b> : aucun token special (nombre ecrit en
     * lettres, token contenant un chiffre, negation) n'est elidable, meme
     * repete. {@code pas pas} et {@code vingt vingt} restent tels quels — un
     * ecart de nombre ou de negation ne peut pas naitre d'un begaiement.
     *
     * <p><b>Les offsets ne bougent pas</b> : le passage restitue reste la
     * sous-chaine ORIGINALE exacte de la production, begaiements compris. Le
     * candidat lit donc toujours ce qu'il a reellement produit.
     *
     * <p><b>Limite assumee</b> : une repetition LEGITIME ({@code tres tres bien},
     * {@code il faut faire}) est elidable par cette regle, donc une citation qui
     * n'en garde qu'une occurrence est acceptee. C'est sans consequence : le
     * texte affiche au candidat reste le texte reel, et rien ne se note sur une
     * citation.
     */
    private static List<Token> withoutImmediateRepetitions(List<Token> tokens) {
        List<Token> out = new ArrayList<>(tokens.size());
        int i = 0;
        while (i < tokens.size()) {
            int repetes = longueurRepetitionImmediate(out, tokens, i);
            if (repetes > 0) {
                i += repetes;
                continue;
            }
            out.add(tokens.get(i));
            i++;
        }
        return List.copyOf(out);
    }

    /**
     * Nombre de tokens, a partir de {@code from}, qui repetent a l'identique le
     * bloc qui vient d'etre retenu — 0 si aucun. On cherche le bloc le PLUS
     * COURT : {@code tous tous tous} s'elide token par token, {@code les films
     * les films} par bloc de deux.
     */
    private static int longueurRepetitionImmediate(List<Token> retenus, List<Token> tokens, int from) {
        for (int k = 1; k <= MAX_TOKENS_REPETITION_ELIDABLE; k++) {
            if (k > retenus.size() || from + k > tokens.size()) return 0;
            if (blocIdentique(retenus, retenus.size() - k, tokens, from, k)
                    && elidableEnRepetition(tokens, from, k)) {
                return k;
            }
        }
        return 0;
    }

    private static boolean blocIdentique(List<Token> gauche, int debutGauche,
                                         List<Token> droite, int debutDroite, int longueur) {
        for (int i = 0; i < longueur; i++) {
            if (!gauche.get(debutGauche + i).normalized()
                    .equals(droite.get(debutDroite + i).normalized())) {
                return false;
            }
        }
        return true;
    }

    /** Un bloc repete ne s'elide que s'il ne porte ni nombre, ni chiffre, ni negation. */
    private static boolean elidableEnRepetition(List<Token> tokens, int from, int longueur) {
        for (int i = 0; i < longueur; i++) {
            if (isSpecial(tokens.get(from + i).normalized())) return false;
        }
        return true;
    }

    private static String candidateCitation(String citation, EpreuveType epreuve) {
        if (epreuve != EpreuveType.TCF_EO) return citation;
        Matcher marker = CITATION_SPEAKER.matcher(citation);
        if (!marker.find()) return citation;
        if (!"candidat".equalsIgnoreCase(marker.group(1))) return null;
        return citation.substring(marker.end());
    }

    private static List<Segment> searchableSegments(String production, EpreuveType epreuve) {
        if (epreuve != EpreuveType.TCF_EO) {
            return List.of(segment(production, 0, production.length()));
        }

        Matcher matcher = TURN_MARKER.matcher(production);
        List<TurnMarker> markers = new ArrayList<>();
        while (matcher.find()) {
            markers.add(new TurnMarker(matcher.start(), matcher.end(), matcher.group(1)));
        }
        // EO monologuee : sans role explicite, tout le transcript vient du candidat.
        if (markers.isEmpty()) return List.of(segment(production, 0, production.length()));

        List<Segment> out = new ArrayList<>();
        for (int i = 0; i < markers.size(); i++) {
            TurnMarker marker = markers.get(i);
            if (!"candidat".equalsIgnoreCase(marker.speaker())) continue;
            int end = i + 1 < markers.size() ? markers.get(i + 1).start() : production.length();
            Segment candidate = segment(production, marker.contentStart(), end);
            if (!candidate.tokens().isEmpty()) out.add(candidate);
        }
        return out;
    }

    private static Segment segment(String source, int start, int end) {
        return new Segment(tokens(source.substring(start, end), start));
    }

    private static List<Token> tokens(String text, int offset) {
        List<Token> out = new ArrayList<>();
        Matcher matcher = TOKEN.matcher(text);
        while (matcher.find()) {
            String normalized = normalizeToken(matcher.group());
            if (!normalized.isEmpty()) {
                out.add(new Token(normalized, offset + matcher.start(), offset + matcher.end()));
            }
        }
        return List.copyOf(out);
    }

    private static String normalizeToken(String raw) {
        String compatible = Normalizer.normalize(raw, Normalizer.Form.NFKC)
            .toLowerCase(Locale.FRENCH)
            .replace("œ", "oe")
            .replace("æ", "ae");
        return Normalizer.normalize(compatible, Normalizer.Form.NFD)
            .replaceAll("\\p{M}+", "");
    }

    private static void collectExact(String production, List<Token> source, List<Token> needle,
                                     Set<SourceMatch> matches) {
        // Un match consomme AU MOINS un token source par token de la citation
        // (l'elision et le recollage n'en consomment que davantage).
        if (source.size() < needle.size()) return;
        for (int start = 0; start <= source.size() - needle.size(); start++) {
            int end = alignFrom(production, source, start, needle);
            if (end > start) addMatch(source, start, end - start, matches);
        }
    }

    /**
     * Aligne la citation sur la production a partir de {@code start} et retourne
     * l'index de fin (exclusif) du passage, ou {@code -1}.
     *
     * <p>Chaque token de la citation doit trouver son identique ; seule la
     * PRODUCTION peut fournir des tokens en trop, et uniquement s'ils sont des
     * {@link #DISFLUENCES}. Le passage commence et se termine donc toujours sur
     * un token reellement cite : une hesitation ne peut ni ouvrir ni fermer une
     * preuve, ce qui garde un seul span possible par point de depart.
     *
     * <p>Un token de la citation peut en revanche recoller PLUSIEURS tokens
     * consecutifs de la production (cf. {@link #longueurRecollee}) : la
     * transcription temps reel coupe des mots en deux, la citation ne le fait
     * pas. Meme sens unique que l'elision des hesitations.
     */
    private static int alignFrom(String production, List<Token> source, int start,
                                 List<Token> needle) {
        int i = start;
        int j = 0;
        while (j < needle.size()) {
            if (i >= source.size()) return -1;
            String s = source.get(i).normalized();
            if (s.equals(needle.get(j).normalized())) {
                i++;
                j++;
                continue;
            }
            if (i > start && DISFLUENCES.contains(s)) {
                i++;
                continue;
            }
            int fragments = longueurRecollee(production, source, i, needle.get(j).normalized());
            if (fragments > 0) {
                i += fragments;
                j++;
                continue;
            }
            return -1;
        }
        return i;
    }

    /**
     * MOT COUPE PAR LA TRANSCRIPTION. Retourne le nombre de tokens consecutifs
     * de la production, a partir de {@code from}, dont la concatenation vaut
     * EXACTEMENT {@code cible} — 0 si aucun recollage sur ne serait-ce qu'un
     * doute.
     *
     * <p><b>Sens unique, comme l'elision des hesitations</b> : la production peut
     * etre coupee (« j'ai ach ete cette ves te »), la citation jamais. On ne
     * decoupe aucun token de la production, ce qui exclut par construction la
     * fusion abusive {@code les tuteurs} ⇄ {@code lest uteurs} : ni « les » ne
     * peut absorber une partie de « lest », ni « lest » se rassembler a partir de
     * « les tuteurs » (la concatenation deborderait la cible).
     *
     * <p><b>Ce que le recollage ne change pas</b> : toutes les lettres de la
     * citation restent presentes, contigues, dans le meme ordre, dans un passage
     * unique ; le passage restitue reste la sous-chaine ORIGINALE exacte de la
     * production, coupures comprises.
     *
     * <p><b>En cas de doute, on ne fusionne pas</b> — quatre garde-fous :
     * <ol>
     *   <li>trois fragments au maximum ({@link #MAX_FRAGMENTS_RECOLLES}) ;</li>
     *   <li>seuls des BLANCS HORIZONTAUX separent deux fragments : jamais une
     *       apostrophe, un trait d'union, une ponctuation ni un saut de ligne —
     *       sinon {@code je pars. Toi aussi} fabriquerait {@code parstoi} ;</li>
     *   <li>aucun fragment n'est un {@link #isSpecial special} (nombre, token
     *       chiffre, negation) ni une hesitation : sans cette regle,
     *       {@code il n'est pas sage} rendrait citable {@code passage} — la
     *       negation aurait disparu — et {@code j'ai paye 20 26 euros} rendrait
     *       citable {@code 2026} ;</li>
     *   <li>le mot recolle lui-meme n'est ni une NEGATION ni un token chiffre :
     *       personne ne fabrique une negation en recollant deux fragments. Les
     *       nombres ECRITS EN LETTRES, eux, restent recollables
     *       ({@code pre mier} → {@code premier}, {@code dou ze} → {@code douze})
     *       — le fragment source, lui, est deja protege.</li>
     * </ol>
     */
    private static int longueurRecollee(String production, List<Token> source, int from,
                                        String cible) {
        if (NEGATIONS.contains(cible) || DISFLUENCES.contains(cible) || contientUnChiffre(cible)) {
            return 0;
        }
        String premier = source.get(from).normalized();
        if (interditAuRecollage(premier)) return 0;
        if (cible.length() <= premier.length() || !cible.startsWith(premier)) return 0;

        StringBuilder recolle = new StringBuilder(premier);
        for (int k = 1; k < MAX_FRAGMENTS_RECOLLES && from + k < source.size(); k++) {
            Token precedent = source.get(from + k - 1);
            Token suivant = source.get(from + k);
            if (!blancsHorizontauxSeuls(production, precedent.end(), suivant.start())) return 0;
            if (interditAuRecollage(suivant.normalized())) return 0;
            recolle.append(suivant.normalized());
            if (recolle.length() > cible.length()) return 0;
            if (cible.contentEquals(recolle)) return k + 1;
            if (!cible.startsWith(recolle.toString())) return 0;
        }
        return 0;
    }

    private static boolean interditAuRecollage(String token) {
        return isSpecial(token) || DISFLUENCES.contains(token);
    }

    private static boolean blancsHorizontauxSeuls(String production, int debut, int fin) {
        if (fin <= debut) return false;
        return BLANCS_HORIZONTAUX.matcher(production.substring(debut, fin)).matches();
    }

    private static List<Token> withoutDisfluences(List<Token> tokens) {
        List<Token> out = new ArrayList<>(tokens.size());
        for (Token token : tokens) {
            if (!DISFLUENCES.contains(token.normalized())) out.add(token);
        }
        return List.copyOf(out);
    }

    private static void collectFuzzy(List<Token> source, List<Token> needle,
                                     Set<SourceMatch> matches) {
        for (int length = needle.size() - 1; length <= needle.size() + 1; length++) {
            if (length <= 0 || source.size() < length) continue;
            for (int start = 0; start <= source.size() - length; start++) {
                List<Token> window = source.subList(start, start + length);
                if (isConservativeOneEditMatch(window, needle)) {
                    addMatch(source, start, length, matches);
                }
            }
        }
    }

    private static boolean isConservativeOneEditMatch(List<Token> source, List<Token> citation) {
        if (!specialTokens(source).equals(specialTokens(citation))) return false;

        Alignment alignment;
        if (source.size() == citation.size()) {
            int mismatch = -1;
            for (int i = 0; i < source.size(); i++) {
                if (source.get(i).normalized().equals(citation.get(i).normalized())) continue;
                if (mismatch >= 0) return false;
                mismatch = i;
            }
            if (mismatch < 0
                || !isExplicitInflection(source.get(mismatch), citation.get(mismatch))) {
                return false;
            }
            alignment = new Alignment(mismatch, mismatch);
        } else if (source.size() == citation.size() + 1) {
            int insertion = oneExtraTokenIndex(source, citation);
            if (insertion < 0
                || !OPTIONAL_FUNCTION_WORDS.contains(source.get(insertion).normalized())) {
                return false;
            }
            alignment = new Alignment(insertion, -1);
        } else if (citation.size() == source.size() + 1) {
            int deletion = oneExtraTokenIndex(citation, source);
            if (deletion < 0
                || !OPTIONAL_FUNCTION_WORDS.contains(citation.get(deletion).normalized())) {
                return false;
            }
            alignment = new Alignment(-1, deletion);
        } else {
            return false;
        }

        return identicalSignificantTokens(source, citation, alignment)
            >= MIN_IDENTICAL_SIGNIFICANT_TOKENS;
    }

    /** Index de l'unique token en trop dans {@code longer}, -1 sinon. */
    private static int oneExtraTokenIndex(List<Token> longer, List<Token> shorter) {
        int i = 0;
        int j = 0;
        int extra = -1;
        while (i < longer.size() && j < shorter.size()) {
            if (longer.get(i).normalized().equals(shorter.get(j).normalized())) {
                i++;
                j++;
                continue;
            }
            if (extra >= 0) return -1;
            extra = i++;
        }
        if (i < longer.size()) {
            if (extra >= 0 || i != longer.size() - 1) return -1;
            extra = i;
        }
        return extra;
    }

    private static boolean isExplicitInflection(Token source, Token citation) {
        String a = source.normalized();
        String b = citation.normalized();
        // Sans analyse lexicale, meme une edition minime peut changer le sens
        // (cour/cours, ville/villa, voie/voix). Seule la flexion dont le besoin
        // est explicitement connu est donc admise.
        return !isSpecial(a) && !isSpecial(b)
            && TEL_INFLECTIONS.contains(a) && TEL_INFLECTIONS.contains(b);
    }

    private static int identicalSignificantTokens(List<Token> source, List<Token> citation,
                                                   Alignment alignment) {
        int sourceIndex = 0;
        int citationIndex = 0;
        int identical = 0;
        while (sourceIndex < source.size() && citationIndex < citation.size()) {
            if (sourceIndex == alignment.skippedSource()) {
                sourceIndex++;
                continue;
            }
            if (citationIndex == alignment.skippedCitation()) {
                citationIndex++;
                continue;
            }
            String sourceToken = source.get(sourceIndex).normalized();
            String citationToken = citation.get(citationIndex).normalized();
            if (sourceToken.equals(citationToken) && isSignificant(sourceToken)) identical++;
            sourceIndex++;
            citationIndex++;
        }
        return identical;
    }

    private static boolean isSignificant(String token) {
        return token.length() > 1 && !NON_SIGNIFICANT.contains(token) && !isSpecial(token);
    }

    /**
     * Nombre de tokens PORTEURS DE SENS d'un texte : mots-outils, hesitations et
     * lettres elidees ({@code l'}, {@code qu'}) exclus.
     *
     * <p>Sert a {@link EvaluationOralArtifactFilter} pour reconnaitre une
     * citation qui ne nomme qu'UN SEUL mot ({@code « l'ile »},
     * {@code « par travers »}) — c'est-a-dire un reproche de niveau MOT, que les
     * rubriques interdisent deja a l'oral. La tokenisation et la liste de
     * mots-outils sont celles du controle de preuve, volontairement : les deux
     * doivent lire un passage de la meme facon.
     */
    static int significantTokenCount(String text) {
        return significantTokens(text).size();
    }

    /**
     * Tokens PORTEURS DE SENS d'un texte, NORMALISES, dans l'ordre.
     *
     * <p>Meme lecture que {@link #significantTokenCount(String)}, dont elle est
     * l'implementation : ce sont deux vues d'un seul decoupage, pas deux
     * decoupages. Elle sert a {@link EvaluationOralForme} pour comparer deux
     * formulations d'un meme enonce — savoir COMBIEN de mots pleins les separent
     * demande la liste, pas seulement un total.
     */
    static List<String> significantTokens(String text) {
        if (text == null || text.isBlank()) return List.of();
        List<String> out = new ArrayList<>();
        for (Token token : tokens(text, 0)) {
            if (isSignificant(token.normalized())) out.add(token.normalized());
        }
        return out;
    }

    private static List<String> specialTokens(List<Token> tokens) {
        List<String> out = new ArrayList<>();
        for (Token token : tokens) {
            if (isSpecial(token.normalized())) out.add(token.normalized());
        }
        return out;
    }

    private static boolean isSpecial(String token) {
        return isNumericMarker(token) || NEGATIONS.contains(token);
    }

    private static boolean isNumericMarker(String token) {
        return NUMBER_WORDS.contains(token) || contientUnChiffre(token);
    }

    private static boolean contientUnChiffre(String token) {
        for (int i = 0; i < token.length(); i++) {
            if (Character.isDigit(token.charAt(i))) return true;
        }
        return false;
    }

    private static void addMatch(List<Token> source, int start, int length,
                                 Set<SourceMatch> matches) {
        Token first = source.get(start);
        Token last = source.get(start + length - 1);
        matches.add(new SourceMatch(first.start(), last.end()));
    }

    private record Token(String normalized, int start, int end) {
    }

    private record Segment(List<Token> tokens) {
    }

    private record TurnMarker(int start, int contentStart, String speaker) {
    }

    /** -1 signifie qu'aucun token n'est saute de ce cote. */
    private record Alignment(int skippedSource, int skippedCitation) {
    }

    private record SourceMatch(int start, int end) {
        String extract(String source) {
            return source.substring(start, end);
        }
    }
}
