#!/bin/bash

# Install Kerberos
yum install -y krb5-server krb5-workstation pam_krb5

# Save base conf
cp /var/kerberos/krb5kdc/kdc.conf /var/kerberos/krb5kdc/kdc.conf-orig

# Generate settiong kerberos
cat << EOF >/var/kerberos/krb5kdc/kdc.conf
[kdcdefaults]
 kdc_ports = 88
 kdc_tcp_ports = 88

[realms]
 SERVER.NET = {
  master_key_type = aes256-cts
  default_principal_flags = +preauth
  acl_file = /var/kerberos/krb5kdc/kadm5.acl
  dict_file = /usr/share/dict/words
  admin_keytab = /var/kerberos/krb5kdc/kadm5.keytab
  supported_enctypes = aes256-cts:normal aes128-cts:normal des3-hmac-sha1:normal arcfour-hmac:normal camellia256-cts:normal camellia128-cts:normal des-hmac-sha1:normal des-cbc-md5:normal des-cbc-crc:normal
 }
EOF

cp /etc/krb5.conf /etc/krb5.conf-orig

cat << EOF > /etc/krb5.conf
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

cp /var/kerberos/krb5kdc/kadm5.acl /var/kerberos/krb5kdc/kadm5.acl-orig

#ACL
cat << EOF > /var/kerberos/krb5kdc/kadm5.acl
*/admin@SERVER.NET	*
EOF

# Gen master key
kdb5_util create -s -r SERVER.NET << EOF
lah6Zai8shahpho4meo1
lah6Zai8shahpho4meo1
EOF

# Enable, start kerberos
systemctl enable krb5kdc
systemctl enable kadmin

systemctl start krb5kdc
systemctl start kadmin

# Create root user
kadmin.local <<EOF
addprinc root/admin
ainae6Ie7aiDuof3bief
ainae6Ie7aiDuof3bief
addprinc -randkey host/kdc.server.net
ktadd host/kdc.server.net
quit
EOF

# Disable selinux
sed -i"" -e 's#SELINUX=enforcing#SELINUX=disabled#g' /etc/selinux/config

# Gen DNS for kerberos
cat << EOF >/etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
10.10.0.2 kdc.server.net server.net server
10.10.0.3 client client.net
EOF

# Install NFS server
yum -y install nfs-utils
yum install iptables-services.x86_64  -y

# Eneble,start  NFS server
systemctl enable iptables
systemctl start iptables



# Enable V3 NFS, disable other
cat << EOF >  /etc/sysconfig/nfs
RPCNFSDARGS="-V 3 -N 2 -N 4 -N 4.1 -N 4.2"
RPCMOUNTDOPTS=""
STATDARG=""
SMNOTIFYARGS=""
RPCIDMAPDARGS=""
RPCGSSDARGS=""
GSS_USE_PROXY="yes"
BLKMAPDARGS=""
EOF


# Gen user kerberos
clienthostname=$(hostname -f)
kadmin <<EOF
ainae6Ie7aiDuof3bief
addprinc -randkey nfs/$clienthostname
ktadd nfs/$clienthostname
quit
EOF

# Gen exports
cat << EOF > /etc/exports
/share client.net(rw,no_root_squash,sec=krb5)
EOF

# Create shared folder
mkdir /share

# Exporting
exportfs -a

# Disable vers2, vers4.x
cat << EOF > /etc/nfs.conf
[nfsd]
 udp=y
 tcp=y
 vers2=n
 vers3=y
 vers4=n
 vers4.0=n
 vers4.1=n
 vers4.2=n
EOF

# Enable,start NFS, RPC
systemctl restart rpcbind
systemctl restart nfs-config
systemctl restart nfs
systemctl restart nfslock

systemctl enable rpcbind
systemctl enable nfs
systemctl enable nfslock


# Gen Firewall rules
cat << EOF > /etc/sysconfig/iptables
# Generated by iptables-save v1.4.21 on Sun Nov  8 05:46:21 2020
*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [38:2900]
:NFS - [0:0]
-A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
-A INPUT -p icmp -j ACCEPT
-A INPUT -i lo -j ACCEPT
-A INPUT -p tcp -m state --state NEW -m tcp --dport 22 -j ACCEPT
-A INPUT -j NFS
-A INPUT -j REJECT --reject-with icmp-host-prohibited
-A FORWARD -j REJECT --reject-with icmp-host-prohibited
-A NFS -s 10.10.0.0/24 -j ACCEPT
-A NFS -j DROP
COMMIT
# Completed on Sun Nov  8 05:46:21 2020
EOF

# Restore firewall rules
iptables-restore < /etc/sysconfig/iptables

