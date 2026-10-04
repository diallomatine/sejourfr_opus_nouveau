package com.sejourfr.app.dto;

import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.JourneyLockReason;
import com.sejourfr.app.enums.JourneyProgressUnit;
import com.sejourfr.app.enums.JourneyStepPurpose;
import com.sejourfr.app.enums.JourneyStepStatus;
import com.sejourfr.app.enums.JourneyStepType;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.SkillTaskCode;

import java.util.List;
import java.util.UUID;

/**
 * Une etape du parcours, telle que les fronts la lisent.
 *
 * <h2>🛑 Le serveur sert des FAITS, la phrase appartient aux fronts</h2>
 * <p>C'est la doctrine de tout l'existant — {@code PlanPathStepKind},
 * {@code PlanDomainAssessmentKind}, {@code PlanChangeDto},
 * {@code PreparationEtape} le disent chacun explicitement. Sont donc servis
 * {@link #type()}, {@link #purpose()}, {@link #bloc()}, {@link #section()},
 * {@link #taskCode()}, {@link #skillCode()}, {@link #skillTitle()},
 * {@link #progress()}, {@link #locked()} et {@link #position()}.
 *
 * <p>Sont <b>composes par les fronts</b>, dans leurs libelles miroirs
 * ({@code lib/plan-domain.ts} ⇄ {@code screens/plan/plan_labels.dart}) :
 * « Expression écrite · Tâche 1 », « Vérifier mes progrès », « Évaluer mon
 * niveau », « Déjà maîtrisée ». Les servir ouvrirait une 7<sup>e</sup> copie de
 * libelles dans le depot.
 *
 * <p>{@link #skillTitle()} est la seule chaine servie, et ce n'est pas une
 * phrase : c'est {@code skills.title}, un <b>fait editorial</b> du referentiel,
 * que les deux fronts affichent deja tel quel partout ailleurs.
 */
