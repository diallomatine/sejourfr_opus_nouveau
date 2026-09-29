package com.sejourfr.app.calibration;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.TreeMap;

/**
 * Metriques du banc « Competences TCF ».
 *
 * <p>Jumelle de {@link CalibrationMetrics}, avec deux differences de fond :
 * <ul>
 *   <li><b>aucune note</b>. Le module n'en produit pas, donc il n'y a ni ecart
 *       de points, ni fourchette. Ce qui se mesure, c'est le <b>palier</b> et le
 *       <b>verdict de critere</b> ;</li>
 *   <li>une metrique de <b>sensibilite</b> qui n'existe pas cote productions
 *       completes, parce que c'est LA question de ce dossier : sur un meme sujet,
 *       deux productions de qualites differentes recoivent-elles des paliers
 *       differents ? Mesure en base avant ce banc : 0 B2 sur 18 tentatives, et
 *       deux productions manifestement inegales notees toutes deux A2.</li>
 * </ul>
 *
 * <p><b>Convention de signe</b>, celle du depot : tout ecart vaut
 * {@code reference - IA}. Negatif = l'IA situe le candidat au-dessus de la
 * reference (trop haut), positif = trop bas.
 *
 * <p><b>Les temoins reels ne comptent jamais.</b> Toutes les fonctions de ce
 * fichier filtrent sur {@link CompetenceCaseRun#exploitable()}, qui exclut deja
 * {@code horsScore} : une ligne sans verite terrain ne peut pas peser sur un
 * taux d'accord.
 */
final class CompetenceCalibrationMetrics {

    /** Profil TCF IRN : C1 et C2 n'existent pas dans ce module. */
    static final List<String> NIVEAUX = List.of("A1_NON_ATTEINT", "A1", "A2", "B1", "B2");

    static final List<String> STATUTS = List.of("VALIDATED", "PARTIAL", "NOT_VALIDATED");

    private CompetenceCalibrationMetrics() {
    }

    static double pct(int num, int den) {
        return den == 0 ? 0.0 : 100.0 * num / den;
    }

    // ------------------------------------------------------------------ agregats

    record Agregat(
        String label,
        int cas,
        int exploitables,
        int accordExactNiveau,
        int accordToleranceNiveau,
        int accordStatut,
        int accordExactStatut,
        double ecartNiveauMoyen) {

        double pctExactNiveau() {
            return pct(accordExactNiveau, exploitables);
        }

        double pctToleranceNiveau() {
            return pct(accordToleranceNiveau, exploitables);
        }

        double pctStatut() {
            return pct(accordStatut, exploitables);
        }

        double pctExactStatut() {
            return pct(accordExactStatut, exploitables);
        }
    }

    static Agregat agregat(String label, List<CompetenceCaseRun> runs) {
        List<CompetenceCaseRun> ok = runs.stream().filter(CompetenceCaseRun::exploitable).toList();
        int exact = 0;
        int tol = 0;
        int statut = 0;
        int statutExact = 0;
        double somme = 0;
        for (CompetenceCaseRun r : ok) {
            if (r.accordExactNiveau()) exact++;
            if (r.accordToleranceNiveau()) tol++;
            if (r.accordStatut()) statut++;
            if (r.accordExactStatut()) statutExact++;
            Integer e = r.ecartNiveau();
            if (e != null) somme += e;
        }
        int n = Math.max(ok.size(), 1);
        return new Agregat(label, comptables(runs), ok.size(), exact, tol, statut, statutExact, somme / n);
    }

    /** Cas qui AURAIENT du entrer dans l'agregat : les temoins n'en font pas partie. */
    private static int comptables(List<CompetenceCaseRun> runs) {
        return (int) runs.stream().filter(r -> !r.horsScore()).count();
    }

    static List<Agregat> parTache(List<CompetenceCaseRun> runs) {
        Map<String, List<CompetenceCaseRun>> parGroupe = new TreeMap<>();
        for (CompetenceCaseRun r : runs) {
            if (r.horsScore()) continue;
            parGroupe.computeIfAbsent(r.groupe(), k -> new ArrayList<>()).add(r);
        }
        return parGroupe.entrySet().stream().map(e -> agregat(e.getKey(), e.getValue())).toList();
    }

