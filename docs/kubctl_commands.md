# Kubctl Commands

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

List all the namespaces
```
kubectl get namespace
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

Get the current context of the cluster
```
kubectl config current-context
```

Switch to the development namespace
```
kubectl config use-context dev
```

Check your current context
```
kubectl config current-context
```

Switch back to the minikube namespace or whatever your default namespace is called
```
kubectl config use-context minikube
```

If you don't know what your default namespace is called, run the command to get all the contexts
```
kubectl config get-contexts
```

Display a specified kubeconfig file
```
kubectl config view
```

## Port Forwarding using Kubectl

Port forward the pods, nginx-deployment, to 127.0.0.1:8080. Access the website at http://127.0.0.1:8080 or http://localhost:8080.
```
kubectl port-forward nginx-deployment-5fbdcbb6d5-lth75 8080:80
```

Port forward the deployment, nginx-deployment, to 127.0.0.1:8080.
```
kubectl port-forward deployments/nginx-deployment 8080:80
```

Port forward the service, nginx-service, to 127.0.0.1:8080.
```
kubectl port-forward service/nginx-service 8080:80
```

## Properly remove the pv and pvc resources

Make finalizers null
```
kubectl patch pv <pv-name> -p '{"metadata":{"finalizers":null}}'
kubectl patch pvc <pvc-name> -p '{"metadata":{"finalizers":null}}'
```

Delete all of the pv and pvc resources
```
kubectl delete pv --all --force --grace-period=0
kubectl delete pvc --all --force --grace-period=0
```

## Useful kubectl utilities

Use curl command with kubectl
```
kubectl run --rm -it --tty pingkungcurl1 --image=curlimages/curl --restart=Never -- 192.168.49.2:30001
```