package com.sejourfr.app.support;

import com.sejourfr.app.config.EmailAsyncConfig;
import org.springframework.beans.factory.config.BeanPostProcessor;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;

import java.util.concurrent.RejectedExecutionHandler;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * <b>Le compteur EXACT des taches de l'executor email</b>, pour les tests
 * d'integration.
 *
 * <p>🛑 Pourquoi il existe : {@code ThreadPoolExecutor.getTaskCount()} ne compte
 * PAS une tache qu'un worker vient de retirer de la file (ou recoit comme
 * premiere tache) tant qu'il n'a pas pris son verrou — la somme est
 * « completees + workers verrouilles + taille de la file ». Pendant cette
 * fenetre, {@code getTaskCount() == getCompletedTaskCount()} est VRAI alors que
 * la tache n'a pas tourne : l'ancien {@code awaitEmailExecutorIdle} rendait la
 * main trop tot, la ligne d'envoi etait encore {@code PENDING}, et la relance
 * differee suivante ne la reprenait pas (echec intermittent de
 * {@code EmailDeferredRetryIT.troisRelancesAuMaximum}).
 *
 * <p>Ici le compte monte <b>dans le thread appelant</b>, au moment ou
 * {@code execute} decore la tache, et ne redescend qu'a la fin de son
 * execution (ou a son rejet). Une tache qui en soumet une autre la compte avant
 * de se decompter : zero veut donc dire « plus rien a faire ».
 *
 * <p>Pose par un {@link BeanPostProcessor} <b>avant</b> l'initialisation du
 * bean : {@code afterPropertiesSet} reconstruit alors le pool avec le decorateur.
 * Le bean de production n'est pas modifie.
 */
public class EmailExecutorTracker implements BeanPostProcessor {

    private final AtomicInteger inFlight = new AtomicInteger();
    private final AtomicInteger decorated = new AtomicInteger();

    @Override
    public Object postProcessBeforeInitialization(Object bean, String beanName) {
        if (EmailAsyncConfig.EMAIL_TASK_EXECUTOR.equals(beanName)
                && bean instanceof ThreadPoolTaskExecutor executor) {
            RejectedExecutionHandler original =
                    executor.getThreadPoolExecutor().getRejectedExecutionHandler();
            executor.setRejectedExecutionHandler((task, pool) -> {
                if (task instanceof Tracked tracked) tracked.done();
                original.rejectedExecution(task, pool);
            });
            executor.setTaskDecorator(this::track);
        }
        return bean;
    }

    /**
     * 🛑 Echoue au demarrage si le decorateur n'a pas pris : un compteur
     * toujours a zero rendrait l'attente « au repos » immediate, en silence.
     */
    @Override
    public Object postProcessAfterInitialization(Object bean, String beanName) {
        if (EmailAsyncConfig.EMAIL_TASK_EXECUTOR.equals(beanName)
                && bean instanceof ThreadPoolTaskExecutor executor) {
            int avant = decorated.get();
            executor.execute(() -> { });
            if (decorated.get() == avant) {
                throw new IllegalStateException(
                        "EmailExecutorTracker : le decorateur de taches n'est pas actif sur "
                                + EmailAsyncConfig.EMAIL_TASK_EXECUTOR);
            }
        }
        return bean;
    }

    /** Taches soumises et pas encore terminees. */
    public int inFlight() {
        return inFlight.get();
    }

    private Runnable track(Runnable task) {
        inFlight.incrementAndGet();
        decorated.incrementAndGet();
        return new Tracked(task);
    }

    private final class Tracked implements Runnable {
        private final Runnable task;
        private final AtomicBoolean finished = new AtomicBoolean();

        private Tracked(Runnable task) {
            this.task = task;
        }

        @Override
        public void run() {
            try {
                task.run();
            } finally {
                done();
            }
        }

        void done() {
            if (finished.compareAndSet(false, true)) inFlight.decrementAndGet();
        }
    }
}
