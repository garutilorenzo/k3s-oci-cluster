resource "oci_core_instance_configuration" "k3s_server_template" {

  compartment_id = var.compartment_ocid
  display_name   = "k3s server configuration"

  freeform_tags = {
    "provisioner"           = "terraform"
    "environment"           = "${var.environment}"
    "${var.unique_tag_key}" = "${var.unique_tag_value}"
    "k3s-template-type"     = "k3s-server"
  }

  instance_details {
    instance_type = "compute"

    launch_details {

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

      availability_domain = var.availability_domain
      compartment_id      = var.compartment_ocid

      create_vnic_details {
        assign_public_ip = true
        subnet_id        = oci_core_subnet.default_oci_core_subnet10.id
        nsg_ids          = [oci_core_network_security_group.lb_to_instances_kubeapi.id]
      }

      display_name = "k3s server template"

      metadata = {
        "ssh_authorized_keys" = file(var.public_key_path)
        "user_data"           = data.cloudinit_config.k3s_server_tpl.rendered
      }

      shape = var.compute_shape
      shape_config {
        memory_in_gbs = "6"
        ocpus         = "1"
      }
      source_details {
        image_id    = var.os_image_id
        source_type = "image"
      }
    }
  }
}

resource "oci_core_instance_configuration" "k3s_worker_template" {

  compartment_id = var.compartment_ocid
  display_name   = "k3s worker configuration"

  freeform_tags = {
    "provisioner"           = "terraform"
    "environment"           = "${var.environment}"
    "${var.unique_tag_key}" = "${var.unique_tag_value}"
    "k3s-template-type"     = "k3s-worker"
  }

  instance_details {
    instance_type = "compute"

    launch_details {

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

      availability_domain = var.availability_domain
      compartment_id      = var.compartment_ocid

      create_vnic_details {
        assign_public_ip = true
        subnet_id        = oci_core_subnet.default_oci_core_subnet10.id
        nsg_ids          = [oci_core_network_security_group.lb_to_instances_http.id]
      }

      display_name = "k3s worker template"

      metadata = {
        "ssh_authorized_keys" = file(var.public_key_path)
        "user_data"           = data.cloudinit_config.k3s_worker_tpl.rendered
      }

      shape = var.compute_shape
      shape_config {
        memory_in_gbs = "6"
        ocpus         = "1"
      }
      source_details {
        image_id    = var.os_image_id
        source_type = "image"
      }
    }
  }
}