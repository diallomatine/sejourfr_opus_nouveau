package com.sejourfr.app.enums;

import java.util.List;
import java.util.Locale;

/**
 * Les 6 taches du TCF IRN sur lesquelles s'accrochent les competences.
 *
 * <p><b>Pourquoi un enum et pas une table.</b> Le NOMBRE et l'ORDRE des taches
 * (3 a l'ecrit, 3 a l'oral) sont fixes par le TCF IRN : ni l'admin ni un seed ne
 * doivent pouvoir en ajouter ni en supprimer une. Une table les aurait rendues
 * editables, avec le risque qu'un libelle derive d'un front a l'autre. Le
 * contenu editorial (competences, sujets, references) vit en base ; le squelette
 * de l'examen vit ici.
 *
 * <p>🛑 <b>Le {@code targetLevel} n'est PAS officiel.</b> France Education
 * international ne rattache aucun palier CECRL a une tache : c'est notre palier
 * PEDAGOGIQUE interne, le niveau que le candidat cherche a atteindre sur cette
 * tache. Il vient d'une fourchette de notre spec (EE1 « A1-A2 », EE2 « A2-B1 »,
 * EE3 « B1-B2 ») dont on retient la borne haute. 🛑 <b>Aucun ecran ne doit le
 * presenter comme une regle du TCF</b> — les libelles disent « niveau vise ».
 * Il ne se confond pas avec {@code skills.target_level}, qui affine competence
 * par competence a l'interieur d'une meme tache.
 *
 * <p>Le {@code title} est notre intitule editorial, pas le libelle officiel de
 * l'epreuve.
 */
public enum SkillTaskCode {
    EE1(SkillSection.EE, 1, "Écrire un message court", "A2"),
    EE2(SkillSection.EE, 2, "Raconter une expérience", "B1"),
    EE3(SkillSection.EE, 3, "Donner son opinion", "B2"),
    EO1(SkillSection.EO, 1, "Entretien dirigé : parler de soi", "A2"),
    EO2(SkillSection.EO, 2, "Jeu de rôle : demander et obtenir des informations", "B1"),
    EO3(SkillSection.EO, 3, "Exprimer et développer un point de vue", "B2");

    private final SkillSection section;
    private final int tacheNumero;
    private final String title;
    private final String targetLevel;

    SkillTaskCode(SkillSection section, int tacheNumero, String title, String targetLevel) {
        this.section = section;
        this.tacheNumero = tacheNumero;
        this.title = title;
        this.targetLevel = targetLevel;
    }

    public SkillSection getSection() {
        return section;
    }

    /** 1, 2 ou 3 — le numero de tache au sein de l'epreuve. */
    public int getTacheNumero() {
        return tacheNumero;
    }

    public String getTitle() {
        return title;
    }

    public String getTargetLevel() {
        return targetLevel;
    }

    /** Les 3 taches d'une epreuve, dans l'ordre d'examen (EE1 -&gt; EE3). */
    public static List<SkillTaskCode> of(SkillSection section) {
        return List.of(values()).stream()
                .filter(t -> t.section == section)
                .sorted((a, b) -> Integer.compare(a.tacheNumero, b.tacheNumero))
                .toList();
    }

    /** Parse tolerant (casse/espaces libres) ; null si inconnu ou absent. */
    public static SkillTaskCode parse(Object raw) {
        if (raw == null) return null;
        String s = raw.toString().trim().toUpperCase(Locale.ROOT);
        if (s.isEmpty()) return null;
        for (SkillTaskCode t : values()) {
            if (t.name().equals(s)) return t;
        }
        return null;
    }
}
