# Déploiement backend SejourFR — Mémo serveur

./mvnw spring-boot:run

> Ce document récapitule **où se trouve chaque chose** sur le serveur de prod
> pour le backend Spring Boot, avec les commandes utiles pour intervenir.

---

## 1. Vue d'ensemble

```
┌─────────────────────────────────────────────────────────────┐
│  Internet                                                    │
│      ↓                                                       │
│  Nginx (443)  →  api.sejourfr.fr  →  proxy_pass :8080       │
│      ↓                                                       │
│  Backend Spring Boot (systemd service)                       │
│      ↓                                                       │
│  PostgreSQL (localhost:5432)                                 │
└─────────────────────────────────────────────────────────────┘
```

**Utilisateur système qui exécute le backend** : `sejourfr` (créé sans shell de login).

---

## 2. Cartographie des fichiers

| Quoi                       | Chemin                                         | Propriétaire                    |
|----------------------------|------------------------------------------------|---------------------------------|
| Jar de l'application       | `/opt/sejourfr/backend/app.jar`                | `sejourfr:sejourfr`             |
| Config Spring (yaml)       | `/opt/sejourfr/backend/application-prod.yaml`  | `sejourfr:sejourfr`             |
| Variables d'env / secrets  | `/etc/sejourfr/backend.env`                    | `sejourfr:sejourfr` (chmod 600) |
| Service systemd            | `/etc/systemd/system/sejourfr-backend.service` | `root:root`                     |
| Logs stdout                | `/opt/sejourfr/logs/backend-stdout.log`        | `sejourfr:sejourfr`             |
| Logs stderr                | `/opt/sejourfr/logs/backend-stderr.log`        | `sejourfr:sejourfr`             |
| Logs applicatifs (logback) | `/opt/sejourfr/logs/backend.log`               | `sejourfr:sejourfr`             |
| Config Nginx               | `/etc/nginx/sites-available/sejourfr.fr`       | `root:root`                     |
| Sauvegardes Postgres       | `/var/backups/sejourfr/*.sql.gz`               | `root:root`                     |
| Script backup cron         | `/etc/cron.daily/sejourfr-pg-backup`           | `root:root`                     |

---

## 3. Fichiers détaillés

### 3.1. `/opt/sejourfr/backend/app.jar`

Le binaire de l'application. C'est ce qu'on remplace à chaque déploiement.

```bash
# Voir la taille / date
ls -lh /opt/sejourfr/backend/app.jar

./mvnw clean package -DskipTests

# Remplacer (depuis ta machine de dev)
scp target/sejourfr-backend-*.jar root@82.223.165.43:/tmp/sejourfr-backend.jar
ssh root@82.223.165.43
sudo systemctl stop sejourfr-backend
sudo mv /tmp/sejourfr-backend.jar /opt/sejourfr/backend/app.jar
sudo chown sejourfr:sejourfr /opt/sejourfr/backend/app.jar
sudo systemctl daemon-reload
sudo systemctl start sejourfr-backend
sudo tail -f /opt/sejourfr/logs/backend-stdout.log
```

### 3.2. `/opt/sejourfr/backend/application-prod.yaml`

Configuration Spring de production. **Pas de secrets ici** — les valeurs sensibles
sont injectées via le fichier `.env` (voir 3.3).

```bash
sudo -u sejourfr nano /opt/sejourfr/backend/application-prod.yaml
```

Contenu attendu (extrait) :

```yaml
server:
  port: 8080
  forward-headers-strategy: native

spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/sejourfr
    username: sejourfr
    password: ${DB_PASSWORD}
  jpa:
    hibernate:
      ddl-auto: validate
    open-in-view: false
  flyway:
    enabled: true
    baseline-on-migrate: false
  mail:
    host: ${MAIL_HOST}
    port: ${MAIL_PORT:587}
    username: ${MAIL_USER}
    password: ${MAIL_PASSWORD}

app:
  jwt:
    secret: ${JWT_SECRET}
    expiration-ms: 86400000
  cors:
    allowed-origins: https://sejourfr.fr,https://www.sejourfr.fr,https://admin.sejourfr.fr

logging:
  file:
    name: /opt/sejourfr/logs/backend.log
```

Après modification, redémarrer le service (voir §4).

### 3.3. `/etc/sejourfr/backend.env` — **Les secrets**

Le fichier le plus sensible du serveur. Permissions `600`, jamais commité.

```bash
sudo nano /etc/sejourfr/backend.env
```

Contenu :

```ini
SPRING_PROFILES_ACTIVE=prod
SPRING_CONFIG_LOCATION=optional:file:/opt/sejourfr/backend/application-prod.yaml

DB_PASSWORD=xxxxxxxxxxxxxxxxxx
JWT_SECRET=xxxxxxxxxxxxxxxxxx_64_chars_min
MAIL_HOST=smtp.example.com
MAIL_PORT=587
MAIL_USER=noreply@sejourfr.fr
MAIL_PASSWORD=xxxxxxxxxxxxxxxxxx
```

