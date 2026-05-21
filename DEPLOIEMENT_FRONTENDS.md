# Déploiement frontends SejourFR — Mémo condensé

> Deux frontends, deux stratégies. Ce document récapitule où vit chaque chose
> et comment déployer une nouvelle version.

---

## 1. Vue d'ensemble

| Frontend       | URL                         | Stack                 | Mode                        | Process                            |
|----------------|-----------------------------|-----------------------|-----------------------------|------------------------------------|
| **Admin**      | `https://admin.sejourfr.fr` | React 19 + Vite + TS  | Statique (build → fichiers) | Nginx sert les fichiers            |
| **Web public** | `https://sejourfr.fr`       | Next.js 16 + React 19 | SSR / SSG / ISR             | systemd `sejourfr-web` (port 3000) |

**Pourquoi cette différence ?**

- Admin = audience interne → pas besoin de SEO → statique suffit (plus rapide, zéro process)
- Web public = besoin de SEO + ISR sur le blog → Next.js avec rendu serveur

---

## 2. Cartographie des fichiers

### 2.1. Admin

| Quoi                         | Chemin                                                                 | Propriétaire        |
|------------------------------|------------------------------------------------------------------------|---------------------|
| Fichiers servis              | `/var/www/admin.sejourfr.fr/html/`                                     | `www-data:www-data` |
| Config Nginx                 | bloc `admin.sejourfr.fr` dans `/etc/nginx/sites-available/sejourfr.fr` | `root:root`         |
| Code source (machine de dev) | `~/admin_sejourfr/`                                                    | `diallomatine`      |
| Repo Git                     | `sejourfr_opus_nouveau` → branche `develop` → `admin_sejourfr/`        | —                   |

### 2.2. Web public (Next.js)

| Quoi                | Chemin                                                           | Propriétaire                     |
|---------------------|------------------------------------------------------------------|----------------------------------|
| Code source serveur | `/opt/sejourfr/repo/web_sejoufr/`                                | `sejourfr:sejourfr`              |
| Config prod         | `/opt/sejourfr/repo/web_sejoufr/.env.production`                 | `sejourfr:sejourfr` (gitignored) |
| Service systemd     | `/etc/systemd/system/sejourfr-web.service`                       | `root:root`                      |
| Logs stdout         | `/opt/sejourfr/logs/web-stdout.log`                              | `sejourfr:sejourfr`              |
| Logs stderr         | `/opt/sejourfr/logs/web-stderr.log`                              | `sejourfr:sejourfr`              |
| Config Nginx        | bloc `sejourfr.fr` dans `/etc/nginx/sites-available/sejourfr.fr` | `root:root`                      |
| Clé SSH GitHub      | `/opt/sejourfr/.ssh/id_ed25519`                                  | `sejourfr:sejourfr` (chmod 600)  |
| Port local          | `3000` (jamais exposé directement)                               | —                                |

---

## 3. Configuration produit clé

### 3.1. Admin — `.env.production` (local)

À la racine du projet `admin_sejourfr` sur ta machine :

```ini
VITE_API_BASE_URL=https://api.sejourfr.fr
```

**Vite injecte cette variable au moment du build.** Toute modification nécessite un rebuild.

### 3.2. Web — `.env.production` (serveur)

Fichier sur le serveur uniquement, jamais commité :

```bash
sudo cat /opt/sejourfr/repo/web_sejoufr/.env.production
```

```ini
NEXT_PUBLIC_API_BASE_URL=https://api.sejourfr.fr
NEXT_PUBLIC_SITE_URL=https://sejourfr.fr
```

**Next.js relit les `NEXT_PUBLIC_*` au build.** Toute modification nécessite un rebuild + restart.

---

## 4. Déploiement — Admin

**Workflow** : build local → upload via rsync → écrasement des fichiers.

```bash
# === Sur ta machine de dev ===
cd ~/admin_sejourfr
npm run build
rsync -avz --delete dist/ root@82.223.165.43:/tmp/admin-build/

# === Sur le serveur ===
sudo rsync -avz --delete /tmp/admin-build/ /var/www/admin.sejourfr.fr/html/
sudo chown -R www-data:www-data /var/www/admin.sejourfr.fr
sudo rm -rf /tmp/admin-build
```

Pas de service à redémarrer. Le déploiement est instantané grâce au `Cache-Control: no-store` sur
`index.html`.

### Diagnostic admin

```bash
# Vérifier que le site répond
curl -I https://admin.sejourfr.fr

# Vérifier le contenu déployé
ls -la /var/www/admin.sejourfr.fr/html/

# Logs Nginx (si erreurs)
sudo tail -f /var/log/nginx/access.log /var/log/nginx/error.log
```

---

## 5. Déploiement — Web public (Next.js)

**Workflow** : push Git → pull serveur → build → restart.

### 5.1. Procédure standard

