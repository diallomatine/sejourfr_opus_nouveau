package com.sejourfr.app.service.progres;

import com.sejourfr.app.dto.LignePartTheme;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.enums.CivicExamFormat;
import com.sejourfr.app.enums.CivicThemeState;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.AttemptQuestionManager;
import com.sejourfr.app.service.diagnosticcivique.CivicDiagnosticThemeResolver;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * <b>L'état d'un thème civique mesuré par EXAMEN BLANC</b> — seule autorité de
 * « ce thème a-t-il été mesuré par un examen, et avec quel état ? »
 * (demande du propriétaire, 2026-09-28).
 *
 * <h2>Ce qui mesure un thème, par ordre de précédence</h2>
 * <ol>
 *   <li>son <b>dernier examen de thème</b> terminé (20 questions) — exactement
 *       ce que l'écran de progression du thème appelle son état
 *       ({@code etatSource = DERNIER_EXAMEN_THEME}, D13) : l'Accueil et cet
 *       écran ne peuvent donc pas dire deux choses différentes ;</li>
 *   <li>sinon, sa <b>part dans le dernier examen civique global</b> terminé qui
 *       lui a posé au moins une question (« x / n posées », D11) : les questions
 *       d'un examen complet couvrent les thèmes, chacun y a donc une mesure ;</li>
 *   <li>sinon, <b>rien</b> : le thème est absent de la carte rendue, et
 *       l'appelant retombe sur ce qu'il savait déjà (le diagnostic civique).</li>
 * </ol>
 *
 * <p>🛑 <b>Un examen de thème passe devant une part d'examen global</b>, même
 * plus ancienne : 20 questions sur le thème mesurent mieux que les quelques
 * questions qu'un examen global lui consacre. 🛑 <b>Un examen blanc passe
 * devant le diagnostic</b>, comme côté TCF où le palier affiché vient des
 * examens et où le diagnostic n'est qu'un repli.
 *
 * <p>🛑 <b>Ce qui est lu est la définition existante du « qualifiant »</b> :
 * {@code AttemptManager.findCivicExamensThemePasses} /
 * {@code findCivicExamensGlobauxPasses} (examen blanc terminé, hors diagnostic,
 * au moins une réponse) et {@code AttemptQuestionManager.partsParTheme} — les
 * lectures des écrans de progression. Jamais les séries d'entraînement.
 *
 * <p>🛑 <b>L'état se demande à {@link CivicDiagnosticThemeResolver}</b>, la même
 * autorité que le diagnostic et les écrans de progression : aucun seuil n'est
 * recopié ici. Un score absent ({@code null}) n'est pas un état : l'examen est
 * ignoré, jamais compté comme raté.
 */
@Component
@RequiredArgsConstructor
public class EtatThemeCiviqueParExamens {

    private final AttemptManager attemptManager;
    private final AttemptQuestionManager attemptQuestionManager;
    private final CivicDiagnosticThemeResolver civicThemeResolver;

    /**
     * L'état d'<b>un</b> examen civique (de thème ou global) sur son score, ou
     * {@code null} s'il n'a pas de score. Le total est celui servi par
     * l'attempt, {@code totalParDefaut} n'est qu'un repli — la règle de l'écran
     * de progression, qui lit ce même état.
     */
    public CivicThemeState etatDExamen(Attempt examen, int totalParDefaut) {
        Integer bonnes = examen.getScore();
        if (bonnes == null) return null;
        int total = examen.getTotalQuestions() != null ? examen.getTotalQuestions() : totalParDefaut;
        return civicThemeResolver.etat(bonnes, total);
    }

    /**
     * Une mesure de thème par examen blanc : son état, et l'examen qui l'a
     * donnée (un examen de thème, ou l'examen global dont la part fait foi).
     */
    public record Mesure(CivicThemeState etat, UUID examenId) {}

    /**
     * Les thèmes mesurés par un examen blanc, avec leur état. Un thème absent
     * de la carte n'a été mesuré par <b>aucun</b> examen — inconnu, jamais
     * faible.
     */
    public Map<UUID, CivicThemeState> etats(UUID userId, List<UUID> themeIds) {
        Map<UUID, CivicThemeState> out = new LinkedHashMap<>();
        mesures(userId, themeIds).forEach((themeId, mesure) -> out.put(themeId, mesure.etat()));
        return out;
    }

    /**
     * Les mêmes mesures, avec l'examen qui a donné chacune — ce que le cycle
     * civique suivant journalise comme source de ses priorités (2026-10-05).
     *
     * <p>Coût constant : une requête pour les examens de thème, une pour les
     * examens globaux, et une pour leurs parts seulement si un thème en a
     * besoin.
     */
    public Map<UUID, Mesure> mesures(UUID userId, List<UUID> themeIds) {
        if (themeIds == null || themeIds.isEmpty()) return Map.of();
        Map<UUID, Mesure> out = new LinkedHashMap<>();

        // Du plus récent au plus ancien : le premier examen rencontré d'un
        // thème est son dernier.
        for (Attempt examen : attemptManager.findCivicExamensThemePasses(
                userId, themeIds,
                ProgressionExamensService.LIMITE_EXAMENS * themeIds.size())) {
            UUID themeId = examen.getLotThemeId();
            if (out.containsKey(themeId)) continue;
            CivicThemeState etat = etatDExamen(examen, CivicExamFormat.QUESTIONS_THEME);
            if (etat != null) out.put(themeId, new Mesure(etat, examen.getId()));
        }
        if (out.size() == themeIds.size()) return out;

        List<Attempt> globaux = attemptManager.findCivicExamensGlobauxPasses(
                userId, ProgressionExamensService.LIMITE_EXAMENS);
        if (globaux.isEmpty()) return out;
        Map<UUID, Map<UUID, LignePartTheme>> parts = new HashMap<>();
        for (LignePartTheme l : attemptQuestionManager.partsParTheme(
                globaux.stream().map(Attempt::getId).toList())) {
            parts.computeIfAbsent(l.attemptId(), k -> new HashMap<>()).put(l.themeId(), l);
        }
        for (UUID themeId : themeIds) {
            if (out.containsKey(themeId)) continue;
            for (Attempt global : globaux) {
                LignePartTheme part = parts.getOrDefault(global.getId(), Map.of()).get(themeId);
                // Un thème non posé par cet examen n'y a pas été mesuré : on
                // remonte au précédent, on ne lit jamais « 0 / 0 » comme raté.
                if (part == null || part.posees() <= 0) continue;
                out.put(themeId, new Mesure(
                        civicThemeResolver.etat(part.bonnes(), part.posees()), global.getId()));
                break;
            }
        }
        return out;
    }
}
