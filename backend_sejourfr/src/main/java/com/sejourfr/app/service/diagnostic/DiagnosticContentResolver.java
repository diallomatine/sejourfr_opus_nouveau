package com.sejourfr.app.service.diagnostic;

import com.sejourfr.app.config.DiagnosticProperties;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.manager.ProductionTaskManager;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

/**
 * Source unique du <em>contenu</em> du diagnostic : le code actif, sa version
 * active, ses deux sujets et leurs textes d'accompagnement.
 *
 * <p>Trois appelants la partagent — la création d'une session
 * ({@link DiagnosticSessionCreator}), sa restitution ({@link DiagnosticService})
 * et la lecture publique ({@link PublicDiagnosticService}). Ils doivent servir
 * exactement les mêmes sujets : un visiteur rédige sans compte, puis s'inscrit
 * et sa session est créée. Si les deux chemins résolvaient la version
 * séparément, une bascule de version entre les deux appels ferait soumettre une
 * production écrite pour un sujet que le candidat n'a jamais lu.
 *
 * <p>Cette classe ne connaît ni utilisateur, ni session : elle ne lit que le
 * catalogue seed-only ({@code diagnostic_code IS NOT NULL}).
 */
@Component
@RequiredArgsConstructor
public class DiagnosticContentResolver {

    /** Accompagnement de l'étape écrite, identique sur la surface publique et authentifiée. */
    public static final String WRITTEN_HELPER =
            "Cet exercice nous aide à observer plusieurs compétences en une seule production.";

    /** Accompagnement de l'étape orale : le diagnostic est enregistré, pas dialogué. */
    public static final String ORAL_HELPER =
            "Enregistrez votre réponse : ce diagnostic n'utilise pas de conversation en temps réel.";

    private final DiagnosticProperties properties;
    private final ProductionTaskManager taskManager;

    /** Code du diagnostic servi aujourd'hui ({@code INITIAL_TCF} par défaut). */
    public String activeCode() {
        return properties.getInitialCode();
    }

    /** Dernière version active de ce code. Absente = seed non appliqué (500 assumé). */
    public int activeVersion(String code) {
        return taskManager.findLatestActiveDiagnosticVersion(code)
                .orElseThrow(() -> new IllegalStateException("Aucun diagnostic actif : " + code));
    }

    public ProductionTask writtenTask(String code, int version) {
        return task(code, version, EpreuveType.TCF_EE);
    }

    public ProductionTask oralTask(String code, int version) {
        return task(code, version, EpreuveType.TCF_EO);
    }

    /** Accompagnement à afficher pour l'épreuve d'un sujet diagnostic. */
    public static String helperText(EpreuveType epreuve) {
        return epreuve == EpreuveType.TCF_EE ? WRITTEN_HELPER : ORAL_HELPER;
    }

    private ProductionTask task(String code, int version, EpreuveType epreuve) {
        return taskManager.findActiveDiagnostic(code, version, epreuve)
                .orElseThrow(() -> new IllegalStateException(
                        "Sujet diagnostic " + epreuve + " actif introuvable"));
    }
}
