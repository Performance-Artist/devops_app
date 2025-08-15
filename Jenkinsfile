pipeline {
  agent any
  environment {
    APP_NAME = 'demo'
    IMAGE_TAG = "demo:${env.BUILD_NUMBER}"
    M2_CACHE_VOL = 'm2'
  }
  options { timestamps() }
  stages {
    stage('Checkout') { steps { checkout scm } }

    stage('Build & Test (Maven in Docker)') {
      steps {
        sh '''
          set -e
          echo "WORKSPACE=$WORKSPACE"
          ls -la "$WORKSPACE"

          # Чистим/готовим локальный target чтобы junit/artifacts потом нашли файлы
          rm -rf "$WORKSPACE/target" || true
          mkdir -p "$WORKSPACE/target"

          # Если остался старый контейнер — удалим
          docker rm -f maven-build || true

          # Передаём содержимое WORKSPACE внутрь контейнера через stdin (tar),
          # собираем, а затем копируем готовый target/ обратно
          tar -C "$WORKSPACE" -cf - . | docker run --name maven-build -i \
            -v m2:/root/.m2 \
            maven:3.9-eclipse-temurin-17 \
            sh -lic 'set -e; mkdir -p /app && cd /app && tar -xf - && mvn -B -ntp -DskipTests=false clean test package && ls -la target'

          # Копируем артефакты из контейнера в рабочую директорию Jenkins
          docker cp maven-build:/app/target "$WORKSPACE/"

          # Чистим контейнер
          docker rm -f maven-build || true

          ls -la "$WORKSPACE/target"
        '''
      }
      post {
        always {
          junit allowEmptyResults: false, testResults: 'target/surefire-reports/*.xml'
          archiveArtifacts artifacts: 'target/*.jar', fingerprint: true, onlyIfSuccessful: true
        }
      }
    }

    stage('Build Docker Image') {
      steps { sh "docker build -t ${IMAGE_TAG} ." }
    }

    stage('Run Container (Smoke)') {
      steps {
        sh "docker run -d --rm --name ${APP_NAME}-smoke -p 18080:8080 ${IMAGE_TAG}"
        sh "sleep 5 && (curl -fsS http://localhost:18080/ || wget -qO- http://localhost:18080/) | tee smoke.out"
      }
      post { always { sh "docker rm -f ${APP_NAME}-smoke || true" } }
    }
  }
  post {
    success { echo "✅ Build ${env.BUILD_NUMBER} OK" }
    failure { echo "❌ Build ${env.BUILD_NUMBER} failed" }
  }
}

