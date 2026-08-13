# ENSPY Server v2.3.0 PRO — Déploiement VPS

Serveur de production de la plateforme ENSPY : API Node.js/Express, PostgreSQL, tableau d'administration web, forum, agenda, notifications, bibliothèque, soumissions étudiantes, publications et gestion des fichiers.

## Installation en une commande

Après avoir publié ce dépôt GitHub public sous `abesskamer237/ENSPY_Server_v2.3.0_PRO` :

```bash
curl -fsSL https://raw.githubusercontent.com/abesskamer237/ENSPY_Server_v2.3.0_PRO/main/install.sh | sudo bash
```

L'installateur installe Docker si nécessaire, clone le dépôt, génère automatiquement `POSTGRES_PASSWORD` et `JWT_SECRET`, initialise PostgreSQL, construit l'API et démarre Nginx + API + PostgreSQL.

Il peut être relancé : le `.env`, la base PostgreSQL et les fichiers téléversés sont conservés.

## Architecture

- Nginx : port 80, tableau admin + reverse proxy `/api/`
- API : Node.js 24 LTS, port interne 8080
- PostgreSQL 16
- Volume `postgres_data` : données de la base
- Volume `uploads_data` : fichiers téléversés
- Migrations : `api/migrations/`

Node.js 24 est utilisé volontairement comme branche LTS de production. Node.js 26 est actuellement la branche Current ; la documentation officielle recommande pour la production une version Active LTS ou Maintenance LTS.

## Après installation

Ouvrir :

```text
http://IP_DU_VPS/
```

Vérifier :

```bash
curl http://127.0.0.1/api/healthz
docker compose ps
```

Compte administrateur initial :

```text
Email    : admin@enspy.cm
Password : admin123
```

**Changer immédiatement le mot de passe après la première connexion.**

## HTTPS

Pour une utilisation réelle avec l'application Android, configurez un nom de domaine et HTTPS avant de mettre l'URL publique dans l'application. Le port 8080 n'a pas besoin d'être exposé : Android passe par Nginx via `/api/`.

## Mise à jour

Depuis le VPS :

```bash
cd /opt/enspy
git pull --ff-only
docker compose build --pull api
docker compose up -d
```

Ne supprimez pas les volumes `postgres_data` ou `uploads_data` lors d'une mise à jour.

## Dépannage

```bash
cd /opt/enspy
docker compose ps
docker compose logs --tail=150 api
docker compose logs --tail=150 db-init
docker compose logs --tail=150 nginx
```

Le fichier `.env` est généré localement et ne doit jamais être publié sur GitHub.


## Déploiement automatique v2.3.0 FIXED VPS

L'installateur est conçu pour prendre possession d'un VPS neuf ou déjà utilisé.

- Détecte et arrête/désactive Nginx, Apache, Caddy, Lighttpd et autres conflits sur les ports 80/443.
- Arrête/supprime les conteneurs Docker qui publient 80/443 lorsqu'ils empêchent ENSPY de démarrer.
- Ne supprime jamais les volumes Docker ENSPY (`postgres_data`, `uploads_data`, `redis_data`) pendant une installation/mise à jour.
- Crée/emploie le réseau Docker externe `enspy_network`, ce qui évite les problèmes de résolution `api`.
- Attend PostgreSQL `healthy`, exécute toutes les migrations existantes, attend l'API `healthy`, puis teste `/api/healthz` à travers Nginx.
- Détecte automatiquement l'IPv4 publique.
- Tente automatiquement d'obtenir un certificat Let's Encrypt pour l'IP publique avec le profil `shortlived`.
- Les certificats IP Let's Encrypt sont volontairement courts (environ 160 heures) ; un timer systemd les renouvelle automatiquement deux fois par jour.
- Si l'autorité de certification ne peut pas valider l'IP (NAT, pare-feu externe, IP non publique, etc.), l'installation conserve HTTP fonctionnel au lieu de casser le serveur.
- L'application Android v2.3.0-patch22 conserve son mécanisme existant `API_BASE_URL` et son URL API configurable ; en production, utiliser l'URL HTTPS affichée par l'installateur lorsque le certificat IP est actif.

### Mode non destructif

Pour ne pas arrêter les services concurrents des ports 80/443 :

```bash
ENSPY_FORCE_PORTS=0 curl -fsSL https://raw.githubusercontent.com/abesskamer237/ENSPY_Server_v2.3.0_PRO/main/install.sh | sudo -E bash
```

Par défaut, `ENSPY_FORCE_PORTS=1` est utilisé comme demandé pour un déploiement qui prend possession des ports web.

### Certificat IP

Let's Encrypt rend désormais les certificats IP publiquement disponibles. Ils sont des certificats courts et nécessitent une validation ACME compatible ; l'installateur utilise Certbot 5.7 et le profil `shortlived`.

## Supervision en direct

Le centre d'administration affiche maintenant un panneau **Activité serveur — EN DIRECT**. Il interroge périodiquement `/api/admin/activity` et affiche avec une animation les nouvelles :

- soumissions étudiantes ;
- publications de documents ;
- annonces/notifications ;
- discussions du forum ;
- événements de l'agenda.

Lorsqu'une nouvelle activité arrive, elle apparaît en tête avec une animation et un indicateur **NOUVEAU**. Le panneau ne remplace aucune page existante et disparaît du fonctionnement normal si l'administrateur n'est pas connecté.

## Fiabilité des fichiers téléversés

Le conteneur API démarre désormais avec un petit entrypoint root qui prépare `/app/uploads` et `/app/logs`, corrige les permissions du volume persistant puis lance Node sous l'utilisateur non privilégié `node`. Cela évite le problème classique où un volume Docker nouvellement créé masque les permissions préparées pendant le build et provoque `EACCES` sur `/app/uploads`.

L'healthcheck Docker utilise `/api/readyz` afin de vérifier la base PostgreSQL **et** le stockage des uploads avant de considérer l'API prête.
