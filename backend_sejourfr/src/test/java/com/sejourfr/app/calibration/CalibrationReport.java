package com.sejourfr.app.calibration;

import tools.jackson.databind.SerializationFeature;
import tools.jackson.databind.json.JsonMapper;

import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Restitution d'une campagne : JSON brut sous {@code target/calibration/} (non
 * versionne) + tableau de synthese sur la sortie standard.
 */
final class CalibrationReport {

    private static final Path DOSSIER = Path.of("target", "calibration");

    /** Meme convention que {@code AdminCalibrationService.computeEcart}. */
    static final String CONVENTION =
        "ecart = reference - IA (reference = centre de [note_min, note_max] ; niveau : rang attendu - rang obtenu). "
            + "NEGATIF = l'IA note AU-DESSUS de la reference, donc trop indulgente. POSITIF = trop severe.";

    private CalibrationReport() {
    }

    static Path ecrire(String label, Map<String, Object> contexte, List<CaseRun> runs) {
        Map<String, Object> racine = new LinkedHashMap<>();
        racine.put("label", label);
        racine.put("genere_le", Instant.now().toString());
        racine.put("contexte", contexte);
        racine.put("convention_ecart", CONVENTION);
        racine.put("global", agregatJson(CalibrationMetrics.agregat("GLOBAL", runs)));
        racine.put("par_tache", CalibrationMetrics.parGroupe(runs).stream()
            .map(CalibrationReport::agregatJson).toList());
        racine.put("par_niveau_attendu", CalibrationMetrics.parNiveauAttendu(runs).stream()
            .map(CalibrationReport::agregatJson).toList());
        racine.put("confusion", CalibrationMetrics.confusion(runs));
        racine.put("pieges", CalibrationMetrics.pieges(runs));
        racine.put("confiance", CalibrationMetrics.confiance(runs));
        racine.put("accomplissement", CalibrationMetrics.accomplissement(runs));
        racine.put("conformite", CalibrationMetrics.conformite(runs));
        racine.put("stabilite", CalibrationMetrics.stabilite(runs));
        racine.put("cout_total_centimes", CalibrationMetrics.coutTotalCentimes(runs));
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

    private static Map<String, Object> agregatJson(CalibrationMetrics.Agregat a) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("label", a.label());
        m.put("cas", a.cas());
        m.put("exploitables", a.exploitables());
        m.put("accord_exact", a.accordExact());
        m.put("accord_exact_pct", arrondi(a.pctExact()));
        m.put("accord_tolerance", a.accordTolerance());
        m.put("accord_tolerance_pct", arrondi(a.pctTolerance()));
        m.put("note_dans_fourchette", a.noteDansFourchette());
        m.put("note_dans_fourchette_pct", arrondi(a.pctFourchette()));
        m.put("ecart_signe_centre_moyen_reference_moins_ia", arrondi(a.ecartCentreMoyen()));
        m.put("ecart_signe_fourchette_moyen_reference_moins_ia", arrondi(a.ecartFourchetteMoyen()));
        m.put("ecart_niveau_moyen_reference_moins_ia", arrondi(a.ecartNiveauMoyen()));
        return m;
    }

    private static double arrondi(double v) {
        return Math.round(v * 100.0) / 100.0;
    }

