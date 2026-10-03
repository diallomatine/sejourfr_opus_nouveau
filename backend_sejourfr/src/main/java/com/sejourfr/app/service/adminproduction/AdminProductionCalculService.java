package com.sejourfr.app.service.adminproduction;

import com.sejourfr.app.config.ProductionEvaluationProperties;
import com.sejourfr.app.dto.AdminProductionDetailDto.Calcul;
import com.sejourfr.app.dto.AdminProductionDetailDto.Couplage;
import com.sejourfr.app.dto.AdminProductionDetailDto.PlafondNiveau;
import com.sejourfr.app.dto.AdminProductionDetailDto.Seuils;
import com.sejourfr.app.entity.AiEvaluation;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.enums.AdminCalculStatut;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.ProductionEvaluabilite;
import com.sejourfr.app.service.AiEvaluationService;
import com.sejourfr.app.service.ProductionBilanService;
import com.sejourfr.app.service.ProductionRubricsProvider;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

/**
 * Bloc « Calcul SejourFR » de la console « Productions IA » (F-5 A) : rejoue,
 * EN LECTURE, le passage scores retenus → note → niveau d'une évaluation avec
 * la grille QUI L'A NOTÉE ({@code ai_evaluations.rubrics_version}).
 *
 * <p>🛑 Aucune règle n'est recopiée ici : la note vient de
 * {@link AiEvaluationService#weightedNote}, le niveau de
 * {@link ProductionBilanService#computeNiveau}, le couplage de
 * {@link AiEvaluationService#plafondCouplage}, les plafonds de
 * {@link AiEvaluationService#plafondsDeclenches} — les fonctions mêmes qui
 * notent le candidat — et la grille de {@link ProductionRubricsProvider}.
 * Rien n'est écrit : un écart est servi ({@code coherent}), jamais corrigé.
 * Version inconnue ou grille absente : rien n'est inventé, seul le niveau
 * persisté est servi.
 */
@Service
@RequiredArgsConstructor
public class AdminProductionCalculService {

    static final String FORMULE_NOTE =
            "Note /20 = Σ (note du critère × poids de la grille), arrondie au dixième "
                    + "(demi supérieur), bornée à [0 ; 20].";

    private final ProductionRubricsProvider rubrics;

    /**
     * @param calcul        le bloc servi
     * @param poidsParCode  poids des critères dans la grille de l'évaluation
     *                      (vide si elle n'est pas traçable)
     */
    public record Explication(Calcul calcul, Map<String, BigDecimal> poidsParCode) {}

