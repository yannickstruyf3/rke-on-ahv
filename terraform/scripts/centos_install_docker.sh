# Eject cloud-init
sudo eject

# Setting SELinux to permissive
sudo setenforce 0
sudo sed -i 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config

sudo sestatus | grep "Current mode"

# Disabling firewalld
sudo systemctl stop firewalld
sudo systemctl disable firewalld

# Remove any previous Docker version
sudo dnf remove docker \
  docker-client \
  docker-client-latest \
  docker-common \
  docker-latest \
  docker-latest-logrotate \
  docker-logrotate \
  docker-engine

# Install iptables but disable it
sudo dnf install -y iptables-services
sudo chkconfig iptables off

#load kernel modules
for module in br_netfilter ip6_udp_tunnel ip_set ip_set_hash_ip ip_set_hash_net iptable_filter iptable_nat iptable_mangle iptable_raw nf_conntrack_netlink nf_conntrack nf_conntrack_ipv4   nf_defrag_ipv4 nf_nat nf_nat_ipv4 nf_nat_masquerade_ipv4 nfnetlink udp_tunnel veth vxlan x_tables xt_addrtype xt_conntrack xt_comment xt_mark xt_multiport xt_nat xt_recent xt_set  xt_statistic xt_tcpudp 
do
  if ! lsmod | grep -q $module 
  then
    echo "module $module is not present but enabling";
    sudo modprobe $module
  fi
done

sudo tee -a /etc/sysctl.d/99-kubernetes.conf <<EOF
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

# Install iSCSI and NFS CentOS packages for Nutanix Volumes and Files CSI support
sudo dnf install -y iscsi-initiator-utils nfs-utils
sudo systemctl enable iscsid
sudo systemctl start iscsid

# Install Docker 19.03+
sudo dnf install -y yum-utils
sudo yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io
sudo systemctl enable docker
sudo systemctl start docker

# Verify you are now running version 19.03+
sudo docker version

# Add your user to the docker group
sudo usermod -aG docker $USER

# Change default cgroup driver to systemd
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF

sudo systemctl restart docker
sudo docker info | grep -i cgroup
