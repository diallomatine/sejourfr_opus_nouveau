package com.sejourfr.app.enums;

/**
 * Origine d'une {@code production_submissions}.
 * <p>
 * ASYNC : flux classique (upload audio EO ou texte EE -> R2 -> Whisper ->
 * notation). C'est le defaut historique.
 * <br>
 * REALTIME : session d'expression orale temps reel (examinateur IA, T1/T2). Pas
 * d'audio stocke (le flux audio est passe directement client <-> fournisseur) :
 * la production est portee par la {@code Transcription} (transcript du candidat),
 * la notation reutilise le meme pipeline en sautant Whisper.
 */
public enum ProductionSubmissionSource {
    ASYNC,
    REALTIME
}
