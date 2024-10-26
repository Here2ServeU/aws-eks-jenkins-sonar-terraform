## Step-by-Step Guide To Deploy and Manage Infrastructure on AWS Using Kubernetes and Helm
* This README file provides a step-by-step guide for deploying and managing a comprehensive infrastructure on AWS using Kubernetes (EKS) and Helm. 
* This guide aims to help you install and configure critical tools such as SonarQube, Prometheus, Grafana, Trivy, and Jenkins and deploy a sample website using Docker and ECR. 
* The instructions will walk you through creating an EKS cluster, setting up namespaces for each service, installing monitoring tools, deploying CI/CD pipelines, and scaling and cleaning up your infrastructure.
* This guide aims to ensure that you have a highly available, scalable, resilient, and cost-efficient infrastructure. It covers the installation of key tools and the deployment of a fully functional web application.

Let’s start by installing the necessary tools and setting up the EKS cluster!

### Tools to Install:
* AWS CLI: To install and configure AWS CLI, go to https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
* EKSCTL: To install EKSCTL, go to https://eksctl.io/installation/ 
* KUBECTL: To install KUBECTL, go to https://kubernetes.io/docs/tasks/tools/
* HELM: To install Helm, go to https://helm.sh/docs/intro/install/ 

### Step 1: Create EKS Cluster
**Clone the Project and navigate to the eks-cluster directory.** 
* cd eks-cluster
***Modify variables on the terraform.tfvars file***
**Run the following terraform commands**
* terraform init 
* terraform plan 
* terraform apply

### Step 2: Update kubeconfig
* aws eks --region $(terraform output -raw t2s_services_region) update-kubeconfig --name $(terraform output -raw t2s_services_cluster_name)

### Step 3: Deploy Monitoring and CI/CD Tools
**Add Helm Repositories**
***SonarQube***
* helm repo add sonarqube https://SonarSource.github.io/helm-chart-sonarqube

***Prometheus***
* helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

***Grafana***
* helm repo add grafana https://grafana.github.io/helm-charts

***Trivy***
* helm repo add aqua https://aquasecurity.github.io/helm-charts

***Jenkins***
* helm repo add jenkins https://charts.jenkins.io

**Update all Repositories**
* helm repo update

### Step 4: Deploy SonarQube, Prometheus, Grafana, and Trivy
**Deploy SonarQube**
* helm install sonarqube sonarqube/sonarqube \
    --namespace sonarqube \
    --create-namespace \
    --set persistence.storageClass="gp2" \
    --set service.type=LoadBalancer

**Deploy Prometheus in the Monitor Namespace**
* helm install prometheus prometheus-community/prometheus \
    --namespace monitor \
    --create-namespace \
    --set "nodeSelector.tool=prometheus" \
    --set "tolerations[0].key=tool" \
    --set "tolerations[0].operator=Equal" \
    --set "tolerations[0].value=prometheus" \
    --set "tolerations[0].effect=NoSchedule" \
    --set "server.service.type=LoadBalancer"

**Deploy Grafana**
* helm install grafana grafana/grafana \
    --namespace monitor \
    --set persistence.storageClassName="gp2" \
    --set adminPassword='admin' \
    --set service.type=LoadBalancer

**Deploy Trivy**
* helm install trivy aqua/trivy-operator \
    --namespace trivy-system \
    --create-namespace \
    --set "nodeSelector.tool=trivy" \
    --set "tolerations[0].key=tool" \
    --set "tolerations[0].operator=Equal" \
    --set "tolerations[0].value=trivy" \
    --set "tolerations[0].effect=NoSchedule"

**Create a Namespace for Jenkins and Install Jenkins**
* kubectl create namespace jenkins
* helm install jenkins jenkins/jenkins \
     --namespace jenkins \
     --set controller.serviceType=LoadBalancer \
     --set controller.jenkinsAdminUser=Admin \
     --set controller.jenkinsAdminPassword=Admin123

### Step 5: Verify Deployments
***Ensure that all your deployments are running:***
* kubectl get pods -o wide -n sonarqube     # To check SonarQube
* kubectl get pods -o wide -n monitor       # To check Prometheus, Grafana
* kubectl get pods -o wide -n trivy-system  # To check Trivy
* kubectl get pods -o wide -n jenkins       # To check Jenkins

### Step 6: Access the Services
***Ensure service will be exposed to an external IP that you can use to access the web interfaces of SonarQube, Grafana, Prometheus, and others.***

**Run the following commands:**
* kubectl get svc -n sonarqube        # Access SonarQube
* kubectl get svc -n monitor          # Access Prometheus, and Grafana
* kubectl get svc -n trivy-system     # Access Trivy
* kubectl get svc -n jenkins          # Access Jenkins
* kubectl get secret --namespace jenkins jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode # To get the password in case "Admin123" does not work. 

### Step 7: Deploy a Website using Docker and ECR
**Create a directory and Dockerfile for the website:**
* mkdir t2s-website
* cd t2s-website
* touch Dockerfile

**Build and push the Docker image to ECR:**
* aws ecr create-repository --repository-name dev/t2s-services --region us-east-1
* aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <AWS_Account_ID>.dkr.ecr.us-east-1.amazonaws.com
* docker build -t dev/t2s-services .
* docker tag dev/t2s-services:latest <AWS_Account_ID>.dkr.ecr.us-east-1.amazonaws.com/dev/t2s-services:latest
* docker push <AWS_Account_ID>.dkr.ecr.us-east-1.amazonaws.com/dev/t2s-services:latest

***Replace <AWS_Account_ID> with the desired Account ID.***

**Create Kubernetes deployment and service YAML files, apply them to your cluster, and deploy your website.**
***Use the deployment and service YAML files from the t2s-website directory.***

### Step 8: Scale the Deployment
* cd /t2s-website/
* kubectl scale deployment t2s-website --replicas=3

### Step 9: Clean Up
**Delete the EKS Cluster**
* cd /eks-cluster/
* terraform destroy

**Delete the ECR Repository and Images**
* aws ecr batch-delete-image --repository-name dev/t2s-services --image-ids imageTag=latest --region us-east-1
* aws ecr delete-repository --repository-name dev/t2s-services --force --region us-east-1

**Manually delete Load Balancers**
***Go to EC2 Dashboard and then Load Balancers to delete the Load Balancers created as part of the infrastructure.***

