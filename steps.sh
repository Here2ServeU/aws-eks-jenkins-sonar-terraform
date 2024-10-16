# Prerequisites
# Install AWS CLI
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /

brew tap weaveworks/tap
brew install weaveworks/tap/eksctl

# Step One: Create EKS Cluster
## Use Terraform configuration files to do it
## All is in the eks-cluster directory
cd eks-cluster
## Change variables on the terraform.tfvars file
## Run the following terraform commands
terraform init 
terraform plan 
terraform apply

# Step Two: Update kubeconfig
aws eks --region $(terraform output -raw t2s_services_region) update-kubeconfig \
    --name $(terraform output -raw t2s_services_cluster_name)

# Step Three: Create Namespace and name it jenkins
kubectl get ns             # To verify
kubectl create ns jenkins  # To create a namespace

# Step Four: Installing Helm on Local Machine
brew install helm 
helm version # To verify

# Step Five: Install and Configure Jenkins for CI/CD
helm repo add jenkins https://charts.jenkins.io
helm repo update
helm install jenkins jenkins/jenkins --set controller.serviceType=LoadBalancer

# Get the Cluster Info
kubectl cluster-info

# Verify the Worker Nodes
kubectl get nodes

# Step Six: Access Jenkins UI
## Get the Jenkins admin password:
kubectl exec --namespace default -it svc/jenkins -c jenkins -- /bin/cat /run/secrets/additional/chart-admin-password && echo

## Get the Load Balancer URL for Jenkins
kubectl get svc --namespace default -w jenkins

## Something like this: a8cc903b184cb4e908a01a07f7748594-416424995.us-east-1.elb.amazonaws.com
## Paste it on the browser: a8cc903b184cb4e908a01a07f7748594-416424995.us-east-1.elb.amazonaws.com:8080
## For Username: Admin
## For Password: (Paste what you generated using this command kubectl exec --name space ...., above)


# Step Seven: Install Plugins
## Docker Pipeline
## GitHub Plugin
## Kubernetes Plugin
## AWS Credentials Plugin
## Pipeline Plugin
## AWS Credentials
## GitLab Crendentials
## SonarQube
## Trivy
## ECR

# Step Eight: Configure the Plugins
## Dashboard => Manage Jenkins => Tools

# Set up Jenkins Pipeline
## Create a file and name it Jenkinsfile
## Add this content (or use the attached file, Jenkinsfile)
pipeline {
    agent any
    environment {
        ECR_REPO_URI = '123456789012.dkr.ecr.us-east-1.amazonaws.com/t2s-services-repo'
    }
    stages {
        stage('Build') {
            steps {
                script {
                    docker.build("$ECR_REPO_URI:$BUILD_NUMBER")
                }
            }
        }
        stage('Push to ECR') {
            steps {
                script {
                    withAWS(region: 'us-east-1') {
                        sh "aws ecr get-login-password | docker login --username AWS --password-stdin $ECR_REPO_URI"
                        docker.image("$ECR_REPO_URI:$BUILD_NUMBER").push()
                    }
                }
            }
        }
        stage('Deploy to Kubernetes') {
            steps {
                script {
                    kubernetesDeploy(
                        configs: 'k8s/deployment.yaml',
                        kubeconfigId: 'kubeconfig'
                    )
                }
            }
        }
    }
}
# Create a Repo on ECR to host the docker image
### Replace with the correct URI: ECR_REPO_URI = '123456789012.dkr.ecr.us-east-1.amazonaws.com/t2s-services-repo' 


# Clean Up
### 1) Manually delete Load Balancers
### 2) Run the terraform destroy command
### 3) In case you get an error message, go to the console
#### to manually delte the vpc. 
terraform destroy

