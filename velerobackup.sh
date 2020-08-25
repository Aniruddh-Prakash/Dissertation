#Backup cluster initialization

export KOPS_CLUSTER_NAME=backup.cnimigration.com
export KOPS_STATE_STORE=s3://backup.cnimigration.com
kops create cluster \
--state=s3://backup.cnimigration.com \
--node-count=3 \
--master-size=t3a.small \
--node-size=t2.micro \
--zones=eu-west-1a \
--name=backup.cnimigration.com \
--dns private \
--master-count 1 \
--vpc vpc-5c9c5825 \
--networking flannel \
--subnets subnet-f25221a8 \
--node-volume-size 20 \
--master-volume-size 20

kops update cluster --yes

sleep 20m

cat > admin-access.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "*",
            "Resource": "*"
        }
    ]
}
EOF
aws iam put-role-policy \
  --role-name masters.backup.cnimigration.com \
  --policy-name adminaccess \
  --policy-document file://admin-access.json
  
cat > admin-access.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "*",
            "Resource": "*"
        }
    ]
}
EOF
aws iam put-role-policy \
  --role-name nodes.backup.cnimigration.com \
  --policy-name adminaccess \
  --policy-document file://admin-access.json
  
 truncate -s 0 ~/.ssh/known_hosts
 
ssh -i ~/.ssh/id_rsa -oStrictHostKeyChecking=no ubuntu@api.backup.cnimigration.com " sudo apt install awscli -y; curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3;chmod +x get_helm.sh; ./get_helm.sh"

truncate -s 0 ~/.ssh/known_hosts
 scp  -o StrictHostKeyChecking=no veleroroles/velerorolebackup.sh ubuntu@api.backup.cnimigration.com:/home/ubuntu/velerorolebackup.sh 
 ssh -i ~/.ssh/id_rsa -oStrictHostKeyChecking=no ubuntu@api.backup.cnimigration.com "chmod +x velerorolebackup.sh; ./velerorolebackup.sh"
scp  -o StrictHostKeyChecking=no veleroinstall/veleroinstallbackup.sh ubuntu@api.backup.cnimigration.com:/home/ubuntu/veleroinstallbackup.sh
ssh -i ~/.ssh/id_rsa -oStrictHostKeyChecking=no ubuntu@api.backup.cnimigration.com "chmod +x veleroinstallbackup.sh; ./veleroinstallbackup.sh"
  

  
  
