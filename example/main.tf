variable "compartment_ocid" {}
variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}

variable "oci_core_vcn_dns_label" {}
variable "oci_core_subnet_dns_label10" {}
variable "oci_core_subnet_dns_label11" {}

variable "region" {}
variable "availability_domain" {}
variable "my_public_ip_cidr" {}
variable "cluster_name" {}
variable "environment" {}
variable "certmanager_email_address" {}
variable "install_oci_ccm" {}

variable "operating_system" {}
variable "os_image_id" {}
variable "compute_shape" {}
variable "k3s_server_pool_size" {}
variable "server_ocpus" {}
variable "server_memory_in_gbs" {}
variable "k3s_worker_pool_size" {}
variable "worker_ocpus" {}
variable "worker_memory_in_gbs" {}

module "k3s_cluster" {
  source                      = "../"
  region                      = var.region
  availability_domain         = var.availability_domain
  compartment_ocid            = var.compartment_ocid
  tenancy_ocid                = var.tenancy_ocid
  my_public_ip_cidr           = var.my_public_ip_cidr
  cluster_name                = var.cluster_name
  environment                 = var.environment
  oci_core_vcn_dns_label      = var.oci_core_vcn_dns_label
  oci_core_subnet_dns_label10 = var.oci_core_subnet_dns_label10
  oci_core_subnet_dns_label11 = var.oci_core_subnet_dns_label11
  certmanager_email_address   = var.certmanager_email_address
  operating_system            = var.operating_system
  os_image_id                 = var.os_image_id
  compute_shape               = var.compute_shape
  k3s_server_pool_size        = var.k3s_server_pool_size
  server_memory_in_gbs        = var.server_memory_in_gbs
  server_ocpus                = var.server_ocpus
  k3s_worker_pool_size        = var.k3s_worker_pool_size
  worker_memory_in_gbs        = var.worker_memory_in_gbs
  worker_ocpus                = var.worker_ocpus
  install_oci_ccm             = var.install_oci_ccm
}

output "k3s_servers_ips" {
  value = module.k3s_cluster.k3s_servers_ips
}

output "k3s_workers_ips" {
  value = module.k3s_cluster.k3s_workers_ips
}

output "public_lb_ip" {
  value = module.k3s_cluster.public_lb_ip
}

output "primary_server_ip" {
  value = module.k3s_cluster.k3s_primary_server_ip
}
