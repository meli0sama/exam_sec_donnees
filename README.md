# Examen Final — Sécurité des Données
## Évaluation de sécurité de NodeGoat — Pipeline CI/CD avec Jenkins & Bearer CLI

## 1. Présentation du projet

Ce dépôt contient l'évaluation de sécurité de l'application **OWASP NodeGoat**, réalisée dans le cadre de l'examen final du module Sécurité des Données. Le projet met en place un pipeline CI/CD automatisé qui analyse le code source à chaque `git push` et notifie les résultats par e-mail.

## 2. Structure du dépôt

```
project/
├── NodeGoat/              # Code source de l'application analysée (OWASP NodeGoat)
├── Jenkinsfile            # Pipeline CI/CD (Checkout → Scan Bearer → Archive → Notification)
├── Dockerfile              # Image Jenkins personnalisée (Jenkins LTS + Bearer CLI)
├── docker-compose.yml     # Démarrage de NodeGoat + MongoDB en local
├── reports/               # Rapports générés par les scans (Bearer HTML/JSON)
├── screenshots/           # Captures d'écran de la configuration et des résultats
├── security-config/       # Scripts additionnels de génération de rapport
└── remediation/           # Preuves des corrections appliquées (avant/après)
```

## 3. Comment exécuter le projet

### 3.1 Prérequis
- Docker installé et démarré
- Un compte GitHub avec un dépôt configuré (webhook + credentials)
- Un compte ngrok (pour exposer Jenkins en local)
- Un compte email avec un mot de passe d'application (pour les notifications SMTP)

### 3.2 Lancer l'application NodeGoat en local

```bash
cd NodeGoat
docker compose up -d --build
```

L'application est accessible sur : **http://localhost:4000**

### 3.3 Construire et lancer l'image Jenkins personnalisée

```bash
docker build --no-cache -t jenkins-bearer-nodegoat:latest .

docker run -d --name jenkins2 \
  --restart unless-stopped \
  -p 8080:8080 -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  jenkins-bearer-nodegoat:latest
```

Jenkins est accessible sur : **http://localhost:8080**

Récupère le mot de passe administrateur initial si besoin :
```bash
docker exec -it jenkins2 cat /var/jenkins_home/secrets/initialAdminPassword
```

### 3.4 Exposer Jenkins avec ngrok (pour recevoir le webhook GitHub)

```bash
docker run -d --restart unless-stopped --net=host \
  -e NGROK_AUTHTOKEN=<TON_TOKEN> \
  ngrok/ngrok:latest http --url=<ton-sous-domaine>.ngrok-free.dev 8080
```

## 4. Comment lancer les analyses

### 4.1 Automatiquement (recommandé)
Chaque `git push` sur la branche `main` déclenche automatiquement le pipeline Jenkins via le webhook GitHub configuré sur l'URL ngrok. Aucune action manuelle n'est nécessaire.

### 4.2 Manuellement
Depuis l'interface Jenkins → sélectionner le job → cliquer sur **"Build Now"**.

### 4.3 Consulter les résultats
- Dans Jenkins : ouvrir le build → **"Voir les empreintes numériques"** ou l'onglet artefacts pour télécharger `bearer-report.html` / `bearer-report.json`.
- Par e-mail : chaque build termine par l'envoi automatique du rapport HTML en pièce jointe.

## 5. Outils utilisés

| Outil | Type d'analyse | Ce qu'il détecte | Limites |
|---|---|---|---|
| **Bearer CLI** | SAST + Secret Detection | Injections (SQL/NoSQL), XSS, secrets codés en dur, mauvaise gestion des données sensibles, violations OWASP Top 10 / CWE | Analyse uniquement le code statique — ne détecte pas les vulnérabilités qui n'apparaissent qu'à l'exécution (ex: mauvaise configuration serveur, comportement runtime) |
| **Jenkins** | Orchestration CI/CD | Automatisation du scan à chaque push, archivage des rapports, notification | Nécessite une configuration correcte des credentials et du webhook pour fonctionner de bout en bout |
| **ngrok** | Exposition réseau | Permet à GitHub (externe) d'atteindre Jenkins (local) | Le tunnel doit rester actif ; plan gratuit limité à une session à la fois |

**Remarque** : des tests complémentaires avec OWASP ZAP (DAST) et npm audit (SCA) ont été réalisés manuellement en local durant le développement, mais n'ont pas été intégrés au pipeline automatisé — voir la section "Analyse critique" du rapport PDF pour la justification.

## 6. Auteur

Mouhamed Cissoko — L3 Cybersécurité
