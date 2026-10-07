package com.sejourfr.app.dto;

/**
 * Compteurs des productions EE/EO corrigées par IA, sur le périmètre de la
 * console « Productions IA » (hors diagnostic). Une production soumise compte
 * une fois, quel que soit son statut : {@code evaluees + nonEvaluables +
 * enEchec + enCours = total}. Servi par l'encart de {@code /productions-ia}
 * (DI-35) et par la fiche utilisateur (D-57) — même requête, mêmes statuts IA
 * que la liste (F-6).
 *
 * @param avecExaminateur soumissions {@code source = REALTIME} (EO temps réel avec l'examinateur vocal)
 * @param signalees       signalement actif non vérifié (« Signalées (à vérifier) », DI-03)
 */
public record AdminProductionCompteursDto(
        long total,
        long ee,
        long eo,
        long avecExaminateur,
        long evaluees,
        long nonEvaluables,
        long enEchec,
        long enCours,
        long signalees
) {}
