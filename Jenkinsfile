pipeline {
    agent any

    environment {
        TF_IN_AUTOMATION = 'true'
        TF_CLI_ARGS = '-no-color'
        BRANCH_NAME = "main"
        AWS_DEFAULT_REGION = "us-east-1"
        
    }
  
    stages {
        stage('Hello') {
            steps {
                echo 'Jenkins Multibranch Pipeline is working!'
            }
        }
 
    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Init') {
            steps {
                bat 'terraform init -no-color'
                bat "type %BRANCH_NAME%.tfvars"
            }
        }

        stage('Terraform Plan') {
            steps {
                bat "terraform plan -var-file=%BRANCH_NAME%.tfvars"
            }
        }

        stage('Validate Apply') {
            input {
                message "Do you want to apply this Terraform plan?"
                ok "Apply"
            }
        }

        stage('Terraform Apply') {
            steps {
                bat "terraform apply -auto-approve -var-file=%BRANCH_NAME%.tfvars"

                script {
                    env.INSTANCE_IP = bat(
                        script: 'terraform output -raw instance_public_ip',
                        returnStdout: true
                    ).trim()

                    env.INSTANCE_ID = bat(
                        script: 'terraform output -raw instance_id',
                        returnStdout: true
                    ).trim()
                }

                bat """
                echo [web] > dynamic_inventory.ini
                echo %INSTANCE_IP% >> dynamic_inventory.ini
                """
            }
        }

        stage('Wait for AWS Instance Health') {
            steps {
                bat "aws ec2 wait instance-status-ok --instance-ids %INSTANCE_ID% --region us-east-1"
            }
        }

        stage('Validate Ansible') {
            input {
                message "Do you want to run Ansible?"
                ok "Run Ansible"
            }
        }

        stage('Ansible Configuration (WSL)') {
            steps {
                bat """
                wsl ansible-playbook install-monitoring.yml -i dynamic_inventory.ini
                """
            }
        }

        stage('Validate Destroy') {
            input {
                message "Do you want to destroy the infrastructure?"
                ok "Destroy"
            }
        }

        stage('Terraform Destroy') {
            steps {
                bat "terraform destroy -auto-approve -var-file=%BRANCH_NAME%.tfvars"
            }
        }
    }

    post {
        always {
            bat "if exist dynamic_inventory.ini del dynamic_inventory.ini"
        }

        failure {
            bat "terraform destroy -auto-approve -var-file=%BRANCH_NAME%.tfvars || echo Cleanup failed"
        }
    }
}