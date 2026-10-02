package com.sejourfr.app.dto;

/**
 * Les sessions EO temps réel d'un compte, vues de la carte Intégral de la fiche
 * admin (V084, B-1). Calculées par l'unique autorité du quota
 * ({@code RealtimeQuotaService.vueAdmin}) : le front affiche, il n'additionne rien.
 *
 * @param remaining             total consommable maintenant (= ce que voit le candidat)
 * @param grantGranted          sessions offertes par l'accès manuel applicable ({@code null} sans lui)
 * @param grantRemaining        solde de cet accès manuel ({@code null} sans lui)
 * @param purchaseRemaining     solde de l'achat qui porte l'accès ({@code null} sans achat)
 * @param scheduledGrantGranted sessions offertes par l'accès manuel programmé ({@code null} sans lui)
 * @param label                 phrase servie, ex. « 14 sessions restantes — accès manuel : 14 restantes sur 20 accordées ; achat : 0 »
 * @param info                  « Cet accès manuel n'ajoute pas actuellement de sessions EO temps réel. »
 *                              quand l'accès manuel affiché n'en offre aucune, {@code null} sinon
 */
public record AdminRealtimeEoSessionsDto(
        int remaining,
        Integer grantGranted,
        Integer grantRemaining,
        Integer purchaseRemaining,
        Integer scheduledGrantGranted,
        String label,
        String info
) {}
