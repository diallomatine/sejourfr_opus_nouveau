package com.sejourfr.app.support;

import java.time.Duration;
import java.util.function.BooleanSupplier;

/**
 * Attente bornee d'un effet asynchrone (l'executor email). Pas d'Awaitility
 * dans le depot : une boucle courte suffit, et elle echoue avec un message clair.
 */
public final class EmailTestSupport {

    private EmailTestSupport() {
    }

    public static void await(String what, BooleanSupplier condition) {
        long deadline = System.nanoTime() + Duration.ofSeconds(10).toNanos();
        while (System.nanoTime() < deadline) {
            if (condition.getAsBoolean()) {
                return;
            }
            try {
                Thread.sleep(25);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                throw new AssertionError("interrompu en attendant : " + what);
            }
        }
        throw new AssertionError("jamais observe en 10 s : " + what);
    }

    /** Laisse a l'executor le temps de faire ce qu'il ferait a tort. */
    public static void settle() {
        try {
            Thread.sleep(400);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
}
