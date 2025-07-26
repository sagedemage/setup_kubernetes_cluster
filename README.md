# setup_kubernetes_cluster

Setup a Kubernetes cluster with MongoDB, Mongo Express, Nginx, Prometheus, and Grafana

## Minikube Commands

[Minikube Commands](./docs/minikube_commands.md)

## Add your user to docker group

Create the docker group
```
sudo groupadd docker
```

Add your user to the docker group
```
sudo usermod -aG docker $USER
```

Activate the changes to the group
```
newgrp docker
```

Verify docker commands run without sudo
```
docker run hello-world
```

## Kubctl Commands

[Kubctl Commands](./docs/kubctl_commands.md)

## Useful commands
Create base64 encoded values for credentials
```
echo -n 'username' | base64
echo -n 'password' | base64
```

Copy the values in the secret file (mongodb-secret.yaml)

## Setup the cluster

Start a cluster using Docker. It is recommended to use docker as the driver.
```
minikube start --driver=docker --cpus=4 --memory=4g --disk-size=20g --cni=cilium --nodes 2 -p worker
```

Deploy the Nginx deployment
```
kubectl apply -f deployments/nginx-config.yaml
```

Deploy the Nginx service
```
kubectl apply -f services/nginx-service.yaml
```

Deploy the secret
```
kubectl apply -f secrets/mongodb-secret.yaml
```

Deploy the MongoDB deployment
```
kubectl apply -f deployments/mongodb-config.yaml
```

Deploy the MongoDB service
```
kubectl apply -f services/mongodb-service.yaml
```

Deploy the configmap
```
kubectl apply -f configmaps/mongo-configmap.yaml
```

Deploy Mongo Express deployment
```
kubectl apply -f deployments/mongo-express.yaml
```

Deploy Mongo Express service
```
kubectl apply -f services/mongo-express-service.yaml
```

Create the development namespace
```
kubectl create -f namespaces/namespace-dev.yaml
```

Create the production namespace
```
kubectl create -f namespaces/namespace-prod.yaml
```

Get current context
```
kubectl config current-context
```

In my case, my current context is minikube

Define development context
```
kubectl config set-context dev --namespace=development --cluster=worker --user=worker
```

Define production context
```
kubectl config set-context prod --namespace=production --cluster=worker --user=worker
```

Deploy the Ingress-Nginx controller
```
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace
```

Install the ingress controller via the minikube's addons system
```
minikube addons enable ingress
```

Create the StorageClass for local storage
```
kubectl apply -f storageclasses/fast-storage-storageclass.yaml
```

Create the PersistentVolume and PersistentVolumeClaim for MongoDB
```
kubectl apply -f pv-pvc/mongo-pv-pvc.yaml
```

Generate the mongodb-keyfile via openssl
```
bash -c "openssl rand -base64 756 > keyfiles/mongodb-keyfile"
```

Create Kubernetes secret to store the keyfile
```
kubectl create secret generic mongodb-keyfile --from-file=keyfiles/mongodb-keyfile
```

Apply the StatefulSet to your cluster
```
kubectl apply -f statefulsets/mongo-statefulset.yaml
```

Create the PersistentVolume and PersistentVolumeClaim for storing backups
```
kubectl apply -f pv-pvc/backup-pv-pvc.yaml
```

Create the CronJob for backing up MongoDB automatically using mongodump
```
kubectl apply -f cronjobs/mongodb-backup-cronjob.yaml
```

Create a pod to access backup files
```
kubectl apply -f pods/backup-access.yaml
```

Add the helm chart repository for Metrics Server
```
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/ -n kube-system
```

Install the Metrics Server helm chart
```
helm upgrade --install metrics-server metrics-server/metrics-server -n kube-system
```

Containers in the Metrics Server are not running due to TLS certificate issues. To resolve this, execute the command to patch the metrics server deployment to bypass TLS verification with a patch file
```
kubectl patch deployment metrics-server --patch-file patches/metrics_server_deployment.yaml -n kube-system
```

Define an HPA resource that specifies how and when to scale the MongoDB staefulset using the command
```
kubectl autoscale statefulset mongo-sfs --min=3 --max=10 --cpu-percent=50
```

Add the prometheus-community helm chart
```
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
```

Install kube-prometheus-stack using helm chart
```
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack
```

Apply the config for the prometheus-server-ext-service service
```
kubectl apply -f services/prometheus-server-ext-service.yaml
```

