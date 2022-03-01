resource "oci_core_default_security_list" "default_security_list" {
  compartment_id             = var.compartment_ocid
  manage_default_resource_id = oci_core_vcn.default_oci_core_vcn.default_security_list_id

  display_name = "Default security list"
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  ingress_security_rules {
    protocol = 1 # icmp
    source   = var.my_public_ip_cidr

    description = "Allow icmp from  ${var.my_public_ip_cidr}"

  }

  ingress_security_rules {
    protocol = 6 # tcp
    source   = var.my_public_ip_cidr

    description = "Allow SSH from ${var.my_public_ip_cidr}"

    tcp_options {
      min = 22
      max = 22
    }
  }

  ingress_security_rules {
    protocol = "all"
    source   = var.oci_core_vcn_cidr

    description = "Allow all from vcn subnet"
  }

  freeform_tags = {
    "provisioner"           = "terraform"
    "environment"           = "${var.environment}"
    "${var.unique_tag_key}" = "${var.unique_tag_value}"
  }
}