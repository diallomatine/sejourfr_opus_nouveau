package com.sejourfr.app.entity;

import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.JourneyStepPurpose;
import com.sejourfr.app.enums.JourneyStepResolution;
import com.sejourfr.app.enums.JourneyStepType;
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
 * Une <b>etape</b> de la file : un diagnostic, l'entrainement d'une competence,
 * ou un examen d'epreuve.
 *
 * <h2>Ce qui est persiste, et rien de plus (arbitrage D-7)</h2>
 * <p><b>La structure</b> — quelle etape, dans quel lot, a quelle position, issue
 * de quelle evaluation — et <b>la cloture</b> : {@link #closedAt} +
 * {@link #resolution}, ecrites <b>ensemble</b>, <b>une seule fois</b>, et
 * <b>jamais reouvertes</b>.
 *
 * <p>🛑 <b>Ce qui n'est PAS persiste, et pourquoi.</b>
 * <ul>
 *   <li><b>Le statut d'affichage</b> ({@code JourneyStepStatus}) : les cinq
 *       valeurs se derivent de {@link #closedAt}, {@link #resolution}, l'etat du
 *       lot et l'ordre de cloture. Il n'y a donc aucune colonne {@code status},
 *       et aucun index « une seule CURRENT » — l'unicite vient de la promotion.</li>
 *   <li><b>Le verrou</b> ({@code locked}) : il depend de l'abonnement du
 *       candidat. Le figer obligerait a reecrire la file a chaque paiement ;
 *       derive, un abonnement souscrit change l'ecran sans <b>une seule</b>
 *       ecriture.</li>
 *   <li><b>L'etat de maitrise</b> : {@code SkillMasteryEngine} en est la seule
 *       autorite, et elle se relit.</li>
 *   <li><b>Le code, le titre, le domaine et la tache de la competence</b> : ils
 *       vivent sur {@code skills}. Les recopier ici les ferait deriver le jour
 *       ou un libelle change en console.</li>
 * </ul>
 */
@Entity
@Table(name = "journey_step")
@Getter
@Setter
public class JourneyStep {

    @Id
    @UuidGenerator
    @Column(columnDefinition = "uuid")
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "journey_id", nullable = false)
    private Journey journey;

    /**
     * Le lot auquel cette etape appartient. 🛑 <b>{@code null} = etape hors
     * lot</b> : une etape {@code DIAGNOSTIC}, ou un « Evaluer mon niveau »
     * (R12) — celui-la mesure une epreuve jamais mesuree, il ne clot aucune
     * priorite.
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "lot_id")
    private JourneyLot lot;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private JourneyStepType type;

    /** Non {@code null} pour les seules etapes {@code SECTION_EXAM}. */
    @Enumerated(EnumType.STRING)
    @Column(length = 24)
    private JourneyStepPurpose purpose;

    /**
     * L'epreuve concernee. {@code null} pour une etape {@code DIAGNOSTIC}
     * seulement — elle mesure le candidat, pas une epreuve.
     *
     * <p>Portee <b>aussi</b> par le lot quand il y en a un : les deux s'ecrivent
     * dans la meme transaction depuis la meme valeur, et c'est cette colonne-ci
     * que lisent les filtres par epreuve. Une jointure de plus a chaque lecture
     * d'etape pour un enum immuable n'aurait rien protege.
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "exam_type", length = 20)
    private EpreuveType examType;

    /**
     * La competence travaillee. Non {@code null} pour les seules etapes
     * {@code TRAIN_SKILL}.
     *
     * <p>C'est bien la <b>competence</b> qui est referencee, et pas son code :
     * tous les moteurs que la lecture interroge — {@code SkillMasteryResolver},
     * {@code SkillProgressCounter}, {@code SkillAccessService} — sont indexes
     * par identifiant.
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "skill_id")
    private Skill skill;

    /** La <b>thematique</b> du bloc, pour une etape civique. Exclusive d'{@code examType}. */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "theme_id")
    private Theme theme;

    /**
     * L'<b>unite travaillable</b> d'une etape civique : une des <b>16 unites du
     * programme officiel</b> (V068).
     *
     * <p>🛑 <b>C'est l'obligation de D-47 en base.</b> Le bloc du cycle se
     * rattache a l'<b>unite</b>, jamais a {@code questions.theme_id} : cote
     * PROGRAMME dans la regle <b>PROGRAMME ≠ CORPUS</b> (D-48).
     *
     * <p>🛑 <b>Exclusive de {@link #skill}</b>
     * ({@code chk_journey_step_train_skill}) : une etape d'entrainement porte
     * <b>exactement une</b> unite travaillable — une competence TCF ou une unite
     * officielle civique.
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "official_unit_id")
    private CivicOfficialUnit officialUnit;

    /**
     * Rang de cette priorite <b>dans son lot</b> (0, 1, 2), derive a la creation
     * depuis l'ordre de {@code LearningPlanPriorityResolver.actionable()}.
     *
     * <p>⚠️ <b>Ce n'est pas un score de gravite</b> : aucun entier de ce genre
     * n'existe ailleurs dans le depot. C'est la memoire du rang qu'une
     * evaluation avait donne, au moment ou elle l'a donne.
     */
    @Column(name = "severity_rank")
    private Integer severityRank;

    /** L'evaluation qui a cree cette etape. {@code null} pour un bootstrap sans reference. */
    @Column(name = "source_assessment_id", columnDefinition = "uuid")
    private UUID sourceAssessmentId;

    /**
     * La place de l'etape dans la file. <b>Unique dans un parcours</b>, jamais
     * renumerotee : deux etapes au meme rang rendraient l'election de
     * {@code CURRENT} non deterministe.
     */
    @Column(nullable = false)
    private long position;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    /**
     * 🛑 <b>Ecrite une seule fois, jamais reouverte</b> (D-7). Une competence
     * redevenue fragile ne reouvre pas son etape : elle reviendra par un examen
     * (R7). C'est ce qui empeche le parcours de tourner en rond.
     */
    @Column(name = "closed_at")
    private Instant closedAt;

    @Enumerated(EnumType.STRING)
    @Column(length = 28)
    private JourneyStepResolution resolution;

    @Column(name = "resolved_by_assessment_id", columnDefinition = "uuid")
    private UUID resolvedByAssessmentId;

    @PrePersist
    void prePersist() {
        if (createdAt == null) createdAt = Instant.now();
    }

    public boolean estOuverte() {
        return closedAt == null;
    }

    /**
     * Clot l'etape, <b>si elle ne l'est pas deja</b>.
     *
     * <p>Le garde-fou n'est pas une precaution de style : c'est l'invariant
     * « une cloture ne se reecrit jamais » rendu impossible a violer depuis le
     * code appelant. Un rejeu, une course, un double branchement retombent donc
     * sur la premiere cloture — celle qui est vraie.
     *
     * @return {@code true} si cet appel a effectivement clos l'etape.
     */
    public boolean clore(JourneyStepResolution motif, UUID parEvaluation, Instant quand) {
        if (closedAt != null) return false;
        this.closedAt = quand;
        this.resolution = motif;
        this.resolvedByAssessmentId = parEvaluation;
        return true;
    }
}
