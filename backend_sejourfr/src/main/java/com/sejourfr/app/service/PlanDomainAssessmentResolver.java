package com.sejourfr.app.service;

import com.sejourfr.app.dto.PlanDomainAssessmentDto;
import com.sejourfr.app.dto.PlanDomainDto;
import com.sejourfr.app.dto.TcfDomainProfileDto;
import com.sejourfr.app.entity.LearningPlanObservation;
import com.sejourfr.app.enums.DureeEpreuve;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.enums.SkillSection;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.EnumSet;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.Set;

/**
 * « <b>Completer mon profil</b> » (brief §3, §6 et §7) : quels domaines du TCF
 * n'ont jamais ete mesures, et <b>par quoi</b> les mesurer.
 *
 * <h2>Le diagnostic est progressif, il n'est plus « fait / pas fait »</h2>
 * Un candidat peut etre evalue sur 0, 1, 2, 3 ou 4 domaines, et le Plan doit
 * fonctionner dans chacun de ces etats. Le <b>compte</b> vit deja sur
 * {@code PlanCycleDto} ({@code domainsEvaluated} / {@code domainsExpected} /
 * {@code profileComplete}) et l'<b>etat</b> de chaque domaine sur
 * {@code PlanDomainDto.evaluated} : ce resolveur ne les recompte pas, il repond
 * a la seule question qui restait sans reponse cote serveur — <b>« et pour
 * l'evaluer, je lance quoi ? »</b>.
 *
 * <h2>🛑 Aucun moteur n'est cree</h2>
 * Les trois natures de {@code PlanDomainAssessmentKind} designent des parcours
 * <b>deja livres</b> : le diagnostic, l'examen blanc de module CO/CE, la
 * production EE/EO. Aucune banque de questions, aucun composant QCM, aucune
 * logique d'{@code Attempt} n'est duplique (brief §5, §84), et le diagnostic
 * n'est jamais un {@code TCF_COMPLET}.
 *
 * <h2>Il n'y a pas de « variante » de diagnostic a persister</h2>
 * « Rapide » (EE + EO) et « complet » (EE + EO + CO + CE) ne different que par
 * ce que le front <b>enchaine</b> apres l'analyse. Le profil reel se lit sur les
 * domaines <b>reellement mesures</b>, jamais sur une intention declaree : une
 * colonne {@code variante} aurait pu affirmer « complet » sur un candidat qui
 * s'est arrete apres l'oral, et deux surfaces auraient repondu differemment a la
 * meme question. Le serveur sert donc ce qui <b>reste a faire</b>, et le front
 * enchaine. Rien n'est ajoute a {@code diagnostic_sessions}, dont
 * {@code user_id} reste {@code NOT NULL}.
 *
 * <h2>Derive a la lecture, jamais persiste</h2>
 * Aucune table, aucune migration, <b>zero requete</b> : tout se decide sur les
 * quatre domaines deja resolus par {@link PlanCycleResolver} et sur un booleen
 * que {@link LearningPlanService} tient deja. Meme philosophie que
 * {@code SkillStatusResolver}, {@code SituationDansNiveau} et
 * {@code PlanCycleDto}.
 */
@Component
public class PlanDomainAssessmentResolver {

    /**
     * Le slot d'examen blanc de module servi pour mesurer un domaine.
     *
     * <p><b>Toujours le premier, et c'est un choix</b> : c'est le seul slot
     * offert a tout compte inscrit — et rejouable a volonte —
     * ({@code AttemptService.enforceMockExamSlotAccess} sort immediatement sous
     * {@code slot <= 1}). <b>Mesurer un domaine ne doit jamais buter sur le
     * paywall</b> : un compte gratuit qui ne pourrait pas completer son profil
     * n'aurait pas de Plan du tout, alors que le Plan reste integralement
     * visible sans abonnement.
     *
     * <p>Servir un slot plus avance n'aurait rien apporte : un domaine qui
     * arrive ici n'a <b>aucun</b> resultat exploitable ({@code TcfProfileService}
     * ecarte deja les examens finis sans une seule reponse), donc la composition
     * du slot 1 lui est de fait inedite. Aucun {@code locked} n'est servi pour
     * la meme raison : il vaudrait {@code false} en toute circonstance, et le
     * depot ne publie pas de champ mort.
     */
    static final int SLOT_OFFERT = 1;

