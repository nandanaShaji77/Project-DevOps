pipeline {
    agent any

    environment {
        TF_IN_AUTOMATION = 'true'
        TF_CLI_ARGS     = '-no-color'
        SSH_CRED_ID     = 'aws-deployer-ssh-key'
        AWS_REGION      = 'us-east-2'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Init') {
            steps {
                withCredentials([
                    [$class: 'AmazonWebServicesCredentialsBinding',
                     credentialsId: 'aws-creds']
                ]) {
                    sh '''
                        aws sts get-caller-identity
                        terraform init
                    '''
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                withCredentials([
                    [$class: 'AmazonWebServicesCredentialsBinding',
                     credentialsId: 'aws-creds']
                ]) {
                    sh """
                        test -f ${BRANCH_NAME}.tfvars
                        terraform plan -var-file=${BRANCH_NAME}.tfvars
                    """
                }
            }
        }

        stage('Approve Apply') {
            when {
                branch 'dev'
            }
            steps {
                input {
                    message "Apply Terraform changes?"
                    ok "Apply"
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                withCredentials([
                    [$class: 'AmazonWebServicesCredentialsBinding',
                     credentialsId: 'aws-creds']
                ]) {
                    script {
                        sh "terraform apply -auto-approve -var-file=${BRANCH_NAME}.tfvars"

                        env.INSTANCE_IP = sh(
                            script: "terraform output -raw instance_public_ip",
                            returnStdout: true
                        ).trim()

                        env.INSTANCE_ID = sh(
                            script: "terraform output -raw instance_id",
                            returnStdout: true
                        ).trim()

                        echo "Instance IP: ${env.INSTANCE_IP}"
                        echo "Instance ID: ${env.INSTANCE_ID}"

                        sh "echo ${env.INSTANCE_IP} > dynamic_inventory.ini"
                    }
                }
            }
        }

        stage('Wait for Instance Health') {
            steps {
                withCredentials([
                    [$class: 'AmazonWebServicesCredentialsBinding',
                     credentialsId: 'aws-creds']
                ]) {
                    sh """
                        aws ec2 wait instance-status-ok \
                        --instance-ids ${INSTANCE_ID} \
                        --region ${AWS_REGION}
                    """
                }
            }
        }

        stage('Approve Ansible') {
            when {
                branch 'dev'
            }
            steps {
                input {
                    message "Run Ansible configuration?"
                    ok "Run Ansible"
                }
            }
        }

        stage('Ansible Configuration') {
            steps {
                ansiblePlaybook(
                    playbook: 'playbooks/grafana.yml',
                    inventory: 'dynamic_inventory.ini',
                    credentialsId: SSH_CRED_ID
                )

                ansiblePlaybook(
                    playbook: 'playbooks/test-grafana.yml',
                    inventory: 'dynamic_inventory.ini',
                    credentialsId: SSH_CRED_ID
                )
            }
        }

        stage('Approve Destroy') {
            steps {
                input {
                    message "Destroy infrastructure?"
                    ok "Destroy"
                }
            }
        }

        stage('Terraform Destroy') {
            steps {
                withCredentials([
                    [$class: 'AmazonWebServicesCredentialsBinding',
                     credentialsId: 'aws-creds']
                ]) {
                    sh "terraform destroy -auto-approve -var-file=${BRANCH_NAME}.tfvars"
                }
            }
        }
    }

    post {
        always {
            sh 'rm -f dynamic_inventory.ini || true'
        }

        failure {
            withCredentials([
                [$class: 'AmazonWebServicesCredentialsBinding',
                 credentialsId: 'aws-creds']
            ]) {
                sh '''
                    terraform destroy -auto-approve -var-file=${BRANCH_NAME}.tfvars \
                    || echo "Cleanup failed. Manual cleanup required."
                '''
            }
        }
    }
}
