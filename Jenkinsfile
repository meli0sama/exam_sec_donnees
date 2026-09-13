pipeline {
    agent any

    options {
        disableConcurrentBuilds()
        timestamps()
    }

    triggers {
        githubPush()
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

                    cd NodeGoat
                    if [ ! -f package-lock.json ]; then
                        echo "⚠️ package-lock.json absent — génération avant audit"
                        npm install --package-lock-only
                    fi
                '''
                echo "✅ Préparation terminée"
            }
        }

        stage('Security Analysis') {
            // Contrôle 1 : SAST + Secret Detection (Bearer CLI)
            steps {
                sh '''
                    bearer scan ./NodeGoat --scanner=sast,secrets --format html \
                        --output reports/bearer-report.html --exit-code 0

                    bearer scan ./NodeGoat --scanner=sast,secrets --format json \
                        --output reports/bearer-report.json --exit-code 0
                '''
            }
        }

        stage('Additional Security Check') {
            // Contrôle 2 : SCA (analyse des dépendances) via npm audit
            steps {
                sh '''
                    cd NodeGoat
                    npm audit --json > ../reports/npm-audit.json || true
                '''
            }
        }

        stage('Report Generation') {
            steps {
                sh '''
                    if [ -f security-config/generate-report.sh ]; then
                        bash security-config/generate-report.sh
                    else
                        echo "<html><body><h1>Rapport de sécurité NodeGoat</h1><p>Voir reports/ (Bearer SAST+Secrets, npm audit SCA)</p></body></html>" > reports/security-report.html
                    fi
                '''
                archiveArtifacts artifacts: 'reports/**/*', fingerprint: true
                echo "✅ Rapports archivés dans Jenkins"
            }
        }

        stage('Notification') {
            steps {
                echo "Pipeline terminé — notification envoyée par e-mail (voir post-actions)"
            }
        }
    }

    post {
        always {
            emailext (
                subject: "🔒 Rapport Sécurité NodeGoat — Build #${env.BUILD_NUMBER} — ${currentBuild.currentResult}",
                body: """
Le scan de sécurité (Bearer CLI - SAST/Secrets, npm audit - SCA) sur NodeGoat est terminé.

Statut du build : ${currentBuild.currentResult}
Job : ${env.JOB_NAME} — Build #${env.BUILD_NUMBER}
Détails : https://nearby-surfacing-dizziness.ngrok-free.dev/${BUILD.NUMBER}

Voir les rapports en pièce jointe / archives Jenkins.
""",
                to: 'mouhamedcissoko03@gmail.com',
                attachmentsPattern: 'reports/bearer-report.html'
            )
        }
    }
}
