resource "nutanix_category_key" "rke_node_type" {
  name = "rke-${var.rke_cluster_name}-NODE_TYPE"
}

resource "nutanix_category_value" "rke_node_type_worker" {
  name  = nutanix_category_key.rke_node_type.id
  value = "worker"
}

resource "nutanix_category_value" "rke_node_type_control" {
  name  = nutanix_category_key.rke_node_type.id
  value = "control"
}

resource "nutanix_category_value" "rke_node_type_admin" {
  name  = nutanix_category_key.rke_node_type.id
  value = "admin"
}

resource "nutanix_category_key" "rke_cluster_name" {
  name = "rke-${var.rke_cluster_name}-CLUSTER_NAME"
}

resource "nutanix_category_value" "rke_cluster_name" {
  name  = nutanix_category_key.rke_cluster_name.id
  value = var.rke_cluster_name
}

resource "nutanix_category_key" "rke_login_user" {
  name = "rke-${var.rke_cluster_name}-LOGIN_USER"
}

resource "nutanix_category_value" "rke_login_user" {
  name  = nutanix_category_key.rke_login_user.id
  value = var.admin_vm_username
}

resource "nutanix_category_key" "rke_ssh_key" {
  name = "rke-${var.rke_cluster_name}-SSH_KEY"
}

resource "nutanix_category_value" "rke_ssh_key" {
  name  = nutanix_category_key.rke_ssh_key.id
  value = local_file.rke_private_ssh_key.filename
}

resource "nutanix_category_key" "rke_admin_vm_ip" {
  name = "rke-${var.rke_cluster_name}-ADMIN_VM_IP"
}

resource "nutanix_category_value" "rke_admin_vm_ip" {
  name  = nutanix_category_key.rke_admin_vm_ip.id
  value = nutanix_virtual_machine.admin_vm.nic_list_status[0].ip_endpoint_list[0].ip
}
