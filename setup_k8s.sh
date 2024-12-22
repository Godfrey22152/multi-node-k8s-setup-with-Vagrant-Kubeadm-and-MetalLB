#!/bin/bash

# Edit these variables to match your environment
# IP address of the master node
MASTER_NODE_IP="192.168.56.10"
# CIDR range for the Pod network, for Calico CNI plugin
POD_NETWORK_CIDR="192.168.0.0/16"


# Function to disable swap
disable_swap() {
  echo "Disabling swap..."
  swapoff -a
  sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
}

# Function to set up sysctl params and load kernel modules
setup_sysctl_and_modules() {
  echo "Setting up sysctl and kernel modules..."
  cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

  sudo modprobe overlay || { echo "Failed to load overlay module"; exit 1; }
  sudo modprobe br_netfilter || { echo "Failed to load br_netfilter module"; exit 1; }

  cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

  sudo sysctl --system

  # Verify the changes
  echo "Verifying loaded kernel modules and sysctl params..."
  lsmod | grep br_netfilter
  lsmod | grep overlay
  sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward
}

# Function to install containerd
install_containerd() {
  echo "Installing containerd..."
  curl -LO https://github.com/containerd/containerd/releases/download/v1.7.14/containerd-1.7.14-linux-amd64.tar.gz || { echo "Failed to 
download containerd"; exit 1; }
  sudo tar Cxzvf /usr/local containerd-1.7.14-linux-amd64.tar.gz
  rm containerd-1.7.14-linux-amd64.tar.gz
  curl -LO https://raw.githubusercontent.com/containerd/containerd/main/containerd.service || { echo "Failed to download containerd.service"; exit 1; }
  sudo mkdir -p /usr/local/lib/systemd/system/
  sudo mv containerd.service /usr/local/lib/systemd/system/
  sudo mkdir -p /etc/containerd
  containerd config default | sudo tee /etc/containerd/config.toml
  sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
  sudo systemctl daemon-reload
  sudo systemctl enable --now containerd

  # Check if containerd service is running
  systemctl status containerd --no-pager
}

# Function to install runc
install_runc() {
  echo "Installing runc..."
  curl -LO https://github.com/opencontainers/runc/releases/download/v1.1.12/runc.amd64 || { echo "Failed to download runc"; exit 1; }   
  sudo install -m 755 runc.amd64 /usr/local/sbin/runc || { echo "Failed to install runc"; exit 1; }
}

# Function to install CNI plugins
install_cni() {
  echo "Installing CNI plugins..."
  curl -LO https://github.com/containernetworking/plugins/releases/download/v1.5.0/cni-plugins-linux-amd64-v1.5.0.tgz || { echo "Failed 
to download CNI plugins"; exit 1; }
  sudo mkdir -p /opt/cni/bin
  sudo tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.5.0.tgz || { echo "Failed to extract CNI plugins"; exit 1; }
  rm cni-plugins-linux-amd64-v1.5.0.tgz
}

# Function to install Kubernetes tools
install_kubernetes_tools() {
  echo "Installing Kubernetes tools..."
  sudo apt-get update
  sudo apt-get install -y apt-transport-https ca-certificates curl gpg

  curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg || { echo "Failed to add Kubernetes GPG key"; exit 1; }
  echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

  sudo apt-get update
  sudo apt-get install -y kubelet kubeadm kubectl || { echo "Failed to install Kubernetes tools"; exit 1; }
  sudo apt-mark hold kubelet kubeadm kubectl

  # Verify installations
  kubeadm version
  kubelet --version
  kubectl version --client
}

# Function to configure crictl for containerd
configure_crictl() {
  echo "Configuring crictl to work with containerd..."
  sudo crictl config runtime-endpoint unix:///var/run/containerd/containerd.sock
}

# Function to initialize Kubernetes control plane (This runs on the Master node)
init_master_node() {
  echo "Initializing Kubernetes control plane..."
  sudo kubeadm init --pod-network-cidr=$POD_NETWORK_CIDR --apiserver-advertise-address=$MASTER_NODE_IP --node-name master || { echo "Failed to initialize master node"; exit 1; }

  # Save join command
  echo "Saving kubeadm join command..."
  sudo bash -c "kubeadm token create --print-join-command > /tmp/kubeadm_join_command.txt"
  echo "Join command saved to /tmp/kubeadm_join_command.txt"
}

# Function to configure kubeconfig for kubectl
setup_kubeconfig() {
  echo "Configuring kubeconfig..."
  sudo mkdir -p $HOME/.kube
  sudo chown $(id -u):$(id -g) /etc/kubernetes/admin.conf
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config
}

# Function to install Calico networking
install_calico() {
  echo "Installing Calico CNI..."
  kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/tigera-operator.yaml || { echo "Failed to apply Calico operator"; exit 1; }
  curl https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/custom-resources.yaml -O
  kubectl apply -f custom-resources.yaml
}

# Function to join worker nodes to the cluster (This runs on the worker nodes)
join_worker_node() {
  echo "Joining the worker node to the cluster..."
  # Assuming the join command was copied to /tmp/kubeadm_join_command.txt on master node
  JOIN_COMMAND=$(cat /tmp/kubeadm_join_command.txt) || { echo "Failed to read join command"; exit 1; }
  sudo $JOIN_COMMAND
}

# Main script
main() {
  disable_swap
  setup_sysctl_and_modules
  install_containerd
  install_runc
  install_cni
  install_kubernetes_tools
  configure_crictl

  if [ "$1" == "master" ]; then
    init_master_node
    setup_kubeconfig
    install_calico
  elif [ "$1" == "worker" ]; then
    join_worker_node
  else
    echo "Usage: $0 {master|worker}"
    exit 1
  fi

  echo "Kubernetes setup completed."
}

# Run main function with provided argument (master or worker)
main "$@"
