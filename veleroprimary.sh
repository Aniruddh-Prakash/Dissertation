
  truncate -s 0 ~/.ssh/known_hosts
  scp  -o StrictHostKeyChecking=no veleroroles/veleroroleprimary.sh ubuntu@api.primary.cnimigration.com:/home/ubuntu/veleroroleprimary.sh
  ssh -i ~/.ssh/id_rsa -oStrictHostKeyChecking=no ubuntu@api.primary.cnimigration.com "./veleroroleprimary.sh"
scp  -o StrictHostKeyChecking=no veleroinstall/veleroinstallprimary.sh ubuntu@api.primary.cnimigration.com:/home/ubuntu/veleroinstallprimary.sh
ssh -i ~/.ssh/id_rsa -oStrictHostKeyChecking=no ubuntu@api.primary.cnimigration.com "./veleroinstallprimary.sh"