Apply the grafana-ext-service service
```
kubectl apply -f services/grafana-ext-service.yaml
```

Install the Prometheus MongoDB Exporter
```
helm install prometheus-mongodb-exporter prometheus-community/prometheus-mongodb-exporter -f mongodb-exporter/values.yaml
```

To access the Prometheus MongoDB Exporter, apply the prometheus-mongodb-exporter-ext-service service config
```
kubectl apply -f services/prometheus-mongodb-exporter-ext-service.yaml
```

Create low, medium, and high priority classes
```
kubectl apply -f priorityclasses/
```

Create quota object which matches it with pods at specific priorities
```
kubectl apply -f resourcequotas/quota.yaml
```

Create the LimitRange in the namespace
```
kubectl apply -f limitranges/mem_limit_range.yaml --namespace=development
```

Install Cilium into the Kubernetes cluster
```
cilium install
```

Create the access-mongodb network policy to limit access to the mongodb-service service
```
kubectl apply -f networkpolicies/mongodb-policy.yaml
```

### Setup the cluster via the manage_cluster.bash script

[Setup the cluster via the manage_cluster script](./docs/setup_the_cluster_via_the_manage_cluster_script.md)

## Default username and password for Mongo Express

username: admin
password: pass

## Ingress-Nginx Controller Setup

[Ingress-Nginx Controller Setup](./docs/ingress-nginx_controller_setup.md)

## firewall-cmd commands

[firewall-cmd commands](./docs/firewall-cmd_commands.md)

## Verify the backup of MongoDB via mongodump works

Get the name of the pod of the mongodb-backup
```
kubectl get pods
```

Verify the backup was created successfully
```
kubectl logs mongodb-backup-29200222-j48wk
```

Access the backup-access pod
```
kubectl exec -it backup-access -- bash
```

Inside the pod, navigate the /backup directory to view the backup files
```
cd /backup
ls
```

## Add a movie to MongoDB

[Add a movie to MongoDB](./docs/add_a_movie_to_mongodb.md)

## mongosh commands

[mongosh commands](./docs/mongosh_commands.md)

## Restore MongoDB via a backup

Simulate a failure
```
kubectl delete deployment mongodb-deployment
```

Start up the mongodb deployment
```
kubectl apply -f deployments/mongodb-config.yaml
```

Go inside the backup-access pod in a terminal
```
kubectl exec -it backup-access -- bash
```

Restore a dump of MongoDB to recover the database after a failure or crash
```
mongorestore --host=mongodb-service --port 27017 backup/2025-07-08T21-50-01/ --username <your_username> --password <your_password>
```

## Configure replica set for MongoDB

Go to one of the Mongo StatefulSet pods. Usually, you would use the first pod (ex: mongo-sfs-0).
```
kubectl exec -it mongo-sfs-0 -- mongosh
```

Initialize the replica set
```
rs.initiate({
  _id: "rs0",
  members: [
    { _id: 0, host: "mongo-sfs-0.mongo-sfs-service.development.svc.cluster.local:27017", priority: 2 },
    { _id: 1, host: "mongo-sfs-1.mongo-sfs-service.development.svc.cluster.local:27017", priority: 1 },
    { _id: 2, host: "mongo-sfs-2.mongo-sfs-service.development.svc.cluster.local:27017", priority: 1 }
  ]
})
```

Run the command if you want to initialize the replica set via a query file
```
kubectl exec -it mongo-sfs-0 -- mongosh < mongosh/query.js && echo ""
```

To get the hostnames that maps to the pods' IP address for the mongo-sfs-0, mongo-sfs-1, and mongo-sfs-2 pods, use these commands
```
kubectl exec -it mongo-sfs-0 -- bash -c "cat /etc/hosts"
kubectl exec -it mongo-sfs-1 -- bash -c "cat /etc/hosts"
kubectl exec -it mongo-sfs-2 -- bash -c "cat /etc/hosts"
```

Reconfigure the replica set if it had been initialized
```
rs.reconfig({
  _id: "rs0",
  members: [
    { _id: 0, host: "mongo-sfs-0.mongo-sfs-service.development.svc.cluster.local:27017", priority: 2 },
    { _id: 1, host: "mongo-sfs-1.mongo-sfs-service.development.svc.cluster.local:27017", priority: 1 },
    { _id: 2, host: "mongo-sfs-2.mongo-sfs-service.development.svc.cluster.local:27017", priority: 1 }
  ]
},
{
  "force" : true,
  "maxTimeMS" : 0
})
```

