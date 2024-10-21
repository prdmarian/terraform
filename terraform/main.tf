provider "local" {}
provider "template" {}

# Create the Vagrantfile
resource "local_file" "vagrantfile" {
  content = templatefile("${path.module}/Vagrantfile.tpl", {
    k8s_master_count = var.k8s_master_count
    k8s_worker_count = var.k8s_worker_count
    vagrant_box      = var.vagrant_box
    vagrant_cpus     = var.vagrant_cpus
    vagrant_memory   = var.vagrant_memory
  })
  filename = "${path.module}/Vagrantfile"
}

# Command to run vagrant up
resource "null_resource" "vagrant_up" {
  provisioner "local-exec" {
    command = "vagrant up"
  }
}

output "vagrantfile_path" {
  value = local_file.vagrantfile.filename
}