public record JourneyStepDto(
        UUID id,
        JourneyStepType type,
        /** Non {@code null} pour les seules etapes {@code SECTION_EXAM}. */
        JourneyStepPurpose purpose,
        /**
         * 🛑 <b>Derive a la lecture, jamais persiste</b> (arbitrage D-7) : il
         * depend du verrou du candidat, donc un abonnement souscrit le change
         * sans aucune ecriture en base.
         */
        JourneyStepStatus status,
        /** {@code null} pour une etape {@code DIAGNOSTIC} seulement. */
        JourneyBlocRefDto bloc,
        /**
         * <b>L'unite travaillable, servie</b> — competence TCF ou unite
         * officielle civique, et l'ecran ne branche pas (D-50).
         *
         * <p>🛑 {@code null} hors {@code TRAIN_SKILL}. ⚠️ {@code skillCode} et
         * {@code skillTitle} restent servis pour ce qu'ils portent d'autre (la
         * seance, l'exercice recommande) ; le <b>titre de la ligne</b> se lit
         * ici.
         */
        JourneyUniteRefDto unite,
        /** Le domaine de la competence. {@code null} hors {@code TRAIN_SKILL}. */
        SkillSection section,
        /**
         * La tache officielle de la competence. 🛑 <b>{@code null} = competence
         * de COMPREHENSION</b> : CO/CE n'ont ni tache ni petit sujet. C'est le
         * discriminant que les fronts lisent pour composer deux sous-titres
         * differents — mais <b>pas</b> pour deviner l'unite de progression,
         * qui est servie ({@link JourneyProgressDto#unit()}).
         */
        SkillTaskCode taskCode,
        String skillCode,
        String skillTitle,
        UUID lotId,
        UUID sourceAssessmentId,
        long position,
        /** {@code null} hors {@code TRAIN_SKILL} : un examen ne se compte pas. */
        JourneyProgressDto progress,
        /**
         * <b>Cette etape ne peut pas etre menee a son terme avec l'acces du
         * candidat</b> (R16, §5 bis).
         *
         * <p>🛑 Une etape verrouillee reste <b>affichee a sa place</b> et ne
         * <b>prend jamais la main</b> : c'est ce qui empeche un compte gratuit
         * de voir son parcours se figer definitivement sur une etape qu'il ne
         * peut pas finir (arbitrage D-1), sans pour autant la lui cacher
         * (contradiction #1 du depot, tranchee le 2026-08-21 : « le Plan reste
         * integralement visible »).
         *
         * <p>⚠️ <b>Elle peut en revanche etre NOMMEE</b> (D-60, 2026-09-20) :
         * quand le bloc meneur n'offre rien d'executable, la premiere etape
         * ouverte de ce bloc est servie dans {@code JourneyDto.current} avec
         * {@code locked: true} et le statut {@code CURRENT}. Le parcours reste
         * {@code LOCKED} — ce champ, et lui seul, dit qu'on ne lance rien.
         */
        boolean locked,
        /**
         * <b>Pourquoi</b> l'etape est verrouillee : {@code PROGRESSION} (D-15,
         * une etape du meme bloc reste a faire) ou {@code ACCESS} (l'acces du
         * candidat). {@code null} si et seulement si {@link #locked()} est faux.
         *
         * <p>🛑 Quand les deux s'appliquent a un examen de bloc,
         * {@code PROGRESSION} l'emporte : c'est la condition a remplir d'abord,
         * et les etapes du bloc portent deja leur propre verrou d'acces.
         */
        JourneyLockReason lockReason,
        /**
         * <b>Par quoi mesurer cette epreuve</b> — l'action que la carte lance,
         * non {@code null} pour les seules etapes {@code SECTION_EXAM}.
         *
         * <h3>🛑 Ce n'est pas un second moteur, c'est le MEME resolveur</h3>
         * <p>{@code PlanDomainAssessmentResolver.pour(EpreuveType)}
         * est publique depuis le 2026-09-16 precisement pour que « mesurer ce
         * domaine » veuille dire la meme chose partout : la fiche d'un domaine,
         * « Completer mon profil », l'Accueil, Reviser, la ligne
         * {@code A_EVALUER} de la seance — et desormais le parcours. Le
         * parcours ne <b>compose</b> aucune action, il <b>relaie</b> celle de
         * son autorite.
         *
         * <h3>Pourquoi elle est servie, alors que A18 dit le contraire</h3>
         * <p>A18 (« le parcours designe, le Plan execute ») tenait tant que
         * l'action se retrouvait dans le Plan. Elle ne s'y retrouve <b>pas</b>
         * pour un point d'etape {@code REASSESS} : {@code domainesAEvaluer} ne
         * liste que les epreuves <b>jamais mesurees</b> (c'est sa definition),
         * et la seance ne porte que la mesure <b>indispensable</b>. Un
         * checkpoint sur une epreuve deja mesuree n'avait donc aucune action
         * resoluble, et les fronts retombaient sur {@code currentPriority} —
         * une <b>autre competence</b> que celle annoncee.
         */
        PlanDomainAssessmentDto assessment,
        /**
         * <b>Le micro-exercice que cette etape LANCE</b> — non {@code null} pour
         * les seules etapes {@code TRAIN_SKILL} dont la competence a du contenu.
         *
         * <h3>🛑 Meme raisonnement qu'{@link #assessment()} (A24), meme cause</h3>
         * <p>A18 (« le parcours designe, le Plan execute ») ne tient que si
         * l'action se retrouve dans le Plan. Elle ne s'y retrouve <b>pas</b> :
         * {@code LearningPlanDto.currentPriority} + {@code nextPriorities} est
         * une <b>vue bornee</b> ({@code display.prioritiesMaxActions} = 5), la
         * file ne l'est pas. Un cycle portant six competences ou plus avait donc
         * des etapes sans aucune action resoluble, et le garde-fou « une ligne ne
         * lance jamais autre chose que l'etape qu'elle annonce » les rendait
         * <b>sans bouton</b> : un cul-de-sac. C'est ce qu'on voyait sur
         * l'expression ecrite, servie apres l'expression orale dans le classement.
         *
         * <h3>Relaye, jamais compose</h3>
         * <p>{@code RecommendedExerciseSelector} reste l'<b>unique</b> autorite
         * du « quel sujet proposer sur cette competence ». Le parcours en devient
         * un lecteur de plus, par son <b>lot</b>
         * ({@code selectAll(userId, skills, access)}) appele <b>une seule fois</b>
         * pour tout le parcours : le cout ne grandit pas avec le nombre d'etapes.
         *
         * <p>🛑 {@link #locked()} <b>ne se derive pas</b> de
         * {@code exercise.locked()} : le verrou d'une etape est celui que
         * {@code JourneyReadService} calcule (R16, §5 bis), et un sujet
         * verrouille reste recommande — savoir quoi travailler est justement ce
         * que le Plan apporte.
         */
        PlanRecommendedExerciseDto exercise,
        /**
         * <b>Quand l'etape a ete close</b> — {@code journey_step.closed_at},
         * lu tel quel. {@code null} tant qu'elle est ouverte (et pour toujours
         * sur une etape {@code NON_FAITE} d'un cycle clos).
         */
        java.time.Instant closedAt,
        /**
         * <b>Ce que l'examen qui a clos cette etape a donne</b> (palier TCF ou
         * score civique). 🛑 <b>Servi par la seule consultation d'un cycle
         * clos</b> : {@code null} dans le Plan courant, qui ne le lit pas, et
         * {@code null} = inconnu partout ailleurs.
         */
        JourneyExamResultDto resultat,
        /**
         * <b>L'examen blanc de theme que cette etape LANCE</b> — non
         * {@code null} pour les seules etapes {@code SECTION_EXAM} d'un bloc
         * <b>civique</b> (le TCF porte {@link #assessment()}).
         *
         * <p>🛑 Meme raisonnement qu'{@code assessment} (A24) : sans action
         * servie, l'etape d'examen d'un theme n'avait aucun bouton. ⚠️
         * {@link #locked()} reste l'autorite du verrou de l'etape.
         * {@code null} sur un cycle clos (consultation, aucune action).
         */
        JourneyThemeExamDto examenTheme,
        /**
         * <b>Les sujets de cette etape</b> — le perimetre de l'ecran d'etape
         * d'une competence d'<b>expression</b>, par rang d'affichage croissant
         * ({@code LearningPlanStep.scope}). Jamais {@code null} : vide hors
         * {@code TRAIN_SKILL} d'expression, sur une etape close et sur une
         * archive.
         *
         * <h3>🛑 Meme cause qu'{@link #exercise()} (A24)</h3>
         * <p>Les fronts retrouvaient ce perimetre dans
         * {@code LearningPlanDto.currentPriority} + {@code nextPriorities} +
         * {@code completedSteps} : une <b>vue bornee</b>, que la file depasse.
         * Une etape EO du cycle absente de ces listes ouvrait la fiche des 15
         * sujets (« Tous · 15 ») au lieu de ses 5 (bug du 2026-10-04). Le
         * perimetre est donc servi sur l'etape elle-meme, depuis le <b>meme</b>
         * compteur que {@link #progress()} et que la cloture
         * ({@code etapesAuQuota}) : l'ecran montre exactement les sujets qui
         * valident l'etape. {@code size() == progress.quota} quand l'etape en a.
         */
        List<UUID> stepPromptIds,
        /** Sujets de l'etape <b>valides</b> — {@code 0} hors expression. */
        int stepValidatedCount,
        /**
         * Tous les sujets de l'etape traites
         * ({@code LearningPlanStep.Progress.completed()}), servi : aucun front
         * ne compare {@code done} et {@code quota} lui-meme.
         */
        boolean stepCompleted
) {

    /**
     * L'avancement d'une etape d'entrainement.
     *
     * @param unit 🛑 <b>Servie</b>, jamais deduite de la nullite de
     *             {@code taskCode} : la deduire reviendrait a recopier une regle
     *             du referentiel dans deux fronts.
     */
    public record JourneyProgressDto(int done, int quota, JourneyProgressUnit unit) {}
}
