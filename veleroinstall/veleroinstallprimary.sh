 cat > velero-values.yaml <<EOF
podAnnotations:
  iam.amazonaws.com/role: k8s-velero

configuration:
  provider: aws
  backupStorageLocation:
    name: aws
    bucket: wordpress.primary.cnimigration.com
    config:
      region: eu-west-1
  volumeSnapshotLocation:
    name: aws
    config:
      region: eu-west-1

initContainers:
  - name: velero-plugin-for-aws
    image: velero/velero-plugin-for-aws:v1.0.0
    imagePullPolicy: IfNotPresent
    volumeMounts:
      - mountPath: /target
        name: plugins
EOF

helm repo add vmware-tanzu https://vmware-tanzu.github.io/helm-charts

helm install wordpressbackup \
  --namespace velero \
  -f velero-values.yaml \
  vmware-tanzu/velero
  
  wget https://github.com/vmware-tanzu/velero/releases/download/v1.4.2/velero-v1.4.2-linux-amd64.tar.gz
   tar -xvf velero-v1.4.2-linux-amd64.tar.gz
    sudo cp velero-v1.4.2-linux-amd64/velero /usr/local/bin/velero
  
  
  velero backup create wordpress-backup --include-namespaces wordpressapp --storage-location aws
  
  velero -n wordpressapp backup get