    static List<Agregat> parNiveauAttendu(List<CompetenceCaseRun> runs) {
        List<Agregat> out = new ArrayList<>();
        for (String niv : NIVEAUX) {
            List<CompetenceCaseRun> l = runs.stream()
                .filter(r -> !r.horsScore() && niv.equals(r.niveauAttendu())).toList();
            if (!l.isEmpty()) out.add(agregat(niv, l));
        }
        return List.copyOf(out);
    }

    /** Matrice {@code palier attendu -> palier obtenu -> effectif}. */
    static Map<String, Map<String, Integer>> confusionNiveau(List<CompetenceCaseRun> runs) {
        return confusion(runs, CompetenceCaseRun::niveauAttendu, CompetenceCaseRun::niveauObtenu);
    }

    /** Matrice {@code verdict attendu -> verdict obtenu -> effectif}. */
    static Map<String, Map<String, Integer>> confusionStatut(List<CompetenceCaseRun> runs) {
        return confusion(runs, CompetenceCaseRun::statutAttendu, CompetenceCaseRun::statutObtenu);
    }

    private static Map<String, Map<String, Integer>> confusion(
        List<CompetenceCaseRun> runs,
        java.util.function.Function<CompetenceCaseRun, String> attendu,
        java.util.function.Function<CompetenceCaseRun, String> obtenu) {
        Map<String, Map<String, Integer>> out = new LinkedHashMap<>();
        for (CompetenceCaseRun r : runs) {
            if (!r.exploitable()) continue;
            out.computeIfAbsent(attendu.apply(r), k -> new LinkedHashMap<>())
                .merge(obtenu.apply(r), 1, Integer::sum);
        }
        return out;
    }

    // ------------------------------------------------------------ repartition

    /**
     * Repartition des paliers RENDUS, en face de celle des paliers ATTENDUS.
     *
     * <p>C'est le chiffre qui a declenche ce chantier : en base, sur 18
     * tentatives analysees, le correcteur n'avait rendu <b>aucun B2</b>. Un banc
     * qui mesurerait un bon taux d'accord global tout en ne produisant jamais un
     * palier entier passerait a cote du defaut.
     */
    record Repartition(Map<String, Integer> attendus, Map<String, Integer> rendus, int exploitables) {

        double pctRendu(String niveau) {
            return pct(rendus.getOrDefault(niveau, 0), exploitables);
        }

        double pctAttendu(String niveau) {
            return pct(attendus.getOrDefault(niveau, 0), exploitables);
        }

        /** Paliers que le correcteur n'a JAMAIS rendus alors que le corpus en contient. */
        List<String> paliersJamaisRendus() {
            return NIVEAUX.stream()
                .filter(n -> attendus.getOrDefault(n, 0) > 0 && rendus.getOrDefault(n, 0) == 0)
                .toList();
        }
    }

    static Repartition repartition(List<CompetenceCaseRun> runs) {
        Map<String, Integer> attendus = new LinkedHashMap<>();
        Map<String, Integer> rendus = new LinkedHashMap<>();
        for (String n : NIVEAUX) {
            attendus.put(n, 0);
            rendus.put(n, 0);
        }
        int exploitables = 0;
        for (CompetenceCaseRun r : runs) {
            if (!r.exploitable()) continue;
            exploitables++;
            attendus.merge(r.niveauAttendu(), 1, Integer::sum);
            rendus.merge(r.niveauObtenu(), 1, Integer::sum);
        }
        return new Repartition(Map.copyOf(attendus), Map.copyOf(rendus), exploitables);
    }

    // ------------------------------------------------------------ sensibilite

