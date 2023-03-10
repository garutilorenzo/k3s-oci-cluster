variable "region" {
  type = string
}

variable "availability_domain" {
  type = string
}

variable "tenancy_ocid" {
  type = string
}

variable "user_ocid" {
  type = string
}

variable "compartment_ocid" {
  type = string
}

variable "environment" {
  type    = string
  default = "staging"
}

variable "cluster_name" {
  type    = string
  default = "k3s-cluster"
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

variable "public_key_path" {
  type        = string
  description = "Path to your public workstation SSH key"
}

variable "private_key_path" {
  type        = string
  description = "Path to your private workstation SSH key"
}
variable "fingerprint" {
  type        = string
  description = "(Optional) The fingerprint for the user's RSA key. This can be found in user settings in the Oracle Cloud Infrastructure console. Required if auth is set to 'ApiKey', ignored otherwise.)"
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
  description = "Dynamic group which contains all instance in this compartment"
  default     = "Compute_Dynamic_Group"
}

variable "oci_identity_policy_name" {
  type        = string
  description = "Policy to allow dynamic group, to read OCI api without auth"
  default     = "Compute_To_Oci_Api_Policy"
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
  type = bool
}

variable "unique_tag_key" {
  type = string
}

variable "unique_tag_value" {
  type    = string
  default = "k3s-provisioner"
}

variable "my_public_ip_cidr" {
  type        = string
  description = "My public ip CIDR"
  default     = ""
}

variable "istio_release" {
  type    = string
  default = "1.16.1"
}

variable "disable_ingress" {
  type    = bool
  default = false
}

variable "ingress_controller" {
  type    = string
  default = "default"
  validation {
    condition     = contains(["default", "nginx", "traefik2", "istio"], var.ingress_controller)
    error_message = "Supported ingress controllers are: default, nginx, traefik2, istio"
  }
}

variable "nginx_ingress_release" {
  type    = string
  default = "v1.5.1"
}

variable "install_certmanager" {
  type    = bool
  default = false
}

variable "certmanager_release" {
  type    = string
  default = "v1.11.0"
}

variable "certmanager_email_address" {
  type    = string
  default = "changeme@example.com"
}

variable "install_longhorn" {
  type    = bool
  default = false
}

variable "longhorn_release" {
  type    = string
  default = "v1.4.0"
}

variable "install_argocd" {
  type    = bool
  default = false
}

variable "argocd_release" {
  type    = string
  default = "v2.6.3"
}

variable "install_argocd_image_updater" {
  type    = bool
  default = false
}

variable "argocd_image_updater_release" {
  type    = string
  default = "v0.12.0"
}

variable "kubevela_release" {
  type    = string
  default = "1.7.5"
}

variable "install_kubevela" {
  type    = bool
  default = false
}

variable "crossplane_release" {
  type    = string
  default = "1.9.2"
}

variable "install_crossplane" {
  type    = bool
  default = false
}

variable "expose_kubeapi" {
  type    = bool
  default = false
}

variable "kubeconfig_location" {
  type        = string
  description = "Kubeconfig default location"
  default     = "~/.kube/config"
}

variable "load_cluster_kubeconfig" {
  type        = bool
  description = "Enable to access cluster locally - overwriting var.kubeconfig_location content!!!!"
  default     = false
}
