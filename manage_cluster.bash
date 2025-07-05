#!/bin/bash

case "$1" in
    "start-minikube")
        minikube start --driver=docker
        ;;
    "apply-all")
        kubectl apply -f deployments_and_services/
        kubectl apply -f configmaps/
        kubectl apply -f namespaces/
        kubectl apply -f secrets/mongodb-secret.yaml
        echo -e "\nApply all the configurations to resources for the cluster."
        ;;
    "delete-all")
        kubectl delete deployments --all
        kubectl delete services --all
        kubectl delete secrets --all
        kubectl delete configmaps --all
        echo -e "\nDelete all the resources of the cluster."
        ;;
    *)
        echo "start-minikube            start a minikube cluster using Docker"
        echo "apply-all                 apply all the configurations to resources for the cluster"
        echo "delete-all                delete all the resources of the cluster"
        ;;
esac