To check if the pod is primary, use this command
```
rs.status()
```

## Test failover and recovery processes

Identify the current primary node
```
kubectl exec -it mongo-sfs-0 -- mongosh --eval "rs.status()"
```

Look for the memeber with the stateStr: 'PRIMARY' attribute
```
{
      _id: 0,
      name: 'mongo-sfs-0.mongo-sfs-service.development.svc.cluster.local:27017',
      health: 1,
      state: 1,
      stateStr: 'PRIMARY',
      ...
}
```

Delete the current primary node pod to simulate a failure
```
kubectl delete pod mongo-sfs-0
```

Monitor the status of the replica set. There will be an election of a new primary
```
kubectl exec -it mongo-sfs-1 -- mongosh --eval "rs.status()"
```

You will notice that one of the secondary nodes has been promoted to primary
```
{
      _id: 1,
      name: 'mongo-sfs-1.mongo-sfs-service.development.svc.cluster.local:27017',
      health: 1,
      state: 1,
      stateStr: 'PRIMARY',
      ...
}
```

Verify that the deleted pod has been recreated. The deleted pod will rejoin the replica set as a secondary node:
```
kubectl get pods
```

Confirm that the pod, mongo-sfs-0, is back and running
```
NAME                                  READY   STATUS      RESTARTS      AGE
mongo-sfs-0                           1/1     Running     0             56s
mongo-sfs-1                           1/1     Running     1 (13m ago)   21h
mongo-sfs-2                           1/1     Running     1 (13m ago)   21h
```

Check the replica set status again. You want to make sure that the new node is now re-elected as the primary because
it had the highest priority
```
kubectl exec -it mongo-sfs-0 -- mongosh --eval "rs.status()"
```

You should have something like this
```
{
      _id: 0,
      name: 'mongo-sfs-0.mongo-sfs-service.development.svc.cluster.local:27017',
      health: 1,
      state: 1,
      stateStr: 'PRIMARY',
      ...
}
```

## Configure automatic scaling

Add the helm chart repository for Metrics Server
```
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/ -n kube-system
```

Install the Metrics Server helm chart
```
helm upgrade --install metrics-server metrics-server/metrics-server -n kube-system
```

View the status of the metrics server pods
```
kubectl get pods -n kube-system
```

You should see the following
```
NAME                               READY   STATUS    RESTARTS        AGE
...
metrics-server-867d48dc9c-q7dsh    0/1     Running   0               2s
...
```

Containers in the Metrics Server are not running due to TLS certificate issues. To resolve this, execute the command to patch the metrics server deployment to bypass TLS verification with a patch file
```
kubectl patch deployment metrics-server --patch-file patches/metrics_server_deployment.yaml -n kube-system
```

Verify the metrics-server deployment config is correct
```
kubectl get deployment metrics-server -n kube-system -o yaml
```

The config should look like this
```
...
spec:
  containers:
  - args:
    ...
    command:
    - /metrics-server
    - --kubelet-insecure-tls
    - --kubelet-preferred-address-types=InternalIP
    image: registry.k8s.io/metrics-server/metrics-server:v0.8.0
...
```

After making changes, confirm that the containers are running by running the command
```
kubectl get pods -n kube-system
```

You should see the following output
```
NAME                               READY   STATUS    RESTARTS        AGE
...
metrics-server-6ccbbf7bbc-bvmg6    1/1     Running   0               2m33s
...
```

Check the resource usage of the pods in the cluster
```
kubectl top pods
```

Here is something you would see
```
NAME                                  CPU(cores)   MEMORY(bytes)
alpine                                0m           1Mi
backup-access                         0m           0Mi
mongo-express-66dc884689-stlzr        1m           125Mi
mongo-sfs-0                           21m          227Mi
mongo-sfs-1                           21m          224Mi
mongo-sfs-2                           21m          233Mi
mongodb-deployment-6d9d7c68f6-mrptm   14m          496Mi
nginx-deployment-5fbdcbb6d5-2rrhq     0m           7Mi
nginx-deployment-5fbdcbb6d5-5qggg     0m           20Mi
```

Define an HPA resource that specifies how and when to scale the MongoDB statefulset using the command
```
kubectl autoscale statefulset mongo-sfs --min=3 --max=10 --cpu-percent=50
```

The configuration will seth the minimum number of replicas to 3 and allow scaling up to a maximum of
10 replicas based on CPU utilization

