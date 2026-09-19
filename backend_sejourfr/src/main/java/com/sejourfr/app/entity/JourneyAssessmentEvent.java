package com.sejourfr.app.entity;

import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.JourneyAssessmentKind;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.UuidGenerator;

import java.time.Instant;
import java.util.UUID;

/**
 * Une evaluation <b>deja traitee</b> par un parcours.
 *
 * <p>Cette table repond a deux questions, et c'est pour cela qu'elle existe
 * plutot qu'un simple drapeau :
 * <ol>
 *   <li><b>« l'a-t-on deja traitee ? »</b> — R14. Un rafraichissement, un double
 *       envoi mobile, une cloture automatique a echeance suivie d'un
 *       {@code finish} explicite, un rejeu quelconque retombent sur la meme cle
 *       {@code (journey, sourceAssessmentId)}. Meme discipline que
 *       {@code uq_learning_plan_observation_source} et que
 *       {@code production_submissions.client_submission_id} (V046) ;</li>
 *   <li><b>« etait-elle plus ancienne que ce qu'on savait deja ? »</b> — une
 *       evaluation arrivee en retard (synchronisation mobile tardive) est
 *       <b>enregistree</b> mais ne modifie pas la structure de son epreuve.
 *       C'est {@link #completedAt} qui le dit, jamais {@link #processedAt}.</li>
 * </ol>
 *
 * <p>Elle sert <b>aussi</b> le bootstrap (R19) : toutes les evaluations
 * historiques y sont enregistrees d'un coup, ce qui garantit qu'aucune ne sera
 * rejouee ensuite — le parcours est reconstruit, pas replaye.
 */
@Entity
@Table(name = "journey_assessment_event")
@Getter
@Setter
public class JourneyAssessmentEvent {

    @Id
    @UuidGenerator
    @Column(columnDefinition = "uuid")
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "journey_id", nullable = false)
    private Journey journey;

    /**
     * L'identite de l'evaluation : {@code attempts.id} pour un examen,
     * {@code diagnostic_sessions.id} pour un diagnostic rapide,
     * {@code tcf_diagnostic_sessions.id} pour un complet. Pas de cle etrangere :
     * les trois tables sont differentes, et {@link #assessmentKind} dit
     * laquelle.
     */
    @Column(name = "source_assessment_id", nullable = false, columnDefinition = "uuid")
    private UUID sourceAssessmentId;

    @Enumerated(EnumType.STRING)
    @Column(name = "assessment_kind", nullable = false, length = 24)
    private JourneyAssessmentKind assessmentKind;

    /**
     * L'epreuve que cette evaluation a <b>mesuree</b>.
     *
     * <p>🛑 <b>{@code null} pour le seul diagnostic RAPIDE</b> : il produit des
     * priorites sans rendre aucune epreuve « mesuree » (R11). Toute autre
     * evaluation en mesure exactement <b>une</b>, et c'est une propriete du
     * modele d'{@code Attempt}, pas une simplification : les sous-epreuves d'un
     * examen blanc complet et les sections d'un diagnostic complet sont des
     * attempts a part entiere, donc des evenements a part entiere. La base le
     * verrouille ({@code chk_journey_assessment_epreuve_mesuree}).
     *
     * <p>C'est cette colonne qui porte le repere de R14 — « la derniere
     * evaluation deja traitee de cette epreuve » — et non les lots : une epreuve
     * mesuree <b>sans produire de priorite</b> (R9) ne cree aucun lot, et
     * laisserait donc un trou dans la chronologie.
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "exam_type", length = 20)
    private EpreuveType examType;

    /**
     * L'<b>axe civique</b> : la thematique que cette evaluation a mesuree.
     *
     * <p>🛑 <b>Exclusif de {@link #examType}</b>, et lie a la nature par
     * {@code chk_journey_assessment_mesure} (V071) : aucun axe pour les deux
     * diagnostics et pour l'examen civique COMPLET -- qui est un fait global --,
     * la thematique pour un examen de theme, l'epreuve pour tout le TCF.
     *
     * <p>⚠️ Un examen complet ecrit donc <b>six</b> lignes : une globale sans
     * axe, plus une par thematique dont le bloc etait debloque (R1, D-51).
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "theme_id")
    private Theme theme;

    /**
     * Quand l'evaluation s'est <b>terminee</b> — la date qui fait l'ordre des
     * evenements (R14). 🛑 A ne pas confondre avec {@link #processedAt} : une
     * evaluation de mardi synchronisee jeudi porte mardi, et c'est mardi qui
     * decide si elle a quelque chose a apprendre au parcours.
     */
    @Column(name = "completed_at", nullable = false)
    private Instant completedAt;

    /** Quand le parcours l'a traitee. Tracabilite ; ne decide de rien. */
    @Column(name = "processed_at", nullable = false)
    private Instant processedAt;

    @PrePersist
    void prePersist() {
        if (processedAt == null) processedAt = Instant.now();
    }
}
