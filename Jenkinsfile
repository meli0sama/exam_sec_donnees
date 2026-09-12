pipeline {
    agent any

    options {
        disableConcurrentBuilds()
        timestamps()
    }

    triggers {
        githubPush()
    }

    environment {
        // ngrok sert UNIQUEMENT à exposer Jenkins (port 8080) pour le webhook GitHub.
        // ZAP tourne en --network host et atteint NodeGoat directement en local.
        APP_URL = "http://localhost:4000"
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/meli0sama/exam_sec_donnees.git',
                    credentialsId: 'identifiants-github'
            }
        }

        stage('Build / Preparation') {
            steps {
                sh '''
                    mkdir -p reports

                    if command -v docker-compose >/dev/null 2>&1; then
                        DC="docker-compose"
                    else
                        DC="docker compose"
                    fi
                    echo "Utilisation de: $DC"

                    # Nettoyage préventif : évite les conflits de noms si un build
                    # précédent n'a pas correctement nettoyé ses conteneurs/réseaux.
                    $DC down --remove-orphans || true
                    docker rm -f nodegoat-mongo nodegoat-app 2>/dev/null || true

                    $DC up -d --build
                    sleep 15
                    echo "✅ NodeGoat démarré"
                '''
            }
        }

        // Les 4 outils sont indépendants entre eux une fois NodeGoat démarré :
        // on les exécute en parallèle pour diviser le temps total par ~3-4.
        stage('Analyses de sécurité (parallèle)') {
            parallel {

                stage('SAST + Secrets — Bearer') {
                    steps {
                        sh '''
                            # .bearerignore exclut node_modules/ (gain de temps majeur)
                            bearer scan . --scanner=sast,secrets --format html \
                                --output reports/bearer-report.html --exit-code 0 --quiet

                            bearer scan . --scanner=sast,secrets --format json \
                                --output reports/bearer-report.json --exit-code 0 --quiet
                        '''
                    }
                }

                stage('SCA — npm audit') {
                    steps {
                        sh '''
                            docker run --rm -v "$(pwd):/app" -w /app node:18 sh -c '
                                if [ ! -f package-lock.json ]; then
                                    npm install --package-lock-only;
                                fi
                                npm audit --json
                            ' > reports/npm-audit.json || true
                        '''
                    }
                }

                stage('DAST — OWASP ZAP') {
                    steps {
                        sh '''
                            chmod 777 reports

                            # -m 2 : borne le spider à 2 minutes max (scan rapide pour CI).
                            # Retire -m pour un scan complet avant ta démo finale si besoin.
                            docker run --rm --network host \
                                -v "$(pwd)/reports:/zap/wrk/:rw" \
                                zaproxy/zap-stable zap-baseline.py \
                                -t $APP_URL \
                                -m 2 \
                                -r zap-report.html || true
                        '''
                    }
                }

                stage('Secret Detection — Gitleaks') {
                    steps {
                        sh '''
                            docker run --rm -v "$(pwd):/repo" \
                                zricethezav/gitleaks:latest detect \
                                --source="/repo" \
                                --report-path=/repo/reports/gitleaks-report.json \
                                --no-git || true
                        '''
                    }
                }
            }
        }

        stage('Report Generation') {
            steps {
                sh '''
                    if [ -f security-config/generate-report.sh ]; then
                        bash security-config/generate-report.sh
                    else
                        echo "<html><body><h1>Rapport de sécurité NodeGoat</h1><p>Voir reports/ (Bearer, npm audit, ZAP, Gitleaks)</p></body></html>" > reports/security-report.html
                    fi
                '''
                archiveArtifacts artifacts: 'reports/**/*', fingerprint: true
                echo " Rapports archivés dans Jenkins"
            }
        }

        stage('Notification') {
            steps {
                echo "Pipeline terminé — notification envoyée"
            }
        }
    }

    post {
        always {
            sh '''
                if command -v docker-compose >/dev/null 2>&1; then
                    docker-compose down || true
                else
                    docker compose down || true
                fi
            '''

            emailext (
                subject: "🔒 Rapport Sécurité NodeGoat — Build #${env.BUILD_NUMBER} — ${currentBuild.currentResult}",
                body: """
Le scan de sécurité (Bearer CLI, npm audit, OWASP ZAP, Gitleaks) sur NodeGoat est terminé.

Statut du build : ${currentBuild.currentResult}
Job : ${env.JOB_NAME} — Build #${env.BUILD_NUMBER}
Détails : ${env.BUILD_URL}

Voir les rapports en pièce jointe / archives Jenkins.
""",
                to: 'mouhamedcissoko03@gmail.com',
                attachmentsPattern: 'reports/bearer-report.html'
            )
        }
    }
}
