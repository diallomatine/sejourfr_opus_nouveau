package com.sejourfr.app.calibration;

import java.text.Normalizer;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;

/**
 * Metriques du banc : accord de niveau, severite de la note, matrice de
 * confusion, pieges, confiance, accomplissement, conformite de sortie et
 * stabilite inter-passes.
 *
 * <p><b>Convention de signe (celle du backend</b>, cf.
 * {@code AdminCalibrationService.computeEcart} et
 * {@code human_calibration_notes.ecart_note}) : tout ecart vaut
 * {@code reference - IA}. Un ecart <b>negatif</b> signifie que l'IA note
 * au-dessus de la reference, donc qu'elle est <b>trop indulgente</b> ; un ecart
 * positif, qu'elle est trop severe. Vaut aussi pour l'ecart de niveau.
 *
 * <p>Toutes les moyennes se calculent sur les runs <b>exploitables</b> (une
 * note et un niveau ont ete produits, court-circuit de validite inclus : c'est
 * une reponse du systeme, pas une panne). Les appels en erreur et les sorties
 * non conformes sont comptes a part.
 */
final class CalibrationMetrics {

    static final List<String> NIVEAUX =
        List.of("A1_NON_ATTEINT", "A1", "A2", "B1", "B2", "C1", "C2");

    /** Mots vides ecartes avant le rapprochement des points oublies. */
    private static final Set<String> VIDES = Set.of(
        "le", "la", "les", "un", "une", "des", "du", "de", "au", "aux", "et", "ou", "a",
        "en", "dans", "sur", "pour", "par", "avec", "sans", "que", "qui", "se", "sa",
        "son", "ses", "leur", "il", "elle", "on", "ce", "cet", "cette", "est", "sont",
        "ne", "pas", "plus", "y", "d", "l");

    private CalibrationMetrics() {
    }

    // ------------------------------------------------------------------ agregats

    record Agregat(
        String label,
        int cas,
        int exploitables,
        int accordExact,
        int accordTolerance,
        int noteDansFourchette,
        double ecartCentreMoyen,
        double ecartFourchetteMoyen,
        double ecartNiveauMoyen) {

        double pctExact() {
            return pct(accordExact, exploitables);
        }

        double pctTolerance() {
            return pct(accordTolerance, exploitables);
        }

        double pctFourchette() {
            return pct(noteDansFourchette, exploitables);
        }
    }

    static double pct(int num, int den) {
        return den == 0 ? 0.0 : 100.0 * num / den;
    }

    static Agregat agregat(String label, List<CaseRun> runs) {
        List<CaseRun> ok = runs.stream().filter(CaseRun::exploitable).toList();
        int exact = 0;
        int tol = 0;
        int fourchette = 0;
        double sommeCentre = 0;
        double sommeFourchette = 0;
        double sommeNiveau = 0;
        for (CaseRun r : ok) {
            if (r.accordExact()) exact++;
            if (r.accordTolerance()) tol++;
            if (r.noteDansFourchette()) fourchette++;
            sommeCentre += r.ecartCentre();
            sommeFourchette += r.ecartFourchette();
            sommeNiveau += NIVEAUX.indexOf(r.niveauAttendu()) - NIVEAUX.indexOf(r.niveauObtenu());
        }
        int n = Math.max(ok.size(), 1);
        return new Agregat(label, runs.size(), ok.size(), exact, tol, fourchette,
            sommeCentre / n, sommeFourchette / n, sommeNiveau / n);
    }

    static List<Agregat> parGroupe(List<CaseRun> runs) {
        Map<String, List<CaseRun>> parGroupe = new TreeMap<>();
        for (CaseRun r : runs) parGroupe.computeIfAbsent(r.groupe(), k -> new ArrayList<>()).add(r);
        return parGroupe.entrySet().stream().map(e -> agregat(e.getKey(), e.getValue())).toList();
    }

    static List<Agregat> parNiveauAttendu(List<CaseRun> runs) {
        Map<String, List<CaseRun>> parNiveau = new LinkedHashMap<>();
        for (String niv : NIVEAUX) {
            List<CaseRun> l = runs.stream().filter(r -> niv.equals(r.niveauAttendu())).toList();
            if (!l.isEmpty()) parNiveau.put(niv, l);
        }
        return parNiveau.entrySet().stream().map(e -> agregat(e.getKey(), e.getValue())).toList();
    }

