data "template_cloudinit_config" "k3s_server_tpl" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/files/k3s-install-server.sh", {
      k3s_token             = var.k3s_token, is_k3s_server = true,
      install_nginx_ingress = var.install_nginx_ingress,
      compartment_ocid      = var.compartment_ocid,
      availability_domain   = var.availability_domain,
      k3s_url               = oci_load_balancer_load_balancer.k3s_load_balancer.ip_addresses[0],
      k3s_tls_san           = oci_load_balancer_load_balancer.k3s_load_balancer.ip_addresses[0],
      install_longhorn      = var.install_longhorn,
      longhorn_release      = var.longhorn_release
    })
  }
}

data "template_cloudinit_config" "k3s_worker_tpl" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/files/k3s-install-agent.sh", {
      k3s_token     = var.k3s_token,
      is_k3s_server = false,
      k3s_url       = oci_load_balancer_load_balancer.k3s_load_balancer.ip_addresses[0],
    })
  }
}

data "oci_core_instance_pool_instances" "k3s_workers_instances" {
  compartment_id   = var.compartment_ocid
  instance_pool_id = oci_core_instance_pool.k3s_workers.id
}

data "oci_core_instance" "k3s_workers_instances_ips" {
  count       = var.k3s_worker_pool_size
  instance_id = data.oci_core_instance_pool_instances.k3s_workers_instances.instances[count.index].id
}

data "oci_core_instance_pool_instances" "k3s_servers_instances" {
  depends_on = [
    oci_core_instance_pool.k3s_servers,
  ]
  compartment_id   = var.compartment_ocid
  instance_pool_id = oci_core_instance_pool.k3s_servers.id
}

data "oci_core_instance" "k3s_servers_instances_ips" {
  count       = var.k3s_server_pool_size
  instance_id = data.oci_core_instance_pool_instances.k3s_servers_instances.instances[count.index].id
}