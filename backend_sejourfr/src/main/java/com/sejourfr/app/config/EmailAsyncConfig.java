package com.sejourfr.app.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;

import java.util.concurrent.ThreadPoolExecutor;

/**
 * L'executor DEDIE des emails.
 *
 * <p>Sans lui, les mails partageaient l'executor par defaut de Spring Boot avec
 * la correction IA des productions et l'analyse des competences : une relance
 * SMTP (jusqu'a ~7 min par mail) aurait bloque un thread de notation payante.
 *
 * <p>🛑 BORNE (file finie) et SANS {@code CallerRunsPolicy} (complement E des
 * arbitrages) : la boucle de relance ne doit jamais tourner dans un thread de
 * requete. Un rejet leve {@code TaskRejectedException}, que
 * {@code EmailDispatcher} transforme en ligne {@code FAILED}.
 */
@Configuration
public class EmailAsyncConfig {

    public static final String EMAIL_TASK_EXECUTOR = "emailTaskExecutor";

    @Bean(name = EMAIL_TASK_EXECUTOR)
    public ThreadPoolTaskExecutor emailTaskExecutor(EmailProperties properties) {
        EmailProperties.Executor cfg = properties.getExecutor();
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        executor.setCorePoolSize(cfg.getCorePoolSize());
        executor.setMaxPoolSize(cfg.getMaxPoolSize());
        executor.setQueueCapacity(cfg.getQueueCapacity());
        executor.setThreadNamePrefix("email-");
        executor.setRejectedExecutionHandler(new ThreadPoolExecutor.AbortPolicy());
        executor.setWaitForTasksToCompleteOnShutdown(true);
        executor.setAwaitTerminationSeconds(20);
        executor.initialize();
        return executor;
    }
}
