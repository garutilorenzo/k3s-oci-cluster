resource "oci_network_load_balancer_network_load_balancer" "k3s_load_balancer" {
  compartment_id = var.compartment_ocid
  display_name   = "k3s internal load balancer"
  subnet_id      = oci_core_subnet.oci_core_subnet11.id

  is_private                     = true
  is_preserve_source_destination = false

  freeform_tags = {
    "provisioner"           = "terraform"
    "environment"           = "${var.environment}"
    "${var.unique_tag_key}" = "${var.unique_tag_value}"
  }
}

resource "oci_network_load_balancer_listener" "k3s_kube_api_listener" {
  default_backend_set_name = oci_network_load_balancer_backend_set.k3s_kube_api_backend_set.name
  name                     = "k3s kube api listener"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.k3s_load_balancer.id
  port                     = var.kube_api_port
  protocol                 = "TCP"
}

resource "oci_network_load_balancer_backend_set" "k3s_kube_api_backend_set" {
  health_checker {
    protocol = "TCP"
    port     = var.kube_api_port
  }

  name                     = "k3s kube api backend"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.k3s_load_balancer.id
  policy                   = "FIVE_TUPLE"
  is_preserve_source       = true
}

resource "oci_network_load_balancer_backend" "k3s_kube_api_backend" {
  depends_on = [
    oci_core_instance_pool.k3s_servers,
  ]

  count                    = var.k3s_server_pool_size
  backend_set_name         = oci_network_load_balancer_backend_set.k3s_kube_api_backend_set.name
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.k3s_load_balancer.id
  port                     = var.kube_api_port

  target_id = data.oci_core_instance_pool_instances.k3s_servers_instances.instances[count.index].id
}