    /** Matrice {@code niveau attendu -> niveau obtenu -> effectif}. */
    static Map<String, Map<String, Integer>> confusion(List<CaseRun> runs) {
        Map<String, Map<String, Integer>> out = new LinkedHashMap<>();
        for (CaseRun r : runs) {
            if (!r.exploitable()) continue;
            out.computeIfAbsent(r.niveauAttendu(), k -> new LinkedHashMap<>())
                .merge(r.niveauObtenu(), 1, Integer::sum);
        }
        return out;
    }

    // -------------------------------------------------------------------- pieges

    /**
     * Verdict d'un cas piege. {@code sens} dit dans quel sens le systeme derape :
     * {@code SUR} = il est tombe dans le piege par indulgence (au-dessus de la
     * reference), {@code SOUS} = par severite.
     */
    record PiegeResultat(
        String casId,
        List<String> pieges,
        String niveauAttendu,
        String niveauObtenu,
        double noteMin,
        double noteMax,
        Double note,
        boolean niveauDansTolerance,
        boolean noteDansFourchette,
        boolean evite,
        String sens,
        String confianceAttendue,
        String confianceObtenue) {
    }

    static List<PiegeResultat> pieges(List<CaseRun> runs) {
        List<PiegeResultat> out = new ArrayList<>();
        for (CaseRun r : runs) {
            if (r.pieges().isEmpty()) continue;
            boolean tol = r.accordTolerance();
            boolean fourchette = r.noteDansFourchette();
            Double ecart = r.ecartFourchette();
            String sens = "-";
            if (!r.exploitable()) {
                sens = "NON_MESURE";
            } else if (!tol || !fourchette) {
                // Convention reference - IA : un signal negatif = l'IA est au-dessus.
                int deltaNiveau = r.niveauObtenu() == null ? 0
                    : NIVEAUX.indexOf(r.niveauAttendu()) - NIVEAUX.indexOf(r.niveauObtenu());
                double signal = deltaNiveau != 0 ? deltaNiveau : (ecart == null ? 0 : ecart);
                sens = signal < 0 ? "SUR" : "SOUS";
            }
            out.add(new PiegeResultat(r.casId(), r.pieges(), r.niveauAttendu(), r.niveauObtenu(),
                r.noteMin(), r.noteMax(), r.note(), tol, fourchette, tol && fourchette, sens,
                r.confianceAttendue(), r.confianceObtenue()));
        }
        out.sort(Comparator.comparing(PiegeResultat::casId));
        return out;
    }

    // ------------------------------------------------------------------ confiance

    record ConfianceResultat(int evalues, int accord, int plusSur, int moinsSur) {
        double pctAccord() {
            return pct(accord, evalues);
        }
    }

    /** Ordre de certitude decroissante : HAUTE > MOYENNE > FAIBLE. */
    private static int rang(String confiance) {
        return switch (confiance == null ? "" : confiance) {
            case "HAUTE" -> 2;
            case "MOYENNE" -> 1;
            case "FAIBLE" -> 0;
            default -> -1;
        };
    }

    static ConfianceResultat confiance(List<CaseRun> runs) {
        int evalues = 0;
        int accord = 0;
        int plusSur = 0;
        int moinsSur = 0;
        for (CaseRun r : runs) {
            int attendu = rang(r.confianceAttendue());
            int obtenu = rang(r.confianceObtenue());
            if (attendu < 0 || obtenu < 0) continue;
            evalues++;
            if (attendu == obtenu) accord++;
            else if (obtenu > attendu) plusSur++;
            else moinsSur++;
        }
        return new ConfianceResultat(evalues, accord, plusSur, moinsSur);
    }

    // ------------------------------------------------------------- accomplissement

    record AccomplissementResultat(
        int casAvecBloc,
        int accordObligatoire,
        int pointsAttendus,
        int pointsDetectes,
        List<String> casSansDetection) {

        double pctAccordObligatoire() {
            return pct(accordObligatoire, casAvecBloc);
        }

        double rappelPoints() {
            return pct(pointsDetectes, pointsAttendus);
        }
    }

