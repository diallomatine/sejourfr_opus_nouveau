package com.sejourfr.app.util;

import com.sejourfr.app.config.TarifsLlm;
import tools.jackson.databind.JsonNode;

import java.time.Clock;
import java.time.Instant;

/**
 * Cout d'UN appel LLM, en <b>micro-dollars</b>, seul endroit du depot ou le
 * calcul existe.
 *
 * <p><b>Pourquoi le micro-dollar.</b> Le cout etait jusqu'ici arrondi au
 * <i>centime superieur</i> ({@code Math.ceil}) avant d'etre persiste. Sur une
 * micro-analyse de competence, qui coute environ 0,0013 $, cet arrondi
 * multipliait la facture enregistree par ~8 : une campagne de 90 cas a laisse
 * « 90 centimes » en base pour 9,9 centimes reellement depenses. Le millionieme
 * de dollar tient toute la gamme sans distorsion (le plus petit appel du depot
 * en vaut encore ~1 700) et reste un <b>entier</b>, donc additionnable sans
 * erreur de virgule flottante quand un second appel s'ajoute au premier. La
 * prudence historique est conservee — on arrondit toujours au SUPERIEUR — mais a
 * une granularite 10 000 fois plus fine, donc sans effet mesurable.
 *
 * <p><b>Trois tarifs, pas deux.</b> Les tokens d'entree servis par le cache de
 * prefixe du fournisseur coutent, chez DeepSeek, 31 fois moins que les autres.
 * La reponse porte deja le decoupage ({@code prompt_cache_hit_tokens} /
 * {@code prompt_cache_miss_tokens} chez DeepSeek,
 * {@code prompt_tokens_details.cached_tokens} chez OpenAI) : il suffit de le
 * lire. Quand il est absent — autre fournisseur, ancienne reponse, champ
 * manquant — <b>tout est facture en cache miss</b>, c'est-a-dire au plein tarif :
 * on surestime, jamais l'inverse.
 *
 * <p><b>Heures pleines.</b> Le multiplicateur est resolu a l'instant de l'appel,
 * en UTC, depuis des plages <i>declarees en configuration</i>. L'horloge est un
 * parametre de ce calcul et non un champ injecte dans onze clients : c'est ici,
 * et seulement ici, qu'une date decide d'un montant, donc c'est ici que le test
 * doit pouvoir la figer.
 */
public record CoutAppelLlm(TarifsLlm tarifs, Clock horloge) {

    private static final long MICRO_PAR_DOLLAR = 1_000_000L;

    public CoutAppelLlm(TarifsLlm tarifs) {
        this(tarifs, Clock.systemUTC());
    }

    /**
     * Tokens consommes par un appel, tels que le fournisseur les rapporte.
     *
     * @param entreeTotal   TOUS les tokens d'entree, cache compris.
     * @param entreeCacheHit sous-ensemble de {@code entreeTotal} servi par le
     *                       cache de prefixe ; {@code null} = inconnu, donc
     *                       facture au plein tarif.
     * @param sortie        tokens generes.
     */
    public record Tokens(Integer entreeTotal, Integer entreeCacheHit, Integer sortie) {

        /** Tokens d'entree factures au tarif plein. */
        public int cacheMiss() {
            int total = nz(entreeTotal);
            int hit = Math.min(nz(entreeCacheHit), total);
            return Math.max(total - hit, 0);
        }

        /** Tokens d'entree factures au tarif de cache. */
        public int cacheHit() {
            return Math.min(nz(entreeCacheHit), nz(entreeTotal));
        }

        private static int nz(Integer v) {
            return v == null || v < 0 ? 0 : v;
        }
    }

    /**
     * Lit le decoupage d'entree d'une reponse « compatible OpenAI ». Deux
     * dialectes sont acceptes parce que les deux existent chez des fournisseurs
     * que ce meme client sert : DeepSeek expose {@code prompt_cache_hit_tokens}
     * a plat, OpenAI expose {@code prompt_tokens_details.cached_tokens}.
     *
     * @return {@code null} quand la reponse ne dit rien — l'appelant facturera
     *         alors tout au plein tarif.
     */
    public static Integer lireCacheHitTokens(JsonNode usage) {
        if (usage == null || usage.isMissingNode()) return null;
        if (usage.hasNonNull("prompt_cache_hit_tokens")) {
            return usage.get("prompt_cache_hit_tokens").asInt();
        }
        JsonNode details = usage.path("prompt_tokens_details");
        if (details.hasNonNull("cached_tokens")) {
            return details.get("cached_tokens").asInt();
        }
        return null;
    }

    /**
     * Cout de l'appel en micro-dollars, ou {@code null} quand aucun token n'a ete
     * rapporte (rien a facturer, et un 0 persiste se lirait « gratuit »).
     */
    public Integer microDollars(Tokens tokens) {
        if (tokens == null) return null;
        int miss = tokens.cacheMiss();
        int hit = tokens.cacheHit();
        int sortie = Tokens.nz(tokens.sortie());
        if (miss == 0 && hit == 0 && sortie == 0) return null;

        double usd = miss * tarifs.getCostPerMillionInputTokens() / MICRO_PAR_DOLLAR
            + hit * tarifCacheHit() / MICRO_PAR_DOLLAR
            + sortie * tarifs.getCostPerMillionOutputTokens() / MICRO_PAR_DOLLAR;
        usd *= multiplicateurCourant();
        if (usd <= 0) return null;
        return (int) Math.min(Math.ceil(usd * MICRO_PAR_DOLLAR), Integer.MAX_VALUE);
    }

    /** Raccourci : les trois nombres bruts d'une reponse. */
    public Integer microDollars(Integer entreeTotal, Integer entreeCacheHit, Integer sortie) {
        return microDollars(new Tokens(entreeTotal, entreeCacheHit, sortie));
    }

    /** true si l'instant courant tombe dans les heures pleines du fournisseur. */
    public boolean heurePleine() {
        return PlagesHorairesUtc.parse(tarifs.getPeakUtcRanges()).contient(maintenant());
    }

    private double multiplicateurCourant() {
        double facteur = tarifs.getPeakMultiplier();
        if (facteur <= 0 || facteur == 1.0) return 1.0;
        return heurePleine() ? facteur : 1.0;
    }

    /** 0 = ce fournisseur n'a pas de tarif de cache → plein tarif d'entree. */
    private double tarifCacheHit() {
        double cache = tarifs.getCostPerMillionCachedInputTokens();
        return cache > 0 ? cache : tarifs.getCostPerMillionInputTokens();
    }

    private Instant maintenant() {
        return horloge == null ? Instant.now() : horloge.instant();
    }
}