You should see the following output
```
horizontalpodautoscaler.autoscaling/mongo-sfs autoscaled
```

Monitor the status of the HPA using the command
```
kubectl get hpa
```

This will show you the current status of the HPA which includes the current number of replicas and the metrics used for scaling
```
NAME        REFERENCE               TARGETS        MINPODS   MAXPODS   REPLICAS   AGE
mongo-sfs   StatefulSet/mongo-sfs   cpu: 19%/50%   3         10        3          101s
```

## Set default text editor for kubectl edit

Set default text editor for kubectl edit, add this to ~/.bashrc
```
export KUBE_EDITOR=vim
```

## Setup Monitoring a Cluster with Prometheus and Grafana

### Setup Prometheus

Add the prometheus-community helm chart
```
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
```

Install kube-prometheus-stack using helm chart
```
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack
```

Run this command to check to see if it installed correctly
```
kubectl get pods
```

You should see something like this
```
NAME                                                        READY   STATUS      RESTARTS        AGE
alertmanager-kube-prometheus-stack-alertmanager-0           2/2     Running     0               2m1s
...
kube-prometheus-stack-grafana-748cbc5458-rvtht              3/3     Running     0               2m3s
kube-prometheus-stack-kube-state-metrics-684f8c7558-c5lpb   1/1     Running     0               2m3s
kube-prometheus-stack-operator-5cfbc8b784-hn6vg             1/1     Running     0               2m3s
kube-prometheus-stack-prometheus-node-exporter-cvsmx        1/1     Running     0               2m3s
...
prometheus-kube-prometheus-stack-prometheus-0               2/2     Running     0               2m
...
```

Let's take a look at all the services that have been deployed with Prometheus
```
kubectl get service
```

You should see something like this
```
NAME                                             TYPE           CLUSTER-IP       EXTERNAL-IP      PORT(S)                      AGE
alertmanager-operated                            ClusterIP      None             <none>           9093/TCP,9094/TCP,9094/UDP   3m42s
...
kube-prometheus-stack-alertmanager               ClusterIP      10.105.15.245    <none>           9093/TCP,8080/TCP            3m44s
kube-prometheus-stack-grafana                    ClusterIP      10.99.230.183    <none>           80/TCP                       3m44s
kube-prometheus-stack-kube-state-metrics         ClusterIP      10.104.129.206   <none>           8080/TCP                     3m44s
kube-prometheus-stack-operator                   ClusterIP      10.111.227.149   <none>           443/TCP                      3m44s
kube-prometheus-stack-prometheus                 ClusterIP      10.101.147.184   <none>           9090/TCP,8080/TCP            3m44s
kube-prometheus-stack-prometheus-node-exporter   ClusterIP      10.96.23.75      <none>           9100/TCP                     3m44s
...
prometheus-operated                              ClusterIP      None             <none>           9090/TCP                     3m41s
```

Port forward to 9090 to get the Prometheus UI
```
kubectl port-forward prometheus-kube-prometheus-stack-prometheus-0 9090
```

Apply the config for the prometheus-server-ext-service service
```
kubectl apply -f services/prometheus-server-ext-service.yaml
```

Run the command to see a new entry called prometheus-server-ext-service.
```
kubectl get service
```

You should see something like this:
```
NAME                                  TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE
...
prometheus-server-ext-service         NodePort       10.98.119.17     <none>           80:30517/TCP                 7s
```

Run the command to get the IP address of the node
```
minikube ip
```

Go to this link to access the Prometheus Server UI. The URL consists of the IP address of the node and
the port of the prometheus-server-ext service. In my case, the url is http://192.168.49.2:30517.

This is what Prometheus UI looks like

![prometheus ui](./screenshots/prometheus_ui.png)

#### Queries in Prometheus UI

Type the `node_memory_Active_bytes` metric, which gets the memory consumption of each of the Nodes in the cluster. Press the Execute button to run the query. The results will be displayed in a table that shows the query's raw output:

![run prometheus query](./screenshots/run_prometheus_query.png)

Switch to the Graph tab to see the visualization of the metric over time.

![graph visualization prometheus](./screenshots/graph_visualization_prometheus.png)

### Setup Grafana

Run the command to get admin user password
```
kubectl --namespace development get secrets kube-prometheus-stack-grafana -o jsonpath="{.data.admin-password}" | base64 -d ; echo
```

Run the command get the Grafana URL to visit
```
kubectl port-forward deployment/kube-prometheus-stack-grafana 3000
```