    static AccomplissementResultat accomplissement(List<CaseRun> runs) {
        int casAvecBloc = 0;
        int accord = 0;
        int attendus = 0;
        int detectes = 0;
        List<String> rates = new ArrayList<>();
        for (CaseRun r : runs) {
            if (r.obligatoireTraiteObtenu() != null) {
                casAvecBloc++;
                if (r.obligatoireTraiteObtenu().equals(r.obligatoireTraiteAttendu())) accord++;
            }
            if (r.pointsOubliesAttendus().isEmpty()) continue;
            int localDetectes = 0;
            for (String attendu : r.pointsOubliesAttendus()) {
                attendus++;
                if (detecte(attendu, r.pointsOubliesObtenus())) {
                    detectes++;
                    localDetectes++;
                }
            }
            if (localDetectes == 0) rates.add(r.casId());
        }
        return new AccomplissementResultat(casAvecBloc, accord, attendus, detectes, List.copyOf(rates));
    }

    /**
     * Rapprochement lexical tolerant entre un point oublie attendu et ceux
     * annonces par l'IA : au moins la moitie des mots significatifs (racine de
     * 4 lettres) doit se retrouver dans un meme libelle. Approximation assumee.
     */
    static boolean detecte(String attendu, List<String> obtenus) {
        Set<String> cible = racines(attendu);
        if (cible.isEmpty()) return false;
        for (String candidat : obtenus) {
            Set<String> mots = racines(candidat);
            long hits = cible.stream().filter(mots::contains).count();
            if (hits * 2 >= cible.size()) return true;
        }
        return false;
    }

    private static Set<String> racines(String texte) {
        if (texte == null) return Set.of();
        String plat = Normalizer.normalize(texte, Normalizer.Form.NFD)
            .replaceAll("\\p{M}+", "")
            .toLowerCase(Locale.FRENCH)
            .replaceAll("[^a-z0-9]+", " ")
            .strip();
        Set<String> out = new LinkedHashSet<>();
        if (plat.isEmpty()) return out;
        for (String mot : plat.split("\\s+")) {
            if (mot.length() < 3 || VIDES.contains(mot)) continue;
            out.add(mot.length() > 4 ? mot.substring(0, 4) : mot);
        }
        return out;
    }

    // ------------------------------------------------------------------ stabilite

    record Stabilite(String casId, double noteMin, double noteMax, int niveauxDistincts, List<String> niveaux) {
        double amplitude() {
            return noteMax - noteMin;
        }
    }

    static List<Stabilite> stabilite(List<CaseRun> runs) {
        Map<String, List<CaseRun>> parCas = new LinkedHashMap<>();
        for (CaseRun r : runs) {
            if (r.exploitable()) parCas.computeIfAbsent(r.casId(), k -> new ArrayList<>()).add(r);
        }
        List<Stabilite> out = new ArrayList<>();
        for (Map.Entry<String, List<CaseRun>> e : parCas.entrySet()) {
            if (e.getValue().size() < 2) continue;
            double min = e.getValue().stream().mapToDouble(CaseRun::note).min().orElse(0);
            double max = e.getValue().stream().mapToDouble(CaseRun::note).max().orElse(0);
            List<String> niveaux = e.getValue().stream().map(CaseRun::niveauObtenu).toList();
            out.add(new Stabilite(e.getKey(), min, max, new LinkedHashSet<>(niveaux).size(), niveaux));
        }
        out.sort(Comparator.comparingDouble(Stabilite::amplitude).reversed()
            .thenComparing(Stabilite::casId));
        return out;
    }

    // ------------------------------------------------------------------ conformite

    /**
     * MOTIF pour lequel un cas n'a pas pu etre mesure. Sans cette ventilation,
     * toute perte tombait indistinctement dans {@code erreurAppel} pendant que
     * le rapport annoncait « 0 % de sortie invalide » : la metrique publiee
     * rendait son propre defaut invisible.
     */
    enum MotifPerte {
        /** Sortie coupee par le plafond de tokens : JSON tronque, illisible. */
        TRONCATURE_JSON,
        /** Une citation n'a pas pu etre rattachee a la production, meme apres reessai. */
        REJET_PREUVE,
        /** Le feedback oral se fondait sur un element non evaluable (hesitations, debit...). */
        GARDE_FOU_ORAL,
        /**
         * 429, 5xx ou timeout du fournisseur, retries epuises : perte SUBIE, pas
         * un defaut de notation. A distinguer des autres motifs, sinon un banc
         * bride par le fournisseur se lit comme une regression de qualite.
         */
        FOURNISSEUR_INDISPONIBLE,
        /** Reponse structurellement incomplete : un champ requis du contrat manque. */
        SORTIE_INCOMPLETE,
        AUTRE
    }

