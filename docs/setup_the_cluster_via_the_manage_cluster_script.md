# Setup the cluster via the manage_cluster.bash script

1. Start a minikube cluster using Docker
    ```
    ./manage_cluster.bash start-minikube
    ```

2. Create all namespaces for the cluster
    ```
    ./manage_cluster.bash create-namespaces
    ```

3. Switch to the development namespace
    ```
    ./manage_cluster.bash switch-to-dev
    ```

4. Install all dependencies for the cluster
    ```
    ./manage_cluster.bash install-dependencies
    ```

5. Create all the secrets for the cluster
    ```
    ./manage_cluster.bash create-secrets
    ```

6. Apply all the configurations to resources for the cluster
    ```
    ./manage_cluster.bash apply-all
    ```

7. Setup the replica set via mongosh
    ```
    ./manage_cluster.bash setup-replica-set
    ```

8.  Define an HPA resource that specifies how and when to scale the MongoDB statefulset
    ```
    ./manage_cluster.bash define_hpa_resource
    ```