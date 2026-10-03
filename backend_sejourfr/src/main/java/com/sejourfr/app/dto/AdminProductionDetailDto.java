package com.sejourfr.app.dto;

import com.sejourfr.app.enums.AdminCalculStatut;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.ProductionEvaluabilite;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Fiche d'une production ({@code GET /api/admin/productions/{submissionId}}).
 * Lecture passive : aucune écriture, aucun appel LLM. Tout ce qui est calculé
 * l'est par le serveur, depuis les mêmes autorités que la notation ; le front
 * n'en recalcule rien. {@code null} = non disponible, jamais 0.
 *
 * @param entete              la ligne de liste de cette production
 * @param evaluationIa        {@code null} sans évaluation (en cours, échec)
 * @param calcul              jamais {@code null} : son {@code statut} dit si le
 *                            calcul a pu être relu
 * @param vueCandidat         le DTO EXACT servi au candidat par
 *                            {@code GET /api/production-submissions/{id}} (même mapper)
 * @param jsonPersiste        {@code ai_evaluations.feedback_json} tel qu'enregistré,
 *                            APRÈS traitement serveur — ce n'est pas la réponse
 *                            de l'IA ; {@code null} sans évaluation
 * @param signalements        tous les signalements, retirés compris, le plus récent d'abord
 * @param signalable          une évaluation existe et aucun signalement n'est actif
 */
