// ============================================================================
// JENKINS PIPELINE: INFRASTRUCTURE DEPLOYMENT (Terraform)
// ============================================================================
// Purpose: Deploy EKS cluster and addons using Terraform (folders 1-2)
// 
// REQUIRED JENKINS PLUGINS:
// 1. Pipeline (workflow-aggregator)
// 2. Git (git)
// 3. AWS Credentials (aws-credentials)
// 4. Terraform (terraform)
// 5. Credentials Binding (credentials-binding)
// 6. Kubernetes CLI (kubernetes-cli)
//
// REQUIRED JENKINS CREDENTIALS:
// - aws-credentials: Single AWS credential (works for all environments)
//
// HOW IT WORKS:
// 1. Select ENVIRONMENT (dev/qa/prod) → Uses corresponding .tfvars file
// 2. Select ACTION (apply/destroy)
// 3. Pipeline automatically:
//    - Apply: Creates 01-infrastructure → 02-eks-addons
//    - Destroy: Deletes 02-eks-addons → 01-infrastructure (reverse order)
//
// USAGE:
// 1. Create new Pipeline job in Jenkins
// 2. Build with Parameters
// 3. Select environment and action
// ============================================================================

pipeline {
    agent any
    
    parameters {
        choice(
            name: 'ENVIRONMENT',
            choices: ['dev', 'qa', 'prod'],
            description: 'Select environment (uses corresponding .tfvars file)'
        )
        choice(
            name: 'ACTION',
            choices: ['apply', 'destroy'],
            description: 'Terraform action: apply (create) or destroy (delete)'
        )
    }
    
    environment {
        // AWS Credentials from Jenkins
        AWS_CREDENTIALS_ID = 'aws-credentials'
        
        // Terraform settings
        TF_IN_AUTOMATION = 'true'
        TF_INPUT = 'false'
        TF_CLI_ARGS = '-no-color'
        
        // Automatically select tfvars file based on environment
        TFVARS_FILE = "${params.ENVIRONMENT}.tfvars"
    }
    
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 1, unit: 'HOURS')
        disableConcurrentBuilds()
        timestamps()
    }
    
    stages {
        stage('Initialize') {
            steps {
                script {
                    echo "============================================"
                    echo "Infrastructure Pipeline"
                    echo "Environment: ${params.ENVIRONMENT}"
                    echo "Action: ${params.ACTION}"
                    echo "Terraform file: ${env.TFVARS_FILE}"
                    echo "============================================"
                }
            }
        }
        
        stage('Checkout') {
            steps {
                checkout scm
                sh 'git rev-parse HEAD > GIT_COMMIT'
                script {
                    env.GIT_COMMIT_HASH = readFile('GIT_COMMIT').trim()
                    echo "Git Commit: ${env.GIT_COMMIT_HASH}"
                }
            }
        }
        
        // ========================================================================
        // APPLY: Create infrastructure in correct order (01 → 02)
        // ========================================================================
        
        stage('Terraform Init - 01-Infrastructure') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                dir('Terraform-K8S-Infra-and-Sample-Application-Deployment/1-infrastructure') {
                    withCredentials([
                        [
                            $class: 'AmazonWebServicesCredentialsBinding',
                            credentialsId: env.AWS_CREDENTIALS_ID,
                            accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                            secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                        ]
                    ]) {
                        sh """
                            echo "Initializing Terraform for 01-infrastructure..."
                            terraform init
                        """
                    }
                }
            }
        }
        
        stage('Terraform Plan - 01-Infrastructure') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                dir('Terraform-K8S-Infra-and-Sample-Application-Deployment/1-infrastructure') {
                    withCredentials([
                        [
                            $class: 'AmazonWebServicesCredentialsBinding',
                            credentialsId: env.AWS_CREDENTIALS_ID,
                            accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                            secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                        ]
                    ]) {
                        sh """
                            echo "Planning Terraform for 01-infrastructure..."
                            terraform plan -var-file="${env.TFVARS_FILE}" -out=tfplan
                        """
                    }
                }
            }
        }
        
        stage('Terraform Apply - 01-Infrastructure') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                script {
                    if (params.ENVIRONMENT == 'prod') {
                        input message: "Apply Terraform to PRODUCTION infrastructure?", ok: 'Apply'
                    }
                }
                
                dir('Terraform-K8S-Infra-and-Sample-Application-Deployment/1-infrastructure') {
                    withCredentials([
                        [
                            $class: 'AmazonWebServicesCredentialsBinding',
                            credentialsId: env.AWS_CREDENTIALS_ID,
                            accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                            secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                        ]
                    ]) {
                        sh """
                            echo "Applying Terraform for 01-infrastructure..."
                            terraform apply -auto-approve tfplan
                        """
                    }
                }
            }
        }
        
        stage('Terraform Init - 02-EKS-Addons') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                dir('Terraform-K8S-Infra-and-Sample-Application-Deployment/2-eks-addons') {
                    withCredentials([
                        [
                            $class: 'AmazonWebServicesCredentialsBinding',
                            credentialsId: env.AWS_CREDENTIALS_ID,
                            accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                            secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                        ]
                    ]) {
                        sh """
                            echo "Initializing Terraform for 02-eks-addons..."
                            terraform init
                        """
                    }
                }
            }
        }
        
        stage('Terraform Plan - 02-EKS-Addons') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                dir('Terraform-K8S-Infra-and-Sample-Application-Deployment/2-eks-addons') {
                    withCredentials([
                        [
                            $class: 'AmazonWebServicesCredentialsBinding',
                            credentialsId: env.AWS_CREDENTIALS_ID,
                            accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                            secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                        ]
                    ]) {
                        sh """
                            echo "Planning Terraform for 02-eks-addons..."
                            terraform plan -var-file="terraform.tfvars" -out=tfplan
                        """
                    }
                }
            }
        }
        
        stage('Terraform Apply - 02-EKS-Addons') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                script {
                    if (params.ENVIRONMENT == 'prod') {
                        input message: "Apply Terraform to PRODUCTION addons?", ok: 'Apply'
                    }
                }
                
                dir('Terraform-K8S-Infra-and-Sample-Application-Deployment/2-eks-addons') {
                    withCredentials([
                        [
                            $class: 'AmazonWebServicesCredentialsBinding',
                            credentialsId: env.AWS_CREDENTIALS_ID,
                            accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                            secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                        ]
                    ]) {
                        sh """
                            echo "Applying Terraform for 02-eks-addons..."
                            terraform apply -auto-approve tfplan
                        """
                    }
                }
            }
        }
        
        stage('Update Kubeconfig') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                dir('Terraform-K8S-Infra-and-Sample-Application-Deployment/1-infrastructure') {
                    withCredentials([
                        [
                            $class: 'AmazonWebServicesCredentialsBinding',
                            credentialsId: env.AWS_CREDENTIALS_ID,
                            accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                            secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                        ]
                    ]) {
                        sh """
                            echo "Getting cluster name from Terraform output..."
                            CLUSTER_NAME=\$(terraform output -raw cluster_name)
                            AWS_REGION=\$(terraform output -raw aws_region)
                            
                            echo "Updating kubeconfig for cluster: \$CLUSTER_NAME"
                            aws eks update-kubeconfig --region \$AWS_REGION --name \$CLUSTER_NAME
                            
                            echo "Verifying cluster access..."
                            kubectl get nodes
                            kubectl get pods -A
                        """
                    }
                }
            }
        }
        
        // ========================================================================
        // DESTROY: Delete infrastructure in reverse order (02 → 01)
        // ========================================================================
        
        stage('Confirm Destroy') {
            when {
                expression { params.ACTION == 'destroy' }
            }
            steps {
                script {
                    input message: "⚠️ WARNING: Destroy ${params.ENVIRONMENT} infrastructure? This cannot be undone!", 
                          ok: 'Destroy'
                }
            }
        }
        
        stage('Terraform Init - 02-EKS-Addons (Destroy)') {
            when {
                expression { params.ACTION == 'destroy' }
            }
            steps {
                dir('Terraform-K8S-Infra-and-Sample-Application-Deployment/2-eks-addons') {
                    withCredentials([
                        [
                            $class: 'AmazonWebServicesCredentialsBinding',
                            credentialsId: env.AWS_CREDENTIALS_ID,
                            accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                            secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                        ]
                    ]) {
                        sh """
                            echo "Initializing Terraform for 02-eks-addons (destroy)..."
                            terraform init
                        """
                    }
                }
            }
        }
        
        stage('Terraform Destroy - 02-EKS-Addons') {
            when {
                expression { params.ACTION == 'destroy' }
            }
            steps {
                dir('Terraform-K8S-Infra-and-Sample-Application-Deployment/2-eks-addons') {
                    withCredentials([
                        [
                            $class: 'AmazonWebServicesCredentialsBinding',
                            credentialsId: env.AWS_CREDENTIALS_ID,
                            accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                            secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                        ]
                    ]) {
                        sh """
                            echo "Destroying 02-eks-addons first..."
                            terraform destroy -auto-approve -var-file="terraform.tfvars"
                        """
                    }
                }
            }
        }
        
        stage('Terraform Init - 01-Infrastructure (Destroy)') {
            when {
                expression { params.ACTION == 'destroy' }
            }
            steps {
                dir('Terraform-K8S-Infra-and-Sample-Application-Deployment/1-infrastructure') {
                    withCredentials([
                        [
                            $class: 'AmazonWebServicesCredentialsBinding',
                            credentialsId: env.AWS_CREDENTIALS_ID,
                            accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                            secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                        ]
                    ]) {
                        sh """
                            echo "Initializing Terraform for 01-infrastructure (destroy)..."
                            terraform init
                        """
                    }
                }
            }
        }
        
        stage('Terraform Destroy - 01-Infrastructure') {
            when {
                expression { params.ACTION == 'destroy' }
            }
            steps {
                dir('Terraform-K8S-Infra-and-Sample-Application-Deployment/1-infrastructure') {
                    withCredentials([
                        [
                            $class: 'AmazonWebServicesCredentialsBinding',
                            credentialsId: env.AWS_CREDENTIALS_ID,
                            accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                            secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                        ]
                    ]) {
                        sh """
                            echo "Destroying 01-infrastructure last..."
                            terraform destroy -auto-approve -var-file="${env.TFVARS_FILE}"
                        """
                    }
                }
            }
        }
    }
    
    post {
        success {
            echo "✅ Infrastructure pipeline completed successfully!"
            echo "Environment: ${params.ENVIRONMENT}"
            echo "Action: ${params.ACTION}"
        }
        
        failure {
            echo "❌ Infrastructure pipeline failed!"
            echo "Environment: ${params.ENVIRONMENT}"
            echo "Action: ${params.ACTION}"
        }
        
        always {
            cleanWs()
        }
    }
}
