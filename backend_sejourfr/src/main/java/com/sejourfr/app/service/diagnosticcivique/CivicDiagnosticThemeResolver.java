package com.sejourfr.app.service.diagnosticcivique;

import com.sejourfr.app.config.CivicDiagnosticProperties;
import com.sejourfr.app.enums.CivicThemeState;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

/**
 * L'etat d'un theme civique a partir de son taux de reussite (20_ §4.4).
 *
 * <p><b>Composant pur</b> : ni base, ni horloge. On lui donne deux comptages et
 * il rend un etat, ce qui le rend testable exactement aux bornes des seuils.
 *
 * <p>🛑 <b>Zero question posee ⇒ {@code NON_EVALUE}, jamais {@code FAIBLE}.</b>
 * Un theme qu'on n'a pas mesure n'a pas ete rate. 20_ §4.2 pose d'ailleurs la
 * contrainte « ne jamais evaluer un theme sur une seule question » precisement
 * pour que ce cas reste rare — mais le mode degrade (catalogue sous-dote sur
 * une mention) le rend possible, et il ne doit alors produire aucun verdict.
 */
@Component
@RequiredArgsConstructor
public class CivicDiagnosticThemeResolver {

    private final CivicDiagnosticProperties props;

    /**
     * @param bonnes bonnes reponses sur ce theme
     * @param posees questions reellement posees sur ce theme
     */
    public CivicThemeState etat(int bonnes, int posees) {
        if (posees <= 0) {
            return CivicThemeState.NON_EVALUE;
        }
        double taux = (double) bonnes / posees;
        if (taux >= props.getSeuils().getSolide()) {
            return CivicThemeState.SOLIDE;
        }
        return taux < props.getSeuils().getFaible()
                ? CivicThemeState.FAIBLE
                : CivicThemeState.A_RENFORCER;
    }

    /**
     * Le taux d'un theme, ou {@code null} s'il n'a pas ete mesure.
     *
     * <p>🛑 {@code null}, pas {@code 0.0} : une barre a zero se lit « tout
     * faux », alors que la verite est « rien de pose ».
     */
    public static Double taux(int bonnes, int posees) {
        return posees <= 0 ? null : (double) bonnes / posees;
    }
}
