output "k3s_servers_ips" {
  depends_on = [
    data.oci_core_instance_pool_instances.k3s_servers_instances,
  ]
  value = data.oci_core_instance.k3s_servers_instances_ips.*.public_ip
}

output "k3s_workers_ips" {
  depends_on = [
    data.oci_core_instance_pool_instances.k3s_workers_instances,
  ]
  value = data.oci_core_instance.k3s_workers_instances_ips.*.public_ip
}

output "public_lb_ip" {
  value = oci_network_load_balancer_network_load_balancer.k3s_public_lb.ip_addresses
}