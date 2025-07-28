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

## Verify the Backup of MongoDB Works

Verify the backup of MongoDB via mongodump works

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

[Setup Monitoring with Prometheus](./docs/setup_monitoring_with_prometheus.md)

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

[Security](./docs/security.md)

## Project Tasks

[Project Tasks](./docs/project_tasks.md)

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
