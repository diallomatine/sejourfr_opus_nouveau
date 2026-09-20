package com.sejourfr.app.service.journey;

import com.sejourfr.app.dto.TcfLevelProfile;
import com.sejourfr.app.entity.LearningPlanObservation;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.ObservationConfidence;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.dto.TcfDomainProfileDto;
import com.sejourfr.app.service.journey.JourneyObservationSources.Sources;
import com.sejourfr.app.util.TcfDomaine;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

/**
 * <b>Les lots qu'une evaluation produit</b> : quelles priorites elle retient par
 * epreuve (R2), et dans quel ordre les lots entrent dans la file (R10 bis).
 *
 * <h2>🛑 Aucune regle de gravite n'est ecrite ici</h2>
 * <p>L'ordre des priorites est celui de
 * {@code LearningPlanPriorityResolver.actionable()} — statut, puis <b>confiance
 * decroissante</b>, puis recence — et il est <b>reproduit</b>, pas reinvente :
 * ce comparateur est le meme, departage par {@code skillCode} pour rester
 * deterministe a egalite parfaite (les deux productions d'un diagnostic sont
 * observees au meme instant, donc la recence n'y trie rien).
 *
 * <p>Pourquoi le reproduire plutot que l'appeler : le resolveur travaille sur
 * <b>la derniere observation de chaque competence</b>, tous historiques
 * confondus, et rend le pool <b>courant</b> du candidat. Le lot, lui, est la
 * photographie de ce qu'<b>UNE evaluation donnee</b> a designe — un fait date,
 * pas un etat. Les deux questions sont differentes ; le critere de tri est le
 * meme, et c'est tout ce qui doit l'etre.
 *
 * <h2>Le plafond est un budget de FILE, et c'est assume</h2>
 * <p>{@code maxPrioritiesPerLot} borne ce que la file <b>met en attente</b> : les
 * priorites au-dela ne sont ni stockees, ni differees (R2). Ce n'est pas
 * l'incident du 2026-08-25 — la ou un plafond de 5 actions <b>partage entre 4
 * domaines</b> avait prive trois domaines sur quatre de toute action : ici le
 * plafond est <b>par epreuve</b>, donc jusqu'a 12 priorites vivantes, et le
 * moteur continue de calculer tout. Si une priorite ecartee persiste, le
 * prochain examen de son epreuve la fera remonter.
 */
@Component
@RequiredArgsConstructor
public class JourneyLotBuilder {

    private final TcfJourneyConfig config;

    /** Une priorite retenue, et son rang <b>dans son lot</b>. */
    public record Priorite(Skill skill, int rang) {}

    /**
     * Un lot pret a etre ecrit : son epreuve, l'evaluation qui l'a designe, et
     * ses priorites dans l'ordre.
     */
    public record Lot(EpreuveType epreuve, UUID sourceAssessmentId, List<Priorite> priorites) {}

    /**
     * Les lots que produit <b>une</b> evaluation.
     *
     * @param sources          l'evaluation <b>et les {@code source_id} de ses
     *                         observations</b>, resolus par
     *                         {@link JourneyObservationSources}. 🛑 Les deux ne
     *                         se confondent pas : l'identite reste
     *                         l'{@code attempt.id} de l'EPREUVE (ou la session
     *                         du diagnostic rapide), jamais une soumission —
     *                         les 3 taches d'une epreuve produisent 3
     *                         soumissions, et traiter chacune comme une
     *                         evaluation ferait que la tache 2
     *                         <b>remplacerait</b> (R7) le lot que la tache 1
     *                         vient de creer (A11). Les <b>observations</b>, en
     *                         revanche, sont clavetees sur ces soumissions :
     *                         c'est pourquoi on les retient par
     *                         {@link Sources#contient} et jamais par egalite
     *                         avec l'identite.
     * @param evaluations      les observations <b>deja filtrees par R1</b>
     *                         ({@link JourneyEvaluationFilter}).
     * @param maitriseesCeJour les competences dont le transfert est prouve
     *                         <b>aujourd'hui</b>, lues chez
     *                         {@code SkillMasteryEngine}. Elles ne rentrent
     *                         jamais dans un lot : ce serait redemander ce qui
     *                         est acquis.
     */
    public List<Lot> depuisEvaluation(
            Sources sources,
            List<LearningPlanObservation> evaluations,
            Set<UUID> maitriseesCeJour,
            TargetLevel objectif,
            TcfLevelProfile profil) {
        List<LearningPlanObservation> sonLot = evaluations.stream()
                .filter(observation -> sources.contient(observation.getSourceId()))
                .toList();
        return ordonner(parEpreuve(sonLot, maitriseesCeJour, source -> sources.evaluation()),
                objectif, profil);
    }

