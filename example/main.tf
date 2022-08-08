variable "compartment_ocid" {

}

variable "tenancy_ocid" {

}

variable "user_ocid" {

}

variable "fingerprint" {

}

variable "private_key_path" {

}

variable "region" {
  default = "<change_me>"
}

module "k3s_cluster" {
  region                    = var.region
  availability_domain       = "<change_me>"
  compartment_ocid          = var.compartment_ocid
  my_public_ip_cidr         = "<change_me>"
  cluster_name              = "<change_me>"
  environment               = "staging"
  k3s_token                 = "<change_me>"
  certmanager_email_address = "<change_me>"
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