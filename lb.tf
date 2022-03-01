resource "oci_load_balancer_load_balancer" "k3s_public_lb" {
  compartment_id             = var.compartment_ocid
  display_name               = var.public_load_balancer_name
  shape                      = var.public_lb_shape
  subnet_ids                 = [oci_core_subnet.oci_core_subnet11.id]
  network_security_group_ids = [oci_core_network_security_group.public_lb_nsg.id]

  freeform_tags = {
    "provisioner"           = "terraform"
    "environment"           = "${var.environment}"
    "${var.unique_tag_key}" = "${var.unique_tag_value}"
  }

  ip_mode    = "IPV4"
  is_private = false

  shape_details {
    maximum_bandwidth_in_mbps = 10
    minimum_bandwidth_in_mbps = 10
  }
}

# HTTP 
resource "oci_load_balancer_listener" "k3s_http_listener" {
  default_backend_set_name = oci_load_balancer_backend_set.k3s_http_backend_set.name
  load_balancer_id         = oci_load_balancer_load_balancer.k3s_public_lb.id
  name                     = "K3s_http_listener"
  port                     = var.http_lb_port
  protocol                 = "HTTP"
}

resource "oci_load_balancer_backend_set" "k3s_http_backend_set" {
  health_checker {
    protocol    = "HTTP"
    port        = var.http_lb_port
    url_path    = "/healthz"
    return_code = 200
  }
  load_balancer_id = oci_load_balancer_load_balancer.k3s_public_lb.id
  name             = "K3s_http_backend_set"
  policy           = "ROUND_ROBIN"
}

resource "oci_load_balancer_backend" "k3s_http_backend" {
  depends_on = [
    oci_core_instance_pool.k3s_workers,
  ]

  count            = var.k3s_worker_pool_size
  backendset_name  = oci_load_balancer_backend_set.k3s_http_backend_set.name
  ip_address       = data.oci_core_instance.k3s_workers_instances_ips[count.index].private_ip
  load_balancer_id = oci_load_balancer_load_balancer.k3s_public_lb.id
  port             = var.http_lb_port
}

# HTTPS
resource "oci_load_balancer_certificate" "k3s_https_certificate" {
  certificate_name = "K3s_lb_https_cert"
  load_balancer_id = oci_load_balancer_load_balancer.k3s_public_lb.id

  private_key        = file(var.PATH_TO_PUBLIC_LB_KEY)
  public_certificate = file(var.PATH_TO_PUBLIC_LB_CERT)

  lifecycle {
    create_before_destroy = true
  }
}

resource "oci_load_balancer_listener" "k3s_https_listener" {
  default_backend_set_name = oci_load_balancer_backend_set.k3s_https_backend_set.name
  load_balancer_id         = oci_load_balancer_load_balancer.k3s_public_lb.id
  name                     = "K3s_https_listener"
  port                     = var.https_lb_port
  protocol                 = "HTTP"
  ssl_configuration {
    certificate_name        = oci_load_balancer_certificate.k3s_https_certificate.certificate_name
    cipher_suite_name       = "oci-default-ssl-cipher-suite-v1"
    verify_peer_certificate = false
    verify_depth            = 1
  }
}

resource "oci_load_balancer_backend_set" "k3s_https_backend_set" {
  health_checker {
    protocol    = "HTTP"
    port        = var.https_lb_port
    url_path    = "/healthz"
    return_code = 200
  }
  load_balancer_id = oci_load_balancer_load_balancer.k3s_public_lb.id
  name             = "K3s_https_backend_set"
  policy           = "ROUND_ROBIN"
}

resource "oci_load_balancer_backend" "k3s_https_backend" {
  depends_on = [
    oci_core_instance_pool.k3s_workers,
  ]

  count            = var.k3s_worker_pool_size
  backendset_name  = oci_load_balancer_backend_set.k3s_https_backend_set.name
  ip_address       = data.oci_core_instance.k3s_workers_instances_ips[count.index].private_ip
  load_balancer_id = oci_load_balancer_load_balancer.k3s_public_lb.id
  port             = var.https_lb_port
}