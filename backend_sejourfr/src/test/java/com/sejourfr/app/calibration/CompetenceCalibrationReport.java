package com.sejourfr.app.calibration;

import tools.jackson.databind.SerializationFeature;
import tools.jackson.databind.json.JsonMapper;

import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Instant;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Restitution d'une campagne « Competences » : JSON brut sous
 * {@code target/calibration/} (non versionne) + synthese sur la sortie standard.
 *
 * <p>Jumelle de {@link CalibrationReport}, y compris pour le garde-fou de
 * comparabilite : deux campagnes qui n'ont pas tourne au meme nombre de
 * reessais ne se comparent pas. C'est exactement le defaut qui a fausse le choix
 * d'un modele cote productions completes (v9-flash a 9 reessais, v9-pro a 3,
 * gpt-5.4 a 1).
 */
final class CompetenceCalibrationReport {

    private static final Path DOSSIER = Path.of("target", "calibration");

    static final String CONVENTION =
        "ecart de palier = rang attendu - rang obtenu. NEGATIF = l'IA situe le candidat AU-DESSUS "
            + "de la reference (trop haut). POSITIF = trop bas. Aucune note sur 20 n'existe dans ce "
            + "module : le contrat de sortie n'a aucun champ ou la loger.";

    private static final List<String> REGLAGES_COMPARABLES =
        List.of("retries", "modele", "provider", "corpus", "cas", "passes",
            "rubrics_version", "tool_schema_version");

    static final String REGLAGE_BLOQUANT = "retries";

    private CompetenceCalibrationReport() {
    }

    static List<String> divergencesDeReglage(Map<String, Object> contexte, Map<String, Object> temoin) {
        List<String> out = new ArrayList<>();
        for (String cle : REGLAGES_COMPARABLES) {
            Object attendu = temoin.get(cle);
            Object obtenu = contexte.get(cle);
            if (attendu == null && obtenu == null) continue;
            if (String.valueOf(attendu).equals(String.valueOf(obtenu))) continue;
            String divergence = cle + " : temoin=" + attendu + " vs campagne=" + obtenu;
            if (REGLAGE_BLOQUANT.equals(cle)) out.add(0, divergence);
            else out.add(divergence);
        }
        return List.copyOf(out);
    }

    static boolean bloquant(List<String> divergences) {
        return divergences.stream().anyMatch(d -> d.startsWith(REGLAGE_BLOQUANT + " :"));
    }

    static Map<String, Object> contexteDuRapport(Path fichier) {
        return CalibrationReport.contexteDuRapport(fichier);
    }

    static String bandeauComparabilite(List<String> divergences) {
        if (divergences.isEmpty()) return "Temoin comparable : memes reglages.";
        StringBuilder sb = new StringBuilder();
        sb.append("\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n");
        sb.append(bloquant(divergences)
            ? "CAMPAGNES NON COMPARABLES — les reglages different sur `retries`.\n"
              + "Un temoin et un candidat DOIVENT tourner au meme nombre de reessais.\n"
            : "ATTENTION — reglages differents entre le temoin et cette campagne.\n");
        for (String d : divergences) sb.append("  · ").append(d).append('\n');
        sb.append("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n");
        return sb.toString();
    }

    // ------------------------------------------------------------------- ecrit