    public Explication expliquer(AiEvaluation evaluation, ProductionTask task) {
        if (evaluation == null) {
            return new Explication(nonCalcule(AdminCalculStatut.SANS_EVALUATION, null), Map.of());
        }
        if (evaluation.getEvaluabilite() == ProductionEvaluabilite.NON_EVALUABLE) {
            return new Explication(nonCalcule(AdminCalculStatut.NON_EVALUABLE, evaluation), Map.of());
        }
        Optional<ProductionRubricsProvider.Grille> trouvee = rubrics.grilleDeVersion(evaluation.getRubricsVersion());
        if (trouvee.isEmpty() || task == null || task.getTacheNumero() == null) {
            return new Explication(nonCalcule(AdminCalculStatut.REGLE_NON_TRACABLE, evaluation), Map.of());
        }
        ProductionRubricsProvider.Grille grille = trouvee.get();
        int tache = task.getTacheNumero();
        Object criteresGrille = grille.tache(task.getEpreuve(), tache).map(r -> r.get("criteres")).orElse(null);
        Map<String, Object> feedback = evaluation.getFeedbackJson() == null ? Map.of() : evaluation.getFeedbackJson();
        Object scores = feedback.get("scores_criteres");

        BigDecimal noteRecalculee = AiEvaluationService.weightedNote(criteresGrille, scores);
        BigDecimal noteGlobale = noteRecalculee != null ? noteRecalculee : evaluation.getNoteSur20();
        ProductionEvaluationProperties.NiveauCecrl seuils = grille.niveauCecrl();
        List<String> porteurs = seuils.getSourceCriteres();
        BigDecimal competence = ProductionBilanService.competence(scores, porteurs, noteGlobale);
        NiveauCecrl avantPlafonds = ProductionBilanService.computeNiveau(scores, porteurs, noteGlobale, seuils);

        Map<String, BigDecimal> notes = AiEvaluationService.notesParCode(scores);
        ProductionEvaluationProperties.Couplage cfgCouplage = grille.couplage();
        BigDecimal plafondRealisation = AiEvaluationService.plafondCouplage(notes, cfgCouplage);
        List<String> auPlafond = new ArrayList<>();
        if (plafondRealisation != null) {
            BigDecimal ramenee = AiEvaluationService.noteRamenee(plafondRealisation);
            for (String code : cfgCouplage.getCriteresRealisation()) {
                BigDecimal note = notes.get(code);
                if (note != null && note.compareTo(ramenee) == 0) auPlafond.add(code);
            }
        }

        ProductionEvaluationProperties.Plafonds cfgPlafonds = grille.plafonds();
        List<PlafondNiveau> plafonds = new ArrayList<>();
        NiveauCecrl niveauRecalcule = avantPlafonds;
        if (cfgPlafonds.isEnabled() && avantPlafonds != null) {
            for (AiEvaluationService.PlafondDeclenche p
                    : AiEvaluationService.plafondsDeclenches(notes, task.getEpreuve(), tache, cfgPlafonds)) {
                plafonds.add(new PlafondNiveau(p.regle(), p.niveauMax(), p.declencheur()));
                niveauRecalcule = AiEvaluationService.plafonner(niveauRecalcule, p.niveauMax());
            }
        }

        NiveauCecrl persiste = evaluation.getNiveauCecrl();
        Map<String, BigDecimal> poids = poidsParCode(criteresGrille);
        // Règle conservatrice : la cohérence n'est conclue que si TOUTES les
        // entrées du calcul sont tracées par la grille de l'évaluation. Un
        // paramètre repris de la configuration actuelle rend le calcul partiel.
        boolean tracable = grille.parametresDeLaGrille() && toutesPonderees(criteresGrille, poids);
        AdminCalculStatut statut = tracable ? AdminCalculStatut.CALCULE : AdminCalculStatut.CALCUL_PARTIEL;
        Calcul calcul = new Calcul(
                statut,
                statut.label(),
                evaluation.getRubricsVersion(),
                evaluation.getPromptVersion(),
                grille.version().equals(rubrics.versionActive()),
                FORMULE_NOTE,
                noteRecalculee,
                evaluation.getNoteSur20(),
                List.copyOf(porteurs),
                competence,
                new Seuils(nombre(seuils.getSeuilA2()), nombre(seuils.getSeuilB1()), nombre(seuils.getSeuilB2())),
                grille.niveauDepuisLaGrille(),
                regleNiveau(seuils),
                avantPlafonds,
                new Couplage(cfgCouplage.isEnabled(), nombre(cfgCouplage.getEcartMax()),
                        List.copyOf(cfgCouplage.getCriteresRealisation()),
                        List.copyOf(cfgCouplage.getCriteresLangue()),
                        plafondRealisation, auPlafond),
                plafonds,
                niveau(feedback.get(AiEvaluationService.PLAFOND_NIVEAU_KEY)),
                niveauRecalcule,
                persiste,
                !tracable || niveauRecalcule == null || persiste == null ? null : niveauRecalcule == persiste);
        return new Explication(calcul, poids);
    }

    private static Calcul nonCalcule(AdminCalculStatut statut, AiEvaluation e) {
        return new Calcul(statut, statut.label(),
                e == null ? null : e.getRubricsVersion(),
                e == null ? null : e.getPromptVersion(),
                false, null, null, e == null ? null : e.getNoteSur20(),
                List.of(), null, null, false, null, null, null, List.of(), null, null,
                e == null ? null : e.getNiveauCecrl(), null);
    }

    /** Lecture de la table de passage, dans les termes de la grille. */
    static String regleNiveau(ProductionEvaluationProperties.NiveauCecrl s) {
        return "Compétence ≥ " + texte(s.getSeuilB2()) + " : B2 · ≥ " + texte(s.getSeuilB1()) + " : B1 · ≥ "
                + texte(s.getSeuilA2()) + " : A2 · > 0 : A1 · 0 : A1 non atteint "
                + "(compétence = moyenne des critères porteurs ; note 0 ⇒ A1 non atteint).";
    }

    private static Map<String, BigDecimal> poidsParCode(Object criteres) {
        Map<String, BigDecimal> out = new LinkedHashMap<>();
        if (!(criteres instanceof List<?> list)) return out;
        for (Object c : list) {
            if (c instanceof Map<?, ?> m && m.get("code") != null && m.get("poids") instanceof Number n) {
                out.put(m.get("code").toString(), new BigDecimal(n.toString()));
            }
        }
        return out;
    }

    /** Chaque critère de la tâche porte-t-il un poids déclaré par la grille ? */
    private static boolean toutesPonderees(Object criteres, Map<String, BigDecimal> poids) {
        return criteres instanceof List<?> list && !list.isEmpty() && poids.size() == list.size();
    }

    private static NiveauCecrl niveau(Object raw) {
        if (raw == null) return null;
        try {
            return NiveauCecrl.valueOf(raw.toString());
        } catch (IllegalArgumentException e) {
            return null;
        }
    }

    private static BigDecimal nombre(double v) {
        return BigDecimal.valueOf(v);
    }

    private static String texte(double v) {
        return BigDecimal.valueOf(v).stripTrailingZeros().toPlainString().replace('.', ',');
    }
}
