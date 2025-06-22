# setup_kubernetes_cluster

Setup a Kubernetes cluster with MongoDB, Mongo Express, Nginx, Prometheus, and Grafana

## Minikube Commands

Create a minikube cluster:
```
minikube start
```

Start a minikube cluster using VirtualBox
```
minikube start --driver=qemu2
```

Driver available:
- kvm2
- qemu2
- qemu
- vmware
- none
- docker
- podman
- ssh

**Note**: Minikube is required to run kubectl commands!

Minikube has Kubernetes Dashboard by default. To get more information about your cluster state, run this command:
```
minikube dashboard
```

Halt the cluster
```
minikube stop
```

## Kubctl Commands

Get the status of the nodes
```
kubectl get nodes
```

List all pods
```
kubectl get pod
```

List all services
```
kubectl get services
```

Get a list of ReplicaSets (ReplicaSet is the replicas of the pods)
```
kubectl get replicaset
```

List all the deployments
```
kubectl get deployment
```

Create a deployment (for example create a nginx deployment)
```
kubectl create deployment nginx-depl --image=nginx
```

Edit a configuration file for a pod
```
kubectl edit deployment [pod_name]
```

Print the logs from a container in a pod
```
kubectl logs [pod_name]
```

Show detailed information about a pod
```
kubectl describe pod [pod_name]
```

Start a bash session in a pod’s container
```
kubectl exec -it [pod_name] -- /bin/bash
```

Delete deployment
```
kubectl delete deployment [deployment_name]
```

Apply configuration to a resource
```
kubectl apply -f [file_name]
```

File: nginx-deployment.yaml
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  selector:
    matchLabels:
      app: nginx
  replicas: 2 # tells deployment to run 2 pods matching the template
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.28.0
        ports:
        - containerPort: 80
```

For example apply yaml configuration file to a resource
```
kubectl apply -f nginx-deployment.yaml
```

## Useful commands
Create base64 encoded values for credentials
```
echo -n 'username' | base64
echo -n 'password' | base64
```

Copy the values in the secret file (mongodb-secret.yaml)

## Start the cluster

Deploy the secret
```
kubectl apply -f mongodb-secret.yaml
```

Deploy the MongoDB deployment and service
```
kubectl apply -f mongodb-config.yaml
```

Deploy the configmap
```
kubectl apply -f mongo-configmap.yaml
```

Deploy Mongo Express deployment and service
```
kubectl apply -f mongo-express.yaml
```

## Resources
* [Kubernetes Documentation](https://kubernetes.io/docs/home/)
  * [Viewing Pods and Nodes](https://kubernetes.io/docs/tutorials/kubernetes-basics/explore/explore-intro/)
  * [Run a Stateless Application Using a Deployment](https://kubernetes.io/docs/tasks/run-application/run-stateless-application-deployment/)
