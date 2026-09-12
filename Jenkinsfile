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
                    url: 'https://github.com/meli0sama/juice-shop-sec.git',
                    credentialsId: 'identifiants-github'
            }
        }

        stage('Build / Preparation') {
            steps {
                sh '''
                    mkdir -p reports
                    docker-compose up -d --build
                    sleep 20
                    echo "✅ Application démarrée"
                '''
            }
        }

        stage('SAST + Secret Detection — Bearer CLI') {
            steps {
                sh '''
                    bearer scan . \
                        --scanner=sast,secrets \
                        --format html \
                        --output reports/bearer-report.html \
                        --exit-code 0

                    bearer scan . \
                        --scanner=sast,secrets \
                        --format json \
                        --output reports/bearer-report.json \
                        --exit-code 0
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
                        echo "<html><body><h1>Rapport de sécurité</h1><p>Voir reports/ pour le détail (Bearer, npm audit, ZAP, Gitleaks).</p></body></html>" > reports/security-report.html
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
            sh 'docker-compose down || true'

            emailext (
                subject: "🔒 Rapport Sécurité — Build #${env.BUILD_NUMBER} — ${currentBuild.currentResult}",
                body: """
<html>
<body style="font-family: Arial, sans-serif; color: #333;">

<div style="background: #1a1a2e; color: white; padding: 20px; border-radius: 8px; margin-bottom: 20px;">
    <h2 style="margin:0;">🔒 Rapport de Sécurité</h2>
    <p style="margin:8px 0 0; opacity:0.8;">Pipeline CI/CD Jenkins — Analyse automatisée</p>
</div>

<table style="width:100%; border-collapse:collapse; margin-bottom:20px;">
    <tr>
        <td style="padding:10px; background:#f8f9fa; border-radius:6px; width:50%;">
            <strong>📌 Job :</strong> ${env.JOB_NAME}<br>
            <strong>🔢 Build :</strong> #${env.BUILD_NUMBER}<br>
            <strong>📅 Date :</strong> ${new Date().format('dd/MM/yyyy HH:mm')}
        </td>
        <td style="padding:10px; text-align:center; width:50%;">
            <div style="display:inline-block; padding:12px 24px; border-radius:8px;
                background:${currentBuild.currentResult == 'SUCCESS' ? '#d4edda' : '#fce8ea'};
                color:${currentBuild.currentResult == 'SUCCESS' ? '#155724' : '#721c24'};
                font-size:18px; font-weight:bold;">
                ${currentBuild.currentResult == 'SUCCESS' ? '✅ BUILD SUCCESS' : '❌ BUILD FAILURE'}
            </div>
        </td>
    </tr>
</table>

<h3>📊 Outils exécutés</h3>
<table style="width:100%; border-collapse:collapse;">
    <tr style="background:#f8f9fa;">
        <th style="padding:10px; text-align:left; border-bottom:2px solid #dee2e6;">Outil</th>
        <th style="padding:10px; text-align:left; border-bottom:2px solid #dee2e6;">Type</th>
        <th style="padding:10px; text-align:left; border-bottom:2px solid #dee2e6;">Rapport</th>
    </tr>
    <tr>
        <td style="padding:10px; border-bottom:1px solid #dee2e6;">Bearer CLI</td>
        <td style="padding:10px; border-bottom:1px solid #dee2e6;">SAST + Secrets</td>
        <td style="padding:10px; border-bottom:1px solid #dee2e6;">bearer-report.html (en pièce jointe)</td>
    </tr>
    <tr style="background:#f8f9fa;">
        <td style="padding:10px; border-bottom:1px solid #dee2e6;">npm audit</td>
        <td style="padding:10px; border-bottom:1px solid #dee2e6;">SCA</td>
        <td style="padding:10px; border-bottom:1px solid #dee2e6;">npm-audit.json</td>
    </tr>
    <tr>
        <td style="padding:10px; border-bottom:1px solid #dee2e6;">OWASP ZAP</td>
        <td style="padding:10px; border-bottom:1px solid #dee2e6;">DAST</td>
        <td style="padding:10px; border-bottom:1px solid #dee2e6;">zap-report.html</td>
    </tr>
    <tr style="background:#f8f9fa;">
        <td style="padding:10px;">Gitleaks</td>
        <td style="padding:10px;">Secret Detection</td>
        <td style="padding:10px;">gitleaks-report.json</td>
    </tr>
</table>

<br>
<p>
    🔗 <a href="${env.BUILD_URL}">Voir le build complet dans Jenkins</a> &nbsp;|&nbsp;
    🔗 <a href="${env.BUILD_URL}artifact/reports/security-report.html">Rapport de sécurité consolidé</a>
</p>

<p style="color:#666; font-size:12px; margin-top:20px;">
    Rapport généré automatiquement — Examen Sécurité des Données L3 Cybersécurité
</p>

</body>
</html>
                """,
                mimeType: 'text/html',
                to: 'mouhamedcissoko03@gmail.com',
                attachmentsPattern: 'reports/bearer-report.html'
            )
        }
    }
}