    /**
     * Les lots que produit un <b>historique</b> : une evaluation de reference par
     * epreuve (R19, points 2 et 3).
     *
     * <p>🛑 <b>Le filtrage est fait EPREUVE PAR EPREUVE</b>, et il le faut :
     * l'evaluation de reference du CO et celle de l'EE peuvent etre la meme —
     * un diagnostic rapide produit des observations EE <b>et</b> EO. Un filtre
     * global verserait alors les observations EO de ce diagnostic dans le lot
     * EO, meme quand l'EO a pour reference un examen plus recent.
     *
     * @param referencesParEpreuve l'evaluation retenue pour chaque epreuve,
     *                             telle que le bootstrap l'a choisie — la plus
     *                             recente qui <b>mesure</b>, a defaut le plus
     *                             recent diagnostic rapide ayant produit des
     *                             priorites —, avec les {@code source_id} de ses
     *                             observations.
     */
    public List<Lot> depuisHistorique(
            Map<EpreuveType, Sources> referencesParEpreuve,
            List<LearningPlanObservation> evaluations,
            Set<UUID> maitriseesCeJour,
            TargetLevel objectif,
            TcfLevelProfile profil) {
        if (referencesParEpreuve.isEmpty()) return List.of();
        List<Lot> lots = new ArrayList<>();
        referencesParEpreuve.forEach((epreuve, reference) -> {
            List<LearningPlanObservation> sonLot = evaluations.stream()
                    .filter(observation -> reference.contient(observation.getSourceId()))
                    .filter(observation -> observation.getSkill() != null
                            && TcfDomaine.epreuve(observation.getSkill().getSection()) == epreuve)
                    .toList();
            List<Priorite> priorites =
                    lotsParEpreuve(sonLot, maitriseesCeJour).get(epreuve);
            if (priorites != null) lots.add(new Lot(epreuve, reference.evaluation(), priorites));
        });
        return ordonner(lots, objectif, profil);
    }

    // ------------------------------------------------------------------ R2

    /**
     * Regroupe par epreuve, trie par gravite, et coupe a
     * {@code maxPrioritiesPerLot}.
     *
     * <p>🛑 <b>Seules les fragilites entrent</b> : {@code PRIORITY} et
     * {@code TO_REINFORCE}. {@code SOLID} n'est pas une priorite, et
     * {@code NOT_OBSERVED} <b>non plus</b> — « le correcteur n'a rien pu
     * observer » veut dire <b>inconnu</b>, jamais « faible ». C'est exactement
     * la confusion qui a produit les faux {@code A1_NON_ATTEINT} de
     * V040/V041/V042. Zero fragilite observee donne zero priorite, et c'est un
     * resultat legitime (R9).
     */
    private Map<EpreuveType, List<Priorite>> lotsParEpreuve(
            List<LearningPlanObservation> observations, Set<UUID> maitriseesCeJour) {
        Map<EpreuveType, List<LearningPlanObservation>> parEpreuve = new LinkedHashMap<>();
        for (LearningPlanObservation observation : observations) {
            Skill skill = observation.getSkill();
            if (skill == null) continue;
            if (maitriseesCeJour.contains(skill.getId())) continue;
            if (observation.getStatus() != LearningPlanSkillStatus.PRIORITY
                    && observation.getStatus() != LearningPlanSkillStatus.TO_REINFORCE) {
                continue;
            }
            EpreuveType epreuve = TcfDomaine.epreuve(skill.getSection());
            if (epreuve == null) continue;
            parEpreuve.computeIfAbsent(epreuve, key -> new ArrayList<>()).add(observation);
        }
        Map<EpreuveType, List<Priorite>> retenus = new LinkedHashMap<>();
        parEpreuve.forEach((epreuve, fragilites) -> {
            List<Priorite> priorites = new ArrayList<>();
            fragilites.stream()
                    .sorted(PAR_GRAVITE)
                    .map(LearningPlanObservation::getSkill)
                    // R13 — pas deux fois la meme competence dans un lot. Une
                    // evaluation peut l'observer sur deux taches ; c'est une
                    // fragilite, pas deux.
                    .distinct()
                    .limit(config.maxPrioritiesPerLot())
                    .forEach(skill -> priorites.add(new Priorite(skill, priorites.size())));
            if (!priorites.isEmpty()) retenus.put(epreuve, List.copyOf(priorites));
        });
        return retenus;
    }

