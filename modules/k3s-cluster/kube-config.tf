resource "ssh_resource" "get_kube_master_config" {
  when = "create"

  host        = data.oci_core_instance.k3s_servers_instances_ips[0].public_ip
  user        = "ubuntu"
  agent       = false
  private_key = file(replace(var.public_key_path, ".pub", ""))

  timeout     = "1m"
  retry_delay = "5s"

  file {
    content     = "sudo -u root cat /etc/rancher/k3s/k3s.yaml"
    destination = "/tmp/config.sh"
    permissions = "0700"
  }

  commands = [
    "/tmp/config.sh"
  ]

  depends_on = [
    data.cloudinit_config.k3s_server_tpl
  ]
}

resource "local_sensitive_file" "load_cluster_kubeconfig" {
  count    = var.load_cluster_kubeconfig ? 1 : 0
  content  = local.kube_config
  filename = local.kube_config_localfile

  depends_on = [
    ssh_resource.get_kube_master_config
  ]
}

