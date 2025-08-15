pipeline {
  agent any

  environment {
    APP_NAME = 'demo'
    IMAGE_TAG = "demo:${env.BUILD_NUMBER}"
    M2_CACHE_VOL = 'm2'  // кеш Maven-репозитория
  }

  options { timestamps() }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Build & Test (Maven in Docker)') {
      steps {
        sh '''
          docker run --rm \
            -v "$PWD":/app -w /app \
            -v ${M2_CACHE_VOL}:/root/.m2 \
            maven:3.9-eclipse-temurin-17 \
            mvn -B -ntp -DskipTests=false clean test package
        '''
      }
      post {
        always {
          junit 'target/surefire-reports/*.xml'
          archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
        }
      }
    }

    stage('Build Docker Image') {
      steps {
        sh "docker build -t ${IMAGE_TAG} ."
      }
    }

    stage('Run Container (Smoke)) {
      steps {
        sh "docker run -d --rm --name ${APP_NAME}-smoke -p 18080:8080 ${IMAGE_TAG}"
        sh "sleep 5 && curl -fsS http://localhost:18080/ | tee smoke.out"
      }
      post {
        always {
          sh "docker rm -f ${APP_NAME}-smoke || true"
        }
      }
    }
  }

  post {
    success { echo "✅ Build ${env.BUILD_NUMBER} OK" }
    failure { echo "❌ Build ${env.BUILD_NUMBER} failed" }
  }
}
