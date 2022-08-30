resource "oci_load_balancer_load_balancer" "k3s_load_balancer" {
  lifecycle {
    ignore_changes = [network_security_group_ids]
  }

  compartment_id = var.compartment_ocid
  display_name   = var.k3s_load_balancer_name
  shape          = var.public_lb_shape
  subnet_ids     = [oci_core_subnet.oci_core_subnet11.id]

  freeform_tags = {
    "provisioner"           = "terraform"
    "environment"           = "${var.environment}"
    "${var.unique_tag_key}" = "${var.unique_tag_value}"
  }

  ip_mode    = "IPV4"
  is_private = true

  shape_details {
    maximum_bandwidth_in_mbps = 10
    minimum_bandwidth_in_mbps = 10
  }
}

resource "oci_load_balancer_listener" "k3s_kube_api_listener" {
  default_backend_set_name = oci_load_balancer_backend_set.k3s_kube_api_backend_set.name
  load_balancer_id         = oci_load_balancer_load_balancer.k3s_load_balancer.id
  name                     = "K3s__kube_api_listener"
  port                     = var.kube_api_port
  protocol                 = "TCP"
}

resource "oci_load_balancer_backend_set" "k3s_kube_api_backend_set" {
  health_checker {
    protocol = "TCP"
    port     = var.kube_api_port
  }
  load_balancer_id = oci_load_balancer_load_balancer.k3s_load_balancer.id
  name             = "K3s__kube_api_backend_set"
  policy           = "ROUND_ROBIN"
}

resource "oci_load_balancer_backend" "k3s_kube_api_backend" {
  depends_on = [
    oci_core_instance_pool.k3s_servers,
  ]

  count            = var.k3s_server_pool_size
  backendset_name  = oci_load_balancer_backend_set.k3s_kube_api_backend_set.name
  ip_address       = data.oci_core_instance.k3s_servers_instances_ips[count.index].private_ip
  load_balancer_id = oci_load_balancer_load_balancer.k3s_load_balancer.id
  port             = var.kube_api_port
}

resource "oci_load_balancer_backend" "k3s_kube_api_backend_primary" {
  depends_on = [
    oci_core_instance.k3s_primary_server
  ]
  backendset_name = oci_load_balancer_backend_set.k3s_kube_api_backend_set.name
  ip_address = oci_core_instance.k3s_primary_server.private_ip
  load_balancer_id = oci_load_balancer_load_balancer.k3s_load_balancer.id
  port = var.kube_api_port
}
