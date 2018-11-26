#!/bin/sh
set -ex

# TODO Floating IP (38.145.34.41) should ideally not be fixed...
# TODO How to send all ssh commands over a single connection, yet still get echo?

openstack server create --flavor m1.medium --image Fedora-Cloud-Base-28-1.1.x86_64 --security-group ssh --key-name laptop odl-coe-k8s-master-fedora28
openstack server add security group odl-coe-k8s-master-fedora28 k8s-master
openstack server add floating ip odl-coe-k8s-master-fedora28 38.145.34.41
sleep 10
ssh-keygen -R 38.145.34.41 || true
ssh -o StrictHostKeyChecking=no fedora@38.145.34.41 "sudo dnf -y update; sudo reboot now"
sleep 10

scp kubernetes.repo fedora@38.145.34.41:
ssh fedora@38.145.34.41 "sudo mv ~/kubernetes.repo /etc/yum.repos.d/kubernetes.repo"
ssh fedora@38.145.34.41 "sudo setenforce 0; sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config"
ssh fedora@38.145.34.41 "sudo dnf install -y docker kubelet kubeadm kubectl --disableexcludes=kubernetes"
ssh fedora@38.145.34.41 "sudo systemctl enable kubelet && systemctl start kubelet; sudo systemctl enable docker; sudo systemctl start docker"
ssh fedora@38.145.34.41 "sudo kubeadm config images pull"
ssh fedora@38.145.34.41 "sudo sysctl net.bridge.bridge-nf-call-iptables=1"
ssh fedora@38.145.34.41 "sudo kubeadm init --pod-network-cidr=10.244.0.0/16"
ssh fedora@38.145.34.41 "mkdir -p ~/.kube; sudo cp -i /etc/kubernetes/admin.conf ~/.kube/config; sudo chown $(id -u):$(id -g) ~/.kube/config"

openstack server create --flavor m1.small --image Fedora-Cloud-Base-28-1.1.x86_64 --security-group ssh --key-name laptop odl-coe-k8s-node1-fedora28
openstack server add security group odl-coe-k8s-node1-fedora28 k8s-node
# TODO Obtain private IP of odl-coe-k8s-node1-fedora28 and store it in NODE_IP
# ssh fedora@38.145.34.41 "ssh -o StrictHostKeyChecking=no $NODE_IP 'sudo dnf -y update; sudo reboot now'"
# sleep 10

# TODO Avoid the copy/paste from above here...
# scp kubernetes.repo fedora@38.145.34.41:
# ssh -t fedora@38.145.34.41 "scp kubernetes.repo $NODE_IP:"
# ssh -t fedora@38.145.34.41 "ssh $NODE_IP 'sudo mv ~/kubernetes.repo /etc/yum.repos.d/kubernetes.repo'"
# ssh -t fedora@38.145.34.41 "ssh $NODE_IP sudo setenforce 0; sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config"
# ssh -t fedora@38.145.34.41 "ssh $NODE_IP 'sudo dnf install -y docker kubelet kubeadm kubectl --disableexcludes=kubernetes'"
# ssh -t fedora@38.145.34.41 "ssh $NODE_IP 'sudo systemctl enable kubelet && systemctl start kubelet; sudo systemctl enable docker; sudo systemctl start docker'"
# ssh -t fedora@38.145.34.41 "ssh $NODE_IP 'sudo kubeadm config images pull'"
# ssh -t fedora@38.145.34.41 "ssh $NODE_IP 'sudo sysctl net.bridge.bridge-nf-call-iptables=1'"

# TODO Obtain private IP of odl-coe-k8s-master-fedora28 and store it in MASTER_PRIVATE_IP
# TODO How to get the --token & --discovery-token-ca-cert-hash from the master to kubeadm join on the nodes?
# ssh -t fedora@38.145.34.41 "ssh $NODE_IP 'sudo kubeadm join $MASTER_PRIVATE_IP:6443 --token $TOKEN --discovery-token-ca-cert-hash $HASH'"

# ssh -t fedora@38.145.34.41 "kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/bc79dd1505b0c8681ece4de4c0d86c5cd2643275/Documentation/kube-flannel.yml"
# sleep 30
# ssh -t fedora@38.145.34.41 "kubectl get nodes"

# TODO Test that it all really works... ;-)