Run the command to see the Grafana service
```
kubectl get service
```

You should see something like this
```
NAME                                             TYPE           CLUSTER-IP       EXTERNAL-IP      PORT(S)                      AGE
...
kube-prometheus-stack-grafana                    ClusterIP      10.99.230.183    <none>           80/TCP                       33m
...
```

Apply the grafana-ext-service service
```
kubectl apply -f services/grafana-ext-service.yaml
```

Run the command to see a new entry called grafana-ext-service
```
kubectl get service
```

You should see something like this
```
NAME                                  TYPE           CLUSTER-IP       EXTERNAL-IP      PORT(S)                      AGE
...
grafana-ext-service                   NodePort       10.108.112.252   <none>           80:31825/TCP                 3h27m
...
```

Go to this link to access the Grafana dashboard. The URL consists of the IP address of the node and
the port of the grafana-ext service. In my case, the url is http://192.168.49.2:31825.

This is what the Grafana home page looks like

![grafana home page](./screenshots/grafana_home_page.png)

#### Configure monitoring applications

You got to create Prometheus as a data source for Grafana. This allows Grafana to retrieve metrics from Prometheus to create
the graphs that will be used to visualize cluster metrics.

Create the first dashboard tile. Then from the list of options presented, select Prometheus.

Add the URL for the Prometheus server URL field
```
http://192.168.49.2:30517
```

![prometheus server url field](./screenshots/prometheus_server_url_field.png)

Save and test to see it works. This will save the configuration and test if the data source is working.

![save and test grafana configuration](./screenshots/save_and_test_grafana_configuration.png)

Let's create a dashboard to visualize the data, go to the menu and select "Dashboards".

To do this, input the ID of the dashboard into the text field. The ID being used is 3662. Click the Load button.

![import dashboard grafana](./screenshots/import_dashboard_grafana.png)

Set the name for the dashboard to Prometheus-v1 and set the Prometheus option for the Data Source.

![set name of dashboard grafana](./screenshots/set_name_of_dashboard_grafana.png)

Select import and you will see the dashboard that has been generated.

![generated dashboard grafana](./screenshots/generated_dashboard_grafana.png)

This retrieves information from the Minikube cluster. The dashboard has a predefined template that runs queries
(PromQL quereis). These queries run against the cluster and provides these metrics.

## helm commands

[helm commands](./docs/helm_commands.md)

## Setup the Prometheus MongoDB Exporter

See all configurable options, run the command
```
helm show values prometheus-community/prometheus-mongodb-exporter
```

Install the Prometheus MongoDB Exporter
```
helm install prometheus-mongodb-exporter prometheus-community/prometheus-mongodb-exporter -f mongodb-exporter/values.yaml
```

Uninstall the Prometheus MongoDB Exporter if something is wrong
```
helm uninstall prometheus-mongodb-exporter
```

Make sure the prometheus-mongodb-exporter pod is available
```
kubectl get pod
```

You should see something like this
```
NAME                                                     READY   STATUS    RESTARTS       AGE
...
prometheus-mongodb-exporter-5cf876c6d9-5djmh             1/1     Running   0              94s
...
```

Make sure the prometheus-mongodb-exporter service is available
```
kubectl get service
```

You should see something like this
```
NAME                                             TYPE           CLUSTER-IP       EXTERNAL-IP      PORT(S)                      AGE
...
prometheus-mongodb-exporter                      ClusterIP      10.96.130.12     <none>           9216/TCP                     15m
...
```

Make sure that the prometheus-mongodb-exporter service monitor is available
```
kubectl get servicemonitor
```

You should see something like this
```
NAME                                                 AGE
prometheus-mongodb-exporter                          2s
...
```

Verify the application is working by running these commands

Port forward the prometheus-mongodb-exporter service
```
kubectl port-forward service/prometheus-mongodb-exporter 9216
```

Curl the metrics of the Prometheus MongoDB Exporter
```
curl http://127.0.0.1:9216/metrics
```

To access the Prometheus MongoDB Exporter, apply the prometheus-mongodb-exporter-ext-service service config
```
kubectl apply -f services/prometheus-mongodb-exporter-ext-service.yaml
```

Check for the prometheus-mongodb-exporter-ext-service service
```
kubectl get service
```

You should see something like this
```
NAME                                             TYPE           CLUSTER-IP       EXTERNAL-IP      PORT(S)                      AGE
...
prometheus-mongodb-exporter-ext-service          NodePort       10.110.114.113   <none>           80:30560/TCP                 8m33s
...
```

