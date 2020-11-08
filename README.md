# Vagrantfile

Install two VM with Kerberos auth, nfs_server, nfs_client 
```bash


IP server: 10.10.0.2/server.net
IP client: 10.10.0.3/client.net

provision:
nfs_storage_config.vm.provision "shell", path: "s/nfs_s_k.sh"
kerberos_server_config.vm.provision "shell", path: "s/nfs_c_k.sh"

```


