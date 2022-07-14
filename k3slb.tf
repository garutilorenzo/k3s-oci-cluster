resource "oci_network_load_balancer_network_load_balancer" "k3s_public_lb" {
  compartment_id             = var.compartment_ocid
  display_name               = var.public_load_balancer_name
  subnet_id                  = oci_core_subnet.oci_core_subnet11.id
  network_security_group_ids = [oci_core_network_security_group.public_lb_nsg.id]

  is_private                     = false
  is_preserve_source_destination = false

  freeform_tags = {
    "provisioner"           = "terraform"
    "environment"           = "${var.environment}"
    "${var.unique_tag_key}" = "${var.unique_tag_value}"
  }
}

# HTTP
resource "oci_network_load_balancer_listener" "k3s_http_listener" {
  default_backend_set_name = oci_network_load_balancer_backend_set.k3s_http_backend_set.name
  name                     = "k3s_http_listener"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.k3s_public_lb.id
  port                     = var.http_lb_port
  protocol                 = "TCP"
}

resource "oci_network_load_balancer_backend_set" "k3s_http_backend_set" {
  health_checker {
    protocol = "TCP"
    port     = var.http_lb_port
  }

  name                     = "k3s_http_backend"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.k3s_public_lb.id
  policy                   = "FIVE_TUPLE"
  is_preserve_source       = true
}

resource "oci_network_load_balancer_backend" "k3s_http_backend" {
  depends_on = [
    oci_core_instance_pool.k3s_workers,
  ]

  count                    = var.k3s_server_pool_size
  backend_set_name         = oci_network_load_balancer_backend_set.k3s_http_backend_set.name
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.k3s_public_lb.id
  name                     = format("%s-%s", "https", data.oci_core_instance_pool_instances.k3s_workers_instances.instances[count.index].display_name)
  port                     = var.http_lb_port
  target_id                = data.oci_core_instance_pool_instances.k3s_workers_instances.instances[count.index].id
}

# HTTPS
resource "oci_network_load_balancer_listener" "k3s_https_listener" {
  default_backend_set_name = oci_network_load_balancer_backend_set.k3s_https_backend_set.name
  name                     = "k3s_https_listener"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.k3s_public_lb.id
  port                     = var.https_lb_port
  protocol                 = "TCP"
}

resource "oci_network_load_balancer_backend_set" "k3s_https_backend_set" {
  health_checker {
    protocol = "TCP"
    port     = var.https_lb_port
  }

  name                     = "k3s_https_backend"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.k3s_public_lb.id
  policy                   = "FIVE_TUPLE"
  is_preserve_source       = true
}

resource "oci_network_load_balancer_backend" "k3s_https_backend" {
  depends_on = [
    oci_core_instance_pool.k3s_workers,
  ]

  count                    = var.k3s_server_pool_size
  backend_set_name         = oci_network_load_balancer_backend_set.k3s_https_backend_set.name
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.k3s_public_lb.id
  name                     = data.oci_core_instance_pool_instances.k3s_workers_instances.instances[count.index].display_name
  port                     = var.https_lb_port
  target_id                = data.oci_core_instance_pool_instances.k3s_workers_instances.instances[count.index].id
}