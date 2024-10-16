## Tools to Install:
* AWS CLI: To install and configure AWS CLI, go to https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
* EKSCTL: To install EKSCTL, go to https://eksctl.io/installation/ 
* KUBECTL: To install KUBECTL, go to https://kubernetes.io/docs/tasks/tools/
* HELM: To install Helm, go to https://helm.sh/docs/intro/install/ 

# Prerequisites
# Install AWS CLI
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /

brew tap weaveworks/tap
brew install weaveworks/tap/eksctl

# Step 1: Create EKS Cluster
Use Terraform configuration files to do it. 
* cd eks-cluster
* Change variables on the terraform.tfvars file
**Run the following terraform commands**
terraform init 
terraform plan 
terraform apply

# Step 2: Update kubeconfig
* aws eks --region $(terraform output -raw t2s_services_region) update-kubeconfig \
    --name $(terraform output -raw t2s_services_cluster_name)

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

# Step 11: Install Trivy with Helm and on Its Dedicated Node
* helm repo add aqua https://aquasecurity.github.io/helm-charts
* helm repo update
* helm install trivy aqua/trivy-operator \
    --namespace trivy-system \
    --create-namespace \
    --set nodeSelector.tool=trivy \
    --set tolerations[0].key=tool \
    --set tolerations[0].operator=Equal \
    --set tolerations[0].value=trivy \
    --set tolerations[0].effect=NoSchedule

# Step 12: Install Prometheus with Helm and on Its Dedicated Node
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

# Step 13: Install Grafana with Helm and on Its Dedicated Node
* helm repo add grafana https://grafana.github.io/helm-charts
* helm repo update
* helm install grafana grafana/grafana \
    --namespace monitoring \
    --set nodeSelector.tool=grafana \
    --set tolerations[0].key=tool \
    --set tolerations[0].operator=Equal \
    --set tolerations[0].value=grafana \
    --set tolerations[0].effect=NoSchedule \
    --set persistence.storageClass="gp2" \
    --set service.type=LoadBalancer

# Step 14: Verify Deployments
* kubectl get pods -o wide -n sonarqube
* kubectl get pods -o wide -n trivy-system
* kubectl get pods -o wide -n monitoring

# Step 15: Access the Tools
**These commands will provide the external IP addresses of SonarQube, Trivy, Prometheus, and Grafana.**
* kubectl get svc -n sonarqube
* kubectl get svc -n trivy-system
* kubectl get svc -n monitoring

# Step 16: Create and Deploy a Website
* mkdir t2s-website
* cd t2s-website
* touch Dockerfile
***Add the following***
FROM nginx:alpine

RUN echo '<html><body><h1>Hello from T2S. Congratulations for having set up a complete infrastructure that is scalable, highly available, resilient, accessible, and cost-efficient. Great job!</h1></body></html>' > /usr/share/nginx/html/index.html

* docker build -t t2s-website .
* docker tag t2s-website <your-repo>/t2s-website:latest
* docker push <your-repo>/t2s-website:latest

# Step 17: Create Kubernetes Deployment and Service
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
        image: <your-repo>/t2s-website:latest  # Replace with your Docker image repo
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

# Step 18: Scale Up the Deployment
* kubectl scale deployment t2s-website --replicas=3


# Clean Up
**Run the terraform destroy command**
**In case you get an error message, go to the console to manually delte the vpc.** 
* terraform destroy

