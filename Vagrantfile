Vagrant.configure(2) do |config|

  config.vm.define "nfs_server" do |nfs_storage_config|
    nfs_storage_config.vm.box = "centos/7"
    nfs_storage_config.vm.hostname = "server.net"

    nfs_storage_config.vm.network "private_network", ip: "10.10.0.2", :netmask => "255.255.255.0"

    nfs_storage_config.vm.provider "virtualbox" do |vb|
      vb.gui = false
      vb.memory = "1024"
      vb.cpus = 2
      vb.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
      vb.name = "kerberos_nfs_server"
    end

    nfs_storage_config.vm.provision "shell", path: "s/nfs_s_k.sh"
  end

  config.vm.define "nfs_client" do |kerberos_server_config|
    kerberos_server_config.vm.box = "centos/7"
    kerberos_server_config.vm.hostname = "client.net"

    kerberos_server_config.vm.network "private_network", ip: "10.10.0.3", :netmask => "255.255.255.0"

    kerberos_server_config.vm.provider "virtualbox" do |vb|
      vb.gui = false
      vb.memory = "1024"
      vb.cpus = 2
      vb.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
      vb.name = "kerberos_nfs_client"
    end
    kerberos_server_config.vm.provision "shell", path: "s/nfs_c_k.sh"

  end

end