```bash
# === Sur ta machine de dev ===
cd ~/web_sejoufr
git add .
git commit -m "feat: ma nouvelle fonctionnalité"
git push origin develop

# === Sur le serveur ===
# Pull la nouvelle version
sudo -u sejourfr git -C /opt/sejourfr/repo pull

# Si package.json a changé, réinstaller :
sudo -u sejourfr bash -c "cd /opt/sejourfr/repo/web_sejoufr && npm ci"

# Rebuild
sudo -u sejourfr bash -c "cd /opt/sejourfr/repo/web_sejoufr && npm run build"

# Restart
sudo systemctl restart sejourfr-web

# Vérifier
sudo systemctl status sejourfr-web --no-pager | head -10
curl -I https://sejourfr.fr
```

### 5.2. Gestion du service systemd

```bash
# Démarrer / arrêter / redémarrer
sudo systemctl start sejourfr-web
sudo systemctl stop sejourfr-web
sudo systemctl restart sejourfr-web

# État
sudo systemctl status sejourfr-web

# Activer / désactiver au boot
sudo systemctl enable sejourfr-web
sudo systemctl disable sejourfr-web

# Logs systemd en temps réel
sudo journalctl -u sejourfr-web -f

# 100 dernières lignes
sudo journalctl -u sejourfr-web -n 100 --no-pager

# Logs fichiers bruts
sudo tail -f /opt/sejourfr/logs/web-stdout.log
sudo tail -f /opt/sejourfr/logs/web-stderr.log
```

### 5.3. Diagnostic web

```bash
# Le service répond-il en local ?
curl -I http://localhost:3000

# Sur quel port il écoute (doit être 127.0.0.1:3000) ?
sudo ss -tlnp | grep 3000

# Combien de RAM il consomme ?
sudo systemctl status sejourfr-web | grep Memory

# Accessible publiquement ?
curl -I https://sejourfr.fr
```

---

## 6. Rollback Next.js en cas de problème

Si un déploiement plante après le build :

```bash
# Voir le dernier commit déployé
sudo -u sejourfr git -C /opt/sejourfr/repo log -3 --oneline

# Revenir au commit précédent
sudo -u sejourfr git -C /opt/sejourfr/repo reset --hard HEAD~1

# Rebuild
sudo -u sejourfr bash -c "cd /opt/sejourfr/repo/web_sejoufr && npm run build"

# Restart
sudo systemctl restart sejourfr-web
```

Pour un rollback admin, il faut soit refaire un build d'une ancienne version, soit garder l'ancien `dist/`
localement avant chaque déploiement.

---

## 7. Modifier la config Nginx

```bash
# Sauvegarde avant toute modif
sudo cp /etc/nginx/sites-available/sejourfr.fr /etc/nginx/sites-available/sejourfr.fr.bak-$(date +%Y%m%d)

# Édition
sudo nano /etc/nginx/sites-available/sejourfr.fr

# Test syntaxe (OBLIGATOIRE avant reload)
sudo nginx -t

# Recharger sans coupure
sudo systemctl reload nginx
```

Les backups sont dans `/etc/nginx/sites-available/sejourfr.fr.bak-*`.

---

## 8. Spécificités à connaître

### 8.1. Admin (Vite + React)

- **SPA fallback** : Nginx redirige les routes inconnues vers `index.html` grâce au `try_files`. Le
  `BrowserRouter` peut alors prendre le relais côté client.
- **Cache des assets** : les fichiers `/assets/index-XXXXXXXX.js` ont un hash dans le nom → cache navigateur 1
  an sans risque (un nouveau build = nouveau hash).
- **`index.html`** : `Cache-Control: no-store` → les déploiements sont visibles immédiatement.

### 8.2. Web (Next.js)

- **Repo Git monorepo** : `sejourfr_opus_nouveau` contient `admin_sejourfr/`, `backend_sejourfr/`,
  `mobile_sejourfr/`, `web_sejoufr/`. Le `git pull` met tout à jour, mais on ne build que `web_sejoufr/`.
- **Branche déployée** : `develop`.
- **Deploy Key GitHub** : clé SSH liée au repo (Settings → Deploy keys), lecture seule.
- **Middleware déprécié** : Next.js 16 prévient que `middleware.ts` deviendra `proxy.ts` à terme. Pas bloquant
  pour l'instant.
- **`.env.production`** : sur le serveur uniquement, jamais commité.
- **ISR actif** : la homepage et `/tarifs` revalident toutes les 30 min sans rebuild.

---

## 9. Aide-mémoire ultra-rapide

### Admin

```bash
# Déployer une nouvelle version
cd ~/admin_sejourfr && npm run build && \
  rsync -avz --delete dist/ user@sejourfr.fr:/tmp/admin-build/

# Sur le serveur, finaliser
sudo rsync -avz --delete /tmp/admin-build/ /var/www/admin.sejourfr.fr/html/ && \
  sudo chown -R www-data:www-data /var/www/admin.sejourfr.fr && \
  sudo rm -rf /tmp/admin-build
```

### Web

```bash
# Déployer une nouvelle version (sur le serveur après git push)
sudo -u sejourfr git -C /opt/sejourfr/repo pull && \
  sudo -u sejourfr bash -c "cd /opt/sejourfr/repo/web_sejoufr && npm run build" && \
  sudo systemctl restart sejourfr-web

# Logs en direct
sudo journalctl -u sejourfr-web -f

# Restart rapide
sudo systemctl restart sejourfr-web
```

### Nginx

```bash
sudo nginx -t && sudo systemctl reload nginx
```
