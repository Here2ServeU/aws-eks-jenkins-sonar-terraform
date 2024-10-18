### Step-by-Step Guide To Deploy and Manage Infrastructure on AWS Using Kubernetes and Helm

* This README file provides a step-by-step guide for deploying and managing a comprehensive infrastructure on AWS using Kubernetes (EKS) and Helm. 
* This guide aims to help you install and configure critical tools such as SonarQube, Prometheus, Grafana, Trivy, and Jenkins and deploy a sample website using Docker and ECR. 
* The instructions will walk you through creating an EKS cluster, setting up namespaces for each service, installing monitoring tools, deploying CI/CD pipelines, and scaling and cleaning up your infrastructure.
* This guide ensures a highly available, scalable, resilient, and cost-efficient infrastructure. It covers the installation of critical tools and the process of deploying a fully functional web application.

Let’s start by installing the necessary tools and setting up the EKS cluster!

#### Tools to Install:
* AWS CLI: To install and configure AWS CLI, go to https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
* EKSCTL: To install EKSCTL, go to https://eksctl.io/installation/ 
* KUBECTL: To install KUBECTL, go to https://kubernetes.io/docs/tasks/tools/
* HELM: To install Helm, go to https://helm.sh/docs/intro/install/ 

#### Prerequisites
#### Install AWS CLI
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /

brew tap weaveworks/tap
brew install weaveworks/tap/eksctl

#### Step 1: Create EKS Cluster
Use Terraform configuration files to do it. 
* cd eks-cluster
* Change variables on the terraform.tfvars file
**Run the following terraform commands**
terraform init 
terraform plan 
terraform apply

#### Step 2: Update kubeconfig
* aws eks --region $(terraform output -raw t2s_services_region) update-kubeconfig \
--name $(terraform output -raw t2s_services_cluster_name)

#### Step 3: Create Namespace and name it jenkins
* kubectl get ns             # To verify
* kubectl create ns jenkins  # To create a namespace

#### Step 4: Installing Helm on Local Machine
* brew install helm 
* helm version # To verify

#### Step 5: Deploy SonarQube, Prometheus, Trivy, Grafana, and ELK
***Add Helm Repositories***
**Add SonarQube Helm repo**
* helm repo add sonarqube https://SonarSource.github.io/helm-chart-sonarqube

**Add Prometheus Helm repo**
* helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

**Add Grafana Helm repo**
* helm repo add grafana https://grafana.github.io/helm-charts

**Add Aqua Security Helm repo for Trivy**
* helm repo add aqua https://aquasecurity.github.io/helm-charts

**Add ELK Stack Helm repo (ElasticSearch, Logstash, Kibana)**
* helm repo add elastic https://helm.elastic.co

**Add the Jenkins Helm repository**
helm repo add jenkins https://charts.jenkins.io

**Update all Helm repositories**
* helm repo update

***Deploy SonarQube in its own namespace***
* helm install sonarqube sonarqube/sonarqube \
    --namespace sonarqube \
    --create-namespace \
    --set persistence.storageClass="gp2" \
    --set service.type=LoadBalancer

***Deploy SonarQube in its own namespace***
* helm install prometheus prometheus-community/prometheus \
    --namespace monitor \
    --create-namespace \
    --set nodeSelector.tool=prometheus \
    --set tolerations[0].key=tool \
    --set tolerations[0].operator=Equal \
    --set tolerations[0].value=prometheus \
    --set tolerations[0].effect=NoSchedule \
    --set server.service.type=LoadBalancer

***Deploy Prometheus, Grafana, and ELK in the monitor Namespace***
* helm install prometheus prometheus-community/prometheus \
    --namespace monitor \
    --create-namespace \
    --set nodeSelector.tool=prometheus \
    --set tolerations[0].key=tool \
    --set tolerations[0].operator=Equal \
    --set tolerations[0].value=prometheus \
    --set tolerations[0].effect=NoSchedule \
    --set server.service.type=LoadBalancer

