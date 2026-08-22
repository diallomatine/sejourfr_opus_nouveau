package com.sejourfr.app.dto;

import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.PlanCycleState;
import com.sejourfr.app.enums.TargetLevel;

import java.util.List;

/**
 * Le <b>cycle de palier</b> en cours : d'ou part le candidat, quel palier le
 * Plan construit maintenant, quel est son objectif, et ou il en est sur le
 * chemin.
 *
 * <p><b>Entierement derive, jamais persiste</b> — aucune table, aucune
 * migration : il se relit du profil TCF et de l'historique d'observations a
 * chaque lecture du Plan, comme {@code SkillMasteryState} et
 * {@code SituationDansNiveau}.
 *
 * <p><b>{@link #targetLevel()} est le cran AU-DESSUS de {@link #startingLevel()},
 * jamais l'objectif directement</b> : un candidat A2 qui vise le B2 travaille
 * d'abord le B1 (brief §37). Il est plafonne par l'objectif — on ne fait jamais
 * viser plus haut que ce dont le candidat a besoin.
 *
 * <p>🛑 <b>{@link #objectiveLevel()} n'est pas « B2 » en dur.</b> C'est
 * {@code TargetProcedure.niveauVise(demarche, niveauDeclare)} — la demarche fait
 * <b>plancher</b> (CSP&rarr;A2, CR&rarr;B1, NAT&rarr;B2), et cette table n'a
 * qu'une seule autorite dans le depot. {@code null} quand le candidat n'a
 * declare ni demarche ni palier : on ne devine jamais une demarche a sa place.
 *
 * @param startingLevel   niveau global mesure d'ou part le cycle — plancher des
 *                        domaines evalues ({@code TcfProfileService}),
 *                        {@code null} tant que rien n'est mesure. Exprime en
 *                        {@link NiveauCecrl} parce qu'il peut valoir {@code A1}
 *                        ou moins, ce que {@link TargetLevel} ne sait pas dire.
 * @param targetLevel     palier construit par ce cycle, dans {@code A2..B2}
 * @param objectiveLevel  palier vise par le candidat, {@code null} si inconnu
 * @param state           ou en est le cycle
 * @param domainsEvaluated domaines reellement mesures (0..4)
 * @param domainsExpected  4, toujours
 * @param profileComplete  les quatre domaines sont mesures
 * @param path            le chemin, de la premiere etape a la derniere ; jamais
 *                        {@code null}, une seule etape y est {@code CURRENT}
 */
public record PlanCycleDto(
        NiveauCecrl startingLevel,
        TargetLevel targetLevel,
        TargetLevel objectiveLevel,
        PlanCycleState state,
        int domainsEvaluated,
        int domainsExpected,
        boolean profileComplete,
        List<PlanPathStepDto> path
) {}
