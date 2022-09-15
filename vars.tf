variable "region" {
  type = string
}

variable "availability_domain" {
  type = string
}

variable "tenancy_ocid" {

}

variable "compartment_ocid" {
  type = string
}

variable "environment" {
  type = string
}

variable "k3s_token" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "fault_domains" {
  type    = list(any)
  default = ["FAULT-DOMAIN-1", "FAULT-DOMAIN-2", "FAULT-DOMAIN-3"]
}

variable "PATH_TO_PUBLIC_KEY" {
  type        = string
  default     = "~/.ssh/id_rsa.pub"
  description = "Path to your public key"
}

variable "os_image_id" {
  type    = string
  default = "ocid1.image.oc1.eu-zurich-1.aaaaaaaailwa7imzkgvd5oc7nrfzq4b7cpk7xbkiuz2kjzvskhthsbyn2vmq" # Canonical-Ubuntu-22.04-aarch64-2022.06.16-0
}

variable "compute_shape" {
  type    = string
  default = "VM.Standard.A1.Flex"
}

variable "public_lb_shape" {
  type    = string
  default = "flexible"
}

variable "oci_identity_dynamic_group_name" {
  type        = string
  default     = "Compute_Dynamic_Group"
  description = "Dynamic group which contains all instance in this compartment"
}

variable "oci_identity_policy_name" {
  type        = string
  default     = "Compute_To_Oci_Api_Policy"
  description = "Policy to allow dynamic group, to read OCI api without auth"
}

variable "oci_core_vcn_dns_label" {
  type    = string
  default = "defaultvcn"
}

variable "oci_core_subnet_dns_label10" {
  type    = string
  default = "defaultsubnet10"
}

variable "oci_core_subnet_dns_label11" {
  type    = string
  default = "defaultsubnet11"
}

variable "oci_core_vcn_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "oci_core_subnet_cidr10" {
  type    = string
  default = "10.0.0.0/24"
}

variable "oci_core_subnet_cidr11" {
  type    = string
  default = "10.0.1.0/24"
}

variable "kube_api_port" {
  type    = number
  default = 6443
}

variable "k3s_load_balancer_name" {
  type    = string
  default = "k3s internal load balancer"
}

variable "public_load_balancer_name" {
  type    = string
  default = "K3s public LB"
}

variable "http_lb_port" {
  type    = number
  default = 80
}

variable "https_lb_port" {
  type    = number
  default = 443
}

variable "nginx_ingress_controller_http_nodeport" {
  type    = number
  default = 30080
}

variable "nginx_ingress_controller_https_nodeport" {
  type    = number
  default = 30443
}

variable "k3s_server_pool_size" {
  type    = number
  default = 2
}

variable "k3s_worker_pool_size" {
  type    = number
  default = 2
}

variable "unique_tag_key" {
  type    = string
  default = "k3s-provisioner"
}

variable "unique_tag_value" {
  type    = string
  default = "https://github.com/garutilorenzo/k3s-oci-cluster"
}

variable "my_public_ip_cidr" {
  type        = string
  description = "My public ip CIDR"
}

variable "install_nginx_ingress" {
  type    = bool
  default = true
}

variable "install_certmanager" {
  type    = bool
  default = true
}

variable "certmanager_release" {
  type    = string
  default = "v1.8.2"
}

variable "certmanager_email_address" {
  type    = string
  default = "changeme@example.com"
}

variable "install_longhorn" {
  type    = bool
  default = true
}

variable "longhorn_release" {
  type    = string
  default = "v1.2.3"
}

variable "install_argocd" {
  type    = bool
  default = true
}

variable "argocd_release" {
  type    = string
  default = "v2.4.11"
}

variable "install_argocd_image_updater" {
  type    = bool
  default = true
}

variable "argocd_image_updater_release" {
  type    = string
  default = "v0.12.0"
}

variable "expose_kubeapi" {
  type    = bool
  default = false
}