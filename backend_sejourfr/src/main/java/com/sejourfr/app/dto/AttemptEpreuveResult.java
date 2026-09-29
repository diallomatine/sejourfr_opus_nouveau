package com.sejourfr.app.dto;

import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.QuestionType;

/**
 * Résultat par épreuve d'un examen TCF stratifié (CO_IMAGE regroupée sous CO).
 * Au TCF IRN, le niveau global retenu est le <b>plancher</b> des épreuves :
 * ce détail permet d'afficher le niveau de chacune et d'expliquer le min à
 * l'utilisateur (un C2 partout sauf un A1 → A1).
 */
public record AttemptEpreuveResult(
        QuestionType epreuve,
        int correct,
        int total,
        int calibratedScore,
        NiveauCecrl cecrlLevel
) {}
