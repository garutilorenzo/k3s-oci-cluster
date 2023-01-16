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

variable "cluster_name" {
  type = string
}

variable "os_image_id" {
  type = string
}

variable "k3s_version" {
  type    = string
  default = "latest"
}

variable "k3s_subnet" {
  type    = string
  default = "default_route_table"
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

variable "ingress_controller_http_nodeport" {
  type    = number
  default = 30080
}

variable "ingress_controller_https_nodeport" {
  type    = number
  default = 30443
}

variable "k3s_server_pool_size" {
  type    = number
  default = 1
}

variable "k3s_worker_pool_size" {
  type    = number
  default = 2
}

variable "k3s_extra_worker_node" {
  type    = bool
  default = true
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

variable "istio_release" {
  type    = string
  default = "1.15.3"
}

variable "disable_ingress" {
  type    = bool
  default = false
}

variable "ingress_controller" {
  type    = string
  default = "default"
  validation {
    condition     = contains(["nginx", "traefik2", "istio"], var.ingress_controller)
    error_message = "Supported ingress controllers are: nginx, traefik2, istio"
  }
}

variable "nginx_ingress_release" {
  type    = string
  default = "v1.5.1"
}

variable "install_certmanager" {
  type    = bool
  default = true
}

variable "certmanager_release" {
  type    = string
  default = "v1.10.0"
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
  default = "v1.3.2"
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