    private List<Lot> parEpreuve(
            List<LearningPlanObservation> observations,
            Set<UUID> maitriseesCeJour,
            java.util.function.Function<EpreuveType, UUID> source) {
        List<Lot> lots = new ArrayList<>();
        lotsParEpreuve(observations, maitriseesCeJour).forEach((epreuve, priorites) ->
                lots.add(new Lot(epreuve, source.apply(epreuve), priorites)));
        return lots;
    }

    /**
     * L'ordre de gravite, <b>le meme</b> que
     * {@code LearningPlanPriorityResolver.actionable()} : {@code PRIORITY} avant
     * {@code TO_REINFORCE}, puis confiance <b>decroissante</b>, puis observation
     * la plus recente — et enfin le code, pour qu'une egalite parfaite reste
     * deterministe.
     */
    private static final Comparator<LearningPlanObservation> PAR_GRAVITE = Comparator
            .comparingInt((LearningPlanObservation item) ->
                    item.getStatus() == LearningPlanSkillStatus.PRIORITY ? 0 : 1)
            .thenComparingInt(item -> -confiance(item.getConfidence()))
            .thenComparing(LearningPlanObservation::getObservedAt, Comparator.reverseOrder())
            .thenComparing(item -> item.getSkill().getCode());

    /** {@code HIGH} 3, {@code MEDIUM} 2, tout le reste 1 — miroir du resolveur du Plan. */
    private static int confiance(ObservationConfidence confidence) {
        if (confidence == null) return 1;
        return switch (confidence) {
            case HIGH -> 3;
            case MEDIUM -> 2;
            case LOW -> 1;
        };
    }

    // -------------------------------------------------------------- R10 bis

    /**
     * <b>R10 bis</b> — ecart au niveau cible <b>decroissant</b>, puis l'ordre des
     * epreuves du TCF.
     *
     * <p>🛑 Le niveau de l'epreuve est celui de la <b>lecture Plan</b>
     * ({@code TcfProfileService.levelProfile} — arbitrage D-2), jamais la moyenne
     * d'affichage : celle-ci <b>peut redescendre</b> (arbitrage du 2026-09-16,
     * « un niveau affiche est une estimation d'aujourd'hui, pas un trophee »), et
     * la brancher ici ferait <b>reordonner la file</b> parce qu'un examen recent
     * a ete moins bon, sans qu'aucune priorite n'ait bouge.
     *
     * <p>🛑 Un ecart <b>inconnu</b> passe <b>apres</b> les ecarts connus, jamais
     * devant : une mesure absente ne devient pas l'urgence maximale par defaut
     * — ce serait la confusion « null = mauvais » que le depot a deja payee.
     */
    public List<Lot> ordonner(List<Lot> lots, TargetLevel objectif, TcfLevelProfile profil) {
        List<Lot> ordonnes = new ArrayList<>(lots);
        ordonnes.sort(Comparator
                .comparingInt((Lot lot) -> {
                    Integer ecart = ecart(lot.epreuve(), objectif, profil);
                    // Ecart inconnu : place en fin, a -1, sous tout ecart reel
                    // (qui vaut 0 au minimum).
                    return ecart == null ? -1 : ecart;
                })
                .reversed()
                .thenComparingInt(lot -> ordreEpreuve(lot.epreuve())));
        return List.copyOf(ordonnes);
    }

    private static Integer ecart(EpreuveType epreuve, TargetLevel objectif, TcfLevelProfile profil) {
        if (profil == null) return null;
        NiveauCecrl mesure = switch (epreuve) {
            case TCF_CO -> profil.co();
            case TCF_CE -> profil.ce();
            case TCF_EE -> profil.ee();
            case TCF_EO -> profil.eo();
            default -> null;
        };
        return TcfDomaine.ecartAuNiveauCible(mesure, objectif);
    }

    /**
     * L'ordre des epreuves du TCF — <b>lu</b> chez {@code TcfDomainProfileDto.ORDRE}
     * ({@code CO, CE, EO, EE}, arbitrage D-9), jamais configure ni recopie : un
     * second ordre ferait diverger la file et « Completer mon profil ».
     */
    public static int ordreEpreuve(EpreuveType epreuve) {
        int rang = TcfDomainProfileDto.ORDRE.indexOf(epreuve);
        return rang < 0 ? TcfDomainProfileDto.ORDRE.size() : rang;
    }
}