public record AdminProductionDetailDto(
        AdminProductionListItemDto entete,
        Sujet sujet,
        Reponse reponse,
        EvaluationIa evaluationIa,
        Calcul calcul,
        ProductionSubmissionDto vueCandidat,
        Technique technique,
        Map<String, Object> jsonPersiste,
        List<AdminProductionFlagDto> signalements,
        boolean signalable
) {

    /**
     * Le sujet tel que reçu par le candidat. La fiche examinateur EO T2 n'en
     * fait pas partie (jamais montrée au candidat). {@code titre} est nullable
     * (contenu antérieur à V028).
     */
    public record Sujet(
            UUID productionTaskId,
            String titre,
            String consigne,
            String contexte,
            String niveauCible,
            Integer motsMin,
            Integer motsMax,
            Integer dureeMinSec,
            Integer dureeMaxSec
    ) {}

    /**
     * La production. EE : {@code texte} + {@code motsCount}. EO :
     * {@code transcription} (texte recollé, celui que le correcteur et le
     * candidat ont lu) + {@code dureeSec}. L'audio n'est JAMAIS conservé.
     */
    public record Reponse(
            String texte,
            Integer motsCount,
            String transcription,
            Integer dureeSec,
            boolean audioConserve,
            String audioMotif,
            TranscriptionInfo transcriptionInfo
    ) {}

    /**
     * Ce qu'on sait de la transcription automatique ; {@code null} hors EO.
     *
     * @param outil          {@code transcriptions.modele_utilise} : {@code whisper-1},
     *                       {@code realtime} (examinateur vocal)…
     * @param coutMicroUsd   coût Whisper en millionièmes de dollar ; {@code null}
     *                       en temps réel (non mesuré)
     */
    public record TranscriptionInfo(
            String outil,
            String langueDetectee,
            Integer dureeAudioSec,
            Boolean qualiteDegradee,
            Double tauxFormesSuspectes,
            Double tauxCollages,
            Double avgLogprob,
            Double noSpeechProb,
            Double compressionRatio,
            Integer coutMicroUsd
    ) {}

    /**
     * La DERNIÈRE évaluation (celle que voit le candidat), scores RETENUS après
     * traitement serveur (couplage, filets) — jamais les notes d'origine de
     * l'IA, qui ne sont pas conservées.
     *
     * @param nbEvaluations      nombre d'évaluations de la production (1 en pratique)
     * @param niveauIa           niveau proposé par l'IA, indicatif ; {@code null} si inconnu
     * @param niveauRetenu       niveau observé (tâche) persisté par le serveur
     * @param ecartNiveauCrans   {@code rang(retenu) - rang(IA)} ; {@code null} si l'un manque
     * @param niveauMontreAuCandidat le candidat voit-il ce niveau (faux sans confiance)
     * @param justificationNiveau texte de l'IA, jamais montré au candidat
     */
    public record EvaluationIa(
            UUID evaluationId,
            ProductionEvaluabilite evaluabilite,
            Instant evaluatedAt,
            long nbEvaluations,
            List<CritereRetenu> criteres,
            BigDecimal noteSur20,
            NiveauCecrl niveauIa,
            NiveauCecrl niveauRetenu,
            Integer ecartNiveauCrans,
            boolean niveauMontreAuCandidat,
            String confiance,
            List<String> confianceRaisons,
            String justificationNiveau,
            List<String> avertissements
    ) {}

    /**
     * Un critère tel qu'il est enregistré. {@code poids} vient de la grille de
     * l'évaluation ({@code null} si elle n'est pas traçable) ; l'échelle est /20.
     */
    public record CritereRetenu(
            String code,
            String label,
            BigDecimal noteSur20,
            BigDecimal poids,
            String bande,
            String commentaire,
            String preuve
    ) {}

    /**
     * Le calcul SejourFR, relu avec la grille de l'évaluation (F-5 A) par les
     * MÊMES fonctions que la notation. Il n'écrit rien : un écart entre le
     * calcul relu et le niveau persisté est affiché ({@code coherent}), jamais
     * corrigé. Hors {@code CALCULE}, seuls {@code statut}, {@code statutLabel},
     * les versions et {@code niveauPersiste} sont renseignés.
     *
     * @param grilleActive         la grille de l'évaluation est celle qui note aujourd'hui
     * @param seuilsDeLaGrille     les seuils viennent du fichier de grille ; {@code false}
     *                             pour les grilles v3 à v4.2, qui les prenaient dans la
     *                             configuration (relus avec la configuration actuelle)
     * @param competence           moyenne des critères porteurs du niveau (4 décimales)
     * @param niveauAvantPlafonds  niveau tiré de la compétence, avant plafonds
     * @param plafondPersiste      {@code feedback_json.plafond_niveau} : plafond réellement
     *                             appliqué à l'époque, {@code null} si aucun
     * @param niveauRecalcule      niveau relu, plafonds compris
     * @param coherent             {@code niveauRecalcule == niveauPersiste} ; {@code null}
     *                             si l'un des deux manque
     */
    public record Calcul(
            AdminCalculStatut statut,
            String statutLabel,
            String rubricsVersion,
            String promptVersion,
            boolean grilleActive,
            String formuleNote,
            BigDecimal noteRecalculee,
            BigDecimal notePersistee,
            List<String> criteresPorteursNiveau,
            BigDecimal competence,
            Seuils seuils,
            boolean seuilsDeLaGrille,
            String regleNiveau,
            NiveauCecrl niveauAvantPlafonds,
            Couplage couplage,
            List<PlafondNiveau> plafondsDeclenches,
            NiveauCecrl plafondPersiste,
            NiveauCecrl niveauRecalcule,
            NiveauCecrl niveauPersiste,
            Boolean coherent
    ) {}

    /** Seuils /20 de la compétence : {@code ≥ b2} B2, {@code ≥ b1} B1, {@code ≥ a2} A2, {@code > 0} A1, 0 A1 non atteint. */
    public record Seuils(BigDecimal a2, BigDecimal b1, BigDecimal b2) {}

    /**
     * Garde-fou de couplage : les critères de réalisation ne dépassent pas
     * {@code moyenne(critères de langue) + ecartMax}.
     *
     * @param plafondRealisation plafond calculé sur les scores retenus ; {@code null}
     *                           si le garde-fou est coupé ou le socle incomplet
     * @param criteresAuPlafond  critères de réalisation EXACTEMENT au plafond : ils ont
     *                           POSSIBLEMENT été ramenés (la note d'origine n'est pas
     *                           conservée, on ne peut pas l'affirmer)
     */
    public record Couplage(
            boolean actif,
            BigDecimal ecartMax,
            List<String> criteresRealisation,
            List<String> criteresLangue,
            BigDecimal plafondRealisation,
            List<String> criteresAuPlafond
    ) {}

    /** Un plafond de niveau dont la condition est remplie sur les scores retenus. */
    public record PlafondNiveau(String regle, NiveauCecrl niveauMax, String declencheur) {}

    /**
     * Ce qui est RÉELLEMENT enregistré sur l'appel. Ni fournisseur, ni durée
     * d'appel, ni tentatives automatiques : rien de cela n'est conservé.
     *
     * @param tokensInput       cumul correction + réparation + seconde passe +
     *                          version ciblée (non ventilable)
     * @param coutMicroUsd      coût en millionièmes de dollar US ({@code null} = inconnu)
     * @param coutLegacyCentimesEuro ancienne colonne (centimes d'euro, arrondis au
     *                          centime supérieur) — ne s'additionne jamais à la précédente
     * @param delaiSoumissionEvaluationSec {@code evaluatedAt - submittedAt} : file
     *                          d'attente + correction, PAS une durée d'appel
     * @param relancesManuelles relances {@code /retry} du candidat (max 3)
     */
    public record Technique(
            String modele,
            String promptVersion,
            String rubricsVersion,
            Integer tokensInput,
            Integer tokensInputCacheHit,
            Integer tokensOutput,
            Integer coutMicroUsd,
            Integer coutLegacyCentimesEuro,
            Instant submittedAt,
            Instant evaluatedAt,
            Long delaiSoumissionEvaluationSec,
            int relancesManuelles,
            String erreurMessage
    ) {}
}
