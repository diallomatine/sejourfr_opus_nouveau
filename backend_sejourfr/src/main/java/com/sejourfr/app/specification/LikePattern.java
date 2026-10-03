package com.sejourfr.app.specification;

import java.util.Locale;

/**
 * Motif LIKE « contient », insensible à la casse, jokers saisis échappés : un
 * {@code _} est courant dans un email et ne doit pas valoir « n'importe quel
 * caractère ». Partagé par les recherches admin.
 */
public final class LikePattern {

    public static final char ESCAPE = '\\';

    private LikePattern() {}

    public static String contient(String saisie) {
        String lower = saisie.trim().toLowerCase(Locale.ROOT);
        return "%" + lower.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_") + "%";
    }
}
