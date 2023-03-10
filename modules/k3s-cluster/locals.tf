locals {
  public_lb_ip = [for interface in oci_network_load_balancer_network_load_balancer.k3s_public_lb.ip_addresses : interface.ip_address if interface.is_public == true]
  my_public_ip = var.my_public_ip_cidr != "" ? var.my_public_ip_cidr : "${data.http.my_public_ip.response_body}/32"

  kube_config = replace(ssh_resource.get_kube_master_config.result,
    "https://127.0.0.1:${var.kube_api_port}",
    "https://${oci_network_load_balancer_network_load_balancer.k3s_public_lb.ip_addresses[0].ip_address}:${var.kube_api_port}"
  )

  kube_config_localfile = pathexpand(var.kubeconfig_location)
}
