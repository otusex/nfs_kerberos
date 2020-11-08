#!/bin/bash

# Install rerberos
yum install -y krb5-workstation pam_krb5

# Generation settings rerberos
cat << EOF >  /etc/krb5.conf
includedir /etc/krb5.conf.d/

[logging]
 default = FILE:/var/log/krb5libs.log
 kdc = FILE:/var/log/krb5kdc.log
 admin_server = FILE:/var/log/kadmind.log

[libdefaults]
 dns_lookup_realm = false
 ticket_lifetime = 24h
 renew_lifetime = 7d
 forwardable = true
 rdns = false
 pkinit_anchors = FILE:/etc/pki/tls/certs/ca-bundle.crt
 default_realm = SERVER.NET
 default_ccache_name = KEYRING:persistent:%{uid}

[realms]
  SERVER.NET = {
   kdc = kdc.server.net
   admin_server = kdc.server.net
}

[domain_realm]
 .server.net = SERVER.NET
 server.net = SERVER.NET
EOF


# Disable selinux
sed -i"" -e 's#SELINUX=enforcing#SELINUX=disabled#g' /etc/selinux/config

# Add DNS, need for kerberos
cat << EOF >  /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
10.10.0.3 client client
10.10.0.2 kdc.server.net server.net server
EOF


# Install,enabled firewall nfs,nfs-secure
yum -y install nfs-utils
yum install iptables-services.x86_64  -y

systemctl enable iptables
systemctl start iptables

systemctl enable nfs-secure 
systemctl start nfs-secure


systemctl enable nfs-client.target
systemctl start nfs-client.target

# Create shared folder
mkdir /share

clienthostname=$(hostname -f)
sleep 5
kadmin <<EOF
ainae6Ie7aiDuof3bief
addprinc -randkey nfs/$clienthostname
ktadd nfs/$clienthostname
quit
EOF

clienthostname=$(hostname -f)
sleep 5
kadmin <<EOF
ainae6Ie7aiDuof3bief
addprinc -randkey host/$clienthostname
ktadd host/$clienthostname
quit
EOF

# Generatee FSTAB
cat << EOF >> /etc/fstab
server.net:/share /share nfs  nfsvers=3,_netdev,sec=krb5p   0 0
EOF

# Reboot service
systemctl restart nfs-client.target nfs-secure


sleep 10
# Mount shared
mount -a
