package com.sejourfr.app.service.questionimport;

/** Un fichier joint au lot, deja lu en memoire (nom d'origine + octets). */
public record FichierImport(String nom, byte[] octets) {}
