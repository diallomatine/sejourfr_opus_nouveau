package com.sejourfr.app.service.email;

import com.sejourfr.app.config.EmailProperties;
import com.sejourfr.app.enums.EmailType;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.Map;

/**
 * Le gabarit d'un type, <b>lu dans la configuration</b> ({@code sejourfr.email.templates}) :
 * sujet et gabarit local aujourd'hui, {@code brevo-template-id} demain. Aucun
 * identifiant Brevo n'est ecrit dans le code Java.
 */
@Component
@RequiredArgsConstructor
public class EmailTemplateResolver {

    private final EmailProperties properties;

    public EmailProperties.Template resolve(EmailType type) {
        EmailProperties.Template template = properties.getTemplates().get(type);
        if (template == null || template.getSubject() == null || template.getSubject().isBlank()) {
            throw new IllegalStateException("Aucun gabarit configure pour " + type
                    + " (sejourfr.email.templates." + type + ")");
        }
        return template;
    }

    public Map<EmailType, EmailProperties.Template> all() {
        return properties.getTemplates();
    }
}
