package com.sejourfr.app.service;

import com.sejourfr.app.config.ProductionEvaluationProperties;
import com.sejourfr.app.enums.ConfianceEvaluation;
import com.sejourfr.app.enums.NiveauCecrl;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Seconde passe d'evaluation LLM, declenchee <b>uniquement en zone floue</b>.
 *
 * <p>Une seule passe par defaut : reinterroger systematiquement un modele a
 * temperature 0 coute le double pour presque rien. La seconde passe n'a de sens
 * que la ou la premiere est peu sure :
 * <ul>
 *   <li>confiance declaree {@code FAIBLE} ;</li>
 *   <li>competence a moins de {@code marge-seuil-niveau} points d'un seuil de
 *       niveau (la note bascule d'un palier a l'autre pour un dixieme) ;</li>
 *   <li>niveau du LLM divergent de plus d'un palier du niveau calcule serveur.</li>
 * </ul>
 *
 * <p>Arbitrage entre les deux passes : on retient la <b>plus basse</b> — le
 * biais mesure au banc est vers l'indulgence — et on <b>abaisse la confiance</b>
 * des qu'elles ne disent pas la meme chose. On garde la passe retenue
 * <b>entiere</b> (feedback, criteres, note, niveau) : melanger la note d'une
 * passe avec les commentaires de l'autre produirait une correction incoherente.
 *
 * <p>Pilote par {@code sejourfr.production-evaluation.seconde-passe.enabled}
 * (defaut <b>false</b>). La seconde passe reutilise obligatoirement le meme
 * client que la premiere : changer le correcteur reste une operation atomique.
 */
@Service
@Slf4j
public class ProductionSecondePasseService {

    private final ProductionEvaluationProperties props;
    private final EvaluationLlmClient client;
    private final ProductionRubricsProvider rubrics;

    public ProductionSecondePasseService(
            ProductionEvaluationProperties props,
            EvaluationLlmClient client,
            ProductionRubricsProvider rubrics) {
        this.props = props;
        this.client = client;
        this.rubrics = rubrics;
    }

    public boolean isEnabled() {
        return props.getSecondePasse().isEnabled();
    }

    /** Même client LLM que la première passe. */
    public EvaluationLlmClient client() {
        return client;
    }

    /**
     * Raisons qui justifient une seconde passe. Liste vide = zone sure, une
     * seule passe. Ne consulte JAMAIS le drapeau : c'est l'appelant qui decide
     * de declencher (cf. {@link #isEnabled()}), ce qui rend la regle testable
     * independamment de la config.
     */
    public List<String> raisonsZoneFloue(ConfianceEvaluation confiance, BigDecimal competence,
                                         NiveauCecrl niveauIa, NiveauCecrl niveauCalcule) {
        List<String> raisons = new ArrayList<>();
        if (confiance == ConfianceEvaluation.FAIBLE) {
            raisons.add("confiance FAIBLE sur la premiere passe");
        }
        String seuil = seuilFrontiere(competence);
        if (seuil != null) {
            raisons.add("competence " + competence + " a la frontiere du seuil " + seuil);
        }
        if (niveauIa != null && niveauCalcule != null
                && Math.abs(niveauIa.ordinal() - niveauCalcule.ordinal()) > 1) {
            raisons.add("niveau LLM (" + niveauIa + ") divergent de plus d'un palier du calcul serveur ("
                + niveauCalcule + ")");
        }
        return raisons;
    }

    /**
     * Seuil de niveau dont la competence est distante de moins de la marge
     * configuree, ou null si elle n'est a la frontiere d'aucun seuil.
     */
    private String seuilFrontiere(BigDecimal competence) {
        if (competence == null) return null;
        double marge = props.getSecondePasse().getMargeSeuilNiveau();
        ProductionEvaluationProperties.NiveauCecrl seuils = rubrics.niveauCecrl();
        double c = competence.doubleValue();
        if (Math.abs(c - seuils.getSeuilB2()) < marge) return "B2 (" + seuils.getSeuilB2() + ")";
        if (Math.abs(c - seuils.getSeuilB1()) < marge) return "B1 (" + seuils.getSeuilB1() + ")";
        if (Math.abs(c - seuils.getSeuilA2()) < marge) return "A2 (" + seuils.getSeuilA2() + ")";
        return null;
    }

