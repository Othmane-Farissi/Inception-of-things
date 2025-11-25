# K3s Cluster and Website Deployment Project

## Overview
This project consists of two distinct parts, each demonstrating the use of K3s and Vagrant to set up Kubernetes clusters on `generic/ubuntu2204` VMs. Both setups include SSH hardening for secure, passwordless access using your SSH key.

- **Part 1: Two-Node K3s Cluster**
  - Sets up a Kubernetes cluster with a master node (`hlachkarS` at `192.168.56.110`) and a worker node (`serverworker` at `192.168.56.111`).
  - Focuses on a minimal K3s cluster setup without application deployment.
  - Useful for learning multi-node Kubernetes configurations.

- **Part 2: Single-Node K3s with Three Static Websites**
  - Sets up a single-node K3s cluster (`hlachkarS` at `192.168.56.110`) hosting three static websites served by Nginx.
  - Websites are accessible at `app1.com`, `app2.com`, `app3.com`, with `app3` as the default route for `192.168.56.110`.
  - `app2` has 3 replicas; `app1` and `app3` have 1 replica each.
  - Uses Traefik Ingress for routing.

## Prerequisites
- **Host Machine**: Ubuntu 20.04 (or compatible OS).
- **Tools**:
  - **Vagrant (version 2.4.7)**:
    Install using the binary provided by HashiCorp:
    1. Download the binary:
       ```bash
       wget https://releases.hashicorp.com/vagrant/2.4.7/vagrant_2.4.7_linux_amd64.zip
       ```
    2. Extract and move to `/home/hlachkar/bin/`:
       ```bash
       unzip vagrant_2.4.7_linux_amd64.zip
       mkdir -p /home/hlachkar/bin
       mv vagrant /home/hlachkar/bin/
       chmod +x /home/hlachkar/bin/vagrant
       ```
    3. Add `/home/hlachkar/bin` to `PATH` in `.bashrc` and `.zshrc`:
       ```bash
       echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
       echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc
       ```
    4. Reload shell configuration:
       ```bash
       source ~/.bashrc  # Or ~/.zshrc ~/.zshrc if using Zsh
       ```
    5. Verify installation:
       ```bash
       vagrant version
       ```
       Should show `Version 2.4.7`.
  - SSH Key: Generate with `ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa` if not present at `~/.ssh/id_rsa.pub`.
- **Network**:
  - Part 1: Ensure `192.168.56.110` (master) and `192.168.56.111` (worker) are available.
  - Part 2: Ensure `192.168.56.110` is available.
- **Project Directory**: `./` with subdirectories `p1/`, `p2/` and `p3/`.

## Part 1: Two-Node K3s Cluster

### Setup Instructions
1. **Navigate to Part 1 Directory**:
   ```bash
   cd ./p1
   ```

2. **Verify Files**:
   - `Vagrantfile`: Configures two VMs and K3s cluster.

3. **Provision the Cluster**:
   ```bash
   vagrant up
   ```
   This:
   - Creates VMs: `hlachkarS` (master, `192.168.56.110`) and `serverworker` (worker, `192.168.56.111`).
   - Installs K3s server on master and agent on worker, joining the cluster using the node token (`/vagrant/master-token`).
   - Configures passwordless SSH with your public key (`~/.ssh/id_rsa.pub`).
   - Hardens SSH by disabling password authentication.

4. **Access the Cluster**:
   - SSH into nodes:
     ```bash
     ssh vagrant@192.168.56.110  # Master
     ssh vagrant@192.168.56.111  # Worker
     ```
     or
     ```bash
     vagrant ssh hlachkarS
     vagrant ssh hlachkarSW
     ```
   - Verify cluster (on master):
     ```bash
     sudo kubectl get nodes
     ```
     Should show `hlachkarS` and `hlachkarSW`.

### Project Structure
- **`part1/Vagrantfile`**:
  - Defines two VMs with private network IPs.
  - Installs K3s server on `hlachkarS` and agent on `serverworker`.
  - Configures SSH with your public key and disables password authentication.

### Troubleshooting
- **Cluster issues**:
  - Verify nodes: `sudo kubectl get nodes` (on master).
  - Check K3s status: `sudo systemctl status k3s` (master -- hlachkarS) or `sudo systemctl status k3s-agent` (worker -- hlachkarSW).
  - Ensure token: `cat /vagrant/master-token`.
- **SSH issues**:
  - Verify `~/.ssh/id_rsa.pub` exists on the host.
  - Check `/etc/ssh/sshd_config.d/99-vagrant-custom.conf` for `PasswordAuthentication no`.

