# the following script is the master script that calls the scripts for installing velero roles and intializing velero pods
#!/bin/bash 
# By: Aniruddh Prakash
# Date: 21/08/2020
#Script: veleroprimary.sh


  truncate -s 0 ~/.ssh/known_hosts
  echo " Kube2iam and k8s-velero role configuration"
  scp  -o StrictHostKeyChecking=no veleroroles/veleroroleprimary.sh ubuntu@api.primary.cnimigration.com:/home/ubuntu/veleroroleprimary.sh
  ssh -i ~/.ssh/id_rsa -oStrictHostKeyChecking=no ubuntu@api.primary.cnimigration.com "./veleroroleprimary.sh"
   echo "Starting the installation of Velero backup pods"
scp  -o StrictHostKeyChecking=no veleroinstall/veleroinstallprimary.sh ubuntu@api.primary.cnimigration.com:/home/ubuntu/veleroinstallprimary.sh
ssh -i ~/.ssh/id_rsa -oStrictHostKeyChecking=no ubuntu@api.primary.cnimigration.com "./veleroinstallprimary.sh"