    /**
     * LA question du dossier : le correcteur DISTINGUE-T-IL deux productions de
     * niveaux differents ?
     *
     * <p>On ne le demande qu'a des paires legitimement comparables : deux cas du
     * meme perimetre dont les paliers ATTENDUS different. Trois issues, et elles
     * ne disent pas la meme chose :
     * <ul>
     *   <li><b>ordonnee</b> : les paliers rendus different ET dans le bon sens.
     *       C'est la seule issue reellement bonne ;</li>
     *   <li><b>inversee</b> : ils different, mais a l'envers. Erreur de jugement,
     *       pas d'aveuglement ;</li>
     *   <li><b>confondue</b> : le meme palier pour les deux. C'est le defaut
     *       mesure en base — deux productions inegales, un seul verdict.</li>
     * </ul>
     *
     * @param perimetre {@code ECHELLE} = paires du MEME SUJET (le test le plus
     *                  dur : seule la production change) ; {@code TACHE} =
     *                  paires de la meme tache, sujets differents.
     */
    record Sensibilite(String perimetre, int paires, int ordonnees, int inversees, int confondues) {

        double pctOrdonnees() {
            return pct(ordonnees, paires);
        }

        double pctConfondues() {
            return pct(confondues, paires);
        }
    }

    /** Sensibilite sur les paires du MEME sujet (cas portant une {@code echelle}). */
    static Sensibilite sensibiliteParEchelle(List<CompetenceCaseRun> runs) {
        return sensibilite("ECHELLE", groupes(runs, CompetenceCaseRun::echelle));
    }

    /** Sensibilite sur les paires de la meme TACHE, tous sujets confondus. */
    static Sensibilite sensibiliteParTache(List<CompetenceCaseRun> runs) {
        return sensibilite("TACHE", groupes(runs, CompetenceCaseRun::groupe));
    }

    private static List<List<CompetenceCaseRun>> groupes(
        List<CompetenceCaseRun> runs, java.util.function.Function<CompetenceCaseRun, String> cle) {
        Map<String, List<CompetenceCaseRun>> parCle = new LinkedHashMap<>();
        for (CompetenceCaseRun r : runs) {
            if (!r.exploitable()) continue;
            String k = cle.apply(r);
            if (k == null || k.isBlank()) continue;
            parCle.computeIfAbsent(k, x -> new ArrayList<>()).add(r);
        }
        return List.copyOf(parCle.values());
    }

    private static Sensibilite sensibilite(String perimetre, List<List<CompetenceCaseRun>> groupes) {
        int paires = 0;
        int ordonnees = 0;
        int inversees = 0;
        int confondues = 0;
        for (List<CompetenceCaseRun> g : groupes) {
            for (int i = 0; i < g.size(); i++) {
                for (int j = i + 1; j < g.size(); j++) {
                    CompetenceCaseRun a = g.get(i);
                    CompetenceCaseRun b = g.get(j);
                    int rangAttA = NIVEAUX.indexOf(a.niveauAttendu());
                    int rangAttB = NIVEAUX.indexOf(b.niveauAttendu());
                    if (rangAttA == rangAttB) continue;
                    paires++;
                    int rangObtA = NIVEAUX.indexOf(a.niveauObtenu());
                    int rangObtB = NIVEAUX.indexOf(b.niveauObtenu());
                    if (rangObtA == rangObtB) confondues++;
                    else if (Integer.signum(rangAttA - rangAttB) == Integer.signum(rangObtA - rangObtB)) ordonnees++;
                    else inversees++;
                }
            }
        }
        return new Sensibilite(perimetre, paires, ordonnees, inversees, confondues);
    }

    // ----------------------------------------------------------------- pieges

    record PiegeResultat(
        String casId,
        List<String> pieges,
        String niveauAttendu,
        String niveauObtenu,
        String statutAttendu,
        String statutObtenu,
        boolean niveauDansTolerance,
        boolean statutDansTolerance,
        boolean evite,
        String sens) {
    }

