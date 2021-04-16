resource "nutanix_image" "rke_iso" {
  name        = "CentOS-8-rke"
  source_uri  = var.image_url
  description = "CentOS 8 image for rke uploaded via terraform"
  image_type  = "DISK_IMAGE"
}

