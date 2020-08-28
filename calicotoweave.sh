
#!/bin/bash 
# By: Aniruddh Prakash
# Date: 21/08/2020
# Function:  Remove Calico and Install Weave
#Script: calicotoweave
echo "This script will remove calico CNI and install weave"
echo "modifying cluster manifest to be CNI neutral"
export KOPS_CLUSTER_NAME=primary.cnimigration.com
export KOPS_STATE_STORE=s3://primary.cnimigration.com
echo "modifying cluster manifest to be CNI neutral"
kops replace -f  CNIyamls/nocni.yaml 
kops update cluster --name primary.cnimigration.com --yes
# This needs to run first on the master node
#the truncate command will empty the known_hosts file, an already existing host file will conflict with a changed host ip address
truncate -s 0 ~/.ssh/known_hosts
#cleaning calico interfaces and iptables rule
echo "Deleting Calico using manifest and cleaning iptables rules"
kops validate cluster | tail -n 6| head -n 4| awk -F " " '{print $1}' > nodes.txt
truncate -s 0 ~/.ssh/known_hosts
scp  -o StrictHostKeyChecking=no CNIyamls/calico_modified.yaml ubuntu@api.primary.cnimigration.com:/home/ubuntu/calico.yaml
ssh -i  ~/.ssh/id_rsa -oStrictHostKeyChecking=no ubuntu@api.primary.cnimigration.com "kubectl delete -f calico.yaml"
#copy calico iptables removal script to each node
for i in $(cat nodes.txt); do scp  -o StrictHostKeyChecking=no CNIyamls/remove_calicoiptables.sh ubuntu@$i:/home/ubuntu/remove_calicoiptables.sh; done
#the people at tigera designed the calico iptables removal script 
for i in $(cat nodes.txt); do ssh -i ~/.ssh/id_rsa -oStrictHostKeyChecking=no ubuntu@$i "./remove_calicoiptables.sh"; done
for i in $(cat nodes.txt); do ssh -i ~/.ssh/id_rsa -oStrictHostKeyChecking=no ubuntu@$i " sudo rm -rf /etc/cni/net.d/*"; done
#removing the tunl0@NONE interface from the kernel
for i in $(cat nodes.txt); do ssh -i ~/.ssh/id_rsa -oStrictHostKeyChecking=no ubuntu@$i "sudo modprobe -r ipip"; done 
echo "Removed Calico CNI plugin"
#forcing a rolling update on the master and nodes
echo " Starting a rolling update"
kops rolling-update cluster --cloudonly --force --master-interval=1s --node-interval=1s --yes
sleep 20m
echo " Rolling Update done"
echo "Starting the installation of Weave CNI plugin"
truncate -s 0 ~/.ssh/known_hosts
echo " Applying Weave CNI Manifest"
ssh -i  ~/.ssh/id_rsa -oStrictHostKeyChecking=no ubuntu@api.primary.cnimigration.com "kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')""
sleep 2m
echo " Installed the Weave CNI Plugin"
kops validate cluster