    static List<PiegeResultat> pieges(List<CompetenceCaseRun> runs) {
        List<PiegeResultat> out = new ArrayList<>();
        for (CompetenceCaseRun r : runs) {
            if (r.horsScore() || r.pieges().isEmpty()) continue;
            boolean niv = r.accordToleranceNiveau();
            boolean st = r.accordStatut();
            String sens = "-";
            if (!r.exploitable()) {
                sens = "NON_MESURE";
            } else if (!niv) {
                Integer ecart = r.ecartNiveau();
                sens = ecart != null && ecart < 0 ? "TROP_HAUT" : "TROP_BAS";
            } else if (!st) {
                sens = "VERDICT";
            }
            out.add(new PiegeResultat(r.casId(), r.pieges(), r.niveauAttendu(), r.niveauObtenu(),
                r.statutAttendu(), r.statutObtenu(), niv, st, niv && st, sens));
        }
        out.sort(Comparator.comparing(PiegeResultat::casId));
        return out;
    }

    // ------------------------------------------------------------- conformite

    /** MOTIF pour lequel un cas n'a pas pu etre mesure. */
    enum MotifPerte {
        /** Sortie coupee par le plafond de tokens : JSON tronque, illisible. */
        TRONCATURE_JSON,
        /** Le contrat n'est toujours pas respecte apres l'unique reparation. */
        CONTRAT_INVALIDE,
        /** 429, 5xx ou timeout : perte SUBIE, jamais un defaut de notation. */
        FOURNISSEUR_INDISPONIBLE,
        /** Sortie persistee a laquelle il manque une cle obligatoire. */
        SORTIE_INCOMPLETE,
        AUTRE
    }

    static MotifPerte motifPerte(CompetenceCaseRun run) {
        if (run.horsScore() || run.exploitable()) return null;
        if ("SORTIE_INVALIDE".equals(run.statut())) return MotifPerte.SORTIE_INCOMPLETE;
        String erreur = run.erreur() == null ? "" : run.erreur().toLowerCase(Locale.ROOT);
        if (erreur.contains("non deserialisable") || erreur.contains("non desorialisable")
            || erreur.contains("finish_reason=length") || erreur.contains("arguments vide")) {
            return MotifPerte.TRONCATURE_JSON;
        }
        if (erreur.contains("invalide apres une tentative de reparation")) {
            return MotifPerte.CONTRAT_INVALIDE;
        }
        if (erreur.contains("429") || erreur.contains("rate-limited")
            || erreur.contains("indisponible apres") || erreur.contains("timeout")
            || erreur.contains("5xx")) {
            return MotifPerte.FOURNISSEUR_INDISPONIBLE;
        }
        return MotifPerte.AUTRE;
    }

    /**
     * DEUX TAUX QU'IL NE FAUT JAMAIS CONFONDRE — l'erreur est deja documentee
     * cote productions completes.
     *
     * <ul>
     *   <li><b>sorties refusees</b> = {@code sortiesRefusees / appelsLlm} : ce
     *       que NOS controles refusent, appel par appel ;</li>
     *   <li><b>echec en conditions de production</b> =
     *       {@code analysesEchouees / analysesTentees} : en production il n'y a
     *       aucune boucle externe, donc une analyse echouee est une production
     *       perdue pour un candidat.</li>
     * </ul>
     */
    record Conformite(int total, int ok, int sortieInvalide, int erreurAppel,
                      int analysesTentees, int analysesEchouees, int appelsLlm,
                      int sortiesRefusees, int refusContrat, int refusPreuve,
                      int casAvecReessai, int casPerdus, int casNonMesures,
                      int niveauxAbaisses, int preuvesServies,
                      Map<String, Integer> motifsPerte) {

        double pctEchecProduction() {
            return pct(analysesEchouees, analysesTentees);
        }

        double pctSortiesRefusees() {
            return pct(sortiesRefusees, appelsLlm);
        }

        double pctCasPerdus() {
            return pct(casPerdus, total);
        }

        double pctSortieInvalide() {
            return pct(sortieInvalide, total);
        }

        double pctCasNonMesures() {
            return pct(casNonMesures, total);
        }

        double pctNiveauxAbaisses() {
            return pct(niveauxAbaisses, total);
        }

        int motif(MotifPerte motif) {
            return motifsPerte.getOrDefault(motif.name(), 0);
        }
    }