    static Path ecrire(String label, Map<String, Object> contexte, List<CompetenceCaseRun> runs) {
        Map<String, Object> racine = new LinkedHashMap<>();
        racine.put("label", label);
        racine.put("genere_le", Instant.now().toString());
        racine.put("contexte", contexte);
        racine.put("convention_ecart", CONVENTION);
        racine.put("global", agregatJson(CompetenceCalibrationMetrics.agregat("GLOBAL", runs)));
        racine.put("par_tache", CompetenceCalibrationMetrics.parTache(runs).stream()
            .map(CompetenceCalibrationReport::agregatJson).toList());
        racine.put("par_niveau_attendu", CompetenceCalibrationMetrics.parNiveauAttendu(runs).stream()
            .map(CompetenceCalibrationReport::agregatJson).toList());
        racine.put("confusion_niveau", CompetenceCalibrationMetrics.confusionNiveau(runs));
        racine.put("confusion_statut", CompetenceCalibrationMetrics.confusionStatut(runs));
        racine.put("repartition_paliers", repartitionJson(CompetenceCalibrationMetrics.repartition(runs)));
        racine.put("sensibilite", List.of(
            sensibiliteJson(CompetenceCalibrationMetrics.sensibiliteParEchelle(runs)),
            sensibiliteJson(CompetenceCalibrationMetrics.sensibiliteParTache(runs))));
        racine.put("pieges", CompetenceCalibrationMetrics.pieges(runs));
        racine.put("conformite", conformiteJson(CompetenceCalibrationMetrics.conformite(runs)));
        racine.put("stabilite", CompetenceCalibrationMetrics.stabilite(runs));
        racine.put("cout", coutJson(runs, contexte));
        racine.put("runs", runs);

        try {
            Files.createDirectories(DOSSIER);
            Path fichier = DOSSIER.resolve(label + ".json");
            JsonMapper.builder().enable(SerializationFeature.INDENT_OUTPUT).build()
                .writeValue(fichier.toFile(), racine);
            return fichier;
        } catch (Exception e) {
            throw new IllegalStateException("Ecriture du rapport de calibration impossible", e);
        }
    }

