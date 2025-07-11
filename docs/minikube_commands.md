# Minikube Commands

Start a cluster:
```
minikube start
```

Start a cluster using Docker (Recommended)
```
minikube start --driver=docker
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

Get logs for minikube and save them to a file called logs.txt
```
minikube logs --file logs.txt
```

Minikube has Kubernetes Dashboard by default. To get more information about your cluster state, run this command:
```
minikube dashboard
```

Halt the cluster
```
minikube stop
```

Delete the local cluster
```
minikube delete
```

Delete all the local clusters, profiles, and its files
```
minikube delete --all --purge
```