Get the IP address of the Prometheus MongoDB Exporter pod
```
kubectl get pod -o wide | grep "prometheus-mongodb-exporter"
```

You should see something like this
```
prometheus-mongodb-exporter-776dcb4c8-kgp54                 1/1     Running     0                26m     10.244.3.88    minikube   <none>           <none>
```

Curl the metrics of the Prometheus MongoDB Exporter pod
```
kubectl run --rm -it --tty pingkungcurl1 --image=curlimages/curl --restart=Never -- 10.244.3.88:9216/metrics
```

## Security
### Resource Quotas

Create low, medium, and high priority classes
```
kubectl apply -f priorityclasses/
```

Create quota object which matches it with pods at specific priorities
```
kubectl apply -f resourcequotas/quota.yaml
```

Very the used stats for `pods-low` and `pods-medium` priority quotas has changed but not `pods-high` quota
```
kubectl describe quota
```

You should see something like this
```
Name:       pods-high
Namespace:  development
Resource    Used  Hard
--------    ----  ----
cpu         0     2
memory      0     2Gi
pods        0     10


Name:       pods-low
Namespace:  development
Resource    Used   Hard
--------    ----   ----
cpu         500m   500m
memory      500Mi  500Mi
pods        1      10


Name:       pods-medium
Namespace:  development
Resource    Used  Hard
--------    ----  ----
cpu         1     1
memory      1Gi   1Gi
pods        1     10
```

### Configure Default Memory Requests and Limits for a Namespace

Create the LimitRange in the namespace
```
kubectl apply -f limitranges/mem_limit_range.yaml --namespace=development
```

Create the MySQL Pod
```
kubectl apply -f pods/default-mem-demo.yaml --namespace=development
```

View detailed information about the MySQL Pod
```
kubectl get pod default-mem-demo -o=yaml --namespace=development
```

Your output should look something like this
```
...
containers:
...
  image: mysql:lts
  imagePullPolicy: Always
  name: default-mem-demo-ctr
  resources:
    limits:
      memory: 512Mi
    requests:
      memory: 256Mi
...
```

Delete the MySQL Pod
```
kubectl delete pod default-mem-demo --namespace=development
```

### Install the Cilium Network Policy Provider

Make sure to start up a minikube cluster prepared for installing cilium with the --cni flag
```
minikube start --driver=docker --cpus=4 --memory=4g --disk-size=20g --cni=cilium --nodes 2 -p worker
```

Install Cilium into the Kubernetes cluster
```
cilium install
```

### Declare Network Policy
#### Test the connection of the mongodb-deployment pod by accessing it from another Pod

Run an nmap command to check if the mongodb-deployment pod is available and the port 27017 is open
```
kubectl run --image=appsoa/docker-alpine-nmap --rm -it nm -- -Pn -p 27017 10.0.0.100
```

Should get something like this
```
Nmap scan report for 10.0.0.100
Host is up (0.000082s latency).
PORT      STATE SERVICE
27017/tcp open  mongod

Nmap done: 1 IP address (1 host up) scanned in 0.29 seconds
```

#### Limit access to the mongodb-deployment pod

Create the access-mongodb network policy to limit access to the mongodb-service service
```
kubectl apply -f networkpolicies/mongodb-policy.yaml
```

Run an nmap command to check if the mongodb-deployment pod is available and the port 27017 is open
```
kubectl run --image=appsoa/docker-alpine-nmap --rm -it nm -- -Pn -p 27017 10.0.0.100
```

Should get something like this
```
Nmap scan report for 10.0.0.100
Host is up.
PORT      STATE    SERVICE
27017/tcp filtered mongod

Nmap done: 1 IP address (1 host up) scanned in 2.09 seconds
```

Set the correct labels to make the mongodb-deployment pod available and the port 27017 open
```
kubectl run --image=appsoa/docker-alpine-nmap --rm -it nm --labels="access=true" -- -Pn -p 27017 10.0.0.100
```

You should see something like this
```
Nmap scan report for 10.0.0.100
Host is up (0.000075s latency).
PORT      STATE SERVICE
27017/tcp open  mongod

Nmap done: 1 IP address (1 host up) scanned in 0.27 seconds
```

If for some reason Network Policies do not work, try stopping and starting minikube for the Network Policies to take affect
```
minkube stop
./manage_cluster.bash start-minikube
```

