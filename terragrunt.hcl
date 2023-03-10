# Indicate where to source the terraform module from.
# The URL used here is a shorthand for
# "tfr://registry.terraform.io/terraform-aws-modules/vpc/aws?version=3.5.0".
# Note the extra `/` after the protocol is required for the shorthand
# notation.
terraform {
  source = "./modules//k3s-cluster"
}

# Error: 409-Conflict fix
// retry_max_attempts       = 2
// retry_sleep_interval_sec = 10
// retryable_errors = [
//   ".*",
//   ".*"
// ]

# Indicate the input values to use for the variables of the module.
inputs = {
  # Addons
  install_argocd     = true
  install_kubevela   = true
  install_crossplane = true

  expose_kubeapi          = true # expose only for my_public_ip
  load_cluster_kubeconfig = true
  k3s_extra_worker_node   = true # creates the 3rd worker node
  unique_tag_value        = basename(get_terragrunt_dir())

  # Set the values below - by editing or setting env vars..
  tenancy_ocid        = get_env("OCI_TENANCY_OCID")
  compartment_ocid    = get_env("OCI_COMPARTMENT_OCID")
  region              = get_env("OCI_REGION")
  os_image_id         = get_env("OCI_OS_IMAGE_ID")
  availability_domain = get_env("OCI_AVAILABILITY_DOMAIN")
  user_ocid           = get_env("OCI_USER_OCID")
  private_key_path    = get_env("OCI_PRIVATE_KEY_PATH")
  public_key_path     = get_env("OCI_PUBLIC_KEY_PATH")
  fingerprint         = get_env("OCI_FINGERPRINT", "")
}