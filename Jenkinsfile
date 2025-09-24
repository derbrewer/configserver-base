pipeline {
    agent {
        kubernetes {
            defaultContainer 'builder'
            yaml """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: builder
    image: pelenor:5000/jenkins-agent:v16
    command: ["cat"]
    tty: true
    securityContext:
      runAsUser: 0
    volumeMounts:
    - name: workspace-volume
      mountPath: /home/jenkins/agent
      readOnly: false
  - name: jnlp
    image: jenkins/inbound-agent:latest
    args: ["\$(JENKINS_SECRET)", "\$(JENKINS_NAME)"]
    env:
    - name: JENKINS_URL
      value: "http://pelenor/jenkins/"
    - name: JENKINS_TUNNEL
      value: "jenkins:50000"
    - name: JENKINS_AGENT_WORKDIR
      value: "/home/jenkins/agent"
    volumeMounts:
    - name: workspace-volume
      mountPath: /home/jenkins/agent
      readOnly: false
  volumes:
  - name: workspace-volume
    emptyDir: {}
  restartPolicy: Never
"""
        }
    }

    environment {
        GIT_CREDENTIALS_ID = '10fcc78e-d54d-4d2a-9bb3-441762173a44'
        REPO_URL = 'https://github.com/derbrewer/configserver-base.git'
        IMAGE_NAME = "pelenor:5000/configserver-base:${BUILD_NUMBER}"
        MODULE_PATH = "."
        SSH_USER = 'mib'
        SSH_HOST = 'pelenor'
    }

    stages {
    stage('SSH Test') {
    steps {
        withCredentials([sshUserPrivateKey(credentialsId: 'pelenor-ssh-key', keyFileVariable: 'SSH_KEY_FILE')]) {
            sh '''
                chmod 600 "$SSH_KEY_FILE"
                ssh -o StrictHostKeyChecking=no -i "$SSH_KEY_FILE" mib@pelenor "echo SSH OK: $(hostname)"
            '''
        }
    }
}

        stage('Checkout') {
            steps {
                container('builder') {
                    git credentialsId: env.GIT_CREDENTIALS_ID,
                        url: env.REPO_URL,
                        branch: 'main'
                }
            }
        }

        stage('Maven Build') {
            steps {
                container('builder') {
                    dir(env.MODULE_PATH) {
                        sh 'mvn clean package -DskipTests'
                    }
                }
            }
        }

        stage('Containerd Image Build & Push') {
            steps {
                container('builder') {
                    dir(env.MODULE_PATH) {
                        sh '''
                            buildah bud -t $IMAGE_NAME .
                            buildah push --tls-verify=false $IMAGE_NAME
                        '''
                    }
                }
            }
        }


        stage('Deploy') {
            steps {
              container('builder') {
             sshagent(['pelenor-ssh-key']) {
                 sh """
                     echo "Deploying build ${BUILD_NUMBER} to pelenor..."

                     # YAML anpassen und in eine Temp-Datei schreiben
                     sed "s|__IMAGE_TAG__|${BUILD_NUMBER}|g" k8s/deploy.yml > /tmp/deploy.yml

                     # Manifest auf Remote-Host kopieren
                     scp -o StrictHostKeyChecking=no /tmp/deploy.yml mib@pelenor:/tmp/deploy.yml

                     # Remote kubectl ausführen (ohne -i)
                     ssh -o StrictHostKeyChecking=no mib@pelenor 'kubectl apply -f /tmp/deploy.yml'

                     echo "Deployment applied."
                 """
             }

              }
}}

    }
}