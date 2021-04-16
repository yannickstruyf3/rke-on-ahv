provider "nutanix" {
  wait_timeout = 4
  insecure     = true
  port         = 9440
  username     = var.ntnx_pc_username
  password     = var.ntnx_pc_password
  endpoint     = var.ntnx_pc_ip
}
