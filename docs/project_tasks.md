# Project Tasks

1. [X] Kubernetes YAML File
	1. 3 parts of a Kubernetes configuration file
	2. Blueprint for pods (template)
	3. Connecting Deployment to Pods
	4. Nginx deployment
2. [x] Complete Application Deployment
	1. MongoDB
	2. Mongo Express
	3. Nginx
3. [x] Kubernetes Namespaces
	1. Default Namespaces
	2. Create Namespaces
	3. Create pods in each namespace
4. [x] Kubernetes Services
	1. Kubernetes Service
	2. Multi-Port Service
5. [x] Helm - Kubernetes
	1. Install Helm
	2. Install an Example Chart
6. [x] Kubernetes Ingress
	1. Human readable url for the Nginx website
	2. TLS Certificate
	3. Redirect to HTTPS
7. [x] Kubernetes Volumes (Persistent Volume)
	1. Persistent Volume (PV)
	2. Local vs Remote Storage
	3. Persistent Volume Claim (PVC)
	4. Storage Class (SC)
8. [x] ConfigMap and Secrets as Kubernetes Volumes
	1. Creating individual values (key-value pairs) for env variables
9. [x] StatefulSet
	1. StatefulSet: stateful applications
	2. Replicating stateful applications
	3. Scaling database applications
10. [x] Prometheus Monitoring
	1. Setup Prometheus Operator via Helm
	2. Access Grafana UI
	3. Access Prometheus UI
11. [x] Kubernetes Operator
	1. Stateful applications with Kubernetes Operator
12. [x] Prometheus Exporter (Monitoring)
	1. Monitor MongoDB metrics
	2. Prometheus Operator
	3. ServiceMonitor
	4. MongoDB Exporter
	5. See new target in Prometheus UI
	6. See MongoDB metrics data in Grafana UI
13. [ ] Kubernetes Security
	1. [x] Cluster
		1. Resource Quotas
		2. Configure Default Memory Requests and Limits for a Namespace
		3. Declare Network Policy
	2. [ ] Control Plane
		1. [x] Admission Control
		2. [x] Auditing
		3. [ ] Validating Admission Policy
		4. [ ] API Authentication
		5. [ ] API Authorization
		6. [ ] Restrict access to etcd
		7. [ ] Encrypting Confidential Data at Rest
		8. [ ] Controlling Access to the Kubernetes API (kube-apiserver)
		9. [ ] Manage TLS Certificates in a Cluster
	3. [ ] Node
		1. [ ] Kubelet authentication/authorization
	4. [x] Pod
		1. Pod Security Standards
		2. Network Policies
		3. Pod Security Admission
		4. Configure a Security Context for a Pod or Container
		5. Assigning Pods to Nodes
		6. Taints and Tolerations