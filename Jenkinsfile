// pipeline {
//     agent any

//     environment {
//         TF_IN_AUTOMATION = 'true'
//         TF_CLI_ARGS = '-no-color'
//         SSH_CRED_ID = 'aws-deployer-ssh-key' 
//         TF_CLI_CONFIG_FILE = credentials('aws-creds')
//     }

//     stages {
//         stage('Terraform Initialization') {
//             steps {
//                 sh 'terraform init'
//                 sh "cat ${env.BRANCH_NAME}.tfvars"
//             }
//         }
//         stage('Terraform Plan') {
//             steps {
//                 sh "terraform plan -var-file=${env.BRANCH_NAME}.tfvars"
//             }
//         }
//         stage('Validate Apply') {
//             when {
//                     beforeInput true
//                     branch 'dev'
//             }
//             input {
//                 message "Do you want to apply this plan?"
//                 ok "Apply"
//             }
//             steps {
//                 echo 'Apply Accepted'
//             }
//         }
//         stage('Terraform Provisioning') {
//             steps {
//                 script {
//                     sh "terraform apply -auto-approve -var-file=${env.BRANCH_NAME}.tfvars"

//                     // 1. Extract Public IP Address of the provisioned instance
//                     env.INSTANCE_IP = sh(
//                         script: 'terraform output -raw instance_public_ip', 
//                         returnStdout: true
//                     ).trim()
                    
//                     // 2. Extract Instance ID (for AWS CLI wait) 
//                     env.INSTANCE_ID = sh(
//                         script: 'terraform output -raw instance_id', 
//                         returnStdout: true
//                     ).trim()

//                     echo "Provisioned Instance IP: ${env.INSTANCE_IP}"
//                     echo "Provisioned Instance ID: ${env.INSTANCE_ID}"
                    
//                     // 3. Create a dynamic inventory file for Ansible 
//                     sh "echo '${env.INSTANCE_IP}' > dynamic_inventory.ini"
//                 }
//             }
//         }

//         stage('Wait for AWS Instance Status') {
//             steps {
//                 echo "Waiting for instance ${env.INSTANCE_ID} to pass AWS health checks..."
                
//                 // --- This is the simple, powerful AWS CLI command ---
//                 // It polls AWS until status checks pass or it hits the default timeout (usually 15 minutes)
//                 sh "aws ec2 wait instance-status-ok --instance-ids ${env.INSTANCE_ID} --region us-east-2"  
                
//                 echo 'AWS instance health checks passed. Proceeding to Ansible.'
//             }
//         }
//         stage('Validate Ansible') {
//             when {
//                     beforeInput true
//                     branch 'dev'
//             }
//             input {
//                 message "Do you want to run Ansible?"
//                 ok "Run Ansible"
//             }
//             steps {
//                 echo 'Ansible approved'
//             }
//         }
//         stage('Ansible Configuration and Testing') {
//             steps {
//                 // Now you can proceed directly to Ansible, knowing SSH is almost certainly ready.
//                 ansiblePlaybook(
//                     playbook: 'playbooks/grafana.yml',
//                     inventory: 'dynamic_inventory.ini', 
//                     credentialsId: SSH_CRED_ID, // Key is securely injected by the plugin here
//                 )
//                 ansiblePlaybook(
//                     playbook: 'playbooks/test-grafana.yml',
//                     inventory: 'dynamic_inventory.ini', 
//                     credentialsId: SSH_CRED_ID, // Key is securely injected by the plugin here
//                 )
//             }
//         }
//         stage('Validate Destroy') {
//             input {
//                 message "Do you want to destroy??"
//                 ok "Destroy"
//             }
//             steps {
//                 echo 'Destroy Approved'
//             }
//         }
//         stage('Destroy') {
//             steps {
//                 sh "terraform destroy -auto-approve -var-file=${env.BRANCH_NAME}.tfvars"
//             }
//         }
//     }    
//     post {
//         always {
//             sh 'rm -f dynamic_inventory.ini'
//         }
//         success {
//             echo 'Success!'
//         }
//         failure {
//             sh "terraform destroy -auto-approve -var-file=${env.BRANCH_NAME}.tfvars || echo \"Cleanup failed, please check manually.\""
//         }
//         aborted {
//             sh "terraform destroy -auto-approve -var-file=${env.BRANCH_NAME}.tfvars || echo \"Cleanup failed, please check manually.\""
//         }
//     }
// }

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
            input {
                message "Apply Terraform changes?"
                ok "Apply"
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
            input {
                message "Run Ansible configuration?"
                ok "Run Ansible"
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
            input {
                message "Destroy infrastructure?"
                ok "Destroy"
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

