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
minikube start --driver=docker
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
kubectl config set-context dev --namespace=development --cluster=minikube --user=minikube
```

Define production context
```
kubectl config set-context prod --namespace=production --cluster=minikube --user=minikube
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

## Restore MongoDB via a backup

Go inside the backup-access pod in a terminal
```
kubectl exec -it backup-access -- bash
```

Restore a dumb of MongoDB to recover the database after a failure or crash
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

## Add a movie to MongoDB

[Add a movie to MongoDB](./docs/add_a_movie_to_mongodb.md)

## mongosh commands

[mongosh commands](./docs/mongosh_commands.md)

## Resources
* [Kubernetes Documentation](https://kubernetes.io/docs/home/)
  * [Viewing Pods and Nodes](https://kubernetes.io/docs/tutorials/kubernetes-basics/explore/explore-intro/)
  * [Run a Stateless Application Using a Deployment](https://kubernetes.io/docs/tasks/run-application/run-stateless-application-deployment/)
  * [Namespaces Walkthrough](https://kubernetes.io/docs/tutorials/cluster-management/namespaces-walkthrough/)
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
* [Basic controls - minikube](https://minikube.sigs.k8s.io/docs/handbook/controls/)
