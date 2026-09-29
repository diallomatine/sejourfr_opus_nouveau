package com.sejourfr.app.dto;

import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.TcfReassessmentBlocker;

import java.time.Instant;
import java.util.UUID;

/**
 * <b>Peut-il relancer un diagnostic, et sinon pourquoi ?</b> — l'ecran T11
 * « Diagnostic deja realise » (30_ §5.6) et la boucle de reevaluation
 * (10_ §4.6), servis.
 *
 * <p>🛑 <b>Aucun front ne recalcule quoi que ce soit d'ici.</b> Ni les 14
 * jours, ni le nombre de jours restants, ni « c'est le premier ». Cette regle a
 * une seule autorite : {@code TcfReassessmentService}, qui sert ce DTO
 * <b>et</b> garde l'ouverture. Deux copies auraient fini par afficher un bouton
 * actif que le serveur refuse.
 *
 * @param canStart          le candidat peut ouvrir ou reprendre un diagnostic
 *                          maintenant
 * @param blocker           ce qui bloque ; {@code null} quand {@code canStart}
 * @param locked            porte <b>commerciale</b> : l'ecran ouvre le paywall.
 *                          Strictement {@code blocker == PREMIUM_REQUIRED} —
 *                          un delai non ecoule n'est pas un cadenas, payer ne
 *                          l'ouvre pas
 * @param message           la phrase exacte que l'ecran affiche, et celle que
 *                          le refus d'ouverture renvoie. {@code null} quand
 *                          rien ne bloque
 * @param first             aucun diagnostic ouvert a ce jour : c'est le
 *                          diagnostic <b>initial</b>, offert sans condition —
 *                          pas une reevaluation
 * @param inProgress        un diagnostic est ouvert et non clos : l'action est
 *                          « Reprendre », pas « Relancer »
 * @param intervalDays      le delai de la regle, en jours, pour que l'ecran
 *                          puisse le <b>dire</b> (« une tous les 14 jours »)
 *                          sans le connaitre
 * @param availableAt       date a laquelle le delai sera ecoule ; {@code null}
 *                          si le delai n'est pas le sujet
 * @param daysUntilAvailable jours restants, arrondis au superieur.
 *                          {@code null} si {@code availableAt} l'est
 * @param triggeredByPlan   une priorite du Plan a ete <b>terminee</b> depuis le
 *                          dernier diagnostic : 10_ §4.6 ouvre alors la
 *                          reevaluation <b>sans attendre</b> le delai. C'est le
 *                          declencheur produit de la boucle
 * @param lastSessionId     le dernier diagnostic, pour « Voir mon diagnostic ».
 *                          {@code null} si aucun
 * @param lastCompletedAt   sa date de cloture ; {@code null} s'il n'est pas
 *                          clos
 * @param lastNiveauGlobal  le palier qu'il a rendu. 🛑 {@code null} = <b>non
 *                          evalue</b>, jamais A1 : l'ecran doit le nommer, pas
 *                          inventer un plancher
 */
public record TcfReassessmentEligibilityDto(
        boolean canStart,
        TcfReassessmentBlocker blocker,
        boolean locked,
        String message,
        boolean first,
        boolean inProgress,
        int intervalDays,
        Instant availableAt,
        Integer daysUntilAvailable,
        boolean triggeredByPlan,
        UUID lastSessionId,
        Instant lastCompletedAt,
        NiveauCecrl lastNiveauGlobal
) {}
