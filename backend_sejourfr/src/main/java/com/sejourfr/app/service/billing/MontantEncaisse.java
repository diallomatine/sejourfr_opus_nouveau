package com.sejourfr.app.service.billing;

import com.sejourfr.app.entity.UserSubscription;

import java.math.BigDecimal;

/**
 * Le montant reellement encaisse pour une souscription, <b>fige au moment de
 * l'encaissement</b>.
 *
 * <p><b>Pourquoi ce n'est pas calcule a la lecture.</b> Jusqu'ici, le revenu ne
 * pouvait se lire qu'en relisant {@code plans.price} — un prix <i>modifiable
 * depuis la console admin</i>. Une simple baisse de tarif reecrivait donc
 * retroactivement tout le chiffre d'affaires du passe. Un montant se constate
 * une fois, au paiement, et ne se recalcule plus jamais.
 *
 * <p>Idem pour le taux de change : convertir aujourd'hui un dollar encaisse
 * l'an dernier donnerait un chiffre d'affaires qui bouge tout seul. Le taux
 * voyage donc avec le montant, dans la meme ligne.
 *
 * @param amountCents    montant dans la plus petite unite de sa devise
 * @param currency       devise ISO 4217, en majuscules
 * @param amountEurCents le meme montant en centimes d'euro, ou {@code null} si
 *                       la devise n'a pas de taux configure — <i>un revenu
 *                       inconnu vaut null, jamais zero</i>
 * @param fxRateToEur    taux applique, ou {@code null} pour la meme raison
 */
public record MontantEncaisse(int amountCents, String currency,
                              Integer amountEurCents, BigDecimal fxRateToEur) {

    /**
     * Montant inconnu : rien n'est ecrit, les quatre colonnes restent nulles.
     *
     * <p>Cas legitimes : un canal qui ne nous dit pas ce qu'il a preleve, un
     * plan sans prix. On prefere l'aveu au chiffre invente — le tableau de bord
     * sait afficher « inconnu », il ne sait pas deviner qu'un « 0 » est faux.
     */
    public static final MontantEncaisse INCONNU = new MontantEncaisse(0, null, null, null);

    /** Vrai si un montant a reellement ete constate. */
    public boolean estConnu() {
        return currency != null && !currency.isBlank();
    }

    /**
     * Recopie ce montant sur la souscription — <b>unique point d'ecriture</b>
     * des quatre colonnes, pour qu'aucun canal n'en oublie une et ne viole
     * {@code chk_user_subscriptions_amount_currency} (montant et devise vont
     * ensemble, ou pas du tout).
     *
     * <p>Un montant inconnu n'ecrit rien plutot que d'ecrire des zeros : la
     * ligne reste a {@code NULL}, ce qui se lit « on ne sait pas », pas
     * « gratuit ».
     */
    public void appliquerA(UserSubscription subscription) {
        if (subscription == null || !estConnu()) return;
        subscription.setAmountCents(amountCents);
        subscription.setCurrency(currency);
        subscription.setAmountEurCents(amountEurCents);
        subscription.setFxRateToEur(fxRateToEur);
    }
}
