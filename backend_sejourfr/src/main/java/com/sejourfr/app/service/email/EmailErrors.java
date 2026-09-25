package com.sejourfr.app.service.email;

import com.sejourfr.app.util.LogMask;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Assainit un message d'erreur avant de le logguer ou de le persister dans
 * {@code email_deliveries.error_message}.
 *
 * <p>Un {@code SendFailedException} SMTP met les adresses refusees dans son
 * message, et une exception de rendu pourrait citer une URL : on masque les
 * adresses ({@link LogMask#email}), on retire toute valeur de {@code token=}, et
 * on tronque a 500 caracteres.
 */
public final class EmailErrors {

    public static final int MAX_LENGTH = 500;

    private static final Pattern EMAIL = Pattern.compile("[A-Za-z0-9._%+\\-]+@[A-Za-z0-9.\\-]+\\.[A-Za-z]{2,}");
    private static final Pattern TOKEN = Pattern.compile("(?i)(token=)[^\\s&\"'<>]+");

    private EmailErrors() {
    }

    public static String sanitize(Throwable error) {
        if (error == null) return "unknown";
        String message = error.getMessage();
        String base = error.getClass().getSimpleName() + (message == null ? "" : ": " + message);
        return sanitize(base);
    }

    public static String sanitize(String raw) {
        if (raw == null) return null;
        String out = TOKEN.matcher(raw).replaceAll("$1***");
        Matcher m = EMAIL.matcher(out);
        StringBuilder sb = new StringBuilder();
        while (m.find()) {
            m.appendReplacement(sb, Matcher.quoteReplacement(LogMask.email(m.group())));
        }
        m.appendTail(sb);
        out = sb.toString().replaceAll("[\\r\\n]+", " ");
        return out.length() <= MAX_LENGTH ? out : out.substring(0, MAX_LENGTH);
    }
}