    static Conformite conformite(List<CompetenceCaseRun> runs) {
        int total = 0;
        int ok = 0;
        int invalide = 0;
        int erreur = 0;
        int tentees = 0;
        int echouees = 0;
        int appels = 0;
        int refusees = 0;
        int refusContrat = 0;
        int refusPreuve = 0;
        int reessais = 0;
        int abaisses = 0;
        int preuves = 0;
        Map<String, Integer> motifs = new LinkedHashMap<>();
        for (MotifPerte m : MotifPerte.values()) motifs.put(m.name(), 0);
        int nonMesures = 0;
        for (CompetenceCaseRun r : runs) {
            if (r.horsScore()) continue;
            total++;
            switch (r.statut()) {
                case "OK" -> ok++;
                case "SORTIE_INVALIDE" -> invalide++;
                default -> erreur++;
            }
            MotifPerte motif = motifPerte(r);
            if (motif != null) {
                motifs.merge(motif.name(), 1, Integer::sum);
                nonMesures++;
            }
            tentees += r.tentatives();
            echouees += r.tentativesRatees();
            appels += r.appelsLlm();
            refusees += r.sortiesRefusees();
            for (CompetenceCaseRun.Refus f : r.refus()) {
                if ("CONTRAT".equals(f.famille())) refusContrat++;
                else refusPreuve++;
            }
            if (r.tentativesRatees() > 0) reessais++;
            if (r.preuveAbaissee()) abaisses++;
            if (r.preuveServie()) preuves++;
        }
        return new Conformite(total, ok, invalide, erreur, tentees, echouees, appels,
            refusees, refusContrat, refusPreuve, reessais, erreur, nonMesures,
            abaisses, preuves, java.util.Collections.unmodifiableMap(motifs));
    }

    // ------------------------------------------------------------------ divers

    record Stabilite(String casId, int niveauxDistincts, List<String> niveaux) {
    }

    /** Ecart entre passes d'un meme cas. Vide quand la campagne n'a qu'une passe. */
    static List<Stabilite> stabilite(List<CompetenceCaseRun> runs) {
        Map<String, List<CompetenceCaseRun>> parCas = new LinkedHashMap<>();
        for (CompetenceCaseRun r : runs) {
            if (r.exploitable()) parCas.computeIfAbsent(r.casId(), k -> new ArrayList<>()).add(r);
        }
        List<Stabilite> out = new ArrayList<>();
        for (Map.Entry<String, List<CompetenceCaseRun>> e : parCas.entrySet()) {
            if (e.getValue().size() < 2) continue;
            List<String> niveaux = e.getValue().stream().map(CompetenceCaseRun::niveauObtenu).toList();
            out.add(new Stabilite(e.getKey(), new java.util.LinkedHashSet<>(niveaux).size(), niveaux));
        }
        out.sort(Comparator.comparingInt(Stabilite::niveauxDistincts).reversed()
            .thenComparing(Stabilite::casId));
        return out;
    }

    /** Cout TOTAL, temoins compris : ils ont ete payes comme les autres. */
    /**
     * Exprime en MILLIONIEMES de dollar. Le millionieme, et
     * non le centime : une micro-analyse coute ~0,0013 $, et l'ancien arrondi au
     * cent SUPERIEUR par appel multipliait la facture affichee par ~8. Le cout
     * persiste est desormais exact, il n'y a plus rien a recalculer a cote.
     */
    static long coutTotalMicroUsd(List<CompetenceCaseRun> runs) {
        return runs.stream().mapToLong(r -> r.coutMicroUsd() == null ? 0 : r.coutMicroUsd()).sum();
    }

    static int tokensInput(List<CompetenceCaseRun> runs) {
        return runs.stream().mapToInt(r -> r.tokensInput() == null ? 0 : r.tokensInput()).sum();
    }

    static int tokensOutput(List<CompetenceCaseRun> runs) {
        return runs.stream().mapToInt(r -> r.tokensOutput() == null ? 0 : r.tokensOutput()).sum();
    }
}
