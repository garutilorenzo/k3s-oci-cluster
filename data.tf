resource "random_password" "k3s_token" {
  length  = 55
  special = false
}

data "template_cloudinit_config" "k3s_server_tpl" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/files/k3s-install-server.sh", {
      k3s_version                       = var.k3s_version,
      k3s_subnet                        = var.k3s_subnet,
      k3s_token                         = random_password.k3s_token.result,
      is_k3s_server                     = true,
      disable_ingress                   = var.disable_ingress,
      install_traefik2                  = var.install_traefik2,
      install_nginx_ingress             = var.install_nginx_ingress,
      nginx_ingress_release             = var.nginx_ingress_release,
      install_certmanager               = var.install_certmanager,
      certmanager_release               = var.certmanager_release,
      certmanager_email_address         = var.certmanager_email_address,
      compartment_ocid                  = var.compartment_ocid,
      availability_domain               = var.availability_domain,
      k3s_url                           = oci_load_balancer_load_balancer.k3s_load_balancer.ip_address_details[0].ip_address,
      k3s_tls_san                       = oci_load_balancer_load_balancer.k3s_load_balancer.ip_address_details[0].ip_address,
      expose_kubeapi                    = var.expose_kubeapi,
      k3s_tls_san_public                = local.public_lb_ip[0],
      argocd_image_updater_release      = var.argocd_image_updater_release,
      install_argocd_image_updater      = var.install_argocd_image_updater,
      install_argocd                    = var.install_argocd,
      argocd_release                    = var.argocd_release,
      install_longhorn                  = var.install_longhorn,
      longhorn_release                  = var.longhorn_release,
      ingress_controller_http_nodeport  = var.ingress_controller_http_nodeport,
      ingress_controller_https_nodeport = var.ingress_controller_https_nodeport,
    })
  }
}

data "template_cloudinit_config" "k3s_worker_tpl" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/files/k3s-install-agent.sh", {
      k3s_version                       = var.k3s_version,
      k3s_subnet                        = var.k3s_subnet,
      k3s_token                         = random_password.k3s_token.result,
      is_k3s_server                     = false,
      disable_ingress                   = var.disable_ingress,
      k3s_url                           = oci_load_balancer_load_balancer.k3s_load_balancer.ip_address_details[0].ip_address,
      http_lb_port                      = var.http_lb_port,
      install_traefik2                  = var.install_traefik2,
      install_nginx_ingress             = var.install_nginx_ingress,
      install_longhorn                  = var.install_longhorn,
      https_lb_port                     = var.https_lb_port,
      ingress_controller_http_nodeport  = var.ingress_controller_http_nodeport,
      ingress_controller_https_nodeport = var.ingress_controller_https_nodeport,
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
