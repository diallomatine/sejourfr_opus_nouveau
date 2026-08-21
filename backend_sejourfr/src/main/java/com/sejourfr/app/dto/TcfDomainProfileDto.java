package com.sejourfr.app.dto;

import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;

import java.util.List;

/**
 * Profil TCF d'un candidat <b>domaine par domaine</b>, servi sur
 * {@code GET /api/me/dashboard} : ce que l'écran « Mon profil TCF » affiche, et
 * ce dont « Compléter mon profil » déduit les domaines manquants.
 *
 * <p>C'est la <b>publication</b> de {@link TcfLevelProfile}, agrégat interne
 * calculé par {@code TcfProfileService} — pas un second calcul. Les trois
 * scalaires historiques de {@code DashboardSummaryResponse}
 * ({@code estimatedTcfLevel} + son périmètre) restent servis à côté, inchangés :
 * ils disent la même chose en plus court.
 *
 * <p>🛑 <b>L'ordre des domaines est FIGÉ CÔTÉ SERVEUR</b> — CO, CE, EO, EE,
 * l'ordre des épreuves du TCF — et la liste en porte <b>toujours 4</b>, un
 * domaine jamais passé étant présent avec {@code evaluated=false}. Aucun front
 * ne réordonne, aucun front ne complète les trous : deux copies de cet ordre
 * finiraient par diverger, et une liste trouée ferait disparaître de l'écran
 * exactement ce que « Compléter mon profil » doit montrer.
 *
 * @param domaines    les 4 domaines, ordre figé CO · CE · EO · EE
 * @param globalLevel plancher des domaines évalués, {@code null} si aucun
 * @param evaluated   nombre de domaines évalués (0..4)
 * @param expected    {@value TcfLevelProfile#EPREUVES_EXPECTED}, toujours
 * @param partial     niveau global établi sur une partie seulement des domaines
 */
public record TcfDomainProfileDto(
        List<TcfDomainDto> domaines,
        NiveauCecrl globalLevel,
        int evaluated,
        int expected,
        boolean partial
) {

    /**
     * Ordre d'affichage des domaines — <b>déclaré ici et nulle part ailleurs</b>.
     * C'est l'ordre du TCF : compréhension orale, compréhension écrite,
     * expression orale, expression écrite.
     */
    public static final List<EpreuveType> ORDRE = List.of(
            EpreuveType.TCF_CO, EpreuveType.TCF_CE, EpreuveType.TCF_EO, EpreuveType.TCF_EE);

    /** Publication d'un {@link TcfLevelProfile} : aucune règle n'est recalculée ici. */
    public static TcfDomainProfileDto of(TcfLevelProfile profile) {
        return new TcfDomainProfileDto(
                List.of(
                        TcfDomainDto.of(EpreuveType.TCF_CO, profile.co()),
                        TcfDomainDto.of(EpreuveType.TCF_CE, profile.ce()),
                        TcfDomainDto.of(EpreuveType.TCF_EO, profile.eo()),
                        TcfDomainDto.of(EpreuveType.TCF_EE, profile.ee())),
                profile.globalLevel(),
                profile.epreuvesCounted(),
                TcfLevelProfile.EPREUVES_EXPECTED,
                profile.partial());
    }
}
