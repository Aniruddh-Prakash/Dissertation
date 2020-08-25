#Installing Kube2iam, a tool that enables pod access to IAM credentials
# initializing the kube2iam pod which is a 
cat > values-kube2iam.yaml <<EOF
extraArgs:
  base-role-arn: arn:aws:iam::671560363271:role/
  default-role: kube2iam-default

host:
  iptables: true
  interface: "cni0"

rbac:
  create: true
EOF

helm repo add stable https://kubernetes-charts.storage.googleapis.com
helm install iam  \
    --namespace kube-system \
    -f values-kube2iam.yaml \
    stable/kube2iam
	
 cat > kube2iam-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "sts:AssumeRole"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:iam::671560363271:role/k8s-*"
      ]
    }
  ]
}
EOF

aws iam put-role-policy \
    --role-name nodes.primary.cnimigration.com \
    --policy-name kube2iam \
    --policy-document file://kube2iam-policy.json \
	






cat > node-trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    },
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::671560363271:role/nodes.primary.cnimigration.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

aws iam create-role \
  --role-name k8s-velero \
  --assume-role-policy-document \
  file://node-trust-policy.json
  
  
  
 cat > s3-velero-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeVolumes",
        "ec2:DescribeSnapshots",
        "ec2:CreateTags",
        "ec2:CreateVolume",
        "ec2:CreateSnapshot",
        "ec2:DeleteSnapshot"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:PutObject",
        "s3:AbortMultipartUpload",
        "s3:ListMultipartUploadParts"
      ],
      "Resource": [
        "arn:aws:s3:::wordpress.primary.cnimigration.com/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::wordpress.primary.cnimigration.com"
      ]
    }
  ]
}
EOF

aws iam put-role-policy \
  --role-name k8s-velero \
  --policy-name s3 \
  --policy-document file://s3-velero-policy.json