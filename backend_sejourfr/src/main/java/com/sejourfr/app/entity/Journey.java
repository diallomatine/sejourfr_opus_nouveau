package com.sejourfr.app.entity;

import com.sejourfr.app.dto.JourneyObjectifRefDto;
import com.sejourfr.app.enums.JourneyObjectifKind;
import com.sejourfr.app.enums.JourneyStatus;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.enums.TargetProcedure;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.UuidGenerator;

import java.time.Instant;
import java.util.UUID;

/**
 * Un <b>cycle</b> du parcours d'un candidat, borne par {@code (candidat,
 * module)} et par son {@link JourneyStatus}.
 *
 * <p>Cette table n'est qu'une <b>enveloppe</b> : elle porte l'identite du cycle,
 * son compteur de positions et les deux faits que rien ne permet de recalculer —
 * son <b>statut</b> et son <b>niveau de sortie</b>. Tout ce qui se lit a
 * l'ecran — le statut de chaque etape, le verrou, l'etape courante, « bloc
 * termine », « cycle termine » — se <b>derive a la lecture</b> (D-7, maintenu en
 * entier par D-14), et tout ce qui se mesure — priorites, niveau courant,
 * maitrise — vit chez ses autorites existantes.
 *
 * <p>🛑 <b>Un seul cycle EN_COURS et un seul EN_ATTENTE par (candidat,
 * module)</b> (D-13), tenus par deux index uniques partiels. Les
 * {@link JourneyStatus#HISTORISE} sont libres et multiples : ils <b>sont</b>
 * l'historique des cycles.
 *
 * <p>🛑 <b>Pas de cycle sans niveau cible</b> (arbitrage D-3). Un candidat qui
 * n'a pas declare sa demarche n'a <b>aucune ligne ici</b> : l'API rend
 * {@code NEEDS_OBJECTIVE} et l'ecran propose « Choisir mon objectif ». Creer un
 * cycle « par defaut » reviendrait a choisir un objectif a sa place, et a batir
 * une file sur cette supposition.
 *
 * <p><b>Changer d'objectif ne detruit rien, et ne recree rien</b> : le cycle
 * EN_COURS <b>survit</b> et son {@link #targetLevel} est mis a jour.
 * L'historiser jetterait le plan que le candidat a sous les yeux, et un
 * ping-pong d'objectif polluerait son historique de cycles ; les priorites
 * d'une competence ne deviennent pas fausses parce que la cible a bouge — seul
 * l'<b>ordre</b> des lots s'en trouve recalcule, et il est deja derive a la
 * lecture. ⚠️ Cela <b>revoque</b> R18 « on bascule vers le parcours de ce
 * niveau, l'ancien est conserve tel quel », qui reposait sur une unicite par
 * niveau cible que D-13 a supprimee. Un changement d'objectif ne force toujours
 * <b>jamais</b> un nouveau diagnostic.
 */
@Entity
@Table(name = "journey")
@Getter
@Setter
public class Journey {

    @Id
    @UuidGenerator
    @Column(columnDefinition = "uuid")
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    /**
     * Le niveau vise par ce parcours — l'objectif d'un cycle <b>TCF</b>.
     *
     * <p>🛑 <b>{@code null} sur un cycle CIVIQUE</b>, dont l'objectif est une
     * mention ({@link #targetProcedure}). V069 a leve le {@code NOT NULL} de
     * V066 et pose {@code chk_journey_objectif} : <b>exactement un</b> des deux.
     * « Pas de parcours sans objectif » (D-3) vaut toujours — c'est la
     * contrainte qui le dit maintenant, pas la nullabilite d'une colonne.
     *
     * <p>🛑 Il est <b>lu</b> chez {@code TargetProcedure.niveauVise(procedure,
     * declare)} au moment de la creation, jamais recalcule ici : la table des
     * paliers a deja vecu en six copies dans ce depot.
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "target_level", length = 8)
    private TargetLevel targetLevel;

    /**
     * Le module prepare par ce cycle. Avec {@code user}, c'est la <b>cle
     * d'unicite</b> : les deux modules se preparent en parallele, donc deux
     * cycles en cours simultanes sont normaux — deux du <b>meme</b> module ne le
     * sont jamais.
     *
     * <p>⚠️ Personne n'ecrit {@link Module#CIVIQUE} aujourd'hui : le civique
     * sort du chantier (D-23) et son plan reste integralement derive.
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "module", nullable = false, length = 16)
    private Module module = Module.TCF;

    /**
     * 🛑 <b>Persiste, et ce n'est pas un derive</b> : c'est une memoire
     * d'ordonnancement (D-14). Voir {@link JourneyStatus} pour l'argument
     * complet, et pourquoi {@code JourneyStepStatus} reste derive a la lecture.
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 16)
    private JourneyStatus status = JourneyStatus.EN_COURS;

    /**
     * Le niveau global au demarrage du cycle : le niveau de sortie du precedent,
     * ou celui du diagnostic pour le premier (D-12).
     *
     * <p>🛑 {@code null} = <b>inconnu, jamais mauvais</b>. Un cycle ouvert avant
     * toute mesure n'a pas de niveau d'entree, et cette absence ne vaut surtout
     * pas « le palier le plus bas ».
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "entry_level", length = 8)
    private TargetLevel entryLevel;

    /**
     * Le niveau global <b>ecrit a l'historisation</b>, jamais recalcule ensuite
     * (D-12).
     *
     * <p>C'est un <b>fait date</b> : « voila ou en etait le candidat quand ce
     * cycle s'est ferme ». Le relire a la demande le ferait reinterpreter par le
     * moteur du jour, et un recalibrage de seuils reecrirait retroactivement son
     * histoire. Meme argument que {@code journey_step.resolution}, qui ne dit
     * jamais « acquise aujourd'hui ». Reste {@code null} si le cycle se ferme
     * sans qu'aucune epreuve n'ait ete mesuree.
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "exit_level", length = 8)
    private TargetLevel exitLevel;

    /**
     * L'objectif d'un cycle <b>CIVIQUE</b> : la demarche visee.
     *
     * <p>🛑 <b>C'est un OBJECTIF, jamais un pool de questions.</b> L'arrete du
     * 10 octobre 2025 pose <b>un</b> programme pour toutes les mentions, sur une
     * seule annexe I (D-27, D-42) : la mention dit ce que le candidat vise -- la
     * demarche et son seuil --, elle ne filtre rien.
     *
     * <p>🛑 <b>Exclusif de {@link #targetLevel}</b> ({@code chk_journey_objectif}) :
     * un cycle a UN objectif, du type de son module. Ni les deux, ni aucun -- « pas
     * de parcours sans niveau cible » (D-3) vaut pour les deux modules.
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "target_procedure", length = 16)
    private TargetProcedure targetProcedure;

    /**
     * Score civique a l'entree du cycle, sur le format de l'epreuve.
     *
     * <p>🛑 <b>Colonne NEUVE, et pas une reinterpretation de {@link #entryLevel}</b>
     * (D-32) : un score n'est pas un niveau. Les deux coexistent, chacune pour son
     * module.
     *
     * <p>🛑 <b>Aucun plafond en base</b>, et c'est voulu : le maximum est
     * {@code CivicExamFormat.QUESTIONS}, qui est son autorite unique. Un
     * {@code BETWEEN 0 AND 40} en aurait fait une 2<sup>e</sup> copie -- un
     * changement de l'arrete demanderait alors une migration la ou il doit
     * demander une ligne de code. Le plafond est verifie par un <b>test
     * normatif</b>, qui le lit chez {@code CivicExamFormat}.
     */
    @Column(name = "entry_score")
    private Short entryScore;

