package com.sejourfr.app.enums;

/**
 * Ce que le parcours <b>suggere</b> quand il n'a plus d'etape ouverte (§8).
 *
 * <p>🛑 <b>Une suggestion n'est pas une etape</b>, et l'enum existe pour que
 * cette difference soit lisible dans le contrat. Elle vit <b>hors de la file</b> :
 * elle n'a pas de position, elle ne se clot pas, elle ne cree pas de lot, et le
 * candidat peut l'ignorer sans que rien ne reste « en attente ». La mettre dans
 * la file aurait fait d'un parcours a jour un parcours perpetuellement inachieve.
 */
public enum JourneySuggestionType {

    /**
     * Passer un <b>examen blanc TCF complet</b> pour confirmer le niveau global.
     *
     * <p>Suggere seulement quand les <b>4 epreuves sont mesurees</b> : on ne
     * confirme pas un palier sur deux domaines sur quatre — c'est la meme regle
     * que le jalon de palier du Plan ({@code PlanCycleDto.profileComplete}), et
     * R12 garantit qu'une epreuve non mesuree a deja son etape dans la file.
     */
    MOCK_EXAM
}
