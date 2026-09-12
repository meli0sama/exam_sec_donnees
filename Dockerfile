FROM jenkins/jenkins:lts
USER root

# git : nécessaire à Jenkins et à Bearer pour analyser l'historique
# curl : pour télécharger le script d'installation de Bearer
# ca-certificates, gnupg, lsb-release : prérequis pour installer Docker CLI proprement
RUN apt-get update && apt-get install -y \
    git curl ca-certificates gnupg lsb-release python3 \
    && rm -rf /var/lib/apt/lists/*

# Installation de Bearer CLI (outil SAST + détection de secrets)
RUN curl -sfL https://raw.githubusercontent.com/Bearer/bearer/main/contrib/install.sh \
    | sh -s -- -b /usr/local/bin

# Installation du Docker CLI (pour piloter docker compose depuis le pipeline
# via le socket Docker de l'hôte monté dans le conteneur Jenkins)
RUN curl -fsSL https://get.docker.com | sh

# Installation explicite du plugin docker compose v2 (évite l'erreur
# "docker-compose: not found" rencontrée quand seule l'image de base est utilisée)
RUN mkdir -p /usr/local/lib/docker/cli-plugins && \
    curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 \
    -o /usr/local/lib/docker/cli-plugins/docker-compose && \
    chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

USER jenkins