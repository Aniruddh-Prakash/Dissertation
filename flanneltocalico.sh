#!/bin/bash 
# By: Aniruddh Prakash
# Date: 21/08/2020
# Function:  Remove Flannel CNI and install Calico
#Script: flanneltocalico
echo "the following script will remove the flannel CNI plugin and its residue components"

echo "Setting Environment Variables to the primary cluster"
export KOPS_CLUSTER_NAME=primary.cnimigration.com
export KOPS_STATE_STORE=s3://primary.cnimigration.com
echo "modifying cluster manifest to be CNI neutral"
kops replace -f  CNIyamls/nocni.yaml 
kops update cluster --name primary.cnimigration.com --yes
echo "Changed the cluster manifest to CNI neutral"
# Remove flannel components such as Daemonsets, deployments, and services 
# This needs to run first on the master node
#the truncate command will empty the known_hosts file, an already existing host file will conflict with a changed host ip address
truncate -s 0 ~/.ssh/known_hosts
echo "Deleting flannel Daemonsets, and residue"
kops validate cluster | tail -n 6| head -n 4| awk -F " " '{print $1}' > nodes.txt 
ssh -i  ~/.ssh/id_rsa -oStrictHostKeyChecking=no ubuntu@api.primary.cnimigration.com "kubectl delete $(kubectl get all -n kube-system | grep flannel | tail -n 1 | awk -F ' ' '{print $1}') -n kube-system"
truncate -s 0 ~/.ssh/known_hosts
echo " removed flannel pods and daemonsets"
# the following tasks require sudo permissions on the host machine
# Loop through the master and worker nodes and delete flannel residue
echo "Removing flannel residue interfaces and links"
for i in $(cat nodes.txt); do ssh -i ~/.ssh/id_rsa -oStrictHostKeyChecking=no ubuntu@$i "sudo rm -rf /etc/cni/net.d/*"; done
for i in $(cat nodes.txt); do ssh -i ~/.ssh/id_rsa -oStrictHostKeyChecking=no ubuntu@$i "sudo ip link delete flannel.1"; done
#rolling update the cluster once flannel is removed
kops rolling-update cluster --cloudonly --force --master-interval=1s --node-interval=1s --yes
sleep 20m
echo "Starting the installation of Calico CNI plugin"
#install calico
#under the CNIyamls directory, in the official calico config yaml obtained from  https://docs.projectcalico.org/manifests/calico.yaml, remove the comment string '#' from the CALICO_IPV4_POOLCIDR lines
#the CIDR will be replaced with the cluster CIDR before applying the calico manifest
#the critical calico system nodes will not start if the cluster CIDR is not initialized
#100.96.0.0/11 is the cluster CIDR
#copy modified yaml to the home directory on master node
truncate -s 0 ~/.ssh/known_hosts
scp  -o StrictHostKeyChecking=no CNIyamls/calico_modified.yaml ubuntu@api.primary.cnimigration.com:/home/ubuntu/calico.yaml
#apply modified manifest file
truncate -s 0 ~/.ssh/known_hosts
echo "Applying official Calico Manifest"
ssh -i  ~/.ssh/id_rsa -oStrictHostKeyChecking=no ubuntu@api.primary.cnimigration.com "kubectl apply -f calico.yaml"
sleep 2m
echo " Calico CNI Plugin Installed successfully"
kops validate cluster


