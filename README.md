Installing a Kubernetes cluster using kubeadm on 4 AWS EC2 instances (1 control plane, 2 worker nodes, and 1 to work as an Nginx LB instead of the AWS ALB or NLB) with the Nginx Ingress controller and deploying the Juice app.
# Notes
## Step 1: Kubernetes Cluster Using Kubeadm
- Initialize the infra in aws using terraform to create one master node and one worker node and one server to act as load balancer
```bash
cd terraform
terraform apply
```


## Step 2: Cluster Using Kubeadm
- Follow the steps in the "k8s (master & worker nodes) setup.txt" file to install the k8s in each node
- Follow the steps in the "nginx lb server setup.txt" file to install the nginx lb



## Step 3: isntall nginx ingress controller using helm after connecting to the cluster
```bash
helm install nginx-ingress ingress-nginx/ingress-nginx \
  --version 4.12.0 \
  --namespace ingress-nginx --create-namespace \
  --set controller.service.type=NodePort \
  --set controller.service.nodePorts.http=32767
```



## Step 4: isntall the juice app and its required ingress resource to access it externally from the nginx server ip
```bash
cd k8s-manifests
kubectl  apply -f .
```
