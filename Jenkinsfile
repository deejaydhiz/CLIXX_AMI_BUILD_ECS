pipeline {
    agent any
    parameters {
        string defaultValue: 'DEJI', name: 'RUNNER'
    }

    environment {
        AMI_ID="stack-ecs_ami-14"
    }
    
    stages{
        stage('Packer ECS AMI Build'){
            steps {
                sh """
                packer init -upgrade .
                packer validate ecs_image.pkr.hcl
                export PACKER_LOG=1
                export PACKER_LOG_PATH=$WORKSPACE/packer.log
                /usr/bin/packer build -force ecs_image.pkr.hcl 
                slackSend (color: '#ff9900ff', message: "${params.RUNNER} Started Packer ECS AMI Build")
                """
            }
        } 

        stage('Scan Custom AMI with Inspector2') {
            steps {
                script {
                    sh """
                    chmod +x ./inspector.sh
                    ./inspector.sh ${env.AMI_ID} subnet-0330cd347d4184bf5
                    slackSend (color: '#ff9900ff', message: "Scanning Custom AMI with Inspector2")
                    """
                }
            }
        }
    }
}