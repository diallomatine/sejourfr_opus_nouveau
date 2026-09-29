package com.sejourfr.app.dto;

/**
 * <b>Le FORMAT du diagnostic</b> : combien d'exercices il comporte, et de quoi
 * en annoncer l'effort. Servi <b>toujours</b>, y compris quand le candidat n'a
 * encore rien commence.
 *
 * <p>🛑 <b>Pourquoi il existe</b> (2026-09-14). L'accueil annoncait « 2
 * exercices · ≈ 8 a 10 min » en dur, alors que le diagnostic actif
 * ({@code QUICK_TCF}) n'en comporte qu'<b>UN</b> — une production ecrite, sans
 * etape orale (V050). Un candidat qui n'a jamais rien fait lisait donc une
 * promesse fausse des la premiere carte. Le contrat rendait l'erreur
 * inevitable : sur un parcours {@code NOT_STARTED}, {@code written} et
 * {@code oral} valent tous deux {@code null} — le serveur n'attache ses sujets
 * qu'a {@code POST /api/diagnostics} —, donc aucun front ne pouvait deriver le
 * compte et les deux l'ont ecrit a la main.
 *
 * <p>🛑 <b>Ce n'est PAS un sujet, et il ne faut pas le confondre avec un.</b>
 * Il ne porte ni identifiant, ni consigne, ni titre : uniquement les
 * <b>mesures</b> du format. Le sujet ecrit est <b>tire</b> a l'ouverture de la
 * session ({@code drawWrittenTask}) et un enonce annonce ici serait un enonce
 * different de celui qui sera joue.
 *
 * <p>Une fois la session ouverte, les mesures sont celles de <b>ses</b> sujets
 * a elle : un diagnostic se relit sous la forme qui l'a produit.
 *
 * @param exerciseCount              1 (production ecrite seule) ou 2 (avec
 *                                   l'etape orale). Jamais 0 : un diagnostic
 *                                   sans contenu n'est pas servi.
 * @param writtenWordsMin            bornes de la production ecrite,
 * @param writtenWordsMax            {@code null} si la base n'en porte pas
 * @param oralDurationMinSeconds     temps de parole de l'etape orale,
 * @param oralDurationMaxSeconds     {@code null} quand il n'y a pas d'oral
 */
public record DiagnosticFormatDto(
        int exerciseCount,
        Integer writtenWordsMin,
        Integer writtenWordsMax,
        Integer oralDurationMinSeconds,
        Integer oralDurationMaxSeconds
) {}
