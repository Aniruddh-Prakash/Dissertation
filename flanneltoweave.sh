# the following script will remove the flannel CNI plugin and install weave
#!/bin/bash 
# By: Aniruddh Prakash
# Date: 21/08/2020
# Function:  Remove FLannel and Install Weave
#Script: calicotoweave
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

#forcing a rolling update on the master and nodes
kops rolling-update cluster --cloudonly --force --master-interval=1s --node-interval=1s --yes
sleep 20m
echo "Starting the installation of Weave CNI plugin"
truncate -s 0 ~/.ssh/known_hosts

ssh -i  ~/.ssh/id_rsa -oStrictHostKeyChecking=no ubuntu@api.primary.cnimigration.com "kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')""
sleep 2m
kops validate cluster

