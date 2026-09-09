package com.sejourfr.app.enums;

import com.sejourfr.app.util.AnalyticsPaths;

import java.util.Arrays;
import java.util.Locale;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

/**
 * Proprietes qu'un evenement d'analytics peut porter — <b>allowlist fermee</b>,
 * cle par cle, valeur par valeur.
 *
 * <p><b>C'est cette classe qui rend le §95 du brief vrai par construction.</b>
 * « Ne jamais stocker de mot de passe, de production, de transcription, de
 * jeton » n'est pas une consigne qu'on espere voir respectee : aucune cle hors
 * de cette liste n'est acceptee, et aucune valeur libre n'existe — chaque
 * propriete est soit un enum, soit un chemin de l'allowlist, soit un
 * identifiant court a charset borne. Meme ordre de preference que partout
 * ailleurs dans le depot : la contrainte dure d'abord, la consigne en dernier
 * recours.
 *
 * <p>Une valeur hors allowlist provoque un <b>400 nomme</b> (champ, valeur
 * recue, valeurs admises), patron {@link TargetProcedure} : jamais un repli
 * muet, qui rangerait une faute de frappe dans une dimension silencieuse.
 */
public enum AnalyticsProperty {

    /** Chemin de la landing d'ou part le geste. Meme allowlist que {@code path}. */
    LANDING_PATH("landingPath", Kind.PATH, null),

    /** Variante editoriale de la landing (test A/B). Slug court. */
    LANDING_VARIANT("landingVariant", Kind.SLUG, null),

    /** Emplacement du CTA clique. */
    CTA_LOCATION("ctaLocation", Kind.ENUM, AnalyticsCtaLocation.class),

    /** Variante de diagnostic choisie. */
    DIAGNOSTIC_TYPE("diagnosticType", Kind.ENUM, AnalyticsDiagnosticType.class),

    /** Moment du parcours ou le compte est demande. */
    REGISTRATION_CONTEXT("registrationContext", Kind.ENUM, AnalyticsRegistrationContext.class),

    /** Code du pass concerne ({@code plans.code}). Jamais un prix, jamais un montant. */
    PLAN_CODE("planCode", Kind.CODE, null),

    /** Ecran d'ou part le geste, quand le chemin ne suffit pas (mobile). */
    SCREEN("screen", Kind.SLUG, null),

    /**
     * Nature de l'exercice lance depuis le Plan.
     *
     * <p>Reprend {@link PlanExerciseKind} <b>tel quel</b> : le Plan sert deja
     * cette valeur aux trois fronts, et une seconde liste ici aurait fini par
     * nommer differemment le meme exercice.
     */
    EXERCISE_KIND("exerciseKind", Kind.ENUM, PlanExerciseKind.class),

    /**
     * L'epreuve concernee par le geste ({@code TCF_EE}, {@code TCF_EO}...).
     *
     * <p>Reprend {@link EpreuveType} <b>tel quel</b>, meme raison que
     * {@link #EXERCISE_KIND} : le Plan sert deja cette valeur aux trois fronts.
     */
    EPREUVE("epreuve", Kind.ENUM, EpreuveType.class),

    /**
     * Combien de lignes le rideau freemium laisse voir <b>en clair</b>.
     *
     * <p>🛑 Avec {@link #TOTAL_COUNT}, c'est ce qui rend le rideau mesurable :
     * le correctif « progression par epreuve » l'a fait passer de « 1 sur 5 » a
     * « 1 sur 9 ou 12 » sur un compte reel. Signal de valeur plus fort, mais
     * l'effet inverse — le decouragement — est tout aussi plausible. On mesure
     * avant de trancher ; on ne tranche pas sur l'intuition.
     */
    VISIBLE_COUNT("visibleCount", Kind.COUNT, null),

    /** Combien de lignes le rideau cache, verrouillees comprises. */
    TOTAL_COUNT("totalCount", Kind.COUNT, null);

