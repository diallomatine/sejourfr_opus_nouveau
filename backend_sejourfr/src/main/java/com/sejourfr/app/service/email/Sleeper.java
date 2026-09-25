package com.sejourfr.app.service.email;

import java.time.Duration;

/**
 * L'attente entre deux tentatives d'envoi, injectable pour que la relance
 * immediate se teste sans attendre 30 s, 2 min puis 5 min (arbitrage n°17).
 */
@FunctionalInterface
public interface Sleeper {

    void sleep(Duration duration) throws InterruptedException;
}
