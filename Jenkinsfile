pipeline {
    agent any

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

        stage('Bearer Scan') {
            steps {
                sh '''
                    bearer scan . --scanner=sast,secrets --format html \
                        --output bearer-report.html --exit-code 0

                    bearer scan . --scanner=sast,secrets --format json \
                        --output bearer-report.json --exit-code 0
                '''
            }
        }

        stage('Archive Report') {
            steps {
                archiveArtifacts artifacts: 'bearer-report.html, bearer-report.json', fingerprint: true
            }
        }
    }

    post {
        always {
            emailext (
                subject: "Rapport de scan Bearer - ${env.JOB_NAME} - Build #${env.BUILD_NUMBER}",
                body: '''Le scan de sécurité Bearer CLI est terminé.
Voir le rapport en pièce jointe.

Statut du build : ${BUILD_STATUS}
Détails : https://nearby-surfacing-dizziness.ngrok-free.dev/job/exam_sec_données/${BUILD_NUMBER}/''',
                to: 'mouhamedcissoko03@gmail.com',
                attachmentsPattern: 'bearer-report.html'
            )
        }
    }
}
