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
  default = "test-cluster"
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
  default = 0
}
variable "k3s_extra_worker_node" {
  default = true
}
variable "expose_kubeapi" {
  default = true
}
variable "environment" {
  default = "prod"
}

module "k3s_cluster" {
  # k3s_version               = "v1.23.8+k3s2" # Fix kubectl exec failure
  # k3s_version               = "v1.24.4+k3s1" # Kubernetes version compatible with longhorn
  #k3s_version               = "v1.28.1+k3s1"
  #k3s_version = "v1.25.13+k3s1"
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
