Vagrant.configure("2") do |config|
  config.vm.box = "${vagrant_box}"

  # Kubernetes Master Nodes
  (1..${k8s_master_count}).each do |i|
    config.vm.define "k8s-master-#{i}" do |master|
      master.vm.hostname = "k8s-master-#{i}"
      master.vm.network "private_network", ip: "192.168.56.#{10 + i}"
      master.vm.provider "virtualbox" do |vb|
        vb.cpus = ${vagrant_cpus}
        vb.memory = ${vagrant_memory}
      end
      master.vm.provision "shell", path: "scripts/install_k8s_master.sh", args: ["master", i]
    end
  end

  # Kubernetes Worker Nodes
  (1..${k8s_worker_count}).each do |i|
    config.vm.define "k8s-worker-#{i}" do |worker|
      worker.vm.hostname = "k8s-worker-#{i}"
      worker.vm.network "private_network", ip: "192.168.56.#{20 + i}"
      worker.vm.provider "virtualbox" do |vb|
        vb.cpus = ${vagrant_cpus}
        vb.memory = ${vagrant_memory}
      end
      worker.vm.provision "shell", path: "scripts/install_k8s_worker.sh", args: ["worker", i]
      worker.vm.provision "shell", path: "join_worker_to_master.sh", args: ["worker", i]
    end
  end
end
