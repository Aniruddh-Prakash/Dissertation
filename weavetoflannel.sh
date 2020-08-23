#This script will remove Weave and install Flannel
#!/bin/bash 
# By: Aniruddh Prakash
# Date: 21/08/2020
# Function:  Remove Weave and Install Flannel
#Script: calicotoweave
echo "This script will remove Weave and install Flannel"
echo "modifying cluster manifest to be CNI neutral"
export KOPS_CLUSTER_NAME=primary.cnimigration.com
export KOPS_STATE_STORE=s3://primary.cnimigration.com

kops replace -f  CNIyamls/nocni.yaml 
kops update cluster --name primary.cnimigration.com --yes
# This needs to run first on the master node
#the truncate command will empty the known_hosts file, an already existing host file will conflict with a changed host ip address
truncate -s 0 ~/.ssh/known_hosts
echo "Deleting Weave CNI and its components"
kops validate cluster | tail -n 6| head -n 4| awk -F " " '{print $1}' > nodes.txt
truncate -s 0 ~/.ssh/known_hosts

ssh -i  ~/.ssh/id_rsa -oStrictHostKeyChecking=no ubuntu@api.primary.cnimigration.com "kubectl delete -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')""

for i in $(cat nodes.txt); do ssh -i ~/.ssh/id_rsa -oStrictHostKeyChecking=no ubuntu@$i "ip link show | grep -E 'weave|veth|vxlan' | awk -F " " '{print $2}'| awk -F ":" '{print $1}'| while read line; do sudo ip link delete $line; done"; done

#forcing a rolling update on the master and nodes
kops rolling-update cluster --cloudonly --force --master-interval=1s --node-interval=1s --yes
sleep 20m
echo "Starting the installation of Flannel CNI plugin"
truncate -s 0 ~/.ssh/known_hosts

ssh -i  ~/.ssh/id_rsa -oStrictHostKeyChecking=no ubuntu@api.primary.cnimigration.com "kubectl apply -f "https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml""
sleep 2m
kops validate cluster