locals {
  k3s_int_lb_dns_name = format("%s.%s.%s.oraclevcn.com", replace(var.k3s_load_balancer_name, " ", "-"), var.oci_core_subnet_dns_label11, var.oci_core_vcn_dns_label)
}