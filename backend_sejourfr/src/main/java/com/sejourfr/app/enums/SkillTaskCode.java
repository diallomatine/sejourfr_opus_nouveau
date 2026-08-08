package com.sejourfr.app.enums;

import java.util.List;
import java.util.Locale;

/**
 * Les 6 taches du TCF IRN sur lesquelles s'accrochent les competences.
 *
 * <p><b>Pourquoi un enum et pas une table.</b> Les 6 taches sont un referentiel
 * OFFICIEL fige par le TCF : ni l'admin ni un seed ne doivent pouvoir en
 * ajouter, en renommer ou en supprimer une. Une table les aurait rendues
 * editables, avec le risque qu'un libelle derive d'un front a l'autre. Le
 * contenu editorial (competences, sujets, references) vit en base ; le squelette
 * de l'examen vit ici.
 *
 * <p>Le {@code targetLevel} est le palier PRINCIPALEMENT vise par la tache
 * (sections 5 et 6 de la spec). Quand la spec donne une fourchette (EE1 « A1-A2 »,
 * EE2 « A2-B1 », EE3 « B1-B2 »), on retient la borne HAUTE : c'est le palier
 * qu'un candidat cherche a atteindre sur cette tache, pas celui dont il part.
 * Il ne se confond pas avec {@code skills.target_level}, qui affine competence
 * par competence a l'interieur d'une meme tache.
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
