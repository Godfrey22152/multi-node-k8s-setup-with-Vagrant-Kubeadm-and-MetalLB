
# Multi-Node Kubernetes Setup with Vagrant, Kubeadm, and MetalLB

A comprehensive guide and resources for setting up a homelab multi-node Kubernetes workspace using **Vagrant**, **Kubeadm**, and **MetalLB**. This repository includes configurations, scripts, and instructions to help developers and DevOps engineers experiment with Kubernetes in a local environment.

---

## **Overview**

This project leverages:
- **Vagrant**: For managing virtual machine environments.
- **Kubeadm**: For initializing and managing Kubernetes clusters.
- **MetalLB**: For providing LoadBalancer functionality in a bare-metal environment.

By combining these tools, you can create a scalable and cost-effective Kubernetes cluster tailored for development and experimentation.

---
## **NOTE**
 For a more detailed guide on setting up the Multi-Node Kubernetes Setup with Vagrant, Kubeadm, and MetalLB I recommend visiting my articles on **Medium**. 
- **[Setting Up a Multi-Node Kubernetes Workspace with Vagrant, Kubeadm, and MetalLB](https://medium.com/@godfreyifeanyi50/setting-up-a-multi-node-kubernetes-workspace-with-vagrant-kubeadm-and-metallb-c1b51d7d394e)**.
- **[Effortless Multi-Node Kubernetes Cluster Setup with Kubeadm](https://medium.com/@godfreyifeanyi50/effortless-multi-node-kubernetes-cluster-setup-with-kubeadm-automate-the-process-35ed86b40435)**.

---
## **Key Features**

- Automated setup of master and worker nodes using Vagrant.
- Comprehensive bash script for Kubernetes installation and configuration.
- Integration of MetalLB for LoadBalancer support.
- Detailed guidance to validate and troubleshoot the cluster.

---

## **Prerequisites**

### **Hardware**
- Minimum **8 GB of RAM** and a **multi-core processor**.

### **Software**
- [VirtualBox](https://www.virtualbox.org/)
- [Vagrant](https://www.vagrantup.com/)
- [Helm](https://helm.sh/docs/intro/install/)

---

## **Setup Instructions**

### **1. Clone the Repository**
```bash
git clone https://github.com/Godfrey22152/multi-node-k8s-setup-with-Vagrant-Kubeadm-and-MetalLB.git
cd multi-node-k8s-setup-with-Vagrant-Kubeadm-and-MetalLB.git
```

---
### **2. Configure Vagrant**

The [Vagrantfile](./Vagrantfile) sets up one master and two worker nodes. Adjust the file if needed:
```ruby
Vagrant.configure("3") do |config| 
    # Define the master node
    config.vm.define "master" do |master|
      master.vm.box = "ubuntu/jammy64"
      master.vm.hostname = "master"
      master.vm.network "private_network", ip: "192.168.56.10"
      master.vm.network "public_network", bridge: "Intel(R) Dual Band Wireless-AC 8260"
      master.vm.provider "virtualbox" do |vb|
        vb.memory = "4096"
        vb.cpus = 2
      end
    end

    # Define the worker node1
    config.vm.define "worker1" do |worker1|
      worker1.vm.box = "ubuntu/jammy64"
      worker1.vm.hostname = "worker1"
      worker1.vm.network "private_network", ip: "192.168.56.11"
      worker1.vm.network "public_network", bridge: "Intel(R) Dual Band Wireless-AC 8260"
      worker1.vm.provider "virtualbox" do |vb|
        vb.memory = "4096"
        vb.cpus = 2
      end
    end

    # Define the worker node2
    config.vm.define "worker2" do |worker2|
      worker2.vm.box = "ubuntu/jammy64"
      worker2.vm.hostname = "worker2"
      worker2.vm.network "private_network", ip: "192.168.56.12"
      worker2.vm.network "public_network", bridge: "Intel(R) Dual Band Wireless-AC 8260"
      worker2.vm.provider "virtualbox" do |vb|
        vb.memory = "4096"
        vb.cpus = 2
      end
    end
end
```
#### Explanation:
- **Master Node:** Uses the private IP 192.168.56.10.
- **Worker1 Node:** Uses the private IP 192.168.56.11.
- **Worker2 Node:** Uses the private IP 192.168.56.12.
- All nodes have dual networking (private and public) for cluster communication and internet access.

- **Bring up the VMs:**
```bash
vagrant up
```
#### Access the Virtual Machines
Once the Vagrant environment is up and running without errors, you can SSH into the master and worker nodes using the following commands:

- **For the master node:**
```bash
vagrant ssh master
```

- **For the worker nodes:**
```bash
vagrant ssh worker1
vagrant ssh worker2
```

---
### **3. Automate Kubernetes Setup**
#### Bash Script for Kubeadm Setup
To automate the Kubeadm setup, we will use the **[setup_k8s.sh](./setup_k8s.sh)** bash script. This script simplifies configuring both master and worker nodes in a multi-node Kubernetes cluster, automating processes that are often manually executed. Kindly see my article on **[Medium](https://medium.com/@godfreyifeanyi50/setting-up-a-multi-node-kubernetes-workspace-with-vagrant-kubeadm-and-metallb-c1b51d7d394e)** for a detailed guidance for setting the cluster using the `setup_k8s.sh` bash script. 

#### Key Features:
The script automates several critical tasks involved in setting up a Kubernetes cluster:

1. **Installing Required Kubernetes Components**
Installs essential tools like kubeadm, kubelet, and kubectl.

2. **Disabling Swap Memory**
Kubernetes requires swap memory to be disabled for optimal operation. The script handles this automatically.

3. **Setting Up System Requirements**
Configures kernel modules, system parameters, and networking prerequisites.

4. **Container Runtime Setup**
Installs and configures containerd along with other container runtimes like runc.

5. **Initializing the Master Node**
Uses kubeadm to initialize the control plane with a specific pod network CIDR and advertise address.

6. **Configuring the Network Plugin**
Sets up Calico as the network plugin, ensuring connectivity across nodes.

7. **Worker Node Joining**
Generates and executes the join command for worker nodes to integrate seamlessly into the cluster.

8. **Reusable Design**
The script is reusable and flexible, allowing easy adaptation for various environments.

#### How To Run the Script:

##### Step 1: Executable Script:
The setup_k8s.sh file must be made executable:
```bash
sudo chmod +x setup_k8s.sh
```

##### Step 2: Run the script:
1. **Run the script on the master node as:**
  ```bash
  bash setup_k8s.sh master
  ```

2. **On the worker nodes:**

- **Prepare the Join Command:**
The kubeadm join command generated during master node initialization is saved to `/tmp/kubeadm_join_command.txt` on the master node.
Copy this file from the master node to each worker node using SCP or another secure transfer method with the file name unchanged.

- **Run the Worker Node Setup:**
On each worker node, run the script with the worker argument:

```bash
bash setup_k8s.sh worker
```

- **NOTE:** For a more detailed guide on setting up and installing Kubernetes with Kubeadm, I recommend visiting my previous article: **[Effortless Multi-Node Kubernetes Cluster Setup with Kubeadm](https://medium.com/@godfreyifeanyi50/effortless-multi-node-kubernetes-cluster-setup-with-kubeadm-automate-the-process-35ed86b40435)**.

---
### **4. Install MetalLB**
Install MetalLB using Manifest:
```bash
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.9/config/manifests/metallb-native.yaml
```

Verify that everything is installed correctly: 
```sh
kubectl get pods -n metallb-system
```

Apply the MetalLB configuration **[metallb.yaml](./metallb.yaml)** that creates **IPAddressPool** and **L2Advertisement**:

```bash
kubectl apply -f metallb.yaml -n metallb-system
```

---

## **Validating the Setup**

### **Verify Node Status**
Ensure all nodes are in a `Ready` state:
```bash
kubectl get nodes
```

### **Test LoadBalancer**
Deploy a sample application with a LoadBalancer service and verify external access.

---

## **Repository Contents**

- **[Vagrantfile](./Vagrantfile)**: Configurations for master and worker nodes.
- **[setup_k8s.sh](./setup_k8s.sh)**: Bash script to automate Kubernetes setup.
- **[metallb.yaml](./metallb.yaml)**: MetalLB configuration for LoadBalancer IP range.

---

## **Challenges and Tips**

- Avoid IP conflicts by carefully choosing the MetalLB IP range.
- Ensure sufficient resources are allocated to your VMs.

---

## **Connect and Contribute**

- **linkedin**: [Godfrey Ifeanyi](https://www.linkedin.com/in/godfrey-ifeanyi/)
- **GitHub**: [Repositories](https://github.com/Godfrey22152?tab=repositories)
- **Twitter**: [Godfrey Ifeanyi](https://x.com/ifeanyi_godfrey)

Contributions are welcome! Please open an issue or submit a pull request to improve this project.

---

**Hashtags**: #Kubernetes #DevOps #Vagrant #Kubeadm #MetalLB #Automation
