// ============================================================================
// JENKINS PIPELINE: APPLICATION DEPLOYMENT (Docker + Kubernetes)
// ============================================================================
// Purpose: Build Docker images and deploy to Kubernetes (folders 3-4)
//
// REQUIRED JENKINS PLUGINS:
// 1. Pipeline (workflow-aggregator)
// 2. Git (git)
// 3. Docker Pipeline (docker-workflow)
// 4. Kubernetes CLI (kubernetes-cli)
// 5. AWS Credentials (aws-credentials)
// 6. Credentials Binding (credentials-binding)
//
// REQUIRED JENKINS CREDENTIALS:
// - aws-credentials: Single AWS credential (works for all environments)
// - kubeconfig-{env}: Kubernetes config for each environment
//
// HOW IT WORKS:
// 1. Select ENVIRONMENT (dev/qa/prod)
// 2. Select what to do: BUILD_IMAGES, DEPLOY_K8S
// 3. Specify IMAGE_TAG (or use git commit hash)
//
// USAGE:
// 1. Create new Pipeline job in Jenkins
// 2. Build with Parameters
// 3. Select options and build
// ============================================================================

pipeline {
    agent any
    
    parameters {
        choice(
            name: 'ENVIRONMENT',
            choices: ['dev', 'qa', 'prod'],
            description: 'Select environment to deploy'
        )
        booleanParam(
            name: 'BUILD_IMAGES',
            defaultValue: true,
            description: 'Build Docker images for all services'
        )
        booleanParam(
            name: 'DEPLOY_K8S',
            defaultValue: true,
            description: 'Deploy to Kubernetes cluster'
        )
        string(
            name: 'IMAGE_TAG',
            defaultValue: 'latest',
            description: 'Docker image tag (use "latest" for git commit hash)'
        )
    }
    
    environment {
        // AWS Credentials from Jenkins
        AWS_CREDENTIALS_ID = 'aws-credentials'
        KUBECONFIG_CREDENTIALS_ID = "kubeconfig-${params.ENVIRONMENT}"
        
        // Docker
        DOCKER_BUILDKIT = '1'
        
        // Backend services to build
        BACKEND_SERVICES = 'adservice cartservice checkoutservice currencyservice emailservice paymentservice productcatalogservice recommendationservice shippingservice'
    }
    
    options {
        buildDiscarder(logRotator(numToKeepStr: '20'))
        timeout(time: 2, unit: 'HOURS')
        disableConcurrentBuilds()
        timestamps()
    }
    
    stages {
        stage('Initialize') {
            steps {
                script {
                    echo "============================================"
                    echo "Application Pipeline"
                    echo "Environment: ${params.ENVIRONMENT}"
                    echo "Build Images: ${params.BUILD_IMAGES}"
                    echo "Deploy K8s: ${params.DEPLOY_K8S}"
                    echo "Image Tag: ${params.IMAGE_TAG}"
                    echo "============================================"
                }
            }
        }
        
        stage('Checkout') {
            steps {
                checkout scm
                sh 'git rev-parse --short HEAD > GIT_COMMIT'
                script {
                    env.GIT_COMMIT_HASH = readFile('GIT_COMMIT').trim()
                    
                    // Use git commit hash if IMAGE_TAG is 'latest'
                    if (params.IMAGE_TAG == 'latest') {
                        env.FINAL_IMAGE_TAG = env.GIT_COMMIT_HASH
                    } else {
                        env.FINAL_IMAGE_TAG = params.IMAGE_TAG
                    }
                    
                    echo "Git Commit: ${env.GIT_COMMIT_HASH}"
                    echo "Final Image Tag: ${env.FINAL_IMAGE_TAG}"
                }
            }
        }
        
        stage('Get AWS Account Info') {
            steps {
                withCredentials([
                    [
                        $class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: env.AWS_CREDENTIALS_ID,
                        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                    ]
                ]) {
                    script {
                        // Get AWS account ID and region
                        env.AWS_ACCOUNT_ID = sh(
                            script: 'aws sts get-caller-identity --query Account --output text',
                            returnStdout: true
                        ).trim()
                        
                        env.AWS_REGION = sh(
                            script: 'aws configure get region || echo us-east-1',
                            returnStdout: true
                        ).trim()
                        
                        env.ECR_REGISTRY = "${env.AWS_ACCOUNT_ID}.dkr.ecr.${env.AWS_REGION}.amazonaws.com"
                        env.ECR_PREFIX = "shopease-${params.ENVIRONMENT}"
                        
                        echo "AWS Account: ${env.AWS_ACCOUNT_ID}"
                        echo "AWS Region: ${env.AWS_REGION}"
                        echo "ECR Registry: ${env.ECR_REGISTRY}"
                    }
                }
            }
        }
        
        stage('ECR Login') {
            when {
                expression { params.BUILD_IMAGES == true }
            }
            steps {
                withCredentials([
                    [
                        $class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: env.AWS_CREDENTIALS_ID,
                        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                    ]
                ]) {
                    sh """
                        echo "Logging into ECR..."
                        aws ecr get-login-password --region ${env.AWS_REGION} | \
                            docker login --username AWS --password-stdin ${env.ECR_REGISTRY}
                    """
                }
            }
        }
        
        stage('Build Backend Services') {
            when {
                expression { params.BUILD_IMAGES == true }
            }
            steps {
                script {
                    def services = env.BACKEND_SERVICES.split(' ')
                    
                    for (service in services) {
                        stage("Build ${service}") {
                            dir("Terraform-K8S-Infra-and-Sample-Application-Deployment/3-application/backend/services/${service}") {
                                sh """
                                    echo "Building ${service}..."
                                    docker build \
                                        -t ${env.ECR_REGISTRY}/${env.ECR_PREFIX}-${service}:${env.FINAL_IMAGE_TAG} \
                                        -t ${env.ECR_REGISTRY}/${env.ECR_PREFIX}-${service}:latest \
                                        .
                                    
                                    echo "Pushing ${service} to ECR..."
                                    docker push ${env.ECR_REGISTRY}/${env.ECR_PREFIX}-${service}:${env.FINAL_IMAGE_TAG}
                                    docker push ${env.ECR_REGISTRY}/${env.ECR_PREFIX}-${service}:latest
                                """
                            }
                        }
                    }
                }
            }
        }
        
        stage('Build Frontend') {
            when {
                expression { params.BUILD_IMAGES == true }
            }
            steps {
                dir('Terraform-K8S-Infra-and-Sample-Application-Deployment/3-application/frontend') {
                    sh """
                        echo "Building frontend..."
                        docker build \
                            -t ${env.ECR_REGISTRY}/${env.ECR_PREFIX}-frontend:${env.FINAL_IMAGE_TAG} \
                            -t ${env.ECR_REGISTRY}/${env.ECR_PREFIX}-frontend:latest \
                            .
                        
                        echo "Pushing frontend to ECR..."
                        docker push ${env.ECR_REGISTRY}/${env.ECR_PREFIX}-frontend:${env.FINAL_IMAGE_TAG}
                        docker push ${env.ECR_REGISTRY}/${env.ECR_PREFIX}-frontend:latest
                    """
                }
            }
        }
        
        stage('Update Kubernetes Manifests') {
            when {
                expression { params.DEPLOY_K8S == true }
            }
            steps {
                dir('Terraform-K8S-Infra-and-Sample-Application-Deployment/4-kubernetes-manifests') {
                    sh """
                        echo "Updating image tags in manifests..."
                        
                        # Create temporary copies
                        cp backend-all.yaml backend-all.yaml.tmp
                        cp frontend.yaml frontend.yaml.tmp
                        
                        # Update backend-all.yaml
                        sed -i "s|<AWS_ACCOUNT_ID>|${env.AWS_ACCOUNT_ID}|g" backend-all.yaml.tmp
                        sed -i "s|<REGION>|${env.AWS_REGION}|g" backend-all.yaml.tmp
                        sed -i "s|:latest|:${env.FINAL_IMAGE_TAG}|g" backend-all.yaml.tmp
                        
                        # Update frontend.yaml
                        sed -i "s|<AWS_ACCOUNT_ID>|${env.AWS_ACCOUNT_ID}|g" frontend.yaml.tmp
                        sed -i "s|<REGION>|${env.AWS_REGION}|g" frontend.yaml.tmp
                        sed -i "s|:latest|:${env.FINAL_IMAGE_TAG}|g" frontend.yaml.tmp
                        
                        echo "Manifests updated with image tag: ${env.FINAL_IMAGE_TAG}"
                    """
                }
            }
        }
        
        stage('Deploy to Kubernetes') {
            when {
                expression { params.DEPLOY_K8S == true }
            }
            steps {
                script {
                    if (params.ENVIRONMENT == 'prod') {
                        input message: "Deploy to PRODUCTION?", ok: 'Deploy'
                    }
                }
                
                withCredentials([file(credentialsId: env.KUBECONFIG_CREDENTIALS_ID, variable: 'KUBECONFIG')]) {
                    dir('Terraform-K8S-Infra-and-Sample-Application-Deployment/4-kubernetes-manifests') {
                        sh """
                            echo "Deploying to Kubernetes (${params.ENVIRONMENT})..."
                            
                            # Apply in order
                            kubectl apply -f namespace.yaml
                            kubectl apply -f database.yaml
                            kubectl apply -f redis.yaml
                            
                            # Wait for database and redis
                            kubectl wait --for=condition=ready pod -l app=postgres -n application --timeout=300s || true
                            kubectl wait --for=condition=ready pod -l app=redis-cart -n application --timeout=120s || true
                            
                            # Deploy backend (use temporary file with updated images)
                            kubectl apply -f backend-all.yaml.tmp
                            
                            # Wait for backend
                            kubectl wait --for=condition=ready pod -l tier=backend -n application --timeout=300s || true
                            
                            # Deploy frontend (use temporary file with updated images)
                            kubectl apply -f frontend.yaml.tmp
                            
                            # Wait for frontend
                            kubectl wait --for=condition=ready pod -l app=frontend -n application --timeout=120s || true
                            
                            # Deploy ingresses
                            kubectl apply -f frontend-ingress-external.yaml
                            kubectl apply -f backend-ingress-internal.yaml
                            kubectl apply -f monitoring-ingress-internal.yaml
                            
                            # Deploy security and scaling
                            kubectl apply -f network-policies.yaml
                            kubectl apply -f hpa.yaml
                            kubectl apply -f servicemonitor.yaml
                            
                            echo "Deployment complete!"
                        """
                    }
                }
            }
        }
        
        stage('Verify Deployment') {
            when {
                expression { params.DEPLOY_K8S == true }
            }
            steps {
                withCredentials([file(credentialsId: env.KUBECONFIG_CREDENTIALS_ID, variable: 'KUBECONFIG')]) {
                    sh """
                        echo "Verifying deployment..."
                        
                        echo "=== Pods ==="
                        kubectl get pods -n application
                        
                        echo "=== Services ==="
                        kubectl get svc -n application
                        
                        echo "=== Ingresses ==="
                        kubectl get ingress -n application
                        
                        echo "=== HPA ==="
                        kubectl get hpa -n application
                        
                        # Get frontend URL
                        echo "=== Frontend URL ==="
                        kubectl get ingress frontend-ingress -n application \
                            -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' || echo "Not ready yet"
                    """
                }
            }
        }
    }
    
    post {
        success {
            echo "✅ Application pipeline completed successfully!"
            echo "Image Tag: ${env.FINAL_IMAGE_TAG}"
            echo "Environment: ${params.ENVIRONMENT}"
        }
        
        failure {
            echo "❌ Application pipeline failed!"
        }
        
        always {
            // Clean up Docker images
            sh 'docker system prune -f || true'
            
            // Clean up temporary manifest files
            dir('Terraform-K8S-Infra-and-Sample-Application-Deployment/4-kubernetes-manifests') {
                sh 'rm -f *.tmp || true'
            }
            
            cleanWs()
        }
    }
}
