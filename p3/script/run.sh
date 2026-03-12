#run.sh




#!/bin/bash

set -e  # Exit on error

echo "=== Starting IoT Cluster Setup ==="

# Check if cluster already exists
if sudo k3d cluster list | grep -q "iot-cluster"; then
    echo "Cluster 'iot-cluster' already exists. Skipping creation."
else
    echo "Creating k3d cluster..."
    sudo k3d cluster create iot-cluster --api-port 6443 -p 8080:80@loadbalancer --agents 2 --wait
    echo "Cluster created successfully."
fi

# Check if argocd namespace exists
if sudo kubectl get namespace argocd &>/dev/null; then
    echo "Namespace 'argocd' already exists. Skipping creation."
else
    echo "Creating namespace 'argocd'..."
    sudo kubectl create namespace argocd
fi

# Check if dev namespace exists
if sudo kubectl get namespace dev &>/dev/null; then
    echo "Namespace 'dev' already exists. Skipping creation."
else
    echo "Creating namespace 'dev'..."
    sudo kubectl create namespace dev
fi

# Check if ArgoCD is already installed
if sudo kubectl get deployment argocd-server -n argocd &>/dev/null; then
    echo "ArgoCD is already installed. Skipping installation."
else
    echo "Installing ArgoCD..."
    sudo kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
fi

# Wait for ArgoCD pods to be ready
# This command will complete quickly, but pods will still be spinning up on the back end.
# These need to be in a running state before you can move forward. Use the watch command
# to ensure the pods are running and ready.
# watch kubectl get pods -n argocd
echo "Waiting for ArgoCD pods to be ready..."
sudo kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s

# By default ArgoCD uses the server pod name as the default password for the admin user,
# To get server pod name => kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server -o name | cut -d'/' -f 2
# so we're gonna replace it with 123 (we used https://bcrypt-generator.com/
# to generate the blowfish hash version of "123" below)
echo "Setting ArgoCD admin password to '123'..."
sudo kubectl -n argocd patch secret argocd-secret \
  -p '{"stringData": {
    "admin.password": "$2a$12$xyk8mlgC6l6gWQhTA.LF8uqlX5ng6Ju5BU7zhJ4Sp4VuCzQT7szIm",
    "admin.passwordMtime": "'$(date +%FT%T%Z)'"
  }}'

# sudo kubectl apply -f ../confs/project.yaml -n argocd
# sudo kubectl apply -f ../confs/application.yaml -n argocd
# sudo kubectl wait --for=condition=Ready pods --all -n argocd

# Get ArgoCD service IP/URL
echo ""
echo "=== ArgoCD Setup Complete ==="
echo ""

# Get LoadBalancer IP if available
LB_IP=$(sudo kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)

if [ -n "$LB_IP" ]; then
    echo "ArgoCD UI is accessible at: http://$LB_IP"
else
    # Fallback to NodePort or ClusterIP
    NODE_PORT=$(sudo kubectl get svc argocd-server -n argocd -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}' 2>/dev/null)
    if [ -n "$NODE_PORT" ]; then
        NODE_IP=$(sudo kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
        echo "ArgoCD UI is accessible at: http://$NODE_IP:$NODE_PORT"
    else
        echo "ArgoCD is running as ClusterIP. Use port-forward to access:"
        echo "  sudo kubectl port-forward svc/argocd-server -n argocd 8081:443"
        echo "  Then visit: https://localhost:8081"
    fi
fi

echo ""
echo "Login credentials:"
echo "  Username: admin"
echo "  Password: 123"
echo ""
