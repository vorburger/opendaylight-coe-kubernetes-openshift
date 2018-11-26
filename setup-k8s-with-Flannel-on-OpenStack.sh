#!/bin/sh
set -ex

# TODO Floating IP (38.145.34.41) should ideally not be fixed...

openstack server create --flavor m1.small --image Fedora-Cloud-Base-28-1.1.x86_64 --security-group ssh --key-name laptop odl-coe-k8s-node1-fedora28
openstack server add security group odl-coe-k8s-node1-fedora28 k8s-node

openstack server create --flavor m1.medium --image Fedora-Cloud-Base-28-1.1.x86_64 --security-group ssh --key-name laptop odl-coe-k8s-master-fedora28
openstack server add security group odl-coe-k8s-master-fedora28 k8s-master
openstack server add floating ip odl-coe-k8s-master-fedora28 38.145.34.41
sleep 10
ssh-keygen -R 38.145.34.41 || true
ssh -o StrictHostKeyChecking=no fedora@38.145.34.41 "sudo dnf -y update; sudo reboot now"
sleep 10

scp kubernetes.repo fedora@38.145.34.41:
ssh fedora@38.145.34.41 "sudo mv /home/fedora/kubernetes.repo /etc/yum.repos.d/kubernetes.repo"
ssh fedora@38.145.34.41 "sudo setenforce 0; sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config"
ssh fedora@38.145.34.41 "sudo dnf install -y docker kubelet kubeadm kubectl --disableexcludes=kubernetes"
ssh fedora@38.145.34.41 "sudo systemctl enable kubelet && systemctl start kubelet; sudo systemctl enable docker; sudo systemctl start docker"
ssh fedora@38.145.34.41 "sudo kubeadm config images pull"
ssh fedora@38.145.34.41 "sudo sysctl net.bridge.bridge-nf-call-iptables=1"
ssh fedora@38.145.34.41 "sudo kubeadm init --pod-network-cidr=10.244.0.0/16"
ssh fedora@38.145.34.41 "mkdir -p ~/.kube; sudo cp -i /etc/kubernetes/admin.conf ~/.kube/config; sudo chown $(id -u):$(id -g) ~/.kube/config"

# TODO ssh to internal IP of node1 through the master, run dnf update, reboot & install...