    /**
     * Arbitre entre les deux passes : retient la plus basse (niveau d'abord,
     * note ensuite ; a egalite, la premiere), abaisse sa confiance d'un cran si
     * les passes divergent, et trace le comparatif dans son feedback sous la
     * cle {@code seconde_passe} (materiau du banc de mesure).
     */
    public Passe arbitrer(Passe p1, Passe p2, List<String> raisons, UUID submissionId) {
        boolean divergent = p1.niveauCalcule() != p2.niveauCalcule()
            || compareNote(p1.note(), p2.note()) != 0;
        Passe retenue = plusBasse(p1, p2);

        Map<String, Object> trace = new LinkedHashMap<>();
        trace.put("declenchee", true);
        trace.put("raisons", List.copyOf(raisons));
        trace.put("passe_1", descripteur(p1));
        trace.put("passe_2", descripteur(p2));
        trace.put("passe_retenue", retenue == p1 ? 1 : 2);
        trace.put("divergente", divergent);
        retenue.feedback().put("seconde_passe", trace);

        if (divergent) {
            abaisserConfiance(retenue.feedback());
        }
        log.info("Seconde passe submission={} raisons={} : p1={} vs p2={} -> retenue={} (divergente={})",
            submissionId, raisons, descripteur(p1), descripteur(p2),
            retenue == p1 ? "1" : "2", divergent);
        return retenue;
    }

    /** Niveau d'abord, note ensuite ; a egalite parfaite, la premiere passe. */
    private static Passe plusBasse(Passe p1, Passe p2) {
        int parNiveau = compareNiveau(p1.niveauCalcule(), p2.niveauCalcule());
        if (parNiveau != 0) return parNiveau < 0 ? p1 : p2;
        return compareNote(p1.note(), p2.note()) <= 0 ? p1 : p2;
    }

    /** Un niveau inconnu (null) n'est jamais "le plus bas" : il n'informe pas. */
    private static int compareNiveau(NiveauCecrl a, NiveauCecrl b) {
        if (a == null && b == null) return 0;
        if (a == null) return 1;
        if (b == null) return -1;
        return Integer.compare(a.ordinal(), b.ordinal());
    }

    private static int compareNote(BigDecimal a, BigDecimal b) {
        if (a == null && b == null) return 0;
        if (a == null) return 1;
        if (b == null) return -1;
        return a.compareTo(b);
    }

    /**
     * Descend la confiance d'un cran (HAUTE → MOYENNE → FAIBLE) et l'explique.
     * Deux modeles qui ne tombent pas d'accord, c'est par definition moins sur.
     */
    private static void abaisserConfiance(Map<String, Object> feedback) {
        ConfianceEvaluation actuelle = ConfianceEvaluation.parse(feedback.get("confiance"));
        ConfianceEvaluation abaissee = switch (actuelle == null ? ConfianceEvaluation.MOYENNE : actuelle) {
            case HAUTE -> ConfianceEvaluation.MOYENNE;
            case MOYENNE, FAIBLE -> ConfianceEvaluation.FAIBLE;
        };
        feedback.put("confiance", abaissee.name());
        List<String> raisons = new ArrayList<>();
        if (feedback.get("confiance_raisons") instanceof List<?> l) {
            for (Object r : l) if (r != null) raisons.add(r.toString());
        }
        raisons.add("deux évaluations indépendantes ont abouti à des résultats différents");
        feedback.put("confiance_raisons", raisons);
    }

    private static Map<String, Object> descripteur(Passe p) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("modele", p.modele());
        m.put("note", p.note());
        m.put("niveau_calcule", p.niveauCalcule() == null ? null : p.niveauCalcule().name());
        m.put("niveau_llm", p.niveauIa() == null ? null : p.niveauIa().name());
        return m;
    }

    /**
     * Resultat complet d'une passe d'evaluation, apres tous les traitements
     * serveur (note recalculee, niveau calcule, plafonds). Une passe est
     * indivisible : on la retient ou on la jette en entier.
     */
    public record Passe(
        Map<String, Object> feedback,
        BigDecimal note,
        NiveauCecrl niveauIa,
        NiveauCecrl niveauCalcule,
        String modele
    ) {
    }
}
