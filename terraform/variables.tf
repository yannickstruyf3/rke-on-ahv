variable "rke_cni" {
  type        = string
  description = "rke CNI name. Must be canal, calico, flannel, weave, or none. Default=calico"
  default     = "calico"
  validation {
    condition     = can(index(["canal", "calico", "flannel", "weave", "none"], var.rke_cni))
    error_message = "Variable rke_cni must be canal, calico, flannel, weave, or none."
  }
}
variable "rke_cluster_name" {
  type        = string
  description = "rke cluster name"
}

variable "rke_binary_url" {
  type        = string
  description = "This is the url of the RKE binary for Linux"
  default     = "https://github.com/rancher/rke/releases/download/v1.2.7/rke_linux-amd64"
}

variable "ntnx_csi_url" {
  type        = string
  default     = "http://download.nutanix.com/csi/v2.3.1/csi-v2.3.1.tar.gz"
  description = "Nutanix CSI Driver URL. Minimum supported version is 2.3.1"
}

variable "ntnx_pc_username" {
  type        = string
  description = "Prism Central username"
}

variable "ntnx_pc_password" {
  type        = string
  description = "Prism Central password"
}

variable "ntnx_pc_ip" {
  type        = string
  description = "Prism Central IP address"
}


variable "ntnx_pe_ip" {
  type        = string
  description = "Prism Element IP address. Required for CSI installation"
}

variable "ntnx_pe_port" {
  type        = number
  default     = 9440
  description = "Prism Element port"
}

variable "ntnx_pe_dataservice_ip" {
  type        = string
  description = "Prism Element dataservices IP address. Required for CSI installation"
}

variable "ntnx_pe_storage_container" {
  type        = string
  description = "This is the Nutanix Storage Container where the requested Persistent Volume Claims will get their volumes created. You can enable things like compression and deduplication in a Storage Container. The recommendation is to create at least one storage container in Prism Element well identified for Kubernetes usage. This will facilitate the search of persistent volumes when the environment scales."
}

variable "ntnx_pe_username" {
  type        = string
  description = "Prism Element username. Required for CSI installation"
}

variable "ntnx_pe_password" {
  type        = string
  description = "Prism Element password. Required for CSI installation"
}

variable "subnet_name" {
  type        = string
  description = "Subnet used for rke deployment."
}

variable "image_url" {
  type        = string
  default     = "https://cloud.centos.org/centos/8/x86_64/images/CentOS-8-GenericCloud-8.2.2004-20200611.2.x86_64.qcow2"
  description = "CentOS image URL required to deploy rke"
}

variable "amount_of_rke_worker_vms" {
  type        = number
  default     = 2
  description = "Amount of rke worker VMs. Changing this value will result in scale-up or scale-down of the cluster"
  validation {
    condition     = var.amount_of_rke_worker_vms > 0
    error_message = "Minimum 1 worker node is required."
  }
}

variable "admin_vm_username" {
  type        = string
  description = "Username used for rke installation. Default: nutanix"
  default     = "nutanix"
}

variable "rke_worker_vm_config" {
  description = "Configuration of the rke worker VMs."
  type = object({
    num_sockets          = number
    memory_size_mib      = number
    num_vcpus_per_socket = number
    disk_size_mib        = number
    }
  )
  default = {
    num_sockets          = 2
    memory_size_mib      = 8 * 1024
    disk_size_mib        = 131072
    num_vcpus_per_socket = 1
  }
}

variable "rke_control_vm_config" {
  description = "Configuration of the rke control VMs."
  type = object({
    num_sockets          = number
    memory_size_mib      = number
    num_vcpus_per_socket = number
    disk_size_mib        = number
    }
  )
  default = {
    num_sockets          = 2
    memory_size_mib      = 8 * 1024
    disk_size_mib        = 131072
    num_vcpus_per_socket = 1
  }
}

variable "rke_admin_vm_config" {
  description = "Configuration of the rke admin VM."
  type = object({
    num_sockets          = number
    memory_size_mib      = number
    num_vcpus_per_socket = number
    disk_size_mib        = number
    }
  )
  default = {
    num_sockets          = 2
    memory_size_mib      = 4 * 1024
    disk_size_mib        = 131072
    num_vcpus_per_socket = 1
  }
}

