resource "oci_core_instance" "k3s_primary_server" {
  depends_on = [
    oci_identity_dynamic_group.compute_dynamic_group,
    oci_identity_policy.compute_dynamic_group_policy,
    oci_identity_policy.oci_ccm_policy
  ]
  compartment_id      = var.compartment_ocid
  availability_domain = var.availability_domain
  display_name        = "K3s primary server"

  shape = var.compute_shape

  agent_config {
    is_management_disabled = "false"
    is_monitoring_disabled = "false"

    plugins_config {
      desired_state = "DISABLED"
      name          = "Vulnerability Scanning"
    }

    plugins_config {
      desired_state = "ENABLED"
      name          = "Compute Instance Monitoring"
    }

    plugins_config {
      desired_state = "DISABLED"
      name          = "Bastion"
    }
  }

  shape_config {
    memory_in_gbs = var.server_memory_in_gbs
    ocpus         = var.server_ocpus
  }

  source_details {
    source_id   = var.os_image_id
    source_type = "image"
  }

  create_vnic_details {
    assign_private_dns_record = true
    assign_public_ip          = true
    subnet_id                 = oci_core_subnet.default_oci_core_subnet10.id
    nsg_ids                   = [oci_core_network_security_group.lb_to_instances_kubeapi.id]
    hostname_label            = "k3s-primary-server"

  }

  metadata = {
    "ssh_authorized_keys" = file(var.PATH_TO_PUBLIC_KEY)
    "user_data"           = data.template_cloudinit_config.k3s_server_tpl.rendered
    "is_primary"          = "YES"
  }

  freeform_tags = {
    "provisioner"           = "terraform"
    "environment"           = "${var.environment}"
    "${var.unique_tag_key}" = "${var.unique_tag_value}"
    "k3s-template-type"     = "k3s-primary-server"
  }
}

resource "oci_core_instance_pool" "k3s_servers" {
  depends_on = [
    oci_core_instance.k3s_primary_server,
    null_resource.oci_ccm_config
  ]

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [load_balancers, freeform_tags]
  }

  display_name              = "k3s-servers"
  compartment_id            = var.compartment_ocid
  instance_configuration_id = oci_core_instance_configuration.k3s_server_template.id

  placement_configurations {
    availability_domain = var.availability_domain
    primary_subnet_id   = oci_core_subnet.default_oci_core_subnet10.id
    fault_domains       = var.fault_domains
  }

  size = var.k3s_server_pool_size - 1

  freeform_tags = {
    "provisioner"           = "terraform"
    "environment"           = "${var.environment}"
    "${var.unique_tag_key}" = "${var.unique_tag_value}"
    "k3s-cluster-name"      = "${var.cluster_name}"
    "k3s-instance-type"     = "k3s-server"
  }
}

resource "oci_core_instance_pool_instance" "k3s_primary_server_instance" {
  depends_on = [
    oci_core_instance_pool.k3s_servers
  ]
  instance_id                       = oci_core_instance.k3s_primary_server.id
  instance_pool_id                  = oci_core_instance_pool.k3s_servers.id
  auto_terminate_instance_on_delete = true
  decrement_size_on_delete          = false
}

resource "null_resource" "oci_ccm_config" {

  count = var.install_oci_ccm == "true" ? 1 : 0

  connection {
    host        = oci_core_instance.k3s_primary_server.public_ip
    private_key = file(var.PATH_TO_PRIVATE_KEY)
    timeout     = "40m"
    type        = "ssh"
    user        = var.operating_system == "ubuntu" ? "ubuntu" : "opc"
  }

  depends_on = [
    oci_core_instance.k3s_primary_server
  ]

  provisioner "file" {
    source      = "files/oci-cloud-controller-manager.yaml"
    destination = "/root/oci-cloud-controller-manager.yaml"
  }

  provisioner "file" {
    source      = "files/oci-cloud-controller-manager-rbac.yaml"
    destination = "/root/oci-cloud-controller-manager-rbac.yaml"
  }
}
