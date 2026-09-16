package com.sejourfr.app.service;

import com.sejourfr.app.dto.PlanDomainAssessmentDto;
import com.sejourfr.app.dto.PlanDomainDto;
import com.sejourfr.app.dto.TcfDomainProfileDto;
import com.sejourfr.app.entity.LearningPlanObservation;
import com.sejourfr.app.enums.DureeEpreuve;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.util.TcfDomaine;
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
 * Les deux natures de {@code PlanDomainAssessmentKind} designent des parcours
 * <b>deja livres</b> : l'examen blanc de module CO/CE, l'examen blanc de
 * production EE/EO. Aucune banque de questions, aucun composant QCM, aucune
 * logique d'{@code Attempt} n'est duplique (brief §5, §84).
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
     */
    public List<PlanDomainAssessmentDto> resolve(List<PlanDomainDto> domaines) {
        if (domaines == null || domaines.isEmpty()) return List.of();
        List<PlanDomainAssessmentDto> restants = new ArrayList<>();
        for (PlanDomainDto domaine : domaines) {
            if (domaine == null || domaine.evaluated()) continue;
            PlanDomainAssessmentDto assessment = pour(domaine.epreuve());
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
     * l'infini sans jamais revenir mesurer son oral, alors que c'est exactement
     * ce qui lui manquait.
     *
     * <p>🛑 <b>C'est la distinction que le brief exige entre les trois sens de
     * {@code NOT_OBSERVED}</b> : « la production etait inutilisable » &rarr; il
     * faut <b>reevaluer</b> (c'est ici) ; « ce palier / cette tache n'a pas
     * encore ete aborde » &rarr; il faut <b>acquerir</b>
     * ({@link PlanAcquisitionSelector}) ; « l'echantillon est trop mince pour
     * conclure » &rarr; il n'y a <b>rien a proposer</b>. Le premier sens se lit
     * au grain du <b>domaine</b> — une production ratee emporte toutes les
     * competences de son epreuve —, le second au grain de la competence, le
     * troisieme au grain du palier.
     *
     * <p>🛑 <b>EXPRESSION SEULEMENT</b> (2026-09-16). Le filtre
     * {@code section.isProduction()} n'est pas une optimisation : en
     * comprehension, {@code NOT_OBSERVED} n'a <b>jamais</b> le sens « la mesure
     * a rate ». {@code ComprehensionObservationService} l'ecrit quand un palier
     * porte moins de {@code comprehension.min-questions} reponses — c'est le
     * <b>troisieme</b> sens, « pas assez de preuve », et une epreuve CO/CE
     * terminee n'a rien a repasser pour autant. Sans ce filtre, un candidat qui
     * venait de finir ses 25 items de CE se voyait proposer de refaire la CE
     * entiere parce qu'un de ses trois paliers manquait de deux reponses.
     *
     * <p>A ne pas confondre avec {@link #resolve} : celui-la liste les domaines
     * <b>jamais mesures</b> et alimente « Completer mon profil », un bloc a part.
     * Ici on repond a « qu'est-ce que la seance doit faire en premier ? », et un
     * domaine sans la moindre observation n'y entre pas — le candidat n'a encore
     * rien tente dessus, donc rien n'a echoue.
     *
     * <p><b>Une seule</b>, la premiere dans l'ordre des epreuves du TCF : une
     * seance ne se remplit pas de mesures. <b>Zero requete</b> — tout se lit sur
     * l'historique deja charge par le Plan et sur les domaines deja resolus. La
     * resolution « par quoi mesurer ce domaine » n'est pas dupliquee : c'est le
     * meme {@link #pour} que « Completer mon profil ».
     *
     * @param domaines          les quatre domaines, tels que
     *                          {@link PlanCycleResolver} les a resolus.
     * @param observations      tout l'historique du candidat, deja charge.
     */
    public Optional<PlanDomainAssessmentDto> indispensable(
            List<PlanDomainDto> domaines,
            List<LearningPlanObservation> observations) {
        if (domaines == null || domaines.isEmpty()) return Optional.empty();
        if (observations == null || observations.isEmpty()) return Optional.empty();

        Set<SkillSection> tentees = EnumSet.noneOf(SkillSection.class);
        Set<SkillSection> observees = EnumSet.noneOf(SkillSection.class);
        for (LearningPlanObservation observation : observations) {
            if (observation == null || observation.getSkill() == null) continue;
            SkillSection section = observation.getSkill().getSection();
            // La comprehension n'entre meme pas dans le comptage : son
            // NOT_OBSERVED dit « echantillon trop mince », jamais « la mesure
            // a rate ». Une epreuve CO/CE terminee ne se repasse pas pour ca.
            if (section == null || !section.isProduction()) continue;
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
                .map(domaine -> pour(domaine.epreuve()))
                .filter(Objects::nonNull)
                .findFirst();
    }

    /**
     * Le domaine d'une epreuve du profil, dans le vocabulaire des competences.
     * 🛑 <b>Lu chez son autorite</b> depuis le 2026-09-17 ({@link TcfDomaine}) :
     * cette table vivait en QUATRE copies privees dans les services du Plan.
     */
    private static SkillSection section(EpreuveType epreuve) {
        return TcfDomaine.section(epreuve);
    }

    /**
     * Par quoi mesurer <b>ce</b> domaine.
     *
     * <p>{@code null} pour une epreuve hors des quatre du profil TCF IRN
     * ({@code TCF_STRUCTURE}, {@code TCF_COMPLET}, {@code CIVIQUE}) : elles ne
     * font pas partie du profil, on n'invente pas une mesure pour elles.
     *
     * <p><b>Publique depuis le 2026-09-16</b>, pour la carte d'epreuve de
     * l'ACCUEIL (« Ou vous en etes ») : une epreuve jamais mesuree y propose
     * « Evaluer mon niveau », et ce bouton doit lancer <b>la meme</b> mesure que
     * « Completer mon profil », que la fiche d'un domaine, que l'ecran Progres,
     * que Reviser et que la ligne {@code A_EVALUER} de la seance. Cinq
     * appelants, pas cinq regles : la table des natures reste ici, et elle est
     * la seule.
     *
     * <p>🛑 <b>Les quatre epreuves se mesurent par un EXAMEN BLANC</b>
     * (arbitrage du proprietaire, 2026-09-16) : examen de module en CO/CE,
     * examen de production (les 3 taches) en EE/EO, toujours au
     * {@link #SLOT_OFFERT}. Cette methode prenait un {@code diagnosticTermine}
     * qui n'aiguillait que l'expression — vers l'ancien diagnostic 1 EE + 1 EO
     * s'il restait a faire, vers l'entrainement libre sinon. <b>Aucun des deux
     * ne lancait un examen blanc</b>, et « mesurer ce domaine » ne voulait donc
     * pas dire la meme chose selon l'epreuve. Le parametre a ete retire de
     * cette signature et de ses appelants : plus personne ne le lisait.
     */
    public PlanDomainAssessmentDto pour(EpreuveType epreuve) {
        if (epreuve == null) return null;
        return switch (epreuve) {
            case TCF_CO -> PlanDomainAssessmentDto.moduleMockExam(
                    epreuve, QuestionType.CO, SLOT_OFFERT, minutes(epreuve));
            case TCF_CE -> PlanDomainAssessmentDto.moduleMockExam(
                    epreuve, QuestionType.CE, SLOT_OFFERT, minutes(epreuve));
            case TCF_EE, TCF_EO -> PlanDomainAssessmentDto.productionMockExam(
                    epreuve, SLOT_OFFERT, minutesOuNull(epreuve));
            default -> null;
        };
    }

    /**
     * La duree de l'epreuve, lue chez {@link DureeEpreuve} — seule autorite du
     * depot sur les durees d'examen. Aucune constante de duree ici.
     */
    private static int minutes(EpreuveType epreuve) {
        Integer secondes = minutesOuNull(epreuve);
        return secondes == null ? 0 : secondes;
    }

    /**
     * La duree de l'epreuve <b>quand elle en a une</b>. {@code null} a
     * l'expression orale, qui se chronometre tache par tache et n'a pas de
     * duree d'epreuve opposable ({@link DureeEpreuve} le dit) : on n'annonce
     * alors aucune minute plutot qu'un « 0 min » qui serait faux.
     */
    private static Integer minutesOuNull(EpreuveType epreuve) {
        Integer secondes = DureeEpreuve.secondes(epreuve);
        return secondes == null ? null : secondes / 60;
    }
}
