## Step-by-Step Guide To Deploy and Manage Infrastructure on AWS Using Kubernetes and Helm

* This README file provides a step-by-step guide for deploying and managing a comprehensive infrastructure on AWS using Kubernetes (EKS) and Helm. 
* The goal of this guide is to help you install and configure critical tools such as SonarQube, Prometheus, Grafana, Trivy, and Jenkins, as well as deploy a sample website using Docker and ECR. 
* The instructions will walk you through creating an EKS cluster, setting up namespaces for each service, installing monitoring tools, deploying CI/CD pipelines, and finally scaling and cleaning up your infrastructure.
* This guide aims to ensure that you have a highly available, scalable, resilient, and cost-efficient infrastructure, covering the installation of key tools and the process of deploying a fully functional web application.

Let’s get started by installing the necessary tools and setting up the EKS cluster!

### Tools to Install:
* AWS CLI: To install and configure AWS CLI, go to https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
* EKSCTL: To install EKSCTL, go to https://eksctl.io/installation/ 
* KUBECTL: To install KUBECTL, go to https://kubernetes.io/docs/tasks/tools/
* HELM: To install Helm, go to https://helm.sh/docs/intro/install/ 

### Step 1: Create EKS Cluster
Use Terraform configuration files to do it. 
* cd eks-cluster
* Change variables on the terraform.tfvars file
**Run the following terraform commands**
* terraform init 
* terraform plan 
* terraform apply

### Step 2: Update kubeconfig
* aws eks --region $(terraform output -raw t2s_services_region) update-kubeconfig --name $(terraform output -raw t2s_services_cluster_name)

# Step 3: Create Namespace and name it jenkins
* kubectl get ns             # To verify
* kubectl create ns jenkins  # To create a namespace

# Step 4: Installing Helm on Local Machine
* brew install helm 
* helm version # To verify

# Step 5: Install and Configure Jenkins for CI/CD
* helm repo add jenkins https://charts.jenkins.io
* helm repo update
* helm install jenkins jenkins/jenkins --set controller.serviceType=LoadBalancer

**Get the Cluster Info**
* kubectl cluster-info

**Verify the Worker Nodes**
* kubectl get nodes

# Step 6: Access Jenkins UI
**Get the Jenkins admin password:**
* kubectl exec --namespace default -it svc/jenkins -c jenkins -- /bin/cat /run/secrets/additional/chart-admin-password && echo

## Get the Load Balancer URL for Jenkins
* kubectl get svc --namespace default -w jenkins

*** Something like this: a8cc903b184cb4e908a01a07f7748594-416424995.us-east-1.elb.amazonaws.com. Paste it on the browser: a8cc903b184cb4e908a01a07f7748594-416424995.us-east-1.elb.amazonaws.com:8080.***

***For Username: Admin; For Password: (Paste what you generated using this command kubectl exec --name space ...., above)***


# Step 7: Install Plugins
**Docker Pipeline**
**GitHub Plugin**
**Kubernetes Plugin**
**AWS Credentials Plugin**
**Pipeline Plugin**
**AWS Credentials**
**GitLab Crendentials**
**SonarQube**
**Trivy**

# Step 8: Configure the Plugins
**Dashboard => Manage Jenkins => Tools**

# Set up Jenkins Pipeline
**Create a file and name it Jenkinsfile**
* Add this content (or use the attached file, Jenkinsfile)
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

# Step 9: Taint each node
**Taint nodes for SonarQube**
* kubectl taint nodes <node-name-1> tool=sonarqube:NoSchedule

**Taint nodes for Trivy**
* kubectl taint nodes <node-name-2> tool=trivy:NoSchedule

**Taint nodes for Grafana**
* kubectl taint nodes <node-name-3> tool=grafana:NoSchedule

**Taint nodes for Prometheus**
* kubectl taint nodes <node-name-4> tool=prometheus:NoSchedule

# Step 10: Install SonarQube with Helm and on Its Dedicated Node
* helm repo add sonarqube https://SonarSource.github.io/helm-chart-sonarqube
* helm repo update

***Deploy SonarQube in its own namespace***
* helm install sonarqube sonarqube/sonarqube \
    --namespace sonarqube \
    --create-namespace \
    --set nodeSelector.tool=sonarqube \
    --set tolerations[0].key=tool \
    --set tolerations[0].operator=Equal \
    --set tolerations[0].value=sonarqube \
    --set tolerations[0].effect=NoSchedule \
    --set persistence.storageClass="gp2" \
    --set service.type=LoadBalancer

* helm install kibana elastic/kibana \
    --namespace monitor \
    --set service.type=LoadBalancer

* helm install logstash elastic/logstash \
    --namespace monitor \
    --set service.type=LoadBalancer -->

***Deploy Trivy in its own namespace***
* helm install trivy aqua/trivy-operator \
    --namespace trivy-system \
    --create-namespace \
    --set nodeSelector.tool=trivy \
    --set tolerations[0].key=tool \
    --set tolerations[0].operator=Equal \
    --set tolerations[0].value=trivy \
    --set tolerations[0].effect=NoSchedule