**Générer un JWT_SECRET solide** :

```bash
openssl rand -base64 64 | tr -d '\n'
```

**Vérifier les permissions** (doit être `-rw-------`) :

```bash
ls -l /etc/sejourfr/backend.env
# Si pas bon :
sudo chmod 600 /etc/sejourfr/backend.env
sudo chown sejourfr:sejourfr /etc/sejourfr/backend.env
```

### 3.4. `/etc/systemd/system/sejourfr-backend.service`

Définition du service systemd. Modifier ce fichier nécessite un `daemon-reload`.

```bash
sudo nano /etc/systemd/system/sejourfr-backend.service
sudo systemctl daemon-reload
sudo systemctl restart sejourfr-backend
```

Contenu :

```ini
[Unit]
Description=SejourFR Backend (Spring Boot)
After=network.target postgresql.service
Requires=postgresql.service

[Service]
Type=simple
User=sejourfr
Group=sejourfr
WorkingDirectory=/opt/sejourfr/backend
EnvironmentFile=/etc/sejourfr/backend.env
ExecStart=/usr/bin/java -Xms256m -Xmx768m -jar /opt/sejourfr/backend/app.jar
SuccessExitStatus=143
Restart=on-failure
RestartSec=10
StandardOutput=append:/opt/sejourfr/logs/backend-stdout.log
StandardError=append:/opt/sejourfr/logs/backend-stderr.log

NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=full
ProtectHome=true

[Install]
WantedBy=multi-user.target
```

### 3.5. `/etc/nginx/sites-available/sejourfr.fr`

Reverse proxy. Le bloc concerné par le backend est celui de `api.sejourfr.fr`.

```bash
sudo nano /etc/nginx/sites-available/sejourfr.fr

# Tester la config avant de reload
sudo nginx -t

# Recharger sans coupure
sudo systemctl reload nginx
```

---

## 4. Commandes de gestion du service

### 4.1. Cycle de vie

```bash
# Démarrer
sudo systemctl start sejourfr-backend

# Arrêter
sudo systemctl stop sejourfr-backend

# Redémarrer (après MAJ du jar ou de la config)
sudo systemctl restart sejourfr-backend

# Statut (PID, mémoire, dernières lignes de log)
sudo systemctl status sejourfr-backend

# Activer au boot
sudo systemctl enable sejourfr-backend

# Désactiver au boot
sudo systemctl disable sejourfr-backend
```

### 4.2. Logs

```bash
# Logs systemd en temps réel (le plus utile)
sudo journalctl -u sejourfr-backend -f

# 200 dernières lignes
sudo journalctl -u sejourfr-backend -n 200 --no-pager

# Logs depuis ce matin
sudo journalctl -u sejourfr-backend --since today

# Logs entre deux dates
sudo journalctl -u sejourfr-backend --since "2026-05-20 09:00" --until "2026-05-20 10:00"

# Logs applicatifs (logback)
sudo tail -f /opt/sejourfr/logs/backend.log

# Logs stdout / stderr bruts
sudo tail -f /opt/sejourfr/logs/backend-stdout.log
sudo tail -f /opt/sejourfr/logs/backend-stderr.log

# Filtrer les erreurs
sudo grep -i "error\|exception" /opt/sejourfr/logs/backend.log | tail -50
```

### 4.3. Diagnostic rapide

```bash
# Le backend répond-il ?
curl http://localhost:8080/actuator/health

# Accessible via Nginx ?
curl https://api.sejourfr.fr/actuator/health

# Le port 8080 est-il bien ouvert localement (et SEULEMENT localement) ?
sudo ss -tlnp | grep 8080

# Le processus tourne-t-il ?
ps aux | grep app.jar

# Combien de mémoire consomme-t-il ?
sudo systemctl status sejourfr-backend | grep Memory
```

---

## 5. Base de données PostgreSQL

| Quoi         | Valeur                                           |
|--------------|--------------------------------------------------|
| Hôte         | `localhost`                                      |
| Port         | `5432`                                           |
| Base         | `sejourfr`                                       |
| User         | `sejourfr`                                       |
| Mot de passe | dans `/etc/sejourfr/backend.env` (`DB_PASSWORD`) |

### 5.1. Se connecter

```bash
# En tant qu'utilisateur applicatif (depuis le serveur)
psql -h localhost -U sejourfr -d sejourfr

# En tant que superuser (sans mot de passe via socket)
sudo -u postgres psql sejourfr
```

### 5.2. Commandes utiles dans psql

