# SejourFR Backend

Backend Spring Boot 3.3 / Java 21 pour l'application SejourFR.

## Demarrage

### Prerequis

- Java 21
- PostgreSQL 14+ (local)
- Maven 3.9+ (ou utiliser `./mvnw` si tu ajoutes le wrapper)

### Base de donnees (dev)

```bash
createdb sejourfr
psql -c "CREATE USER sejourfr WITH PASSWORD 'sejourfr';"
psql -c "GRANT ALL PRIVILEGES ON DATABASE sejourfr TO sejourfr;"
psql -d sejourfr -c "GRANT ALL ON SCHEMA public TO sejourfr;"
```

### Lancer en dev

```bash
mvn spring-boot:run -Dspring-boot.run.profiles=dev
```

L'app demarre sur `http://localhost:8080`. Flyway charge automatiquement :

- `V1__schema.sql` (toutes les tables)
- `V2__seed_reference.sql` (themes officiels + plans)
- `V3__seed_dev.sql` (admin + utilisateurs + ~15 questions + 2 conversations de test)

### Comptes de test (profil dev)

| Email                  | Mot de passe | Role  |
|------------------------|--------------|-------|
| admin@sejourfr.fr      | Admin123!    | ADMIN |
| user@sejourfr.fr       | User123!     | USER  |
| karim.test@sejourfr.fr | User123!     | USER  |

### Premier appel API

```bash
# 1) Login
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@sejourfr.fr","password":"Admin123!"}'

# 2) Recopier l'accessToken et l'utiliser
curl http://localhost:8080/api/admin/dashboard \
  -H "Authorization: Bearer <ACCESS_TOKEN>"
```

## Profil prod

Variables d'environnement requises :

```
DB_URL=jdbc:postgresql://host:5432/sejourfr
DB_USERNAME=sejourfr
DB_PASSWORD=...
JWT_SECRET=<base64 d'au moins 32 octets>
CORS_ORIGINS=https://app.sejourfr.fr
STORAGE_PUBLIC_BASE_URL=https://api.sejourfr.fr/files
STORAGE_LOCAL_ROOT=/var/sejourfr/uploads
```

Lancer :

```bash
java -jar target/sejourfr-backend-0.1.0-SNAPSHOT.jar --spring.profiles.active=prod
```

## Endpoints admin

Tous prefixes par `/api/admin/**`, requiert un JWT avec role ADMIN.

- `GET /dashboard` - KPIs
- `GET/POST/PUT/DELETE /questions` + `PATCH /questions/{id}/status`
- `GET/POST/PUT/DELETE /themes`
- `POST /media/upload` (multipart) + `POST /media/from-url`
- `GET /conversations`, `POST /conversations/{id}/reply`, etc.

Auth : `POST /api/auth/login`, `POST /api/auth/refresh`, `GET /api/auth/me`.

Fichiers uploades servis sur `/files/{key}`.

# Stripe

stripe listen --forward-to http://localhost:8080/api/billing/webhook
