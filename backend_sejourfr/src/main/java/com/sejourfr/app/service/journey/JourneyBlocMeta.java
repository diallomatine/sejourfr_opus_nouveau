package com.sejourfr.app.service.journey;

import com.sejourfr.app.dto.JourneyBlocRefDto;
import com.sejourfr.app.enums.JourneyBlocKind;
import com.sejourfr.app.enums.JourneyBlocStatus;

/**
 * <b>La phrase d'etat d'un bloc</b> — « 3 unites restantes · puis examen ».
 *
 * <h2>🛑 Pourquoi elle est SERVIE (D-50 §4, chantier {@code DETTE-P1})</h2>
 * <p>Elle vivait <b>a la main dans les deux fronts</b> ({@code journeyBlocMeta}
 * / {@code journeyBlocMeta}), et le mot qu'elle emploie depend du <b>grain du
 * module</b> : « competence » cote TCF, « unite » cote civique. Un front qui
 * choisit ce mot le choisit <b>seul</b> — et son jumeau peut en choisir un
 * autre. C'est exactement le motif de {@code DETTE-P1}, dont la 3e occurrence a
 * ouvert le chantier.
 *
 * <p>⚠️ <b>Exception assumee et bornee</b> a « le serveur sert des faits, les
 * phrases appartiennent aux fronts ». Le motif : ce n'est pas une formulation
 * d'ecran, c'est le <b>nom du grain</b>, et le grain appartient au referentiel
 * (D-48). Les deux fronts n'ont plus qu'a l'afficher.
 *
 * <p>🛑 <b>Les phrases TCF sont INCHANGEES</b>, mot pour mot : ce composant
 * reprend celles des deux fronts. Rien ne bouge a l'ecran cote TCF.
 */
final class JourneyBlocMeta {

    private JourneyBlocMeta() {}

    static String pour(
            JourneyBlocRefDto bloc, JourneyBlocStatus status,
            int restantes, boolean porteDesEtapes, boolean examenOuvert) {

        boolean thematique = bloc.kind() == JourneyBlocKind.THEMATIQUE;
        // « examen blanc » cote TCF ; cote civique l'examen d'un bloc est
        // l'examen du THEME, et l'appeler « blanc » le confondrait avec
        // l'examen complet de 40 questions.
        String examen = thematique ? "examen" : "examen blanc";

        if (status == JourneyBlocStatus.TERMINE) {
            return porteDesEtapes
                    ? (thematique ? "Unités travaillées · " : "Compétences travaillées · ")
                            + examen + " terminé"
                    : "Niveau évalué · " + examen + " terminé";
        }
        if (status == JourneyBlocStatus.A_EVALUER) return "Niveau à évaluer";

        if (restantes > 0) {
            String mot = restantes + " " + nom(thematique, restantes);
            return status == JourneyBlocStatus.EN_COURS
                    ? mot + " restante" + (restantes == 1 ? "" : "s") + " · puis examen"
                    : mot + " · puis examen";
        }
        if (examenOuvert) return "Examen à passer";
        return "Rien à travailler pour l'instant";
    }

    private static String nom(boolean thematique, int combien) {
        String racine = thematique ? "unité" : "compétence";
        return combien == 1 ? racine : racine + "s";
    }
}