## Part 2: Single-Node K3s with Three Static Websites

### Setup Instructions
1. **Configure Host Mapping**:
   Edit `/etc/hosts` on your host:
   ```bash
   sudo nano /etc/hosts
   ```
   Add:
   ```
   192.168.56.110 app1.com app2.com app3.com test.com
   ```

2. **Navigate to Part 2 Directory**:
   ```bash
   cd ./p2
   ```

3. **Verify Files**:
   - `Vagrantfile`: Configures single VM and website deployments.
   - `config/deployment_app1.yaml`: Website with 3 replicas, default route for `192.168.56.110` AND Website with 1 replica AND Website with 1 replica.

4. **Provision the Cluster and Websites**:
   ```bash
   vagrant up
   ```
   This:
   - Creates VM: `hlachkarS` at `192.168.56.110`.
   - Installs K3s server and saves node token to `/vagrant/master-token`.
   - Configures passwordless SSH with your public key.
   - Hardens SSH by disabling password authentication.
   - Deploys three websites using `kubectl apply -f /home/vagrant/deployment_app1.yaml` manifest.

5. **Access the Websites**:
   - Via hostnames:
     ```bash
     curl http://app1.com
     curl http://app2.com
     curl http://app3.com
     curl http://test.com
     ```
   - Via IP (defaults to Site 1):
     ```bash
     curl http://192.168.56.110
     ```
   - Open in a browser: `http://app1.com`, `http://app2.com`, `http://app3.com`.
   - Expected outputs:
     - Site 1: `<h1>Welcome to Site 1</h1>...`
     - Site 2: `<h1>Welcome to Site 2</h1>...`
     - Site 3: `<h1>Welcome to Site 3</h1>...`

6. **Access the Cluster**:
   - SSH into VM:
     ```bash
     vagrant ssh
     ```
   - Verify deployments:
     ```bash
     sudo kubectl get pods -l app=app2  # Should show 3 pods
     sudo kubectl get pods -l app=app1  # 1 pod
     sudo kubectl get pods -l app=app3  # 1 pod
     sudo kubectl get ingress
     ```

### Project Structure
- **`part2/Vagrantfile`**:
  - Defines single VM (`hlachkarS`).
  - Installs K3s server and deploys three websites.
  - Configures SSH with your public key and disables password authentication.
- **`p2/config/deployment_app1.yaml`**:
  - ConfigMap, Deployment (3 replicas), ClusterIP Service, Ingress for `app2.com` and default IP route. ConfigMap, Deployment (1 replica), ClusterIP Service, Ingress for `app3.com`. ConfigMap, Deployment (1 replica), ClusterIP Service, Ingress for `app1.com`.

### Troubleshooting
- **Website not accessible**:
  - Verify `/etc/hosts` maps `app1.com`, `app2.com`, `app3.com` to `192.168.56.110`.
  - Check Traefik: `sudo kubectl logs -n kube-system -l app=traefik`.
- **Pod issues**:
  - Check status: `sudo kubectl describe pod -l app=app1` (or `app2`, `app3`).
  - View logs: `sudo kubectl logs -l app=app1`.
- **Cluster issues**:
  - Check K3s status: `sudo systemctl status k3s`.
  - Ensure token: `cat /vagrant/master-token`.
- **SSH issues**:
  - Verify `~/.ssh/id_rsa.pub` exists.
  - Check `/etc/ssh/sshd_config.d/99-vagrant-custom.conf` for `PasswordAuthentication no`.

## References
- **K3s Documentation**: [https://k3s.io/](https://k3s.io/) - Lightweight Kubernetes and multi-node setup.
- **Vagrant Documentation**: [https://www.vagrantup.com/docs](https://www.vagrantup.com/docs) - VM provisioning and multi-machine configuration.
- **Traefik Documentation**: [https://doc.traefik.io/traefik/](https://doc.traefik.io/traefik/) - Ingress controller for Kubernetes.
- **Ubuntu SSH Hardening**: [https://ubuntu.com/server/docs/ssh](https://ubuntu.com/server/docs/ssh) - Secure SSH configuration guidelines.
- **Kubernetes Ingress**: [https://kubernetes.io/docs/concepts/services-networking/ingress/](https://kubernetes.io/docs/concepts/services-networking/ingress/) - Routing external traffic with catch-all rules.


For questions or contributions, contact the team lead or open an issue in the repository.