    static void console(String label, Map<String, Object> contexte, List<CaseRun> runs, Path fichier) {
        StringBuilder sb = new StringBuilder();
        sb.append("\n================================================================\n");
        sb.append("BANC DE MESURE — campagne ").append(label).append('\n');
        contexte.forEach((k, v) -> sb.append("  ").append(k).append(" = ").append(v).append('\n'));
        sb.append("================================================================\n\n");

        CalibrationMetrics.Conformite c = CalibrationMetrics.conformite(runs);
        sb.append(String.format(
            "Runs %d — OK %d · court-circuit validite %d · champ requis manquant %d · cas perdus %d%n",
            c.total(), c.ok(), c.validiteServeur(), c.sortieInvalide(), c.erreurAppel()));
        sb.append(String.format(
            "Sorties invalides : %d appels rates sur %d (%.1f %%) — %d cas ont exige un reessai, "
                + "%d cas irrecuperables (%.1f %%) · criteres manquants sur %d run(s)%n",
            c.appelsRates(), c.appels(), c.pctAppelsRates(), c.casAvecReessai(),
            c.casPerdus(), c.pctCasPerdus(), c.criteresManquants()));
        sb.append(String.format("Cout estime : %d centimes%n%n", CalibrationMetrics.coutTotalCentimes(runs)));
        sb.append(CONVENTION).append("\n\n");

        sb.append(entete());
        sb.append(ligne(CalibrationMetrics.agregat("GLOBAL", runs)));
        sb.append('\n');
        sb.append("Par tache :\n").append(entete());
        for (CalibrationMetrics.Agregat a : CalibrationMetrics.parGroupe(runs)) sb.append(ligne(a));
        sb.append('\n');
        sb.append("Par niveau attendu :\n").append(entete());
        for (CalibrationMetrics.Agregat a : CalibrationMetrics.parNiveauAttendu(runs)) sb.append(ligne(a));
        sb.append('\n');

        sb.append("Matrice de confusion (lignes = attendu, colonnes = obtenu) :\n");
        sb.append(confusion(runs));
        sb.append('\n');

        sb.append("Pieges :\n");
        sb.append(String.format("  %-16s %-22s %-14s %-14s %-8s %-6s %s%n",
            "cas", "piege", "niveau att.", "niveau obt.", "note", "zone", "verdict"));
        for (CalibrationMetrics.PiegeResultat p : CalibrationMetrics.pieges(runs)) {
            sb.append(String.format("  %-16s %-22s %-14s %-14s %-8s %-6s %s%n",
                p.casId(), String.join(",", p.pieges()), p.niveauAttendu(),
                p.niveauObtenu() == null ? "-" : p.niveauObtenu(),
                p.note() == null ? "-" : String.format("%.1f", p.note()),
                String.format("%.0f-%.0f", p.noteMin(), p.noteMax()),
                p.evite() ? "EVITE" : ("RATE (" + p.sens() + ")")));
        }
        sb.append('\n');

        List<?> champs = contexte.get("champs_requis") instanceof List<?> l ? l : null;
        CalibrationMetrics.ConfianceResultat conf = CalibrationMetrics.confiance(runs);
        if (champs != null && !champs.contains("confiance")) {
            sb.append("Confiance : HORS SCHEMA de cette version de prompt — le serveur pose MOYENNE "
                + "par defaut, la mesure ne dit rien du modele.\n");
        }
        sb.append(String.format("Confiance : accord %d/%d (%.1f %%) · plus sure que la reference %d · moins sure %d%n",
            conf.accord(), conf.evalues(), conf.pctAccord(), conf.plusSur(), conf.moinsSur()));

        CalibrationMetrics.AccomplissementResultat acc = CalibrationMetrics.accomplissement(runs);
        if (champs != null && !champs.contains("accomplissement")) {
            sb.append("Accomplissement : HORS SCHEMA de cette version de prompt — le serveur pose un bloc "
                + "vide, la mesure ne dit rien du modele.\n");
        }
        sb.append(String.format(
            "Accomplissement : bloc present sur %d run(s) · accord \"obligatoire traite\" %d (%.1f %%) · "
                + "points oublies detectes %d/%d (%.1f %%)%n",
            acc.casAvecBloc(), acc.accordObligatoire(), acc.pctAccordObligatoire(),
            acc.pointsDetectes(), acc.pointsAttendus(), acc.rappelPoints()));
        if (!acc.casSansDetection().isEmpty()) {
            sb.append("  aucun point oublie retrouve sur : ")
                .append(String.join(", ", acc.casSansDetection())).append('\n');
        }
        sb.append('\n');

        List<CalibrationMetrics.Stabilite> stab = CalibrationMetrics.stabilite(runs);
        if (!stab.isEmpty()) {
            double amplitudeMoyenne = stab.stream().mapToDouble(CalibrationMetrics.Stabilite::amplitude).average().orElse(0);
            long instables = stab.stream().filter(s -> s.niveauxDistincts() > 1).count();
            long identiques = stab.stream().filter(s -> s.amplitude() == 0 && s.niveauxDistincts() == 1).count();
            sb.append(String.format(
                "Stabilite (%d cas rejoues) : amplitude de note moyenne %.2f pt · max %.1f pt · "
                    + "cas strictement identiques %d · cas a plusieurs niveaux %d%n",
                stab.size(), amplitudeMoyenne, stab.get(0).amplitude(), identiques, instables));
            sb.append("  10 cas les plus instables :\n");
            stab.stream().limit(10).forEach(s -> sb.append(String.format(
                "    %-16s notes %.1f-%.1f (amplitude %.1f) niveaux %s%n",
                s.casId(), s.noteMin(), s.noteMax(), s.amplitude(), String.join("/", s.niveaux()))));
            sb.append('\n');
        }

        sb.append("Rapport JSON : ").append(fichier.toAbsolutePath()).append('\n');
        System.out.println(sb);
    }

    private static String entete() {
        return String.format("  %-16s %4s %8s %8s %10s %11s %11s %11s%n",
            "perimetre", "n", "exact", "+/-1", "fourchette",
            "ecart pt", "ecart borne", "ecart niveau");
    }

    private static String ligne(CalibrationMetrics.Agregat a) {
        return String.format("  %-16s %4d %7.1f%% %7.1f%% %9.1f%% %+11.2f %+11.2f %+11.2f%n",
            a.label(), a.exploitables(), a.pctExact(), a.pctTolerance(), a.pctFourchette(),
            a.ecartCentreMoyen(), a.ecartFourchetteMoyen(), a.ecartNiveauMoyen());
    }

    private static String confusion(List<CaseRun> runs) {
        Map<String, Map<String, Integer>> m = CalibrationMetrics.confusion(runs);
        List<String> colonnes = CalibrationMetrics.NIVEAUX.stream()
            .filter(n -> m.values().stream().anyMatch(l -> l.containsKey(n)))
            .toList();
        StringBuilder sb = new StringBuilder();
        sb.append(String.format("  %-16s", ""));
        for (String col : colonnes) sb.append(String.format("%16s", col));
        sb.append('\n');
        for (String niv : CalibrationMetrics.NIVEAUX) {
            Map<String, Integer> ligne = m.get(niv);
            if (ligne == null) continue;
            sb.append(String.format("  %-16s", niv));
            for (String col : colonnes) sb.append(String.format("%16d", ligne.getOrDefault(col, 0)));
            sb.append('\n');
        }
        return sb.toString();
    }
}
