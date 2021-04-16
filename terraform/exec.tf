resource "null_resource" "copy_cluster_yml" {
  depends_on = [
    nutanix_virtual_machine.worker_vm,
    nutanix_virtual_machine.control_vm,
    nutanix_virtual_machine.admin_vm
  ]
  triggers = {
    worker_vm_ips = join(",", local.worker_vm_ips),
  }
  connection {
    user        = var.admin_vm_username
    private_key = file(local_file.rke_private_ssh_key.filename)
    host        = nutanix_virtual_machine.admin_vm.nic_list_status[0].ip_endpoint_list[0].ip
  }
  provisioner "file" {
    destination = "~/cluster.yml"
    content = templatefile("${path.module}/templates/cluster.yml.tpl", {
      ssh_username = var.admin_vm_username,
      "rke_worker_nodes" : local.worker_vm_ips,
      "rke_control_nodes" : local.control_vm_ips,
      "csi_secret" : base64encode("${var.ntnx_pe_ip}:${var.ntnx_pe_port}:${var.ntnx_pe_username}:${var.ntnx_pe_password}"),
      "ntnx_pe_dataservice_ip" : var.ntnx_pe_dataservice_ip,
      "ntnx_pe_storage_container" : var.ntnx_pe_storage_container,
      "rke_cluster_name" : var.rke_cluster_name,
      "rke_cni" : var.rke_cni
    })
  }
}

resource "null_resource" "configure_admin_vm" {
  depends_on = [
    null_resource.copy_cluster_yml
  ]
  triggers = {
    scripts_path     = local.scripts_path
    admin_vm_user    = [for x in nutanix_virtual_machine.admin_vm.categories : x.value if can(regex("LOGIN_USER", x.name))][0]
    private_key_path = [for x in nutanix_virtual_machine.admin_vm.categories : x.value if can(regex("SSH_KEY", x.name))][0]
    admin_vm_ip      = nutanix_virtual_machine.admin_vm.nic_list_status[0].ip_endpoint_list[0].ip
  }
  connection {
    user        = self.triggers.admin_vm_user
    private_key = file(self.triggers.private_key_path)
    host        = self.triggers.admin_vm_ip
  }

  provisioner "file" {
    content     = file(local_file.rke_private_ssh_key.filename)
    destination = "~/.ssh/id_rsa"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo yum install -y wget",
      "wget -O rke ${var.rke_binary_url}",
      "sudo mv rke /usr/local/bin",
      "sudo chmod +x /usr/local/bin/rke",
      "curl -s -o csi.tar.gz ${var.ntnx_csi_url}",
      "mkdir -p csi && tar -xvf csi.tar.gz -C csi --strip-components 1",
    ]
  }
}
resource "null_resource" "run_rke_up" {
  depends_on = [
    null_resource.configure_admin_vm,
    null_resource.copy_cluster_yml
  ]
  triggers = {
    cluster_yaml_id = null_resource.copy_cluster_yml.id
  }
  connection {
    user        = var.admin_vm_username
    private_key = file(local_file.rke_private_ssh_key.filename)
    host        = nutanix_virtual_machine.admin_vm.nic_list_status[0].ip_endpoint_list[0].ip
  }
  provisioner "remote-exec" {
    inline = [
      "rke up"
    ]
  }
}
