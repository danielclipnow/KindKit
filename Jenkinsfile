pipeline {
    agent any
    stages {
        stage('Clone Repository') {
            steps {
                script {
                    git credentialsId: '83759a99-5eb1-4406-8296-e9e4e3bf0594', url: 'git@github.com:danielclipnow/KindKit.git'
                }
            }
        }
        stage('Update with Upstream') {
            steps {
                script {
                    sh 'git remote add upstream https://github.com/KindKit/KindKit.git'
                    sh 'git fetch upstream'
                    sh 'git merge upstream/master'
                    sh 'git push origin HEAD:master'
                }
            }
        }
    }
}