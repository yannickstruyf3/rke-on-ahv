locals {
  ssh_key_default_name   = "rke_${var.rke_cluster_name}"
  cluster_uuid           = data.nutanix_subnet.vlan.cluster_uuid
  amount_of_control_vms  = 3
  control_vm_ips         = nutanix_virtual_machine.control_vm.*.nic_list_status.0.ip_endpoint_list.0.ip
  worker_vm_ips          = nutanix_virtual_machine.worker_vm.*.nic_list_status.0.ip_endpoint_list.0.ip
  admin_vm_ip            = nutanix_virtual_machine.admin_vm.nic_list_status.0.ip_endpoint_list.0.ip
  kubeconfig_path        = "/home/${var.admin_vm_username}/kube_config_cluster.yml"
  kubeconfig_scp_command = "scp -o \"StrictHostKeyChecking no\" -i ${local_file.rke_private_ssh_key.filename} ${var.admin_vm_username}@${local.admin_vm_ip}:${local.kubeconfig_path} ."
  scripts_path           = "./scripts"
}