### Admission Control in Kubernetes

Get the name of the kube-apiserver pod
```
kubectl get -n kube-system pods | grep kube-apiserver
```

Run kube-apiserver commands in the kube-apiserver-worker pod
```
kubectl exec -it kube-apiserver-worker -n kube-system -- kube-apiserver -h
```

See which admision plugins are enabled
```
kubectl exec -it kube-apiserver-worker -n kube-system -- kube-apiserver -h | grep enable-admission-plugins
```

Here are the default admission plugins

1. CertificateApproval
2. CertificateSigning
3. CertificateSubjectRestriction
4. ClusterTrustBundleAttest
5. DefaultIngressClass
6. DefaultStorageClass
7. DefaultTolerationSeconds
8. LimitRanger
9. MutatingAdmissionPolicy
10. MutatingAdmissionWebhook
11. NamespaceLifecycle
12. PersistentVolumeClaimResize
13. PodSecurity
14. PodTopologyLabels
15. Priority
16. ResourceQuota
17. RuntimeClass
18. ServiceAccount
19. StorageObjectInUseProtection
20. TaintNodesByCondition
21. ValidatingAdmissionPolicy
22. ValidatingAdmissionWebhook

### Auditing

Copy the `policies/audit-policy.yaml` file to `/etc/kubernetes/audit-policy.yaml`
```
minikube cp policies/audit-policy.yaml worker:/etc/kubernetes/audit-policy.yaml -p worker
```

SSH into the minikube cluster
```
minikube ssh -p worker
```

Login as root
```
sudo su
```

Install vim
```
apt update
apt install vim
```

Specify the audit policy file path in `/etc/kubernetes/manifests/kube-apiserver.yaml`
```
vim /etc/kubernetes/manifests/kube-apiserver.yaml
```

Add the **--audit-policy-file** flag to specify the `/etc/kubernetes/audit-policy.yaml` file and
add the **--audit-log-path** flag to specify the `/var/log/kubernetes/audit/audit.log` path
to spec.containers.command.
```
...
spec:
  containers:
  - command:
    - --audit-policy-file=/etc/kubernetes/audit-policy.yaml
    - --audit-log-path=/var/log/kubernetes/audit/audit.log
...
```

We need to mount the directory where the logs will be stored in the Kubernetes API server pod’s server directory so that it can see it.

For spec.containers.volumeMounts:
```
spec:
  containers:
    volumeMounts:
    ...
    - mountPath: /etc/kubernetes/audit-policy.yaml
      name: audit
      readOnly: true
    - mountPath: /var/log/kubernetes/audit/
      name: audit-log
      readOnly: false
```

For spec.volumes
```
spec:
  volumes:
  - hostPath:
      path: /etc/kubernetes/audit-policy.yaml
      type: File
    name: audit
  - hostPath:
      path: /var/log/kubernetes/audit/
      type: DirectoryOrCreate
    name: audit-log
```

Stop minikube
```
minikube -p worker stop
```

Start minikube
```
./manage_cluster.bash start-minikube
```

See the resulting log file
```
sudo tail -n 5 /var/log/kubernetes/audit/audit.log
```

### Assigning Pods to Nodes using Node Affinity

List nodes in your cluster with their labels
```
kubectl get nodes --show-labels
```

Add a label to the worker-m02 node
```
kubectl label nodes worker-m02 servertype=mongodb
```

Verify the chosen node has `servertype=mongodb` label
```
kubectl get nodes --show-labels
```

In deployments/mongodb-config.yaml, specify the Pod to the worker-m02 node using Node Affinity
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mongodb-deployment
  labels:
    apps: mongodb
spec:
  template:
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: servertype
                operator: In
                values:
                - mongodb
