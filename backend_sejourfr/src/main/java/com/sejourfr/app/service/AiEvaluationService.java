package com.sejourfr.app.service;

import com.sejourfr.app.config.ProductionEvaluationProperties;
import com.sejourfr.app.entity.AiEvaluation;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.entity.Transcription;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.SubmissionStatut;
import com.sejourfr.app.exception.AiEvaluationException;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.AiEvaluationManager;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import com.sejourfr.app.manager.TranscriptionManager;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Orchestre l'evaluation IA d'une {@link ProductionSubmission} :
 * construit les prompts, appelle le LLM via {@link EvaluationLlmClient}
 * (provider selectionne par config : Anthropic, OpenAI, ...), persiste
 * {@link AiEvaluation} et passe la submission a EVALUATED.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class AiEvaluationService {

    private static final BigDecimal NOTE_MAX = new BigDecimal("20");

    private final ProductionSubmissionManager submissionManager;
    private final TranscriptionManager transcriptionManager;
    private final AiEvaluationManager aiEvaluationManager;
    private final EvaluationLlmClient llmClient;
    private final EvaluationPromptBuilder promptBuilder;
    private final ProductionRubricsProvider rubrics;
    private final ProductionEvaluationProperties props;

    private static BigDecimal extractNote(Map<String, Object> feedback) {
        Object raw = feedback.get("note_globale");
        if (raw == null) return null;
        try {
            BigDecimal v = new BigDecimal(raw.toString()).setScale(1, RoundingMode.HALF_UP);
            if (v.compareTo(BigDecimal.ZERO) < 0 || v.compareTo(NOTE_MAX) > 0) {
                log.warn("note_globale hors borne [0,20] : {}", v);
                return null;
            }
            return v;
        } catch (NumberFormatException e) {
            log.warn("note_globale non-numerique : {}", raw);
            return null;
        }
    }

    private static NiveauCecrl extractNiveau(Map<String, Object> feedback) {
        Object raw = feedback.get("niveau_cecrl");
        if (raw == null) return null;
        try {
            return NiveauCecrl.valueOf(raw.toString());
        } catch (IllegalArgumentException e) {
            log.warn("niveau_cecrl inconnu : {}", raw);
            return null;
        }
    }

    @Transactional
    public AiEvaluation evaluate(UUID submissionId) {
        ProductionSubmission sub = submissionManager.findById(submissionId)
                .orElseThrow(() -> new NotFoundException("Submission introuvable : " + submissionId));
        ProductionTask task = sub.getProductionTask();
        if (task == null) {
            throw new AiEvaluationException("Submission " + submissionId + " sans production_task.");
        }

        ProductionInput input = loadInput(sub, task);
        Integer dureeSec = task.getEpreuve() == EpreuveType.TCF_EO ? sub.getMediaDurationSec() : null;
        String systemPrompt = promptBuilder.buildSystemPrompt();
        String userPrompt = promptBuilder.buildUserPrompt(task, input.production(), input.litteral(), dureeSec);

        EvaluationLlmClient.Outcome outcome = llmClient.evaluate(systemPrompt, userPrompt);

        // Avertissements construits cote serveur (longueur/duree), injectes dans
        // le feedback expose au front. L'IA ne les produit pas elle-meme.
        Map<String, Object> feedback = new LinkedHashMap<>(outcome.feedback());
        List<String> avertissements = buildAvertissements(sub, task);
        if (!avertissements.isEmpty()) {
            feedback.put("avertissements", avertissements);
        }
        // Joint le `label` des criteres a chaque score (le LLM ne renvoie que le
        // `code`). Source = la rubrique de la tache (fallback DB) : evite au mobile
        // de maintenir une table parallele code→libelle qui derive.
        enrichScoresWithLabels(feedback, task);
        // note_globale calculee SERVEUR a partir des scores par critere ponderes
        // par la rubrique : on ecrase la valeur du LLM (advisory). Garantit la
        // coherence global <-> criteres. Si la rubrique est absente, on conserve
        // la note du LLM (extractNote la relira).
        applyServerComputedNote(feedback, task, submissionId);
        BigDecimal noteSur20 = extractNote(feedback);
        // niveau_cecrl du LLM = advisory (conserve en base, jamais affiche). Le
        // niveau AFFICHE est calcule serveur depuis lexique+morphosyntaxe, comme
        // note_globale. On lit le brut AVANT d'ecraser feedback.niveau_cecrl.
        NiveauCecrl niveauIa = extractNiveau(feedback);
        NiveauCecrl niveauCalcule = applyServerComputedNiveau(feedback, noteSur20, niveauIa, submissionId);

        AiEvaluation eval = new AiEvaluation();
        eval.setSubmission(sub);
        eval.setModeleUtilise(llmClient.getModelName());
        eval.setPromptVersion(llmClient.getPromptVersion());
        eval.setNoteSur20(noteSur20);
        eval.setNiveauCecrl(niveauCalcule);
        eval.setNiveauCecrlIa(niveauIa);
        eval.setFeedbackJson(feedback);
        eval.setTokensInput(outcome.inputTokens());
        eval.setTokensOutput(outcome.outputTokens());
        eval.setCoutEstimeCentimes(outcome.costEstimateCents());
        aiEvaluationManager.save(eval);

        sub.setStatut(SubmissionStatut.EVALUATED);
        sub.setErreurMessage(null);
        submissionManager.save(sub);

        log.info("AiEvaluation persistee submission={} note={} niveau={} (LLM={}) model={}",
                submissionId, noteSur20, niveauCalcule, niveauIa, llmClient.getModelName());
        return eval;
    }

    /**
     * Avertissements affiches a l'utilisateur (construits serveur, hors IA) :
     * <ul>
     *   <li>EE : depassement modere de la limite de mots (tolerance) ;</li>
     *   <li>EO : duree parlee sous la cible / sous le minimum (2 min).</li>
     * </ul>
     */
    private List<String> buildAvertissements(ProductionSubmission sub, ProductionTask task) {
        List<String> out = new ArrayList<>();
        if (task.getEpreuve() == EpreuveType.TCF_EE) {
            Integer mots = sub.getMotsCount();
            Integer max = task.getMotsMax();
            if (mots != null && max != null && mots > max) {
                out.add("Votre texte depasse legerement la limite (" + mots
                    + " mots pour un maximum de " + max + "). A l'examen, restez dans les bornes.");
            }
            return out;
        }
        // TCF_EO
        Integer duree = sub.getMediaDurationSec();
        Integer cible = task.getDureeMaxSec();
        Integer min = task.getDureeMinSec();
        if (duree != null && cible != null && duree < cible) {
            if (min != null && duree < min) {
                out.add("Votre enregistrement est court (" + duree + " s, soit environ "
                    + formatMinutes(duree) + "). Le minimum recommande est de 2 minutes et l'objectif "
                    + cible + " s (~" + formatMinutes(cible) + "). Une production trop courte limite la "
                    + "demonstration de vos competences : votre note en tient compte. Rapprochez-vous "
                    + "de 3 minutes la prochaine fois.");
            } else {
                out.add("Vous avez parle " + duree + " s ; l'objectif est " + cible + " s (~"
                    + formatMinutes(cible) + "). Developpez davantage pour viser le niveau superieur.");
            }
        }
        return out;
    }

    @SuppressWarnings("unchecked")
    private void enrichScoresWithLabels(Map<String, Object> feedback, ProductionTask task) {
        Object scoresObj = feedback.get("scores_criteres");
        // Source UNIQUE des labels = la rubrique de la tache (meme source que les
        // criteres envoyes au LLM). Plus de fallback DB.
        Object grilleObj = rubrics.find(task.getEpreuve(), task.getTacheNumero())
                .map(r -> r.get("criteres"))
                .orElse(null);
        if (!(scoresObj instanceof List<?> scores) || !(grilleObj instanceof List<?> grille)) return;
        Map<String, String> labelByCode = new HashMap<>();
        for (Object g : grille) {
            if (g instanceof Map<?, ?> m) {
                Object code = m.get("code");
                Object label = m.get("label");
                if (code != null && label != null) {
                    labelByCode.put(code.toString(), label.toString());
                }
            }
        }
        if (labelByCode.isEmpty()) return;
        for (Object s : scores) {
            if (s instanceof Map<?, ?> rawMap) {
                Map<String, Object> sm = (Map<String, Object>) rawMap;
                Object existing = sm.get("label");
                if (existing == null || existing.toString().isBlank()) {
                    Object code = sm.get("code");
                    if (code != null) {
                        String lbl = labelByCode.get(code.toString());
                        if (lbl != null) sm.put("label", lbl);
                    }
                }
            }
        }
    }

    /** Au-dela de cet ecart |note_LLM − note_calculee|, on log pour calibration. */
    private static final BigDecimal SEUIL_ECART_CALIBRATION = new BigDecimal("3");

    /**
     * Recalcule {@code note_globale} cote serveur = {@code round(Σ note_sur_20 × poids)}
     * a partir des {@code scores_criteres} et des poids de la rubrique, puis
     * <b>ecrase</b> la valeur du LLM dans {@code feedback}. La note du LLM devient
     * advisory : un ecart > seuil est logue (calibration). Sans rubrique ou sans
     * scores exploitables, on ne touche pas a la note du LLM.
     */
    private void applyServerComputedNote(Map<String, Object> feedback, ProductionTask task, UUID submissionId) {
        Object criteres = rubrics.find(task.getEpreuve(), task.getTacheNumero())
                .map(r -> r.get("criteres")).orElse(null);
        BigDecimal computed = weightedNote(criteres, feedback.get("scores_criteres"));
        if (computed == null) {
            log.warn("note_globale non recalculee serveur (submission={} : rubrique/scores manquants) — "
                + "note LLM conservee.", submissionId);
            return;
        }
        BigDecimal llmNote = extractNote(feedback);
        if (llmNote != null && llmNote.subtract(computed).abs().compareTo(SEUIL_ECART_CALIBRATION) > 0) {
            log.warn("Ecart de notation submission={} : LLM={} vs serveur={} (>{}) — a calibrer.",
                submissionId, llmNote, computed, SEUIL_ECART_CALIBRATION);
        }
        feedback.put("note_globale", computed);
    }

    /**
     * {@code round(Σ note_sur_20[code] × poids[code])}, arrondi a l'entier le plus
     * proche (HALF_UP), borne a [0,20]. Retourne null si les criteres/poids ou les
     * scores sont inexploitables (le hors-sujet — tous les criteres a 0 — rend
     * coherent 0, puisque Σ(0×poids)=0). Package-private pour le test unitaire.
     */
    static BigDecimal weightedNote(Object criteres, Object scoresCriteres) {
        if (!(criteres instanceof List<?> critList) || !(scoresCriteres instanceof List<?> scores)) {
            return null;
        }
        Map<String, BigDecimal> poidsByCode = new HashMap<>();
        for (Object c : critList) {
            if (c instanceof Map<?, ?> m && m.get("code") != null && m.get("poids") instanceof Number n) {
                poidsByCode.put(m.get("code").toString(), new BigDecimal(n.toString()));
            }
        }
        if (poidsByCode.isEmpty()) return null;

        BigDecimal sum = BigDecimal.ZERO;
        boolean any = false;
        for (Object s : scores) {
            if (!(s instanceof Map<?, ?> m)) continue;
            Object code = m.get("code");
            Object note = m.get("note_sur_20");
            if (code == null || !(note instanceof Number noteNum)) continue;
            BigDecimal poids = poidsByCode.get(code.toString());
            if (poids == null) continue;
            sum = sum.add(new BigDecimal(noteNum.toString()).multiply(poids));
            any = true;
        }
        if (!any) return null;
        BigDecimal rounded = sum.setScale(0, RoundingMode.HALF_UP);
        if (rounded.compareTo(BigDecimal.ZERO) < 0) return BigDecimal.ZERO;
        if (rounded.compareTo(NOTE_MAX) > 0) return NOTE_MAX;
        return rounded;
    }

    /**
     * Calcule le {@code niveau_cecrl} SERVEUR depuis lexique+morphosyntaxe et le
     * persiste comme niveau affiche, en <b>ecrasant</b> {@code feedback.niveau_cecrl}
     * (le mobile lit ce champ). Le niveau du LLM ({@code niveauIa}) reste advisory.
     * Si un critere source manque, WARN + fallback sur la moyenne ponderee (note).
     * Logue un compteur de divergence (≥1 cran) IA vs calcul pour la calibration.
     *
     * @return le niveau calcule, ou le niveau LLM si le calcul est impossible.
     */
    private NiveauCecrl applyServerComputedNiveau(Map<String, Object> feedback, BigDecimal noteGlobale,
                                                  NiveauCecrl niveauIa, UUID submissionId) {
        List<String> sourceCodes = props.getNiveauCecrl().getSourceCriteres();
        Object scores = feedback.get("scores_criteres");
        if (!sourceCriteriaPresent(scores, sourceCodes)) {
            log.warn("niveau_cecrl : critere(s) porteur(s) {} manquant(s) dans scores_criteres "
                + "(submission={}) — fallback sur la moyenne ponderee.", sourceCodes, submissionId);
        }
        NiveauCecrl calcule = computeNiveau(scores, sourceCodes, noteGlobale, props.getNiveauCecrl());
        if (calcule == null) {
            log.warn("niveau_cecrl non calculable serveur (submission={}) — niveau LLM conserve.", submissionId);
            return niveauIa; // feedback.niveau_cecrl reste la valeur LLM
        }
        if (niveauIa != null && niveauIa != calcule) {
            String sens = niveauIa.ordinal() < calcule.ordinal() ? "sous-estimation LLM" : "sur-estimation LLM";
            log.info("Divergence niveau submission={} : LLM={} vs calcule={} ({}) — calibration.",
                submissionId, niveauIa, calcule, sens);
        }
        feedback.put("niveau_cecrl", calcule.name());
        return calcule;
    }

    private static boolean sourceCriteriaPresent(Object scoresCriteres, List<String> sourceCodes) {
        if (!(scoresCriteres instanceof List<?> scores)) return false;
        java.util.Set<String> present = new java.util.HashSet<>();
        for (Object s : scores) {
            if (s instanceof Map<?, ?> m && m.get("code") != null && m.get("note_sur_20") instanceof Number) {
                present.add(m.get("code").toString());
            }
        }
        return present.containsAll(sourceCodes);
    }

    /**
     * {@code competence = moyenne(note_sur_20[source-criteres])} → bande CECRL via
     * les seuils config (plafond B2). Hors-sujet ({@code note_globale == 0}) →
     * {@code A1_NON_ATTEINT}. Si un critere source manque, fallback sur la moyenne
     * ponderee deja calculee ({@code note_globale}). Retourne null si rien
     * d'exploitable. Package-private pour le test unitaire.
     */
    static NiveauCecrl computeNiveau(Object scoresCriteres, List<String> sourceCodes,
                                     BigDecimal noteGlobale, ProductionEvaluationProperties.NiveauCecrl seuils) {
        if (noteGlobale != null && noteGlobale.compareTo(BigDecimal.ZERO) == 0) {
            return NiveauCecrl.A1_NON_ATTEINT; // hors-sujet : coherent avec note_globale = 0
        }
        Map<String, BigDecimal> byCode = new HashMap<>();
        if (scoresCriteres instanceof List<?> scores) {
            for (Object s : scores) {
                if (s instanceof Map<?, ?> m && m.get("code") != null && m.get("note_sur_20") instanceof Number n) {
                    byCode.put(m.get("code").toString(), new BigDecimal(n.toString()));
                }
            }
        }
        List<BigDecimal> src = new ArrayList<>();
        for (String code : sourceCodes) {
            BigDecimal v = byCode.get(code);
            if (v != null) src.add(v);
        }

        BigDecimal competence;
        if (!sourceCodes.isEmpty() && src.size() == sourceCodes.size()) {
            competence = moyenne(src);
        } else if (noteGlobale != null) {
            competence = noteGlobale; // fallback : moyenne ponderee des criteres presents
        } else if (!src.isEmpty()) {
            competence = moyenne(src);
        } else {
            return null;
        }

        double c = competence.doubleValue();
        if (c >= seuils.getSeuilB2()) return NiveauCecrl.B2; // plafond B2
        if (c >= seuils.getSeuilB1()) return NiveauCecrl.B1;
        if (c >= seuils.getSeuilA2()) return NiveauCecrl.A2;
        if (c > 0) return NiveauCecrl.A1;
        return NiveauCecrl.A1_NON_ATTEINT;
    }

    private static BigDecimal moyenne(List<BigDecimal> values) {
        BigDecimal sum = BigDecimal.ZERO;
        for (BigDecimal v : values) sum = sum.add(v);
        return sum.divide(BigDecimal.valueOf(values.size()), 4, RoundingMode.HALF_UP);
    }

    private static String formatMinutes(int sec) {
        int m = sec / 60;
        int s = sec % 60;
        if (m == 0) return s + " s";
        return s == 0 ? m + " min" : m + " min " + s + " s";
    }

    private ProductionInput loadInput(ProductionSubmission sub, ProductionTask task) {
        if (task.getEpreuve() == EpreuveType.TCF_EO) {
            Transcription t = transcriptionManager
                    .findLatestBySubmissionId(sub.getId())
                    .orElseThrow(() -> new AiEvaluationException(
                            "Submission EO " + sub.getId() + " sans transcription : Whisper a echoue ou n'a pas tourne."
                    ));
            return new ProductionInput(t.getTexte(), true);
        }
        // EE : texte rendu directement par l'utilisateur.
        if (sub.getTexteSoumis() == null || sub.getTexteSoumis().isBlank()) {
            throw new AiEvaluationException("Submission EE " + sub.getId() + " sans texte_soumis.");
        }
        return new ProductionInput(sub.getTexteSoumis(), false);
    }

    private record ProductionInput(String production, boolean litteral) {
    }
}