    private static Map<String, Object> agregatJson(CompetenceCalibrationMetrics.Agregat a) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("label", a.label());
        m.put("cas", a.cas());
        m.put("exploitables", a.exploitables());
        m.put("accord_exact_niveau", a.accordExactNiveau());
        m.put("accord_exact_niveau_pct", arrondi(a.pctExactNiveau()));
        m.put("accord_tolerance_niveau", a.accordToleranceNiveau());
        m.put("accord_tolerance_niveau_pct", arrondi(a.pctToleranceNiveau()));
        m.put("accord_statut_critere", a.accordStatut());
        m.put("accord_statut_critere_pct", arrondi(a.pctStatut()));
        m.put("accord_statut_exact_pct", arrondi(a.pctExactStatut()));
        m.put("ecart_niveau_moyen_reference_moins_ia", arrondi(a.ecartNiveauMoyen()));
        return m;
    }

    private static Map<String, Object> repartitionJson(CompetenceCalibrationMetrics.Repartition r) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("exploitables", r.exploitables());
        m.put("attendus", r.attendus());
        m.put("rendus", r.rendus());
        Map<String, Object> pct = new LinkedHashMap<>();
        for (String n : CompetenceCalibrationMetrics.NIVEAUX) pct.put(n, arrondi(r.pctRendu(n)));
        m.put("rendus_pct", pct);
        m.put("paliers_jamais_rendus", r.paliersJamaisRendus());
        return m;
    }

    private static Map<String, Object> sensibiliteJson(CompetenceCalibrationMetrics.Sensibilite s) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("perimetre", s.perimetre());
        m.put("paires_comparables", s.paires());
        m.put("ordonnees", s.ordonnees());
        m.put("ordonnees_pct", arrondi(s.pctOrdonnees()));
        m.put("inversees", s.inversees());
        m.put("confondues", s.confondues());
        m.put("confondues_pct", arrondi(s.pctConfondues()));
        return m;
    }

    private static Map<String, Object> conformiteJson(CompetenceCalibrationMetrics.Conformite c) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("total", c.total());
        m.put("ok", c.ok());
        m.put("analyses_tentees", c.analysesTentees());
        m.put("analyses_echouees", c.analysesEchouees());
        m.put("echec_production_pct", arrondi(c.pctEchecProduction()));
        m.put("appels_llm", c.appelsLlm());
        m.put("sorties_refusees", c.sortiesRefusees());
        m.put("sorties_refusees_pct", arrondi(c.pctSortiesRefusees()));
        m.put("refus_contrat", c.refusContrat());
        m.put("refus_preuve_du_niveau", c.refusPreuve());
        m.put("cas_avec_reessai", c.casAvecReessai());
        m.put("sortie_invalide", c.sortieInvalide());
        m.put("sortie_invalide_pct", arrondi(c.pctSortieInvalide()));
        m.put("cas_perdus", c.casPerdus());
        m.put("cas_perdus_pct", arrondi(c.pctCasPerdus()));
        m.put("cas_non_mesures", c.casNonMesures());
        m.put("cas_non_mesures_pct", arrondi(c.pctCasNonMesures()));
        m.put("preuve_du_niveau_servie", c.preuvesServies());
        m.put("niveaux_abaisses_par_le_garde_fou", c.niveauxAbaisses());
        m.put("niveaux_abaisses_pct", arrondi(c.pctNiveauxAbaisses()));
        m.put("motifs_perte", c.motifsPerte());
        m.put("motifs_perte_lisible", motifs(c));
        return m;
    }

    /**
     * Cout de la campagne, sous DEUX formes, et il faut les deux.
     *
     * <p>{@code cout_total_centimes} est la somme des couts persistes par le
     * client — chacun ARRONDI AU CENT SUPERIEUR
     * ({@code Math.ceil}). Sur une analyse de competence, qui coute quelques
     * millimes, cet arrondi multiplie la facture affichee par un facteur dix :
     * il est fidele a ce que la base enregistre, il ne dit rien de la depense
     * reelle. {@code cout_reel_usd} recalcule celle-ci a partir des tokens et
     * des tarifs du provider ACTIF, sans arrondi intermediaire — c'est le chiffre
     * a citer quand on decide de payer une campagne.
     */
    private static Map<String, Object> coutJson(List<CompetenceCaseRun> runs, Map<String, Object> contexte) {
        int in = CompetenceCalibrationMetrics.tokensInput(runs);
        int out = CompetenceCalibrationMetrics.tokensOutput(runs);
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("tokens_input", in);
        m.put("tokens_output", out);
        m.put("cout_total_centimes", CompetenceCalibrationMetrics.coutTotalCentimes(runs));
        m.put("cout_total_centimes_note",
            "somme des couts persistes, chacun arrondi au cent SUPERIEUR : surestime "
                + "fortement une campagne de micro-analyses");
        Double reel = coutReelUsd(in, out, contexte);
        m.put("cout_reel_usd", reel == null ? null : Math.round(reel * 100000.0) / 100000.0);
        m.put("cout_entree_par_million_usd", contexte.get("cout_entree_par_million_usd"));
        m.put("cout_sortie_par_million_usd", contexte.get("cout_sortie_par_million_usd"));
        return m;
    }

    /** {@code null} quand la campagne n'a pas publie les tarifs du provider actif. */
    static Double coutReelUsd(int tokensIn, int tokensOut, Map<String, Object> contexte) {
        Object cin = contexte.get("cout_entree_par_million_usd");
        Object cout = contexte.get("cout_sortie_par_million_usd");
        if (!(cin instanceof Number in) || !(cout instanceof Number sortie)) return null;
        return tokensIn * in.doubleValue() / 1_000_000.0 + tokensOut * sortie.doubleValue() / 1_000_000.0;
    }

    private static double arrondi(double v) {
        return Math.round(v * 100.0) / 100.0;
    }

    // ----------------------------------------------------------------- console

    static void console(String label, Map<String, Object> contexte, List<CompetenceCaseRun> runs,
                        Path fichier) {
        StringBuilder sb = new StringBuilder();
        sb.append("\n================================================================\n");
        sb.append("BANC COMPETENCES TCF — campagne ").append(label).append('\n');
        contexte.forEach((k, v) -> sb.append("  ").append(k).append(" = ").append(v).append('\n'));
        sb.append("================================================================\n\n");

        CompetenceCalibrationMetrics.Conformite c = CompetenceCalibrationMetrics.conformite(runs);
        sb.append(String.format("Runs notes %d — OK %d · sortie invalide %d · cas perdus %d%n",
            c.total(), c.ok(), c.sortieInvalide(), c.casPerdus()));
        sb.append(String.format(
            "SORTIES REFUSEES par nos controles : %d sur %d appels LLM (%.1f %%) "
                + "— contrat %d · preuve du niveau %d%n",
            c.sortiesRefusees(), c.appelsLlm(), c.pctSortiesRefusees(), c.refusContrat(), c.refusPreuve()));
        sb.append(String.format(
            "ECHEC EN CONDITIONS DE PRODUCTION : %d analyses echouees sur %d tentees (%.1f %%) "
                + "— %d cas ont exige un reessai%n",
            c.analysesEchouees(), c.analysesTentees(), c.pctEchecProduction(), c.casAvecReessai()));
        sb.append(String.format("Non mesures au total %d/%d (%.1f %%) — motifs : %s%n",
            c.casNonMesures(), c.total(), c.pctCasNonMesures(), motifs(c)));
        sb.append(String.format(
            "Preuve du niveau : servie sur %d run(s) · palier abaisse par le garde-fou %d (%.1f %%)%n",
            c.preuvesServies(), c.niveauxAbaisses(), c.pctNiveauxAbaisses()));
        int tokensIn = CompetenceCalibrationMetrics.tokensInput(runs);
        int tokensOut = CompetenceCalibrationMetrics.tokensOutput(runs);
        Double reel = coutReelUsd(tokensIn, tokensOut, contexte);
        sb.append(String.format(
            "Cout : %d tokens entree · %d tokens sortie · %s (persiste : %d centimes, arrondi au cent "
                + "SUPERIEUR par appel, donc surestime)%n%n",
            tokensIn, tokensOut,
            reel == null ? "tarifs indisponibles" : String.format("%.4f $ reels", reel),
            CompetenceCalibrationMetrics.coutTotalCentimes(runs)));
        sb.append(CONVENTION).append("\n\n");

        sb.append(entete());
        sb.append(ligne(CompetenceCalibrationMetrics.agregat("GLOBAL", runs)));
        sb.append('\n');
        sb.append("Par tache :\n").append(entete());
        for (CompetenceCalibrationMetrics.Agregat a : CompetenceCalibrationMetrics.parTache(runs)) {
            sb.append(ligne(a));
        }
        sb.append('\n');
        sb.append("Par palier attendu :\n").append(entete());
        for (CompetenceCalibrationMetrics.Agregat a : CompetenceCalibrationMetrics.parNiveauAttendu(runs)) {
            sb.append(ligne(a));
        }
        sb.append('\n');

        sb.append("Matrice de confusion des PALIERS (lignes = attendu, colonnes = rendu) :\n");
        sb.append(matrice(CompetenceCalibrationMetrics.confusionNiveau(runs),
            CompetenceCalibrationMetrics.NIVEAUX));
        sb.append('\n');
        sb.append("Matrice de confusion des VERDICTS DE CRITERE :\n");
        sb.append(matrice(CompetenceCalibrationMetrics.confusionStatut(runs),
            CompetenceCalibrationMetrics.STATUTS));
        sb.append('\n');

        CompetenceCalibrationMetrics.Repartition rep = CompetenceCalibrationMetrics.repartition(runs);
        sb.append("Repartition des paliers (attendus vs rendus) :\n");
        for (String n : CompetenceCalibrationMetrics.NIVEAUX) {
            sb.append(String.format("  %-16s attendu %3d (%5.1f %%)   rendu %3d (%5.1f %%)%n",
                n, rep.attendus().getOrDefault(n, 0), rep.pctAttendu(n),
                rep.rendus().getOrDefault(n, 0), rep.pctRendu(n)));
        }
        if (!rep.paliersJamaisRendus().isEmpty()) {
            sb.append("  /!\\ PALIER(S) JAMAIS RENDU(S) alors que le corpus en contient : ")
                .append(String.join(", ", rep.paliersJamaisRendus())).append('\n');
        }
        sb.append('\n');

        sb.append("SENSIBILITE — le correcteur distingue-t-il deux productions de paliers differents ?\n");
        sb.append(String.format("  %-10s %8s %10s %10s %12s%n",
            "perimetre", "paires", "ordonnees", "inversees", "confondues"));
        for (CompetenceCalibrationMetrics.Sensibilite s : List.of(
            CompetenceCalibrationMetrics.sensibiliteParEchelle(runs),
            CompetenceCalibrationMetrics.sensibiliteParTache(runs))) {
            sb.append(String.format("  %-10s %8d %6d %5.1f%% %10d %7d %5.1f%%%n",
                s.perimetre(), s.paires(), s.ordonnees(), s.pctOrdonnees(),
                s.inversees(), s.confondues(), s.pctConfondues()));
        }
        sb.append("  ECHELLE = paires du MEME sujet, seule la production change : c'est le test dur.\n\n");

        sb.append("Pieges :\n");
        sb.append(String.format("  %-18s %-24s %-14s %-14s %-14s %-14s %s%n",
            "cas", "piege", "palier att.", "palier obt.", "verdict att.", "verdict obt.", "issue"));
        for (CompetenceCalibrationMetrics.PiegeResultat p : CompetenceCalibrationMetrics.pieges(runs)) {
            sb.append(String.format("  %-18s %-24s %-14s %-14s %-14s %-14s %s%n",
                p.casId(), String.join(",", p.pieges()), p.niveauAttendu(),
                p.niveauObtenu() == null ? "-" : p.niveauObtenu(),
                p.statutAttendu(), p.statutObtenu() == null ? "-" : p.statutObtenu(),
                p.evite() ? "EVITE" : ("RATE (" + p.sens() + ")")));
        }
        sb.append('\n');

        List<CompetenceCalibrationMetrics.Stabilite> stab = CompetenceCalibrationMetrics.stabilite(runs);
        if (!stab.isEmpty()) {
            long instables = stab.stream().filter(s -> s.niveauxDistincts() > 1).count();
            sb.append(String.format("Stabilite (%d cas rejoues) : %d cas rendent plusieurs paliers%n",
                stab.size(), instables));
            stab.stream().limit(10).forEach(s -> sb.append(String.format("    %-18s %s%n",
                s.casId(), String.join("/", s.niveaux()))));
            sb.append('\n');
        }

        long temoins = runs.stream().filter(CompetenceCaseRun::horsScore).count();
        if (temoins > 0) {
            sb.append(String.format(
                "%d production(s) reelle(s) jouee(s) en TEMOIN : mesurees, affichees dans `runs`, "
                    + "EXCLUES de tous les agregats ci-dessus (aucune verite terrain).%n%n", temoins));
        }

        sb.append("Rapport JSON : ").append(fichier.toAbsolutePath()).append('\n');
        System.out.println(sb);
    }

    static String motifs(CompetenceCalibrationMetrics.Conformite c) {
        if (c.casNonMesures() == 0) return "aucun cas perdu";
        StringBuilder sb = new StringBuilder();
        for (CompetenceCalibrationMetrics.MotifPerte motif : CompetenceCalibrationMetrics.MotifPerte.values()) {
            int n = c.motif(motif);
            if (n == 0) continue;
            if (!sb.isEmpty()) sb.append(" · ");
            sb.append(libelle(motif)).append(' ').append(n);
        }
        return sb.toString();
    }

    private static String libelle(CompetenceCalibrationMetrics.MotifPerte motif) {
        return switch (motif) {
            case TRONCATURE_JSON -> "troncature JSON (plafond de tokens)";
            case CONTRAT_INVALIDE -> "contrat encore invalide apres reparation";
            case FOURNISSEUR_INDISPONIBLE -> "fournisseur indisponible (429/5xx/timeout)";
            case SORTIE_INCOMPLETE -> "sortie incomplete";
            case AUTRE -> "autre";
        };
    }

    private static String entete() {
        return String.format("  %-16s %4s %10s %10s %12s %14s%n",
            "perimetre", "n", "exact", "+/- tol.", "verdict", "ecart palier");
    }

    private static String ligne(CompetenceCalibrationMetrics.Agregat a) {
        return String.format("  %-16s %4d %9.1f%% %9.1f%% %11.1f%% %+14.2f%n",
            a.label(), a.exploitables(), a.pctExactNiveau(), a.pctToleranceNiveau(),
            a.pctStatut(), a.ecartNiveauMoyen());
    }

    private static String matrice(Map<String, Map<String, Integer>> m, List<String> axes) {
        List<String> colonnes = axes.stream()
            .filter(n -> m.values().stream().anyMatch(l -> l.containsKey(n)))
            .toList();
        StringBuilder sb = new StringBuilder();
        sb.append(String.format("  %-16s", ""));
        for (String col : colonnes) sb.append(String.format("%18s", col));
        sb.append('\n');
        for (String axe : axes) {
            Map<String, Integer> ligne = m.get(axe);
            if (ligne == null) continue;
            sb.append(String.format("  %-16s", axe));
            for (String col : colonnes) sb.append(String.format("%18d", ligne.getOrDefault(col, 0)));
            sb.append('\n');
        }
        return sb.toString();
    }
}
