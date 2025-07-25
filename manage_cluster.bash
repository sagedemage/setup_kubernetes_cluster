#!/bin/bash

case "$1" in
    "start-minikube")
        minikube start --driver=docker --cpus=4 --memory=4g --disk-size=20g --cni=cilium
        ;;
    "apply-all")
        kubectl apply -f deployments/
        kubectl apply -f services/
        kubectl apply -f configmaps/
        kubectl apply -f ingress/
        kubectl apply -f secrets/mongodb-secret.yaml
        kubectl apply -f storageclasses/
        kubectl apply -f pv-pvc/
        kubectl apply -f statefulsets/
        kubectl apply -f cronjobs/
        kubectl apply -f limitranges/
        kubectl apply -f networkpolicies/
        kubectl apply -f priorityclasses/
        kubectl apply -f resourcequotas/
        kubectl apply -l app!=default-mem-demo -f pods/
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
        kubectl delete limitranges --all --force --grace-period=0
        kubectl delete networkpolicies --all --force --grace-period=0
        kubectl delete priorityclasses --all --force --grace-period=0
        kubectl delete resourcequotas --all --force --grace-period=0
        echo -e "\nDelete all the resources of the cluster."
        ;;
    "dev-switch")
        kubectl config use-context dev
        kubectl config get-contexts
        ;;
    "create-namespaces")
        kubectl create -f namespaces/
        kubectl config set-context dev --namespace=development --cluster=minikube --user=minikube
        kubectl config set-context prod --namespace=production --cluster=minikube --user=minikube
        ;;
    "create-secrets")
        bash -c "openssl rand -base64 756 > keyfiles/mongodb-keyfile"
        kubectl create secret generic mongodb-keyfile --from-file=keyfiles/mongodb-keyfile
        openssl genrsa -out tls_certificate/ca.key 2048
        openssl req -x509 -new -nodes -days 365 -key tls_certificate/ca.key -out tls_certificate/ca.crt -subj "/CN=nginx.demo.io/O=Spirit Technologies/OU=Spirit Cloud" -addext "subjectAltName=DNS:nginx.demo.io"
        kubectl create secret tls tls-secret --key tls_certificate/ca.key --cert tls_certificate/ca.crt
        ;;
    "install-dependencies")
        # install ingress
        helm upgrade --install ingress-nginx ingress-nginx \
        --repo https://kubernetes.github.io/ingress-nginx \
        --namespace ingress-nginx --create-namespace
        minikube addons enable ingress

        # install metrics server
        helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/ -n kube-system
        helm upgrade --install metrics-server metrics-server/metrics-server -n kube-system
        kubectl patch deployment metrics-server --patch-file patches/metrics_server_deployment.yaml -n kube-system

        # install prometheus and grafana
        helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
        helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack

        # install prometheus mongodb exporter
        helm install prometheus-mongodb-exporter prometheus-community/prometheus-mongodb-exporter -f mongodb-exporter/values.yaml

        ;;
    "setup-replica-set")
        kubectl exec -it mongo-sfs-0 -- mongosh < mongosh/query.js && echo ""
        ;;

    "define_hpa_resource")
        # Define an HPA resource that specifies how and when to scale the MongoDB statefulset
        kubectl autoscale statefulset mongo-sfs --min=3 --max=10 --cpu-percent=50
        ;;
    *)
        echo "start-minikube                start a minikube cluster using Docker"
        echo "apply-all                     apply all the configurations to resources for the cluster"
        echo "delete-all                    delete all the resources of the cluster"
        echo "dev-switch                    switch to the development namespace"
        echo "create-namespaces             create all namespaces for the cluster"
        echo "create-secrets                create all secrets for the cluster"
        echo "install-dependencies          install all dependencies for the cluster"
        echo "setup-replica-set             setup replica set via mongosh"
        echo "define_hpa_resource           define HPA resource to specify how and when to scale MongoDB statefulset"
        ;;
esac