    /**
     * Ce qu'il reste a mesurer, dans l'ordre des epreuves du TCF.
     *
     * <p><b>Jamais {@code null}</b> ; <b>vide</b> quand les quatre domaines sont
     * mesures — c'est l'etat vise, pas une anomalie. Un domaine deja mesure n'y
     * figure <b>pas</b> : le Plan ne propose pas de refaire une mesure qui
     * existe, il propose de travailler (les series ciblees et les petits sujets
     * s'en chargent, sous {@code currentPriority}).
     *
     * @param domaines             les quatre domaines, tels que
     *                             {@link PlanCycleResolver} les a resolus.
     * @param diagnosticTermine    ce candidat a une session de diagnostic
     *                             {@code COMPLETED}. Elle est unique par
     *                             {@code (user, code, version)} : une fois
     *                             terminee, elle ne se rejoue pas, et un domaine
     *                             d'expression encore vide retombe sur une
     *                             production.
     */
    public List<PlanDomainAssessmentDto> resolve(
            List<PlanDomainDto> domaines, boolean diagnosticTermine) {
        if (domaines == null || domaines.isEmpty()) return List.of();
        List<PlanDomainAssessmentDto> restants = new ArrayList<>();
        for (PlanDomainDto domaine : domaines) {
            if (domaine == null || domaine.evaluated()) continue;
            PlanDomainAssessmentDto assessment = pour(domaine.epreuve(), diagnosticTermine);
            if (assessment != null) restants.add(assessment);
        }
        // L'ordre des epreuves du TCF, pas celui des pastilles : les quatre
        // lignes qui arrivent ici portent toutes la meme priorite (A_EVALUER),
        // donc le tri par urgence ne les separe pas et laisserait l'ordre
        // dependre d'un detail de tri stable. Aucun front ne reordonne.
        restants.sort(Comparator.comparingInt(
                item -> TcfDomainProfileDto.ORDRE.indexOf(item.epreuve())));
        return List.copyOf(restants);
    }