    /** Motif de perte d'un cas non mesure, {@code null} si le cas a bien ete mesure. */
    static MotifPerte motifPerte(CaseRun run) {
        if (run.exploitable()) return null;
        if ("SORTIE_INVALIDE".equals(run.statut())) return MotifPerte.SORTIE_INCOMPLETE;
        String erreur = run.erreur() == null ? "" : run.erreur().toLowerCase(Locale.ROOT);
        if (erreur.contains("non desorialisable") || erreur.contains("finish_reason=length")
            || erreur.contains("tool_call.arguments vide")) {
            return MotifPerte.TRONCATURE_JSON;
        }
        if (erreur.contains("doit citer un passage reel")) return MotifPerte.REJET_PREUVE;
        if (erreur.contains("element non evaluable")) return MotifPerte.GARDE_FOU_ORAL;
        if (erreur.contains("429") || erreur.contains("rate-limited")
            || erreur.contains("indisponible apres") || erreur.contains("timeout")
            || erreur.contains("5xx")) {
            return MotifPerte.FOURNISSEUR_INDISPONIBLE;
        }
        return MotifPerte.AUTRE;
    }

    /**
     * @param appels          appels LLM reellement emis (retries compris)
     * @param appelsRates     appels dont la reponse etait inexploitable — en
     *                        production, chacun fait echouer une soumission
     * @param casPerdus       cas qu'aucune tentative n'a permis de mesurer
     * @param casNonMesures   cas absents des agregats, quelle qu'en soit la
     *                        cause ({@code casPerdus} + sorties incompletes)
     * @param motifsPerte     ventilation des {@code casNonMesures} par cause,
     *                        dans l'ordre de {@link MotifPerte}. Un cas perdu
     *                        coute exactement autant qu'une sortie invalide a un
     *                        utilisateur : les deux taux se lisent cote a cote.
     */
    record Conformite(int total, int ok, int validiteServeur, int sortieInvalide, int erreurAppel,
                      int criteresManquants, int appels, int appelsRates, int casPerdus,
                      int casAvecReessai, int casNonMesures, Map<String, Integer> motifsPerte) {

        /** Taux de sorties invalides du modele, par appel. */
        double pctAppelsRates() {
            return pct(appelsRates, appels);
        }

        /** Taux de cas irrecuperables meme apres reessai. */
        double pctCasPerdus() {
            return pct(casPerdus, total);
        }

        /** Taux de runs dont la sortie etait structurellement incomplete. */
        double pctSortieInvalide() {
            return pct(sortieInvalide, total);
        }

        /** Taux de cas absents des agregats, toutes causes confondues. */
        double pctCasNonMesures() {
            return pct(casNonMesures, total);
        }

        int motif(MotifPerte motif) {
            return motifsPerte.getOrDefault(motif.name(), 0);
        }
    }

    static Conformite conformite(List<CaseRun> runs) {
        int ok = 0;
        int validite = 0;
        int invalide = 0;
        int erreur = 0;
        int criteres = 0;
        int appels = 0;
        int rates = 0;
        int reessais = 0;
        Map<String, Integer> motifs = new LinkedHashMap<>();
        for (MotifPerte motif : MotifPerte.values()) motifs.put(motif.name(), 0);
        int nonMesures = 0;
        for (CaseRun r : runs) {
            switch (r.statut()) {
                case "OK" -> ok++;
                case "VALIDITE_SERVEUR" -> validite++;
                case "SORTIE_INVALIDE" -> invalide++;
                default -> erreur++;
            }
            MotifPerte motif = motifPerte(r);
            if (motif != null) {
                motifs.merge(motif.name(), 1, Integer::sum);
                nonMesures++;
            }
            if (!r.criteresManquants().isEmpty()) criteres++;
            appels += r.tentatives();
            rates += r.tentativesRatees();
            if (r.tentativesRatees() > 0) reessais++;
        }
        return new Conformite(runs.size(), ok, validite, invalide, erreur, criteres,
            appels, rates, erreur, reessais, nonMesures,
            java.util.Collections.unmodifiableMap(motifs));
    }

    static int coutTotalCentimes(List<CaseRun> runs) {
        return runs.stream().mapToInt(r -> r.coutCentimes() == null ? 0 : r.coutCentimes()).sum();
    }
}
