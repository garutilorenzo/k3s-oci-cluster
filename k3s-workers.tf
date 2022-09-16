resource "oci_core_instance_pool" "k3s_workers" {

  depends_on = [
    oci_load_balancer_load_balancer.k3s_load_balancer,
  ]

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [load_balancers, freeform_tags, instance_configuration_id]
  }

  display_name              = "k3s-workers"
  compartment_id            = var.compartment_ocid
  instance_configuration_id = oci_core_instance_configuration.k3s_worker_template.id

  placement_configurations {
    availability_domain = var.availability_domain
    primary_subnet_id   = oci_core_subnet.default_oci_core_subnet10.id
    fault_domains       = var.fault_domains
  }

  size = var.k3s_worker_pool_size

  freeform_tags = {
    "provisioner"           = "terraform"
    "environment"           = "${var.environment}"
    "${var.unique_tag_key}" = "${var.unique_tag_value}"
    "k3s-cluster-name"      = "${var.cluster_name}"
    "k3s-instance-type"     = "k3s-worker"
  }
}