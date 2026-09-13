FROM jenkins/jenkins:lts
USER root

RUN apt-get update && apt-get install -y git curl \
    && rm -rf /var/lib/apt/lists/*

RUN curl -sfL https://raw.githubusercontent.com/Bearer/bearer/main/contrib/install.sh \
    | sh -s -- -b /usr/local/bin

# Node.js + npm, installés nativement (pas de docker-in-docker), pour npm audit (SCA)
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

USER jenkins
