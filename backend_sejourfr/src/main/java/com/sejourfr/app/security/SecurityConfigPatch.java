package com.sejourfr.app.security;

/*
 * ============================================================================
 *  PATCH à appliquer dans ta SecurityConfig existante
 * ============================================================================
 *
 *  Dans la méthode securityFilterChain(HttpSecurity http), localise
 *  le bloc .authorizeHttpRequests(...) et complète la liste des règles
 *  comme ci-dessous.
 *
 *  L'ordre est important : les règles publiques d'abord, puis les règles
 *  par préfixe, puis le anyRequest().authenticated() en dernier.
 *
 *  Note : .cors(Customizer.withDefaults()) et le .permitAll() sur OPTIONS
 *  doivent toujours être présents pour que les preflights fonctionnent
 *  depuis le mobile et le admin web.
 *
 * ============================================================================
 *
 *  Bloc à substituer (copy-paste dans ta SecurityConfig) :
 *
 *
 *      http
 *          .cors(Customizer.withDefaults())
 *          .csrf(AbstractHttpConfigurer::disable)
 *          .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
 *          .authorizeHttpRequests(auth -> auth
 *              // -- Preflight CORS toujours en premier
 *              .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()
 *
 *              // -- Endpoints publics auth
 *              .requestMatchers(HttpMethod.POST, "/api/auth/login").permitAll()
 *              .requestMatchers(HttpMethod.POST, "/api/auth/register").permitAll()
 *              .requestMatchers(HttpMethod.POST, "/api/auth/refresh").permitAll()
 *              .requestMatchers(HttpMethod.POST, "/api/auth/forgot-password").permitAll()
 *              .requestMatchers(HttpMethod.POST, "/api/auth/reset-password").permitAll()
 *
 *              // -- Endpoints publics divers
 *              .requestMatchers(HttpMethod.GET, "/actuator/health").permitAll()
 *              .requestMatchers(HttpMethod.GET, "/files/**").permitAll()
 *              .requestMatchers(
 *                  "/swagger-ui.html",
 *                  "/swagger-ui/**",
 *                  "/v3/api-docs",
 *                  "/v3/api-docs/**"
 *              ).permitAll()
 *
 *              // -- Endpoints utilisateurs (USER ou ADMIN)
 *              .requestMatchers("/api/auth/me").authenticated()
 *              .requestMatchers("/api/themes/**").authenticated()
 *              .requestMatchers("/api/attempts/**").authenticated()
 *              .requestMatchers("/api/me/**").authenticated()
 *
 *              // -- Endpoints admin
 *              .requestMatchers("/api/admin/**").hasRole("ADMIN")
 *
 *              // -- Tout le reste : authentifié
 *              .anyRequest().authenticated()
 *          )
 *          .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);
 *
 *      return http.build();
 *
 * ============================================================================
 */
public final class SecurityConfigPatch {
    private SecurityConfigPatch() {}
}