```

Apply the mongodb-deployment deployement
```
kubectl apply -f deployments/mongodb-config.yaml
```

Verify the node is running on your chosen node
```
kubectl get pods --output=wide
```

Make sure the mongodb-deployment pod is in the worker-m02 node
```
NAME                                                        READY   STATUS
mongodb-deployment-6f6574b48-7rwmq                          1/1     Running     0          45m     10.244.1.208   worker-m02   <none>           <none>
```


## Resources
* [Kubernetes Documentation](https://kubernetes.io/docs/home/)
  * [Viewing Pods and Nodes](https://kubernetes.io/docs/tutorials/kubernetes-basics/explore/explore-intro/)
  * [Run a Stateless Application Using a Deployment](https://kubernetes.io/docs/tasks/run-application/run-stateless-application-deployment/)
  * [Namespaces Walkthrough](https://kubernetes.io/docs/tutorials/cluster-management/namespaces-walkthrough/)
  * [Resource Quotas](https://kubernetes.io/docs/concepts/policy/resource-quotas/)
  * [Declare Network Policy](https://kubernetes.io/docs/tasks/administer-cluster/declare-network-policy/)
  * [Use Cilium for NetworkPolicy](https://kubernetes.io/docs/tasks/administer-cluster/network-policy-provider/cilium-network-policy/)
  * [Admission Control in Kubernetes](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/)
  * [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
  * [Pod Security Admission](https://kubernetes.io/docs/concepts/security/pod-security-admission/)
  * [Auditing](https://kubernetes.io/docs/tasks/debug/debug-cluster/audit/)
* [minikube Documentation](https://minikube.sigs.k8s.io/docs/)
  * [Basic controls](https://minikube.sigs.k8s.io/docs/handbook/controls/)
  * [minikube cp](https://minikube.sigs.k8s.io/docs/commands/cp/)
  * [Using Multi-Node Clusters](https://minikube.sigs.k8s.io/docs/tutorials/multi_node/)
  * [Assign Pods to Nodes using Node Affinity](https://kubernetes.io/docs/tasks/configure-pod-container/assign-pods-nodes-using-node-affinity/)
* [Linux post-installation steps for Docker Engine](https://docs.docker.com/engine/install/linux-postinstall/)
* [mongo-express Docker image](https://hub.docker.com/_/mongo-express)
* [Installation Guide - Ingress-Nginx Controller](https://kubernetes.github.io/ingress-nginx/deploy/)
* [Ensuring High Availability for MongoDB on Kubernetes - MongoDB](https://www.mongodb.com/developer/products/mongodb/mongodb-with-kubernetes/)
* [How to Create a Database in MongoDB - MongoDB](https://www.mongodb.com/resources/products/fundamentals/create-database)
* [How To Use the MongoDB Shell - DigitalOcean](https://www.digitalocean.com/community/tutorials/how-to-use-the-mongodb-shell)
* [Delete Documents - MongoDB](https://www.mongodb.com/docs/mongodb-shell/crud/delete/)
* [db.collection.drop() (mongosh method) - MongoDB](https://www.mongodb.com/docs/manual/reference/method/db.collection.drop/)
* [db.dropDatabase() (mongosh method) - MongoDB](https://www.mongodb.com/docs/manual/reference/method/db.dropDatabase/)
* [deleting minikube cluster so I can create a larger cluster with more CPUs - Stack Overflow](https://stackoverflow.com/questions/72147700/deleting-minikube-cluster-so-i-can-create-a-larger-cluster-with-more-cpus#:~:text=I%20run%20minikube%20with%20--,294)
* [Kubernetes Metrics Server](https://kubernetes-sigs.github.io/metrics-server/)
* [Monitoring a Kubernetes Cluster using Prometheus and Grafana - Medium](https://medium.com/@akilblanchard09/monitoring-a-kubernetes-cluster-using-prometheus-and-grafana-8e0f21805ea9)
* [prometheus-community/helm-charts GitHub repository](https://github.com/prometheus-community/helm-charts)
* [grafana/helm-charts GitHub repository](https://github.com/grafana/helm-charts)
* [Prometheus Monitoring for Kubernetes Cluster [Tutorial] - spacelift](https://spacelift.io/blog/prometheus-kubernetes)
* [prometheus-community/prometheus-mongodb-exporter - Artifact Hub](https://artifacthub.io/packages/helm/prometheus-community/prometheus-mongodb-exporter)
* [kube-prometheus-stack - prometheus-community/helm-charts GitHub repository](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
* [Cilium Quick Installation - docs.cilium.io](https://docs.cilium.io/en/stable/gettingstarted/k8s-install-default/)
* [How to access kube-apiserver on command line? [closed] - StackOverflow](https://stackoverflow.com/questions/56542351/how-to-access-kube-apiserver-on-command-line)
* [A Guide to Audit Logging in Kubernetes - Medium](https://medium.com/@alparslanuysal/a-guide-to-audit-logging-in-kubernetes-1d9128d0f9d5)
* [ingress is not listening on port 80 #4799 - kubernetes/ingress-nginx](https://github.com/kubernetes/ingress-nginx/issues/4799)
