package com.sejourfr.app.security;

import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.security.web.header.writers.ReferrerPolicyHeaderWriter.ReferrerPolicy;

@Configuration
@EnableMethodSecurity
@EnableConfigurationProperties(JwtProperties.class)
public class SecurityConfig {

    private final JwtAuthenticationFilter jwtAuthenticationFilter;
    private final RestAuthEntryPoints.Unauthorized unauthorizedHandler;
    private final RestAuthEntryPoints.Forbidden forbiddenHandler;

    public SecurityConfig(
            JwtAuthenticationFilter jwtAuthenticationFilter,
            RestAuthEntryPoints.Unauthorized unauthorizedHandler,
            RestAuthEntryPoints.Forbidden forbiddenHandler) {
        this.jwtAuthenticationFilter = jwtAuthenticationFilter;
        this.unauthorizedHandler = unauthorizedHandler;
        this.forbiddenHandler = forbiddenHandler;
    }

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                .cors(Customizer.withDefaults())                                  // <-- AJOUTÉ
                .csrf(AbstractHttpConfigurer::disable)
                // Headers de securite. X-Content-Type-Options=nosniff et
                // X-Frame-Options=DENY sont deja poses par defaut ; on ajoute
                // HSTS (emis uniquement sur requete HTTPS — le proxy termine le
                // TLS et transmet X-Forwarded-Proto), Referrer-Policy, et une
                // CSP d'API : `default-src 'none'` neutralise toute execution de
                // script dans une reponse (defense XSS), `style-src 'unsafe-inline'`
                // + `img-src` laissent la page HTML de confirmation d'email
                // s'afficher correctement.
                .headers(headers -> headers
                        .httpStrictTransportSecurity(hsts -> hsts
                                .includeSubDomains(true)
                                .preload(true)
                                .maxAgeInSeconds(31_536_000L))
                        .referrerPolicy(rp -> rp.policy(ReferrerPolicy.STRICT_ORIGIN_WHEN_CROSS_ORIGIN))
                        .contentSecurityPolicy(csp -> csp.policyDirectives(
                                "default-src 'none'; style-src 'unsafe-inline'; "
                                        + "img-src 'self' data:; frame-ancestors 'none'; base-uri 'none'"))
                )
                .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                // 401 sur "pas authentifie / token KO" (declenche le refresh JWT cote client),
                // 403 sur "authentifie mais role insuffisant".
                .exceptionHandling(e -> e
                        .authenticationEntryPoint(unauthorizedHandler)
                        .accessDeniedHandler(forbiddenHandler)
                )
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()   // <-- AJOUTÉ
                        .requestMatchers(HttpMethod.GET, "/actuator/health").permitAll()
                        // /api/auth/me exige un Bearer valide — il vit sous
                        // /api/auth/** pour des raisons d'URL, mais ce n'est
                        // pas un endpoint public. Sans cette ligne, le
                        // permitAll() en dessous laisse passer la requête
                        // jusqu'au controller, et `principal` y est null →
                        // NullPointerException 500. Cf audit Vuln 8.
                        .requestMatchers(HttpMethod.GET, "/api/auth/me").authenticated()
                        .requestMatchers("/api/auth/**").permitAll()
                        .requestMatchers(HttpMethod.GET, "/files/**").permitAll()
                        .requestMatchers(HttpMethod.GET, "/api/exams/**").permitAll()
                        // Liste publique des plans pour la section Tarifs de la landing.
                        // Lecture seule, pas de données sensibles.
                        .requestMatchers(HttpMethod.GET, "/api/billing/plans").permitAll()
                        // Webhook Stripe : appelé par Stripe (pas un user), authentifié
                        // par signature HMAC vérifiée dans BillingService.
                        .requestMatchers(HttpMethod.POST, "/api/billing/webhook").permitAll()
                        // Webhooks stores mobiles : Apple (ASSN V2, JWS signé) et
                        // Google (RTDN via Pub/Sub, message signé). Authentifiés
                        // par vérification de signature/authenticité dans
                        // StoreWebhookService — lots 2 et 3.
                        .requestMatchers(HttpMethod.POST, "/api/billing/webhooks/apple").permitAll()
                        .requestMatchers(HttpMethod.POST, "/api/billing/webhooks/google").permitAll()
                        // Formulaire de contact accessible sans login (visiteur
                        // qui n'a pas encore créé de compte peut nous écrire).
                        .requestMatchers(HttpMethod.POST, "/api/contact").permitAll()
                        // Surface publique pour les visiteurs non authentifiés
                        // (démo guest : themes, exams, attempts limités par IP).
                        .requestMatchers("/api/public/**").permitAll()
                        .requestMatchers("/api/admin/**").hasRole("ADMIN")
                        .anyRequest().authenticated()
                )
                .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);
        return http.build();
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public DaoAuthenticationProvider authenticationProvider(UserDetailsService uds, PasswordEncoder encoder) {
        DaoAuthenticationProvider provider = new DaoAuthenticationProvider(uds);
        provider.setPasswordEncoder(encoder);
        return provider;
    }

    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration cfg) throws Exception {
        return cfg.getAuthenticationManager();
    }
}
