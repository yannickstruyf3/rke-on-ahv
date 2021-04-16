## Set the name of the Kubernetes cluster  
cluster_name: ${rke_cluster_name}

## Nodes for the RKE cluster
nodes:
%{ for ip in rke_control_nodes }
    - address: ${ip}
      user: ${ssh_username}
      role:
        - controlplane
        - etcd
      port: 22
%{ endfor }
%{ for ip in rke_worker_nodes }
    - address: ${ip}
      user: ${ssh_username}
      role:
        - worker
      port: 22
%{ endfor }

# Specify network plugin-in (canal, calico, flannel, weave, or none)
network:
    plugin: ${rke_cni}

## Cluster level SSH private key
ssh_key_path: ~/.ssh/id_rsa

# All add-on manifests MUST specify a namespace
addons: |-
    ---
    apiVersion: storage.k8s.io/v1beta1
    kind: CSIDriver
    metadata:
        name: csi.nutanix.com
    spec:
        attachRequired: false
        podInfoOnMount: true
    ---
    apiVersion: v1
    kind: Secret
    metadata:
        name: ntnx-secret
        namespace: kube-system
    data:
        key: ${csi_secret}
    ---
    allowVolumeExpansion: true
    apiVersion: storage.k8s.io/v1
    kind: StorageClass
    metadata:
        annotations:
            storageclass.kubernetes.io/is-default-class: "true"
        name: nutanix-default
    parameters:
        csi.storage.k8s.io/provisioner-secret-name: ntnx-secret
        csi.storage.k8s.io/provisioner-secret-namespace: kube-system
        csi.storage.k8s.io/node-publish-secret-name: ntnx-secret  
        csi.storage.k8s.io/node-publish-secret-namespace: kube-system
        csi.storage.k8s.io/controller-expand-secret-name: ntnx-secret
        csi.storage.k8s.io/controller-expand-secret-namespace: kube-system
        csi.storage.k8s.io/fstype: ext4
        dataServiceEndPoint: ${ntnx_pe_dataservice_ip}:3260
        flashMode: DISABLED
        storageContainer: ${ntnx_pe_storage_container}
        chapAuth: DISABLED
        storageType: NutanixVolumes
    provisioner: csi.nutanix.com
    reclaimPolicy: Delete

addons_include:
    - csi/ntnx-csi-rbac.yaml
    - csi/ntnx-csi-node.yaml
    - csi/ntnx-csi-provisioner.yaml