***Create a Namespace for Jenkins***
* kubectl create namespace jenkins

***Install Jenkins Using Helm***
* helm install jenkins jenkins/jenkins \
     --namespace jenkins \
     --set controller.serviceType=LoadBalancer \
     --set controller.jenkinsAdminUser=admin \
     --set controller.jenkinsAdminPassword=admin123

### Step 4: Install SonarQube with Helm and on Its Dedicated Node
* helm repo add sonarqube https://SonarSource.github.io/helm-chart-sonarqube
* helm repo update
* helm install sonarqube sonarqube/sonarqube \
    --namespace sonarqube \
    --create-namespace \
    --set nodeSelector.tool=sonarqube \
    --set tolerations\[0\].key=tool \
    --set tolerations\[0\].operator=Equal \
    --set tolerations\[0\].value=sonarqube \
    --set tolerations\[0\].effect=NoSchedule \
    --set persistence.storageClass="gp2" \
    --set service.type=LoadBalancer

### Step 5: Install Trivy with Helm and on Its Dedicated Node
* helm repo add aqua https://aquasecurity.github.io/helm-charts
* helm repo update
* helm install trivy aqua/trivy-operator \
    --namespace trivy-system \
    --create-namespace \
    --set nodeSelector.tool=trivy \
    --set tolerations\[0\].key=tool \
    --set tolerations\[0\].operator=Equal \
    --set tolerations\[0\].value=trivy \
    --set tolerations\[0\].effect=NoSchedule

### Step 6: Install Prometheus with Helm and on Its Dedicated Node
* helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
* helm repo update
* helm install prometheus prometheus-community/prometheus \
    --namespace monitoring \
    --create-namespace \
    --set nodeSelector.tool=prometheus \
    --set tolerations[0].key=tool \
    --set tolerations[0].operator=Equal \
    --set tolerations[0].value=prometheus \
    --set tolerations[0].effect=NoSchedule

### Step 7: Install Grafana with Helm and on Its Dedicated Node
* helm repo add grafana https://grafana.github.io/helm-charts
* helm repo update
* helm install grafana grafana/grafana \
    --namespace grafana \
    --create-namespace \
    --set nodeSelector.tool=grafana \
    --set tolerations[0].key=tool \
    --set tolerations[0].operator=Equal \
    --set tolerations[0].value=grafana \
    --set tolerations[0].effect=NoSchedule

### Step 8: Verify Deployments
* kubectl get pods -o wide -n sonarqube
* kubectl get pods -o wide -n trivy-system
* kubectl get pods -o wide -n monitoring
* kubectl get pods -o wide -n grafana

### Step 9: Access the Services
***You will find external IP addresses under EXTERNAL-IP for each service. Open them in your browser.***
**SonarQube.**
* kubectl get svc -n sonarqube

**Prometheus, Grafana, and ELK**
* kubectl get svc -n monitor

**Trivy**
* kubectl get svc -n trivy-system

**Jenkins**
kubectl get svc -n jenkins

**Default Credentials**
***Grafana***
* Username: admin
* Password: admin

***SonarQube***
* Username: admin
* Password: admin

***Jenkins***
* Username: admin
* Password: admin123

### Step 10: Create and Deploy a Website as Image to ECR
* mkdir t2s-website
* cd t2s-website
* touch Dockerfile
***Add the following from the Dockerfile file***
* aws ecr create-repository --repository-name dev/t2s-services --region us-east-1 
* aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <AWS_Account_ID>.dkr.ecr.us-east-1.amazonaws.com 
* docker build -t dev/t2s-services .
* docker tag dev/t2s-services:latest <AWS_Account_ID>.dkr.ecr.us-east-1.amazonaws.com/dev/t2s-services:latest
* docker push <AWS_Account_ID>.dkr.ecr.us-east-1.amazonaws.com/dev/t2s-services:latest

### Step 11: Create Kubernetes Deployment and Service
* touch website-deployment.yaml
***Find content in the "t2s-website" directory***

* touch website-service.yaml
***Find content in the "t2s-website" directory***

**Deploy the Website to EKS**
* kubectl apply -f website-deployment.yaml
* kubectl apply -f website-service.yaml

**Verifiy**
* kubectl get pods

**Get the external IP Address**
kubectl get svc

**Access the Website**
***Use the external IP from the Load Balancer. Open a browser and visit the IP to see your website. The message displayed will be:***
* "Hello from T2S. Congratulations for having set up a complete infrastructure that is scalable, highly available, resilient, accessible, and cost-efficient. Great job!"

### Step 12: Scale Up the Deployment
* kubectl scale deployment t2s-website --replicas=3

### Step 13: Clean Up
***Run the terraform destroy command***
***In case you get an error message, go to the console to manually delete the Load Balancers.*** 

***Delete the EKS Cluster***
* terraform destroy

***Delete the ECR Repository and Images***
* aws ecr batch-delete-image \
    --repository-name dev/t2s-services \
    --image-ids imageTag=latest \
    --region us-east-1
* aws ecr delete-repository \
    --repository-name dev/t2s-services \
    --force \
    --region us-east-1

