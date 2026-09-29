package com.sejourfr.app.util;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * LA NEUTRALISATION TYPOGRAPHIQUE, et son invariant : ON RESTITUE L'ORIGINAL.
 *
 * <p>Le defaut corrige : le controle « l'extrait est dans le texte » etait
 * strictement litteral. La production d'un candidat porte des apostrophes courbes,
 * le texte modele des apostrophes droites, et rien ne garantit qu'un modele soit
 * coherent entre son texte et son extrait — un extrait JUSTE etait alors declare
 * introuvable et la section entiere disparaissait de l'ecran.
 *
 * <p>Ce qui n'est PAS relache : aucun appariement flou. Un extrait reellement
 * absent reste refuse.
 */
class TexteNormaliseTest {

    @Test
    void extraitAApostropheCourbe_retrouveDansUnTexteAApostropheDroite() {
        TexteNormalise texte = TexteNormalise.de("Je t'annonce que j'ai emménagé.");

        assertThat(texte.sousChaineOriginale("j’ai emménagé"))
            .contains("j'ai emménagé");
    }

    /** ET L'INVERSE : le modele n'est coherent dans aucun sens en particulier. */
    @Test
    void extraitAApostropheDroite_retrouveDansUnTexteAApostropheCourbe() {
        TexteNormalise texte = TexteNormalise.de("Je t’annonce que j’ai emménagé.");

        assertThat(texte.sousChaineOriginale("j'ai emménagé"))
            .contains("j’ai emménagé");
    }

    /**
     * L'INVARIANT : ce qui est rendu est la sous-chaine ORIGINALE exacte, jamais
     * la forme normalisee. Le front surligne par simple recherche de chaine dans
     * le texte qu'il affiche — un extrait normalise ne s'y trouverait pas.
     */
    @Test
    void lExtraitRestitueEstIdentiqueAuTexte() {
        String source = "Ce logement — lumineux — me plaît beaucoup.";
        TexteNormalise texte = TexteNormalise.de(source);

        String extrait = texte.sousChaineOriginale("logement - lumineux - me plaît").orElseThrow();

        assertThat(source).contains(extrait);
        assertThat(extrait).isEqualTo("logement — lumineux — me plaît");
    }

    @Test
    void espaceInsecableEtSautDeLigneNeCassentPlusUnExtrait() {
        TexteNormalise texte = TexteNormalise.de("Passe quand tu veux :\nje te ferai visiter !");

        assertThat(texte.sousChaineOriginale("tu veux : je te ferai"))
            .contains("tu veux :\nje te ferai");
    }

    @Test
    void ligatureDeveloppee() {
        TexteNormalise texte = TexteNormalise.de("Mon cœur balance encore.");

        assertThat(texte.sousChaineOriginale("Mon coeur balance")).contains("Mon cœur balance");
    }

    /** UN EXTRAIT REELLEMENT ABSENT RESTE REFUSE : rien n'est rapproche au jugé. */
    @Test
    void unExtraitInventeResteIntrouvable() {
        TexteNormalise texte = TexteNormalise.de("Je t'annonce que j'ai emménagé.");

        assertThat(texte.sousChaineOriginale("un passage que le texte ne contient pas")).isEmpty();
        assertThat(texte.contient("j'ai déménagé")).isFalse();
    }

    /** LA CASSE ET LES ACCENTS NE SONT PAS NEUTRALISES : c'est ce que le candidat écrit. */
    @Test
    void niLaCasseNiLesAccentsNeSontNeutralises() {
        TexteNormalise texte = TexteNormalise.de("J'ai emménagé près de la gare.");

        assertThat(texte.contient("j'ai emménagé")).isFalse();
        assertThat(texte.contient("pres de la gare")).isFalse();
    }

    @Test
    void unExtraitVideOuNulNeTrouveRien() {
        TexteNormalise texte = TexteNormalise.de("Un texte quelconque.");

        assertThat(texte.sousChaineOriginale(null)).isEmpty();
        assertThat(texte.sousChaineOriginale("   ")).isEmpty();
        assertThat(TexteNormalise.de(null).sousChaineOriginale("quoi que ce soit")).isEmpty();
    }

    /**
     * FORME MOT : celle du rapprochement de preuve, DEPLACEE ici sans un octet de
     * changement — minuscules et accents retires en plus de la typographie.
     */
    @Test
    void laFormeMotMinusculiseEtRetireLesAccents() {
        assertThat(TexteNormalise.mot("Emménagé")).isEqualTo("emmenage");
        assertThat(TexteNormalise.mot("CŒUR")).isEqualTo("coeur");
        assertThat(TexteNormalise.mot(null)).isEmpty();
    }
}
