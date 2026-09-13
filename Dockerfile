FROM jenkins/jenkins:lts
USER root

RUN apt-get update && apt-get install -y git curl \
    && rm -rf /var/lib/apt/lists/*

RUN curl -sfL https://raw.githubusercontent.com/Bearer/bearer/main/contrib/install.sh \
    | sh -s -- -b /usr/local/bin

USER jenkins
