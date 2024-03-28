pipeline {
    agent any
    environment {
        GITHUB_TOKEN = credentials('83759a99-5eb1-4406-8296-e9e4e3bf0594')
    }
    stages {
        stage('Git Fork Update ') {
            steps{
                script{
                    def githubUrl = "https://github.com/KindKit/KindKit.git"
                    echo "GitHub URL: ${githubUrl}"
                    sh '''
                        git remote add upstream ${githubUrl}
                        git fetch upstream
                        git checkout master
                        git merge upstream/master
                    '''
                }
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