    /**
     * <b>La mesure manquante indispensable</b>, ou rien.
     *
     * <p>Elle repond a un cas precis, mesure sur un compte reel : un candidat
     * dont la production <b>orale a bien ete rendue</b> mais dont le correcteur
     * n'a rien pu observer — huit competences {@code NOT_OBSERVED}, aucune
     * probante. Le Plan lui proposait alors des micro-exercices d'ecrit a
     * l'infini sans jamais revenir mesurer son oral, alors que c'est
     * exactement ce qui lui manquait.
     *
     * <p>🛑 <b>C'est la distinction que le brief exige entre les deux sens de
     * {@code NOT_OBSERVED}</b> : « la production etait inutilisable » &rarr; il
     * faut <b>reevaluer</b> (c'est ici) ; « ce palier / cette tache n'a pas
     * encore ete abordee » &rarr; il faut <b>acquerir</b>
     * ({@code PlanAcquisitionSelector}). Le premier sens se lit au grain du
     * <b>domaine</b> — une production ratee emporte toutes les competences de
     * son epreuve —, le second au grain de la competence.
     *
     * <p>A ne pas confondre avec {@link #resolve} : celui-la liste les domaines
     * <b>jamais mesures</b> et alimente « Completer mon profil », un bloc a part.
     * Ici on repond a « qu'est-ce que la seance doit faire en premier ? », et un
     * domaine sans la moindre observation n'y entre pas — le candidat n'a encore
     * rien tente dessus, rien n'a echoue.
     *
     * <p><b>Une seule</b>, la premiere dans l'ordre des epreuves du TCF : une
     * seance ne se remplit pas de mesures. <b>Zero requete</b> — tout se lit sur
     * l'historique deja charge par le Plan et sur les domaines deja resolus.
     *
     * @param domaines          les quatre domaines, tels que
     *                          {@link PlanCycleResolver} les a resolus.
     * @param observations      tout l'historique du candidat, deja charge.
     * @param diagnosticTermine ce candidat a une session de diagnostic
     *                          {@code COMPLETED} — elle ne se rejoue pas.
     */
    public Optional<PlanDomainAssessmentDto> indispensable(
            List<PlanDomainDto> domaines,
            List<LearningPlanObservation> observations,
            boolean diagnosticTermine) {
        if (domaines == null || domaines.isEmpty()) return Optional.empty();
        if (observations == null || observations.isEmpty()) return Optional.empty();

        Set<SkillSection> tentees = EnumSet.noneOf(SkillSection.class);
        Set<SkillSection> observees = EnumSet.noneOf(SkillSection.class);
        for (LearningPlanObservation observation : observations) {
            if (observation == null || observation.getSkill() == null) continue;
            SkillSection section = observation.getSkill().getSection();
            if (section == null) continue;
            tentees.add(section);
            if (observation.isObserved()) observees.add(section);
        }

        return domaines.stream()
                .filter(domaine -> domaine != null && domaine.epreuve() != null)
                .filter(domaine -> {
                    SkillSection section = section(domaine.epreuve());
                    return section != null
                            && tentees.contains(section)
                            && !observees.contains(section);
                })
                .sorted(Comparator.comparingInt(
                        item -> TcfDomainProfileDto.ORDRE.indexOf(item.epreuve())))
                .map(domaine -> pour(domaine.epreuve(), diagnosticTermine))
                .filter(Objects::nonNull)
                .findFirst();
    }

    /** Le domaine d'une epreuve du profil, dans le vocabulaire des competences. */
    private static SkillSection section(EpreuveType epreuve) {
        return switch (epreuve) {
            case TCF_CO -> SkillSection.CO;
            case TCF_CE -> SkillSection.CE;
            case TCF_EO -> SkillSection.EO;
            case TCF_EE -> SkillSection.EE;
            default -> null;
        };
    }

    /**
     * Par quoi mesurer <b>ce</b> domaine.
     *
     * <p>{@code null} pour une epreuve hors des quatre du profil TCF IRN
     * ({@code TCF_STRUCTURE}, {@code TCF_COMPLET}, {@code CIVIQUE}) : elles ne
     * font pas partie du profil, on n'invente pas une mesure pour elles.
     */
    private static PlanDomainAssessmentDto pour(EpreuveType epreuve, boolean diagnosticTermine) {
        if (epreuve == null) return null;
        return switch (epreuve) {
            case TCF_CO -> PlanDomainAssessmentDto.moduleMockExam(
                    epreuve, QuestionType.CO, SLOT_OFFERT, minutes(epreuve));
            case TCF_CE -> PlanDomainAssessmentDto.moduleMockExam(
                    epreuve, QuestionType.CE, SLOT_OFFERT, minutes(epreuve));
            case TCF_EE, TCF_EO -> diagnosticTermine
                    ? PlanDomainAssessmentDto.production(epreuve)
                    : PlanDomainAssessmentDto.diagnostic(epreuve);
            default -> null;
        };
    }

    /**
     * La duree de l'epreuve, lue chez {@link DureeEpreuve} — seule autorite du
     * depot sur les durees d'examen. Aucune constante de duree ici.
     */
    private static int minutes(EpreuveType epreuve) {
        Integer secondes = DureeEpreuve.secondes(epreuve);
        return secondes == null ? 0 : secondes / 60;
    }
}
