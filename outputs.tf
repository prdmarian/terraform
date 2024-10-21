output "k8s_master_ips" {
  description = "IP addresses of Kubernetes master nodes"
  value       = ["k8s-master-1", "k8s-master-2"]
}

output "k8s_worker_ips" {
  description = "IP addresses of Kubernetes worker nodes"
  value       = ["k8s-worker-1", "k8s-worker-2"]
}