    /** Compteur d'affichage : entier positif, quatre chiffres au plus. */
    private static final Pattern COUNT = Pattern.compile("^\\d{1,4}$");

    /**
     * Slug editorial : minuscules, chiffres, tiret, underscore. 40 caracteres.
     * Assez pour nommer une variante ou un ecran, trop court pour y glisser une
     * phrase, et sans espace ni ponctuation ou loger une adresse e-mail.
     */
    private static final Pattern SLUG = Pattern.compile("^[a-z0-9][a-z0-9_-]{0,39}$");

    /** Code de plan : majuscules, chiffres, underscore ({@code INTEGRAL_PASS_2M}). */
    private static final Pattern CODE = Pattern.compile("^[A-Z0-9][A-Z0-9_]{0,63}$");

    private enum Kind { ENUM, PATH, SLUG, CODE, COUNT }

    private final String key;
    private final Kind kind;
    private final Class<? extends Enum<?>> enumType;

    AnalyticsProperty(String key, Kind kind, Class<? extends Enum<?>> enumType) {
        this.key = key;
        this.kind = kind;
        this.enumType = enumType;
    }

    /** Nom de la cle telle qu'elle arrive du client et telle qu'elle est stockee. */
    public String getKey() {
        return key;
    }

    /**
     * Valeur normalisee, prete a etre persistee.
     *
     * @throws IllegalArgumentException si la valeur n'est pas admise. Le message
     *         nomme la cle, la valeur recue et ce qui etait attendu.
     */
    public String normalizeOrThrow(String raw) {
        String value = raw == null ? "" : raw.trim();
        if (value.isEmpty()) {
            throw refus(raw, "une valeur non vide");
        }
        return switch (kind) {
            case ENUM -> normalizeEnum(value);
            // Une landing hors allowlist leve deja avec son propre message
            // nomme : on ne le re-emballe pas, il est plus precis.
            case PATH -> AnalyticsPaths.normalizeOrThrow(value);
            case SLUG -> {
                String slug = value.toLowerCase(Locale.ROOT);
                if (!SLUG.matcher(slug).matches()) {
                    throw refus(raw, "un identifiant court en minuscules, chiffres, « - » ou « _ » (40 caractères max)");
                }
                yield slug;
            }
            case CODE -> {
                String code = value.toUpperCase(Locale.ROOT);
                if (!CODE.matcher(code).matches()) {
                    throw refus(raw, "un code de plan en majuscules, chiffres ou « _ » (64 caractères max)");
                }
                yield code;
            }
            // Un compteur d'ecran, borne a quatre chiffres : c'est une TAILLE
            // d'affichage, jamais une donnee du candidat. La borne est ce qui
            // empeche cette cle de devenir un champ libre numerique.
            case COUNT -> {
                if (!COUNT.matcher(value).matches()) {
                    throw refus(raw, "un entier positif de 4 chiffres au plus");
                }
                yield String.valueOf(Integer.parseInt(value));
            }
        };
    }

    private String normalizeEnum(String value) {
        String candidate = value.toUpperCase(Locale.ROOT);
        for (Enum<?> constant : enumType.getEnumConstants()) {
            if (constant.name().equals(candidate)) return constant.name();
        }
        throw refus(value, "l'une de " + constants());
    }

    private String constants() {
        return Arrays.stream(enumType.getEnumConstants())
                .map(Enum::name)
                .collect(Collectors.joining(", ", "[", "]"));
    }

    private IllegalArgumentException refus(String raw, String attendu) {
        return new IllegalArgumentException(
                "Valeur invalide pour « " + key + " » : « " + raw + " ». Attendu : " + attendu + ".");
    }

    /** La propriete portant cette cle, ou {@code null} si la cle est inconnue. */
    public static AnalyticsProperty byKey(String key) {
        if (key == null) return null;
        for (AnalyticsProperty property : values()) {
            if (property.key.equals(key)) return property;
        }
        return null;
    }
}
