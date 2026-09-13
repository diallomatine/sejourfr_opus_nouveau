package com.sejourfr.app.service;

import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.enums.EpreuveType;

/**
 * « Cette tache se passe-t-elle en CONDITIONS REELLES ? » — le fait, derive
 * cote serveur, que les deux runners se contentent d'afficher.
 *
 * <p>🛑 <b>Une seule autorite.</b> La condition vivait implicitement dans les
 * fronts (le web forcait {@code examMode}, le mobile lisait {@code isExam}) :
 * deux implementations de la meme regle, vouees a diverger. Elle est ici, et
 * elle est servie sur {@code ProductionTaskDto.conditionsReelles}.
 *
 * <p><b>La regle, et rien de plus</b> (arbitrage du proprietaire,
 * 2026-09-13) : dans le <b>diagnostic</b> TCF, les taches 1 et 2 de
 * l'<b>expression orale</b> ne sont pas en conditions d'examen — le candidat
 * s'enregistre, se reecoute, refait s'il veut, et envoie quand il est pret. Le
 * reste ne bouge pas : EO3, toute l'EE, et surtout <b>l'examen blanc, qui reste
 * un examen</b>.
 *
 * <p>🛑 <b>Relacher les conditions ne relache AUCUN garde-fou serveur.</b> Une
 * tache reste soumise <b>une seule fois</b> par session
 * ({@code ProductionAccessService.assertTacheNotAlreadySubmitted}), la 3e
 * soumission clot la section, et le pipeline de notation est inchange. Ce qui
 * est relache est le <b>geste</b> du candidat, pas le budget d'appels payants.
 */
public final class ProductionExamConditions {

    private ProductionExamConditions() {
    }

    /**
     * {@code true} quand la tache doit se jouer comme a l'examen (chrono de
     * tache, pas de reecoute, envoi au premier arret).
     *
     * <p>Le defaut est <b>true</b> : un contexte inconnu se joue comme un
     * examen, jamais l'inverse — c'est le sens dans lequel une erreur ne coute
     * rien au candidat.
     */
    public static boolean conditionsReelles(Attempt attempt, ProductionTask task) {
        if (attempt == null || task == null) return true;
        if (!estDiagnostic(attempt)) return true;
        if (task.getEpreuve() != EpreuveType.TCF_EO) return true;
        Short tache = task.getTacheNumero();
        // EO1 et EO2 seulement. EO3 garde les conditions d'examen : c'est la
        // tache qui ressemble le plus a l'epreuve reelle, et rien ne demandait
        // de l'ouvrir.
        return tache == null || tache > 2;
    }

    /**
     * Un attempt de diagnostic, qu'on le regarde depuis la section ou depuis
     * son parent {@code TCF_COMPLET} — le meme discriminant
     * {@code attempts.tcf_diagnostic_id} que partout ailleurs.
     */
    private static boolean estDiagnostic(Attempt attempt) {
        if (attempt.getTcfDiagnostic() != null) return true;
        Attempt parent = attempt.getParentAttempt();
        return parent != null && parent.getTcfDiagnostic() != null;
    }
}
