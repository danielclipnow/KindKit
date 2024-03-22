pipeline {
    agent any
    environment {}
    stages {
        stage('Git Fork Update ') {
            sh 'git fetch upstream'
            sh 'git checkout master'
            sh 'git merge upstream/master'
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
}