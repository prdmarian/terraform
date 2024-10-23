resource "local_file" "vagrant" {
  content = templatefile("${path.module}/Vagrantfile.tpl", {
    k8s_master_count = var.k8s_master_count
    k8s_worker_count = var.k8s_worker_count
    vagrant_box      = var.vagrant_box
    vagrant_cpus     = var.vagrant_cpus
    vagrant_memory   = var.vagrant_memory
  })
  filename = "${path.module}/Vagrantfile"
}
