resource "oci_identity_dynamic_group" "compute_dynamic_group" {
  compartment_id = var.tenancy_ocid
  description    = "Dynamic group which contains all instance in this compartment"
  matching_rule  = "All {instance.compartment.id = '${var.compartment_ocid}'}"
  name           = var.oci_identity_dynamic_group_name

  freeform_tags = {
    "provisioner"           = "terraform"
    "environment"           = "${var.environment}"
    "${var.unique_tag_key}" = "${var.unique_tag_value}"
  }
}

resource "oci_identity_policy" "compute_dynamic_group_policy" {
  compartment_id = var.compartment_ocid
  description    = "Policy to allow dynamic group ${oci_identity_dynamic_group.compute_dynamic_group.name} to read instance-family and compute-management-family in the compartment"
  name           = var.oci_identity_policy_name
  statements = [
    "allow dynamic-group ${oci_identity_dynamic_group.compute_dynamic_group.name} to read instance-family in compartment id ${var.compartment_ocid}",
    "allow dynamic-group ${oci_identity_dynamic_group.compute_dynamic_group.name} to read compute-management-family in compartment id ${var.compartment_ocid}"
  ]

  freeform_tags = {
    "provisioner"           = "terraform"
    "environment"           = "${var.environment}"
    "${var.unique_tag_key}" = "${var.unique_tag_value}"
  }
}
