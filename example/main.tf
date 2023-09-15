variable "compartment_ocid" {}
variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "availability_domain" {
  default = "wYgE:EU-FRANKFURT-1-AD-1"
}
variable "public_key_path" {
  default     = "~/.ssh/id_rsa.pub"
}

variable "my_public_ip_cidr" {}
variable "cluster_name" {
  default = "k3s-oci"
}
variable "os_image_id" {
  default = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaaeusqwc4fgp4c5ienodxnlvrkimp4rp4a6snpnkpudznmdlxt3wpq"
}
variable "certmanager_email_address" {
  default = "changeme@example.com"
}
variable "region" {
  default = "eu-frankfurt-1"
}
variable "k3s_server_pool_size" {
  default = 1
}
variable "k3s_worker_pool_size" {
  default = 1
}
variable "k3s_extra_worker_node" {
  default = false
}
variable "expose_kubeapi" {
  default = true
}
variable "environment" {
  default = "prod"
}

variable "oci_core_vcn_cidr" {
  type    = string
  default = "10.100.0.0/16"
}

variable "oci_core_subnet_cidr10" {
  type    = string
  default = "10.100.0.0/24"
}

variable "oci_core_subnet_cidr11" {
  type    = string
  default = "10.100.1.0/24"
}

module "k3s_cluster" {
  #k3s_version               = "v1.28.1+k3s1"
  #k3s_version = "v1.27.5+k3s1"
  k3s_version = "v1.26.7+k3s1"
  #k3s_version = "v1.25.13+k3s1"

  region                    = var.region
  availability_domain       = var.availability_domain
  tenancy_ocid              = var.tenancy_ocid
  compartment_ocid          = var.compartment_ocid
  my_public_ip_cidr         = var.my_public_ip_cidr
  cluster_name              = var.cluster_name
  environment               = var.environment
  os_image_id               = var.os_image_id
  certmanager_email_address = var.certmanager_email_address
  k3s_server_pool_size      = var.k3s_server_pool_size
  k3s_worker_pool_size      = var.k3s_worker_pool_size
  k3s_extra_worker_node     = var.k3s_extra_worker_node
  expose_kubeapi            = var.expose_kubeapi
  ingress_controller        = "nginx"
  source                    = "../"
  install_certmanager       = false
  install_longhorn          = false
  install_argocd_image_updater = false
  argocd_image_updater_release = false

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
