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
    private static final Pattern TURN_MARKER = Pattern.compile(
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
    private static final Set<String> DISFLUENCES = Set.of("euh", "heu", "hum");

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
        Set<SourceMatch> exactMatches = new LinkedHashSet<>();
        for (Segment segment : segments) {
            collectExact(segment.tokens(), needle, exactMatches);
        }
        if (!exactMatches.isEmpty()) {
            Set<String> exactPassages = new LinkedHashSet<>();
            for (SourceMatch match : exactMatches) exactPassages.add(match.extract(production));
            // Une phrase strictement identique repetee a la meme valeur
            // canonique. Deux graphies originales distinctes seraient en
            // revanche impossibles a canonicaliser sans choisir arbitrairement.
            if (exactPassages.size() == 1) return Optional.of(exactPassages.iterator().next());
            return Optional.empty();
        }
        if (needle.size() < MIN_FUZZY_TOKENS) return Optional.empty();

        Set<SourceMatch> fuzzyMatches = new LinkedHashSet<>();
        for (Segment segment : segments) {
            collectFuzzy(segment.tokens(), needle, fuzzyMatches);
            // Seconde lecture du meme segment, hesitations retirees : la
            // tolerance d'UNE edition reste entiere, elle n'est simplement plus
            // consommee par un « euh ». Les offsets restant ceux du texte brut,
            // le passage restitue contient toujours la production originale.
            List<Token> sansHesitations = withoutDisfluences(segment.tokens());
            if (sansHesitations.size() != segment.tokens().size()) {
                collectFuzzy(sansHesitations, needle, fuzzyMatches);
            }
        }
        if (fuzzyMatches.size() != 1) return Optional.empty();
        return Optional.of(fuzzyMatches.iterator().next().extract(production));
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

    private static void collectExact(List<Token> source, List<Token> needle,
                                     Set<SourceMatch> matches) {
        if (source.size() < needle.size()) return;
        for (int start = 0; start <= source.size() - needle.size(); start++) {
            int end = alignFrom(source, start, needle);
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
     */
    private static int alignFrom(List<Token> source, int start, List<Token> needle) {
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
            return -1;
        }
        return i;
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
        if (text == null || text.isBlank()) return 0;
        int count = 0;
        for (Token token : tokens(text, 0)) {
            if (isSignificant(token.normalized())) count++;
        }
        return count;
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
        if (NUMBER_WORDS.contains(token)) return true;
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
