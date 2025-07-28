# Security

## Resource Quotas

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

## Configure Default Memory Requests and Limits for a Namespace

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

## Install the Cilium Network Policy Provider

Make sure to start up a minikube cluster prepared for installing cilium with the --cni flag
```
minikube start --driver=docker --cpus=4 --memory=4g --disk-size=20g --cni=cilium --nodes 2 -p worker
```

Install Cilium into the Kubernetes cluster
```
cilium install
```

## Declare Network Policy
### Test the connection of the mongodb-deployment pod by accessing it from another Pod

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

### Limit access to the mongodb-deployment pod

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

## Admission Control in Kubernetes

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

## Auditing

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

## Assigning Pods to Nodes using Node Affinity

List nodes in your cluster with their labels
```
kubectl get nodes --show-labels
```

Add a label to the worker-m02 node
```
kubectl label nodes worker-m02 servertype=mongodb
```

Add a label to the worker node
```
kubectl label nodes worker servertype=nginx
```

Verify the chosen node has the `servertype=mongodb` and `servertype=nginx` label
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
NAME                                                        READY   STATUS      RESTARTS        AGE     IP             NODE         NOMINATED NODE   READINESS GATES
mongodb-deployment-66d4676cf9-2knl8                         1/1     Running     3 (145m ago)    3h54m   10.244.1.60    worker-m02   <none>           <none>
```

In deployments/nginx-config.yaml, specify the Pod to the worker node via Node Affinity. Set the key to
`servertype` and its value to `nginx`.


Apply the nginx-deployment deployement
```
kubectl apply -f deployments/nginx-config.yaml
```

Make sure the nginx-deployment pod is in the worker node
```
NAME                                                        READY   STATUS      RESTARTS        AGE     IP             NODE         NOMINATED NODE   READINESS GATES
nginx-deployment-5b687784f-87mnf                            1/1     Running     0               14s     10.244.0.182   worker       <none>           <none>
nginx-deployment-5b687784f-d47rf                            1/1     Running     0               16s     10.244.0.197   worker       <none>           <none>
```