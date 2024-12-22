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
