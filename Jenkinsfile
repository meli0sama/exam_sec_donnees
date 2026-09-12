pipeline {
    agent any

    triggers {
        githubPush()
    }

    environment {
        APP_URL = "http://host.docker.internal:4000"
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/<ton-user>/nodegoat-sec.git',
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

                    $DC up -d --build
                    sleep 20
                    echo "✅ NodeGoat démarré"
                '''
            }
        }

        stage('SAST + Secret Detection — Bearer CLI') {
            steps {
                sh '''
                    bearer scan . --scanner=sast,secrets --format html \
                        --output reports/bearer-report.html --exit-code 0

                    bearer scan . --scanner=sast,secrets --format json \
                        --output reports/bearer-report.json --exit-code 0
                '''
            }
        }

        stage('SCA — npm audit') {
            steps {
                sh '''
                    docker run --rm -v "$(pwd):/app" -w /app node:18 \
                        npm audit --json > reports/npm-audit.json || true
                '''
            }
        }

        stage('DAST — OWASP ZAP') {
            steps {
                sh '''
                    docker run --rm --network host \
                        -v "$(pwd)/reports:/zap/wrk/:rw" \
                        zaproxy/zap-stable zap-baseline.py \
                        -t $APP_URL \
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
                echo "✅ Rapports archivés dans Jenkins"
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
