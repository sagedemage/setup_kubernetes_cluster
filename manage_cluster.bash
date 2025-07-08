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
        echo -e "\nApply all the configurations to resources for the cluster."
        ;;
    "delete-all")
        kubectl delete deployments --all
        kubectl delete services --all
        kubectl delete secrets --all
        kubectl delete configmaps --all
        kubectl delete ingress --all
        echo -e "\nDelete all the resources of the cluster."
        ;;
    "switch-to-dev")
        kubectl config use-context dev
        kubectl config get-contexts
        ;;
    "create-namespaces")
        kubectl create -f namespaces/
        ;;
    *)
        echo "start-minikube            start a minikube cluster using Docker"
        echo "apply-all                 apply all the configurations to resources for the cluster"
        echo "delete-all                delete all the resources of the cluster"
        echo "switch-to-dev             switch to the development namespace"
        echo "create-namespaces         create all namespaces for the cluster"
        ;;
esac