* helm install grafana grafana/grafana \
    --namespace monitor \
    --set persistence.storageClassName="gp2" \
    --set adminPassword='admin' \
    --set service.type=LoadBalancer

****Deploy Elasticsearch****
* helm install elasticsearch elastic/elasticsearch \
    --namespace monitor \
    --set persistence.storageClass="gp2" \
    --set service.type=LoadBalancer

* helm install kibana elastic/kibana \
    --namespace monitor \
    --set service.type=LoadBalancer

* helm install logstash elastic/logstash \
    --namespace monitor \
    --set service.type=LoadBalancer

***Deploy Trivy in its own namespace***
* helm install trivy aqua/trivy-operator \
    --namespace trivy-system \
    --create-namespace \
    --set nodeSelector.tool=trivy \
    --set tolerations[0].key=tool \
    --set tolerations[0].operator=Equal \
    --set tolerations[0].value=trivy \
    --set tolerations[0].effect=NoSchedule

**Create a Namespace for Jenkins**
* kubectl create namespace jenkins

***Install Jenkins Using Helm***
* helm install jenkins jenkins/jenkins \
     --namespace jenkins \
     --set controller.serviceType=LoadBalancer \
     --set controller.jenkinsAdminUser=admin \
     --set controller.jenkinsAdminPassword=admin123

#### Step 6: Install SonarQube with Helm and on Its Dedicated Node
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

#### Step 7: Install Trivy with Helm and on Its Dedicated Node
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

#### Step 8: Install Prometheus with Helm and on Its Dedicated Node
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

#### Step 9: Install Grafana with Helm and on Its Dedicated Node
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

#### Step 10: Verify Deployments
* kubectl get pods -o wide -n sonarqube
* kubectl get pods -o wide -n trivy-system
* kubectl get pods -o wide -n monitoring
* kubectl get pods -o wide -n grafana

#### Step 11: Access the Services
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

# Step 12: Create and Deploy a Website as Image to ECR
* mkdir t2s-website
* cd t2s-website
* touch Dockerfile
***Add the following from the Dockerfile file***
* aws ecr create-repository --repository-name dev/t2s-services --region us-east-1 
* aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <AWS_Account_ID>.dkr.ecr.us-east-1.amazonaws.com 
* docker build -t dev/t2s-services .
* docker tag dev/t2s-services:latest <AWS_Account_ID>.dkr.ecr.us-east-1.amazonaws.com/dev/t2s-services:latest
* docker push <AWS_Account_ID>.dkr.ecr.us-east-1.amazonaws.com/dev/t2s-services:latest

#### Step 13: Create Kubernetes Deployment and Service
* touch website-deployment.yaml
***Add this content***
apiVersion: apps/v1
kind: Deployment
metadata:
  name: t2s-website
  labels:
    app: t2s-website
spec:
  replicas: 1
  selector:
    matchLabels:
      app: t2s-website
  template:
    metadata:
      labels:
        app: t2s-website
    spec:
      containers:
      - name: t2s-website
        image: <AWS_Account_ID>.dkr.ecr.us-east-1.amazonaws.com/dev/t2s-services:latest  # Replace with your Docker image repo
        ports:
        - containerPort: 80

* touch website-service.yaml
***Add this content***
apiVersion: v1
kind: Service
metadata:
  name: t2s-website-service
spec:
  type: LoadBalancer
  selector:
    app: t2s-website
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80

**Deploy the Website to EKS**
* kubectl apply -f website-deployment.yaml
* kubectl apply -f website-service.yaml

**Verifiy**
* kubectl get pods

**Get the external IP Address**
kubectl get svc

**Access the Website**
***Use the external IP from the Load Balancer. Open a browser and visit the IP to see your website. The message displayed will be:***
"Hello from T2S. Congratulations for having set up a complete infrastructure that is scalable, highly available, resilient, accessible, and cost-efficient. Great job!"

#### Step 14: Scale Up the Deployment
* kubectl scale deployment t2s-website --replicas=3

#### Step 15: Clean Up
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

