package com.sejourfr.app.enums;

/**
 * Les indicateurs du dashboard « Suivi » qui ont une <b>date de debut de
 * mesure</b> (arbitrage Q16, aucun backfill).
 *
 * <p>Avant sa date, un indicateur vaut {@code null} — jamais 0 : un compteur
 * qui n'existait pas n'a rien compte, il n'a pas compte zero. La date vit dans
 * {@code analytics/analytics-config-vN.json} ({@code measurementStart}), une
 * par indicateur ; {@code null} dans la config = pas encore mesure.
 */
public enum SuiviIndicator {
    /** Visiteurs uniques ({@code analytics_event}, V043). */
    VISITORS,
    /** Sources d'acquisition ({@code analytics_visitor.ft_source}, V043). */
    ACQUISITION_SOURCES,
    /** Etape 1 : {@code diagnostic_run.subject_viewed_at}. */
    DIAGNOSTIC_SUBJECT_VIEWED,
    /** Etape 2 : {@code diagnostic_run.submitted_at}. */
    DIAGNOSTIC_SUBMITTED,
    /** Etape 3 : soumis connecte ou claim. */
    ACCOUNT_ATTACHED,
    /** Etape 4 : {@code DIAGNOSTIC_REPORT_VIEWED} porteur d'une run. */
    REPORT_VIEWED,
    /** Etape 5 : {@code PLAN_OPENED} porteur d'une run. */
    PLAN_VIEWED,
    /** Etape 6 : {@code PLAN_UNLOCK_CLICKED}. */
    PLAN_UNLOCK_CLICKED,
    /** Achats datés par {@code user_subscriptions.purchased_at}. */
    PURCHASES,
    /** {@code user_subscriptions.origin} (purchase_intent). */
    PURCHASE_ORIGIN,
    /** TVA, frais et net figes a l'ecriture. */
    REVENUE_BREAKDOWN,
    /** {@code payment_refunds}. */
    REFUNDS,
    /** {@code users.signup_context} / {@code signup_diagnostic_type}. */
    SIGNUP_CONTEXT,
    /** {@code users.signup_platform} ventile iOS / Android. */
    SIGNUP_PLATFORM_DETAIL
}
