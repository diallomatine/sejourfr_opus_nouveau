package com.sejourfr.app.audioquestion.service;

import java.util.Set;

/** Whitelist des voix Azure Speech autorisees pour la pipeline (fr-FR neural). */
public final class AzureVoices {

    public static final Set<String> ALLOWED = Set.of(
        // Femmes - jeunes
        "fr-FR-DeniseNeural",
        "fr-FR-EloiseNeural",
        "fr-FR-CelesteNeural",
        // Femmes - matures
        "fr-FR-BrigitteNeural",
        "fr-FR-YvetteNeural",
        "fr-FR-CoralieNeural",
        // Femmes - professionnelles
        "fr-FR-VivienneNeural",
        "fr-FR-JosephineNeural",
        // Hommes - jeunes
        "fr-FR-MauriceNeural",
        "fr-FR-JeromeNeural",
        "fr-FR-YvesNeural",
        // Hommes - matures
        "fr-FR-HenriNeural",
        "fr-FR-AlainNeural",
        "fr-FR-ClaudeNeural"
    );

    private AzureVoices() {}
}
