#!/bin/bash

case "$1" in
    "start-minikube")
        minikube start --driver=docker
        ;;
    "apply-all")
        kubectl apply -f deployments_and_services/
        kubectl apply -f configmaps/
        kubectl apply -f ingress/
        kubectl apply -f secrets/mongodb-secret.yaml
        kubectl apply -f storageclasses/
        kubectl apply -f pv-pvc/
        kubectl apply -f statefulsets/
        kubectl apply -f cronjobs/
        kubectl apply -f pods/
        echo -e "\nApply all the configurations to resources for the cluster."
        ;;
    "delete-all")
        kubectl delete deployments --all --force --grace-period=0
        kubectl delete services --all --force --grace-period=0
        kubectl delete secrets --all --force --grace-period=0
        kubectl delete configmaps --all --force --grace-period=0
        kubectl delete ingress --all --force --grace-period=0
        kubectl delete storageclasses --all --force --grace-period=0
        kubectl delete statefulsets --all --force --grace-period=0
        kubectl delete cronjobs --all --force --grace-period=0
        kubectl delete pods --all --force --grace-period=0
        echo -e "\nDelete all the resources of the cluster."
        ;;
    "switch-to-dev")
        kubectl config use-context dev
        kubectl config get-contexts
        ;;
    "create-namespaces")
        kubectl create -f namespaces/
        ;;
    "create-secrets-from-file")
        kubectl create secret generic mongodb-keyfile --from-file=keyfiles/mongodb-keyfile
        ;;
    *)
        echo "start-minikube                start a minikube cluster using Docker"
        echo "apply-all                     apply all the configurations to resources for the cluster"
        echo "delete-all                    delete all the resources of the cluster"
        echo "switch-to-dev                 switch to the development namespace"
        echo "create-namespaces             create all namespaces for the cluster"
        echo "create-secrets-from-file      create all secrets from a file"
        ;;
esac