```sql
\dt                       -- liste les tables
\
d questions              -- structure d'une table
\dn                       -- liste les schémas
SELECT *
FROM flyway_schema_history
ORDER BY installed_rank DESC LIMIT 10;
\q                        -- quitter
```

### 5.3. Sauvegardes

```bash
# Backup manuel ponctuel
sudo -u postgres pg_dump sejourfr | gzip > ~/sejourfr-manuel-$(date +%Y%m%d).sql.gz

# Lister les backups automatiques
ls -lh /var/backups/sejourfr/

# Restaurer (ATTENTION : écrase la base)
gunzip -c /var/backups/sejourfr/sejourfr-20260520-030000.sql.gz | sudo -u postgres psql sejourfr

# Tester que le cron tourne
sudo run-parts --test /etc/cron.daily
```

---

## 6. Procédure de mise à jour standard

```bash
# === Sur ta machine de dev ===
cd /chemin/vers/sejourfr-backend
./mvnw clean package -DskipTests
scp target/sejourfr-backend-*.jar root@82.223.165.43:/tmp/sejourfr-backend.jar

# === Sur le serveur ===
ssh user@sejourfr.fr

# Backup du jar actuel (au cas où)
sudo cp /opt/sejourfr/backend/app.jar /opt/sejourfr/backend/app.jar.bak

# Backup base de données (Flyway va appliquer les nouvelles migrations)
sudo -u postgres pg_dump sejourfr | gzip > /var/backups/sejourfr/avant-deploy-$(date +%Y%m%d-%H%M).sql.gz

# Remplacer le jar
sudo systemctl stop sejourfr-backend
sudo mv /tmp/sejourfr-backend.jar /opt/sejourfr/backend/app.jar
sudo chown sejourfr:sejourfr /opt/sejourfr/backend/app.jar
sudo systemctl start sejourfr-backend

# Vérifier
sudo journalctl -u sejourfr-backend -f
# (Ctrl+C une fois "Started SejourFR Backend" affiché)

curl https://api.sejourfr.fr/actuator/health
```

### 6.1. Rollback en cas de problème

```bash
sudo systemctl stop sejourfr-backend
sudo mv /opt/sejourfr/backend/app.jar.bak /opt/sejourfr/backend/app.jar
sudo systemctl start sejourfr-backend

# Si une migration Flyway a posé problème : restaurer la base
gunzip -c /var/backups/sejourfr/avant-deploy-XXX.sql.gz | sudo -u postgres psql sejourfr
```

---

## 7. Modifier un secret (ex: rotation JWT, MDP mail)

```bash
# 1. Éditer le fichier .env
sudo nano /etc/sejourfr/backend.env

# 2. Redémarrer le service (la conf systemd recharge le EnvironmentFile)
sudo systemctl restart sejourfr-backend

# 3. Vérifier que le service est UP
sudo systemctl status sejourfr-backend
curl http://localhost:8080/actuator/health
```

⚠️ Rotation du `JWT_SECRET` = invalidation de **tous** les JWT existants.
Tous les utilisateurs devront se reconnecter.

---

## 8. Modifier un paramètre Spring (non-secret)

```bash
# 1. Éditer le yaml
sudo -u sejourfr nano /opt/sejourfr/backend/application-prod.yaml

# 2. Redémarrer
sudo systemctl restart sejourfr-backend
```

---

## 9. Checklist de santé hebdomadaire

```bash
# Service UP ?
sudo systemctl is-active sejourfr-backend

# Espace disque OK ?
df -h /

# Taille des logs (à truncate si trop gros)
sudo du -sh /opt/sejourfr/logs/

# Backups récents ?
ls -lh /var/backups/sejourfr/ | tail -5

# Certificats SSL OK ?
sudo certbot certificates

# Erreurs récentes ?
sudo journalctl -u sejourfr-backend --since "1 week ago" | grep -i "error\|exception" | wc -l
```

---

## 10. Rotation des logs

Spring Boot tourne tout dans `/opt/sejourfr/logs/`. Pour éviter que ça gonfle :

```bash
sudo nano /etc/logrotate.d/sejourfr
```

```
/opt/sejourfr/logs/*.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    copytruncate
    su sejourfr sejourfr
}
```

Tester :

```bash
sudo logrotate -d /etc/logrotate.d/sejourfr   # dry-run
sudo logrotate -f /etc/logrotate.d/sejourfr   # force exécution
```

---

## 11. Aide-mémoire ultra-rapide

```bash
# Restart backend
sudo systemctl restart sejourfr-backend

# Logs live
sudo journalctl -u sejourfr-backend -f

# Health check
curl https://api.sejourfr.fr/actuator/health

# Connexion DB
psql -h localhost -U sejourfr -d sejourfr

# Reload Nginx
sudo nginx -t && sudo systemctl reload nginx
```
