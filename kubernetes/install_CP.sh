#!/bin/bash
#0 - Creating a Cluster
#Create our kubernetes cluster, specify a pod network range matching that in calico.yaml! 
#Only on the Control Plane Node, download the yaml files for the pod network.
wget https://docs.projectcalico.org/manifests/calico.yaml

sudo kubeadm init > output.txt

#Configure our account on the Control Plane Node to have admin access to the API server from a non-privileged account.
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

#1 - Creating a Pod Network
#Deploy yaml file for your pod network.
kubectl apply -f calico.yaml

#Look for the all the system pods and calico pods to change to Running. 
#The DNS pod won't start (pending) until the Pod network is deployed and Running.
kubectl get pods --all-namespaces