variable "k8s_master_count" {
  description = "Number of Kubernetes master nodes"
  default     = 1
}

variable "k8s_worker_count" {
  description = "Number of Kubernetes worker nodes"
  default     = 2
}

variable "k8s_version" {
  description = "Kubernetes version to be installed"
  default     = "1.28.0"
}

variable "vagrant_box" {
  description = "Vagrant box to use"
  default     = "ubuntu/focal64"
}

variable "vagrant_cpus" {
  description = "Number of CPUs for each VM"
  default     = 6
}

variable "vagrant_memory" {
  description = "Memory in MB for each VM"
  default     = 4096
}

