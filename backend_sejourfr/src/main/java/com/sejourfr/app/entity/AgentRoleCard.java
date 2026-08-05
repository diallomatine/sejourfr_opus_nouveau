package com.sejourfr.app.entity;

import com.sejourfr.app.enums.AgentInfoImportance;
import com.sejourfr.app.enums.AgentRelation;

import java.util.List;

/**
 * Fiche de scenario de l'examinateur-personnage de la Tache 2 (EO, interaction).
 * Stockee en JSONB sur {@link ProductionTask#getAgentRoleCard()} et injectee dans
 * la system instruction de l'agent vocal par
 * {@code service/realtime/RealtimePersonaBuilder}.
 *
 * <p><b>A quoi elle sert.</b> Sans elle, l'agent improvise tous les faits (prix,
 * delais, horaires) et peut se contredire en cours d'echange. La fiche lui donne
 * ses faits <b>a l'avance</b> : il devient coherent, et on dispose d'une verite de
 * reference sur ce que le candidat pouvait obtenir.
 *
 * <p><b>Ce qu'elle n'est PAS.</b> Ni une check-list de notation, ni un plan de
 * l'echange : les questions du sujet restent des <i>pistes</i>, ne pas les poser
 * toutes n'est jamais une faute. Une information non obtenue est informative, pas
 * penalisante. La fiche n'est jamais exposee au client (les {@code valeur} sont
 * les reponses que le candidat doit aller chercher).
 *
 * @param roleAgent               role tenu par l'examinateur, a la 1re personne
 *                                cote agent (« Conseiller du service apres-vente »)
 * @param relation                registre a tenir (vouvoiement / tutoiement)
 * @param objectifCandidat        ce que le candidat cherche a obtenir — sert a
 *                                l'agent pour rester plausible, jamais a l'orienter
 * @param phraseOuverture         replique d'entree en role, une fois le cadre pose
 * @param informationsEssentielles faits au coeur du scenario (4 a 6)
 * @param informationsSecondaires faits peripheriques (1 a 3)
 * @param contraintesAgent        contraintes de jeu PROPRES a ce scenario
 *                                (attitude, resistance, ce qu'il refuse). Les regles
 *                                universelles vivent dans le gabarit de persona.
 */
public record AgentRoleCard(
        String roleAgent,
        AgentRelation relation,
        String objectifCandidat,
        String phraseOuverture,
        List<Info> informationsEssentielles,
        List<Info> informationsSecondaires,
        List<String> contraintesAgent
) {

    /**
     * Un fait detenu par l'agent.
     *
     * @param id         cle stable machine (snake_case), pour un futur rapprochement
     *                   « quelles informations le candidat a-t-il obtenues »
     * @param valeur     phrase francaise complete et autoportante — c'est elle qui
     *                   part dans le prompt, telle quelle
     * @param importance poids editorial du fait, jamais un poids de notation
     */
    public record Info(String id, String valeur, AgentInfoImportance importance) {
    }

    /** Toutes les informations detenues, essentielles puis secondaires. */
    public List<Info> toutesInformations() {
        return java.util.stream.Stream
                .concat(safe(informationsEssentielles).stream(), safe(informationsSecondaires).stream())
                .toList();
    }

    private static <T> List<T> safe(List<T> list) {
        return list == null ? List.of() : list;
    }
}
