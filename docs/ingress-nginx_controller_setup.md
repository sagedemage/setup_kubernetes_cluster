# Ingress-Nginx Controller Setup

## Install Nginx controller

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

## Local testing

Expose the nginx-deployment
```
kubectl expose deployment nginx-deployment
```

Create ingress resource
```
kubectl create ingress nginx-localhost --class=nginx --rule="nginx.localdev.me/*=nginx-deployment:80"
```

Forward a local port to the ingress controller
```
kubectl port-forward --namespace=ingress-nginx service/ingress-nginx-controller 8080:80
```

Access the deployment via curl
```
curl --resolve nginx.localdev.me:8080:127.0.0.1 http://nginx.localdev.me:8080
```

## Online testing

See the external IP address to the ingress controller is available
```
kubectl get service ingress-nginx-controller --namespace=ingress-nginx
```

If the external IP address is still pending, run this command to connect to the LoadBalancer service
```
minikube tunnel
```

Create an ingress resource
```
kubectl apply -f ingress/nginx-ingress.yaml
```

Edit the hosts file
```
sudo vim /etc/hosts
```

Add this line to the hosts file
```
...
192.168.49.2    nginx.demo.io
```

To get the address of the ingress, type this command
```
kubectl get ingress
```

If everything goes well, you should be able to access the website at http://nginx.demo.io/.
Great job, the public website you are serving is hosted on a Kubernetes cluster!

## Setup TLS Certificate for HTTPS

Generate a private key
```
openssl genrsa -out tls_certificate/ca.key 2048
```

Create a self-signed cerficate that is valid for 365 days
```
openssl req -x509 -new -nodes -days 365 -key tls_certificate/ca.key -out tls_certificate/ca.crt -subj "/CN=nginx.demo.io/O=Spirit Technologies/OU=Spirit Cloud" -addext "subjectAltName=DNS:nginx.demo.io"
```

Create tls secret
```
kubectl create secret tls tls-secret --key tls_certificate/ca.key --cert tls_certificate/ca.crt
```

Enable the hostNetwork in ingress-nginx-controller deployment
```
kubectl patch deployment ingress-nginx-controller --patch-file patches/ingress-nginx-controller.yaml -n ingress-nginx
```

If everything goes well, you should see a certificate for the website at https://nginx.demo.io/.

![tls_certificate](../screenshots/tls_certificate.png)