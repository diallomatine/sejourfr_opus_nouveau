package com.sejourfr.app.entity;

import com.sejourfr.app.enums.QuestionType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;
import java.util.UUID;

/**
 * Une <b>unite du programme officiel</b> de l'examen civique — l'une des
 * <b>16</b> (V068).
 *
 * <p>Source de droit : <b>arrete du 10 octobre 2025</b> relatif au programme, aux
 * epreuves et aux modalites d'organisation de l'examen civique (JORF n° 0240 du
 * 12 octobre 2025, <b>NOR INTV2527907A</b>), <b>annexe I</b>. 16 = les
 * <b>14 notions</b> de connaissance + les <b>2 unites de mises en situation</b>,
 * que l'annexe place au meme niveau qu'une notion, avec leur propre quota, dans
 * « Principes et valeurs » (6) et « Droits et devoirs » (6).
 *
 * <h2>🛑 Ce n'est PAS une version de {@link CivicNotion}</h2>
 * <p>Ce sont deux objets de nature differente, et le depot a paye cher de les
 * avoir confondus :
 * <ul>
 *   <li>{@link CivicNotion} (46 actives) est une <b>taxonomie editoriale</b>,
 *       « reconstruite A PARTIR DU CORPUS REEL » (V058). Elle sert a <b>ecrire</b>
 *       des questions et a choisir quoi faire travailler. Elle bouge.</li>
 *   <li><b>Cette classe</b> est <b>le programme</b>. Elle sert a <b>tirer</b> un
 *       examen conforme et a <b>mesurer</b> un candidat. Elle ne bouge que si
 *       l'arrete bouge.</li>
 * </ul>
 * Une {@code CivicNotion} active <b>doit</b> declarer son unite officielle : la
 * base l'impose ({@code chk_civic_notion_rattachee}).
 *
 * <h2>🛑 Aucun setter d'ecriture metier, et pas d'admin</h2>
 * <p>La table est <b>seedee par migration</b> et n'a <b>aucun endpoint</b> : une
 * valeur d'arrete ne se modifie pas depuis une interface (garde-fou 1 de D-38).
 * {@code @Setter} n'est la que pour le mapping JPA, sur le patron des autres
 * entites du depot.
 *
 * <h2>Ou vit quoi (D-38)</h2>
 * <table>
 *   <tr><td>Le <b>quota par unite</b></td><td><b>ici</b>, {@link #examQuota}</td></tr>
 *   <tr><td>40 questions, seuil 32, 45 min, partage 28 / 12</td>
 *       <td>{@code CivicExamFormat}</td></tr>
 *   <tr><td>Les totaux par thematique (11 / 6 / 11 / 8 / 4)</td>
 *       <td><b>nulle part</b> : ils se <b>derivent</b> par somme des quotas</td></tr>
 * </table>
 */
@Entity
@Table(name = "civic_official_units")
@Getter
@Setter
public class CivicOfficialUnit {

    /**
     * 🛑 <b>Pas de {@code @UuidGenerator}</b>, contrairement a {@link CivicNotion} :
     * les 16 lignes portent des UUID <b>fixes</b>, poses par V068. Une table
     * seedee une fois se reference par un id stable, y compris depuis un test.
     */
    @Id
    @Column(columnDefinition = "uuid")
    private UUID id;

    /** Le code de l'unite ({@code P1_DEVISE_SYMBOLES}…), stable et unique. */
    @Column(nullable = false, length = 40, unique = true)
    private String code;

    /** Le theme par son CODE ({@code CIV_PRINCIPES}…), comme {@link CivicNotion}. */
    @Column(name = "theme_code", nullable = false, length = 64)
    private String themeCode;

    /**
     * Le libelle de l'annexe I, <b>tel qu'il s'affiche au candidat</b>.
     *
     * <p>🛑 C'est ce que l'ecran lit. Le vocabulaire interne ({@code lot},
     * {@code step}, {@code journey}, {@code notion}) n'apparait jamais (D-21).
     */
    @Column(nullable = false, length = 160)
    private String label;

    @Column(name = "display_order", nullable = false)
    private short displayOrder;

    /**
     * Questions que l'examen reel tire sur cette unite.
     *
     * <p>🛑 <b>La somme des 16 vaut 40</b>, dont <b>12</b> en
     * {@link QuestionType#MISE_SITUATION}. Verifie par un <b>test normatif</b>, pas
     * par un {@code CHECK} : Postgres refuse une sous-requete en contrainte, et un
     * {@code CHECK} est <b>par ligne</b> — il ne peut pas sommer 16 lignes
     * (garde-fou 2 de D-38).
     */
    @Column(name = "exam_quota", nullable = false)
    private short examQuota;

    /**
     * Le type de question que l'unite porte.
     *
     * <p>🛑 <b>Un type, pas un booleen</b> « est-ce une mise en situation » : c'est
     * ce que le tirage conforme consommera directement, et ca reutilise le
     * vocabulaire de {@code questions.question_type} au lieu d'en inventer un
     * second. Seules deux valeurs sont admises en base
     * ({@code chk_civic_official_unit_type}).
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "question_type", nullable = false, length = 24)
    private QuestionType questionType;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt = Instant.now();
}
