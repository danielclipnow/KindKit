pipeline {
    agent any
    stages {
        stage('Git Fork Update ') {
            steps{
                sh 'git remote add upstream git@github.com:KindKit/KindKit.git'
                sh 'git fetch upstream'
                sh 'git checkout master'
                sh 'git merge upstream/master'
            }
        }
    }
    post {
        always {
             script {
                if (getContext(hudson.FilePath)) {
                    deleteDir()
                }
            }
            dir("${env.WORKSPACE}@tmp") {
                deleteDir()
            }
            dir("${env.WORKSPACE}@script") {
                deleteDir()
            }
            dir("${env.WORKSPACE}@script@tmp") {
                deleteDir()
            }
        }
    }
}