    /** Score civique persiste a l'historisation. Meme regle qu'{@link #entryScore}. */
    @Column(name = "exit_score")
    private Short exitScore;

    /**
     * La date d'historisation. <b>Obligatoire des que le statut l'est</b>, et
     * interdite sinon ({@code chk_journey_historisation}) : un cycle historise
     * dont personne ne sait QUAND il s'est ferme serait impossible a ranger dans
     * un historique.
     */
    @Column(name = "historise_at")
    private Instant historiseAt;

    /**
     * La prochaine position libre de la file. <b>Monotone</b> : jamais
     * decremente, jamais renumerote.
     *
     * <p>C'est ce qui rend R4 vrai — « toute nouvelle etape se range apres tout
     * ce qui est deja planifie ». Renumeroter ferait bouger un parcours que le
     * candidat a sous les yeux, et rendrait l'ordre dependant du moment de la
     * lecture.
     */
    @Column(name = "next_position", nullable = false)
    private long nextPosition = 1L;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @PrePersist
    void prePersist() {
        Instant now = Instant.now();
        if (createdAt == null) createdAt = now;
        if (updatedAt == null) updatedAt = now;
    }

    @PreUpdate
    void preUpdate() {
        updatedAt = Instant.now();
    }

    // ------------------------------------------------------------------------
    // L'OBJECTIF, LU SANS SAVOIR DE QUEL MODULE ON PARLE
    // ------------------------------------------------------------------------
    // 🛑 Meme geste que `blocRef()` / `poserBloc()` sur JourneyStep et
    // JourneyLot (D-47, A47) : les appelants lisent `objectifRef()` et ne
    // savent plus si c'est un palier CECRL ou une mention. C'est ce qui a permis
    // de traiter les 57 occurrences d'EpreuveType a la source plutot qu'en 57
    // branchements, et le raisonnement vaut ici mot pour mot.

    /**
     * L'objectif de ce cycle, tel qu'il se sert.
     *
     * <p>{@code null} n'arrive pas sur une ligne valide : la base exige
     * exactement un des deux objectifs. Le rendre quand meme evite qu'une
     * lecture defensive invente un objectif par defaut.
     */
    public JourneyObjectifRefDto objectifRef() {
        if (targetLevel != null) {
            return new JourneyObjectifRefDto(
                    JourneyObjectifKind.NIVEAU, targetLevel.name(), targetLevel.name());
        }
        if (targetProcedure != null) {
            return new JourneyObjectifRefDto(
                    JourneyObjectifKind.PROCEDURE,
                    targetProcedure.name(),
                    targetProcedure.getLabel());
        }
        return null;
    }

    /**
     * Pose l'objectif TCF, en garantissant l'exclusivite que la base impose.
     *
     * <p>🛑 Deux setters nus laisseraient poser les deux, et
     * {@code chk_journey_objectif} ne refuserait qu'au flush — loin de la ligne
     * fautive.
     */
    public void poserObjectif(TargetLevel niveau) {
        this.targetLevel = niveau;
        this.targetProcedure = null;
    }

    /** Pose l'objectif civique. Voir {@link #poserObjectif(TargetLevel)}. */
    public void poserObjectif(TargetProcedure mention) {
        this.targetProcedure = mention;
        this.targetLevel = null;
    }

    /** Reserve la position suivante. Appele sous le verrou du parcours (R14). */
    public long consommerPosition() {
        long position = nextPosition;
        nextPosition = position + 1;
        return position;
    }
}
